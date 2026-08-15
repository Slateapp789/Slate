# Workloop Launch Readiness

Last updated: 2026-08-13

This is the release gate for Workloop 1.0 on iOS and Android. “Code ready”
means the repository passes its automated and device checks. “Store ready”
also requires the external accounts, legal details, hosted pages, signing
credentials, and declarations listed below.

## Product release position

Workloop launches as a mobile-first business operating system for solo service
business owners. Its promise is one calm daily loop:

1. See what is happening.
2. See what needs attention.
3. Take the next useful action without switching tools.

Clients, bookings, money, tasks, and notes are connected operating modules, not
separate mini-apps. V1 must not claim real-time calendar sync, automated bank
feeds, operational card collection, or remote push notifications unless those
services are actually connected and verified. Stripe live credentials and the
server-side live-mode switch are configured, but the first merchant is still
pending hosted onboarding and no live charge/refund has been completed. Payment
collection therefore remains release-gated.

## Repository launch gates

| Area | Gate |
| --- | --- |
| Identity | Workloop name, `com.ismaeel.workloop` identifiers, existing `#C1FF72` app icon, Studio indigo native startup |
| Navigation | Today, Clients, Work, Money, Business; Schedule, Tasks, and Notes are retained views inside Work |
| Visual system | Persisted System/Light/Dark appearances; porcelain Light and midnight Dark; Studio indigo actions; bundled Manrope; shared floating-dock and control geometry; reduced-motion handling; semantic labels |
| Core workflows | Auth/onboarding, clients, atomic/idempotent single-booking and task workflows, money, notes, profile/settings, retry-safe imports, one-time calendar import/export, on-device reminders; recurring-series creation is intentionally outside V1 |
| Trust | Workspace export, protected deletion request, in-app privacy/terms, public policy/deletion artifacts |
| Platform | Flutter 3.44.8; iPhone-only portrait scope on iOS 15+; Android portrait, API 36 target/minimum API 26, Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, Java 17; production network permission, no cleartext release traffic, sensitive backup exclusion, iOS/Android recovery link |
| Quality | Formatting, analysis, full tests, Android profile build with 16 KB page alignment, iOS profile build, web release build; current-candidate physical iPhone install and CoreDevice-confirmed launch, recorded separately from interactive workflow QA |
| Automation | Secret-safe CI runs Flutter formatting/analysis/tests, Deno formatting/checks/tests, Gradle-wrapper validation, Android profile and web builds, plus an unsigned iOS profile build on macOS |

The final verification evidence for a release candidate must be appended to
`docs/CurrentState.md`; failures are never waived silently.

## Production backend gate

Connected project:

- Project: `imtbyrvsonzvtddswbtb`
- Region: London (`eu-west-2`)
- Status checked 2026-08-08: active and healthy on Postgres 17.6.1
- Client access is protected by workspace-scoped RLS; the current security
  advisor reports no missing-RLS or RLS-enabled-without-policy finding.
- Anonymous Data API table grants are removed. Authenticated app tables expose
  CRUD only, while deletion request/audit tables remain Edge-only.
- Public profile, booking request, address search, and deletion operations use
  Edge Functions rather than direct public table access.
- Live migration history checked 2026-07-26 includes:
  `20260726000048` transactional task, `20260726000057` Edge rate limits,
  `20260726000102` deletion-request export,
  `20260726000110` reserved public routes, and
  `20260726000118` transactional booking workflows, followed by
  `20260726000520` explicit client-deny policy for the private Edge rate-limit
  ledger. Test-mode Stripe payment storage and reconciliation were added by
  `20260804181440` and its foreign-key indexes by `20260804181648`.
  Retry/RLS hardening followed as `20260805210418`, with explicit private-ledger
  deny policies in `20260805210559`.
- Repository source routes task creation, booking creation, booking-request
  conversion, and booking completion through authenticated, tenant-validating,
  idempotent workflows. Public request and Places source use bounded private
  rate-limit state.
