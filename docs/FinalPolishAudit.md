# Workloop Final Polish Audit

Date: 2026-07-19

This document records the final full-application polish pass against the two supplied requirements briefs. It distinguishes shipped behaviour from deliberately unavailable or unverified capabilities so the product never over-promises.

## Product and UI foundation

- The approved brand accent is centralised as `#C1FF72`; semantic foregrounds provide readable text and icons on lime.
- Light mode uses a warm white, extremely subtle textured backdrop. OLED-aware dark mode uses near-black semantic surfaces and a quieter texture.
- Theme mode supports System, Light, and Dark and persists locally.
- Shared typography, spacing, radius, border, motion, button, field, search, picker, segmented-control, surface, empty, loading, error, dialog, sheet, snackbar, switch, haptic, and navigation primitives are the default UI language.
- iOS routes use Cupertino-style back transitions and edge-swipe navigation through the app theme. Android keeps restrained platform-appropriate transitions.
- Tapping outside an input dismisses the keyboard globally. Changed primary forms ask whether to save, discard, or continue editing before leaving.
- Search, selection sheets, date/time pickers, and large list choices use accessible, scrollable shared surfaces rather than browser-style dropdown menus.

## Route and screen inventory

| Area | Primary states and actions | Connected records |
| --- | --- | --- |
| Authentication | Sign in, sign up, password visibility, validation, loading, friendly failure copy | Supabase Auth and workspace gate |
| Onboarding | Resumable profile, handle, services, working hours, first booking, revenue target, import preference, in-app alert preferences, completion | Auth metadata, workspace, business profile, settings, services, booking |
| Home | Personalised time-aware greeting, setup checklist, Today, calm attention, Money, Tasks, Notes, Coming up, recent activity | Clients, bookings, payments, tasks, notes, requests |
| Clients | Search, All/Active/Leads/Inactive, drag/swipe navigation, sort, add, import, edit, details, linked bookings/money/tasks | Canonical client plus related module records |
| Bookings | Schedule/Requests, Today/Upcoming/Past, list/calendar, add/edit/details, directions, linked client/payment/tasks | Client, service, booking, payment, task |
| Money | Made/Spent/Owed, periods, targets, income/expense creation and editing, payment state | Client and booking links |
| Tasks | Now/Later/Done, create/import/edit/detail, reminders, checklist, completion/reopen | Optional client and booking links |
| Notes | Search, All/Pinned/Clients/Bookings, create/import/edit, checklist/bullets | Optional client and booking links |
| Business Feed | Filtered computed activity and contextual navigation | Existing module data only; no duplicate feed table |
| Notifications | In-app activity centre, filtering, mark-read and preferences | Existing application records and local preferences |
| Profile | Business identity, services, hours, public profile, booking requests | Existing profile/settings/services/request data |
| Settings | Notifications, account, app appearance/maps, data import/export/delete, support | Existing repositories plus local device preferences |
| Imports | Contacts, calendar snapshot, client CSV, task text, note text/Markdown | Explicit user selection and tenant-scoped writes |

## New-user activation

- Onboarding is resumable and skippable where data is optional.
- The dashboard setup checklist uses real record state for first client, booking, and payment. It permanently hides when dismissed and automatically disappears when complete.
- Empty Clients, Tasks, and Notes screens provide focused creation plus privacy-first import actions. Empty booking views provide booking creation; Money exposes direct income and expense actions.
- No demo business data is silently inserted into a real workspace.

## Import support matrix

| Source | Support | Privacy and failure behaviour |
| --- | --- | --- |
| Device contacts | Supported | Permission requested only after intent; denied/restricted states, search, multi-select, review, duplicate handling, progress, per-record failures |
| Calendar events | Supported as explicit one-time import | User chooses calendar, range, events, and destination client; creates reviewable £0 bookings with source context |
| Client CSV | Supported | File selection, UTF-8/Latin-1 fallback, delimiter/header detection, field mapping, preview, validation, duplicates, progress, row failures |
| Task text/Markdown | Supported | Selected local files only; each non-empty line becomes a task after review |
| Note text/Markdown | Supported | Selected local files only; content is preserved in one note per file |
| OS reminder databases | Not connected | Platform APIs and cross-platform data shape are not sufficiently dependable for this release; text-file import is the honest fallback |
| Other apps' private note stores | Not connected | Workloop does not claim access to another app's private database; exported text/Markdown is supported |

## Capability truth table

- In-app notifications and repository-backed preference filtering are supported.
- Device push notifications and scheduled local reminders are not enabled and are labelled accordingly.
- Calendar import and ICS export are supported; continuous two-way calendar sync is not connected.
- Apple Maps and Google Maps directions are supported for saved booking addresses, with a remembered device-level preference.
- Google Places address suggestions are supported through the authenticated Supabase Edge Function; manual entry remains available.
- Public booking, privacy deletion, and production support email paths depend on their deployed Supabase/operational services and require staging verification before release.
- There is no AI assistant surface in the current product. No placeholder or fake assistant was added.

## Accessibility, responsive, and performance review

- Interactive shared controls target at least 44 logical pixels and expose semantic labels where icons stand alone.
- Semantic colours are theme-aware and the lime accent is not used as body text on white.
- Lists use lazy builders where record counts can grow; dashboard previews remain intentionally capped.
- Search and address requests are debounced; providers are invalidated narrowly after writes.
- Text scaling, compact-phone layout, landscape, tablet, VoiceOver/TalkBack, reduced motion, and weak/offline-network behaviour remain mandatory items in the release-device QA matrix.

## Security and data integrity

- No secret was added to the mobile bundle. Google Places remains server-mediated.
- Imports write only into the authenticated workspace and request device permissions only after the user chooses a source.
- Existing RLS and repository boundaries remain intact; no schema migration was introduced in this pass.
- Privacy export now reports partial-table warnings rather than presenting an incomplete export as complete.
- Account deletion uses the existing protected Edge Function and needs production operational verification.

## Release blockers and follow-up

1. Validate account deletion, public booking, and Google Places Edge Functions in the production project.
2. Publish and link final Terms and Privacy documents before store submission.
3. Decide whether to build a real APNs/FCM and local-scheduling notification delivery system; until then the UI must keep saying in-app only.
4. Run the manual two-user tenant isolation test and complete device accessibility/rotation/text-scale QA.
5. Add repository fakes and integration tests for the full client-to-booking-to-payment loop.
6. Continue splitting the largest legacy feature files in separate, behaviour-preserving changes.

## Verification record

- Required `source scripts/dev_env.sh`: repaired to resolve configured, sibling, PATH, or pinned local Flutter installations; the final mandated commands use this script successfully.
- Pinned Flutter 3.35.7 `flutter analyze`: passed with no issues.
- Full `flutter test --dart-define-from-file=.env`: all 88 tests passed.
- iOS profile build: passed and produced `build/ios/iphoneos/Runner.app`.
- Physical iPhone profile install and launch: passed; CoreDevice confirmed the Workloop process running on the connected iPhone.
- Wireless Dart VM attachment: timed out after launch, so the result is recorded as a successful device install/launch rather than an attached interactive debugging session.
- Android profile build: blocked before compilation because no Java runtime is installed or bundled on this machine.
