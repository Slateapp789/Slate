# Workloop Current State

Last updated: 2026-07-30

## Completed / Mostly Working Features

### 2026-07-30 visual hierarchy and daily-focus pass

- Root workspaces now separate three attention levels: one labelled primary
  action, one contextual focus area where the feature needs it, and quieter
  filters/content. Clients, Bookings, Money, Tasks, and Notes no longer rely on
  an unlabeled `+` as the main create affordance.
- Home now leads with a state-driven daily-focus surface for an in-progress
  booking, the next booking today, or a clear day. The greeting is quieter,
  the focus action is explicit, and in-progress bookings remain visible until
  their end time.
- Dashboard attention uses the existing actionable copy and prioritises an
  imminent unconfirmed booking, then overdue work, overdue payment follow-up,
  and stale leads. Task and note shortcuts show live counts when available.
- Bookings retains Schedule/Requests as peer navigation while List/Calendar
  and Today/Upcoming/Past use quieter graphite selection. Client, task, note,
  and other filter states use the same subordinate hierarchy.
- Shared section headings now form visible sentence-case divisions; dense
  chronological groups use a quiet variant. Empty states are inline by default
  so whitespace and typography carry hierarchy without another bordered card.
- Booking completion/cancellation decisions sit directly below the booking
  hero and time context rather than after every disclosure. Public profiles
  expose a prominent booking-request action beside the business proposition.
- Tools replaces the generic More label and presents Money, Tasks, and Notes as
  three equal full-width workspace rows. Profile and Settings move to compact
  direct controls beside the Home greeting.
- Root empty states no longer repeat the same neon create action already
  present in the header. Imports remain available as quiet secondary paths.
- Bookings keeps Schedule/Requests as its only full-width workspace decision;
  Today/Upcoming/Past shares one row with a compact List/Calendar mode control.
- Pushed detail, editor, import, support, legal, calendar, task, note, client,
  booking, income, and expense screens now share `WorkloopRouteHeader`.
- Settings makes the identity surface the Account destination, Profile removes
  duplicated snapshot links, Booking Requests uses Active/New/Closed, and
  import screens use one route title instead of competing headlines.

### Final application foundation

- Workloop ships with one fixed Dark appearance. The graphite canvas was lifted
  slightly to `#151A16`, with layered `#1C231D`, `#252E26`, and `#2C372D`
  surfaces so it remains calm without feeling black or oppressive. The exact
  icon and launch-artwork neon `#C1FF72` remains the restrained brand accent,
  with dark `#17200D` content on neon fills and tested contrast pairs.
- Instrument Sans is bundled with its licence so launch typography does not
  depend on a runtime font download. The app-wide weight scale is capped at
  semibold, with regular-weight body copy for a calmer, more minimal hierarchy.
- A shared, restrained textured backdrop now connects the main application, onboarding, profile, settings, support, calendar tools, notifications, and import flows.
- Shared fields, search, pickers, sheets, dialogs, buttons, switches, haptics, motion, loading, empty, error, and success states form the canonical interaction system.
- A resumable onboarding preferences step, real-record dashboard setup checklist, and action-led empty states guide first value without inserting demo data.
- Privacy-first import supports selected contacts, one-time calendar events, client CSV, task text, and note text/Markdown. Partial attempts retain only failed records for retry so already-created records are not duplicated. Unsupported private stores are labelled honestly.
- In-app notifications and on-device task/booking reminders are supported on iOS and Android. Task reminders follow the selected timing; opted-in booking reminders are scheduled about 15 minutes before the booking. Tapping a reminder routes back into Workloop. Remote APNs/FCM push delivery is not claimed.
- See `docs/LaunchReadiness.md` for the current release gate. `docs/FinalPolishAudit.md` remains a historical snapshot of the earlier July polish pass.

### 2026-07-28 final UI/UX refinement

- The four-destination shell remains Home, Clients, Bookings, and Tools. Root
  screens keep one measured header grid, while pushed Profile, Settings, and
  Notifications routes now use one responsive route-header primitive.
- Bookings now separates peer navigation (Schedule and Requests) from display
  controls (List and Calendar) and time filters. The next booking is not
  repeated in list mode, request rows open the selected request, and failed
  schedule/request loads offer a specific retry.
