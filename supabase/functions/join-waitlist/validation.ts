export function normalizeWaitlistEmail(value: unknown) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

export function isValidWaitlistEmail(value: string) {
  return value.length >= 3 && value.length <= 254 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

export function waitlistSource(value: unknown) {
  if (typeof value !== "string") return "website";
  const source = value.trim().toLowerCase();
  return /^[a-z0-9_-]{1,40}$/.test(source) ? source : "website";
}

export function waitlistOutcomeResponse(outcome: unknown) {
  if (outcome === "created" || outcome === "duplicate") {
    return { status: 200, body: { ok: true } };
  }
  if (outcome === "rate_limited") {
    return {
      status: 429,
      body: { error: "Too many requests. Please try again later." },
    };
  }
  return { status: 500, body: { error: "Could not join the waitlist" } };
}
