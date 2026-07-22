# Workloop Current State

Last updated: 2026-07-19

## Completed / Mostly Working Features

### Final application foundation

- System, Light, and OLED-aware Dark appearance modes use one semantic theme and a centralised `#C1FF72` brand accent.
- A shared, restrained textured backdrop now connects the main application, onboarding, profile, settings, support, calendar tools, notifications, and import flows.
- Shared fields, search, pickers, sheets, dialogs, buttons, switches, haptics, motion, loading, empty, error, and success states form the canonical interaction system.
- A resumable onboarding preferences step, real-record dashboard setup checklist, and action-led empty states guide first value without inserting demo data.
- Privacy-first import supports selected contacts, one-time calendar events, client CSV, task text, and note text/Markdown. Unsupported private stores are labelled honestly.
- In-app notifications are supported. Push delivery and scheduled local reminders are explicitly not claimed as enabled.
- See `docs/FinalPolishAudit.md` for the route/state matrix, integration truth table, and release blockers.

### Auth

- Email/password sign up.
- Email/password sign in.
- Sign out.
- Password update from settings.
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
- Main shell with a four-item glass/pill bottom navigation: Home, Clients, Bookings, More.
- More keeps Money, Tasks, Notes, Profile, and Settings one tap away without crowding the primary navigation.
- The oversized global create button has been removed; Clients, Bookings, Money, Tasks, and Notes expose a consistent compact create action in each feature header.
- Tasks, Notes, Work/Bookings, and Payments routes can deep-link to their shell screens while More remains the active navigation destination for secondary modules.
- Business Feed route opens from Home without adding a bottom navigation tab.
- Tapping outside an active text field dismisses the keyboard consistently across every route while taps within the field keep editing active.

### Dashboard

- Calm daily overview ordered around Today, Worth a look, Money, quick access, Coming up, and Recent activity.
- Visual hierarchy stays close to the original flat dashboard, with a very quiet paper-like backdrop, a stronger Today heading, and higher-contrast operational metadata adding depth without more cards or decorative colour markers.
- Time-aware personalised greeting includes the current date.
- Today shows only the next remaining booking plus a quiet count of later bookings; Coming up excludes today and is capped at three rows.
- Worth a look is optional, neutrally worded, capped at two rows, and uses no alarming totals, badges, or urgency colours.
- Money is a compact received-this-month row rather than a dominant hero card.
- Tasks and Notes use two small, low-contrast utility cards so they read separately from Money without adding visual noise.
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
- Inline client creation in new booking.
- Custom service name, duration, and price.
- Working-hours exceptions show a calm confirmation and remain bookable by choice; real appointment conflicts remain blocked.
- New and edited clients and bookings protect changed drafts with Save, Discard, and Keep editing choices before leaving.
- Linked tasks in booking detail.
- Booking status controls: scheduled, completed, cancelled/no-show style workflows.
- Calendar export / ICS flow.
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
- Checklist item creation, editing, toggling, deletion.
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
- Settings is intentionally separate and contains only Alerts, Account, and App preferences.

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
- Public insert into `booking_requests`.

### Booking Requests

- In-app booking request triage.
- Status update.
- Manual confirmation flow that checks/edits client, phone, service, date, time, duration, price, location, private notes, and optional payment due before creating the booking.
- Decline confirmation before closing a request.
- Notification creation on request/confirmation paths.

### Notifications

- Notification centre.
- Read/unread state.
- Mark read/all read.
- Preferences screen.
- App-side notification records for selected events.
- Push token table exists for future push delivery.

### Settings

- Calm Settings overview with account identity and dedicated Account, Notifications, and App preferences destinations.
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
- Schema contract.
- GitHub remote connected.
- Model serialization tests.
- `flutter analyze` clean at latest verification.
- `flutter test --dart-define-from-file=.env` passing at latest verification.

## Partially Completed Features

- Money-to-booking workflow: new bookings and completed bookings can create linked payments; more end-to-end QA is still needed.
- Calendar sync: account state and ICS export exist; real external provider sync does not.
- Notifications: in-app centre/preferences exist; APNs/FCM push delivery and Edge Functions are not complete.
- Recurring bookings: recurrence fields exist; full recurring creation/edit/exception UX is not complete.
- Public profile: request-booking MVP exists; full slot-selection/self-booking/pay-now is not complete.
- Privacy: export and account deletion request/completion foundation exists; operational QA/SLA documentation is still needed before production.
- Security: RLS enabled, public profile/request tables are no longer directly public, and advisors currently only flag leaked password protection plus low-traffic unused-index info.
- Typed models: main models exist; some features still pass raw maps.
- Navigation: GoRouter exists, but many flows still use `MaterialPageRoute`.
- Testing: model/util tests exist; repository/widget/integration tests are still thin.

## Planned Features

Near-term:

- QA Money daily-use workflow across real device and simulator.
- QA Money-to-Bookings across new booking, completed booking, paid/unpaid, and dashboard refresh.
- QA booking request confirmation on real device.
- Monitor Supabase advisors and enable leaked password protection before beta.
- Continue splitting oversized files.

V1 before beta:

- Production-grade reminders logic.
- Better notification scheduling and push foundation.
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
- Supabase advisors now only flag leaked password protection plus expected low-traffic unused-index info.
- No CI yet.
- No repository tests with mocked Supabase.
- Limited widget/integration tests.
- No crash/error reporting.
- No environment separation docs beyond `.env`.

## Priority Queue

1. QA and polish Money UX because it is now connected enough to be used daily.
2. QA booking-to-payment loops so completing work leads naturally to payment tracking.
3. Enable leaked password protection and keep Supabase advisor output clean before beta.
4. Continue refactoring largest files in small safe slices.
5. QA booking request confirmation UX.
6. Add repository and flow tests for bookings, money, tasks, CRM.
7. Build production notification delivery foundation.
8. Harden privacy/security for beta.

## Current Risk Level

Product risk: medium-low. The core loop is coherent.

Architecture risk: medium. The app is improving but several screens remain large.

Security risk: medium before production. RLS/public boundaries are stronger, but auth leaked password protection and production deletion operations still need hardening.

UX risk: medium. Many screens are much stronger now, but Money/Settings/Booking Requests need polish.
