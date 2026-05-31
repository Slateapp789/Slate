# Slate Architecture

Last updated: 2026-05-31

## Stack

Slate is a Flutter application using:

- Flutter / Dart
- Riverpod / flutter_riverpod for state management
- Supabase for Auth, Postgres, and future storage/functions
- GoRouter for top-level routes
- Material navigation for many nested flows
- Google Fonts / Inter
- Lucide icons
- url_launcher for phone/email/external actions
- confetti for target celebration

The app is multi-platform by Flutter structure, but current product design is mobile-first.

## Folder Structure

Current structure:

```text
lib/
  core/
    supabase/
    theme/
  features/
    appointments/
    auth/
    calendar_sync/
    clients/
    dashboard/
    finance/
    notifications/
    onboarding/
    public_profile/
    settings/
    tasks/
  shared/
    models/
    providers/
    repositories/
    utils/
    widgets/
```

Supporting folders:

```text
docs/
supabase/
test/
```

## Application Entry

`lib/main.dart`:

- Validates Supabase config from Dart defines.
- Initializes Supabase.
- Wraps the app in `ProviderScope`.
- Builds `MaterialApp.router`.
- Defines GoRouter routes.
- Contains `AuthGate`, `WorkspaceGate`, `MainShell`, FAB sheet, and custom pill bottom nav.

## Auth and Workspace Flow

Current flow:

1. App starts at `/`.
2. `AuthGate` listens to `Supabase.instance.client.auth.onAuthStateChange`.
3. If no session, user sees `AuthScreen`.
4. If authenticated, `WorkspaceGate` loads workspace.
5. If no workspace, user sees onboarding.
6. If workspace exists, user enters `MainShell`.

Workspace lookup uses `workspaceProvider`, which reads through repository/provider layers.

## Navigation

Top-level routes use GoRouter:

- `/`
- `/auth`
- `/onboarding`
- `/home`
- `/tasks`
- `/work`
- `/payments`
- `/notifications`
- `/booking-requests`
- `/calendar-sync`
- `/p/:handle`

Main app tabs are controlled by `MainShell` local state:

- Home
- Clients
- Bookings
- Money
- Tasks

Many detail and creation flows still use `Navigator.push` with `MaterialPageRoute`. This is acceptable for the current MVP but should eventually become a more consistent route strategy if deep linking and state restoration become important.

## State Management

Riverpod is the central state management tool.

Patterns currently used:

- `FutureProvider` for async Supabase-backed reads.
- `Provider` for repositories.
- `NotifierProvider` for onboarding state.
- `FutureProvider.family` for entity-specific detail collections.
- Local `StatefulWidget` state for form fields, tab selection, filters, and sheet state.

Provider examples:

- `workspaceProvider`
- `clientsProvider`
- `clientCrmRecordsProvider`
- `appointmentsProvider`
- `tasksProvider`
- `financeSummaryProvider`
- `notificationsProvider`
- `calendarSyncProvider`

## Repository Pattern

Supabase access is mostly centralized under `lib/shared/repositories/`.

Repositories include:

- `AuthRepository`
- `WorkspaceRepository`
- `WorkspaceSettingsRepository`
- `OnboardingRepository`
- `ClientsRepository`
- `AppointmentsRepository`
- `PaymentsRepository`
- `ExpensesRepository`
- `TasksRepository`
- `DashboardRepository`
- `ProfileRepository`
- `NotificationsRepository`
- `CalendarSyncRepository`
- `PrivacyRepository`
- `DebugDemoDataRepository`

Rule:

New Supabase table access should live in repositories, not screens.

Current reality:

- Most direct `.from(...)` calls are in repositories.
- Some screens still manipulate maps and have substantial form/business logic.
- There are no direct table writes in most screen code, but UI files still coordinate repository calls, validation, state invalidation, and workflow decisions.

## Model Layer

Typed row models live in:

`lib/shared/models/slate_models.dart`

Current models include:

- `Workspace`
- `Client`
- `Service`
- `Appointment`
- `Payment`
- `Expense`
- `SlateTask`
- `TaskChecklistItem`
- `BusinessProfile`
- `BookingRequest`
- `SlateNotification`

The migration from raw `Map<String, dynamic>` to typed models is partially complete. Some providers and screens still use joined map payloads for convenience, especially bookings, client detail, dashboard, settings, and legacy tabs.

## Shared UI System

Shared components live in:

`lib/shared/widgets/slate_ui.dart`

Important components:

- `SlateSurface`
- `SlateGlassSurface`
- `SlateButton`
- `SlateSheetFrame`
- `SlateLoadingBlock`
- supporting action/surface primitives

Theme tokens live in:

`lib/core/theme/app_theme.dart`

## Current Naming Conventions

Product language:

- User-facing language should prefer `Bookings` and `Money`.
- Backend and some internal code still use `appointments` and `invoices`.
- This is intentional for now to avoid risky database renames.

Code naming:

- Feature screens: `*_screen.dart`
- Repositories: `*_repository.dart`
- Providers: `*_provider.dart`
- Shared model classes: PascalCase inside `slate_models.dart`
- Workspace-scoped database tables use `workspace_id`.

## Coding Standards

Current standards established by docs and code:

- Use `.env` via `--dart-define-from-file=.env`.
- Do not commit `.env`.
- Do not put service-role keys in Flutter.
- Keep Supabase table access inside repositories.
- Run `flutter analyze`.
- Run `flutter test --dart-define-from-file=.env`.
- Update `supabase/schema_contract.sql` and `supabase/rls_policies.sql` when DB shape changes.
- Add model tests when row serialization boundaries change.
- Prefer extracting widgets as screen sections become independently understandable.

## Architectural Assessment

Strengths:

- Real multi-tenant workspace model exists.
- RLS is enabled on live workspace-owned tables.
- Repository layer is now broad enough to support safe growth.
- Typed models exist for major domains.
- App modules map well to the product loop.
- Tests now cover model serialization and important utilities.

Risks:

- Several feature files are too large: `tasks_screen.dart`, `add_appointment_screen.dart`, `appointment_detail_screen.dart`, `settings_business_tab.dart`, `finance_screen.dart`, `client_detail_screen.dart`.
- Some providers still expose raw maps.
- Routing is mixed between GoRouter and imperative `Navigator.push`.
- Screen files still contain validation, orchestration, and UI together.
- Supabase live policies include older duplicate policies that should be cleaned.

## Recommended Architecture Direction

Do not rebuild.

Move gradually toward:

```text
Screen -> Feature widgets -> Provider -> Repository -> Supabase
```

Priority refactors:

1. Split oversized screens by domain section.
2. Finish typed model migration for bookings, settings, dashboard, and public profile.
3. Standardize route handling for detail/create/edit flows.
4. Add repository tests or adapter tests.
5. Clean live Supabase legacy policies and indexes.