- The last recorded active Edge deployments include `create-booking-request` v9,
  `places-address-search` v9, `get-public-profile` v7,
  `request-account-deletion` v7, `complete-account-deletion` v10,
  `workloop-ai-assistant` v4 and `stripe-payments` v8. Re-read deployed versions
  from the release environment before promotion rather than relying on this
  historical inventory.
  Structural/grant smoke checks passed. The release gate remains open until the
  production-like signed-out, authenticated-workflow, and destructive deletion
  matrix is recorded.
- The historical transaction-wrapped live schema and tenant-isolation scripts
  reached their final 47th and 14th successful assertions. This validated that
  project state without persisting fixtures; it is not a clean database replay.
- A 2026-08-08 read-only grant/RLS refresh found RLS on all 23 public and all
  four private application tables, zero anonymous table grants, zero client
  grants on private tables, and `account_deletion_audit` as the sole public
  table intentionally unavailable to authenticated clients. The security
  advisor reported only leaked-password protection at that time. The 2026-08-11
  hardening record below supersedes that historical advisor state.

Before submission:

- [x] Add `workloop://reset-password` to Supabase Auth redirect URLs.
- [x] Enable Supabase Auth leaked-password protection. The live Auth service
      also enforces the 12-character uppercase/lowercase/number/symbol policy,
      and the security advisor reports no findings.
- [x] Production SMTP, `auth@workloop.uk`, DKIM/SPF/DMARC and one real
      password-recovery delivery are configured and verified.
- [ ] Complete fresh-account confirmation, password change and recovery with an
      address outside the development team before external beta invitations.
- [ ] Review Auth signup/reset rate limits and enable CAPTCHA if public signup
      abuse warrants it.
- [ ] Confirm `GOOGLE_PLACES_API_KEY` is a restricted server key with quotas and
      billing alerts.
- [ ] Set a dedicated booking rate-limit salt (the function securely derives a
      fallback from the Edge-only service secret) and confirm the
      account-deletion admin token is
      set in production secrets.
- [ ] Apply the candidate migration to isolated staging and deploy the candidate
      `create-booking-request` source there. After the full booking/security
      matrix passes, promote the reviewed versions and record the live
      migration/function versions. Existing production functions were not
      changed during this audit.
- [ ] Exercise account deletion end to end with a disposable production-like
      sole-owner account and record the operational result. Confirm a
      multi-member workspace is rejected at both request and completion
      boundaries.
- [ ] Exercise public profile and booking request abuse controls from a
      signed-out device, including honeypot, duplicate request token,
      source/phone limits, invalid service, and recovery after the limit window.
- [ ] Reconcile the candidate migration and changed Edge source with the final
      isolated-staging evidence before production promotion.
- [ ] Preserve the final verified release state in a clean commit/tag before
      store submission.

Do not remove “unused” production indexes solely because a pre-launch database
has little traffic. Reassess them after representative usage exists.

## Verified release-candidate evidence

Completed 2026-07-26:

- Dart formatting clean across 186 files, Flutter analysis clean, and all 249
  Flutter tests passing with 40.10% line coverage.
- Eleven golden tests produced 13 reviewed images and passed again in non-update
  mode. The responsive matrix covered 108 phone/text-scale renders plus keyboard
  safety.
- Deno formatting/lint and all six entry-point type checks are clean; all 19
  Edge tests pass.
- OSV-Scanner 2.4.0 found no known issue in 132 resolved Dart packages. Deno
  and CocoaPods lock formats were not supported by that scanner and remain a
  documented scope limit.
- The signed-out iOS simulator integration smoke passed. iOS simulator debug,
  device profile, and device release compilation passed; the recovery custom
  scheme is registered.
- The current 34.8 MB profile is installed and launched on the physical iPhone;
  CoreDevice confirmed the Workloop process is running.
- Android debug/profile compilation passed. The profile APK passed 16 KB
  `zipalign` and signature verification.
- Web release compilation passed.
- iOS IPA export is blocked by the missing Distribution certificate/profile.
  Android AAB creation fails closed until the production upload keystore is
  configured.
