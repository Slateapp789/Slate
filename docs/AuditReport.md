# Slate Code, Product, and Platform Audit

Date: 2026-06-01
Scope: Read-only audit of the Flutter + Supabase codebase, SQL contracts, docs, tests, platform config, dependency posture, and a local web smoke test. No app code was changed.
Method: Static source review, `flutter analyze`, `flutter test --dart-define-from-file=.env`, local web browser smoke test, Supabase live advisors/table metadata, and dependency/config checks.

---

## 1. Executive Summary

Slate is a solid MVP with unusually good internal documentation for its stage. The main architecture shape is sound: Flutter/Riverpod screens call providers and repositories, Supabase access is mostly centralized, RLS is enabled across workspace-owned tables, typed models exist for the core domains, and the product loop is coherent.

The main risks are not "rewrite the app" risks. They are specific public-surface, data-integrity, and release-readiness problems that should be fixed before a public beta.

Most important findings:

- Public profile/deep-link behavior is currently the highest-risk product issue.
- Public booking requests need abuse protection and a tighter server-side contract.
- Invoice/payment numbering can collide.
- Booking confirmation/edit flows bypass the same checks used by the main booking form.
- Account deletion is only a request queue, not an implemented deletion path.
- Release/platform config has concrete issues that will bite mobile builds.

Correction from the earlier draft: the suspected high-severity timezone storage bug is not a live bug in the current main add-booking path. `AddAppointmentScreen` converts selected local times to UTC before calling `AppointmentsRepository.create()`. The repository still has a weak contract because it writes whatever `DateTime` it receives, but the traced caller is safe.

| Severity | Count | Theme |
|---|---:|---|
| High | 6 | Public profile, public booking abuse, invoice numbers, booking validation gaps, account deletion, platform release config |
| Medium | 9 | Notifications, money math, error handling, auth/workspace UX, tab state, booking-mode mismatch, privacy/export, accessibility, docs drift |
| Low / debt | 9 | Oversized files, mixed routing, raw maps, CI, crash reporting, tests, currency, dependency freshness, token cleanup |

---

## 2. High Priority

### H1. Public profile routing and public data contract are broken

The local browser smoke test found two separate public-profile problems:

- Loading `http://127.0.0.1:57321/p/slate-demo` rendered the auth screen instead of the public profile.
- Loading `http://127.0.0.1:57321/#/p/slate-demo` reached the route but stayed on a spinner.

Likely routing cause: `GoRouter(initialLocation: '/')` in `lib/main.dart` can override the browser's incoming path on cold web loads.

Data-contract cause: `ProfileRepository.getPublicProfile()` selects:

```dart
'*, workspaces(name, industry), workspace_settings(working_hours)'
```

for an anonymous route, then force-casts the embedded rows:

```dart
final workspace = Map<String, dynamic>.from(profileMap['workspaces'] as Map);
```

But RLS only grants anon read to `business_profiles` and visible `services`. It does not grant anon read to `workspaces` or `workspace_settings`. Owner testing while authenticated can mask this because authenticated policies are different.

Fix direction:

- Make public web routing honor the incoming `/p/:handle` location.
- Serve public profile data through an explicit public view/RPC/Edge Function containing only intended public columns.
- Stop relying on embedded reads from authenticated-only tables for anonymous visitors.
- Add a public-route smoke/integration test.

Files:

- `lib/main.dart`
- `lib/shared/repositories/profile_repository.dart`
- `supabase/rls_policies.sql`

### H2. Invoice/payment numbers can collide

Both `PaymentsRepository.create()` and `ProfileRepository.confirmBookingRequest()` generate `PAY-NNN` by reading all invoice IDs for the workspace and adding one.

Problems:

- Deleting a payment lets the same number be regenerated.
- Concurrent creates can generate the same number.
- The live DB does not have a unique constraint on `(workspace_id, invoice_number)`.
- Fetching all IDs to count is O(n) per create.

Fix direction: generate invoice numbers in Postgres with a per-workspace sequence/counter or trigger, and add a unique constraint on `(workspace_id, invoice_number)` so collisions fail loudly.

Files:

- `lib/shared/repositories/payments_repository.dart`
- `lib/shared/repositories/profile_repository.dart`
- live Supabase constraints

### H3. Anonymous booking-request abuse and integrity gaps

The public `booking_requests` insert policy allows anon inserts for any workspace with a manual business profile. Combined with anon-readable `business_profiles`, an attacker can discover workspace IDs and flood request inboxes.

Additional issues:

- No rate limiting.
- No input length limits in UI or DB checks.
- No forced `status = 'pending'`.
- No check that `service_id` belongs to the same workspace.
- No check that the service is public/active.
- Public insert is direct from the client, so abuse protection is hard to centralize.

Fix direction: move public request creation behind a server-side boundary such as an Edge Function or RPC that accepts a handle, validates the service/workspace relationship, bounds input length, forces status, and rate-limits by IP/handle. Avoid exposing internal `workspace_id` to anonymous clients.

Files:

