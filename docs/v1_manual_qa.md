# Slate V1 Manual QA

Use this checklist before treating a V1 build as ready for test users.

## Core Loop

- Sign up with email and complete onboarding in under 3 minutes.
- Create a workspace with services, working hours, revenue target, handle, and first booking.
- Add a client, open the client detail screen, edit the client, and confirm the list updates.
- Add an appointment, open appointment detail, edit time/service/price, mark complete, and cancel another appointment.
- Record a paid payment and a pending/outstanding payment; verify dashboard and payments list reflect both.
- Add a client-linked task; verify it appears on the task list and the client detail task tab.

## Full V1 Surfaces

- Open `/p/{handle}` and verify the public profile renders business name, services, hours, and booking request form.
- Submit a public booking request and confirm a `booking_requests` row is created.
- Open notification centre and confirm empty, unread, and read states render.
- Toggle every notification preference in Settings -> Alerts and verify persistence.
- Open Calendar Sync from Settings -> App and confirm the contained integration screen is reachable.

## Dashboard/HQ

- Pull to refresh dashboard after each core action.
- Confirm today, upcoming appointments, important tasks, revenue, outstanding money, and empty states remain readable.
- Confirm copy stays calm, practical, and short.

## Security/Backend

- Confirm all workspace-owned tables have RLS policies scoped through `workspace_members`.
- Confirm public profile reads expose only public business profile and public service data.
- Confirm a user cannot read another workspace by manually changing IDs.

## Regression

- `flutter analyze` returns no issues.
- `flutter test` passes.
- Test on mobile-width web or simulator for: auth, onboarding, dashboard, clients, appointments, payments, tasks, settings, public profile.
