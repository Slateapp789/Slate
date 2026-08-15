import type {
  BookingConfirmationEmailConfig,
  BookingConfirmationRpcClient,
} from "./booking_confirmation_email.ts";

type Claim = {
  outbox_id: string;
  lease_token: string;
  recipient_email: string;
  attempt_count: number;
};

export function waitlistWelcomeEmailConfig(
  readEnv: (name: string) => string | undefined = Deno.env.get,
): BookingConfirmationEmailConfig | null {
  const apiKey = readEnv("RESEND_API_KEY")?.trim() ?? "";
  const from = (readEnv("WAITLIST_CONFIRMATION_EMAIL_FROM") ??
    readEnv("BOOKING_CONFIRMATION_EMAIL_FROM") ?? "").trim();
  if (apiKey.length < 16 || from.length < 3) return null;
  return { apiKey, from };
}

export function waitlistWelcomeEmailContent() {
  const subject = "Welcome to the Workloop launch list";
  const plainText = `Hi,

Thanks for joining the Workloop launch list. You are all set.

Workloop brings clients, bookings, tasks, notes and money into one calm mobile workspace, helping solo business owners spend less time on admin and more time doing the work.

What happens next

• We will email you when a beta place or public access is ready.
• Private beta access is free and does not require payment details.
• Public access is planned with 30 days free, then £9.99 monthly or £99 annually.

What you will be able to do

• See your day and what needs attention.
• Keep client details, booking history, notes and tasks connected.
• Track money made, spent and owed without a complicated finance system.

See how Workloop fits into a working day: https://workloop.uk/how-it-works

Questions? Reply to this email or contact support@workloop.uk.

You can leave the launch list at any time by emailing support@workloop.uk.

Workloop
The business operating system for one.`;
  const html =
    `<!doctype html><html><body style="margin:0;background:#f7f5ef;color:#121728;font-family:Arial,sans-serif"><div style="display:none;max-height:0;overflow:hidden">You are on the Workloop launch list.</div><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f7f5ef"><tr><td align="center" style="padding:32px 16px"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:600px;background:#ffffff;border:1px solid #e5e2db;border-radius:24px;overflow:hidden"><tr><td style="padding:34px 34px 20px"><div style="font-size:24px;font-weight:800;color:#121728">Workloop</div></td></tr><tr><td style="padding:0 34px 34px"><p style="margin:0 0 12px;color:#5a54ec;font-size:13px;font-weight:800;letter-spacing:.08em">YOU ARE ON THE LIST</p><h1 style="margin:0 0 18px;font-size:34px;line-height:1.08;letter-spacing:-.03em">Thanks. You are all set.</h1><p style="margin:0 0 24px;color:#616778;font-size:17px;line-height:1.6">Workloop brings clients, bookings, tasks, notes and money into one calm mobile workspace, so you can spend less time on admin and more time doing the work.</p><div style="padding:22px;background:#eeecff;border-radius:16px"><h2 style="margin:0 0 12px;font-size:19px">What happens next</h2><p style="margin:0 0 10px;line-height:1.55">✓ We will email you when a beta place or public access is ready.</p><p style="margin:0 0 10px;line-height:1.55">✓ Private beta access is free and needs no payment details.</p><p style="margin:0;line-height:1.55">✓ Public access is planned with 30 days free, then £9.99 monthly or £99 annually.</p></div><h2 style="margin:28px 0 10px;font-size:19px">One place for the working day</h2><p style="margin:0 0 22px;color:#616778;line-height:1.6">See the day ahead, call a client, tick off tasks, complete bookings and keep an eye on money made, spent and owed.</p><a href="https://workloop.uk/how-it-works" style="display:inline-block;padding:15px 22px;background:#554eef;color:#ffffff;text-decoration:none;border-radius:14px;font-weight:700">See how Workloop works</a><p style="margin:30px 0 0;color:#616778;font-size:14px;line-height:1.6">Questions? Reply to this email or contact <a href="mailto:support@workloop.uk" style="color:#554eef">support@workloop.uk</a>.<br>You can leave the launch list at any time by emailing us.</p></td></tr></table></td></tr></table></body></html>`;
  return { subject, plainText, html };
}

export async function drainWaitlistWelcomeEmails(input: {
  client: BookingConfirmationRpcClient;
  config: BookingConfirmationEmailConfig;
  limit?: number;
  fetcher?: typeof fetch;
}) {
  const { data, error } = await input.client.rpc(
    "claim_waitlist_welcome_emails",
    {
      p_limit: input.limit ?? 20,
    },
  );
  if (error) throw new Error(`waitlist_email_claim_failed:${error.code ?? ""}`);
  const claims = Array.isArray(data) ? data as Claim[] : [];
  let sent = 0;
  let pending = 0;
  let failed = 0;
  for (const claim of claims) {
    let providerMessageId = "";
    let delivered = false;
    let failure = "";
    try {
      const content = waitlistWelcomeEmailContent();
      const provider = await (input.fetcher ?? fetch)(
        "https://api.resend.com/emails",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${input.config.apiKey}`,
            "Content-Type": "application/json",
            "Idempotency-Key": `launch-waitlist-joined/${claim.outbox_id}`,
          },
          body: JSON.stringify({
            from: input.config.from,
            to: [claim.recipient_email],
            subject: content.subject,
            text: content.plainText,
            html: content.html,
          }),
          signal: AbortSignal.timeout(10_000),
        },
      );
      if (!provider.ok) {
        throw new Error(`email_provider_http_${provider.status}`);
      }
      const body = await provider.json().catch(() => ({}));
      providerMessageId = typeof body?.id === "string" ? body.id : "";
      if (!providerMessageId) {
        throw new Error("email_provider_invalid_response");
      }
      delivered = true;
    } catch (error) {
      failure = error instanceof Error
        ? error.message.slice(0, 500)
        : "email_provider_unavailable";
    }
    const completion = await input.client.rpc("finish_waitlist_welcome_email", {
      p_outbox_id: claim.outbox_id,
      p_lease_token: claim.lease_token,
      p_sent: delivered,
      p_provider_message_id: providerMessageId || null,
      p_error: failure || null,
    });
    if (completion.error) {
      throw new Error(
        `waitlist_email_finish_failed:${completion.error.code ?? ""}`,
      );
    }
    if (completion.data === "sent") sent++;
    else if (completion.data === "failed") failed++;
    else pending++;
  }
  return { processed: claims.length, sent, pending, failed };
}
