# Workloop V1 Manual QA

Use this checklist only against an isolated local or staging environment before
treating a V1 build as ready for test users. Never use production accounts or
production data for destructive, cross-account, booking-abuse, or load checks.

## Core Loop

- Sign up with email and complete onboarding in under 3 minutes.
- Create a workspace with services, working hours, revenue target, handle, and first booking.
- Add a client, open the client detail screen, edit the client, and confirm the list updates.
- Add a booking, open booking detail, edit time/service/price, mark complete, and cancel another booking.
- Record received and outstanding income; verify the dashboard and Money workspace reflect both.
- Add a client-linked task; verify it appears on the task list and the client detail task tab.

## Full V1 Surfaces

- Open `/p/{handle}` and verify the public profile renders business name, services, hours, and booking request form.
- In disposable staging, submit a public booking request and confirm it appears
  in the owner's Requests view without querying or editing production directly.
- Open Notifications and confirm empty, unread, read, error, and retry states.
- Toggle every notification preference in Home -> Settings -> Notifications
  and verify persistence after relaunch.
- Open Calendar from Home -> Settings -> App preferences and confirm the
  one-time import/export screen is reachable without implying live sync.

## Dashboard/HQ

- Pull to refresh dashboard after each core action.
- Confirm today's work, upcoming bookings, important tasks, received income,
  outstanding money, and empty states remain readable.
- Confirm copy stays calm, practical, and short.

## Security/Backend

- Confirm all workspace-owned tables have RLS policies scoped through `workspace_members`.
- Confirm public profile reads expose only public business profile and public service data.
- In disposable staging, use two test accounts to confirm neither can select,
  insert, update, delete, or export the other's workspace data.

## Regression

- `flutter analyze` returns no issues.
- `flutter test` passes.
- Test signed builds on supported iOS and Android devices for: Auth, onboarding,
  Home, Clients, Bookings, Money, Tasks, Notes, Tools, Notifications, Settings,
  and the public profile.
