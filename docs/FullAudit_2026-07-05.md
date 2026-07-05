# Workloop Full Audit

Date: 2026-07-05
Scope: Notion product context, Flutter app, local docs, Supabase schema/RLS/functions, live Supabase advisors, tests, and current setup state.

## Executive Summary

Workloop is a real MVP foundation, not a throwaway prototype. The core product direction in Notion is clear: a mobile-first operating app for solo appointment-based service businesses, centered on dashboard, clients, bookings, payments, tasks, onboarding, settings, public profile, and privacy.

The codebase broadly matches that direction and is currently healthy at the tooling level:

- `flutter analyze` passes.
- `flutter test --dart-define-from-file=.env` passes: 18 tests.
- `dart format --output=none --set-exit-if-changed .` passes: 0 changed files.
- Live Supabase has RLS enabled on all inspected public tables.
- Public profile and booking requests now use Edge Functions instead of direct anonymous table access.

The biggest risks are now product/architecture hardening, not basic build failure. The top priorities are onboarding error handling, exposed RLS helper functions, payment numbering integrity, routing/state consistency, screen size/typed model debt, release branding, and replacing local Flutter SDK hacks with a documented/future-proof build setup.

## Notion Alignment

Relevant Notion sources reviewed:

- Workloop HQ: https://app.notion.com/p/35867589db3781ac98f3faf11bd4ce1c
- Product Vision: https://app.notion.com/p/35867589db3781248e05d3dcdaf8052b
- App Map & Navigation: https://app.notion.com/p/35867589db3781c1af91cd92317f6375
- Core Architecture: https://app.notion.com/p/35867589db3781e2986fc2defcbff612
- Roadmap & Build Order: https://app.notion.com/p/35867589db378196921efdf81242e824
- MVP Roadmap Revised: https://app.notion.com/p/36367589db3781fe859ef7f1ef2660ee
- Features Index: https://app.notion.com/p/35867589db3781deae9bca44c4209d49
- Technical Audit & Architecture Plan: https://app.notion.com/p/36867589db3781d0ae93c24da47ae2a4

Current product fit:

- Strong match: mobile-first solo service-business ICP, workspace model, auth/onboarding, dashboard, clients, bookings, money/payments, tasks, settings, public profile, privacy/delete-account path.
- Partial drift: product is called Workloop in Notion, but repo/package/docs/app IDs still say Slate in many places.
- Scope drift risk: calendar sync, public booking, account deletion, notifications, and AI stubs exist even though several Notion pages treat them as later or carefully scoped features. They should stay bounded until the daily loop is polished.

## Current Repo State

Branch: `main`

Dirty app changes at audit time:

