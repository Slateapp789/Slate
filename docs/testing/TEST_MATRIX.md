# Workloop Test Matrix

Last updated: 2026-07-28

## Reading the matrix

Coverage labels are deliberately conservative:

- **Covered**: meaningful automated coverage exists for the named layer.
- **Partial**: some behaviours are covered, but important paths remain.
- **Harness only**: automation exists, but it does not exercise the full
  workflow or has not yet been run in its required environment.
- **Manual**: a human/device check is required.
- **None**: no meaningful evidence was found.
- **Out of scope**: the capability is not part of the launch product.

“Covered” describes the test inventory, not the current pass state. Candidate
pass/fail evidence belongs in [TEST_RESULTS.md](TEST_RESULTS.md).

## Feature and workflow coverage

| Area | Launch risk | Unit/provider | Widget/responsive/golden | Integration | Database/security | Current status and principal gap |
| --- | --- | --- | --- | --- | --- | --- |
| App bootstrap and Auth gate | Critical | Partial: metadata, validation, launch hardening | Partial: Auth states and launch surfaces | Harness only: signed-out launch/resume | Partial: Auth role boundaries in pgTAP | Real registration, refresh expiry, email confirmation, recovery delivery, restart, and returning session still need isolated E2E. |
| Onboarding and first workspace | Critical | Partial: state/provider behaviour | Partial: focused onboarding widget audits | None authenticated | Partial: schema and membership policy contracts | Full signup-to-dashboard persistence and interrupted/retried onboarding are not automated end to end. |
| Main navigation and deep links | High | Partial | Covered for global implicit/explicit vertical scroll targeting, retained-tab independence, native and fallback back-swipe completion, direct-route back actions, protected draft gestures, keyboard dismissal, and shared nav | Harness only for signed-out Auth navigation | Not applicable | Real notification, password-reset, public-profile, shell deep links, and physical gesture feel still need iOS/Android device checks. |
| Shared design system | High | Covered for dark-only theme semantics, native startup colour, pickers, and reusable logic | Covered across primitive, state, trust, accessibility, 132 launch-surface combinations, and reviewed goldens | None | Not applicable | Final goldens pass; physical-device accessibility review remains open. |
| Dashboard | High | Covered for greeting, attention, finance alignment, timing, and provider aggregation | Partial for empty/populated responsive surfaces | None authenticated | Indirect through source tables and RLS | Cross-module refresh after booking/payment/task changes and degraded-network states need E2E. |
| Clients / CRM | Critical | Covered for validation, sorting, views, duplicate handling, money/feed aggregation, and scale-sensitive CRM aggregation | Partial: canonical form, list, address field, detail/profile-adjacent surfaces | None authenticated | Partial: contacts table, tenant RLS, keys, and cross-user mutation in pgTAP | Create/edit/search/archive/delete persistence, permission import, and two-user direct API checks remain dynamic gaps. |
| Booking schedule and calendar | Critical | Covered for recurrence, validation, conflict mapping, price, workflow payloads, time/date boundaries, and status filtering | Partial: selectors, controls, forms, detail, empty/populated and responsive states | None authenticated | Partial: workflow/function contracts and appointment tenant boundaries | Real create/edit/reschedule/complete/cancel, conflict races, recurrence persistence, and DST behaviour need isolated E2E. |
| Public profile | Critical | Partial: repository/model and public-response handling | Partial: public-profile and booking-form UI audit plus golden surface | None against deployed isolated Edge | Static Edge boundary inspected | Signed-out device access, unavailable profile, abuse limits, malformed requests, and recovery after throttling remain unexecuted. |
| Booking requests | Critical | Covered for validation, confirmation mapping, stable retry/idempotency contract, lifecycle/error mapping, and backend security source contracts | Partial: inbox/detail/public request controls | None authenticated | Partial: booking-request table and workflow contracts; dynamic pgTAP pending | Full request-to-notification-to-owner-triage-to-booking conversion, duplicate concurrent submission, decline, and preference behaviour need staging E2E. |
| Services and pricing | Critical | Partial: selection, duration, working-hours/booking interaction, decimal-price regressions | Partial through onboarding, Settings/Profile, and booking forms | None authenticated | Partial: table/RLS contract | CRUD persistence, inactive services, 49.99 round trips, service deletion with related bookings, and public visibility need E2E. |
| Working hours | Critical | Covered for range validation and booking exceptions | Partial through onboarding and Profile/Settings screens | None authenticated | Partial: settings/profile table policies | Split blocks, closed days, DST, cross-midnight rejection, and persistence need device/staging journeys. |
| Money | Critical | Covered for period bounds, DST, totals, amount precision, income dates, client balance, and failure safety | Partial: Money overview and income/expense forms | None authenticated | Partial: invoice/payment/expense table and relationship contracts | Create/edit/delete/receive reconciliation across booking, client, dashboard, and Money needs authenticated E2E; large histories need measured profiling. |
| Tasks and checklists | High | Covered for filters, due-state rules, reminder plan, parsing/import, workflow payload, and retry behaviour | Partial: workspace, detail, editor, destructive and failure states | None authenticated | Partial: table/checklist keys, RLS, and workflow wrapper contracts | Transactional create, edit, complete/reopen, checklist persistence, notification scheduling, and restart recovery need E2E/device testing. |
| Notes | Medium | Covered for parsing/import and filter-related logic; long-content coverage is partial | Partial: empty/editor/list states and controls | None authenticated | Partial: table, keys, and RLS contracts | Create/edit/search/pin/delete persistence, very long content, and booking/client relationships need E2E. Archive/restore is not a current launch behaviour and must not be claimed. |
| Business Feed | High | Covered for ordering, classification, dashboard aggregation, and related finance/client signals | Partial: empty and filtered UI states | None authenticated | Indirect through source tables | Live cross-module refresh, error recovery, quiet-day boundaries, and large-volume behaviour need E2E/performance evidence. |
| Notifications centre | High | Partial: reminder-plan, preferences, counts, and scheduled-record logic | Partial: centre/preferences and state surfaces | None authenticated | Partial: notification/preferences/push-token RLS contracts | Remote push is not launch functionality. On-device permission, schedule, reschedule, reboot, tap-through, and time-zone changes require real-device QA. |
| Profile and business details | High | Partial: profile mapping and repository/provider behaviour | Partial: overview, owner preview, settings-owned boundaries, responsive surfaces | None authenticated | Partial: business-profile and settings RLS contracts | Edit persistence, handle collision/reservation, public-preview parity, and unavailable-network recovery need E2E. |
| Settings and appearance | High | Partial: map preference store and account hardening; dark-only theme contract covered | Covered for core Settings ownership, theme, picker, trust, and responsive contracts | None authenticated | Indirect | Appearance choice is intentionally absent. Password update, sign-out, and production recovery must still be checked on devices. |
| Address search and maps | Medium | Covered for address repository, unit labels, rate-limit source logic, and launcher choice | Covered for booking address field and manual fallback | None against isolated Edge | Static Edge/grant boundary inspected | Restricted production key, quota/billing alerts, poor network, denied external app, and device-level map selection remain operational/manual gates. |
| Contacts import | High | Covered for validation, mapping, and partial retry without duplicating successes | Partial through import UI | None with platform picker | Not applicable | Accepted/denied/revoked permission, thousands of contacts, interruption, and real-device picker behaviour remain manual/integration gaps. |
| Calendar import/export | High | Covered for one-time export and import retry rules | Partial through calendar UI | None with platform provider | Calendar account table RLS is a static contract | Accepted/denied/revoked permission, malformed `.ics`, DST, duplicate retry, and device interoperability remain unexecuted. Workloop must not claim live two-way sync. |
| CSV/task/note import | High | Covered for quoted CSV, validation, text/Markdown parsing, and retry safety | Partial through import UI | None with Files picker | Not applicable | Platform picker cancellation, huge/malformed files, encoding variants, interruption, and physical-device retry remain. |
| Workspace export | Critical | Partial: privacy repository and paginated data collection | Partial: account UI and confirmation states | None authenticated | Partial: deletion/export tables and grants | Export completeness, large workspace, PII handling, file sharing, offline failure, and two-account isolation need isolated E2E/manual validation. |
| Account deletion | Critical | Partial: request validation and sole-owner source contracts | Partial: destructive confirmation and account UI | None destructive | Partial: request/audit schema and deny policies statically inspected | Disposable-account request and completion, multi-member rejection, cascade/orphan checks, audit access, retry, and email/operations need staging validation. |
| Repository pagination | Critical | Covered for multi-page fetch, exact page boundary, ordering, and large result contracts | Not applicable | None against real large dataset | Not applicable | Source cap regressions are covered; query latency, index use, payload size, cancellation, and memory at 10,000 records require measurement. |
| Local data generation | Medium | Covered by deterministic dry-run/profile validation | Not applicable | Generator only | Does not write a backend | Small, medium, large, and scale plans exist. Generated representation is not a seeded environment or a concurrency result. |
| Edge Functions | Critical | Partial: 19 final Deno tests cover selected shared/booking/Places behaviours | Not applicable | None against isolated deployments | Static type/grant/function inspection; local database tests pending | Deployed public request, profile, Places, deletion, rate-limit, timeout, and idempotency paths need disposable staging journeys. |
| Supabase RLS and tenant isolation | Critical | Not applicable | Not applicable | None through client SDK | Harness only: 31 schema/grant assertions and 12 two-user boundary assertions are authored | Docker/local stack was unavailable for the local run; CI is configured but no hosted passing run is evidence yet. |
| Storage / file attachments | Critical if introduced | None | None | None | None | No launch file-attachment/storage-bucket workflow or repository bucket policy was identified. Files metadata in generated fixtures does not constitute Storage coverage. Keep out of launch claims unless implemented and secured. |
| AI assistant | Out of scope | Edge source returns a disabled response | None | None | No data access should be exposed | AI-first workflows are parked/disabled. Verify the endpoint remains safely unavailable; do not market it as a launch feature. |
| Subscription access / billing | Out of scope | None | None | None | None | No subscription entitlement or payment-processing launch implementation was identified. Do not imply card processing, deposits, or paid-plan gating. |
| Crash/error reporting | High operational | None | None | None | Not applicable | No production crash/error reporting is integrated. This reduces post-launch observability and is tracked as a release-risk decision. |
| Android platform/build | Critical | Not applicable | Automated viewport coverage only | CI harness for signed-out emulator smoke | Not applicable | Debug/profile and 16 KB alignment pass; release signing, hosted Android integration, physical Android, permissions, deep links, lifecycle, reinstall, and upgrade remain open. |
| iOS platform/build | Critical | Not applicable | Automated viewport coverage plus reviewed goldens | Signed-out simulator smoke passes | Not applicable | Debug/profile/release compilation passes; Distribution signing, complete physical-device launch/manual matrix, VoiceOver, permissions, lifecycle, reinstall, and upgrade remain release gates. |
| Web legal/support surface | Critical external | Not applicable | Source artifacts exist outside this matrix | Manual HTTP/DNS operation | Not applicable | Public privacy, terms, deletion, and support endpoints were not reachable in the observed domain check. Store submission remains blocked until verified. |

