# Slate Current State

Last updated: 2026-05-31

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

### Dashboard

- Revenue card.
- Today pulse / business pulse.
- Today schedule.
- Tasks section.
- Notification access and unread count.
- Booking request visibility.
- Pull-to-refresh.
- Navigation callbacks into core modules.

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
- Delete expense.
- Weekly target progress.
- Comparisons vs last week/month/custom period foundation.
- Paid/unpaid/expenses/profit summary.
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
- Manual confirmation flow that creates/matches client and creates booking.
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
- Privacy export and deletion request.

### Security / Foundation

- `.env`-based Supabase config.
- `.env.example`.
- RLS policy contract.
- Live RLS enabled on current public tables.
- Schema contract.
- GitHub remote connected.
- Model serialization tests.
- `flutter analyze` clean at latest verification.
- `flutter test --dart-define-from-file=.env` passing at latest verification.

## Partially Completed Features

- Money expenses: create/delete exists; edit expense and richer category reporting are not complete.
- Calendar sync: account state and ICS export exist; real external provider sync does not.
- Notifications: in-app centre/preferences exist; APNs/FCM push delivery and Edge Functions are not complete.
- Recurring bookings: recurrence fields exist; full recurring creation/edit/exception UX is not complete.
- Public profile: request-booking MVP exists; full slot-selection/self-booking/pay-now is not complete.
- Privacy: export and deletion request exist; actual server-side deletion/purge workflow is not complete.
- Security: RLS enabled, but live duplicate policies and advisor warnings remain.
- Typed models: main models exist; some features still pass raw maps.
- Navigation: GoRouter exists, but many flows still use `MaterialPageRoute`.
- Testing: model/util tests exist; repository/widget/integration tests are still thin.

## Planned Features

Near-term:

- Finish Money daily-use workflow: edit expenses, expense categories, target editing, period switcher polish.
- Connect Money to Bookings: completed booking prompts payment, booking detail shows payment status.
- Improve booking request confirmation with the same strong booking form patterns.
- Clean Supabase policy duplicates and add missing indexes.
- Split oversized files.

V1 before beta:

- Production-grade reminders logic.
- Better notification scheduling and push foundation.
- Calendar sync hardening.
- Data export/delete completion.
- More robust QA around onboarding, auth, bookings, money, tasks, public profile.

Post-V1 / V2:

- Stripe/pay-now/deposits.
- Full public slot-selection booking engine.
- Reviews system.
- Intake forms.
- QR code export.
- Closure dates.
- Advanced analytics.
- AI assistant.
- Teams/staff.
- Marketplace/discovery only if product direction changes.

## Technical Debt

- Large files:
  - `lib/features/tasks/tasks_screen.dart` ~2037 lines.
  - `lib/features/appointments/add_appointment_screen.dart` ~1417 lines.
  - `lib/features/appointments/appointment_detail_screen.dart` ~1232 lines.
  - `lib/features/settings/widgets/settings_business_tab.dart` ~1215 lines.
  - `lib/features/finance/finance_screen.dart` ~1207 lines.
  - `lib/features/clients/client_detail_screen.dart` ~1061 lines.
- Mixed routing approach.
- Raw map payloads still used in several areas.
- Some legacy product/code names remain.
- Live Supabase has duplicate older policies.
- Performance advisor flags unindexed foreign keys on newer tables.
- No CI yet.
- No repository tests with mocked Supabase.
- Limited widget/integration tests.
- No crash/error reporting.
- No environment separation docs beyond `.env`.

## Priority Queue

1. Finish Money UX because it was just expanded and is closest to being production-useful.
2. Connect Money to Bookings so completing work leads naturally to payment tracking.
3. Clean live Supabase policy/index debt before adding more tables.
4. Refactor largest files in small safe slices.
5. Improve booking request confirmation UX.
6. Add repository and flow tests for bookings, money, tasks, CRM.
7. Build production notification delivery foundation.
8. Harden privacy/security for beta.

## Current Risk Level

Product risk: medium-low. The core loop is coherent.

Architecture risk: medium. The app is improving but several screens remain large.

Security risk: medium before production. RLS is enabled, but auth leaked password protection and policy cleanup remain.

UX risk: medium. Many screens are much stronger now, but Money/Settings/Booking Requests need polish.
