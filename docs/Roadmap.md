# Slate Roadmap

Last updated: 2026-05-31

## Current Milestone: V1 Operating Loop Stabilisation

Goal:

Make `Client -> Booking -> Work -> Payment -> Repeat` feel coherent, safe, fast, and polished.

Current focus:

- Money tracking has just been expanded.
- Expenses table and RLS are live.
- Next work should finish Money UX and connect it to bookings.

Dependencies:

- Existing workspace/auth/RLS.
- Payments/invoices and expenses repositories.
- Booking detail and add/edit booking flows.
- Dashboard finance pulse.

Exit criteria:

- Money can be used daily without confusion.
- Completing a booking can lead to payment state.
- Dashboard shows the most useful money signals.
- No known runtime overflows or red screens.
- Analyze/tests pass.

## Next Milestone: Beta Foundation

Goal:

Prepare the app for early real users without overbuilding.

Scope:

- Clean Supabase duplicate policies and missing indexes.
- Add repository tests for core domains.
- Add widget/smoke tests for auth gate, onboarding gate, shell, dashboard, bookings, tasks, money.
- Split the largest files enough that future work is safer.
- Finish booking request confirmation UX.
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

Make Slate safe enough for paying users.

Scope:

- Enable leaked password protection.
- Complete account deletion server-side purge.
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

Turn Slate into a trusted daily assistant without notification fatigue.

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

## Future Milestone: Payment Expansion

Goal:

Upgrade Money from tracking to collection when the core UX is stable.

Scope:

- Pay-now links.
- Stripe connection.
- Deposits.
- Public invoice/payment links.
- Payment receipts.

Dependencies:

- Stable Money tracking.
- Public profile routes.
- Security/privacy review.
- Stripe integration design.

## Future Milestone: V2 Intelligence and Scale

Goal:

Expand only after V1 proves daily retention.

Possible scope:

- AI assistant.
- Advanced analytics.
- Teams/staff.
- Reviews.
- Intake forms.
- Advanced recurring bookings.
- Workflow automation builder.

Rule:

Do not build these until the V1 loop is stable with real usage feedback.
