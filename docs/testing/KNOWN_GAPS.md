# Workloop Known Quality and Launch Gaps

Last updated: 2026-07-26

## How to use this register

This is a release-risk register, not a backlog of every desirable enhancement.
An item closes only when its exit evidence is recorded against the release
commit. A source implementation or written test is not equivalent to a passing
dynamic result.

No confirmed critical cross-user exposure, destructive bypass, or core data-loss
defect was identified in the static/read-only review. That does not prove their
absence because several critical dynamic suites are blocked.

## High-severity release blockers

| ID | Gap | Evidence and impact | Exit evidence | Suggested owner |
| --- | --- | --- | --- | --- |
| H-01 | Clean database replay and pgTAP were not executed locally | Docker was unavailable. The schema/RLS suites are implemented, but the reconstructed clean baseline and all later migrations have not been proven from an empty database on this candidate. A migration or policy error can block a new environment or expose data. | `supabase db reset --local` and `supabase test db` pass on the release SHA; CI run URL retained; no skipped assertions. | Backend / QA |
| H-02 | No isolated authenticated core-business E2E | The current integration harness is signed-out only. Registration, onboarding, client, booking, money, task, note, dashboard refresh, restart, token expiry, and retry are not proven together. | Automated authenticated journey passes on iOS and Android against disposable Supabase staging, including restart and failure recovery. | Mobile / QA |
| H-03 | Two-account isolation is authored but not dynamically proven | pgTAP User A/User B tests are unexecuted, and no client-SDK cross-tenant select/insert/update/delete/export run exists. A failure would be critical. | Local pgTAP plus SDK-level two-user suite rejects every cross-tenant operation and validates unchanged victim data. | Backend security |
| H-04 | Public booking-request workflow lacks production-like end-to-end proof | Static validation, rate-limit, retry, conversion, and UI tests exist, but signed-out submit, owner notification/triage, decline, and atomic conversion have not run in an isolated deployed environment. This is a core public acquisition path. | Disposable staging run covers valid request, honeypot, invalid service, source/phone rate limits, stable duplicate token, parallel submit, recovery, preferences, owner triage, decline, and conversion. | Product / Backend / QA |
| H-05 | Account deletion is not verified end to end | Completion is destructive and was correctly not run against production. Sole-owner completion, multi-member rejection, cascade/orphan behaviour, audit access, retry, and operational follow-through remain unknown. | Disposable production-like accounts prove request, export, sole-owner completion, multi-member denial, cleanup, audit protection, retry, and user communication. | Backend / Operations |
| H-06 | Production Auth controls and delivery are incomplete | Leaked-password protection is disabled. SMTP sender identity, confirmation, password recovery, redirect allow-list, expiry/revocation, and external delivery are not verified. Users could fail to onboard or recover access. | Enable leaked-password protection; verify confirmation and recovery with external addresses on both platforms; record rate limits and redirect behaviour. | Backend / Operations |
| H-07 | Public legal, deletion, and support endpoints are not operational | The observed apex HTTPS checks timed out and `www` resolved to a parking destination. Store-required privacy, terms, deletion, and monitored support cannot be considered available. | Public HTTPS pages return successful responses without Auth, apex/`www` redirect consistently, support mailbox is monitored, and legal/operator wording is approved. | Operations / Legal |
| H-08 | Distribution signing and store operation are incomplete | Android release bundle is guarded until an upload keystore exists. iOS Distribution certificate/App Store profile are absent. Store accounts, declarations, review credentials, agreements, tax, and banking are external gates. | Signed AAB and IPA build from the release tag; signatures verified; both console submissions and declarations complete. | Release manager |
| H-09 | Physical Android and full accessibility/device matrix are incomplete | Automated viewports cannot prove TalkBack/VoiceOver order, permissions, notification delivery, deep links, lifecycle, reinstall/upgrade, keyboard, and OS behaviour. The latest candidate has not completed the full iOS/Android manual matrix. | Signed manual results for a small and current Android device, supported iPhone/simulator set, VoiceOver, TalkBack, large text, reduced motion, permissions, notifications, deep links, offline, reinstall, and upgrade. | Mobile QA |
| H-11 | Brand and store-title clearance is unresolved | Other products use similar Workloop/WorkLoop names. This is not a code defect, but it can block or force a late launch change. | Professional target-market clearance and reservation of both store listing names, with explicit product decision. | Founder / Legal |

## Medium-severity launch risks

