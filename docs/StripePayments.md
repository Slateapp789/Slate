# Stripe Payments

## Product contract

Workloop collects card payments for appointment-based services through Stripe
Connect. Each Workloop business connects its own Accounts v2 merchant account
with full Stripe Dashboard access and is the merchant of record. Charges are
created directly on that connected account.
Stripe processing, refund, dispute, and payout responsibility therefore stays
with the connected business.

Workloop's platform fee is disabled by default and is set to `0` basis points.
It must not be enabled without an explicit commercial and product decision.

The initial market and currency are the United Kingdom and GBP.

## Supported flows

- Stripe-hosted connected-account onboarding and full Stripe Dashboard access.
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
WORKLOOP_PAYMENTS_BETA_ENABLED=false
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

Deployment status on 2026-08-05: steps 1-3 are complete on the Workloop
Supabase project in Stripe test mode. `stripe-payments` v2 and
`stripe-webhook` v2 are active. Retry hardening is deployed: one logical
payment/refund operation retains one key, failed or stale webhook work can be
reclaimed, completed events remain final, and succeeded refunds are summed for
reconciliation. Private payment/workflow ledgers have RLS, explicit client-deny
policies, and no client DML grants. The live transaction-wrapped 47-assertion
schema and 14-assertion isolation scripts reached their final successful checks;
this is not a clean replay. Platform fees are disabled, live Stripe keys are
blocked, and no real payment has been attempted.

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

## 2026-08-11 beta-readiness update

- `stripe-payments` v8 is active with JWT verification enabled. The live Stripe
  credential and explicit server-side live-mode approval are active after a
  supervised cutover. Platform-profile failures return the stable
  `platform_configuration_required` code without leaking Stripe dashboard URLs;
  Flutter converts Function failures into calm, actionable inline states.
- The first live retry proved Stripe rejects the deprecated Accounts v1
  `type=express` creation path for this platform's selected responsibilities.
  Account creation and hosted onboarding now use Accounts v2 with the Merchant
  configuration, direct charges, full Dashboard access, Stripe-collected fees
  and Stripe loss liability. An authenticated app retry created the first live
  v2 merchant account for the intended production workspace. It remains pending
  hosted onboarding with charges and payouts disabled.
- Tap to Pay can send a Stripe email receipt when the customer supplies an
  address. Workloop also exposes the completed Stripe receipt, system sharing
  for payment links, a copy fallback, and clearer processing/refund states.
- Stripe Terminal is pinned to 5.7 on iOS and Android. The Android native bridge
  compiles against the 5.7 locale contract; the iOS 5.7 pod resolves.
- Apple Sign in is enabled for `com.ismaeel.workloop`. The Tap to Pay entitlement
  request is submitted but not yet approved, so the proximity-reader entitlement
  must remain absent from `Runner.entitlements`.
- Stripe confirms business and platform identity verification complete, and the
  public `@workloopapp` profile is active. The direct-charge Connect model is
  selected and the Connect Platform Agreement is confirmed.
- Setup return/expiry and Checkout success/cancellation pages are implemented
  and validated in the Workloop website. Hosted version 5 is deployed and all
  four production routes return HTTP 200.
- The production connected-account webhook is active, and its signing secret
  plus all four public handoff URLs are stored in Supabase. The live Stripe API
  key is installed and `STRIPE_LIVE_MODE_ALLOWED=true` is active.
- The approved cleanup removed one test account, two non-succeeded test
  transactions, 18 test webhook events and the legacy account pointer. No live
  account, transaction, refund or webhook row existed at cutover.
- The credential returned HTTP 200 for the expected Stripe platform account,
  with charges and payouts enabled. The payment function now reaches its HTTP
  401 authentication boundary instead of the HTTP 503 live-mode block.
- Stripe records the owner's negative-balance liability and ongoing
  seller-compliance acknowledgements as completed on 12 August 2026. The first
  live connected account exists and is pending hosted onboarding; no live charge,
  refund or webhook has been created.
- Xcode signing is connected. Signed profile and App Store IPA builds succeed;
  the exported IPA includes `beta-reports-active` and disables debug attachment.
- The next operational gate is live connected-account onboarding followed by
  one tightly bounded payment and full refund. Tap to Pay remains separately
  blocked until Apple grants the required entitlement.

## 2026-08-12 beta boundary

Live configuration is not the same as an operational beta payment path. The
first production merchant is still pending hosted onboarding, charges and
payouts are disabled for that account, and no live charge, refund or confirming
webhook has been recorded. Do not enable payment collection for beta customers
until onboarding, account-status webhook reconciliation, payment-link success
and cancellation, receipt delivery, full refund and interrupted-network retry
pass on the exact candidate. Run one bounded live payment/full refund only with
the owner's explicit approval immediately beforehand.

Before producing any signed store artifact, run:

```bash
RUN_SIGNED_BUILDS=true RELEASE_EXPECTED_SHA=<reviewed-full-commit-sha> scripts/qa_all.sh
```

The signed-build path must see a completely clean tracked/untracked worktree,
refuses stale target AAB/IPA files, and records the exact commit, app/Flutter
versions, and each new artifact's size and SHA-256 in `build/release/`. The
current in-progress worktree is not an eligible candidate. This QA remediation
did not deploy a function, change a secret, onboard a merchant, move money,
upload a build or alter provider state.
