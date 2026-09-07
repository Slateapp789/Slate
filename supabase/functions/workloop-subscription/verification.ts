import {
  Environment,
  SignedDataVerifier,
} from "@apple/app-store-server-library";
import { Buffer } from "node:buffer";
import { appleRootG3 } from "./apple_root.ts";

export const products = new Set(["workloop_monthly", "workloop_yearly"]);
export const bundleId = "com.ismaeel.workloop";
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export type VerifiedTransaction = {
  bundleId?: string;
  productId?: string;
  appAccountToken?: string;
  originalTransactionId?: string;
  transactionId?: string;
  expiresDate?: number;
  revocationDate?: number;
  signedDate?: number;
  environment?: string;
  type?: string;
  isUpgraded?: boolean;
};

export function subscriptionRecord(
  t: VerifiedTransaction,
  expectedUser?: string,
  graceExpiresDate?: number,
  signedDate?: number,
) {
  if (graceExpiresDate !== undefined && signedDate === undefined) {
    throw new Error("Verified renewal status required for grace period");
  }
  if (
    t.bundleId !== bundleId || !products.has(t.productId ?? "") ||
    !uuid.test(t.appAccountToken ?? "") ||
    (expectedUser &&
      t.appAccountToken?.toLowerCase() !== expectedUser.toLowerCase()) ||
    !/^[0-9]{1,64}$/.test(t.originalTransactionId ?? "") ||
    !/^[0-9]{1,64}$/.test(t.transactionId ?? "") ||
    (t.isUpgraded !== undefined && typeof t.isUpgraded !== "boolean") ||
    !["Production", "Sandbox"].includes(t.environment ?? "") ||
    t.type !== "Auto-Renewable Subscription"
  ) throw new Error("Invalid subscription identity");
  const instant = (n: number | undefined, required = false) => {
    if (n == null && !required) return null;
    if (
      !Number.isSafeInteger(n) || n! <= 0 ||
      !Number.isFinite(new Date(n!).getTime())
    ) {
      throw new Error("Invalid subscription date");
    }
    return new Date(n!).toISOString();
  };
  return {
    platform: "apple",
    environment: t.environment,
    user_id: t.appAccountToken!.toLowerCase(),
    product_id: t.productId,
    original_transaction_id: t.originalTransactionId,
    transaction_id: t.transactionId,
    expires_at: instant(t.expiresDate, true),
    revoked_at: instant(t.revocationDate),
    grace_expires_at: instant(graceExpiresDate),
    // An outer notification may be newer while carrying an older transaction
    // snapshot. Only the inner signature date may update refund/expiry facts.
    signed_at: instant(t.signedDate, true),
    // A restored transaction does not include renewal/grace status. Keep that
    // independently ordered so restoring cannot erase a verified grace period.
    status_signed_at: instant(signedDate),
    is_upgraded: t.isUpgraded ?? false,
  };
}

function verifier(environment: Environment) {
  return new SignedDataVerifier(
    [Buffer.from(appleRootG3, "base64")],
    true,
    environment,
    bundleId,
    6800472527,
  );
}

// Environment is never trusted from an unverified payload. Each verifier checks
// Apple's certificate chain, signature, application and environment itself.
export async function verifyTransaction(jws: string) {
  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    try {
      return await verifier(environment).verifyAndDecodeTransaction(jws);
    } catch {
      /* Try the other Apple environment; never decode without verification. */
    }
  }
  throw new Error("Apple verification failed");
}

export async function verifyNotification(jws: string) {
  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    try {
      const v = verifier(environment);
      const notification = await v.verifyAndDecodeNotification(jws);
      if (notification.notificationType === "TEST") return null;
      if (
        !Number.isSafeInteger(notification.signedDate) ||
        notification.signedDate! <= 0
      ) {
        throw new Error("Missing notification date");
      }
      const data = notification.data;
      if (!data?.signedTransactionInfo) throw new Error("Missing transaction");
      const transaction = await v.verifyAndDecodeTransaction(
        data.signedTransactionInfo,
      );
      const renewal = data.signedRenewalInfo
        ? await v.verifyAndDecodeRenewalInfo(data.signedRenewalInfo)
        : null;
      if (
        renewal &&
        renewal.originalTransactionId !== transaction.originalTransactionId
      ) {
        throw new Error("Mismatched renewal");
      }
      return subscriptionRecord(
        transaction,
        undefined,
        data.status === 4 ? renewal?.gracePeriodExpiresDate : undefined,
        notification.signedDate,
      );
    } catch { /* Signed sandbox events must pass the sandbox verifier. */ }
  }
  throw new Error("Apple notification verification failed");
}