- `supabase/rls_policies.sql`
- `supabase/schema_contract.sql`
- `lib/features/public_profile/public_profile_screen.dart`
- `lib/shared/repositories/profile_repository.dart`

### H4. Booking confirmation and editing bypass scheduling safeguards

The main add-booking flow warns when a booking overlaps an existing appointment and falls outside working hours. Other write paths do not apply the same checks:

- Confirming a public booking request creates an appointment with no conflict or working-hours check.
- Editing an existing appointment can move it into a clash silently.
- Recurring booking creation only checks the first selected occurrence in the UI.
- Optional tasks added during recurring booking creation attach only to `bookingIds.first`, not every occurrence.

Fix direction: move conflict/working-hours validation into a shared booking service/repository method and use it from create, edit, request-confirmation, and recurring flows. Decide whether overlaps are warnings or hard stops, then apply that consistently.

Files:

- `lib/features/appointments/add_appointment_screen.dart`
- `lib/features/appointments/appointment_detail_screen.dart`
- `lib/features/public_profile/booking_requests_screen.dart`
- `lib/shared/repositories/profile_repository.dart`
- `lib/shared/repositories/appointments_repository.dart`

### H5. Account deletion is a queue with no processor

`PrivacyRepository.requestAccountDeletion()` inserts a row into `account_deletion_requests`. No processor, Edge Function, admin workflow, or documented SLA exists in the repo to actually erase workspace/auth/user data.

For a product storing client PII such as names, phone numbers, notes, birthdays, and booking history, this is not enough for real-world erasure expectations.

Fix direction: implement a trusted deletion path or document a manual operational process before collecting real production user data.

Files:

- `lib/shared/repositories/privacy_repository.dart`
- `supabase/schema_contract.sql`

### H6. Mobile release/platform config is not production-ready

Concrete config issues found in platform files:

- Android release builds are still signed with debug keys.
- Android app label is lowercase `slate`.
- macOS product name is lowercase `slate`.
- iOS `LSApplicationQueriesSchemes` for `tel`/`mailto` appears after the closing `</plist>`, so it is not parsed as an Info.plist key even though `plutil -lint` accepts the XML prefix.

The URL-scheme issue matters because the app calls `launchUrl()` for phone and email actions.

Fix direction: set release signing, app display names, and valid platform metadata before TestFlight/Play/internal testing.

Files:

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `macos/Runner/Configs/AppInfo.xcconfig`
- `lib/features/clients/client_detail_screen.dart`
- `lib/features/public_profile/booking_requests_screen.dart`

---

## 3. Medium Priority

### M1. Public booking-request notifications are attempted but blocked

After an anonymous booking request insert, `ProfileRepository.createBookingRequest()` attempts to insert a `notifications` row. RLS only allows authenticated workspace members to manage notifications, so this anon insert fails and is swallowed.

Result: public requests can land without notifying the owner through the app's notification system.

Fix direction: create owner notifications server-side after validated public request creation, or have the authenticated owner poll/request count reliably until a server path exists.

### M2. Money math is inconsistent across providers

Some views use full invoice `total` for non-paid balances instead of outstanding amount (`total - amount_paid`). Dashboard outstanding also excludes `pending` while `PaymentsRepository.outstanding()` includes `pending`.

This is user-visible if partial payments exist in the DB, even if the current UI mostly creates paid/unpaid payments.

Fix direction: define a single `amountDue` helper/model field and use the same status set across dashboard, finance, and clients.

Files:

- `lib/shared/providers/finance_provider.dart`
- `lib/shared/providers/clients_provider.dart`
- `lib/shared/providers/dashboard_provider.dart`
- `lib/shared/repositories/payments_repository.dart`

### M3. Transient workspace-load errors look like logout

`WorkspaceGate` renders `AuthScreen` for any `workspaceProvider` error. A network/RLS/schema hiccup can visually drop an authenticated user back to sign-in.

Fix direction: show a workspace-load error state with retry and sign-out actions instead of treating every error as unauthenticated.

File:

- `lib/main.dart`

### M4. Tab switching discards screen state

The main shell swaps tabs with `AnimatedSwitcher` and a keyed subtree. That rebuilds tab screens, losing scroll position, filters, search state, and some local focus behavior.

Fix direction: use an `IndexedStack` or another preserved-state shell when tab state matters.

File:

- `lib/main.dart`

### M5. Booking-mode UI and RLS can drift

Current settings UI only exposes `manual` and `closed`, so this is not an immediate user-facing bug. The public profile, however, shows the form for anything except `closed`, while RLS allows anon inserts only when `booking_mode = 'manual'`.

If a future mode such as `auto` or imported data reaches the table, the UI can show a form that RLS rejects with a generic failure.

Fix direction: centralize allowed modes and make UI rendering match the same policy predicate used by the backend.

Files:

- `lib/features/public_profile/public_profile_screen.dart`
- `lib/features/settings/widgets/settings_business_tab.dart`
- `supabase/rls_policies.sql`

### M6. Silent catches hide real failures

There are multiple broad `catch (_) {}` blocks. Some are intentional schema-drift shims, but they also hide permission failures, insert failures, and export omissions.

