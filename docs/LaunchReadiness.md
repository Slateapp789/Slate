# Workloop Launch Readiness

Last updated: 2026-07-28

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
feeds, card processing, or remote push notifications unless those services are
actually connected and verified.

## Repository launch gates

| Area | Gate |
| --- | --- |
| Identity | Workloop name, `com.ismaeel.workloop` identifiers, exact `#C1FF72` icon/splash accent |
| Navigation | Home, Clients, Bookings, Tools; Money, Tasks, and Notes remain feature-local destinations |
| Visual system | Fixed, slightly lifted graphite Dark appearance; exact icon/launch neon `#C1FF72`; contrast-safe neon foregrounds; bundled Instrument Sans; shared shell geometry; reduced-motion handling; semantic labels |
| Core workflows | Auth/onboarding, clients, atomic/idempotent booking and task workflows, money, notes, profile/settings, retry-safe imports, one-time calendar import/export, on-device reminders |
| Trust | Workspace export, protected deletion request, in-app privacy/terms, public policy/deletion artifacts |
| Platform | Flutter 3.44.8; iPhone-only portrait scope on iOS 13+; Android portrait, API 36 target/minimum API 24, Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, Java 17; production network permission, no cleartext release traffic, sensitive backup exclusion, iOS/Android recovery link |
| Quality | Formatting, analysis, full tests, Android profile build with 16 KB page alignment, iOS profile build, web release build, physical iPhone launch |
| Automation | Secret-safe CI runs Flutter formatting/analysis/tests, Deno formatting/checks/tests, Gradle-wrapper validation, Android profile and web builds, plus an unsigned iOS profile build on macOS |

The final verification evidence for a release candidate must be appended to
`docs/CurrentState.md`; failures are never waived silently.

## Production backend gate

Connected project:

- Project: `imtbyrvsonzvtddswbtb`
- Region: London (`eu-west-2`)
- Status checked 2026-07-26: healthy
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
  ledger.
- Repository source routes task creation, booking creation, booking-request
  conversion, and booking completion through authenticated, tenant-validating,
  idempotent workflows. Public request and Places source use bounded private
  rate-limit state.
- Current active Edge deployments are `create-booking-request` v8,
  `places-address-search` v8, `get-public-profile` v6,
  `request-account-deletion` v6, and `complete-account-deletion` v9.
  Structural/grant smoke checks passed. The release gate remains open until the
  production-like signed-out, authenticated-workflow, and destructive deletion
  matrix is recorded.
- The audit candidate adds booking-request/contact/notification hardening in
  migration `20260726005736` and updated `create-booking-request` source. These
  changes were deliberately not deployed to production during QA. They must
  first pass a clean replay and isolated staging workflow.

Before submission:

- [ ] Add `workloop://reset-password` to Supabase Auth redirect URLs.
- [ ] Enable Supabase Auth leaked-password protection. This is the remaining
      security-advisor warning.
- [ ] Configure production SMTP, sender identity, email confirmation, and
      password-reset delivery; test fresh-account and recovery emails outside
      the development team.
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
- Clean Supabase replay/43 pgTAP assertions, authenticated staging E2E, and
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

As checked on 2026-07-26, the apex HTTPS host timed out and `www` still served
a Namecheap registration/parking page. The repository now contains:

- `/privacy.html`
- `/terms.html`
- `/delete-account.html`

Before submission:

- [ ] Deploy the release web artifact and make those exact HTTPS URLs public,
      stable, crawlable, and accessible without signing in.
- [ ] Redirect the apex and `www` hosts consistently.
- [ ] Create and actively monitor `support@workloop.app`.
- [ ] Replace generic operator wording in the policies with the legal
      controller/business name, contact address, and any company number.
- [ ] Have the privacy policy and terms reviewed for the launch markets.

### 3. Signing and store accounts

- [ ] Create the Android upload key, keep two encrypted backups, and enable Play
      App Signing. Never commit `android/key.properties` or a keystore.
- [ ] Create the Play Console app with package `com.ismaeel.workloop`.
- [ ] Install an iOS Distribution certificate and App Store provisioning
      profile for `com.ismaeel.workloop`; then confirm the team, agreements,
      tax, and banking status in App Store Connect.
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
- [ ] Add review notes explaining why contacts/calendar are optional imports
      and that financial records are tracking records, not payment processing.

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
flutter build appbundle --release --dart-define-from-file=.env
flutter build ipa --release --dart-define-from-file=.env
```

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
- The fixed dark appearance, reduced motion, VoiceOver, and TalkBack.
- Fresh install, sign-up, password recovery, interrupted onboarding, sign-out,
  returning session, and offline/error recovery.
- Empty, realistic, and high-volume workspaces.
- UK daylight-saving transition, month-end recurrence, and cross-midnight
  bookings.
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
