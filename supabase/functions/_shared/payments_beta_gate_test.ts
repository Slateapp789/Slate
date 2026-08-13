import { paymentsBetaEnabled } from "./payments_beta_gate.ts";

Deno.test("payments beta gate is closed unless explicitly enabled", () => {
  const missing = (_name: string) => undefined;
  const falseValue = (_name: string) => "false";
  const differentlyCased = (_name: string) => "TRUE";

  if (paymentsBetaEnabled(missing)) throw new Error("Missing gate must deny");
  if (paymentsBetaEnabled(falseValue)) throw new Error("False gate must deny");
  if (paymentsBetaEnabled(differentlyCased)) {
    throw new Error("Only the explicit literal true may enable payments");
  }
});

Deno.test("payments beta gate accepts the explicit true literal", () => {
  const enabled = (name: string) =>
    name === "WORKLOOP_PAYMENTS_BETA_ENABLED" ? "true" : undefined;

  if (!paymentsBetaEnabled(enabled)) {
    throw new Error("Explicit beta enablement should allow payments");
  }
});