- Clean Supabase replay/82 current pgTAP assertions, authenticated staging E2E, and
  backend load testing were not executed and remain release gates.

Refreshed 2026-07-28 after the final UI/UX refinement:

- Formatting is clean, Flutter analysis reports no issues, and all 285 Flutter
  tests pass. The focused 86-test usability/refinement matrix and the 11-test
  golden suite also pass.
- Development-signed iOS profile and Android profile APK builds pass. Workloop
  launched on the physical iPhone with a discoverable Dart VM Service, and the
  detached Runner process was confirmed on-device.
- Automated checks cover responsive phone layouts, large text, keyboard
  reachability, reduced-motion branches, semantic actions, retry states, and
  critical booking/request/import recovery. They do not replace manual
  VoiceOver, TalkBack, permission, lifecycle, offline, or physical Android QA.
- The 132-case launch-surface matrix found and now protects a small-phone,
  200%-text booking-request overflow. Native iOS and Android startup surfaces
  use the Flutter graphite background, preventing a light flash.
- Thirteen navigation-assist tests protect the native iOS status-bar bridge,
  implicit and visible-screen scroll targeting, shell-tab independence, native
  clean-route back-swipe eligibility and completion, broad top-zone taps,
  simultaneous visible vertical layers, header-action isolation, direct-route
  and retained-workspace back actions, a populated Clients top-zone journey,
  cancelled pointer sequences, and draft-protected edge-swipe behaviour.
- The source-level UI/UX gate is materially stronger; the backend, security,
  store signing, legal hosting, and manual-device blockers below are unchanged.

Refreshed 2026-08-08 after the final completion sweep:

- Formatting is clean across 205 Dart files, analysis reports no issues, all
  340 Flutter tests pass, and coverage is 9,650/19,424 lines (49.68%).
- The protected golden suite passes 19/19 across 23 image files; the signed-out
  iOS simulator journey passes 1/1.
- Deno format/lint, all eight Edge entry-point checks, and 25/25 Deno tests
  pass. Clean local Supabase replay and pgTAP remain blocked by absent Docker.
- iOS profile (70.7 MB), universal Android profile (155.6 MB), Android arm64
  profile (129.4 MB), and web release (43 MB) builds pass. The arm64 APK passes
  16 KB alignment and v2 signature verification; the iOS app passes strict
  local signature verification.
- The exact iOS candidate installed and launched on the paired iPhone after an
  initial locked-device denial; CoreDevice confirmed the running process.
  Install/launch does not replace interactive workflow or accessibility QA.
- Recurring-series creation is removed from V1 rather than left partially
  functional. Historic recurrence data remains readable and data-compatible.

Refreshed 2026-08-10 after Booking page and public-web consolidation:

- Formatting is clean across 206 Dart files, analysis reports no issues, all
  349 Flutter tests pass, and the protected golden suite passes against its
  reviewed updated Home, Tools, Business profile and public booking images.
- The iOS profile build succeeds at 71.0 MB. The exact build installed and
  launched on the paired physical iPhone through CoreDevice.
- Managed Sites version 4 is publicly deployed with production Supabase runtime
  configuration. Live Home, `/:handle`, privacy, terms and deletion requests
  return successfully, and a honeypot booking request reached the Edge boundary
  without creating data.
- The canonical apex and `www` host are attached but await the supplied DNS
  validation/A/CNAME records and SSL activation. Support monitoring, manual
  signed-out submission, legal approval and store gates remain open.

## External launch blockers

These cannot be completed safely from source code alone:

### 1. Brand clearance and store-name reservation

Other current store products use “Workloop” or “WorkLoop,” including products
in adjacent business/productivity categories. Before spending on launch:

- [ ] Run a professional UK and target-market trade-mark clearance search for
      the word mark and logo in the relevant software/SaaS classes.
- [ ] Reserve the final App Store and Play Console listing names.
- [ ] Decide whether the store-facing title should be the more distinctive
      `Workloop: Solo Business OS` while preserving the product name Workloop.

