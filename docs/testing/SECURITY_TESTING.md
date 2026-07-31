# Workloop Security Testing

Last updated: 2026-07-26

## Security position

No confirmed cross-user exposure was found in the 2026-07-26 static and
read-only metadata review. That statement is intentionally narrower than
“secure”:

- the authored pgTAP suite has not yet run on a clean local database;
- an authenticated User A/User B client-SDK journey has not run;
- Storage isolation has not been tested;
- destructive account deletion and public booking abuse controls have not been
  exercised against a disposable production-like environment;
- production Auth leaked-password protection is disabled.

Any cross-workspace read, insert, update, delete, export, file access, or
workflow execution is a critical release stop.

## Scope and threat model

The launch threat model covers:

- an anonymous caller using the public client key;
- authenticated User A, who is a member of Workspace A;
- authenticated User B, who is a member of Workspace B;
- a user attempting to supply another workspace, contact, service, booking,
  task, invoice, or request identifier;
- replay, duplicate tap, timeout retry, and concurrent workflow calls;
- malformed and oversized public booking/profile/Places input;
- a client attempting to call private or privileged functions directly;
- accidental exposure through Data API grants, views, Storage, exports, logs,
  CI artifacts, or mobile configuration;
- destructive deletion of a sole-owner or multi-member workspace;
- service-role use restricted to trusted backend execution.

The review does not claim a full penetration test, infrastructure audit,
third-party vendor assessment, or legal/privacy compliance review.

## Environment and production safety

The repository's remote `.env` points to a production-class Supabase
environment. During this audit:

- environment variable names were inventoried without printing secret values;
- production schema and policy state were queried read-only;
- no production rows, Auth users, Storage objects, schema, policies, functions,
  or secrets were modified;
- no service-role key was added to source, docs, fixtures, or CI;
- destructive, multi-user, database-reset, and load tests were not redirected
  to production.

Local isolated configuration lives in
[`supabase/config.toml`](../../supabase/config.toml). It uses loopback services
and a local-only project identifier.

## Read-only production observations

Observed on 2026-07-26; production state can drift and must be rechecked for the
release commit:

| Control | Read-only observation | Evidence limit |
| --- | --- | --- |
| Public application tables | RLS was enabled on the inspected public tables. | Metadata inspection does not prove every policy expression or operation. |
| Anonymous table access | No direct anonymous application-table grants were observed. | Public Edge Function behaviour still needs dynamic abuse testing. |
| Authenticated access | Application grants and policies were workspace-scoped in the inspected metadata/source. | User A/User B SDK tests are still required. |
| Private workflow tables | `app_private.payment_counters` and `app_private.workflow_idempotency` had RLS disabled, no `anon`/`authenticated` table grants, and were outside the exposed Data API schema. | This relies on schema/grant boundaries; enabling RLS with explicit deny/service policies remains a defence-in-depth decision. |
| Edge deployments | Public profile, booking request, Places search, deletion request, and deletion completion functions were active with JWT verification enabled. | Deployment presence is not behavioural proof. Exact versions are tracked in [`LaunchReadiness.md`](../LaunchReadiness.md). |
| Auth password protection | Leaked-password protection was disabled. | Must be enabled and regression-tested before public launch. |

The generic Supabase advisor warning for the two non-RLS private tables must not
be silently dismissed. Their current protection is that clients have no table
grants and the `app_private` schema is not exposed by the Data API. The release
owner should either:

1. retain this architecture with an explicit reviewed rationale and automated
   grant/schema assertions; or
2. enable RLS and add policies compatible with the trusted workflow functions.

Do not apply a production migration solely from an automated advisory without
testing workflow semantics in isolation.

## Database object coverage

