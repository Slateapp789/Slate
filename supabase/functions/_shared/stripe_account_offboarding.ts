import { stripeRequest } from "./stripe_api.ts";

type Json = Record<string, unknown>;

type StripeRequestOptions = {
  method?: "GET" | "POST";
  json?: unknown;
};

export type StripeRequester = <T>(
  secretKey: string,
  path: string,
  options?: StripeRequestOptions,
) => Promise<T>;

const supportedConfigurations = new Set(["customer", "merchant", "recipient"]);

function stringArray(value: unknown) {
  if (!Array.isArray(value)) return [] as string[];
  return value.filter((item): item is string =>
    typeof item === "string" && supportedConfigurations.has(item)
  );
}

function assertMatchingKeyMode(secretKey: string, mode: string) {
  const matches = mode === "live"
    ? secretKey.startsWith("sk_live_")
    : mode === "test" && secretKey.startsWith("sk_test_");
  if (!matches) {
    throw new Error("Stripe account mode does not match the configured key");
  }
}

// Accounts are created by Workloop through Accounts v2. Closing every applied
// configuration removes platform access and prevents further operation while
// retaining Stripe's limited regulatory/history record. A GET first makes the
// workflow safely retryable after a provider success followed by a DB failure.
export async function closeWorkloopStripeAccount(
  secretKey: string,
  accountId: string,
  mode: string,
  request: StripeRequester = stripeRequest,
) {
  assertMatchingKeyMode(secretKey, mode);
  if (!/^acct_[A-Za-z0-9]+$/.test(accountId)) {
    throw new Error("Invalid Stripe account identifier");
  }

  const account = await request<Json>(
    secretKey,
    `/v2/core/accounts/${encodeURIComponent(accountId)}`,
  );
  if (account.closed === true) return { alreadyClosed: true };

  const appliedConfigurations = stringArray(account.applied_configurations);
  if (appliedConfigurations.length === 0) {
    throw new Error("Stripe account has no closeable configuration");
  }

  const closed = await request<Json>(
    secretKey,
    `/v2/core/accounts/${encodeURIComponent(accountId)}/close`,
    {
      method: "POST",
      json: { applied_configurations: appliedConfigurations },
    },
  );
  if (closed.closed !== true) {
    throw new Error("Stripe did not confirm account offboarding");
  }
  return { alreadyClosed: false };
}
