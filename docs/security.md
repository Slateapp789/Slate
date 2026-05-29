# Slate Security Notes

## Local Configuration

Slate reads Supabase client configuration from Dart defines:

```bash
flutter run --dart-define-from-file=.env
```

The local `.env` file is ignored by git. Keep `.env.example` committed so new environments know which keys are required.

Required values:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-or-publishable-key
```

The Supabase anon/publishable key is not a server secret. It is expected to be present in client apps, but database safety depends on correct Supabase Row Level Security policies. Never put a `service_role` key or any other privileged backend secret in Flutter code, `.env`, or mobile app bundles.

## Immediate Security Priorities

- Verify Row Level Security for `workspaces`, `workspace_members`, `contacts`, `appointments`, `services`, `tasks`, `invoices`, `business_profiles`, `booking_requests`, `notifications`, `notification_preferences`, and `push_tokens`.
- Keep all workspace-scoped queries filtered by the active workspace.
- Move direct Supabase writes out of screens into repositories so access rules and error handling are centralized.
- Add account deletion/export flows before production launch.
- Add biometric lock and 2FA preference support after the main V1 loop is stable.
