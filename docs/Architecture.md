# Workloop Architecture

Last updated: 2026-07-26

## Stack

Workloop is a Flutter application using:

- Flutter / Dart
- Riverpod / flutter_riverpod for state management
- Supabase for Auth, Postgres, RLS, RPC workflows, and Edge Functions
- GoRouter for top-level routes
- Material navigation for many nested flows
- Bundled Instrument Sans variable font
- `lucide_flutter` icons
- url_launcher for phone/email/external actions
- shared_preferences for non-critical, device-specific choices such as the default maps app
- `flutter_local_notifications` for opted-in on-device reminders
- `device_calendar` and `file_picker` for reviewed imports and portable exports

The 1.0 product is phone-first: iPhone portrait on iOS 13+ and portrait Android
on API 24+, targeting API 36.

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
    business_feed/
    calendar_sync/
    clients/
    dashboard/
    finance/
    imports/
    more/
    notes/
    notifications/
    onboarding/
    profile/
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
- Contains `AuthGate`, `WorkspaceGate`, `MainShell`, and the shared Workloop
  bottom navigation.

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
- `/reset-password`
- `/onboarding`
- `/home`
- `/business-feed`
- `/clients`
- `/clients/new`
- `/tasks`
- `/work`
- `/bookings/new`
- `/payments`
- `/notifications`
- `/notes`
- `/booking-requests`
- `/calendar-sync`
- `/import-data`
- `/p/:handle`
- `/:handle` for public profile links

Main app tabs are controlled by `MainShell` local state:

- Home
- Clients
- Bookings
- Tools

Money, Tasks, and Notes are routed from Tools. Profile and Settings are opened
from the Home header or direct feature links. Many detail and creation flows
still use `Navigator.push`; this should migrate gradually when deeper
restoration or linking requires it.

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
- `businessFeedProvider`
- `dashboardAttentionProvider`
- `workloopAppearanceProvider`

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

- `WorkloopPage`
- `WorkloopSurface`
- `WorkloopPageHeader`
- `WorkloopPrimaryButton`
- `WorkloopBottomNav`
- `WorkloopSegmentedControl`
- `WorkloopPickerField`
- `SlateErrorState` and retained compatibility primitives

Theme tokens live in:

`lib/core/theme/app_theme.dart`

The exact icon/launch neon `#C1FF72` is the shared product accent. Dark
foregrounds are used on neon fills; a deeper accent-ink role is used for small
light-surface content.

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