Do not rename the product from an engineering task without an explicit product
decision.

### 2. Public domain and support operation

On 2026-08-10 the public Sites deployment was published at
`https://workloop-os.ismaeelsmiley.chatgpt.site`. It serves customer booking
pages and the exact public legal endpoints below without Workloop or Sites
authentication. A non-persisting honeypot request also reached the production
booking Edge Function and returned its expected accepted response. On
2026-08-11 the owner registered `workloop.uk`, attached the apex and `www`
hostnames, and published the required routing and validation DNS records. TLS
is active on both hosts and the canonical routes respond over HTTPS. Publication
of the saved `workloop.uk` legal, support, current-navigation and payment-data
copy remains pending explicit approval. The deployed 10 August pages still
contain the previous `workloop.app` support identity and navigation wording.

- `/privacy.html`
- `/terms.html`
- `/delete-account.html`

Before submission:

- [x] Deploy the release web artifact and make the hosted legal URLs public and
      accessible without signing in.
- [ ] Publish the current reviewed local legal artifact, then verify the live
      content, dates, support identity and deletion navigation match the app.
- [x] Apply the supplied apex, `www` CNAME, and validation DNS records, then
      prove those exact custom-domain legal and booking URLs over HTTPS.
- [ ] Redirect the apex and `www` hosts consistently.
- [ ] Create and actively monitor `support@workloop.uk`.
- [ ] Replace generic operator wording in the policies with the legal
      controller/business name, contact address, and any company number.
- [ ] Have the privacy policy and terms reviewed for the launch markets.

### 3. Signing and store accounts

- [ ] Create the Android upload key, keep two encrypted backups, and enable Play
      App Signing. Never commit `android/key.properties` or a keystore.
- [ ] Create the Play Console app with package `com.ismaeel.workloop`.
- [x] Connect the Apple Developer team, allow Xcode-managed App Store signing
      for `com.ismaeel.workloop`, accept the required App Store Connect
      agreement, and export the 1.0.0 (1) App Store IPA successfully.
- [ ] Use the same public version on both stores; build numbers may differ but
      must always increase.

### 4. Store declarations and review access

- [ ] Complete Apple App Privacy from the actual data map.
- [ ] Complete Google Play Data safety and the account-deletion URL.
- [ ] Declare contact, calendar, file, and notification permissions accurately,
      including Android's calendar read/write permission pair and Workloop's
      read-only launch behavior.
- [ ] Supply a dedicated review account with realistic, non-personal sample
      data and working public-profile/booking flows.
- [ ] Add review notes explaining why contacts/calendar are optional imports,
      that Money always supports manual operational records, and whether the
      exact submitted build has the default-off Stripe capability enabled.

## Release commands

Run from the repository root:

```bash
source scripts/dev_env.sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test --coverage \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=ci-public-anon-key
deno fmt --check supabase/functions quality/load
deno lint supabase/functions
deno check --config supabase/functions/complete-account-deletion/deno.json supabase/functions/complete-account-deletion/index.ts
deno check --config supabase/functions/create-booking-request/deno.json supabase/functions/create-booking-request/index.ts
deno check --config supabase/functions/get-public-profile/deno.json supabase/functions/get-public-profile/index.ts
deno check --config supabase/functions/places-address-search/deno.json supabase/functions/places-address-search/index.ts
deno check --config supabase/functions/request-account-deletion/deno.json supabase/functions/request-account-deletion/index.ts
deno check supabase/functions/workloop-ai-assistant/index.ts
deno test supabase/functions
scripts/qa_local_supabase.sh
QUALITY_DEVICE_ID=<simulator-or-emulator> scripts/qa_integration.sh
```

`scripts/qa_local_supabase.sh` requires Docker and must pass before promotion.
Run supported source builds with `RUN_BUILDS=true scripts/qa_all.sh`, or use the
individual build commands recorded in
[`docs/testing/TEST_RESULTS.md`](testing/TEST_RESULTS.md). After the Android
profile build, verify native-library packaging with the SDK's
`zipalign -c -P 16 -v 4` check.

