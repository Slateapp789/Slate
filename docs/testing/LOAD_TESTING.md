# Workloop Load and Concurrency Testing

Last updated: 2026-07-26

## Current evidence status

The guarded k6 implementation exists at
[`quality/load/workloop_staging.js`](../../quality/load/workloop_staging.js).
It was **not executed** during the local audit because:

- no dedicated staging Supabase project was available;
- k6 was not installed on the audit machine;
- the configured remote project is production-class;
- running high concurrency against production would create cost, availability,
  and data-integrity risk.

Therefore the current measured result is:

| Measure | Result |
| --- | --- |
| Accounts represented by generator plan | 50,000 profile available |
| Accounts generated locally | 258 synthetic records in final evidence: 8 small-profile records plus one 250-record scale batch |
| Accounts seeded to a backend | 0 during this audit |
| Maximum concurrent virtual users executed | 0 |
| Requests per second | Not measured |
| p50 / p95 / p99 latency | Not measured |
| Error or timeout rate | Not measured |
| Failed or duplicate writes | Not measured |
| Database pressure / rate limits | Not measured |
| Post-spike recovery | Not measured |

A dry-run or generated JSONL file is not a seeded backend. A 50,000-account
population is not 50,000 concurrent users.

## Safety controls

The load script refuses to start unless:

- `LOAD_TEST_ENV=staging`;
- `ALLOW_STAGING_LOAD=true`;
- the target is HTTPS or loopback;
- an anonymous staging key is present;
- the target does not contain the known production project reference or
  Workloop production domains;
- non-smoke profiles also set `CONFIRM_STAGING_COST=true`.

Authenticated reads require a short-lived staging token and a fixture workspace.
Booking and finance writes are independently disabled by default.

Never:

- use a production URL, token, workspace, service, or public handle;
- commit access tokens, keys, or real environment values;
- run moderate or higher profiles without reviewing Supabase plan limits and
  cost exposure;
- enable writes unless the staging workspace is disposable and a cleanup plan
  has been rehearsed;
- interpret a single shared token/workspace as realistic multi-tenant Auth
  pressure.

The environment template is
[`quality/load/.env.example`](../../quality/load/.env.example). It contains
placeholder values only.

## Profiles

The implemented stages are:

| Profile | Ramp up | Sustain | Ramp down | Peak virtual users | Intended use |
| --- | --- | --- | --- | ---: | --- |
| `smoke` | 20 seconds | 40 seconds | 20 seconds | 10 | Validate configuration, expected statuses, and metric collection. |
| `baseline` | 2 minutes | 5 minutes | 2 minutes | 100 | Establish normal read latency and error rate. |
| `moderate` | 5 minutes | 10 minutes | 5 minutes | 500 | Expected-growth test against an approved staging plan. |
| `high` | 10 minutes | 15 minutes | 10 minutes | 1,000 | Capacity test requiring active monitoring and cost approval. |
| `stress` | 15 minutes | 15 minutes | 15 minutes | 5,000 | Deliberate stress test only on an environment sized and approved for it. |

Higher concurrency is not implemented and must not be inferred.

## Implemented traffic mix

Each virtual user rotates through five operations:

1. **Normal daily activity**: list clients and appointments.
2. **Morning read spike**: load today's appointment-shaped data, tasks, and
   notifications.
3. **Booking spike**: read a public profile by default; optionally submit
   bounded public booking requests and repeat a deterministic request token to
   exercise idempotency/rate-limit behaviour.
4. **Finance activity**: list payments and expenses; optionally write a
   synthetic expense.
5. **Notification activity**: repeat notification-history reads.

Important limits of the current implementation:

- it does not perform a distinct sign-in request per virtual user;
- authenticated reads use one supplied test token and workspace;
- it does not create a Realtime WebSocket subscription, reconnect it, or
  measure broadcast latency;
- it does not reschedule or complete authenticated bookings;
- it does not edit or delete finance records;
- write-mode cleanup is not automatic;
- it does not capture database CPU, memory, connections, locks, or query plans
  by itself.

Those limitations must be addressed before describing the suite as a complete
50,000-user or Realtime capacity simulation.

## Initial thresholds

The k6 script enforces:

- critical workflow error rate below 1%;
- HTTP request failure rate below 1%;
- p95 tagged read latency below 1 second;
- p95 tagged write latency below 2 seconds.

The release review must additionally confirm:

- no cross-user exposure;
- no duplicate committed record after an idempotent retry;
- no missing or partially committed workflow records;
- no invalid foreign keys or corrupted money totals;
- recovery to baseline latency and error rate after the spike;
- no unexplained rate-limit, connection-pool, or database saturation.

Thresholds may change only with a documented product expectation and measured
baseline. They must not be loosened solely to make a run pass.

## Fixture population

[`tool/quality/generate_test_data.dart`](../../tool/quality/generate_test_data.dart)
supports:

| Profile | Represented accounts |
| --- | ---: |
| `small` | 8 |
| `medium` | 250 |
| `large` | 5,000 |
| `scale-50000` | 50,000 |