- Booking creation and request conversion retain entered context through
  recoverable failures. Public requests use persistent labels and inline
  validation; conversion keeps its sheet and draft open, checks conflicts and
  working hours, and reports the exact recovery action. Booking-to-client
  navigation resolves the canonical client instead of constructing a partial
  record.
- Money renders each operating section from its own provider state, so a
  target, invoice, or expense failure does not hide unrelated financial
  information. Tasks, Business Feed, Notifications, deletion, onboarding
  handle checks, and calendar import now expose bounded retry paths.
- Calendar imports use the same validated, atomic, idempotent booking workflow
  as manual creation. Failed events remain selected with their exact reason.
- Bottom navigation and Tools launchers expose invokable semantic actions;
  checklist controls keep a compact appearance with 44-point targets; success
  and error feedback use live regions where appropriate; reduced-motion and
  large-text layouts are protected by responsive tests.
- Final local UI evidence: formatting is clean, Flutter analysis reports no
  issues, all 285 Flutter tests pass, the 11-test golden suite passes in
  non-update mode, iOS and Android profile artifacts compile, and the current
  iOS profile launched on the physical iPhone with a Dart VM Service and a
  confirmed running process. Manual VoiceOver, TalkBack, permission, offline,
  lifecycle, and physical Android coverage remain launch gates.

### 2026-07-28 dark-only usability and edge-case pass

- System and Light appearance selection, persisted theme preference logic, and
  the Settings appearance destination were removed. Native iOS and Android
  launch windows now use the same graphite background, preventing a white
  startup flash before Flutter paints.
- The responsive matrix now renders 11 launch surfaces across six phone
  viewports and two text scales: 132 combinations plus keyboard reachability.
  Settings and the booking-request inbox are included.
- A booking-request empty state that overflowed by 337 logical pixels on a
  320x568 phone at 200% text now scrolls and remains centred when space allows.
- Dark-only theme contracts, native startup colour, Settings ownership, and
  feature-action geometry are protected by targeted regression tests.
- The focused usability suite passes 86/86 tests, the full Flutter suite passes
  280/280, formatting and static analysis are clean, and iOS/Android profile
  builds pass. The signed-out simulator integration journey passes and the
  physical iPhone profile exposed a Dart VM Service with a confirmed running
  process.

### Auth

- Email/password sign up.
- Email/password sign in.
- Sign out.
- Password update from settings.
- Password recovery through the `workloop://reset-password` deep link, subject to the production Supabase redirect and email-delivery configuration.
- Session-based auth gate.
- Workspace gate.

### Onboarding

- Multi-step onboarding.
- Captures business profile basics.
- Persists the owner's preferred first name in Supabase Auth metadata for personalised app greetings.
- Captures public handle.
- Captures services.
- Captures working hours, including split working blocks with breaks.
- Captures monthly revenue target, used as weekly finance target.
- Optional first booking.
- Creates workspace, member, settings, business profile, services, and first booking.

### Navigation

- GoRouter top-level routes.
- Main shell with a four-item glass/pill bottom navigation: Home, Clients,
  Bookings, Tools.
- Tools presents Money, Tasks, and Notes as equal, full-width operating
  workspaces. Profile and Settings are direct secondary controls in the Home
  header rather than content sections in the daily dashboard.
- Clients, Bookings, Money, Tasks, and Notes expose the same labelled neon
  create action in each feature header. Money opens a two-choice sheet for
  income or expense instead of mixing unrelated controls.
- Shell headers share one safe-area top grid, header type treatment, 24-point
  header-to-content rhythm, and bottom-navigation clearance.
- Tasks, Notes, Work/Bookings, and Payments routes can deep-link to their shell
  screens while Tools remains the active navigation destination for secondary
  modules.
- Business Feed route opens from Home without adding a bottom navigation tab.
- Tapping outside an active text field dismisses the keyboard consistently across every route while taps within the field keep editing active.
- Tapping the native iOS status bar or the app's top edge returns the visible
  vertical screen to its beginning. Every vertical scroll view is discovered
  centrally, including implicit and nested controllers. Render visibility and
  hit testing exclude hidden PageView/TabBarView children. One tap across the
  non-interactive top/header zone resets every visible vertical layer with a
  distance-aware animation while leaving header buttons to perform only their
  own actions. Home, Clients, Bookings, Money, Tasks, Notes, and Tools retain
  independent scroll targets rather than resetting an offstage tab.
