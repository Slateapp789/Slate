import {
  parsePlacesRateLimitResult,
  placesRateLimitBucket,
} from "./rate_limit.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("uses independent autocomplete and details buckets", () => {
  assertEquals(placesRateLimitBucket("autocomplete"), "autocomplete");
  assertEquals(placesRateLimitBucket("details"), "details");
  assertEquals(placesRateLimitBucket("unsupported"), null);
});

Deno.test("parses the single-row Supabase RPC response", () => {
  assertEquals(
    parsePlacesRateLimitResult([{
      allowed: false,
      retry_after_seconds: 42,
      remaining: 0,
    }]),
    {
      allowed: false,
      retryAfterSeconds: 42,
      remaining: 0,
    },
  );
});

Deno.test("rejects malformed rate-limit responses", () => {
  assertEquals(parsePlacesRateLimitResult([{ allowed: "yes" }]), null);
  assertEquals(parsePlacesRateLimitResult([]), null);
});