For the signed store artifacts:

```bash
RUN_SIGNED_BUILDS=true RELEASE_EXPECTED_SHA=<reviewed-full-commit-sha> scripts/qa_all.sh
```

The signed-build path fails on every tracked or untracked worktree change,
rejects tracked Android signing material and stale target AAB/IPA files,
verifies the expected commit, and records commit/version/toolchain plus each
new artifact's byte size and SHA-256 under `build/release/`. Keep that
provenance beside the candidate artifacts and store-upload record.

The Android release command is expected to fail immediately until a valid
production keystore is configured. Never work around that guard with a debug or
temporary key for a store upload.

## Manual release matrix

Test at minimum:

- Latest public iOS on a physical iPhone.
- Oldest supported iOS or the closest available simulator.
- A current Google Pixel-class Android device.
- A smaller Android phone at large text size.
- Portrait layout on every launch device. iPad is excluded by the iOS target
  family; Android tablet compatibility needs an explicit Play/device decision.
  Landscape must not be implied by store media.
- System, Light, and Dark appearances, reduced motion, VoiceOver, and TalkBack.
- Fresh install, sign-up, password recovery, interrupted onboarding, sign-out,
  returning session, and offline/error recovery.
- Empty, realistic, and high-volume workspaces.
- UK daylight-saving transition and cross-midnight bookings, plus read-only
  rendering of any legacy recurring records.
- Contacts/calendar permission accepted, denied, and later revoked.
- Task and booking reminder permission accepted, denied, later revoked,
  rescheduled after record changes, restored after app/device restart, and
  opened from a notification tap.
- Partial contacts, calendar, CSV, task-text, and note-text imports: retry only
  the failed records and confirm successful records are not duplicated.
- Booking/task workflow retries with a stable idempotency key and a simulated
  mid-request network interruption.
- Workspace export, deletion request, and support contact.

## Release decision

Ship only when every repository gate passes and every external blocker has a
named owner. A feature that is not operationally connected must be described
honestly or removed from the release surface.

## 2026-08-11 Stripe and TestFlight gates

- [x] Deploy authenticated `stripe-payments` v3 in Stripe test mode.
- [x] Verify Flutter analysis, 359 Flutter tests, Stripe Deno checks, Android
      native compilation, and unauthenticated Edge Function rejection.
- [x] Enable Sign in with Apple for the Workloop App ID.
- [x] Enable Supabase breached-password checks, strong password policy, TOTP,
      bounded sessions, refresh-token replay detection, MFA-aware RLS and
      mandatory database SSL; security advisor is clear.
- [x] Create the App Store Connect Workloop record for `com.ismaeel.workloop`
      (Apple app ID `6800472527`).
- [x] Add the Apple Developer account to Xcode, regenerate signing profiles and
      export a valid 34.3 MB App Store/TestFlight IPA.
- [x] Create the automatically distributed `Workloop Internal Beta` TestFlight
      group. Build 1's upload exposed missing camera/photo-library purpose
      strings from the file-import dependency; build 2 includes the fix, passed
      processing, and is attached to the group as `Ready to Submit`.
- [ ] Build 3 is a locally archived and signature-verified owned-domain
      candidate. Its upload was stopped before acceptance at the owner's request;
      App Store Connect still lists only builds 1 and 2. Do not upload another
      build until the remaining app work is complete and the owner explicitly
      approves it.
- [ ] Google OAuth is configured, enabled and redirect-tested for the owner in
      consent-screen testing mode. Test existing-email identity linking and
      publish the consent screen before a wider external cohort.
- [ ] Verified custom SMTP delivered a real Supabase password-recovery email.
      Confirm fresh signup, confirmation and secure password-change delivery
      with an external beta address before invitations begin.
- [ ] Confirm a fresh Pro scheduled backup appears after 8 August 2026. Decide
      separately whether the paid point-in-time recovery add-on is justified.