- Clean pushed routes retain native iOS interactive back swipes and Android
  system back gestures, including finger-tracked reveal and cancellation. A
  route-aware fallback is reserved for direct routes and draft-protected
  editors; it acts only after pointer-up and still invokes the same
  Save/Discard/Keep editing decision. Reminder navigation pushes onto the
  current history instead of replacing it.
- Money, Tasks, and Notes also retain the shell workspace that launched them.
  Their iOS back swipe now moves with the finger, reveals that workspace with
  Cupertino-style parallax, and can be cancelled before returning—normally to
  Tools, or Home when Money was opened from a Home follow-up.
- Clients gives the top shortcut precedence over a tappable client row occupying
  the top zone after scrolling. Filter changes remain explicit through the
  visible filter rail rather than a competing full-screen horizontal gesture.

### Dashboard

- Calm daily overview ordered around Today, Worth a look, Money, quick access,
  Coming up, and Recent activity.
- Today is the single focal surface. It distinguishes an in-progress booking,
  the next booking, and a clear day, then exposes one explicit action.
- Time-aware personalised greeting includes the current date.
- Today keeps an in-progress booking visible until its end time and adds a quiet
  count of later bookings; Coming up excludes today and is capped at three rows.
- Worth a look is optional, capped at two rows, and keeps direct action-led copy
  without alarm-heavy colour.
- Money is a compact received-this-month row rather than a dominant hero card.
- Tasks and Notes use two small, low-contrast utility cards with live counts so
  they read separately from Money without adding visual noise.
- Recent activity is capped at three calm items and excludes attention/overdue/unpaid warning states.
- Dashboard rows and section actions open the related booking detail or owning feature.
- Pull-to-refresh.
- Navigation callbacks into core modules.

### Business Feed

- Computed feed generated from existing bookings, clients, payments, expenses, tasks, notes, booking requests, and weekly target progress.
- Feed item types include today's bookings, upcoming bookings, payment received, unpaid/overdue invoices, expenses, due/overdue tasks, notes, client follow-ups, booking requests, quiet-day detection, daily summary, and weekly target progress.
- Home preview appears inside Daily Command with a View all action.
- Full Business Feed screen includes All, Needs attention, Money, Bookings, Tasks, and Clients filters.
- Feed row taps route to the most useful existing module or booking request screen where exact detail routes do not yet exist.
- No persisted feed table or AI dependency has been introduced.

### Clients / CRM

- Calm, whitespace-first client list aligned with the dashboard's title scale, top spacing, paper-like backdrop, text hierarchy, and continuous divider-led rows.
- Client sorting supports Next booking, A–Z, Recently booked, Recently added, and Most booked without additional database queries.
- Client sorting is presented as a compact single-line choice menu with a quiet selected state rather than a second list of full record-style rows.
- Search across client names, contact details, and tags, with bottom-navigation-inspired All/Active/Leads/Inactive views that can be changed by tapping, dragging the selected capsule across the selector, or swiping horizontally across the screen.
- Active and Inactive remain distinct status views; inactive contacts also carry a quiet neutral label inside All.
- Changing client views returns the portfolio to the top, and each empty category has calm, contextual guidance.
- Add and Edit client use one canonical form with the dashboard/client textured shell, shared field styling, and identical Contact information, Client settings, Booking address, Client notes, and Additional information sections.
- The shared Booking address field supports debounced UK Google Places autocomplete through an authenticated Supabase Edge Function, suggestions that remain visible while the surrounding form is repositioned, and an independently scrollable and explicitly dismissible result list. It deliberately stays as one field: users start with the first line of an address for suggestions, or keep any manually typed value such as a postcode. Building-level matches preserve typed flat/unit labels, selection remains immediate with manual fallback, and the Google key stays out of the mobile app.
- Saved client booking addresses open driving directions in Apple Maps or Google Maps. Users can choose per launch, remember a choice from the directions sheet, or change the device-level default under App settings.
- Client entry validates optional email addresses, explains relationship statuses, warns when the selected contact channel has no matching detail, and blocks duplicate phone/email records before saving.
- Lead source, tags, and birthday remain progressively disclosed; destructive deletion stays separate from Save, and backing out of an edited client offers to preserve or discard the draft.
- Delete client with confirmation.
- Client workspace with a compact relationship header, call/email actions, textured backdrop, and draggable Overview/Bookings/Money/Tasks navigation aligned with the app shell.
- Notes and important notes.
- Status/source/tags/birthday/preferred contact method fields.
- Client overview prioritises the next booking, a restrained relationship snapshot, calm follow-up rows, useful context, and three recent activities rather than repeating full module histories.
- Client booking history is repository-backed, opens canonical booking details, and creates bookings with the client preselected.
- Client payment history is repository-backed, supports direct recording/editing, and distinguishes received, remaining, paid, part-paid, and unpaid amounts without alarm styling.
- Client task history uses the shared task repository and contact relationship, invalidates the main Tasks state, and links directly to the full Tasks workspace.

