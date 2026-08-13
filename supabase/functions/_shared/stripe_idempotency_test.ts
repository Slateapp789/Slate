import {
  requireMatchingPaymentOperation,
  requireRefundWithinBalance,
  requireStripeIdempotencyKey,
} from "./stripe_idempotency.ts";

Deno.test("Stripe idempotency keys are trimmed, bounded, and required", () => {
  const key = requireStripeIdempotencyKey(
    { idempotencyKey: `  ${"a".repeat(140)}  ` },
    "invalid",
  );
  if (key.length !== 128) throw new Error("Expected a bounded key");

  let rejected = false;
  try {
    requireStripeIdempotencyKey({ idempotencyKey: "too-short" }, "invalid");
  } catch (error) {
    rejected = error instanceof Error && error.message === "invalid";
  }
  if (!rejected) throw new Error("Expected a short key to be rejected");
});

Deno.test("new refunds cannot exceed the succeeded-refund balance", () => {
  requireRefundWithinBalance(1500, 5000, 2500);

  for (const requested of [0, 2501, 5000.5]) {
    let rejected = false;
    try {
      requireRefundWithinBalance(requested, 5000, 2500);
    } catch (_) {
      rejected = true;
    }
    if (!rejected) throw new Error("Expected an invalid refund to fail");
  }
});

Deno.test("a replay key cannot be reused for different payment parameters", () => {
  const existing = {
    invoice_id: "invoice-1",
    amount_minor: 2500,
    collection_method: "payment_link",
  };
  requireMatchingPaymentOperation(
    existing,
    "invoice-1",
    2500,
    "payment_link",
  );

  for (
    const attempt of [
      () =>
        requireMatchingPaymentOperation(
          existing,
          "invoice-2",
          2500,
          "payment_link",
        ),
      () =>
        requireMatchingPaymentOperation(
          existing,
          "invoice-1",
          3000,
          "payment_link",
        ),
      () =>
        requireMatchingPaymentOperation(
          existing,
          "invoice-1",
          2500,
          "tap_to_pay",
        ),
    ]
  ) {
    let rejected = false;
    try {
      attempt();
    } catch (_) {
      rejected = true;
    }
    if (!rejected) throw new Error("Expected parameter drift to be rejected");
  }
});
