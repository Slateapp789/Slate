# Workloop Roadmap

Last updated: 2026-06-07

## Current Milestone: V1 Operating Loop Stabilisation

Goal:

Make `Client -> Booking -> Work -> Payment -> Repeat` feel coherent, safe, fast, and polished.

Current focus:

- Money tracking has just been expanded and linked into booking completion.
- Expenses table and RLS are live.
- Next work should QA the Money/Bookings/request loop and reduce large-file risk.

Dependencies:

- Existing workspace/auth/RLS.
- Payments/invoices and expenses repositories.
- Booking detail and add/edit booking flows.
- Dashboard finance pulse.

Exit criteria:

- Money can be used daily without confusion.
- Completing a booking can lead to payment state.
- Linked booking payments refresh cleanly in Money and booking detail.
- Public booking requests can be confirmed with clear client/service/time/payment details.
- Dashboard shows the most useful money signals.
- No known runtime overflows or red screens.
- Analyze/tests pass.

## Next Milestone: Beta Foundation

Goal:

Prepare the app for early real users without overbuilding.

Scope:

- Keep Supabase advisor output clean and resolve leaked password protection before beta.
- Add repository tests for core domains.
- Add widget/smoke tests for auth gate, onboarding gate, shell, dashboard, bookings, tasks, money.
- Continue splitting the largest files enough that future work is safer.
- QA booking request confirmation UX.
- Improve settings as a real control centre for defaults.
- Validate public profile request flow end to end.
- Add manual QA scripts for real-device testing.

Dependencies:

- Stable current feature behavior.
- Schema contract kept current.
- Git history clean.

Exit criteria:

- No analyzer warnings.
- Tests pass.
- RLS verified.
- Main flows manually QA'd.
- Known production blockers listed separately.

## Future Milestone: Production Hardening

Goal:

Make Workloop safe enough for paying users.

Scope:

- Enable leaked password protection.
- Exercise account deletion server-side purge and document the operational process.
- Complete data export coverage.
- Add error/crash reporting.
- Add CI for analyze/tests.
- Add environment separation.
- Add stronger logging/audit around destructive actions.
- Review all RLS policies and advisors.
- Consider biometric lock/2FA preferences.

Dependencies:

- Supabase plan/settings.
- Stable schema.
- Beta feedback.

## Future Milestone: Notifications and Reminders

Goal:

Turn Workloop into a trusted daily assistant without notification fatigue.

Scope:

- Edge Functions for notification delivery.
- APNs/FCM integration.
- Push token registration.
- Reminder scheduling.
- Quiet hours.
- Morning digest.
- Weekly summary.
- Payment/booking/task reminders.

Dependencies:

- Notification preferences table.
- Push token table.
- Reliable booking/payment/task state.
- Production auth and RLS.

## Future Milestone: Public Profile Growth

Goal:

Make the profile link valuable enough to replace a basic website and booking enquiry form.

Scope:

- QR code export.
- Closure dates.
- Stronger public profile settings.
- Better booking request conversion.
- Portfolio/gallery improvements.
- Optional social/contact controls.

Dependencies:

- Business profile fields.
- Services show-on-profile.
- Booking requests.

## Active Milestone: Payment Collection

Goal:

Upgrade Money from tracking to secure card collection without weakening the
existing booking and reconciliation workflow.

Scope:

- Stripe Connect onboarding, Tap to Pay, Checkout links, receipts, refunds, and
  webhook reconciliation are implemented and deployed in test mode. The
  platform fee remains disabled and live keys are blocked.
- Connected-account onboarding, simulated and physical-device/payment QA,
  Apple entitlement approval, and explicit live-mode approval remain before
  live use.
- Deposits and public-profile pay-now entry points remain future scope.

Dependencies:

- Stable Money tracking.
- Public profile routes.
- Security/privacy review.
- Apple Tap to Pay development and distribution entitlements.

## Future Milestone: V2 Intelligence and Scale

Goal:

Expand only after V1 proves daily retention.

Possible scope:

- Advanced analytics.
- Teams/staff.
- Reviews.
- Intake forms.
- Advanced recurring bookings.
- Workflow automation builder.

Rule:

Do not build these until the V1 loop is stable with real usage feedback.