## Coverage inventory by test type

Representative current files include:

- Auth/account:
  [`auth_metadata_test.dart`](../../test/auth_metadata_test.dart),
  [`account_launch_hardening_test.dart`](../../test/account_launch_hardening_test.dart)
- Clients:
  [`client_form_test.dart`](../../test/client_form_test.dart),
  [`client_sort_test.dart`](../../test/client_sort_test.dart),
  [`client_view_test.dart`](../../test/client_view_test.dart),
  [`core_audit_client_crm_scalability_test.dart`](../../test/core_audit_client_crm_scalability_test.dart)
- Bookings:
  [`appointment_recurrence_test.dart`](../../test/appointment_recurrence_test.dart),
  [`booking_workflow_test.dart`](../../test/booking_workflow_test.dart),
  [`booking_confirmation_test.dart`](../../test/booking_confirmation_test.dart),
  [`booking_backend_security_contract_test.dart`](../../test/booking_backend_security_contract_test.dart)
- Money:
  [`finance_period_summary_test.dart`](../../test/finance_period_summary_test.dart),
  [`core_audit_finance_boundaries_test.dart`](../../test/core_audit_finance_boundaries_test.dart),
  [`task_finance_failure_safety_test.dart`](../../test/task_finance_failure_safety_test.dart)
