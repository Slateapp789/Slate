import { createClient } from "@supabase/supabase-js";
import {
  bestEffortPlatformIp,
  bookingRequestOutcomeResponse,
  bookingRequestValidationError,
  nullableStringValue,
  resolveRequestToken,
  stringValue,
} from "./request_validation.ts";

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
  email?: unknown;
  serviceId?: unknown;
  service_id?: unknown;
  preferredTimeText?: unknown;
  preferred_time_text?: unknown;
  message?: unknown;
  website?: unknown;
  requestToken?: unknown;
  request_token?: unknown;
};

const textEncoder = new TextEncoder();

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
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
  const configuredRateLimitSalt =
    Deno.env.get("BOOKING_REQUEST_RATE_LIMIT_SALT") ?? "";
  if (supabaseUrl.length === 0 || serviceRoleKey.length < 32) {
    return response(500, {
      error: "Booking request service is not configured",
    });
  }
  // Prefer a dedicated secret, but retain a secure, domain-separated fallback
  // so a missing optional secret cannot silently disable public bookings.
  const rateLimitSalt = configuredRateLimitSalt.length >= 32
    ? configuredRateLimitSalt
    : await sha256(`workloop-booking-rate-limit:${serviceRoleKey}`);

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
  const email = typeof payload.email === "string"
    ? payload.email.trim().toLowerCase()
    : "";
  const preferredTimeText = nullableStringValue(
    payload.preferredTimeText ?? payload.preferred_time_text,
    160,
  );
  const message = nullableStringValue(payload.message, 1000);
  const serviceId = stringValue(payload.serviceId ?? payload.service_id, 64);
  const requestToken = resolveRequestToken(
    payload.requestToken ?? payload.request_token,
  );
  const validationError = bookingRequestValidationError({
    handle,
    name,
    phone,
    email,
    serviceId,
    requestToken,
  });
  if (validationError !== null) {
    return response(400, { error: validationError });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: profile, error: profileError } = await supabase
    .from("business_profiles")
    .select("workspace_id")
    .eq("handle", handle)
    .maybeSingle();

  if (profileError) return response(500, { error: "Could not load profile" });
  if (!profile) return response(404, { error: "Profile not found" });

  const sourceHash = await sha256(
    `${profile.workspace_id}:${
      bestEffortPlatformIp(req.headers)
    }:${rateLimitSalt}`,
  );

  const { data: result, error: createError } = await supabase.rpc(
    "create_public_booking_request_v2",
    {
      p_workspace_id: profile.workspace_id,
      p_name: name,
      p_phone: phone,
      p_email: email,
      p_service_id: serviceId || null,
      p_preferred_time_text: preferredTimeText,
      p_message: message,
      p_source_hash: sourceHash,
      p_request_token: requestToken,
    },
  );

  if (createError) {
    console.error("booking_request_rpc_failed", { code: createError.code });
    return response(500, { error: "Could not create request" });
  }

  const row = Array.isArray(result) ? result[0] : result;
  const outcome = typeof row?.outcome === "string" ? row.outcome : "";
  const mappedOutcome = bookingRequestOutcomeResponse(outcome);
  return response(mappedOutcome.status, mappedOutcome.body);
});
