import {
  bestEffortPlatformIp,
  bookingRequestOutcomeResponse,
  bookingRequestValidationError,
  isUuid,
  normalizePhoneDigits,
  nullableStringValue,
  resolveRequestToken,
  stringValue,
} from "./request_validation.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("normalises public text and optional values", () => {
  assertEquals(stringValue("  Ada   Lovelace  ", 80), "Ada Lovelace");
  assertEquals(nullableStringValue("   ", 80), null);
});

Deno.test("normalises equivalent phone formats to the same digits", () => {
  assertEquals(normalizePhoneDigits("+44 (0) 7123-456-789"), "4407123456789");
  assertEquals(normalizePhoneDigits("44 0 7123 456 789"), "4407123456789");
});

Deno.test("accepts UUID request tokens and rejects arbitrary identifiers", () => {
  assertEquals(isUuid("c2499f36-c3f4-4f80-80dd-31ba2b581f78"), true);
  assertEquals(isUuid("retry-me"), false);
});

Deno.test("preserves a supplied retry token across duplicate submissions", () => {
  const token = "c2499f36-c3f4-4f80-80dd-31ba2b581f78";
  assertEquals(resolveRequestToken(token, () => "unused"), token);
  assertEquals(resolveRequestToken(token, () => "different"), token);
  assertEquals(resolveRequestToken("", () => token), token);
});

Deno.test("rejects invalid booking fields before any database call", () => {
  const valid = {
    handle: "ada-studio",
    name: "Ada",
    phone: "+44 7123 456 789",
    serviceId: "c2499f36-c3f4-4f80-80dd-31ba2b581f78",
    requestToken: "e72d0756-7440-4ae3-88f2-c6dce8bcbdf7",
  };
  assertEquals(bookingRequestValidationError(valid), null);
  assertEquals(
    bookingRequestValidationError({ ...valid, handle: "../admin" }),
    "Invalid profile handle",
  );
  assertEquals(
    bookingRequestValidationError({ ...valid, phone: "123" }),
    "Name and a valid phone are required",
  );
  assertEquals(
    bookingRequestValidationError({ ...valid, serviceId: "other-workspace" }),
    "Invalid service",
  );
  assertEquals(
    bookingRequestValidationError({ ...valid, requestToken: "retry-me" }),
    "Invalid request token",
  );
});

Deno.test("maps duplicate and guarded database outcomes safely", () => {
  assertEquals(bookingRequestOutcomeResponse("duplicate"), {
    status: 200,
    body: { ok: true, duplicate: true },
  });
  assertEquals(bookingRequestOutcomeResponse("invalid_service"), {
    status: 400,
    body: { error: "Invalid service" },
  });
  assertEquals(
    bookingRequestOutcomeResponse("profile_unavailable").status,
    409,
  );
  assertEquals(bookingRequestOutcomeResponse("rate_limited_phone").status, 429);
  assertEquals(bookingRequestOutcomeResponse("unknown").status, 500);
});

Deno.test("prefers gateway IP headers over caller-forwarded values", () => {
  const headers = new Headers({
    "cf-connecting-ip": "2001:db8::7",
    "x-forwarded-for": "198.51.100.10, 203.0.113.8",
  });
  assertEquals(bestEffortPlatformIp(headers), "2001:db8::7");
});

Deno.test("uses the right-most valid forwarded address as a fallback", () => {
  const headers = new Headers({
    "x-forwarded-for": "not-an-ip, 198.51.100.10, 203.0.113.8",
  });
  assertEquals(bestEffortPlatformIp(headers), "203.0.113.8");
});
