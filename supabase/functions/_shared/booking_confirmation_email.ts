export type BookingConfirmationEmailConfig = {
  apiKey: string;
  from: string;
};

type ClaimedEmail = {
  outbox_id: string;
  booking_request_id: string;
  lease_token: string;
  recipient_email: string;
  payload: Record<string, unknown>;
  attempt_count: number;
};

type RpcError = { code?: string; message?: string };

export type BookingConfirmationRpcClient = {
  rpc: (
    name: string,
    params?: Record<string, unknown>,
  ) => PromiseLike<{ data: unknown; error: RpcError | null }>;
};

export function bookingConfirmationEmailConfig(
  readEnv: (name: string) => string | undefined = Deno.env.get,
): BookingConfirmationEmailConfig | null {
  const apiKey = readEnv("RESEND_API_KEY")?.trim() ?? "";
  const from = readEnv("BOOKING_CONFIRMATION_EMAIL_FROM")?.trim() ?? "";
  if (apiKey.length < 16 || from.length < 3) return null;
  return { apiKey, from };
}

export function validBookingConfirmationDrainToken(
  configured: string,
  supplied: string,
) {
  const encoder = new TextEncoder();
  const a = encoder.encode(configured);
  const b = encoder.encode(supplied);
  if (a.length < 32 || a.length !== b.length) return false;
  let difference = 0;
  for (let index = 0; index < a.length; index++) {
    difference |= a[index] ^ b[index];
  }
  return difference === 0;
}

function text(value: unknown, fallback = "") {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : fallback;
}

export function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function bookingTime(payload: Record<string, unknown>) {
  const raw = text(payload.start_time);
  if (raw.length === 0) return "the time agreed with the business";
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    return "the time agreed with the business";
  }
  const requestedTimezone = text(payload.timezone, "UTC");
  try {
    return new Intl.DateTimeFormat("en-GB", {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: requestedTimezone,
      timeZoneName: "short",
    }).format(parsed);
  } catch (_) {
    return new Intl.DateTimeFormat("en-GB", {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "UTC",
      timeZoneName: "short",
    }).format(parsed);
  }
}

export function bookingConfirmationEmailContent(
  claim: Pick<ClaimedEmail, "payload">,
) {
  const customerName = text(claim.payload.customer_name, "there");
  const businessName = text(claim.payload.business_name, "The business");
  const bookingTitle = text(claim.payload.booking_title, "Booking");
  const location = text(claim.payload.location);
  const time = bookingTime(claim.payload);
  const subject = `${businessName} confirmed your booking`;
  const locationText = location.length > 0 ? `\nLocation: ${location}` : "";
  const plainText =
    `Hi ${customerName},\n\n${businessName} has confirmed your booking request.\n\nBooking: ${bookingTitle}\nWhen: ${time}${locationText}\n\nIf anything needs changing, contact ${businessName} directly.\n\nSent by Workloop`;
  const locationHtml = location.length > 0
    ? `<br><strong>Location:</strong> ${escapeHtml(location)}`
    : "";
  const html = `<p>Hi ${escapeHtml(customerName)},</p><p>${
    escapeHtml(businessName)
  } has confirmed your booking request.</p><p><strong>Booking:</strong> ${
    escapeHtml(bookingTitle)
  }<br><strong>When:</strong> ${
    escapeHtml(time)
  }${locationHtml}</p><p>If anything needs changing, contact ${
    escapeHtml(businessName)
  } directly.</p><p>Sent by Workloop</p>`;
  return { subject, plainText, html };
}

export async function sendBookingConfirmationEmail(
  claim: ClaimedEmail,
  config: BookingConfirmationEmailConfig,
  fetcher: typeof fetch = fetch,
) {
  const content = bookingConfirmationEmailContent(claim);
  const response = await fetcher("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": `booking-request-confirmed/${claim.outbox_id}`,
    },
    body: JSON.stringify({
      from: config.from,
      to: [claim.recipient_email],
      subject: content.subject,
      text: content.plainText,
      html: content.html,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    throw new Error(`email_provider_http_${response.status}`);
  }
  const body = await response.json().catch(() => ({}));
  const providerMessageId = typeof body?.id === "string" ? body.id : "";
  if (providerMessageId.length === 0) {
    throw new Error("email_provider_invalid_response");
  }
  return providerMessageId;
}

export async function drainBookingConfirmationEmails(input: {
  client: BookingConfirmationRpcClient;
  config: BookingConfirmationEmailConfig;
  limit?: number;
  bookingRequestId?: string;
  fetcher?: typeof fetch;
}) {
  const { data, error } = await input.client.rpc(
    "claim_booking_confirmation_emails",
    {
      p_limit: input.limit ?? 20,
      p_booking_request_id: input.bookingRequestId ?? null,
    },
  );
  if (error) throw new Error(`email_outbox_claim_failed:${error.code ?? ""}`);
  const claims = Array.isArray(data) ? data as ClaimedEmail[] : [];
  let sent = 0;
  let pending = 0;
  let failed = 0;

  for (const claim of claims) {
    let providerMessageId = "";
    let delivered = false;
    let failure = "";
    try {
      providerMessageId = await sendBookingConfirmationEmail(
        claim,
        input.config,
        input.fetcher,
      );
      delivered = true;
    } catch (error) {
      failure = error instanceof Error
        ? error.message.slice(0, 500)
        : "email_provider_unavailable";
    }

    const completion = await input.client.rpc(
      "finish_booking_confirmation_email",
      {
        p_outbox_id: claim.outbox_id,
        p_lease_token: claim.lease_token,
        p_sent: delivered,
        p_provider_message_id: providerMessageId || null,
        p_error: failure || null,
      },
    );
    if (completion.error) {
      throw new Error(
        `email_outbox_finish_failed:${completion.error.code ?? ""}`,
      );
    }
    if (completion.data === "sent") sent++;
    else if (completion.data === "failed") failed++;
    else pending++;
  }

  return { processed: claims.length, sent, pending, failed };
}
