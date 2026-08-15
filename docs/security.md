# Workloop Security Notes

## Local Configuration

Workloop reads Supabase client configuration from Dart defines:

```bash
flutter run --dart-define-from-file=.env
```

The local `.env` file is ignored by git. Keep `.env.example` committed so new environments know which keys are required.

Required values:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-supabase-publishable-key
```

Google Places is called only by the authenticated `places-address-search` Edge
Function. Store `GOOGLE_PLACES_API_KEY` in Supabase Edge Function secrets and
restrict it to Places API (New). Never add that key to Flutter `.env`, source
code, or a mobile application bundle. See `docs/GooglePlacesSetup.md`.

The Supabase anon/publishable key is not a server secret. It is expected to be present in client apps, but database safety depends on correct Supabase Row Level Security policies. Never put a `service_role` key or any other privileged backend secret in Flutter code, `.env`, or mobile app bundles.

The public booking/profile Edge Functions remain deployed with JWT verification enabled. The managed Supabase gateway was verified on 2026-08-11 to accept the project's publishable key for the public profile boundary. The legacy anon key remains supported only as a temporary client fallback while existing installations are migrated; the service role key only lives in Supabase Edge Function secrets.

## Current Public Boundary

- Anonymous users do not read `business_profiles`, `services`, or `booking_requests` directly.
- Public profile reads go through the `get-public-profile` Edge Function, which returns only the safe public projection.
- Public booking requests go through the `create-booking-request` Edge Function, which validates handle/service ownership, forces `pending` status, applies length limits, rate-limits by source hash and phone, and creates the owner notification server-side.
- Public launch-interest submissions go through the `join-waitlist` Edge
  Function. The function validates and normalizes the address, handles a
  honeypot without disclosure, hashes the normalized email with an Edge-only
  salt for bounded rate limiting, and invokes a service-only RPC. The private
  waitlist table has no `anon` or `authenticated` grants and duplicate
  responses do not reveal whether an email already exists.
- New public booking requests require a normalized email. Owner confirmation
  enters the authenticated `confirm-booking-request` Edge boundary while the
  database workflow remains authoritative for MFA, tenancy, idempotency and
  booking conflicts. Confirmation commits a private email outbox intent in the
  same transaction; provider delivery cannot roll back a confirmed booking.
- Confirmation mail reuses Resend with Edge-only `RESEND_API_KEY` and
  `BOOKING_CONFIRMATION_EMAIL_FROM` secrets. The protected scheduled drain also
  requires `BOOKING_CONFIRMATION_DRAIN_TOKEN`. Never put those values in
  Flutter, a migration, a public schema or client environment.
- Deploy only `drain-booking-confirmation-emails` with gateway JWT verification
  disabled and schedule a POST every minute with its 32+ character
  `x-workloop-drain-token`. All other authenticated Edge boundaries retain JWT
  verification. The worker fails closed when its token is missing or short.
- The sender uses `booking-request-confirmed/<outbox-id>` as the provider
  idempotency key, never logs recipient/body data, recovers stale leases, and
  stops after eight attempts or 24 hours. Terminal failures require operations
  review rather than an unbounded late resend.
- Before beta, create an external scheduler that sends `POST
  https://<project-ref>.supabase.co/functions/v1/drain-booking-confirmation-emails`
  every minute with `x-workloop-drain-token`; store the token only in the
  scheduler and Edge secrets. Alert when any row is `failed`, when pending rows
  are older than five minutes, or when the oldest due row continues ageing.
  Exercise the scheduler and alert path on disposable staging before production
  promotion. This is an operational release gate, not completed by migration or
  function deployment alone.
- Workspace data access remains gated by RLS policies scoped to authenticated workspace members.

## Account Deletion Boundary

- The app no longer writes deletion requests directly to the database.
- Deletion requests go through the `request-account-deletion` Edge Function,
  which verifies the signed-in user is the workspace's sole member before
  creating or refreshing an open request.
- Destructive completion goes through the `complete-account-deletion` Edge
  Function. It revalidates sole ownership before claiming the request, deletes
  the workspace rows through cascade, deletes the Supabase Auth user through
  the admin API, and writes a non-identifying audit row with a hashed email.
- `complete-account-deletion` requires an `ACCOUNT_DELETION_ADMIN_TOKEN` Edge Function secret. Do not put this token in Flutter, `.env`, docs, commits, screenshots, or logs.
- `account_deletion_audit` has RLS enabled with an explicit deny-all client policy. It is service-role/admin-only.

## Immediate Security Priorities

