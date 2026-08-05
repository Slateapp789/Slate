import { createClient } from "@supabase/supabase-js";
import {
  amountToMinor,
  publicStripeError,
  safePlatformFeeMinor,
  stripeRequest,
} from "../_shared/stripe_api.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Json = Record<string, unknown>;

function response(status: number, body: Json) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function stringValue(value: unknown, maxLength = 160) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function requireConfiguredUrl(name: string) {
  const value = Deno.env.get(name) ?? "";
  if (!value.startsWith("https://")) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function accountStatus(account: Json) {
  const requirements = account.requirements as Json | undefined;
  const disabledReason = stringValue(requirements?.disabled_reason, 200);
  const detailsSubmitted = account.details_submitted === true;
  const chargesEnabled = account.charges_enabled === true;
  const payoutsEnabled = account.payouts_enabled === true;
  return {
    detailsSubmitted,
    chargesEnabled,
    payoutsEnabled,
    onboardingStatus: disabledReason
      ? "restricted"
      : chargesEnabled && detailsSubmitted
      ? "ready"
      : "pending",
    requirementsDue: Array.isArray(requirements?.currently_due)
      ? requirements.currently_due.filter((value) => typeof value === "string")
      : [],
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return response(405, { error: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
  const liveMode = stripeSecretKey.startsWith("sk_live_");
  if (
    !supabaseUrl || !anonKey || serviceRoleKey.length < 32 ||
    !stripeSecretKey.startsWith("sk_")
  ) {
    return response(503, { error: "Payments are not configured yet" });
  }
  if (liveMode && Deno.env.get("STRIPE_LIVE_MODE_ALLOWED") !== "true") {
    return response(503, { error: "Live payments require explicit approval" });
  }

  let payload: Json;
  try {
    payload = await req.json();
  } catch (_) {
    return response(400, { error: "Invalid request body" });
  }
  const action = stringValue(payload.action, 48);
  const workspaceId = stringValue(payload.workspaceId, 64);
  if (!isUuid(workspaceId)) {
    return response(400, { error: "Invalid workspace" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  const user = authData.user;
  if (authError || !user) return response(401, { error: "Unauthorized" });

  const { data: member } = await serviceClient
    .from("workspace_members")
    .select("workspace_id")
    .eq("workspace_id", workspaceId)
    .eq("user_id", user.id)
    .maybeSingle();
  if (!member) return response(403, { error: "Workspace access denied" });

  const mode = liveMode ? "live" : "test";

  async function loadPaymentAccount() {
    const { data } = await serviceClient
      .from("workspace_payment_accounts")
      .select("*")
      .eq("workspace_id", workspaceId)
      .maybeSingle();
    return data as Json | null;
  }

  async function ensurePaymentAccount() {
    const existing = await loadPaymentAccount();
    if (existing) {
      if (existing.mode !== mode) {
        throw new Error(
          `Workspace is configured for Stripe ${existing.mode} mode`,
        );
      }
      return existing;
    }
    const account = await stripeRequest<Json>(stripeSecretKey, "/v1/accounts", {
      form: [
        ["type", "express"],
        ["country", "GB"],
        ["capabilities[card_payments][requested]", "true"],
        ["capabilities[transfers][requested]", "true"],
        ["business_profile[product_description]", "Appointment-based services"],
        ["metadata[workloop_workspace_id]", workspaceId],
      ],
      idempotencyKey: `workloop-connect-${mode}-${workspaceId}`,
    });
    const accountId = stringValue(account.id, 80);
    if (!accountId.startsWith("acct_")) {
      throw new Error("Stripe account was not created");
    }
    const status = accountStatus(account);
    const { data, error } = await serviceClient
      .from("workspace_payment_accounts")
      .upsert({
        workspace_id: workspaceId,
        stripe_account_id: accountId,
        mode,
        country: "GB",
        currency: "gbp",
        onboarding_status: status.onboardingStatus,
        details_submitted: status.detailsSubmitted,
        charges_enabled: status.chargesEnabled,
        payouts_enabled: status.payoutsEnabled,
        requirements_due: status.requirementsDue,
        last_synced_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }, { onConflict: "workspace_id" })
      .select()
      .single();
    if (error) throw error;
    return data as Json;
  }

  async function refreshPaymentAccount(accountRow: Json) {
    const accountId = stringValue(accountRow.stripe_account_id, 80);
    const account = await stripeRequest<Json>(
      stripeSecretKey,
      `/v1/accounts/${accountId}`,
    );
    const status = accountStatus(account);
    const { data, error } = await serviceClient
      .from("workspace_payment_accounts")
      .update({
        onboarding_status: status.onboardingStatus,
        details_submitted: status.detailsSubmitted,
        charges_enabled: status.chargesEnabled,
        payouts_enabled: status.payoutsEnabled,
        requirements_due: status.requirementsDue,
        last_synced_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("workspace_id", workspaceId)
      .select()
      .single();
    if (error) throw error;
    return data as Json;
  }

  async function ensureTerminalLocation(accountRow: Json) {
    const current = stringValue(accountRow.terminal_location_id, 80);
    if (current.startsWith("tml_")) return current;
    const [{ data: workspace }, { data: settings }] = await Promise.all([
      serviceClient.from("workspaces").select("name").eq("id", workspaceId)
        .single(),
      serviceClient.from("workspace_settings").select("business_address")
        .eq("workspace_id", workspaceId).maybeSingle(),
    ]);
    const displayName = stringValue(workspace?.name, 80) || "Workloop business";
    const address = stringValue(settings?.business_address, 200);
    const form: Array<[string, string]> = [
      ["display_name", displayName],
      ["address[country]", "GB"],
      ["metadata[workloop_workspace_id]", workspaceId],
    ];
    if (address) form.push(["address[line1]", address]);
    const location = await stripeRequest<Json>(
      stripeSecretKey,
      "/v1/terminal/locations",
      {
        accountId: stringValue(accountRow.stripe_account_id, 80),
        idempotencyKey: `workloop-location-${mode}-${workspaceId}`,
        form,
      },
    );
    const locationId = stringValue(location.id, 80);
    if (!locationId.startsWith("tml_")) {
      throw new Error("Terminal location was not created");
    }
    const { error } = await serviceClient
      .from("workspace_payment_accounts")
      .update({
        terminal_location_id: locationId,
        updated_at: new Date().toISOString(),
      })
      .eq("workspace_id", workspaceId);
    if (error) throw error;
    return locationId;
  }

  async function requireReadyAccount() {
    const refreshed = await refreshPaymentAccount(await ensurePaymentAccount());
    if (refreshed.charges_enabled !== true) {
      throw new Error("Finish Stripe setup before taking a payment");
    }
    return refreshed;
  }

  async function loadInvoice() {
    const invoiceId = stringValue(payload.invoiceId, 64);
    if (!isUuid(invoiceId)) throw new Error("Invalid payment record");
    const { data, error } = await serviceClient
      .from("invoices")
      .select("id, workspace_id, invoice_number, total, amount_paid, status")
      .eq("id", invoiceId)
      .eq("workspace_id", workspaceId)
      .single();
    if (error || !data) throw new Error("Payment record was not found");
    return data as Json;
  }

  function requestedAmountMinor(invoice: Json) {
    const total = amountToMinor(invoice.total);
    const paid = Math.max(0, amountToMinor(invoice.amount_paid) ?? 0);
    if (total === null) {
      throw new Error("Payment amount must be greater than zero");
    }
    const outstanding = Math.max(0, total - paid);
    const requested = Number(payload.amountMinor ?? outstanding);
    if (
      !Number.isSafeInteger(requested) || requested <= 0 ||
      requested > outstanding
    ) {
      throw new Error("Amount must not exceed the outstanding balance");
    }
    return requested;
  }

  try {
    switch (action) {
      case "accountStatus": {
        const existing = await loadPaymentAccount();
        if (!existing) return response(200, { connected: false, mode });
        const refreshed = await refreshPaymentAccount(existing);
        return response(200, {
          connected: true,
          mode,
          onboardingStatus: refreshed.onboarding_status,
          detailsSubmitted: refreshed.details_submitted,
          chargesEnabled: refreshed.charges_enabled,
          payoutsEnabled: refreshed.payouts_enabled,
          requirementsDue: refreshed.requirements_due,
          terminalLocationId: refreshed.terminal_location_id,
        });
      }
      case "createOnboardingLink": {
        const accountRow = await ensurePaymentAccount();
        const link = await stripeRequest<Json>(
          stripeSecretKey,
          "/v1/account_links",
          {
            form: [
              ["account", stringValue(accountRow.stripe_account_id, 80)],
              [
                "refresh_url",
                requireConfiguredUrl("STRIPE_CONNECT_REFRESH_URL"),
              ],
              ["return_url", requireConfiguredUrl("STRIPE_CONNECT_RETURN_URL")],
              ["type", "account_onboarding"],
            ],
          },
        );
        return response(200, { url: link.url, mode });
      }
      case "createDashboardLink": {
        const accountRow = await requireReadyAccount();
        const link = await stripeRequest<Json>(
          stripeSecretKey,
          `/v1/accounts/${
            stringValue(accountRow.stripe_account_id, 80)
          }/login_links`,
          { method: "POST" },
        );
        return response(200, { url: link.url });
      }
      case "createConnectionToken": {
        const accountRow = await requireReadyAccount();
        const locationId = await ensureTerminalLocation(accountRow);
        const token = await stripeRequest<Json>(
          stripeSecretKey,
          "/v1/terminal/connection_tokens",
          {
            accountId: stringValue(accountRow.stripe_account_id, 80),
            form: [["location", locationId]],
          },
        );
        return response(200, { secret: token.secret, locationId });
      }
      case "createTerminalPaymentIntent": {
        const accountRow = await requireReadyAccount();
        const invoice = await loadInvoice();
        const amountMinor = requestedAmountMinor(invoice);
        const idempotencyKey = stringValue(payload.idempotencyKey, 128);
        if (idempotencyKey.length < 16) {
          throw new Error("Invalid payment request");
        }
        const { data: existing } = await serviceClient
          .from("payment_transactions")
          .select("id, stripe_payment_intent_id, status")
          .eq("workspace_id", workspaceId)
          .eq("idempotency_key", idempotencyKey)
          .maybeSingle();
        if (existing) {
          const existingIntentId = stringValue(
            existing.stripe_payment_intent_id,
            100,
          );
          const existingIntent = await stripeRequest<Json>(
            stripeSecretKey,
            `/v1/payment_intents/${existingIntentId}`,
            { accountId: stringValue(accountRow.stripe_account_id, 80) },
          );
          return response(200, {
            transaction: existing,
            clientSecret: existingIntent.client_secret,
            locationId: await ensureTerminalLocation(accountRow),
            reused: true,
          });
        }
        const feeMinor = safePlatformFeeMinor(amountMinor);
        const form: Array<[string, string]> = [
          ["amount", String(amountMinor)],
          ["currency", "gbp"],
          ["payment_method_types[]", "card_present"],
          ["capture_method", "automatic"],
          [
            "description",
            `Workloop ${stringValue(invoice.invoice_number, 60)}`,
          ],
          ["metadata[workloop_workspace_id]", workspaceId],
          ["metadata[workloop_invoice_id]", stringValue(invoice.id, 64)],
          ["metadata[workloop_collection_method]", "tap_to_pay"],
        ];
        if (feeMinor > 0) {
          form.push(["application_fee_amount", String(feeMinor)]);
        }
        const intent = await stripeRequest<Json>(
          stripeSecretKey,
          "/v1/payment_intents",
          {
            accountId: stringValue(accountRow.stripe_account_id, 80),
            idempotencyKey,
            form,
          },
        );
        const { data: transaction, error } = await serviceClient
          .from("payment_transactions")
          .insert({
            workspace_id: workspaceId,
            invoice_id: invoice.id,
            stripe_account_id: accountRow.stripe_account_id,
            stripe_payment_intent_id: intent.id,
            collection_method: "tap_to_pay",
            status: "pending",
            currency: "gbp",
            amount_minor: amountMinor,
            platform_fee_minor: feeMinor,
            created_by_user_id: user.id,
            idempotency_key: idempotencyKey,
          })
          .select()
          .single();
        if (error) throw error;
        return response(200, {
          transaction,
          clientSecret: intent.client_secret,
          locationId: await ensureTerminalLocation(accountRow),
        });
      }
      case "createPaymentLink": {
        const accountRow = await requireReadyAccount();
        const invoice = await loadInvoice();
        const amountMinor = requestedAmountMinor(invoice);
        const idempotencyKey = stringValue(payload.idempotencyKey, 128);
        if (idempotencyKey.length < 16) {
          throw new Error("Invalid payment request");
        }
        const { data: existing } = await serviceClient
          .from("payment_transactions")
          .select("id, stripe_checkout_session_id, status, metadata")
          .eq("workspace_id", workspaceId)
          .eq("idempotency_key", idempotencyKey)
          .maybeSingle();
        if (existing) {
          return response(200, {
            transaction: existing,
            url: (existing.metadata as Json | null)?.checkout_url,
            reused: true,
          });
        }
        const feeMinor = safePlatformFeeMinor(amountMinor);
        const form: Array<[string, string]> = [
          ["mode", "payment"],
          ["success_url", requireConfiguredUrl("STRIPE_CHECKOUT_SUCCESS_URL")],
          ["cancel_url", requireConfiguredUrl("STRIPE_CHECKOUT_CANCEL_URL")],
          ["client_reference_id", stringValue(invoice.id, 64)],
          ["line_items[0][quantity]", "1"],
          ["line_items[0][price_data][currency]", "gbp"],
          ["line_items[0][price_data][unit_amount]", String(amountMinor)],
          [
            "line_items[0][price_data][product_data][name]",
            `Payment ${stringValue(invoice.invoice_number, 60)}`,
          ],
          ["payment_intent_data[metadata][workloop_workspace_id]", workspaceId],
          [
            "payment_intent_data[metadata][workloop_invoice_id]",
            stringValue(invoice.id, 64),
          ],
          [
            "payment_intent_data[metadata][workloop_collection_method]",
            "payment_link",
          ],
          ["metadata[workloop_workspace_id]", workspaceId],
          ["metadata[workloop_invoice_id]", stringValue(invoice.id, 64)],
        ];
        if (feeMinor > 0) {
          form.push([
            "payment_intent_data[application_fee_amount]",
            String(feeMinor),
          ]);
        }
        const session = await stripeRequest<Json>(
          stripeSecretKey,
          "/v1/checkout/sessions",
          {
            accountId: stringValue(accountRow.stripe_account_id, 80),
            idempotencyKey,
            form,
          },
        );
        const { data: transaction, error } = await serviceClient
          .from("payment_transactions")
          .insert({
            workspace_id: workspaceId,
            invoice_id: invoice.id,
            stripe_account_id: accountRow.stripe_account_id,
            stripe_checkout_session_id: session.id,
            collection_method: "payment_link",
            status: "pending",
            currency: "gbp",
            amount_minor: amountMinor,
            platform_fee_minor: feeMinor,
            created_by_user_id: user.id,
            idempotency_key: idempotencyKey,
            metadata: { checkout_url: session.url },
          })
          .select()
          .single();
        if (error) throw error;
        return response(200, { transaction, url: session.url });
      }
      case "refund": {
        const accountRow = await requireReadyAccount();
        const transactionId = stringValue(payload.transactionId, 64);
        if (!isUuid(transactionId)) throw new Error("Invalid transaction");
        const { data: transaction, error: transactionError } =
          await serviceClient
            .from("payment_transactions")
            .select("*")
            .eq("id", transactionId)
            .eq("workspace_id", workspaceId)
            .single();
        if (transactionError || !transaction) {
          throw new Error("Transaction was not found");
        }
        const remaining = Number(transaction.amount_minor) -
          Number(transaction.amount_refunded_minor);
        const requested = payload.amountMinor == null
          ? remaining
          : Number(payload.amountMinor);
        if (
          !Number.isSafeInteger(requested) || requested <= 0 ||
          requested > remaining
        ) {
          throw new Error("Refund amount is outside the refundable balance");
        }
        const intentId = stringValue(transaction.stripe_payment_intent_id, 100);
        if (!intentId.startsWith("pi_")) {
          throw new Error("Payment is not ready to refund");
        }
        const idempotencyKey = stringValue(payload.idempotencyKey, 128);
        if (idempotencyKey.length < 16) {
          throw new Error("Invalid refund request");
        }
        const refund = await stripeRequest<Json>(
          stripeSecretKey,
          "/v1/refunds",
          {
            accountId: stringValue(accountRow.stripe_account_id, 80),
            idempotencyKey,
            form: [
              ["payment_intent", intentId],
              ["amount", String(requested)],
              ["metadata[workloop_workspace_id]", workspaceId],
              ["metadata[workloop_transaction_id]", transactionId],
            ],
          },
        );
        const refundStatus = refund.status === "succeeded"
          ? "succeeded"
          : "pending";
        const { error: refundError } = await serviceClient.from(
          "payment_refunds",
        ).upsert({
          workspace_id: workspaceId,
          transaction_id: transactionId,
          stripe_refund_id: refund.id,
          amount_minor: requested,
          status: refundStatus,
          created_by_user_id: user.id,
          updated_at: new Date().toISOString(),
        }, { onConflict: "stripe_refund_id" });
        if (refundError) throw refundError;
        if (refundStatus === "succeeded") {
          const refunded = Number(transaction.amount_refunded_minor) +
            requested;
          const { error } = await serviceClient.from("payment_transactions")
            .update({
              amount_refunded_minor: refunded,
              status: refunded >= Number(transaction.amount_minor)
                ? "refunded"
                : "partially_refunded",
              updated_at: new Date().toISOString(),
            }).eq("id", transactionId);
          if (error) throw error;
        }
        return response(200, { refundId: refund.id, status: refundStatus });
      }
      default:
        return response(400, { error: "Unsupported payment action" });
    }
  } catch (error) {
    console.error("stripe_payment_action_failed", {
      action,
      workspaceId,
      message: error instanceof Error ? error.message : "unknown",
    });
    const safe = publicStripeError(error);
    return response(safe.status, { error: safe.message, code: safe.code });
  }
});
