# Workloop Test Strategy

Last updated: 2026-07-26

## Purpose

This strategy defines the evidence required to release Workloop on iOS and
Android without confusing implemented test tooling with executed proof.
Workloop's highest-risk promise is not an isolated feature: it is the connected
business loop from client, to booking, to money, task, note, notification, and
dashboard state.

The strategy therefore prioritises:

1. tenant isolation and destructive-operation safety;
2. atomic and idempotent booking, booking-request, task, and payment workflows;
3. correct dates, time zones, daylight-saving transitions, and money values;
4. complete loading, empty, error, retry, and offline behaviour;
5. usable layouts across supported phone sizes and accessible text scales;
6. reproducible builds and tests on both mobile platforms;
7. measured performance under realistic data and concurrency.

It does not claim that Workloop is bug-free. It defines how evidence is gathered
and which missing evidence prevents a release claim.

## Evidence labels

Every result in this testing pack uses one of these labels.

| Label | Meaning |
| --- | --- |
| **Verified on candidate** | The command ran against the current candidate after the final code change, and its output was recorded. |
| **Verified baseline** | The command passed earlier, before the current audit changes. Useful context, but not a substitute for a final rerun. |
| **Static verified** | Source, migrations, configuration, or read-only metadata were inspected; no dynamic behaviour is inferred. |
| **Implemented, unexecuted** | A test or tool exists, but its required isolated environment, device, service, or credential was unavailable. |
| **Manual required** | Automation cannot establish the full result, such as VoiceOver reading order or notification delivery after reboot. |
| **Blocked** | A prerequisite is absent or unsafe, so the test did not run. |

The current run ledger is
[TEST_RESULTS.md](TEST_RESULTS.md). Feature-level coverage is
[TEST_MATRIX.md](TEST_MATRIX.md).

## Safety boundary

- The configured remote Supabase project is production-class. Its identifiers
  and secret values must never be copied into test fixtures, screenshots, logs,
  or committed CI configuration.
- Production may be inspected only with read-only metadata queries during this
  audit. No production records, Auth users, Storage objects, policies, schema,
  function versions, or secrets may be changed.
- Dynamic database, Auth, tenant-isolation, destructive, and load tests must
  target the loopback stack in
  [`supabase/config.toml`](../../supabase/config.toml) or a dedicated,
  disposable staging project.
- Flutter tests and unsigned builds use non-secret placeholder Dart defines
  unless an explicitly approved isolated environment is required.
- A missing isolated environment is recorded as a gap. It is never worked
  around by pointing destructive or high-volume tooling at production.
- Load profiles above smoke require an explicit staging and cost
  acknowledgement. Write scenarios require separate opt-in flags.

No production data was modified as part of the test-documentation work.

## System under test

The candidate is a Flutter 3.44.8 / Dart 3.12.2 application using:

- Riverpod for state and dependency wiring;
- GoRouter for top-level routing, with some local `MaterialPageRoute` flows;
- Supabase Auth, Postgres, Row Level Security, and Edge Functions;
- a repository/provider boundary for most business data;
- feature-first UI modules and shared Workloop design primitives;
- on-device notifications for task and booking reminders.

The application version is `1.0.0+1`. The primary source inventory is
[`docs/CurrentState.md`](../CurrentState.md), while release and external
operational gates are tracked in
[`docs/LaunchReadiness.md`](../LaunchReadiness.md).

## Test layers

### 1. Static quality

Run formatting, analysis, dependency resolution, Deno checks, and vulnerability
scanning before behavioural conclusions.

```bash
source scripts/dev_env.sh
flutter pub get
dart format --output=none --set-exit-if-changed \
  lib test integration_test tool
flutter analyze
deno fmt --check supabase/functions quality/load
deno lint supabase/functions
deno test supabase/functions
```

Run the repository's consolidated safe suite with:

```bash
scripts/qa_all.sh
```

Database tests, integration tests, and builds are opt-in in that script because
their prerequisites and safety boundaries differ.

### 2. Unit and provider logic

Pure business rules and provider aggregation should be deterministic and fast.
High-priority subjects are:

- email, password, phone, amount, recurrence, and working-hours validation;
- booking overlap, recurrence, duration, price precision, status transitions,
  retry keys, and date/time boundaries;
- income, expense, outstanding amount, period bounds, and dashboard totals;
- client search, status filters, sorting, duplicate-like contacts, and
  relationship aggregation;
- task state, reminders, checklist handling, and note parsing/import;
- pagination beyond the Supabase default row cap;
- import retry behaviour that cannot duplicate previously successful records;
- malformed, null, partial, and stale backend payloads.

Tests should use explicit fixed clocks and currencies. A test that crosses a
day or month boundary must name the time zone and daylight-saving expectation.

### 3. Widget and responsive behaviour

Widget tests cover shared primitives and complete high-risk screens, including
loading, empty, populated, error, disabled, destructive, retry, and keyboard
states. The responsive matrix must include:

- small, standard, and large iPhone-like viewports;
- small, standard, and large Android-like viewports;
- normal and large accessibility text;
- keyboard-open and safe-area-sensitive forms;
- long names, emails, labels, and currency values.

The current responsive harness is
[`test/launch_responsive_matrix_test.dart`](../../test/launch_responsive_matrix_test.dart).
Automated overflow coverage does not replace interaction testing on physical
devices.

### 4. Golden visual regression

The deterministic launch-surface suite is
[`test/golden/launch_surfaces_golden_test.dart`](../../test/golden/launch_surfaces_golden_test.dart).
It uses fixed fonts, dimensions, data, and disabled animation.

Run:

```bash
flutter test test/golden/launch_surfaces_golden_test.dart \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=ci-public-anon-key
```

Update expected images only after a human has inspected the candidate render:

