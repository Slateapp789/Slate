type Json = Record<string, unknown>;

export function requireStripeIdempotencyKey(
  payload: Json,
  errorMessage: string,
) {
  const raw = payload.idempotencyKey;
  const key = typeof raw === "string" ? raw.trim().slice(0, 128) : "";
  if (key.length < 16) throw new Error(errorMessage);
  return key;
}

export function requireMatchingPaymentOperation(
  transaction: Json,
  invoiceId: string,
  amountMinor: number,
  collectionMethod: "tap_to_pay" | "payment_link",
) {
  if (
    transaction.invoice_id !== invoiceId ||
    Number(transaction.amount_minor) !== amountMinor ||
    transaction.collection_method !== collectionMethod
  ) {
    throw new Error("Payment request key was already used");
  }
}

export function requireRefundWithinBalance(
  requested: number,
  amount: number,
  alreadyRefunded: number,
) {
  const remaining = Math.max(0, amount - Math.max(0, alreadyRefunded));
  if (
    !Number.isSafeInteger(requested) || requested <= 0 || requested > remaining
  ) {
    throw new Error("Refund amount is outside the refundable balance");
  }
}
