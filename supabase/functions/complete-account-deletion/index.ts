import { createClient } from "@supabase/supabase-js";

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

  const configuredAdminToken = Deno.env.get("ACCOUNT_DELETION_ADMIN_TOKEN") ?? "";
  const suppliedAdminToken = req.headers.get("x-admin-token") ?? "";
  if (!configuredAdminToken || suppliedAdminToken !== configuredAdminToken) {
    return response(401, { error: "Unauthorized" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    return response(500, { error: "Deletion completion service is not configured" });
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
    .select("id, workspace_id, user_id, requested_by_user_id, email, status, requested_at")
    .eq("id", requestId)
    .maybeSingle();

  if (requestError) {
    return response(500, { error: "Could not load deletion request" });
  }
  if (!request) return response(404, { error: "Deletion request not found" });
  if (!["requested", "processing"].includes(request.status)) {
    return response(409, { error: "Deletion request is not open" });
  }

  await supabase
    .from("account_deletion_requests")
    .update({
      status: "processing",
      processing_started_at: new Date().toISOString(),
      completed_by: "admin-token",
      completion_mode: "workspace_and_auth_user_delete",
      notes: notes || "Deletion completion started.",
    })
    .eq("id", request.id);

  let workspaceDeleted = false;
  let authUserDeleted = false;
  const userId = request.requested_by_user_id ?? request.user_id;

  const { error: workspaceDeleteError } = await supabase
    .from("workspaces")
    .delete()
    .eq("id", request.workspace_id);
  if (workspaceDeleteError) {
    await supabase.from("account_deletion_audit").insert({
      request_id: request.id,
      workspace_id: request.workspace_id,
      user_id: userId,
      email_hash: request.email ? await sha256(request.email.toLowerCase()) : null,
      requested_at: request.requested_at,
      completed_by: "admin-token",
      completion_mode: "workspace_and_auth_user_delete",
      workspace_deleted: false,
      auth_user_deleted: false,
      notes: `Workspace deletion failed: ${workspaceDeleteError.message}`,
    });
    return response(500, { error: "Workspace deletion failed" });
  }
  workspaceDeleted = true;

  if (userId) {
    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(userId);
    if (authDeleteError) {
      await supabase.from("account_deletion_audit").insert({
        request_id: request.id,
        workspace_id: request.workspace_id,
        user_id: userId,
        email_hash: request.email ? await sha256(request.email.toLowerCase()) : null,
        requested_at: request.requested_at,
        completed_by: "admin-token",
        completion_mode: "workspace_and_auth_user_delete",
        workspace_deleted: workspaceDeleted,
        auth_user_deleted: false,
        notes: `Workspace deleted, auth user deletion failed: ${authDeleteError.message}`,
      });
      return response(500, { error: "Auth user deletion failed after workspace deletion" });
    }
    authUserDeleted = true;
  }

  await supabase.from("account_deletion_audit").insert({
    request_id: request.id,
    workspace_id: request.workspace_id,
    user_id: userId,
    email_hash: request.email ? await sha256(request.email.toLowerCase()) : null,
    requested_at: request.requested_at,
    completed_by: "admin-token",
    completion_mode: "workspace_and_auth_user_delete",
    workspace_deleted: workspaceDeleted,
    auth_user_deleted: authUserDeleted,
    notes: notes || "Workspace and auth user deleted.",
  });

  return response(200, {
    ok: true,
    workspaceDeleted,
    authUserDeleted,
  });
});