| ID | Gap | Impact | Exit evidence | Suggested owner |
| --- | --- | --- | --- | --- |
| M-01 | No staging project or executed load test | No measured RPS, p50/p95/p99, error rate, database pressure, rate-limit response, or post-spike recovery exists. Scale confidence is unknown. | Approved isolated staging; smoke, baseline, moderate, spike, and recovery evidence with integrity checks. | Backend / SRE |
| M-02 | No measured in-app performance profile | Pagination and an aggregation hot path were audited in source/tests, but startup, frame timing, memory, rebuilds, query latency, and 1k/10k record UX are not measured on target devices. | DevTools/trace evidence before and after fixes on representative iOS/Android hardware and datasets. | Flutter / QA |
| M-04 | CI changes have no hosted pass history | Database and Android integration jobs are configured, but source configuration alone cannot prove runner/tool compatibility or stability. | Successful PR and scheduled workflow URLs retained for release SHA; failures/flakes resolved. | DevOps |
| M-05 | Production crash/error reporting is absent | Post-launch crashes, Edge failures, and degraded journeys may be invisible until users report them. This increases incident time and weakens launch confidence. | Adopt a privacy-reviewed crash/error service or explicitly accept the risk with support/monitoring and rollback procedures. | Product / Engineering |
| M-06 | Repository fakes and network-failure coverage remain thin | Many widget tests exercise UI logic, but real repository failures, timeouts, stale responses, cancellation, and partial payloads are not consistently injectable across modules. | Standard repository fakes cover loading/error/retry/offline/token-expiry for every critical module. | Flutter |
| M-07 | Storage isolation is untested | No launch attachment workflow or bucket policy was identified. Generated file metadata does not prove Supabase Storage security. Risk becomes high if attachments are enabled or marketed. | Keep attachments out of launch claims, or add buckets, least-privilege policies, two-user tests, signed URL expiry, size/type limits, malware/privacy operations. | Product / Backend |
| M-08 | Private workflow tables rely on schema/grant isolation without RLS | The inspected `app_private` counter/idempotency tables had no client grants and were outside exposed schemas, but Supabase surfaces a generic RLS warning. A future grant/config drift could weaken defence in depth. | Reviewed decision plus automated schema exposure/grant assertions; preferably validate an RLS-compatible hardening migration locally. | Backend security |
| M-09 | Public booking and Places operational controls are not verified | Server key restriction, quotas, billing alerts, booking salt/limits, timeout behaviour, and external dependency degradation are operational rather than source-only controls. | Staging/production configuration review and monitored smoke tests, without exposing keys. | Backend / Operations |
| M-10 | Reminder behaviour is not proven across device lifecycle | Logic tests cannot prove OS permission denial, reboot, app update, DST/time-zone changes, background limits, reschedule/cancel, and tap routing. | iOS/Android device matrix with controlled clocks and restart/reboot cases. | Mobile QA |
| M-11 | Import and export platform edges remain manual | Retry logic has regressions, but contact/calendar/file picker denial, revocation, malformed files, huge datasets, interruption, encoding, and share-sheet outcomes need device tests. | Permission and failure matrix on both platforms, including duplicate-free partial retry and complete workspace export. | Mobile QA |
| M-12 | Large legacy screens and mixed local routing remain | Oversized booking, finance, tasks, settings, and client files increase regression cost; mixed GoRouter/local routes complicate deep links and restoration. Refactoring now would add launch risk. | No launch-blocking behaviour failure; schedule small, test-backed extractions after release rather than a broad rewrite. | Flutter |
| M-13 | Non-Dart dependency vulnerability coverage is tool-limited | OSV-Scanner 2.4.0 found no issue in 132 resolved Dart packages. It did not recognise the Deno or CocoaPods lock formats; six direct Flutter packages are behind their latest releases. Blind upgrades can also introduce regressions. | Produce an SBOM or use scanners that support the Deno and native graphs; review and test each justified upgrade. | Flutter / Security |

## Closed during this audit

| ID | Closed risk | Exit evidence |
| --- | --- | --- |
| H-10 | Final candidate safe verification was incomplete. | [TEST_RESULTS.md](TEST_RESULTS.md) now records the final 249-test Flutter run, 19-test Deno run, goldens, integration smoke, dependency evidence, generator guards, and supported platform builds. |
| M-03 | Launch goldens were not final or human-reviewed. | Eleven tests produced 13 expected images; every image was reviewed after the final UI change and the non-update suite passed. |

## Low-severity and follow-up gaps

| ID | Gap | Recommended action |
| --- | --- | --- |
| L-01 | Automated coverage remains uneven by feature even if aggregate line coverage rises. | Track critical behaviours by matrix row; do not chase 100% or use aggregate percentage as the release verdict. |
| L-02 | Edge Deno tests cover selected helpers/functions, not every deployed error path. | Add contract tests for each response code, CORS/auth boundary, malformed payload, timeout, and safe error body. |
| L-03 | Notification history is bounded rather than user-paginated. | Add cursor pagination when real usage shows the owner needs older history; preserve bounded dashboard/provider reads. |
| L-04 | Domain email authentication was not fully verified. | Configure and verify SPF, DKIM, and DMARC for the production sender/support operation. |
| L-05 | App version is still the initial `1.0.0+1`. | Assign monotonically increasing store build numbers during signed release preparation. |
| L-06 | No automated upgrade/migration compatibility suite exists. | Preserve representative previous-version local data and add upgrade tests before the first update release. |

## Deliberately absent or limited launch capabilities

These are not defects if product copy remains accurate:

- remote APNs/FCM push delivery;
- live or two-way calendar sync;
- card payment processing, deposits, Stripe, or bank feeds;
- subscription entitlement or paid-plan gating;
- file attachments or Supabase Storage-backed user files;
- AI-first workflows or an enabled AI assistant;
- team/staff operation;
- tablet-optimised or landscape UI.

If any store listing, onboarding screen, support response, or marketing page
claims one of these capabilities, the gap becomes a launch-blocking copy defect.

## Release position

The current evidence supports continued controlled internal testing. It does not
yet support “technically ready for public release” because H-01 through H-09
and H-11 include unexecuted database/security/E2E/device evidence and external
store operation.

The final safe local suite now passes. A closed beta becomes reasonable only
after the high-risk database/Auth/booking gates needed by beta users are
closed, access is controlled, support is staffed, and no
production-destructive testing is implied. Public store launch still requires
every applicable high-severity exit condition.

## Prioritised closure order

1. Run a clean local Supabase replay and pgTAP in Docker/CI.
2. Provision disposable staging and run User A/User B plus authenticated core
   E2E.
3. Exercise public booking-request and deletion workflows safely.
4. Complete physical Android/iOS, accessibility, permission, reminder, offline,
   lifecycle, and deep-link QA.
5. Enable and test production Auth protections and email delivery.
6. Publish and verify legal/deletion/support operations.
7. Run measured app performance and staged load tests.
8. Configure signing, stores, declarations, review access, and brand clearance.
9. Run and retain hosted CI evidence for the candidate.
10. Tag the exact reviewed candidate and retain all evidence.