### Bookings

- User-facing Bookings built on `appointments`.
- Calm Schedule / Requests workspace using the same textured backdrop, typography, spacing, segmented controls, and feature-header action as Home and Clients.
- List mode with Today / Upcoming / Past views and a concise next-booking summary.
- Calendar mode with month navigation, a Today shortcut, selected-date list, and selected-date hand-off when adding a booking.
- Add and inline Edit booking forms share the client form visual language, keyboard dismissal, calm input surfaces, and progressive booking sections.
- Change date/time/duration/service/price/client/location/notes/status.
- Business/client/online location choices; physical locations use the shared Google Places address search and can reuse the selected client's saved booking address.
- Saved physical booking locations open directions using the shared Apple Maps / Google Maps device preference.
- Booking creation is routed through an authenticated, atomic, idempotent workflow that validates workspace relationships, serialises conflict checks, and can create recurring occurrences, an inline client, a linked payment, a follow-up task, request status, and in-app notification without exposing a partially-created workflow.
- Booking completion and its linked payment/notification handling use a separate atomic, idempotent workflow.
- Inline client creation in new booking.
- Custom service name, duration, and price.
- Working-hours exceptions show a calm confirmation and remain bookable by choice; real appointment conflicts remain blocked.
- New and edited clients and bookings protect changed drafts with Save, Discard, and Keep editing choices before leaving.
- Linked tasks in booking detail.
- Booking status controls: scheduled, completed, cancelled/no-show style workflows.
- Explicit calendar-event import and a point-in-time `.ics` file export. Workloop does not represent this as live or two-way calendar sync.
- Dashboard and client booking rows continue to open the canonical booking detail; booking detail links back to the canonical client workspace and shared Money and Tasks records.

### Tasks

- Calm Now/Later/Done workspace with Overdue, Today, Anytime, and future sections.
- Task rows open a dedicated detail screen while preserving deliberate completion actions.
- Add and Edit task use a full-screen form aligned with Client and Booking creation, including progressive options and Save/Discard/Keep editing protection.
- Delete task.
- Reopen task.
- Deliberate completion.
- Priority.
- Due date shortcuts/custom date.
- Reminder timing.
- Client and booking linking.
- Quick task templates.
- New task and initial checklist creation is one authenticated, atomic, idempotent workflow.
- Checklist item creation, editing, toggling, deletion.
- Real on-device reminders with permission-aware validation and safe reconciliation on app resume.
- Client task rows no longer complete instantly.

### Notes

- Calm searchable notes workspace with All, Pinned, Clients, and Bookings filters.
- Full-screen note editor aligned with the shared textured app shell and page hierarchy.
- First line acts as the note title while the remaining text supports paragraphs, checklists, and bullets.
- Pin remains a visible editor action; delete sits behind a secondary actions menu and retains confirmation.
- Compact labelled checklist and bullet controls remain available above the keyboard and preserve layout stability.

### Profile