| Object group | Intended boundary | Current evidence | Remaining dynamic test |
| --- | --- | --- | --- |
| `workspaces`, `workspace_members`, `workspace_settings` | Authenticated membership and first-workspace bootstrap only | Static policy/source review; pgTAP table/RLS/grant contracts authored | First membership, second workspace, cross-member read/update, last-owner and multi-member cases |
| `contacts`, `services`, `appointments` | Workspace members only | Static tenant policies; pgTAP cross-user contact assertions and relationship checks authored | User A/User B CRUD, foreign ID injection, conflict race, cascade/restrict behaviour |
| `invoices`, `invoice_line_items`, `expenses` | Workspace members only | Static policies, keys, and tenant-aware relationship contracts authored | Cross-tenant writes, decimal integrity, duplicate workflow retry, edit/delete race |
| `tasks`, `task_checklist_items`, `notes` | Workspace members only | Static policies; task workflow function/grant contracts authored | Atomic create, retry/replay, checklist/relationship isolation, cross-user SDK attempts |
| `business_profiles`, public profile views | Private member CRUD; bounded safe public projection | Direct anonymous table grants removed; public read routed through Edge source | Projection leakage, reserved/invalid handle, enumeration, cache/error behaviour |
| `booking_requests` | No anonymous direct table writes; bounded public Edge write; member triage | Static Edge validation, rate-limit, notification, token, and function contracts | Honeypot, oversized input, invalid service, rate windows, concurrent duplicate, owner preference, conversion/decline |
| `notifications`, `notification_preferences`, `push_tokens` | Workspace member access | Static policies and table/grant contracts authored | User A/User B access, preference enforcement, token replacement/revocation |
| `calendar_sync_accounts` | Workspace member access | Static table/RLS contract authored | Cross-tenant access and secret/token handling if the feature becomes operational |
| `account_deletion_requests`, `account_deletion_audit` | Requester-visible request; audit denied to clients; privileged completion | Static policies, Edge source, and request/audit contract inspection | Disposable sole-owner completion, multi-member denial, replays, cascade, orphan and export checks |
| Removed AI-support tables | Not part of the launch schema | `ai_actions`, `support_chats`, and `support_messages` are created only in historical migrations and then explicitly dropped by later migrations | Clean replay must confirm they remain absent; add new security tests only if the capability is intentionally reintroduced |
| `app_private.payment_counters`, `workflow_idempotency`, `edge_rate_limit_events` | Trusted functions/service boundary only | Private-schema revoke/grant source and read-only metadata inspection; pgTAP checks client table grants | Function-level execution, replay, expiry/cleanup, concurrent locks, and explicit private-table RLS decision |
| Storage buckets and objects | Per-workspace private access if introduced | No launch bucket/policy migration or attachment workflow identified | No Storage isolation claim is possible; add bucket/policy tests before any attachment feature ships |

## Authored pgTAP tests

Run:

```bash
scripts/qa_local_supabase.sh
```

The script requires Docker, an active Docker daemon, and Supabase CLI. It:

1. rejects a local config containing known production identifiers;
2. starts the loopback Supabase stack;
3. rebuilds the database from repository migrations;
4. runs `supabase test db`.

### Schema and grant contract

[`001_schema_security.test.sql`](../../supabase/tests/database/001_schema_security.test.sql)
contains 31 assertions covering:

- existence of 20 launch data tables;
- RLS enabled for those named tables;
- no anonymous direct table privileges;
- no client-role private-table privileges;
- primary keys on named row-identity tables;
- public authenticated and private workflow function presence;
- no client CRUD grants on private workflow state;
- tenant-aware relationship foreign keys.

### User isolation contract

[`002_rls_isolation.test.sql`](../../supabase/tests/database/002_rls_isolation.test.sql)
contains 12 assertions using two synthetic Auth users and two workspaces in a
rolled-back transaction. It covers:

- User A seeing only Workspace A contacts;
- cross-account update and delete affecting no rows;
- cross-account insert rejection;
- same-workspace insert permission;
- blocked mutations leaving User B data unchanged;
- User B isolation;
- anonymous table reads being rejected for lack of privilege;
- anonymous/authenticated booking-workflow function grants;
- explicit service-role RLS bypass boundary.

### Execution status