- [x] Review and submit the Apple Tap to Pay entitlement request.
- [ ] Await Apple approval, then obtain both development and distribution
      entitlement support before adding the proximity-reader entitlement.
- [x] Complete Stripe platform identity verification; the dashboard also
      confirms business verification complete.
- [x] Review and submit the public `@workloopapp` Stripe profile, including the
      public business contact details.
- [x] Confirm the direct-charge Connect model and Stripe Connect Platform
      Agreement in the dashboard.
- [x] Deploy and verify the public payment setup, success and cancellation
      handoff routes; all four production URLs return HTTP 200.
- [x] Configure the production connected-account webhook and store its signing
      secret plus all four public handoff URLs in Supabase.
- [x] Remove the approved test-only Stripe state, install the authenticated live
      Stripe API key and set `STRIPE_LIVE_MODE_ALLOWED=true` during an explicit,
      supervised cutover. The payment tables are empty after cleanup.
- [x] Verify the live credential against the expected Stripe platform account
      and prove the payment function reaches its HTTP 401 authentication
      boundary rather than the HTTP 503 live-mode block.
- [x] Deploy `stripe-payments` v8 so Stripe platform-profile failures return a
      stable, non-sensitive public error; normalize Edge Function failures in
      Flutter and render them with the shared inline error component. The live
      platform's account creation and onboarding path now uses Accounts v2 with
      the Merchant configuration rather than deprecated v1 account types.
- [x] Retry the deployed Accounts v2 onboarding path from the authenticated app
      and verify the live connected-account row. The account is pending hosted
      onboarding with charges and payouts disabled until requirements are met.
- [ ] Complete Stripe-hosted onboarding, refresh Workloop status and verify the
      connected-account webhook before treating collection as operational.
- [x] Owner reviewed and accepted Stripe's negative-balance liability and ongoing
      seller-compliance acknowledgements. These create financial, reserve,
      risk-monitoring and connected-account communication responsibilities;
      Stripe records both as completed on 12 August 2026.
- [ ] Perform a real-device test-mode matrix: onboarding, payment link success
      and cancel, Tap to Pay, receipt delivery, full/partial refund, dispute and
      interrupted-network retry.
- [ ] Perform one tightly bounded live-money smoke payment and refund after all
      preceding gates pass.

## 2026-08-12 release-candidate audit gate

- Local static analysis and all 360 Flutter unit/widget tests passed before this
  documentation/QA remediation. `git diff --check` was also clean.
- The current signed-out iOS simulator integration journey is **red**: on the
  402 x 874 iPhone 17 Pro simulator the Auth mode toggle is below the tappable
  viewport, so the tap misses and the expected Create-account state never
  appears. This is a beta blocker until fixed and rerun on the exact candidate.
- The current database inventory contains 51 schema/security, 16 isolation and
  15 privileged-MFA/payment-retention assertions (82 total). They are authored,
  not passed: Docker, Supabase CLI and
  a clean replay result were unavailable in this local audit.
- The guarded two-account staging test now attempts read, insert, update and
  delete isolation across contacts, services, appointments, invoices and line
  items, expenses, tasks and checklists, notes, notifications, booking requests,
  push tokens and calendar-sync accounts, while recording owner-cleanup rows
  and refusing production/write execution by default. It still needs a passing
  disposable-staging run on the release SHA.
- `scripts/qa_release_candidate.sh` is now the signed-artifact boundary. The
  signed-build path also rejects stale target AAB/IPA files and records the
  size and SHA-256 of each artifact produced after the clean-SHA preflight. The
  present working tree is intentionally dirty with in-progress owner work, so
  that preflight must fail and no signed artifact from this tree is a candidate.
- Build 3 remains locally archived/signature-verified but was not accepted by
  App Store Connect. It also predates current source/backend payment changes and
  must not be uploaded as the beta candidate.

Release position: source confidence is strong enough for continued developer
testing only. A small invitation-only beta should wait for the red Auth journey,
clean replay/82 pgTAP checks, disposable staging E2E/isolation, fresh external
Auth lifecycle, support/legal operation and current signed-artifact provenance.
Physical Android, accessibility, performance/load, crash observability, Stripe
onboarding/payment/refund and full store operation remain public-launch gates.

