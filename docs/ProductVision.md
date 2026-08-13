# Workloop Product Vision

Last updated: 2026-07-26

## What Workloop Is

Workloop is the headquarters for solo appointment-based business owners.

It is a premium, calm, mobile-first business operating system that helps solo service businesses run their daily operations from one connected app. The core product loop is:

`Client -> Booking -> Work -> Payment -> Repeat`

Workloop currently supports the main operating surfaces needed for that loop:

- Dashboard / HQ
- Clients / CRM
- Bookings and calendar
- Tasks and reminders
- Money tracking
- Public business profile and booking requests
- Notifications centre and preferences
- Settings, business profile, services, working hours, privacy export/request deletion

## Who Workloop Serves

Workloop is designed for solo appointment-based service businesses:

- Barbers and hairdressers
- Beauty and aesthetics professionals
- Personal trainers and fitness coaches
- Therapists and wellness practitioners
- Cleaners and home service providers
- Coaches, tutors, and mobile service operators
- Tattoo artists and other appointment-led operators

The target customer runs the business from their phone, has limited time for admin, and currently stitches together multiple tools such as calendars, notes, WhatsApp, spreadsheets, booking links, and payment trackers.

## Core Product Philosophy

Workloop should reduce mental load. It should feel like a calm command centre, not another admin burden.

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

Workloop should become the first app a solo business owner opens each day.

Success looks like:

- Users manage most daily admin inside Workloop.
- Users cancel or reduce reliance on fragmented tools.
- Users trust Workloop for schedule, clients, money, tasks, and follow-ups.
- V1 proves retention through daily operational value before expanding into heavier modules.

## Current Scope

Current V1 scope is focused on solo appointment-based businesses. The app already implements a real MVP, not a blank prototype.

Current code scope includes:

- Email/password authentication through Supabase.
- Workspace onboarding with services, working hours, profile handle, revenue target, and first booking.
- Main shell with five clear operating destinations: Today, Clients, Work,
  Money, and Business. Work contains Schedule, Tasks, and Notes; Business owns
  the customer-facing booking page, services, working hours, and business
  profile. Settings remains a secondary utility rather than a product module.
- Dashboard with revenue, pulse, schedule, tasks, notification access, and booking requests.
- CRM with client records, contact actions, notes, follow-ups, timeline, booking history, payment history, and tasks.
- Bookings with today/upcoming/past views, calendar view, next booking, date selection, location type, custom services, inline client creation, edit flow, status control, linked tasks, and calendar export.
- Tasks with priority, due date, reminders, client/booking context, templates, checklist items, deliberate completion, reopen, delete, and detail/edit sheets.
- Money tracking with paid/unpaid payments, booking-linked payments, expenses, target progress, comparisons, add/edit payments, mark received, delete payments, add/edit/delete expenses, category summaries, and week/month/custom period views.
- Public profile at `/p/:handle`, services, working hours, gallery/reviews toggles/content, notice, and booking request form.
- Booking request triage and manual confirmation.
- Notification centre, read/unread filtering, settings toggles, notification
  rows created by app events, and on-device task/booking reminders.
- Point-in-time ICS calendar export and explicit calendar-event import. Workloop
  does not claim live two-way calendar sync.
- Privacy export and trusted Edge Function account deletion workflow.
- Explicit debug-only demo data seeding through `SEED_DEMO_DATA`; release
  builds cannot seed demo records.

## Future Vision

Future Workloop should deepen the V1 operating loop before expanding sideways.

Likely future directions:

- Optional cross-device push delivery through Edge Functions/APNs/FCM, while
  preserving the launch-ready local reminder path.
- QA and polish booking-to-payment workflows.
- Deeper money reporting once the daily tracking loop is stable.
- Calendar integration beyond explicit import/export only when it can be
  reliable, reversible, and clearly communicated.
- Public profile improvements: QR code, closure dates, richer profile controls.
- Data export/delete operational hardening around the trusted server-side deletion path.
- Stripe/pay-now and deposits only when the simple payment workflow is stable.
- Lightweight analytics where they directly support daily decisions.
- Team/staff support later, not V1.

## What Workloop Is Not

Workloop is not:

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

- What Workloop Is
- What Workloop Is Not
- V1 Scope Lock
- Product Vision
- Features Index
- Business Profile Page
- Notifications & Comms

Implementation reality comes from the current Flutter codebase, live Supabase
schema/function inventory, and the release evidence recorded in
`docs/CurrentState.md` and `docs/LaunchReadiness.md`.