- Profile is a dedicated owner-and-business overview instead of an alias for the Business settings tab.
- The identity area stays business-focused and uses the shared textured workspace shell and Workloop typography. Personal account controls live only in Settings.
- A compact snapshot links directly to Services, Working hours, and active Booking requests.
- Business and Online sections use shared divider-led rows rather than nested settings cards.
- Public profile preview uses the already-loaded authenticated workspace data and the same native navigation stack, avoiding a blank owner preview while public deep links continue through the secured Edge Function.
- Business details, Working hours, Public profile, and Services use dedicated Profile-owned screens while reusing the established repositories and save logic. Business Info includes the owner's preferred name, business name, and industry. Working hours use scrolling time wheels in a direct full-screen day-by-day editor.
- Booking requests use a compact, filterable inbox. Each request opens a focused detail screen for calling, marking contacted, declining, or converting into a booking.
- Settings is intentionally separate and contains Account, Notifications, and
  App preferences. Workloop has no user-selectable appearance.

### Money

- User-facing Money built partly on `invoices`.
- Calm three-section Money workspace aligned with Home, Clients, and Bookings: plain-language Made / Spent / Owed navigation, one primary figure per section, period controls for Made and Spent, period-aware target progress, category summaries, and one divider-led owed list.
- Compact top actions create income or expense entries without a floating action button.
- Record payment.
- Edit payment.
- Mark payment as received.
- Delete payment.
- Paid/unpaid tracking.
- Overdue refresh logic.
- Add expense.
- Edit expense.
- Delete expense.
- Expense category summary.
- Week/month/custom period switcher.
- Weekly target progress.
- Weekly/monthly target editing from Money.
- Comparisons vs last week/month/custom period foundation.
- Paid/unpaid/expenses/profit summary.
- Booking-linked payment rows through `appointment_id`.
- Supabase-backed `expenses` table with RLS.
- Add/Edit Income and Add/Edit Expense use the same Money form sections, amount field, picker treatment, date rows, page hierarchy, keyboard behaviour, and Save/Discard/Keep editing protection.

### Public Business Profile

- Public route `/p/:handle`.
- Business info.
- Services.
- Working hours.
- Gallery/review fields where configured.
- Notice banner.
- Request-booking form.
- Public request creation through the bounded `create-booking-request` Edge
  Function; anonymous clients do not write the table directly.
- The request path uses a stable client request token, bounded server validation, a honeypot, source/phone rate limits, profile/service ownership checks, and a server-created owner notification. Manual entry remains available if public booking is unavailable.

### Booking Requests

- In-app booking request triage.
- Status update.
- Manual confirmation flow that checks/edits client, phone, service, date, time, duration, price, location, private notes, and optional payment due before atomically creating the booking and updating the request.
- Decline confirmation before closing a request.
- Notification creation on request/confirmation paths.

### Notifications

- Notification centre.
- Read/unread state.
- Mark read/all read.
- Preferences screen.
- App-side notification records for selected events.
- On-device task and booking reminders with tap-through navigation.
- Push token table exists for future push delivery.

### Settings

- Calm Settings overview with account identity and dedicated Account,
  Notifications, and App preferences destinations.
- The app uses one fixed dark semantic palette; there is no appearance state,
  persisted mode, or OS-brightness transition to reconcile.
- App preferences is reserved for maps, calendar, and Workloop information.
- Account owns preferred name, email, password, workspace export, account deletion request, and sign out.
- Notifications owns booking, payment, task, follow-up, digest, summary, and quiet-time preferences.
- App preferences owns the default maps choice, calendar connection entry point, and concise build information.
- Business details, public profile, services, working hours, and booking requests remain in Profile rather than being duplicated in Settings.
- Legacy tab navigation, nested settings cards, unfinished payment placeholders, and duplicate feature-directory links have been removed.

### Security / Foundation

- `.env`-based Supabase config.
- `.env.example`.
- RLS policy contract.
- Live RLS enabled on current public tables.
- Public profile and booking request access routed through Edge Functions.
- Account deletion request/completion Edge Functions exist; completion remains admin-token gated.
- Request and completion source independently require the requester to be the workspace's sole member before destructive deletion can proceed.
- Authenticated task and booking workflow RPCs use bounded public wrappers, private tenant-validating implementations, and per-user/workspace idempotency records.
- Public booking and Places Edge Function paths use private rate-limit state; direct anonymous table grants remain removed.
- Six launch migrations are live: `20260726000048`, `20260726000057`,
  `20260726000102`, `20260726000110`, `20260726000118`, and the explicit
  client-deny policy `20260726000520`. Current Edge deployments are
  `create-booking-request` v8, `places-address-search` v8,
  `get-public-profile` v6, `request-account-deletion` v6, and
  `complete-account-deletion` v9; structural, grant, and advisor smoke checks
  passed.
