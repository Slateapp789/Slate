const PAYMENTS_BETA_ENV = "WORKLOOP_PAYMENTS_BETA_ENABLED";

type EnvironmentReader = (name: string) => string | undefined;

// Server-side and default-off by design: an old or modified client cannot
// bypass this boundary. Enable only after the beta payment cohort is approved
// by setting WORKLOOP_PAYMENTS_BETA_ENABLED=true on the Edge runtime.
export function paymentsBetaEnabled(
  readEnvironment: EnvironmentReader = (name) => Deno.env.get(name),
) {
  return readEnvironment(PAYMENTS_BETA_ENV) === "true";
}
