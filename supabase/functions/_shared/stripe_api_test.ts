import {
  amountToMinor,
  publicStripeError,
  safePlatformFeeMinor,
  StripeApiError,
  stripeRequest,
  verifyStripeSignature,
} from "./stripe_api.ts";

Deno.test("amountToMinor rounds provider amounts safely", () => {
  if (amountToMinor("12.34") !== 1234) throw new Error("Expected 1234");
  if (amountToMinor(10.005) !== 1001) throw new Error("Expected 1001");
  if (amountToMinor(0) !== null) throw new Error("Zero must be rejected");
});

Deno.test("platform fee remains zero unless explicitly enabled", () => {
  Deno.env.set("WORKLOOP_PLATFORM_FEE_BPS", "250");
  Deno.env.delete("WORKLOOP_PLATFORM_FEE_ENABLED");
  try {
    if (safePlatformFeeMinor(10_000) !== 0) {
      throw new Error("Fee must be off by default");
    }
  } finally {
    Deno.env.delete("WORKLOOP_PLATFORM_FEE_BPS");
  }
});

Deno.test("platform setup errors never expose internal Stripe links", () => {
  const result = publicStripeError(
    new StripeApiError(
      "Please review the responsibilities of managing losses at " +
        "https://dashboard.stripe.com/settings/connect/platform-profile.",
      400,
    ),
  );
  if (result.status !== 503) throw new Error("Expected a setup outage");
  if (result.code !== "platform_configuration_required") {
    throw new Error("Expected a stable platform setup code");
  }
  if (result.message.includes("stripe.com")) {
    throw new Error("Internal Stripe links must not reach the app");
  }
});

Deno.test("Stripe v2 requests use pinned JSON without exposing the key", async () => {
  const originalFetch = globalThis.fetch;
  let requestUrl = "";
  let requestHeaders = new Headers();
  let requestBody = "";
  globalThis.fetch = (input, init) => {
    requestUrl = String(input);
    requestHeaders = new Headers(init?.headers);
    requestBody = typeof init?.body === "string" ? init.body : "";
    return Promise.resolve(
      new Response('{"id":"acct_v2_test"}', {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );
  };
  try {
    await stripeRequest("sk_test_private", "/v2/core/accounts", {
      idempotencyKey: "workloop-connect-v2-test",
      json: { dashboard: "full" },
    });
  } finally {
    globalThis.fetch = originalFetch;
  }

  if (requestUrl !== "https://api.stripe.com/v2/core/accounts") {
    throw new Error("Expected the Accounts v2 endpoint");
  }
  if (requestHeaders.get("Content-Type") !== "application/json") {
    throw new Error("Expected a JSON request");
  }
  if (requestHeaders.get("Stripe-Version") !== "2026-07-29.dahlia") {
    throw new Error("Expected the pinned Stripe API version");
  }
  if (requestBody !== '{"dashboard":"full"}') {
    throw new Error("Unexpected Stripe JSON body");
  }
  if (requestBody.includes("sk_test_private")) {
    throw new Error("Stripe keys must remain in authorization headers");
  }
});

Deno.test("Stripe signature accepts current valid HMAC and rejects stale", async () => {
  const payload = '{"id":"evt_test"}';
  const secret = "whsec_test";
  const timestamp = 2_000_000_000;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${payload}`),
  );
  const signature = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
  const header = `t=${timestamp},v1=${signature}`;
  if (!await verifyStripeSignature(payload, header, secret, timestamp)) {
    throw new Error("Expected a valid signature");
  }
  if (await verifyStripeSignature(payload, header, secret, timestamp + 301)) {
    throw new Error("Expected stale signature to fail");
  }
});