- Keep the verified `auth@workloop.uk` Resend/Supabase SMTP path monitored and
  complete one fresh external signup before inviting the wider beta cohort.
- Google OAuth and native Apple sign-in are enabled. Keep Google in testing
  mode until the consent-screen domain, policies and external cohort are ready,
  and record an existing-email identity-linking test before public launch.
- Re-check that the next scheduled Pro database backup is created. Point-in-time
  recovery is a separately billed add-on and has not been enabled.
- Keep all workspace-scoped queries filtered by the active workspace.
- Set `ACCOUNT_DELETION_ADMIN_TOKEN` in Supabase Edge Function secrets before using account deletion completion.
- Consider CAPTCHA only with a native flow that preserves accessibility and does
  not leak a provider secret into the app.

## 2026-08-11 Auth and Database Hardening

- Email confirmation is required. Passwords require at least 12 characters with
  uppercase, lowercase, number and symbol classes, and breached passwords are
  rejected by Supabase Auth.
- TOTP authenticator enrollment is available in Account settings. Users who
  enroll a verified factor must present an AAL2 session before any authenticated
  Data API table access; unenrolled accounts retain AAL1 during rollout.
- Session lifetime is capped at 30 days with a 7-day inactivity timeout. Refresh
  token replay detection remains enabled and access tokens retain the recommended
  one-hour lifetime.
- All 22 authenticated public tables have a restrictive MFA policy. Trigger-only
  functions are no longer executable as client RPCs, and default function execute
  privileges are revoked until a migration grants them deliberately.
- Direct Postgres connections require SSL. The live Supabase security advisor
  reported no findings after migration and configuration verification.

## 2026-08-12 Release Security Evidence Boundary

- Android `key.properties`, `.jks` and `.keystore` files are ignored at the
  expected Android project/app paths. `scripts/qa_release_candidate.sh` also
  refuses any matching file already tracked by Git.
- The signed-build boundary fails on any tracked or untracked worktree entry,
  tracked Android signing material, or stale target AAB/IPA. It optionally
  verifies `RELEASE_EXPECTED_SHA`, records the resolved commit, app and Flutter
  versions before building, then records each new artifact's size and SHA-256.
- The repository authors 51 schema/security, 16 RLS-isolation and 15
  privileged-MFA/payment-retention pgTAP checks, but no clean replay/pass was
  produced in this audit because Docker and the Supabase CLI are unavailable.
  Treat 82 as an authored count, not a pass.
- The guarded two-user SDK harness covers cross-tenant read/insert/update/delete
  attempts for contacts, services, appointments, invoices and line items,
  expenses, tasks and checklists, notes, notifications, booking requests, push
  tokens and calendar-sync accounts. It refuses writes without explicit
  staging credentials and has not yet passed against disposable staging.
- Leaked-password protection, strong password rules, bounded sessions and
  opt-in MFA enforcement are configured. External fresh signup/confirmation,
  recovery/password-change, identity linking, deletion completion and deployed
  abuse controls remain dynamic release evidence, not configuration claims.

## 2026-08-13 exact-tag security evidence

- The isolated local stack rebuilt all 52 migrations from empty and passed
  83/83 pgTAP assertions across schema/grants, tenant isolation and privileged
  MFA/payment-retention boundaries. Database lint reported no warning-level
  findings.
- All 23 public and four private local application tables have RLS. Anonymous
  application DML and client private-table DML are absent. Local Data API tests
  denied anonymous reads, non-member reads, cross-tenant inserts, deletion-audit
  reads and `app_private` exposure.
- Local GoTrue/Mailpit tests passed confirmation, sign-in, recovery/password
  replacement, refresh-token revocation, TOTP enrollment/challenge and AAL2
  enforcement. These do not prove external SMTP, Apple/Google linking or
  physical-device restart/expiry behaviour.
- Deno format/lint/type checks and 32/32 Edge tests pass. Candidate payments
  fail closed unless `WORKLOOP_PAYMENTS_BETA_ENABLED=true`; the webhook remains
  intentionally ungated for signed reconciliation.
- Read-only production inspection remains materially behind candidate source:
  privileged workflow MFA, payment gate, webhook retention/scrubbing and Stripe
  account offboarding are not live. Do not use blanket `supabase db push`
  because live migration timestamps diverge from local history.
- Production promotion must first be rehearsed on a disposable live-derived
  branch, with the missing booking/contact hardening applied before the
  privileged MFA/payment-retention migration. Production changes remain
  unauthorised in this evidence run.
