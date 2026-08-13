import { createClient } from "@supabase/supabase-js";
import {
  bookingConfirmationEmailConfig,
  BookingConfirmationRpcClient,
  drainBookingConfirmationEmails,
  validBookingConfirmationDrainToken,
} from "../_shared/booking_confirmation_email.ts";

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return response(405, { error: "Method not allowed" });
  }

  const configuredToken = Deno.env.get("BOOKING_CONFIRMATION_DRAIN_TOKEN") ??
    "";
  const suppliedToken = req.headers.get("x-workloop-drain-token") ?? "";
  if (!validBookingConfirmationDrainToken(configuredToken, suppliedToken)) {
    return response(401, { error: "Unauthorized" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const emailConfig = bookingConfirmationEmailConfig();
  if (!supabaseUrl || serviceRoleKey.length < 32 || emailConfig === null) {
    return response(503, { error: "Email delivery is not configured" });
  }

  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  try {
    const result = await drainBookingConfirmationEmails({
      client: serviceClient as unknown as BookingConfirmationRpcClient,
      config: emailConfig,
      limit: 20,
    });
    // Counts provide operational evidence without logging recipient/body data.
    return response(200, { ok: true, ...result });
  } catch (_) {
    console.error("booking_confirmation_email_scheduled_drain_failed");
    return response(503, {
      error: "Email delivery is temporarily unavailable",
    });
  }
});