- The audit candidate additionally contains migration `20260726005736` and
  updated booking-request Edge source. Production was not changed during this
  audit; clean replay and isolated staging validation are required before
  promotion.
- Schema contract.
- GitHub remote connected.
- iOS launch scope is iPhone portrait on iOS 13+; Android is portrait with minimum API 24 and target/compile API 36.
- CI is defined for Flutter 3.44.8 formatting, analysis, tests, Deno formatting/type checks/tests, Android profile and web builds, plus a separate unsigned iOS profile build on macOS. Android uses Gradle 8.14.3, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, and Java 17.
- Model serialization tests.
- `flutter analyze` clean at latest verification.
- `flutter test --dart-define-from-file=.env` passing at latest verification.

### 2026-07-26 comprehensive-audit candidate evidence

- Dart formatting checked 186 files with no changes; `flutter analyze` reported
  no issues; all 249 Flutter tests passed in approximately 33 seconds with
  40.10% line coverage.
- Eleven launch-golden tests produced 13 reviewed images and passed again
  without updating expectations. The responsive harness passed 108 phone/text-scale
  renders plus keyboard safety.
- All 19 Edge Function unit tests passed, with Deno formatting, lint, and six
  entry-point type checks clean.
- OSV-Scanner 2.4.0 found no known issue in 132 resolved Dart packages. Deno
  and CocoaPods lock formats were unsupported by that scanner; six direct
  Flutter packages are behind latest and were reviewed without blind upgrades.
- Signed-out Auth/navigation integration passed on an iPhone 17 Pro simulator.
  iOS simulator debug plus unsigned device profile/release compilation passed,
  and the `workloop://` recovery scheme is registered.
- The current 34.8 MB profile installed and launched on the physical iPhone;
  the launch command completed successfully and the Workloop process was
  confirmed running through CoreDevice.
- Android debug/profile compilation passed with package
  `com.ismaeel.workloop`, minimum API 24, target/compile API 36, and portrait
  activity. The profile APK passed `zipalign -c -P 16 -v 4` and signature
  verification.
- The web release build passed. Android App Bundle release signing fails closed
  until the production upload keystore is supplied; no debug-signing fallback
  exists. iOS App Store export remains blocked by missing Distribution signing.
- Clean database replay, all 43 pgTAP assertions, authenticated/two-account
  staging E2E, public booking conversion, deletion completion, measured
  performance/load, physical Android, and full assistive-technology QA remain
  open. The evidence-based verdict is not public-launch ready.

## Partially Completed Features

- Money-to-booking workflow: new bookings and completed bookings use atomic linked-payment workflows; production-like end-to-end and real-device QA is still needed.
- Calendar integration: explicit event import and point-in-time `.ics` export exist; real external provider sync does not.
- Notifications: in-app centre/preferences and on-device task/booking reminders exist; APNs/FCM cross-device push delivery does not.
- Recurring bookings: recurrence fields exist; full recurring creation/edit/exception UX is not complete.
- Public profile: request-booking MVP exists; full slot-selection/self-booking/pay-now is not complete.
- Privacy: export and sole-owner-guarded account deletion request/completion are deployed; the production secret, destructive disposable-account test, and operational SLA still require release evidence.
- Security: RLS enabled, public profile/request tables are no longer directly
  public, and the security advisor now reports only the leaked-password
  protection warning. Low-traffic unused-index notices belong to the separate
  performance advisor.
- Typed models: main models exist; some features still pass raw maps.
- Navigation: GoRouter exists, but many flows still use `MaterialPageRoute`.
- Testing: 285 Flutter tests, 19 Deno tests, responsive/golden suites, a
  signed-out iOS integration smoke, database contracts, and generator/load
  harnesses exist; dynamic database, authenticated staging, repository-fake,
  load, and physical-device coverage is still thinner than the launch risk
  warrants.

## Planned Features

Near-term:

- QA Money daily-use workflow across real device and simulator.
- QA Money-to-Bookings across new booking, completed booking, paid/unpaid, and dashboard refresh.
- QA booking request confirmation on real device.
- Monitor Supabase advisors and enable leaked password protection before beta.
- Continue splitting oversized files.

