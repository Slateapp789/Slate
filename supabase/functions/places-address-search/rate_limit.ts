export type PlacesRateLimitBucket = "autocomplete" | "details";

export type PlacesRateLimitResult = {
  allowed: boolean;
  retryAfterSeconds: number;
  remaining: number;
};

export function placesRateLimitBucket(
  action: string,
): PlacesRateLimitBucket | null {
  if (action === "autocomplete" || action === "details") return action;
  return null;
}

export function parsePlacesRateLimitResult(
  value: unknown,
): PlacesRateLimitResult | null {
  const row = Array.isArray(value) ? value[0] : value;
  if (!row || typeof row !== "object") return null;

  const record = row as Record<string, unknown>;
  if (typeof record.allowed !== "boolean") return null;

  const retryAfterSeconds = typeof record.retry_after_seconds === "number"
    ? Math.max(0, Math.floor(record.retry_after_seconds))
    : 0;
  const remaining = typeof record.remaining === "number"
    ? Math.max(0, Math.floor(record.remaining))
    : 0;

  return {
    allowed: record.allowed,
    retryAfterSeconds,
    remaining,
  };
}
