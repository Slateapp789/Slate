# Slate Foundation Notes

## Current Architecture

- UI screens should not call Supabase tables directly.
- Supabase table reads and writes live in `lib/shared/repositories/`.
- `lib/shared/repositories/slate_repositories.dart` is a barrel export so older imports keep working while repositories stay split by domain.
- Shared row parsing lives in `lib/shared/models/slate_models.dart`.
- Feature providers should return typed models where practical, and only use raw maps when a legacy screen still requires joined Supabase payloads.

## Security Baseline

- Runtime Supabase config comes from Dart defines via `.env`.
- `.env` is ignored by git; `.env.example` documents required keys.
- The Supabase anon/publishable key is acceptable in a client app, but production safety depends on RLS.
- Do not add service-role keys or privileged backend secrets to Flutter, `.env`, or checked-in files.

## Before New Features

- Run `flutter analyze`.
- Run `flutter test --dart-define-from-file=.env`.
- Keep new table access inside a repository.
- Add or update model tests when a row shape changes.
- Prefer extracting widgets once a screen section becomes independently understandable.

## Remaining Foundation Work

- Continue converting legacy map payloads to typed models.
- Split large screen files, starting with tasks, appointments, client detail, and settings business.
- Add repository tests with mocked Supabase clients or a small database adapter.
- Verify and document Supabase RLS policies for every workspace-scoped table.
- Add CI for analyze and tests once the repository has a clean baseline commit.