V1 before beta:

- Production validation of on-device reminder behaviour across permission, reboot, timezone, daylight-saving, and notification-tap states.
- Optional remote push foundation only after APNs/FCM can be operated reliably.
- Calendar sync hardening.
- Data export/delete operational hardening.
- More robust QA around onboarding, auth, bookings, money, tasks, public profile.

Post-V1 / V2:

- Stripe/pay-now/deposits.
- Full public slot-selection booking engine.
- Reviews system.
- Intake forms.
- QR code export.
- Closure dates.
- Advanced analytics.
- Teams/staff.
- Marketplace/discovery only if product direction changes.

## Technical Debt

- UI system: the canonical `Workloop*` primitives now cover headers, metrics, rows, filters, segmented controls, empty states, buttons, bottom navigation, fields, search, sheets, dialogs, pickers, haptics, motion, texture, and theme semantics. System/Light/Dark modes are enabled. Some large legacy screens still mix shared primitives with local layout containers and should be migrated gradually when those screens next change.
- Large files:
  - `lib/features/tasks/tasks_screen.dart` ~946 lines after extracting task card, task logic, task detail, and task editor parts.
  - `lib/features/tasks/task_logic.dart` ~280 lines.
  - `lib/features/tasks/task_card.dart` ~259 lines.
  - `lib/features/tasks/task_detail_widgets.dart` ~320 lines.
  - `lib/features/tasks/task_editor_widgets.dart` ~497 lines.
  - `lib/features/appointments/add_appointment_screen.dart` ~1200 lines after extracting appointment logic and reusable booking form widgets.
  - `lib/features/appointments/add_appointment_logic.dart` ~45 lines.
  - `lib/features/appointments/add_appointment_widgets.dart` ~328 lines.
  - `lib/features/appointments/appointment_detail_screen.dart` ~1217 lines after extracting private detail sections and time picker.
  - `lib/features/appointments/appointment_detail_sections.dart` ~375 lines.
  - `lib/features/settings/widgets/settings_business_tab.dart` ~1215 lines.
  - `lib/features/finance/finance_screen.dart` ~1087 lines after extracting target/activity widgets.
  - `lib/features/finance/finance_screen_widgets.dart` ~394 lines.
  - `lib/features/clients/client_detail_screen.dart` ~1061 lines.
- Mixed routing approach.
- Raw map payloads still used in several areas.
- Some legacy product/code names remain.
- Supabase security advisor now only flags leaked-password protection.
  Separate performance-advisor output still includes expected low-traffic
  unused-index notices.
- CI has not yet accumulated hosted-run history for this launch branch.
- `device_calendar` and `flutter_local_notifications` still use CocoaPods on
  iOS. Flutter 3.44 supports this hybrid build, but their Swift Package Manager
  support must be revisited before a future Flutter release makes it mandatory.
- No repository tests with mocked Supabase.
- Limited widget/integration tests.
- No crash/error reporting.
- No environment separation docs beyond `.env`.

## Priority Queue

1. Complete signed-out abuse, authenticated workflow, and destructive disposable-account end-to-end tests against the deployed Edge Functions and migrations.
2. Configure production Auth email/recovery, leaked-password protection, deletion secret, and Google Places restrictions.
3. QA booking/payment, task/reminder, public-request, import-retry, export, and deletion loops on a physical Android device and finish the accessibility/device matrix.
4. Publish the legal/support web surface, complete iOS/Android distribution signing, and finish both store declarations.
5. Preserve this release candidate in a reviewed commit/tag.
6. Add repository fakes, end-to-end flow coverage, and production crash/error reporting.
7. Continue refactoring the largest files only in small behaviour-preserving slices.

## Current Risk Level

Product risk: medium-low. The core loop is coherent.

Architecture risk: medium. The app is improving but several screens remain large.

Security risk: medium before production. RLS/public boundaries and destructive guards are stronger, but Auth leaked-password protection, production secrets, and live deletion/abuse-control verification remain release gates.

UX risk: medium-low in source, with physical-device accessibility, text-scale, compact-phone, permission, error, and Android coverage still required before launch.
