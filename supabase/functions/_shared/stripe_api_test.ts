import {
  amountToMinor,
  safePlatformFeeMinor,
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
