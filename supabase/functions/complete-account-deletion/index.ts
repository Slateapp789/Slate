import { createClient } from "@supabase/supabase-js";
import { closeWorkloopStripeAccount } from "../_shared/stripe_account_offboarding.ts";
import { canCompleteAccountDeletion } from "../_shared/account_deletion_owner.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type CompletionPayload = {
  requestId?: unknown;
  notes?: unknown;
};

const textEncoder = new TextEncoder();

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function stringValue(value: unknown, maxLength: number) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    textEncoder.encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return response(405, { error: "Method not allowed" });
  }

  const configuredAdminToken = Deno.env.get("ACCOUNT_DELETION_ADMIN_TOKEN") ??
    "";
  const suppliedAdminToken = req.headers.get("x-admin-token") ?? "";
  if (!configuredAdminToken || suppliedAdminToken !== configuredAdminToken) {
    return response(401, { error: "Unauthorized" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    return response(500, {
      error: "Deletion completion service is not configured",
    });
  }

  let payload: CompletionPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return response(400, { error: "Invalid request body" });
  }

  const requestId = stringValue(payload.requestId, 64);
  const notes = stringValue(payload.notes, 1000);
  if (!isUuid(requestId)) {
    return response(400, { error: "Invalid deletion request" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: request, error: requestError } = await supabase
    .from("account_deletion_requests")
    .select(
      "id, workspace_id, user_id, requested_by_user_id, email, status, requested_at, processing_started_at",
    )
    .eq("id", requestId)
    .maybeSingle();

  if (requestError) {
    return response(500, { error: "Could not load deletion request" });
  }
  if (!request) return response(404, { error: "Deletion request not found" });
  if (!["requested", "processing"].includes(request.status)) {
    return response(409, { error: "Deletion request is not open" });
  }

  const userId = request.requested_by_user_id ?? request.user_id;
  if (!userId) {
    return response(409, {
      error: "Deletion blocked because the request has no verified owner",
    });
  }

  if (request.workspace_id) {
    const { data: memberships, error: membershipError } = await supabase
      .from("workspace_members")
      .select("user_id")
      .eq("workspace_id", request.workspace_id)
      .limit(2);

    if (membershipError) {
      return response(500, {
        error: "Could not verify workspace ownership",
      });
    }
    const { data: authUserResult, error: authUserLookupError } = await supabase
      .auth.admin.getUserById(userId);
    const authUserMissing = authUserLookupError &&
      (authUserLookupError.status === 404 ||
        /not found|does not exist/i.test(authUserLookupError.message));
    if (authUserLookupError && !authUserMissing) {
      return response(500, { error: "Could not verify the Auth owner" });
    }
    if (
      !canCompleteAccountDeletion({
        memberships,
        requestedUserId: userId,
        authUserExists: authUserResult?.user != null,
      })
    ) {
      return response(409, {
        error:
          "Deletion blocked because sole workspace ownership could not be verified",
      });
    }
  }

  const claimTime = new Date();
  const previousClaimTime = request.processing_started_at
    ? new Date(request.processing_started_at)
    : null;
  const retryLeaseMs = 5 * 60 * 1000;
  if (
    request.status === "processing" &&
    previousClaimTime &&
    claimTime.getTime() - previousClaimTime.getTime() < retryLeaseMs
  ) {
    return response(409, {
      error: "Deletion is already processing; retry after five minutes",
    });
  }

  let claimQuery = supabase
    .from("account_deletion_requests")
    .update({
      status: "processing",
      processing_started_at: claimTime.toISOString(),
      completed_by: "admin-token",
      completion_mode: "workspace_and_auth_user_delete",
      notes: notes || "Deletion completion started.",
    })
    .eq("id", request.id)
    .eq("status", request.status);
  if (request.status === "processing") {
    claimQuery = previousClaimTime
      ? claimQuery.eq("processing_started_at", request.processing_started_at)
      : claimQuery.is("processing_started_at", null);
  }
  const { data: claim, error: completionUpdateError } = await claimQuery
    .select("id")
    .maybeSingle();
  if (completionUpdateError) {
    return response(500, { error: "Could not start account deletion" });
  }
  if (!claim) {
    return response(409, { error: "Deletion request was claimed elsewhere" });
  }

  async function releaseClaim(note: string) {
    const { error } = await supabase.from("account_deletion_requests").update({
      status: "requested",
      processing_started_at: null,
      notes: note,
    }).eq("id", requestId).eq("status", "processing");
    return error == null;
  }

  // Workloop creates Accounts v2 merchant accounts. Provider offboarding must
  // be confirmed before local account/payment mappings are deleted; otherwise
  // Workloop could retain access to an account that the user believed removed.
  // The helper first reads the account and treats `closed: true` as an
  // idempotent success, so a retry is safe if the later DB delete fails.
  if (request.workspace_id) {
    const { data: paymentAccount, error: paymentAccountError } = await supabase
      .from("workspace_payment_accounts")
      .select("stripe_account_id, mode")
      .eq("workspace_id", request.workspace_id)
      .maybeSingle();
    if (paymentAccountError) {
      await releaseClaim("Stripe offboarding could not be prepared; retry.");
      return response(500, {
        error: "Could not prepare payment account offboarding",
      });
    }

    if (paymentAccount) {
      const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
      try {
        await closeWorkloopStripeAccount(
          stripeSecretKey,
          stringValue(paymentAccount.stripe_account_id, 100),
          stringValue(paymentAccount.mode, 8),
        );
      } catch (_) {
        console.error("account_deletion_stripe_offboarding_failed", {
          requestId: request.id,
        });
        const released = await releaseClaim(
          "Stripe offboarding was not confirmed; no local account data was deleted.",
        );
        return response(released ? 409 : 500, {
          error: released
            ? "Payment account offboarding must complete before deletion"
            : "Payment account offboarding failed and the request needs review",
          code: "stripe_offboarding_required",
        });
      }
    }
  }

  let workspaceDeleted = false;
  let authUserDeleted = false;

  // The request survives workspace deletion (FK uses ON DELETE SET NULL), so
  // a later auth failure can be retried with the same request id.
  if (request.workspace_id) {
    const { error: workspaceDeleteError } = await supabase
      .from("workspaces")
      .delete()
      .eq("id", request.workspace_id);
    if (workspaceDeleteError) {
      await supabase.from("account_deletion_audit").insert({
        request_id: request.id,
        workspace_id: request.workspace_id,
        user_id: userId,
        email_hash: request.email
          ? await sha256(request.email.toLowerCase())
          : null,
        requested_at: request.requested_at,
        completed_by: "admin-token",
        completion_mode: "workspace_and_auth_user_delete",
        workspace_deleted: false,
        auth_user_deleted: false,
        notes: `Workspace deletion failed: ${workspaceDeleteError.message}`,
      });
      return response(500, { error: "Workspace deletion failed" });
    }
  }
  workspaceDeleted = true;

  if (userId) {
    // Prevent new sign-ins while the final delete is being completed. Existing
    // access JWTs are bounded separately by RLS and the app's server check.
    await supabase.auth.admin.updateUserById(userId, {
      ban_duration: "876000h",
    }).catch(() => null);
    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(
      userId,
    );
    const authUserAlreadyDeleted = authDeleteError &&
      (authDeleteError.status === 404 ||
        /not found|does not exist/i.test(authDeleteError.message));
    if (authDeleteError && !authUserAlreadyDeleted) {
      await supabase.from("account_deletion_audit").insert({
        request_id: request.id,
        workspace_id: request.workspace_id,
        user_id: userId,
        email_hash: request.email
          ? await sha256(request.email.toLowerCase())
          : null,
        requested_at: request.requested_at,
        completed_by: "admin-token",
        completion_mode: "workspace_and_auth_user_delete",
        workspace_deleted: workspaceDeleted,
        auth_user_deleted: false,
        notes:
          `Workspace deleted, auth user deletion failed: ${authDeleteError.message}`,
      });
      return response(500, {
        error: "Auth user deletion failed after workspace deletion",
      });
    }
    authUserDeleted = true;
  }

  const { error: finalUpdateError } = await supabase
    .from("account_deletion_requests")
    .update({
      status: "completed",
      completed_at: new Date().toISOString(),
      notes: notes || "Workspace and auth user deleted.",
    })
    .eq("id", request.id);
  if (finalUpdateError) {
    return response(500, {
      error:
        "Account data was deleted, but completion could not be recorded; retry this request",
    });
  }

  const { error: auditError } = await supabase.from("account_deletion_audit")
    .insert({
      request_id: request.id,
      workspace_id: request.workspace_id,
      user_id: userId,
      email_hash: request.email
        ? await sha256(request.email.toLowerCase())
        : null,
      requested_at: request.requested_at,
      completed_by: "admin-token",
      completion_mode: "workspace_and_auth_user_delete",
      workspace_deleted: workspaceDeleted,
      auth_user_deleted: authUserDeleted,
      notes: notes || "Workspace and auth user deleted.",
    });
  if (auditError) {
    return response(500, {
      error:
        "Account data was deleted, but the deletion audit could not be recorded",
    });
  }

  return response(200, {
    ok: true,
    workspaceDeleted,
    authUserDeleted,
  });
});