- Connected state:
  [`business_feed_provider_test.dart`](../../test/business_feed_provider_test.dart),
  [`dashboard_attention_provider_test.dart`](../../test/dashboard_attention_provider_test.dart),
  [`core_audit_client_money_feed_test.dart`](../../test/core_audit_client_money_feed_test.dart)
- Scheduling/import/retry:
  [`core_audit_auth_import_test.dart`](../../test/core_audit_auth_import_test.dart),
  [`core_audit_scheduling_tasks_notes_test.dart`](../../test/core_audit_scheduling_tasks_notes_test.dart),
  [`local_reminder_plan_test.dart`](../../test/local_reminder_plan_test.dart)
- UI/accessibility:
  [`launch_accessibility_test.dart`](../../test/launch_accessibility_test.dart),
  [`navigation_assist_test.dart`](../../test/navigation_assist_test.dart),
  [`launch_responsive_matrix_test.dart`](../../test/launch_responsive_matrix_test.dart),
  [`launch_trust_ui_test.dart`](../../test/launch_trust_ui_test.dart),
  [`ui_audit_states_test.dart`](../../test/ui_audit_states_test.dart)
- Golden and integration:
  [`launch_surfaces_golden_test.dart`](../../test/golden/launch_surfaces_golden_test.dart),
  [`launch_smoke_test.dart`](../../integration_test/launch_smoke_test.dart)
- Database:
  [`001_schema_security.test.sql`](../../supabase/tests/database/001_schema_security.test.sql),
  [`002_rls_isolation.test.sql`](../../supabase/tests/database/002_rls_isolation.test.sql)

This inventory should be regenerated when modules or launch claims change. A
test filename alone is not evidence that every row in that feature is covered.

## Highest-priority coverage additions

1. Isolated authenticated E2E for onboarding and the connected core business
   journey.
2. Dynamic public booking-request abuse/idempotency/conversion tests.
3. Clean local migration replay plus pgTAP execution.
4. Two-account SDK-level reads, writes, deletes, export, and Storage checks.
5. Disposable account-deletion completion and cascade validation.
6. Real-device reminder, permission, offline, lifecycle, and deep-link matrix.
7. Measured large-dataset app profiling and staging load execution.
8. Hosted CI evidence for the new database and Android integration jobs.
