import {
  isValidWaitlistEmail,
  normalizeWaitlistEmail,
  waitlistOutcomeResponse,
  waitlistSource,
} from "./validation.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("normalises waitlist email without truncating it", () => {
  assertEquals(normalizeWaitlistEmail("  ADA@Example.COM "), "ada@example.com");
  assertEquals(normalizeWaitlistEmail(null), "");
});

Deno.test("validates waitlist email boundaries and header injection", () => {
  assertEquals(isValidWaitlistEmail("ada@example.com"), true);
  assertEquals(isValidWaitlistEmail("ada@localhost"), false);
  assertEquals(
    isValidWaitlistEmail("ada@example.com\r\nBcc:x@example.com"),
    false,
  );
  assertEquals(isValidWaitlistEmail(`${"a".repeat(242)}@example.com`), true);
  assertEquals(isValidWaitlistEmail(`${"a".repeat(243)}@example.com`), false);
});

Deno.test("allows only bounded campaign source labels", () => {
  assertEquals(waitlistSource(" Early-Access "), "early-access");
  assertEquals(waitlistSource("../../admin"), "website");
  assertEquals(waitlistSource(null), "website");
});

Deno.test("maps join outcomes without disclosing duplicate addresses", () => {
  assertEquals(waitlistOutcomeResponse("created"), {
    status: 200,
    body: { ok: true },
  });
  assertEquals(waitlistOutcomeResponse("duplicate"), {
    status: 200,
    body: { ok: true },
  });
  assertEquals(waitlistOutcomeResponse("rate_limited").status, 429);
  assertEquals(waitlistOutcomeResponse("other").status, 500);
});
