# Stripe Payments

## Product contract

Workloop collects card payments for appointment-based services through Stripe
Connect. Each Workloop business connects its own Stripe Express account and is
the merchant of record. Charges are created directly on that connected account.
Stripe processing, refund, dispute, and payout responsibility therefore stays
with the connected business.

Workloop's platform fee is disabled by default and is set to `0` basis points.
It must not be enabled without an explicit commercial and product decision.

The initial market and currency are the United Kingdom and GBP.

## Supported flows

- Stripe-hosted connected-account onboarding and Express dashboard access.
- Tap to Pay on a compatible iPhone or Android phone using Stripe Terminal.
- Stripe Checkout payment links copied from an outstanding Money item.
- Full or partial refunds against provider-backed Money items.
- Signed, idempotent connected-account webhooks for payment, refund, dispute,
  Checkout Session, and account-status changes.
- Atomic reconciliation into the existing `invoices.amount_paid` Money model.

## Security boundaries

- Stripe secret and webhook signing keys exist only in Supabase secrets.
- The Flutter app receives only short-lived Terminal connection tokens and
  PaymentIntent client secrets for an active collection attempt.
- Connected-account, transaction, and refund rows are read-only to authenticated
  clients and isolated by workspace RLS. All writes use the service role in
  authenticated or signed Edge Functions.
- `app_private.stripe_webhook_events` rejects duplicate event processing.
- Provider-backed payment rows cannot be deleted while their transaction ledger
  exists. Manual edits cannot reduce a Money total or amount received below the
  Stripe-collected amount.
- `STRIPE_LIVE_MODE_ALLOWED=false` is a server-side production kill switch.

## Required Supabase secrets

Configure these in the staging/test project first:

```text
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECT_REFRESH_URL=https://<workloop-domain>/payments/connect/refresh
STRIPE_CONNECT_RETURN_URL=https://<workloop-domain>/payments/connect/return
STRIPE_CHECKOUT_SUCCESS_URL=https://<workloop-domain>/payments/success
STRIPE_CHECKOUT_CANCEL_URL=https://<workloop-domain>/payments/cancel
WORKLOOP_PLATFORM_FEE_BPS=0
WORKLOOP_PLATFORM_FEE_ENABLED=false
STRIPE_LIVE_MODE_ALLOWED=false
```

The webhook endpoint must receive events for connected accounts. Its URL is:

```text
https://<supabase-project-ref>.supabase.co/functions/v1/stripe-webhook
```

Deploy `stripe-payments` with JWT verification enabled. Deploy
`stripe-webhook` with platform JWT verification disabled because it performs
its own raw-body Stripe signature verification.

## Apple activation

The first-party Stripe Terminal SDK is integrated, but production Tap to Pay on
iPhone requires Apple to grant both development and distribution proximity
reader entitlements for `com.ismaeel.workloop`. After approval, copy
`ios/Runner/RunnerTapToPay.entitlements.example` to the production entitlements
file and set `CODE_SIGN_ENTITLEMENTS` on the Runner target. Complete App Review
using Apple's Tap to Pay guidance. Do not wire the entitlement before it is
present in the signing profile.

Each connected business must also accept Apple's Tap to Pay terms using the
Apple ID that represents that business.

## Device support

- Workloop now targets iOS 15+ because Stripe Terminal 5.x requires it. Tap to
  Pay requires a compatible iPhone and a currently supported iOS release.
- Workloop now targets Android API 26+ because Stripe Terminal 5.x requires it.
  Tap to Pay requires Android 13+, NFC, Google Mobile Services, a supported
  hardware keystore, a recent security update, and a non-rooted production
  device with developer options disabled.
- Debug builds use Stripe's simulated Android reader. Real Android Tap to Pay
  requires a non-debuggable signed build.

## Release sequence

Deployment status on 2026-08-04: steps 1-3 are complete on the Workloop
Supabase project in Stripe test mode. Both migrations and both Edge Functions
are active, the connected-account webhook listens to the documented 19 events,
RLS/security pgTAP checks pass, platform fees are disabled, and live Stripe
keys are blocked. No real payment has been attempted.

1. Apply `20260804090000_stripe_connect_payments.sql` to an isolated branch or
   staging project and run the database tests and advisors.
2. Set test-mode secrets and deploy both Edge Functions.
3. Create a Stripe Connect test webhook for connected accounts using API version
   `2026-07-29.dahlia` and store its signing secret.
4. Complete one test connected-account onboarding flow.
5. Verify simulated Terminal collection, Checkout link success/cancel, duplicate
   webhooks, full and partial refunds, failed payments, disputes, and recovery.
6. Verify on supported physical iPhone and Android devices.
7. Obtain the Apple entitlements and complete App Review.
8. Repeat in live mode only after explicit go-live approval. Never reuse test
   account IDs, webhook secrets, transactions, or idempotency keys in live mode.