```bash
flutter test test/golden/launch_surfaces_golden_test.dart \
  --update-goldens \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=ci-public-anon-key
```

An unexplained pixel change is a review input, not an image to approve
automatically.

### 5. Integration and end-to-end

The current integration harness,
[`integration_test/launch_smoke_test.dart`](../../integration_test/launch_smoke_test.dart),
checks signed-out launch plus sign-up, sign-in, and password-reset navigation
without using a real backend. Lifecycle transitions remain a real
simulator/device test because synthetic desktop transitions do not model the
platform state machine reliably.

Run it on a selected simulator or emulator:

```bash
QUALITY_DEVICE_ID=<isolated-device-id> scripts/qa_integration.sh
```

The launch gate also requires a separate authenticated suite against an
isolated Supabase environment for:

- registration, onboarding, restart, and returning session;
- client create/edit/search;
- booking create/reschedule/complete/cancel and cross-module refresh;
- booking-request submit, duplicate retry, owner triage, decline, and
  conversion;
- income, expense, task, note, and dashboard reconciliation;
- permission denial and recovery;
- network timeout, token expiry, duplicate tap, retry, and interrupted submit;
- archive/restore, export, and destructive account deletion;
- two-account data isolation.

That authenticated suite must not run against production.

### 6. Database and security

The local stack is rebuilt from migrations before pgTAP runs:

```bash
scripts/qa_local_supabase.sh
```

The current tests are:

- [`001_schema_security.test.sql`](../../supabase/tests/database/001_schema_security.test.sql)
  for schema, RLS, grants, primary keys, tenant foreign keys, and workflow
  boundaries;
- [`002_rls_isolation.test.sql`](../../supabase/tests/database/002_rls_isolation.test.sql)
  for User A, User B, anonymous, cross-tenant mutation, and service-role
  boundaries.

See [SECURITY_TESTING.md](SECURITY_TESTING.md) for the threat model and
unexecuted areas.

### 7. Data volume and performance

[`tool/quality/generate_test_data.dart`](../../tool/quality/generate_test_data.dart)
generates deterministic JSONL fixtures for small, medium, large, and
50,000-account profiles. It writes only under `build/quality_data` and never
writes directly to a backend. The scale profile requires
`WORKLOOP_TEST_ENV=isolated` when not run in dry-run mode.

Performance evidence must record, rather than estimate:

- cold and warm startup;
- Auth restore and dashboard first useful content;
- list loading, search, filter, and calendar render time;
- p50/p95 query latency for representative datasets;
- frame build/raster times and jank;
- memory at idle, after repeated navigation, and after long-list scrolling;
- request count, payload size, pagination behaviour, and provider rebuilds.

No optimisation is considered proven without a before-and-after measurement.

### 8. Staging load and concurrency

The guarded k6 suite is documented in
[LOAD_TESTING.md](LOAD_TESTING.md). It distinguishes registered accounts,
represented accounts, active virtual users, concurrent sessions, and actual
request throughput. A generated 50,000-account file does not prove that 50,000
accounts were seeded or that any concurrency level was executed.

### 9. Accessibility and manual platform QA

Automated tests check semantic labels, contrast contracts, text scaling,
overflow, and minimum control dimensions where practical. A release candidate
still needs manual:

- VoiceOver and TalkBack focus order, announcements, rotor/navigation, and
  modal return focus;
- reduced-motion and high-text-scale review;
- notification permission, scheduling, tap-through, reboot, and time-zone
  changes;
- contacts/calendar permission accepted, denied, and revoked;
- password-recovery and deep-link handling;
- fresh install, upgrade, background/resume, offline, and interrupted
  submission;
- small iPhone and small Android physical-device review.

The detailed manual matrix remains in
[`docs/LaunchReadiness.md`](../LaunchReadiness.md#manual-release-matrix).

## CI policy

[`mobile-ci.yml`](../../.github/workflows/mobile-ci.yml) is intended to gate:

- format, analysis, Flutter tests, and coverage;
- deterministic data-profile validation;
- Deno formatting, type checks, and tests;
- Android profile and web release builds;
- unsigned iOS profile build;
- clean local Supabase migration replay and pgTAP;
- Android signed-out integration smoke.

[`scheduled-quality.yml`](../../.github/workflows/scheduled-quality.yml) is
intended to run broad regression, dependency inventory, vulnerability scanning,
and an explicitly enabled staging-only moderate load profile.

A workflow definition is not proof of a hosted pass. CI conclusions require a
successful run URL and commit SHA.

## Defect policy

For every defect:

1. reproduce it with the smallest stable case;
2. retain or add a failing regression test;
3. record severity, affected workflow, and root cause;
4. make the smallest architecture-consistent fix;
5. run focused tests, then the full safe suite;
6. record any test that could not be rerun;
7. never weaken an assertion or silently refresh a golden to hide the defect.

Cross-user exposure, data loss, wrong money values, duplicate atomic-workflow
writes, destructive-operation bypass, or a crash in a core journey is a release
stop.

## Release evidence gate

Source can advance to a technical release verdict only when:

- final formatting, analysis, Flutter, Deno, golden, and supported build runs
  pass on the same candidate;
- clean migration replay and pgTAP pass in isolation;
- authenticated two-account and core-business E2E passes in staging;
- public booking-request abuse, idempotency, and conversion are exercised;
- representative app performance and staging load are measured;
- VoiceOver, TalkBack, permission, offline, lifecycle, and physical-device
  matrices are signed off;
- iOS and Android release signing succeeds;
- production Auth delivery, leaked-password protection, legal URLs, support
  operation, and store declarations are complete.

Until then, [KNOWN_GAPS.md](KNOWN_GAPS.md) remains part of the release decision.
