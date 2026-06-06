import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type BookingRequestPayload = {
  handle?: unknown;
  name?: unknown;
  phone?: unknown;
  serviceId?: unknown;
  service_id?: unknown;
  preferredTimeText?: unknown;
  preferred_time_text?: unknown;
  message?: unknown;
  website?: unknown;
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
  return value.replace(/\s+/g, " ").trim().slice(0, maxLength);
}

function nullableStringValue(value: unknown, maxLength: number) {
  const cleaned = stringValue(value, maxLength);
  return cleaned.length === 0 ? null : cleaned;
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function firstForwardedIp(req: Request) {
  const forwarded = req.headers.get("x-forwarded-for") ?? "";
  const first = forwarded.split(",").map((part) => part.trim()).find(Boolean);
  return first ??
    req.headers.get("cf-connecting-ip") ??
    req.headers.get("x-real-ip") ??
    "unknown";
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

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (supabaseUrl.length === 0 || serviceRoleKey.length === 0) {
    return response(500, { error: "Booking request service is not configured" });
  }

  let payload: BookingRequestPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return response(400, { error: "Invalid request body" });
  }

  if (stringValue(payload.website, 120).length > 0) {
    return response(202, { ok: true });
  }

  const handle = stringValue(payload.handle, 80).toLowerCase();
  const name = stringValue(payload.name, 80);
  const phone = stringValue(payload.phone, 32);
  const phoneDigits = phone.replace(/\D/g, "");
  const preferredTimeText = nullableStringValue(
    payload.preferredTimeText ?? payload.preferred_time_text,
    160,
  );
  const message = nullableStringValue(payload.message, 1000);
  const serviceId = stringValue(payload.serviceId ?? payload.service_id, 64);

  if (!/^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$/.test(handle)) {
    return response(400, { error: "Invalid profile handle" });
  }
  if (name.length === 0 || phone.length === 0 || phoneDigits.length < 7) {
    return response(400, { error: "Name and a valid phone are required" });
  }
  if (serviceId.length > 0 && !isUuid(serviceId)) {
    return response(400, { error: "Invalid service" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: profile, error: profileError } = await supabase
    .from("business_profiles")
    .select("workspace_id, booking_mode")
    .eq("handle", handle)
    .maybeSingle();

  if (profileError) return response(500, { error: "Could not load profile" });
  if (!profile) return response(404, { error: "Profile not found" });
  if (profile.booking_mode !== "manual") {
    return response(409, { error: "Booking requests are closed" });
  }

  let safeServiceId: string | null = null;
  if (serviceId.length > 0) {
    const { data: service, error: serviceError } = await supabase
      .from("services")
      .select("id")
      .eq("id", serviceId)
      .eq("workspace_id", profile.workspace_id)
      .eq("show_on_profile", true)
      .eq("active", true)
      .maybeSingle();

    if (serviceError) {
      return response(500, { error: "Could not validate service" });
    }
    if (!service) return response(400, { error: "Invalid service" });
    safeServiceId = service.id;
  }

  const salt = Deno.env.get("BOOKING_REQUEST_RATE_LIMIT_SALT") ?? "slate-v1";
  const sourceHash = await sha256(
    `${profile.workspace_id}:${firstForwardedIp(req)}:${salt}`,
  );
  const recentWindow = new Date(Date.now() - 15 * 60 * 1000).toISOString();

  const { count: sourceCount, error: sourceCountError } = await supabase
    .from("booking_requests")
    .select("id", { count: "exact", head: true })
    .eq("workspace_id", profile.workspace_id)
    .eq("source_hash", sourceHash)
    .gte("created_at", recentWindow);

  if (sourceCountError) {
    return response(500, { error: "Could not validate request" });
  }
  if ((sourceCount ?? 0) >= 5) {
    return response(429, { error: "Too many requests. Try again later." });
  }

  const { count: phoneCount, error: phoneCountError } = await supabase
    .from("booking_requests")
    .select("id", { count: "exact", head: true })
    .eq("workspace_id", profile.workspace_id)
    .eq("phone", phone)
    .gte("created_at", recentWindow);

  if (phoneCountError) {
    return response(500, { error: "Could not validate request" });
  }
  if ((phoneCount ?? 0) >= 3) {
    return response(429, { error: "Too many requests. Try again later." });
  }

  const { error: insertError } = await supabase.from("booking_requests").insert({
    workspace_id: profile.workspace_id,
    name,
    phone,
    service_id: safeServiceId,
    preferred_time_text: preferredTimeText,
    message,
    status: "pending",
    source_hash: sourceHash,
  });

  if (insertError) return response(500, { error: "Could not create request" });

  const { error: notificationError } = await supabase
    .from("notifications")
    .insert({
      workspace_id: profile.workspace_id,
      type: "booking_request",
      title: "New booking request",
      body: `${name} requested a booking.`,
      deep_link: "/booking-requests",
    });
  if (notificationError) {
    console.error("booking_request_notification_failed", notificationError);
  }

  return response(200, { ok: true });
});