## 2026-08-12 remediation verification gate

The current local remediation supersedes the failed signed-out Auth result in
the preceding audit section:

- [x] The first-run Create account action is visible without scrolling and the
      signed-out iPhone 17 Pro simulator journey passes.
- [x] Formatting is clean across 220 Dart files, analysis is clean, and all
      371 Flutter unit/widget/golden tests pass with 52.84% line coverage.
- [x] The 27 protected golden scenarios pass after visual review of the
      intentional Auth and Business compact-layout changes.
- [x] Deno formatting/lint, all eight Edge entry-point checks, and 30/30 Deno
      tests pass using Deno 2.9.5.
- [x] Four deterministic data profiles pass in dry-run mode.
- [x] The signed iOS profile build passes at 71.3 MB and strict code-sign
      verification succeeds.
- [x] The same signed profile installs and launches on the paired iPhone 15 Pro
      Max; CoreDevice confirms the running process. Manual workflow and
      VoiceOver coverage remain open.
- [x] The Android profile APK passes at 158.7 MB, 16 KB alignment, and v2
      signature verification. The profile signature is intentionally a debug
      certificate and is not a store credential.
- [x] The web release build passes.
- [ ] Run the clean migration replay and all 82 pgTAP assertions. No local
      Docker, Postgres, or Supabase CLI runtime is available.
- [ ] Run core, public-booking, expanded two-user isolation, Stripe test-mode
      offboarding, and deletion journeys against a disposable non-production
      project. The connected Supabase account exposes production only.
- [ ] Freeze the reviewed work in a clean commit/tag, rerun this gate against
      that SHA, produce a fresh IPA, upload it, and install the TestFlight copy.

Production migrations and Edge Functions were deliberately not changed from a
dirty local tree. The release-candidate preflight exits 78 until every tracked
and untracked change is intentionally resolved.

## 2026-08-13 exact candidate gate

| Gate | Current exact-tag result | Remaining boundary |
| --- | --- | --- |
| Release identity | Clean `81673f6e5f67b11a5c4f2697e51477d95811ab4f`, local `v1.0.0-beta.4`, `1.0.0+4` | Branch/tag are local-only; no exact-SHA hosted CI evidence |
| Flutter | 222 files formatted, analysis clean, 375/375 tests, 52.86% line coverage, protected goldens pass | Automation is not physical/manual workflow proof |
| Edge | Format/lint/type checks pass; 32/32 Deno tests | Candidate functions are not deployed to staging or production |
| Database | Empty local rebuild applies all 52 migrations; 83/83 pgTAP pass; lint clean | Hosted live-derived staging and safe production promotion remain open |
| Auth | Local confirmation, recovery/password update, token revocation and TOTP/AAL2 pass | Fresh external email/provider/linking and restart/expiry evidence remain open |
| Integration | Signed-out simulator journey passes; three staging suites compile and safely skip | Core, isolation, public booking and deletion require hosted staging |
| iOS artifact | Distribution-signed App Store IPA, strict-valid, `1.0.0 (4)`, 33,854,083 bytes, SHA-256 `2dc632e23f5ea00a54df57405d9b675fb8ca33b749310ba4df5c461a0ca3c6fa` | Not uploaded; no TestFlight install/manual VoiceOver matrix |
| Android | Profile APK builds, is 16 KB aligned and v2-signed for QA | No upload key, release AAB, physical Android or TalkBack evidence |
| Payments | Flutter and candidate Edge gates default false | Production Edge is behind candidate; merchant restricted; no payment/refund evidence |
| Public/legal | Live apex, privacy, terms and deletion return 200 and use `support@workloop.uk`; deletion navigation is current | Live 12 August copy trails the tagged fuller copy; controller details, monitoring and legal review remain open |

