export const STRIPE_API_VERSION = "2026-07-29.dahlia";

export class StripeApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code?: string,
  ) {
    super(message);
  }
}

type StripeRequestOptions = {
  method?: "GET" | "POST";
  accountId?: string;
  idempotencyKey?: string;
  form?: Array<[string, string]>;
  json?: unknown;
};

export async function stripeRequest<T>(
  secretKey: string,
  path: string,
  options: StripeRequestOptions = {},
): Promise<T> {
  const headers = new Headers({
    Authorization: `Bearer ${secretKey}`,
    "Stripe-Version": STRIPE_API_VERSION,
  });
  if (options.accountId) headers.set("Stripe-Account", options.accountId);
  if (options.idempotencyKey) {
    headers.set("Idempotency-Key", options.idempotencyKey);
  }

  if (options.form && options.json !== undefined) {
    throw new Error("Stripe requests cannot contain both form and JSON bodies");
  }

  let body: URLSearchParams | string | undefined;
  if (options.form) {
    body = new URLSearchParams();
    for (const [key, value] of options.form) body.append(key, value);
    headers.set("Content-Type", "application/x-www-form-urlencoded");
  } else if (options.json !== undefined) {
    body = JSON.stringify(options.json);
    headers.set("Content-Type", "application/json");
  }

  const response = await fetch(`https://api.stripe.com${path}`, {
    method: options.method ?? (body ? "POST" : "GET"),
    headers,
    body,
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const stripeError = payload?.error ?? {};
    throw new StripeApiError(
      typeof stripeError.message === "string"
        ? stripeError.message
        : "Stripe could not complete the request",
      response.status,
      typeof stripeError.code === "string" ? stripeError.code : undefined,
    );
  }
  return payload as T;
}

export function amountToMinor(value: unknown): number | null {
  const amount = typeof value === "number"
    ? value
    : Number.parseFloat(String(value ?? ""));
  if (!Number.isFinite(amount) || amount <= 0) return null;
  const minor = Math.round((amount + Number.EPSILON) * 100);
  return Number.isSafeInteger(minor) && minor > 0 ? minor : null;
}

export function safePlatformFeeMinor(amountMinor: number): number {
  const configured = Number.parseInt(
    Deno.env.get("WORKLOOP_PLATFORM_FEE_BPS") ?? "0",
    10,
  );
  const enabled = Deno.env.get("WORKLOOP_PLATFORM_FEE_ENABLED") === "true";
  if (!enabled || !Number.isInteger(configured) || configured <= 0) return 0;
  if (configured > 10_000) {
    throw new Error("Invalid platform fee configuration");
  }
  return Math.floor(amountMinor * configured / 10_000);
}

function bytesToHex(bytes: ArrayBuffer) {
  return Array.from(new Uint8Array(bytes))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

export async function verifyStripeSignature(
  payload: string,
  signatureHeader: string,
  secret: string,
  nowSeconds = Math.floor(Date.now() / 1000),
  toleranceSeconds = 300,
) {
  const parts = signatureHeader.split(",").map((part) => part.trim());
  const timestamp = Number.parseInt(
    parts.find((part) => part.startsWith("t="))?.slice(2) ?? "",
    10,
  );
  const signatures = parts
    .filter((part) => part.startsWith("v1="))
    .map((part) => part.slice(3));
  if (!Number.isFinite(timestamp) || signatures.length === 0) return false;
  if (Math.abs(nowSeconds - timestamp) > toleranceSeconds) return false;

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
  const expected = bytesToHex(digest);
  return signatures.some((signature) => constantTimeEqual(signature, expected));
}

export function publicStripeError(error: unknown) {
  if (error instanceof StripeApiError) {
    const normalizedMessage = error.message.toLowerCase();
    if (
      normalizedMessage.includes("responsibilities of managing losses") ||
      normalizedMessage.includes("/settings/connect/platform-profile")
    ) {
      return {
        status: 503,
        message: "Payment setup is being finalised. Please try again shortly.",
        code: "platform_configuration_required",
      };
    }
    return {
      status: error.status >= 400 && error.status < 500 ? 400 : 502,
      message: error.message,
      code: error.code,
    };
  }
  return {
    status: 500,
    message: "Payment service could not complete the request",
  };
}
