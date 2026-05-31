# Slate Product Vision

Last updated: 2026-05-31

## What Slate Is

Slate is the headquarters for solo appointment-based business owners.

It is a premium, calm, mobile-first business operating system that helps solo service businesses run their daily operations from one connected app. The core product loop is:

`Client -> Booking -> Work -> Payment -> Repeat`

Slate currently supports the main operating surfaces needed for that loop:

- Dashboard / HQ
- Clients / CRM
- Bookings and calendar
- Tasks and reminders
- Money tracking
- Public business profile and booking requests
- Notifications centre and preferences
- Settings, business profile, services, working hours, privacy export/request deletion

## Who Slate Serves

Slate is designed for solo appointment-based service businesses:

- Barbers and hairdressers
- Beauty and aesthetics professionals
- Personal trainers and fitness coaches
- Therapists and wellness practitioners
- Cleaners and home service providers
- Coaches, tutors, and mobile service operators
- Tattoo artists and other appointment-led operators

The target customer runs the business from their phone, has limited time for admin, and currently stitches together multiple tools such as calendars, notes, WhatsApp, spreadsheets, booking links, and payment trackers.

## Core Product Philosophy

Slate should reduce mental load. It should feel like a calm command centre, not another admin burden.

Product principles from Notion and current implementation:

- Calm over clutter.
- Daily utility over impressive feature lists.
- Mobile-first and thumb-friendly.
- Business context first.
- One clear primary action per screen.
- Connected operations across modules.
- Premium but simple.
- Fast daily use.
- No unnecessary complexity.

## Business Goals

Slate should become the first app a solo business owner opens each day.

Success looks like:

- Users manage most daily admin inside Slate.
- Users cancel or reduce reliance on fragmented tools.
- Users trust Slate for schedule, clients, money, tasks, and follow-ups.
- V1 proves retention through daily operational value before expanding into heavier modules.

## Current Scope

Current V1 scope is focused on solo appointment-based businesses. The app already implements a real MVP, not a blank prototype.

Current code scope includes:

- Email/password authentication through Supabase.
- Workspace onboarding with services, working hours, profile handle, revenue target, and first booking.
- Main shell with bottom pill navigation: Home, Clients, Bookings, Money, Tasks.
- Dashboard with revenue, pulse, schedule, tasks, notification access, and booking requests.
- CRM with client records, contact actions, notes, follow-ups, timeline, booking history, payment history, and tasks.
- Bookings with today/upcoming/past views, calendar view, next booking, date selection, location type, custom services, inline client creation, edit flow, status control, linked tasks, and calendar export.
- Tasks with priority, due date, reminders, client/booking context, templates, checklist items, deliberate completion, reopen, delete, and detail/edit sheets.
- Money tracking with paid/unpaid payments, expenses, target progress, comparisons, add/edit payments, mark received, delete payments, add/delete expenses.
- Public profile at `/p/:handle`, services, working hours, gallery/reviews toggles/content, notice, and booking request form.
- Booking request triage and manual confirmation.
- Notification centre, read/unread filtering, settings toggles, notification rows created by app events.
- Calendar sync placeholder/account state and ICS export.
- Privacy export and account deletion request foundation.
- Demo data seeding through `SEED_DEMO_DATA`.

## Future Vision

Future Slate should deepen the V1 operating loop before expanding sideways.

Likely future directions:

- Production-grade reminders and push notifications through Edge Functions/APNs/FCM.
- Stronger booking-to-payment workflows.
- Improved expense editing, categorisation, and finance targets.
- Calendar integration beyond ICS export.
- Public profile improvements: QR code, closure dates, richer profile controls.
- Data export/delete completion through trusted server-side jobs.
- Stripe/pay-now and deposits only when the simple payment workflow is stable.
- Lightweight analytics where they directly support daily decisions.
- AI assistant later, only after enough real user data exists to make it useful.
- Team/staff support later, not V1.

## What Slate Is Not

Slate is not:

- Generic project management software.
- A generic business operating system for every company type.
- AI-first.
- A WhatsApp replacement.
- A marketplace or discovery platform.
- Enterprise/team management software in V1.
- Generic productivity software.
- A full accounting package.
- A visual automation builder.
- An everything app.

V1 guardrail:

If a feature does not materially improve bookings, clients, payments, daily control, or trust, it probably does not belong in V1.

## Source Notes

Primary product truth comes from Notion pages:

- What Slate Is
- What Slate Is Not
- V1 Scope Lock
- Product Vision
- Features Index
- Business Profile Page
- Notifications & Comms

Implementation reality comes from the current Flutter codebase, live Supabase schema, and Git history as of commit `44c596f`.
