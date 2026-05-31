# Slate Database Rules

Last updated: 2026-05-31

## Source of Truth

Database truth is split across:

- Live Supabase project `imtbyrvsonzvtddswbtb`.
- `supabase/schema_contract.sql`.
- `supabase/rls_policies.sql`.
- Flutter repositories and models.
- Notion Database Schema, which is older than the current implementation in several places.

For future work:

1. Update `supabase/schema_contract.sql`.
2. Apply a named Supabase migration.
3. Update repositories/models/tests.
4. Verify RLS.
5. Update docs if the product meaning changes.

## Live Tables

Live public tables as of 2026-05-31:

- `workspaces`
- `workspace_settings`
- `workspace_members`
- `contacts`
- `services`
- `appointments`
- `tasks`
- `task_checklist_items`
- `invoices`
- `invoice_line_items`
- `expenses`
- `business_profiles`
- `booking_requests`
- `notifications`
- `notification_preferences`
- `push_tokens`
- `calendar_sync_accounts`
- `account_deletion_requests`

All listed live tables currently have RLS enabled.

## Table Purposes

`workspaces`

- One business account/workspace.
- Solo by default for V1.

`workspace_members`

- Connects Supabase auth users to workspaces.
- Current app assumes one owner/member, but the table supports future membership.

`workspace_settings`

- Business settings: timezone, address, working hours, revenue target, reminders, booking notice/window, calendar sync flag, invoice defaults.

`contacts`

- CRM records.
- Stores name, phone, email, address, status, notes, important notes, tags, source, birthday, preferred contact method, last activity.

`services`

- Workspace service menu.
- Used by bookings and public profile.
- Includes duration, price, description, active, show-on-profile.

`appointments`

- Internal table for user-facing Bookings.
- Stores client/service links, title, start/end, status, price, notes, location, recurrence metadata.

`tasks`

- Business tasks.
- May link to contact and/or appointment.
- Includes priority, due date, reminder timing, status, completed timestamp.

`task_checklist_items`

- Checklist/subtask rows for tasks.

`invoices`

- Backend table for user-facing Payments/Money.
- Stores invoice/payment rows, status, due date, amount, paid amount, linked client and appointment.

`invoice_line_items`

- Existing line item table. Current app mostly uses simplified payment rows.

`expenses`

- Money-tracking expenses.
- Stores amount, category, date, notes.

`business_profiles`

- Public profile configuration.
- Stores handle, bio, cover/gallery/review fields, notice fields, booking mode, profile toggles.

`booking_requests`

- Public profile request-booking submissions.
- Owner triages and can manually confirm into a booking.

`notifications`

- In-app bell centre records.

`notification_preferences`

- Workspace-level notification toggles.

`push_tokens`

- Future push delivery device tokens.

`calendar_sync_accounts`

- Calendar integration placeholder/account state.

`account_deletion_requests`

- Account deletion request tracking.
- Actual deletion must be completed by trusted backend/server-side code.

## Relationships

Core relationships:

- Workspace has many contacts, services, appointments, tasks, invoices, expenses, notifications, booking requests.
- Contact has many appointments, invoices, tasks.
- Appointment belongs to workspace, optionally contact and service.
- Appointment can have linked tasks and linked invoices.
- Task belongs to workspace, optionally contact and appointment.
- Invoice belongs to workspace, optionally contact and appointment.
- Business profile belongs to workspace.
- Booking request belongs to workspace and optionally service.

## Auth Flow

Supabase Auth handles email/password sign-up, sign-in, password update, session persistence, and sign-out.

Flutter app flow:

- Supabase initialized from `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Auth session is read through Supabase auth stream.
- Workspace membership determines whether the user enters the app or onboarding.
- Workspace data access is filtered through `workspace_id`.

## RLS Principles

Principle:

Every workspace-owned table must enforce access through `workspace_members`.

Helper function:

`public.is_workspace_member(target_workspace_id uuid)`

Expected rule:

- Authenticated users can access rows only where they are members of the row's workspace.
- Public profile reads are allowed only for public business profile/service data.
- Public booking request inserts are allowed only for valid public profiles in manual booking mode.
- Privileged operations such as final account deletion should happen through trusted backend code, not Flutter.

## Live RLS State

Live RLS is enabled on all current public tables.

Known issue:

The live project still contains some older duplicate policies such as `appointments_policy`, `contacts_policy`, `services_policy`, `tasks_policy`, `invoices_policy`, and `workspace_settings_policy` alongside newer named policies. Supabase performance advisor flags these as multiple permissive policies and auth initplan concerns.

This is not currently blocking local MVP use, but should be cleaned before production.

## Security Advisor State

Supabase security advisor currently reports:

- Leaked password protection disabled.

This requires Supabase Auth settings and may depend on plan/production stage. It should be enabled before launch.

Performance advisor highlights:

- Unindexed foreign keys on some newer tables.
- RLS initplan inefficiencies.
- Multiple permissive policies from legacy policy overlap.
- Some unused indexes due to low current usage.

## Naming Conventions

Database table names remain backend-stable:

- `appointments` is user-facing Bookings.
- `invoices` is user-facing Payments/Money.
- `contacts` is user-facing Clients.

Do not rename these live tables casually. Prefer product-language aliases in UI while preserving backend compatibility.

## Migration Rules

- Never make manual schema changes without updating `supabase/schema_contract.sql`.
- Apply DDL through Supabase migrations.
- Name migrations in snake_case.
- Do not hardcode generated UUIDs in migrations.
- Add indexes for new foreign keys.
- Add RLS policies in the same migration or immediately after.
- Verify with Supabase table list and advisors.
- Update Dart models/repositories/tests in the same feature slice.

## Client Secret Rules

- `SUPABASE_ANON_KEY` / publishable key may exist in the client bundle.
- `service_role` keys must never enter Flutter, `.env`, docs, commits, screenshots, or logs.
- `.env` must remain ignored.
- `.env.example` should document required variables only.