Examples:

- Booking requests provider returns an empty list on repository error.
- Dashboard focus silently zeros failed data.
- Privacy export silently omits failed tables.
- Notification creation swallows insert errors.
- Calendar sync swallows account-table failures.

Fix direction: narrow expected exceptions, add logging/crash reporting, and surface user-facing failures when data is incomplete.

### M7. Privacy export can silently be incomplete

`PrivacyRepository.exportWorkspaceData()` returns null/empty sections when a table read fails. For a privacy export, silent partial data is risky because the output looks complete.

Fix direction: include an `errors` section in the export or fail loudly when required tables cannot be read.

File:

- `lib/shared/repositories/privacy_repository.dart`

### M8. Accessibility and keyboard/screen-reader behavior need attention

Shared interactive controls and many local chips/buttons use `GestureDetector` without semantic labels, focus handling, tooltips, or Material states. This affects icon buttons, tab items, filter chips, and some destructive actions.

Fix direction: prefer `IconButton`, `InkWell`, `Semantics`, `Tooltip`, and focusable controls for reusable primitives.

Files:

- `lib/shared/widgets/slate_ui.dart`
- feature screens using local `GestureDetector` controls

### M9. Docs and contracts drift from code/live DB

Examples:

- `docs/UIDesignSystem.md` describes a light neutral palette; live `AppTheme` is dark graphite/lime.
- `supabase/schema_contract.sql` comments/alter statements drift from live `services.active`.
- Earlier `docs/AuditReport.md` claimed tests could not run and promoted a timezone bug that is not live in the traced create path.
- `docs/Architecture.md` says older duplicate policies should be cleaned, while live Supabase policy/advisor checks did not show that issue.

Fix direction: treat the reconciled audit and live schema checks as the current source, then refresh the docs that claim to describe current state.

---

## 4. Low Priority / Known Debt

- Oversized feature files remain hard to reason about: `appointment_detail_screen.dart`, `settings_business_tab.dart`, `add_appointment_screen.dart`, `booking_requests_screen.dart`, `finance_screen.dart`, and `tasks_screen.dart`.
- Some providers still expose raw `Map<String, dynamic>` even where typed models exist.
- Routing is mixed between GoRouter routes, local tab state, and imperative `Navigator.push`.
- CI is not present in the repo; `analyze` and `test` are manual.
- Crash/error reporting is not present, which compounds silent catches.
- Test coverage is thin: model serialization and finance summary are covered, but public profile, booking confirmation, repository contracts, and navigation are not.
- Currency is hardcoded to GBP in many UI strings; this is fine for a UK-only launch, but should become a workspace setting before broader use.
- Dependency posture is healthy enough, but `flutter pub outdated --no-transitive` showed direct updates available for `cupertino_icons`, `go_router`, `google_fonts`, and `flutter_lints`.
- Design-token aliases (`green*`, `violet*`, `slate*`) carry old naming from prior palette experiments.

---

## 5. Things Done Well

- The product loop is coherent: clients, bookings, money, tasks, dashboard, public profile, and settings all connect.
- Supabase access mostly lives in repositories, not scattered through widgets.
- RLS is enabled on workspace-owned tables and routed through a shared `is_workspace_member()` helper.
- Typed models are defensive and generally sensible around nulls and numeric parsing.
- Secrets are handled correctly: `.env` is gitignored, and no service-role key appears in client code.
- The docs are unusually honest about current state and debt.
- `flutter analyze` passed.
- `flutter test --dart-define-from-file=.env` passed.
- Local auth screen rendered cleanly on desktop and mobile web with no console errors.
- Supabase project was active/healthy; advisors showed leaked password protection disabled and informational unused-index warnings, not broad RLS advisor failures.

---

## 6. Suggested Order of Attack

1. Fix public profile routing and data access with a proper public read contract.
2. Move public booking-request creation behind a validated/rate-limited server boundary.
3. Replace row-count payment numbering with a DB-backed unique sequence/counter.
4. Centralize booking validation so create, edit, request-confirmation, and recurring paths share conflict/working-hours checks.
5. Implement or formally document the account deletion processor/SLA.
6. Fix platform release metadata/signing before mobile beta distribution.
7. Clean up notification creation, money math, workspace error states, and tab state.
8. Add focused tests around public profile, booking requests, payment numbering, and booking validation.

---

## 7. Verification Notes

Commands/checks run during the reconciled audit:

```text
flutter analyze
flutter test --dart-define-from-file=.env
flutter pub outdated --no-transitive
plutil -lint ios/Runner/Info.plist
local web smoke test at http://127.0.0.1:57321/
local web public-route smoke tests for /p/slate-demo and /#/p/slate-demo
Supabase security advisor
Supabase performance advisor
Supabase public schema/table metadata
Supabase live policy/constraint checks
```

Important limitation: the browser public-profile test was a smoke test, not a full authenticated/anonymous matrix. The clean-path route and the hash route appeared to fail in different ways, so public profile should be pinned down with a targeted reproduction after the routing and data-contract fix is chosen.
