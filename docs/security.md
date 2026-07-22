# Workloop Security Notes

## Local Configuration

Workloop reads Supabase client configuration from Dart defines:

```bash
flutter run --dart-define-from-file=.env
```

The local `.env` file is ignored by git. Keep `.env.example` committed so new environments know which keys are required.

Required values:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-or-publishable-key
```

Google Places is called only by the authenticated `places-address-search` Edge
Function. Store `GOOGLE_PLACES_API_KEY` in Supabase Edge Function secrets and
restrict it to Places API (New). Never add that key to Flutter `.env`, source
code, or a mobile application bundle. See `docs/GooglePlacesSetup.md`.

The Supabase anon/publishable key is not a server secret. It is expected to be present in client apps, but database safety depends on correct Supabase Row Level Security policies. Never put a `service_role` key or any other privileged backend secret in Flutter code, `.env`, or mobile app bundles.

The public booking/profile Edge Functions are deployed with JWT verification enabled, so the current mobile `.env` uses the legacy anon JWT rather than the newer publishable key. Both are public client keys; the service role key only lives in Supabase Edge Function secrets.

## Current Public Boundary

- Anonymous users do not read `business_profiles`, `services`, or `booking_requests` directly.
- Public profile reads go through the `get-public-profile` Edge Function, which returns only the safe public projection.
- Public booking requests go through the `create-booking-request` Edge Function, which validates handle/service ownership, forces `pending` status, applies length limits, rate-limits by source hash and phone, and creates the owner notification server-side.
- Workspace data access remains gated by RLS policies scoped to authenticated workspace members.

## Account Deletion Boundary

- The app no longer writes deletion requests directly to the database.
- Deletion requests go through the `request-account-deletion` Edge Function, which verifies the signed-in user and workspace membership before creating or refreshing an open request.
- Destructive completion goes through the `complete-account-deletion` Edge Function. It deletes the workspace rows through cascade, deletes the Supabase Auth user through the admin API, and writes a non-identifying audit row with a hashed email.
- `complete-account-deletion` requires an `ACCOUNT_DELETION_ADMIN_TOKEN` Edge Function secret. Do not put this token in Flutter, `.env`, docs, commits, screenshots, or logs.
- `account_deletion_audit` has RLS enabled with an explicit deny-all client policy. It is service-role/admin-only.

## Immediate Security Priorities

- Enable Supabase Auth leaked password protection before beta.
- Keep all workspace-scoped queries filtered by the active workspace.
- Set `ACCOUNT_DELETION_ADMIN_TOKEN` in Supabase Edge Function secrets before using account deletion completion.
- Add biometric lock and 2FA preference support after the main V1 loop is stable.