The generator is deterministic, batched, resumable, and restricted to
`build/quality_data`. It emits accounts with varied business maturity, clients,
services, bookings, payments, expenses, tasks, notes, notifications, feed
items, international text, long values, and date-boundary data. It deliberately
does not write to Supabase.

Examples:

```bash
dart run tool/quality/generate_test_data.dart \
  --profile=small \
  --dry-run

WORKLOOP_TEST_ENV=isolated \
dart run tool/quality/generate_test_data.dart \
  --profile=scale-50000 \
  --max-batches=1
```

Before load execution, use a separate, reviewed importer to create disposable
staging Auth users and rows in safe batches. That importer must:

- target only the approved staging project;
- checkpoint each batch;
- respect plan and Auth rate limits;
- never log passwords, access tokens, or service-role credentials;
- verify counts and tenant ownership after each batch;
- support complete fixture deletion or project reset;
- record how many accounts were actually accepted.

No backend importer is currently part of this repository, so “50,000 users
seeded” must remain false until independently evidenced.

## Runbook

### 1. Approve the environment

Record:

- staging project reference and owner in a private run record;
- confirmation that the reference is not production;
- Supabase plan, quotas, connection limits, and billing alerts;
- expected maximum requests and write volume;
- test window, operator, abort authority, and incident channel;
- disposable workspace/user fixtures and cleanup method.

### 2. Establish correctness first

Before load:

```bash
scripts/qa_local_supabase.sh
scripts/qa_all.sh
```

Then perform a single-user authenticated staging journey and verify the same
rows from the owner UI. Load must not be used to discover basic schema or
permission failures.

### 3. Configure non-secret local environment

Copy the variable names from
[`quality/load/.env.example`](../../quality/load/.env.example) into an ignored
local environment file. Supply only staging values and short-lived tokens.
Do not source or print production `.env` content.

### 4. Run in stages

```bash
LOAD_PROFILE=smoke scripts/qa_load_staging.sh
LOAD_PROFILE=baseline CONFIRM_STAGING_COST=true \
  scripts/qa_load_staging.sh
```

Proceed to `moderate`, `high`, or `stress` only after the prior level passes,
the environment recovers, costs remain acceptable, and the service owner
explicitly approves the next level.

### 5. Enable writes separately

Read-only results do not prove workflow safety. For a disposable fixture only:

```bash
BOOKING_WRITE_ENABLED=true \
PUBLIC_HANDLE=<staging-handle> \
SERVICE_ID=<staging-service-id> \
LOAD_PROFILE=smoke \
scripts/qa_load_staging.sh
```

Finance writes use a separate `FINANCE_WRITE_ENABLED=true` opt-in. Never enable
both write modes initially. Add server-side fixture markers and a verified
cleanup query before any write run.

### 6. Abort conditions

Stop the test if any of these occurs:

- cross-workspace data is observed;
- duplicate or partial workflow records appear;
- error rate reaches 5% for more than one minute;
- p95 exceeds 5 seconds for more than one minute;
- connection saturation or database health degrades;
- rate limiting affects non-test users;
- projected cost exceeds the approved cap;
- recovery does not begin during ramp-down.

### 7. Capture evidence

For each run preserve:

- source commit SHA and k6 version;
- profile, exact stages, start/end time, and region;
- accounts actually seeded and active tokens used;
- peak virtual users and requests per second;
- p50, p95, p99, failures, timeouts, and status distribution by scenario;
- database CPU, memory, connections, locks, slow queries, and rate limits;
- fixture row counts before and after;
- duplicate/idempotency and integrity queries;
- recovery metrics five and fifteen minutes after load;
- cleanup/reset outcome.

Store results as CI artifacts or in a private operational record without
secrets. Summarise the measured values in
[TEST_RESULTS.md](TEST_RESULTS.md).

## CI

The scheduled workflow contains a conditional `moderate` read-only job. It runs
only when the repository variable `ENABLE_STAGING_LOAD` is `true` and requires
staging secrets:

- `STAGING_SUPABASE_URL`;
- `STAGING_SUPABASE_ANON_KEY`;
- `STAGING_TEST_ACCESS_TOKEN`;
- `STAGING_WORKSPACE_ID`.

The public staging handle is a repository variable, not a secret. Booking and
finance writes remain off in scheduled CI.

A configured workflow is not a load result. The first run should remain manual
and supervised; enable the schedule only after a successful smoke and baseline
run, cost review, monitoring, and cleanup rehearsal.

## Expansion required for launch-scale confidence

1. Create a dedicated staging project and backend fixture importer.
2. Use a pool of independent staging users/workspaces and rotate short-lived
   tokens by virtual user.
3. Add authenticated atomic booking create/reschedule/complete scenarios.
4. Add client, task, note, and finance create/edit/delete flows with cleanup.
5. Add Realtime subscription connect/change/reconnect measurement if remote
   Realtime becomes a launch dependency.
6. Add database telemetry and post-run integrity queries to the pipeline.
7. Measure smoke, baseline, moderate, spike, sustained, and recovery in order.
8. Reassess the 5,000-user stress ceiling only after measured demand and plan
   limits justify it.
