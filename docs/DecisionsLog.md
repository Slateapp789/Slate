# Slate Decisions Log

Last updated: 2026-05-31

This log consolidates Notion decisions, Git history, and codebase reality.

## May 2026 - Slate Is Focused On Solo Appointment Businesses

Decision:

Slate serves solo appointment-based service businesses first.

Reasoning:

Notion product vision identifies this ICP as the clearest wedge: users have repeated bookings, clients, payments, notes, and daily admin pain.

Consequences:

- V1 prioritises clients, bookings, money, tasks, dashboard, profile, notifications.
- Projects, team/staff, marketplace, generic productivity, advanced analytics, and AI-first workflows are parked.

## May 2026 - Core Loop Is Client -> Booking -> Work -> Payment -> Repeat

Decision:

Every major feature must support the operating loop.

Reasoning:

This keeps Slate from becoming an everything app.

Consequences:

- Dashboard is an HQ.
- Clients, bookings, tasks, and payments are connected.
- Feature proposals are filtered against daily business utility.

## May 2026 - Do Not Rebuild Slate

Decision:

Continue refactoring and building in place.

Reasoning:

Notion technical audit found Slate is already a functioning early MVP with real architecture, onboarding, business logic, and backend integration.

Consequences:

- Architecture is improved incrementally.
- Existing table names are preserved.
- Major rewrites are avoided unless they remove real risk.

## May 2026 - Supabase + Riverpod + Flutter Remain The Stack

Decision:

Keep Flutter, Riverpod, and Supabase.

Reasoning:

This stack supports mobile-first UX, quick iteration, auth, Postgres, RLS, and future Edge Functions.

Consequences:

- Supabase repositories are the backend boundary.
- Riverpod providers are the app state boundary.
- Flutter remains the only app UI implementation.

## May 2026 - Move Secrets To Dart Defines

Decision:

Supabase URL/key are loaded from `.env` through `--dart-define-from-file=.env`.

Reasoning:

Avoid hardcoded environment values and prepare for separate environments.

Consequences:

- `.env` is not committed.
- `.env.example` documents required values.
- Client publishable key is accepted in app bundle; service-role key is forbidden.

## May 2026 - RLS Is Mandatory

Decision:

All workspace-owned tables should have RLS.

Reasoning:

Application bugs must not expose cross-workspace data.

Consequences:

- `supabase/rls_policies.sql` was added.
- Live tables now have RLS enabled.
- Remaining work is policy cleanup/performance, not basic RLS enablement.

## May 2026 - User-Facing Language Changed From Appointments/Invoices To Bookings/Money

Decision:

Use Bookings and Money in product language while preserving `appointments` and `invoices` backend names.

Reasoning:

Bookings/Money are more natural for solo service users. Renaming live DB tables would add risk without enough benefit.

Consequences:

- UI says Bookings and Money.
- Internal code still contains appointment/invoice names.
- Docs must explicitly explain this translation.

## May 2026 - Tasks Need Deliberate Completion

Decision:

Avoid one-tap accidental task completion.

Reasoning:

Tasks can be business-critical. Completion should be intentional.

Consequences:

- Task rows open detail/actions.
- Completion can happen through sheet/action/swipe.
- Checklists and reminders were added.

## May 2026 - Bottom Nav Must Include Tasks

Decision:

Tasks became a first-class bottom-nav tab.

Reasoning:

Users should not have to scroll Dashboard to reach daily tasks.

Consequences:

- Main tabs are Home, Clients, Bookings, Money, Tasks.
- FAB remains for creation actions.

## May 2026 - UI Moved Through Several Theme Experiments

Decision:

Final current direction is neutral northbound greys with glass navigation.

Reasoning:

Pure dark was too harsh; pastel was too light; green-tinted grey felt wrong. Current palette uses soft grey hierarchy and premium neutral surfaces.

Consequences:

- `AppColors` are light neutral greys.
- Some legacy token names remain.
- UI design system needs this documented so future work does not drift.

## May 2026 - Public Profile V1 Is Request Booking, Not Full Slot Selection

Decision:

Public profile ships with static profile/service information and manual booking request.

Reasoning:

Full public slot-selection requires availability engine, conflict detection, confirmations, and more failure states.

Consequences:

- `/p/:handle` exists.
- Booking requests are stored and triaged in-app.
- Owner confirms manually.

## May 2026 - Calendar Sync Starts As A Contained Integration

Decision:

Calendar sync is represented by a contained screen/state and ICS export, not scattered booking logic.

Reasoning:

Avoid premature deep integration while still providing export utility.

Consequences:

- `CalendarSyncScreen`, `CalendarSyncRepository`, `calendar_sync_accounts`, and `buildSlateIcs`.
- True external provider sync remains future work.

## 2026-05-30 - Foundation Hardening

Decision:

Repository layer, schema contract, RLS docs, env setup, tests, and Git baseline were introduced before heavy feature expansion.

Reasoning:

The user explicitly paused feature expansion to strengthen the foundation.

Consequences:

- GitHub remote is connected.
- Commits and pushes happen regularly.
- `docs/foundation.md`, `docs/security.md`, `supabase/schema_contract.sql`, and `supabase/rls_policies.sql` exist.

## 2026-05-30 - Major UX Passes

Decision:

Dashboard, core layouts, tasks, bookings, and CRM were elevated with stronger UX.

Reasoning:

The app was functional but felt too generic/blocky.

Consequences:

- Dashboard was reorganized around revenue, pulse, schedule, tasks.
- Tasks gained templates, reminders, checklists, detail sheets.
- Bookings gained calendar, next booking, location, custom services, inline client creation, edit flow.
- CRM was expanded, then simplified after user feedback.

## 2026-05-31 - Money Tracking Expansion

Decision:

Money should track paid, unpaid, expenses, weekly target, and comparisons.

Reasoning:

The user compared against an older prototype and identified current Money as insufficient.

Consequences:

- `expenses` table/model/repository/provider added.
- Money screen tracks paid, unpaid, expenses, profit, target progress, comparisons.
- Weekly target derives from monthly onboarding/settings target.

## 2026-05-31 - Project Memory Created

Decision:

Create durable `/docs` memory for product, architecture, database, UI, current state, roadmap, Notion sync, and constitution.

Reasoning:

Prevent loss of project knowledge between threads.

Consequences:

- Future feature work should start from these docs.
- Notion remains product truth unless code has clearly superseded it.
