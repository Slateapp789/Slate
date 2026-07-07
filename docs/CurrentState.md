# Workloop Current State

Last updated: 2026-07-06

## Completed / Mostly Working Features

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
- Captures public handle.
- Captures services.
- Captures working hours, including split working blocks with breaks.
- Captures monthly revenue target, used as weekly finance target.
- Optional first booking.
- Creates workspace, member, settings, business profile, services, and first booking.

### Navigation

- GoRouter top-level routes.
- Main shell with glass/pill bottom navigation.
- Tabs: Home, Clients, Bookings, Money, Tasks.
- Floating action button with creation sheet.
- Tasks, Work/Bookings, and Payments routes can deep-link to shell indexes.
- Business Feed route opens from Home without adding a bottom navigation tab.

### Dashboard

- Revenue card.
- Today pulse / business pulse.
- Morning Briefing with rules-based next-action recommendation.
- Today schedule.
- Tasks section.
- Daily Command preview of computed Business Feed activity.
- Notification access and unread count.
- Booking request visibility.
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

- Client list.
- Search and filtering/sorting.
- Simplified rows showing useful business signals rather than contact clutter.
- Add client.
- Edit client.
- Delete client with confirmation.
- Client detail with call/email actions.
- Notes and important notes.
- Status/source/tags/birthday/preferred contact method fields.
- Client booking history.
- Client payment history.
- Client task history.
- Client overview timeline and follow-up task creation.

### Bookings

- User-facing Bookings built on `appointments`.
- Today / Upcoming / Past views.
- Calendar view with selected-date list.
- Next booking card.
- Add booking.
- Edit booking.
- Change date/time/duration/service/price/client/location/notes/status.
- Business/client/online location choices.
- Inline client creation in new booking.
- Custom service name, duration, and price.
- Conflict checks.
- Linked tasks in booking detail.
- Booking status controls: scheduled, completed, cancelled/no-show style workflows.
- Calendar export / ICS flow.

### Tasks

- Open/done/all and priority/section views.
- Add task.
- Edit task.
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

### Money

- User-facing Money built partly on `invoices`.
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

- Business info.
- Business profile controls.
- Handle/profile link.
- Services add/edit/delete/show-on-profile.
- Working hours editing.
- Booking settings.
- Revenue target.
- Notification settings.
- Calendar sync entry point.
- Account email/password/sign out.
- Privacy export and account deletion request flow.

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

- UI system: the 2026-07-07 whitespace-first refoundation now has canonical `Workloop*` screen primitives for headers, metrics, rows, filters, segmented controls, empty states, buttons, bottom nav, FAB, and surfaces. Some settings child tabs, onboarding steps, auth, notification, public profile, form, sheet, and detail widgets still contain local `Container`/`AppColors` styling that should be migrated to shared theme tokens and row/divider primitives before enabling real dark mode.
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