These pgTAP tests are **implemented, unexecuted locally** because Docker was not
available. The GitHub Actions database job is configured to run them, but a
workflow file is not evidence of a hosted pass.

Before accepting a result, confirm:

- a clean migration replay succeeded from an empty database;
- all planned assertions ran, with no skipped or TODO tests;
- the run used the release commit;
- `support_chats`, `support_messages`, and `ai_actions` remain absent after their
  explicit removal migrations;
- all created users and rows were local/disposable.

## Edge Function controls

Static source and baseline Deno checks cover selected validation and rate-limit
logic. The intended boundary is:

- `get-public-profile`: returns an allow-listed public projection;
- `create-booking-request`: accepts bounded anonymous input, validates
  profile/service ownership, forces safe state, applies honeypot and source/phone
  rate limits, uses a stable request token, and creates owner notification
  server-side;
- `places-address-search`: keeps the Google key server-side and requires an
  authenticated call;
- `request-account-deletion`: creates a guarded deletion request;
- `complete-account-deletion`: requires a backend-only administrative secret
  and validates ownership constraints;
- `workloop-ai-assistant`: remains disabled and must not expose data.

Required staging tests:

- missing, expired, malformed, and wrong-role JWTs;
- malformed JSON, unexpected fields, SQL-like input, Unicode, large bodies, and
  boundary lengths;
- invalid/reserved profile handles and a service from another workspace;
- honeypot and rate limits from repeated source/phone inputs;
- repeated identical token, parallel duplicate calls, timeout and retry;
- notification preference enforcement;
- deletion request replay, invalid admin secret, sole-owner success, and
  multi-member rejection;
- response bodies contain no stack traces, secrets, internal hashes, or private
  profile fields.

Function source tests do not prove deployed configuration, secrets, egress
restrictions, rate limits, or database behaviour.

## Secrets and CI

Allowed in mobile source and public CI:

- public placeholder Supabase URL;
- public placeholder anonymous client key;
- non-sensitive synthetic IDs and `example.invalid` identities.

Forbidden:

- production service-role keys;
- account-deletion administrative token;
- Google Places server key;
- signing keys, keystores, certificates, provisioning profiles;
- real access/refresh tokens;
- SMTP credentials;
- real customer or operator data.

The staging load job expects values from GitHub Secrets and is disabled unless
an explicit repository variable enables it. Secret values must not be echoed or
uploaded in logs/artifacts.

## Authentication gaps

Before public launch:

- enable Supabase leaked-password protection;
- configure and test production SMTP/sender identity;
- test sign-up confirmation and password recovery outside the development team;
- allow and verify the `workloop://reset-password` redirect;
- review sign-up and reset rate limits;
- decide whether CAPTCHA is required for public abuse;
- verify token expiry, refresh rotation, revoked sessions, email change, password
  change, sign-out-all, and offline recovery.

Official guidance:

- [Supabase password security](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase database functions](https://supabase.com/docs/guides/database/functions)
- [Supabase secure data](https://supabase.com/docs/guides/database/secure-data)

## Required security exit criteria

- Clean local migration replay and every pgTAP assertion pass.
- User A/User B SDK tests reject cross-tenant select, insert, update, delete,
  export, function execution, and Storage access.
- Public booking requests pass validation, rate-limit, idempotency, and
  conversion/decline tests under concurrency.
- Atomic booking/task/payment flows prove no partial or duplicate records after
  retry and timeout.
- Disposable account deletion proves correct sole-owner completion,
  multi-member rejection, cascade behaviour, and audit protection.
- Auth leaked-password protection and production email/recovery are enabled and
  tested.
- No secrets appear in source, commit history under review, logs, artifacts, or
  mobile bundles.
- Any private-table RLS exception has a reviewed rationale and automated
  Data-API/grant regression checks.
- Storage remains absent from launch claims or receives explicit bucket-policy
  and two-user isolation coverage.

Until these pass, security evidence supports controlled testing only; it does
not support an unconditional public-release claim.
