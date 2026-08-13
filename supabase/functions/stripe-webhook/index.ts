import { createClient } from "@supabase/supabase-js";
import { verifyStripeSignature } from "../_shared/stripe_api.ts";

type Json = Record<string, unknown>;

function jsonResponse(status: number, body: Json) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function stringValue(value: unknown, maxLength = 200) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function objectValue(value: unknown): Json {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Json
    : {};
}

function idValue(value: unknown) {
  if (typeof value === "string") return value;
  return stringValue(objectValue(value).id);
}

function intentStatus(value: unknown) {
  switch (value) {
    case "succeeded":
      return "succeeded";
    case "processing":
      return "processing";
    case "requires_payment_method":
      return "requires_payment_method";
    case "canceled":
      return "cancelled";
    default:
      return "pending";
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
  if (
    !supabaseUrl || serviceRoleKey.length < 32 ||
    !webhookSecret.startsWith("whsec_")
  ) {
    return jsonResponse(503, { error: "Webhook is not configured" });
  }

  const rawBody = await req.text();
  const signature = req.headers.get("Stripe-Signature") ?? "";
  if (!await verifyStripeSignature(rawBody, signature, webhookSecret)) {
    return jsonResponse(400, { error: "Invalid signature" });
  }

  let event: Json;
  try {
    event = JSON.parse(rawBody) as Json;
  } catch (_) {
    return jsonResponse(400, { error: "Invalid event" });
  }
  const eventId = stringValue(event.id, 120);
  const eventType = stringValue(event.type, 120);
  const accountId = stringValue(event.account, 100);
  if (!eventId.startsWith("evt_") || !eventType) {
    return jsonResponse(400, { error: "Invalid event" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  async function syncSucceededRefunds(
    transactionId: string,
    amount: number,
  ) {
    const { data: refunds, error: refundsError } = await supabase
      .from("payment_refunds")
      .select("amount_minor")
      .eq("transaction_id", transactionId)
      .eq("status", "succeeded");
    if (refundsError) throw refundsError;
    const refunded = (refunds ?? []).reduce(
      (sum, row) => sum + Number(row.amount_minor),
      0,
    );
    const boundedRefunded = Math.min(amount, Math.max(0, refunded));
    if (boundedRefunded === 0) return;
    const { error } = await supabase.from("payment_transactions").update({
      amount_refunded_minor: boundedRefunded,
      status: boundedRefunded >= amount ? "refunded" : "partially_refunded",
      updated_at: new Date().toISOString(),
    }).eq("id", transactionId);
    if (error) throw error;
  }

  const { data: claimed, error: claimError } = await supabase.rpc(
    "claim_stripe_webhook_event",
    {
      p_event_id: eventId,
      p_account_id: accountId || null,
      p_event_type: eventType,
      p_livemode: event.livemode === true,
      p_payload: event,
    },
  );
  if (claimError) {
    console.error("stripe_webhook_claim_failed", {
      eventId,
      code: claimError.code,
    });
    return jsonResponse(500, { error: "Could not record event" });
  }
  if (claimed !== true) {
    return jsonResponse(200, { received: true, duplicate: true });
  }

  async function finish(
    status: "processed" | "ignored" | "failed",
    message?: string,
  ) {
    const { error } = await supabase.rpc("finish_stripe_webhook_event", {
      p_event_id: eventId,
      p_status: status,
      p_error_message: message?.slice(0, 1000) ?? null,
    });
    if (error) throw error;
  }

  const object = objectValue(objectValue(event.data).object);
  try {
    let handled = true;
    if (eventType === "account.updated") {
      const requirements = objectValue(object.requirements);
      const requirementsDue = Array.isArray(requirements.currently_due)
        ? requirements.currently_due.filter((value) =>
          typeof value === "string"
        )
        : [];
      const disabled = stringValue(requirements.disabled_reason);
      const ready = object.charges_enabled === true &&
        object.payouts_enabled === true &&
        object.details_submitted === true;
      const { error } = await supabase.from("workspace_payment_accounts")
        .update({
          onboarding_status: disabled
            ? "restricted"
            : ready
            ? "ready"
            : "pending",
          details_submitted: object.details_submitted === true,
          charges_enabled: object.charges_enabled === true,
          payouts_enabled: object.payouts_enabled === true,
          requirements_due: requirementsDue,
          last_synced_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }).eq("stripe_account_id", stringValue(object.id));
      if (error) throw error;
    } else if (eventType.startsWith("payment_intent.")) {
      const intentId = stringValue(object.id);
      const lastError = objectValue(object.last_payment_error);
      const update: Json = {
        status: intentStatus(object.status),
        stripe_charge_id: idValue(object.latest_charge) || null,
        failure_code: stringValue(lastError.code) || null,
        failure_message: stringValue(lastError.message, 500) || null,
        paid_at: object.status === "succeeded"
          ? new Date().toISOString()
          : null,
        updated_at: new Date().toISOString(),
      };
      const { error } = await supabase.from("payment_transactions").update(
        update,
      )
        .eq("stripe_account_id", accountId)
        .eq("stripe_payment_intent_id", intentId);
      if (error) throw error;
    } else if (
      eventType.startsWith("charge.") &&
      !eventType.startsWith("charge.refund.") &&
      !eventType.startsWith("charge.dispute.")
    ) {
      const intentId = idValue(object.payment_intent);
      if (!intentId) {
        handled = false;
      } else {
        const amount = Number(object.amount ?? 0);
        const refunded = Math.max(0, Number(object.amount_refunded ?? 0));
        const paid = object.status === "succeeded" || object.paid === true;
        const status = refunded >= amount && amount > 0
          ? "refunded"
          : refunded > 0
          ? "partially_refunded"
          : paid
          ? "succeeded"
          : eventType === "charge.failed"
          ? "failed"
          : "pending";
        const outcome = objectValue(object.outcome);
        const { error } = await supabase.from("payment_transactions").update({
          stripe_charge_id: stringValue(object.id) || null,
          amount_refunded_minor: refunded,
          status,
          receipt_url: stringValue(object.receipt_url, 1000) || null,
          failure_code: stringValue(object.failure_code) || null,
          failure_message: stringValue(object.failure_message, 500) ||
            stringValue(outcome.seller_message, 500) || null,
          paid_at: paid ? new Date().toISOString() : null,
          updated_at: new Date().toISOString(),
        }).eq("stripe_account_id", accountId)
          .eq("stripe_payment_intent_id", intentId);
        if (error) throw error;
      }
    } else if (
      eventType.startsWith("refund.") ||
      eventType.startsWith("charge.refund.")
    ) {
      const intentId = idValue(object.payment_intent);
      const { data: transaction, error: findError } = await supabase
        .from("payment_transactions")
        .select("id, workspace_id")
        .eq("stripe_account_id", accountId)
        .eq("stripe_payment_intent_id", intentId)
        .maybeSingle();
      if (findError) throw findError;
      if (!transaction) {
        handled = false;
      } else {
        const status = object.status === "succeeded"
          ? "succeeded"
          : object.status === "failed"
          ? "failed"
          : object.status === "canceled"
          ? "cancelled"
          : "pending";
        const metadata = objectValue(object.metadata);
        const idempotencyKey = stringValue(
          metadata.workloop_idempotency_key,
          128,
        );
        const { error } = await supabase.from("payment_refunds").upsert({
          workspace_id: transaction.workspace_id,
          transaction_id: transaction.id,
          stripe_refund_id: object.id,
          amount_minor: object.amount,
          status,
          reason: stringValue(object.reason) || null,
          failure_reason: stringValue(object.failure_reason) || null,
          idempotency_key: idempotencyKey.length >= 16 ? idempotencyKey : null,
          updated_at: new Date().toISOString(),
        }, { onConflict: "stripe_refund_id" });
        if (error) throw error;
        if (status === "succeeded") {
          const { data: fullTransaction, error: transactionError } =
            await supabase.from("payment_transactions")
              .select("amount_minor")
              .eq("id", transaction.id)
              .single();
          if (transactionError) throw transactionError;
          await syncSucceededRefunds(
            transaction.id,
            Number(fullTransaction.amount_minor),
          );
        }
      }
    } else if (
      eventType === "checkout.session.completed" ||
      eventType === "checkout.session.async_payment_succeeded"
    ) {
      const paid = object.payment_status === "paid" ||
        eventType === "checkout.session.async_payment_succeeded";
      const { error } = await supabase.from("payment_transactions").update({
        stripe_payment_intent_id: idValue(object.payment_intent) || null,
        status: paid ? "succeeded" : "processing",
        paid_at: paid ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      }).eq("stripe_account_id", accountId)
        .eq("stripe_checkout_session_id", stringValue(object.id));
      if (error) throw error;
    } else if (
      eventType === "checkout.session.expired" ||
      eventType === "checkout.session.async_payment_failed"
    ) {
      const { error } = await supabase.from("payment_transactions").update({
        status: eventType === "checkout.session.expired"
          ? "cancelled"
          : "failed",
        updated_at: new Date().toISOString(),
      }).eq("stripe_account_id", accountId)
        .eq("stripe_checkout_session_id", stringValue(object.id));
      if (error) throw error;
    } else if (eventType.startsWith("charge.dispute.")) {
      const intentId = idValue(object.payment_intent);
      const lost = object.status === "lost";
      const won = object.status === "won";
      const { error } = await supabase.from("payment_transactions").update({
        status: won ? "succeeded" : "disputed",
        failure_code: lost ? "dispute_lost" : "disputed",
        failure_message: lost
          ? "The card dispute was lost."
          : "This payment is under dispute.",
        updated_at: new Date().toISOString(),
      }).eq("stripe_account_id", accountId)
        .eq("stripe_payment_intent_id", intentId);
      if (error) throw error;
    } else {
      handled = false;
    }

    await finish(handled ? "processed" : "ignored");
    return jsonResponse(200, { received: true });
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : "Unknown webhook error";
    console.error("stripe_webhook_processing_failed", {
      eventId,
      eventType,
      message,
    });
    try {
      await finish("failed", message);
    } catch (finishError) {
      console.error("stripe_webhook_failure_record_failed", {
        eventId,
        message: finishError instanceof Error ? finishError.message : "unknown",
      });
    }
    return jsonResponse(500, { error: "Webhook processing failed" });
  }
});
