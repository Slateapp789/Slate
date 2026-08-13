import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  closeWorkloopStripeAccount,
  type StripeRequester,
} from "./stripe_account_offboarding.ts";

Deno.test("closes every configuration on a Workloop Accounts v2 account", async () => {
  const calls: Array<{ path: string; options: unknown }> = [];
  const request: StripeRequester = <T>(
    _secret: string,
    path: string,
    options?: unknown,
  ) => {
    calls.push({ path, options });
    return Promise.resolve(
      (calls.length === 1
        ? { closed: false, applied_configurations: ["merchant", "recipient"] }
        : { closed: true }) as T,
    );
  };

  const result = await closeWorkloopStripeAccount(
    "sk_test_private",
    "acct_Workloop123",
    "test",
    request,
  );

  assertEquals(result, { alreadyClosed: false });
  assertEquals(calls, [
    { path: "/v2/core/accounts/acct_Workloop123", options: undefined },
    {
      path: "/v2/core/accounts/acct_Workloop123/close",
      options: {
        method: "POST",
        json: { applied_configurations: ["merchant", "recipient"] },
      },
    },
  ]);
});

Deno.test("already closed Stripe accounts are an idempotent success", async () => {
  const request: StripeRequester = <T>() =>
    Promise.resolve({ closed: true } as T);
  const result = await closeWorkloopStripeAccount(
    "sk_live_private",
    "acct_Workloop123",
    "live",
    request,
  );
  assertEquals(result, { alreadyClosed: true });
});

Deno.test("offboarding rejects a key/account mode mismatch", async () => {
  await assertRejects(
    () =>
      closeWorkloopStripeAccount(
        "sk_test_private",
        "acct_Workloop123",
        "live",
      ),
    Error,
    "mode does not match",
  );
});