Verdict: **not ready to upload**. A valid exact-tag IPA exists, but the strict
definition also requires hosted staging, external Auth and manual exact-build
device evidence. The required Supabase preview branch begins at $0.01344/hour
plus metered usage and needs explicit owner approval. Uploading remains a
separate prohibited boundary until final approval.

## 2026-08-13 Build 5 booking-email gate

- [x] New public requests capture a required normalized customer email; legacy
      rows remain nullable and confirmable.
- [x] Booking confirmation and one private outbox intent commit atomically;
      retries cannot duplicate the request, booking or email intent.
- [x] The stored request email is the immutable delivery address during owner
      confirmation; provider content is escaped and uses a fixed verified
      sender plus a stable idempotency key.
- [x] Delivery has stale-lease recovery, capped exponential retry, an
      eight-attempt/24-hour terminal boundary and honest sent/queued/failed UI.
- [x] Local proof passes all 55 migrations, 111/111 pgTAP assertions, database
      lint, 38/38 Deno tests, both new handler type checks, focused Flutter
      tests, the full 383/383 Flutter suite and Flutter analysis.
- [x] An iOS profile build compiles and signs as `1.0.0 (5)` at 71.2 MB and
      passes strict code-sign verification. It is working-tree evidence, not a
      distribution candidate.
- [x] Rehearse all 55 migrations without a blanket production push, then deploy
      `create-booking-request`,
      `confirm-booking-request`, and `drain-booking-confirmation-emails` in that
      order on a disposable preview branch. Production remains unchanged.
- [x] Configure `RESEND_API_KEY`, verified
      `BOOKING_CONFIRMATION_EMAIL_FROM`, and a random 32+ character
      `BOOKING_CONFIRMATION_DRAIN_TOKEN`. Deploy only the drain with
      `--no-verify-jwt`, then schedule its token-authenticated POST every minute.
- [x] In disposable staging, prove a controlled Resend inbox receives one
      correctly timed confirmation after owner acceptance; exercise duplicate
      submission, honeypot, invalid service, atomic conversion and a real
      provider 401/retry/recovery. Resend reports delivered, verified DKIM/SPF,
      and a valid DMARC record.
- [ ] Exercise bounced/suppressed recipients and deletion/export behaviour in
      disposable staging; keep operational bounce monitoring explicit.
- [ ] Monitor terminal failures and oldest pending age, with a documented owner
      response to contact the customer directly.
- [x] Freeze the fully verified `1.0.0+5` source as a new immutable local
      `v1.0.0-beta.5` tag.
- [ ] Build/sign a new distribution IPA from that exact tag, then repeat the
      artifact signature/provenance and TestFlight-install gates.

A metered preview branch was created with owner approval at $0.01344/hour,
rehearsed, cleaned and deleted after evidence capture. Build 4 must not be
reused or retagged for this changed public data and transactional-email
contract. Production promotion and Apple upload remain separate approval
boundaries.

## 2026-08-15 TestFlight distribution status

- [x] Promote the reviewed booking-email schema, functions, secrets and
      minute-by-minute retry worker to production in the rehearsed order.
- [x] Verify production is healthy, current migrations/functions are present,
      the retry job is active, no paid preview branch remains, and payments are
      still closed by default.
- [x] Export and strictly verify the exact-tag `1.0.0 (5)` App Store IPA; retain
      its immutable SHA/tag provenance.
- [x] Upload Build 5 and confirm App Store Connect reports the upload complete.
- [x] Add accurate What to Test, beta description, URLs, feedback contact and
      review notes, and create `Workloop Private Beta` as the external group.
- [x] Correct the production Auth site URL and web redirect allow-list from the
      retired third-party-owned domain to `workloop.uk`; confirm a dedicated
      reviewer account and verify password sign-in without storing credentials
      in the repository.
- [ ] Enter the owner's monitored reviewer phone number, attach Build 5 to the
      external group, submit it for Beta App Review, and enable/copy the public
      TestFlight link after Apple approves it.
- [ ] Add the intended testers or share the approved public link, then record
      one real TestFlight install/launch and the short physical-device smoke.