- `ios/Podfile.lock`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner/AppDelegate.swift`
- `lib/shared/repositories/onboarding_repository.dart`
- `macos/Podfile.lock`
- `macos/Runner.xcodeproj/project.pbxproj`
- `pubspec.lock`
- `supabase/rls_policies.sql`
- `supabase/migrations/20260705123700_fix_workspace_members_rls_recursion.sql`

Dirty local Flutter SDK changes:

- `work/flutter/packages/flutter_tools/bin/xcode_backend.dart`
- `work/flutter/packages/flutter_tools/lib/src/build_system/targets/ios.dart`

These SDK edits were needed to get iOS simulator builds past extended attribute/codesign issues, but they are local and brittle.

## High Priority Findings

### H1. Onboarding can silently fail and still let the user enter the dashboard

Evidence:

- `lib/features/onboarding/screens/ob_complete.dart:44` starts saving automatically.
- `lib/features/onboarding/screens/ob_complete.dart:59` catches errors and only `debugPrint`s them.
- `lib/features/onboarding/screens/ob_complete.dart:67` lets the user go to `MainShell` directly, without confirming the workspace save succeeded or invalidating `workspaceProvider`.

Impact:

This is exactly the class of bug we just hit: if workspace creation, membership, services, or booking insert fails, the UI can still say the workspace is ready. Users can land in a broken dashboard or get bounced by auth/workspace state later.

Fix:

- Track save status as `saving/saved/failed`.
- Disable "Go to dashboard" until saved.
- Show a real retry error if save fails.
- Invalidate `workspaceProvider` after success.
- Route through GoRouter/AuthGate rather than pushing `MainShell` manually.

### H2. Supabase security-definer helper functions are exposed as RPCs to authenticated users

Evidence:

- `supabase/rls_policies.sql:4` and `supabase/rls_policies.sql:24` define `public.is_workspace_member` and `public.workspace_has_no_members` as `security definer`.
- `supabase/rls_policies.sql:22` and `supabase/rls_policies.sql:43` grant execute to `authenticated`.
- Supabase security advisor reports both functions as externally callable security-definer functions.

Impact:

The functions currently guard on `auth.uid()` and are narrow, so this is not an obvious cross-tenant leak. But security-definer functions in `public` are a production smell because they become RPC endpoints. We needed this to fix RLS recursion, but the clean version should move helpers into a private schema or otherwise prevent direct API execution while still allowing policies to use them.

Fix:

- Move helper functions to a private/non-exposed schema, or redesign the membership policy to avoid public executable security-definer RPCs.
- Re-run Supabase advisors after migration.
- Keep the auth guard and `search_path`.

### H3. Payment numbers can still collide

Evidence:

- `lib/shared/repositories/payments_repository.dart:74` counts existing invoice rows and generates `PAY-NNN`.
- `lib/shared/repositories/profile_repository.dart:159` repeats the same pattern when confirming booking requests with payment due.
- Live constraints for `invoices` did not show a unique `(workspace_id, invoice_number)` constraint.

Impact:

Concurrent creates or deleted rows can generate duplicate payment numbers. This may become a user-visible finance bug and makes support/reconciliation harder.

Fix:

- Generate payment/invoice numbers server-side with a per-workspace counter, RPC, or trigger.
- Add a unique constraint on `(workspace_id, invoice_number)`.
- Make both normal payment creation and booking-confirmation payment creation use the same path.

### H4. Booking confirmation bypasses core scheduling safeguards

Evidence:

- `lib/shared/repositories/appointments_repository.dart:37` has conflict lookup.
- `lib/shared/repositories/profile_repository.dart:111` confirms a booking request by inserting an appointment directly.
- `lib/features/public_profile/booking_requests_screen.dart:640` passes selected date/time straight into confirmation.

Impact:

Main booking creation may warn/check for clashes, but request confirmation and edits can drift from that logic. Double bookings are one of the exact problems Workloop is meant to solve.

Fix:

- Create a shared appointment creation service that validates conflicts, working hours, service ownership, recurrence, and payment side effects.
- Use it from add booking, edit booking, recurring booking, and public request confirmation.

### H5. The build currently depends on local Flutter SDK patches

Evidence:

- Local Flutter SDK has modified `xcode_backend.dart` and `ios.dart`.
- App repo also added iOS/macOS Xcode phases to strip extended attributes.

Impact:

The app runs on this machine now, but a fresh clone or future Flutter upgrade may hit the same iOS signing issue again. This is fragile for future development.

Fix:

- Document the current workaround in setup docs.
- Prefer repo-level cleanup/build phases where possible.
- Track a task to remove SDK patches after confirming whether Flutter/Xcode has a supported fix.

## Medium Priority Findings

### M1. Branding is split between Slate and Workloop

Evidence:

- `pubspec.yaml:1` package is `slate`.
- `README.md:1` says Slate.
- `lib/main.dart:44` sets app title to Slate.
- iOS display name is Slate.
- Android namespace/application ID is `com.slate.app.slate`.

Impact:

This will confuse test users, docs, App Store prep, and future code/search work. Some backend names can stay stable for now, but user-facing branding needs a deliberate cutover.

Fix:

- Decide whether to rename app/package IDs now or keep IDs stable and only change display/docs.
- Minimum before beta: user-facing strings and docs should say Workloop consistently.

### M2. Dart SDK constraint does not match the lockfile/tooling reality

Evidence:

- `pubspec.yaml:21` says `sdk: ^3.8.1`.
- `pubspec.lock` resolves to Dart `>=3.9.2 <4.0.0`.

Impact:

Fresh installs on older Dart 3.8 tooling can fail or resolve differently.

Fix:

- Update `pubspec.yaml` to `>=3.9.2 <4.0.0` if Flutter 3.35.7 remains the team baseline.
- Document the required Flutter version.

### M3. Main shell discards tab state

Evidence:

- `lib/main.dart:311` uses `AnimatedSwitcher`.
- `lib/main.dart:331` keys the subtree by current tab, rebuilding tab contents when switching.

Impact:

Search, scroll, filters, and local tab state can reset as users move around. This matters for a daily-use operations app.

Fix:

- Replace tab body switching with `IndexedStack` or a state-preserving shell.
- Keep animation only where it does not destroy screen state.

### M4. Workspace-load errors look like logout

Evidence:

- `lib/main.dart:138` renders `AuthScreen` for any `workspaceProvider` error.

Impact:

Network/RLS/schema issues can look like the user has been logged out.

Fix:

- Add a workspace error screen with retry and sign-out actions.

### M5. Screen and widget files are still too large

Largest files now:

- `add_appointment_screen.dart`: 1252 lines
- `appointment_detail_screen.dart`: 1236 lines
- `settings_business_tab.dart`: 1224 lines
- `booking_requests_screen.dart`: 1202 lines
- `finance_screen.dart`: 1167 lines
- `dashboard_screen.dart`: 1054 lines

Impact:

This is the main maintainability drag Notion already warned about. It increases regression risk and makes AI-assisted edits harder.

Fix:

- Extract forms, sheets, cards, and pure logic one feature at a time.
- Start with onboarding, bookings, and finance because they touch revenue/activation.

### M6. Typed model migration is incomplete

Evidence:

- Typed models exist in `lib/shared/models/slate_models.dart`.
- Providers still expose raw maps, e.g. `workspaceProvider` returns `Map<String, dynamic>?`.
- Several screens pass joined `Map<String, dynamic>` payloads around.

Impact:

Raw maps hide schema errors until runtime and keep business logic in UI files.

Fix:

- Convert workspace, dashboard, booking detail, and client detail providers to typed view models.
- Keep raw maps only at repository edges.

### M7. Supabase Auth leaked-password protection is disabled

Evidence:

- Supabase security advisor reports `auth_leaked_password_protection` disabled.

Impact:

Not a code bug, but it should be enabled before beta.

Fix:

- Enable leaked password protection in Supabase Auth settings.

## What Is In Good Shape

- Core stack choice matches Notion: Flutter + Riverpod + Supabase.
- Repository boundary is mostly respected; direct table access is largely centralized.
- RLS is enabled on all inspected public tables.
- Public profile and public booking now use Edge Functions.
- Account deletion has request and completion Edge Functions, not just a local queue.
- Release signing on Android fails closed when keystore config is absent.
- iOS phone/email URL schemes are currently in the plist.
- Tests cover model serialization, finance summaries, date labels, and next-booking selection.

## Recommended Build Plan

### Phase 1: Stabilize Activation and Safety

1. Fix onboarding completion state and routing.
2. Move/rework RLS helper functions so Supabase advisors are clean.
3. Enable leaked-password protection.
4. Add payment number uniqueness and server-side generation.
5. Add smoke tests for sign-up/onboarding/workspace creation and public booking request.

### Phase 2: Protect the Daily Loop

1. Centralize appointment creation/edit/confirmation validation.
2. Preserve tab state in `MainShell`.
3. Add workspace-load error/retry UI.
4. Standardize provider invalidation after create/update/delete flows.
5. Add tests for booking conflicts, payment due creation, booking request confirmation, and onboarding failure.

### Phase 3: Reduce Architecture Entropy

1. Split the largest screens into sections/widgets/controllers.
2. Convert workspace, dashboard, appointments, and client detail flows to typed view models.
3. Keep repositories as the only Supabase data boundary.
4. Add a short architecture rule doc for new features.

### Phase 4: Beta Readiness

1. Resolve Workloop vs Slate branding.
2. Lock Flutter/Dart version in docs and `pubspec.yaml`.
3. Remove or document local Flutter SDK patches.
4. Add crash/error reporting.
5. Create a manual QA checklist for iPhone simulator and real device.
6. Prepare App Store/TestFlight metadata and production env split.

## Suggested Next Task

Start with H1 onboarding completion. It is small, directly related to the bug we just fixed, easy to test, and protects every new user.
