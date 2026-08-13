import { createClient } from "@supabase/supabase-js";
import { isSoleWorkspaceOwner } from "../_shared/sole_workspace_owner.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type RequestPayload = {
  workspaceId?: unknown;
};

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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return response(405, { error: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return response(500, {
      error: "Deletion request service is not configured",
    });
  }

  let payload: RequestPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return response(400, { error: "Invalid request body" });
  }

  const workspaceId = stringValue(payload.workspaceId, 64);
  if (!isUuid(workspaceId)) {
    return response(400, { error: "Invalid workspace" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userResult, error: userError } = await userClient.auth
    .getUser();
  const user = userResult.user;
  if (userError || !user) {
    return response(401, { error: "Unauthorized" });
  }

  const { data: meetsMfaPolicy, error: mfaPolicyError } = await userClient.rpc(
    "current_user_meets_mfa_policy",
  );
  if (mfaPolicyError) {
    console.error("account_deletion_mfa_policy_check_failed", {
      code: mfaPolicyError.code,
    });
    return response(503, { error: "Could not verify account security" });
  }
  if (meetsMfaPolicy !== true) {
    return response(403, {
      error: "Complete two-factor verification to delete this account",
      code: "mfa_required",
    });
  }

  const { data: memberships, error: membershipError } = await serviceClient
    .from("workspace_members")
    .select("user_id")
    .eq("workspace_id", workspaceId)
    .limit(2);

  if (membershipError) {
    return response(500, { error: "Could not verify workspace ownership" });
  }
  if (!isSoleWorkspaceOwner(memberships, user.id)) {
    return response(403, {
      error: "Only the sole workspace owner can delete this account",
    });
  }

  const { data: existing, error: existingError } = await serviceClient
    .from("account_deletion_requests")
    .select("id, status")
    .eq("workspace_id", workspaceId)
    .eq("requested_by_user_id", user.id)
    .in("status", ["requested", "processing"])
    .maybeSingle();

  if (existingError) {
    return response(500, { error: "Could not check deletion request" });
  }

  const email = user.email ?? "";
  if (existing) {
    const { error: updateError } = await serviceClient
      .from("account_deletion_requests")
      .update({
        user_id: user.id,
        email,
        requested_at: new Date().toISOString(),
        notes: "Deletion request refreshed by account owner.",
      })
      .eq("id", existing.id);

    if (updateError) {
      return response(500, { error: "Could not refresh deletion request" });
    }
    return response(200, {
      ok: true,
      requestId: existing.id,
      status: existing.status,
    });
  }

  const { data: inserted, error: insertError } = await serviceClient
    .from("account_deletion_requests")
    .insert({
      workspace_id: workspaceId,
      user_id: user.id,
      requested_by_user_id: user.id,
      email,
      status: "requested",
      requested_at: new Date().toISOString(),
      notes: "Deletion requested from Workloop account settings.",
    })
    .select("id, status")
    .single();

  if (insertError) {
    return response(500, { error: "Could not create deletion request" });
  }

  return response(200, {
    ok: true,
    requestId: inserted.id,
    status: inserted.status,
  });
});
