# Workloop Test Results

Last updated: 2026-07-28

> **Final local evidence ledger for branch
> `codex/comprehensive-launch-audit-2026-07-26`.** Commands below were observed
> after the last source, migration, and golden change. Production was not
> mutated. Passing local evidence is not a substitute for the isolated
> staging, store, and physical-device gates recorded below.

## 1. Executive summary

The audit found a broad Flutter test inventory, targeted Deno tests, new
responsive/golden/integration harnesses, local pgTAP security contracts,
deterministic dataset tooling, guarded k6 scenarios, and expanded CI.

The final candidate is clean for formatting and static analysis. All 249
Flutter tests and all 19 Deno tests pass. Eleven launch goldens were generated,
visually inspected, and then passed in non-update mode. The signed-out iOS
simulator integration smoke passes. Android debug/profile, web release, iOS
simulator debug, and unsigned iOS profile/release artifacts all compile.

No production data was modified. Destructive, database-reset, multi-user,
authenticated E2E, and load tests were not pointed at production.

Verdict: **strong closed-beta candidate after the remaining backend/Auth gates,
but not ready for public store launch**. Clean database/security execution,
authenticated staging E2E, physical Android/accessibility QA, production Auth
operations, public legal/support URLs, distribution signing, and store
operation remain open. No “bug-free” claim is made.

## 2. Work completed

The candidate includes:

- expanded unit/provider regression coverage for Auth/import, CRM, money/feed,
  finance boundaries, scheduling/tasks/notes, booking workflow/security, UI
  trust/accessibility, failure safety, and repository pagination;
- a multi-device/text-scale responsive harness;
- deterministic launch-surface golden tests;
- a signed-out Flutter integration smoke;
- a local-only Supabase configuration and clean-schema baseline migration;
- pgTAP schema/grant and two-user RLS tests;
- deterministic small, medium, large, and 50,000-account fixture profiles;
- guarded k6 staging scenarios and explicit write/cost opt-ins;
- consolidated local QA scripts;
- pull-request database/integration jobs and scheduled dependency/load jobs;
- this testing strategy, matrix, results ledger, security plan, load runbook,
  and gap register.

See:

- [TEST_STRATEGY.md](TEST_STRATEGY.md)
- [TEST_MATRIX.md](TEST_MATRIX.md)
- [SECURITY_TESTING.md](SECURITY_TESTING.md)
- [LOAD_TESTING.md](LOAD_TESTING.md)
- [KNOWN_GAPS.md](KNOWN_GAPS.md)

## 3. Verified baseline before final audit changes

These commands passed earlier on 2026-07-26, before all current audit changes
were complete.

| Suite | Observed baseline | Scope warning |
| --- | --- | --- |
| Dart format | Clean across 161 files | Current tree changed afterward. |
| Flutter analysis | No issues | Current tree changed afterward. |
| Flutter tests | 156 passed, 0 failed, approximately 26.49 seconds | Current tree now contains additional tests and implementation changes. |
| Flutter line coverage | 4,727 of 17,074 lines, 27.69% | Aggregate coverage is not a critical-workflow guarantee. |
| Deno tests | 16 passed, 0 failed | Superseded by the 19-test final run below. |
| OSV-Scanner 2.4.0 | No known issue in the earlier supported lockfile scan | Superseded by the final Dart lockfile scan below. |
| Android profile | APK built and passed 16 KB `zipalign` verification | Not a signed release bundle. |
| iOS profile | Built and launched on an attached iPhone with Dart VM service evidence | Not App Store signing/export. |
| Web release | Built successfully | Does not prove public domain deployment. |

## 4. Final candidate command ledger

Use non-secret placeholder Dart defines for source-only tests/builds. Use an
isolated target only where backend behaviour is required.

| Area | Command | Tests/checks | Passed | Failed | Skipped | Duration | Final status |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| Toolchain | `flutter doctor -v` | Flutter 3.44.8 / Dart 3.12.2 | 5 categories | 1 category | 0 | 7.4 s | **Supported mobile toolchains pass; Chrome absent** |
| Dependencies | `flutter pub get` | 132 resolved Dart packages | 1 | 0 | 0 | 1.2 s | **Pass** |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 186 files | 186 | 0 | 0 | 0.84 s | **Pass** |
| Analysis | `flutter analyze` | 0 diagnostics | 1 | 0 | 0 | 3.0 s | **Pass** |
| Flutter full suite | `flutter test --coverage --dart-define-from-file=.env` | 249 | 249 | 0 | 0 | approximately 33 s wall time | **Pass** |
| Flutter coverage | LCOV summary from `coverage/lcov.info` | 17,493 lines | 7,014 lines hit | 10,479 lines not hit | N/A | N/A | **40.10% line coverage** |
| Golden suite | Update, visual review, then non-update `launch_surfaces_golden_test.dart` | 11 tests / 13 image files | 11 | 0 | 0 | approximately 3 s | **Pass; safe-area-aware and human-reviewed after final UI change** |
| Responsive matrix | Included in full suite | 2 declarations / 108 render cases plus keyboard case | 110 render checks | 0 | 0 | Included in full run | **Pass** |
| Accessibility contracts | Included in full suite | 4 declarations | 4 | 0 | 0 | Included in full run | **Pass; physical AT still manual** |
| Booking regressions | Workflow, confirmation, controls, recurrence, and backend security files | 34 | 34 | 0 | 0 | Included in full run | **Pass** |
| Core audit regressions | `test/core_audit_*_test.dart` | 33 | 33 | 0 | 0 | Included in full run | **Pass** |
| Integration smoke | `QUALITY_DEVICE_ID=390... scripts/qa_integration.sh` on iPhone 17 Pro simulator / iOS 26.5 | 1 | 1 | 0 | 0 | 36.8 s build + 4 s test | **Pass** |
| Deno format | `deno fmt --check supabase/functions quality/load` | 20 files | 20 | 0 | 0 | <1 s | **Pass** |
| Deno lint | `deno lint supabase/functions` | 14 files | 14 | 0 | 0 | <1 s | **Pass** |
| Deno type checks | Function-specific `deno check` commands in `scripts/qa_all.sh` | 6 entry points | 6 | 0 | 0 | <1 s cached | **Pass** |
| Deno tests | `deno test supabase/functions` | 19 | 19 | 0 | 0 | 39 ms | **Pass** |
| Data profiles | Dry-run small, medium, large, and scale-50000 profiles | 4 profiles | 4 | 0 | 0 | 1.7 s | **Pass; no backend writes** |
| Small data generation | Generate then rerun the `small` profile | 8 represented accounts | 8 generated | 0 | 1 existing batch skipped on retry | Within 3.7 s combined generator run | **Pass; resume verified** |
| Scale batch generation | One `scale-50000` batch with isolated opt-in | 50,000 represented / 250 generated | 250 | 0 | 199 batches not requested | Within 3.7 s combined generator run | **Pass as generator evidence only** |
| Generator safety | Scale without isolated opt-in; output outside `build/quality_data` | 2 negative checks | 2 refused safely | 0 | 0 | 0.87 s | **Pass; exits 78 and 64** |
| Local migrations | `scripts/qa_local_supabase.sh` | 0 migrations executed | 0 | 0 | Entire run | 0.17 s | **Blocked: Docker unavailable** |
| pgTAP schema/security | `supabase test db` | 43 authored assertions | 0 executed locally | 0 | 43 locally | N/A | **Implemented, unexecuted locally** |
| Dependency scan | OSV-Scanner 2.4.0 against `pubspec.lock` | 132 Dart packages | 132 | 0 known issues | Deno/CocoaPods lock formats unsupported by scanner | 0.46 s | **Pass for supported Dart graph; scope-limited** |
| Dependency inventory | `flutter pub outdated --no-transitive` | 6 direct packages behind latest | N/A | N/A | N/A | 1.2 s | **Reviewed; no blind launch upgrade** |

The pgTAP total is 31 schema/grant assertions plus 12 isolation assertions.
It is an authored count, not an executed pass count.

## 5. Build and platform ledger

| Target | Command/device | Result | Evidence limit |
| --- | --- | --- | --- |
| Android debug APK | `flutter build apk --debug` with placeholder defines | **Pass; 157 MB** | Build only. |
| Android profile APK | `flutter build apk --profile --dart-define-from-file=.env` | **Pass; 113.5 MB; 16 KB `zipalign` pass; APK signature verifies** | Debug certificate is expected for profile and is not a store signature. |
| Android release AAB | `flutter build appbundle --release` | **Blocked safely: exit 1, “Release signing is not configured”** | No debug-key fallback. |
| Android emulator integration | API 35/Pixel-class emulator | **Not executed locally; CI harness only** | No local Android virtual device or hosted CI result. |
| Android physical device | Supported small/current phone | **Not executed in this audit** | Permissions, TalkBack, lifecycle, reminder, deep-link, reinstall, and upgrade remain manual. |
| iOS debug simulator | `flutter build ios --debug --simulator` | **Pass; installed and launched** | Custom recovery scheme registration verified; token exchange was not. |
| iOS profile unsigned | `flutter build ios --profile --no-codesign` | **Pass; 35.3 MB** | Not an App Store artifact. |
| iOS profile development-signed | `flutter build ios --profile --dart-define-from-file=.env` | **Pass; 34.8 MB** | Development signing only; not an App Store artifact. |
| iOS release unsigned | `flutter build ios --release --no-codesign` | **Pass; 26.2 MB** | Compile evidence only. |
| iOS IPA | `flutter build ipa --release` | **Not attempted: only Apple Development identity exists; Distribution profile/certificate absent** | Store artifact remains blocked. |
| iOS simulator integration | iPhone 17 Pro / iOS 26.5 | **Pass, 1/1** | Signed-out Auth/navigation smoke only. |
| iOS physical device | Ismaeel’s iPhone / iOS 26.5.2 | **Current profile installed and launched; CoreDevice confirmed the Workloop process running** | Physical launch is confirmed; full manual VoiceOver/permission/lifecycle coverage remains open. |
| Web release | `flutter build web --release` with placeholder defines | **Pass; 44 MB** | Does not deploy legal/support pages. |

## 6. Feature coverage summary

| Module | Unit/provider | Widget/UI | Integration | Database/security | Current confidence |
| --- | --- | --- | --- | --- | --- |
| Auth/onboarding | Partial | Partial | Signed-out harness only | Partial contracts | Medium-low until isolated E2E and production email/recovery |
| Dashboard/feed | Strong targeted logic | Partial responsive/state | None authenticated | Indirect | Medium |
| Clients/CRM | Strong targeted logic | Partial form/list/detail | None authenticated | Isolation harness pending | Medium |
| Bookings | Strong targeted logic/contracts | Partial form/list/detail | None authenticated | Workflow/RLS harness pending | Medium; public request flow remains high risk |
| Money | Strong calculation/boundary logic | Partial | None authenticated | Relationship/RLS harness pending | Medium |
| Tasks/notes | Strong targeted logic | Partial | None authenticated | Workflow/RLS harness pending | Medium |
| Notifications/reminders | Partial | Partial | None on device | Partial RLS contract | Medium-low |
| Profile/settings/services/hours | Partial | Partial | None authenticated | Partial RLS contract | Medium |
| Export/deletion | Partial | Partial | None destructive | Partial source/contracts | Low until disposable E2E |
| Platform/accessibility | Automated contracts and viewport matrix | Goldens pass and are reviewed | Signed-out iOS simulator smoke | Not applicable | Medium-low until physical-device matrix |

Detailed, test-file-linked coverage is in
[TEST_MATRIX.md](TEST_MATRIX.md).

## 7. Defects found and regression status

The following issues were reproduced during the audit, fixed in the candidate,
and covered by the final 249-test pass unless otherwise stated.

| Severity | Feature | Reproduction/root cause | Candidate fix | Regression evidence |
| --- | --- | --- | --- | --- |
| High | Repository data loading | Supabase-sized result sets could stop at a default page boundary, hiding later business records. | Shared stable pagination used across repositories/providers. | Final pagination and full suites pass. |
| High | Import retries | Partial retry could resubmit records already created, producing duplicate customer data. | Retain/retry only failed records. | Final Auth/import and full suites pass. |
| High | Booking requests | Stale lifecycle updates and retry/error paths could fail silently or lose price precision. | Workspace-scoped update checks, visible failure mapping, stable retry key, atomic conversion contract, and decimal price preservation. | 34 booking regressions, 8 request-validation Deno tests, and full suites pass; dynamic staging still required. |
| High | Money/dashboard | Date and daylight-saving boundaries could include/exclude the wrong records or misstate connected totals. | Explicit inclusive/exclusive period bounds and corrected aggregation. | Final finance/client/feed and full suites pass. |
| Medium | Booking status | Cancelled/no-show/completed entries could appear as the next actionable booking. | Restrict next-booking selection to actionable scheduled state. | Final scheduling and full suites pass. |
| Medium | Currency precision | Appointment and connected Money/CRM surfaces rounded `149.99` to `150`. | Central `formatPounds`/`currencyInputValue` across every currency surface. | Unit contracts pass; reviewed booking golden shows `£149.99`. |
| Medium | Small-phone appointments | Empty schedule content overflowed a 320×568 viewport. | Scrollable refreshable sliver empty state. | Final 96-case responsive matrix passes. |
| Medium | Large text shared header | Section label/action row overflowed at 2× text scale. | Flexible bounded label/action layout with line limits. | Final 96-case responsive matrix passes. |
| Medium | Contact/request reuse | Formatting differences in phone numbers could create duplicate-like contacts during booking conversion. | Normalised phone matching at the workflow boundary. | Backend/security contract and migration coverage added; dynamic DB run pending. |

Unresolved environment, operations, and evidence risks are tracked separately
in [KNOWN_GAPS.md](KNOWN_GAPS.md); none is silently converted into a pass.

## 8. Supabase security results

| Area | Result |
| --- | --- |
| Production changes | None |
| Read-only live metadata | Inspected on 2026-07-26 |
| Public table RLS | Enabled on inspected live application tables |
| Anonymous direct table grants | None observed on inspected application tables |
| Private workflow table client grants | None observed |
| Private-table RLS | Two internal tables observed without RLS; protected by private schema/no client grants, with defence-in-depth decision still open |
| User A/User B pgTAP | Authored, not executed locally |
| Storage isolation | Not tested; no launch bucket/policy workflow identified |
| Edge source tests | 19/19 final Deno tests pass; six entry points type-check |
| Public booking abuse/concurrency | Not executed against isolated deployment |
| Account deletion completion | Not executed |
| Leaked-password protection | Disabled; release blocker |

See [SECURITY_TESTING.md](SECURITY_TESTING.md).

## 9. UI and accessibility results

| Area | Current result |
| --- | --- |
| Automated semantic/contrast contracts | Four launch accessibility declarations plus theme/primitive contracts pass in the 249-test suite |
| Phone/text-scale responsive matrix | 108 surface renders plus keyboard case pass after overflow fixes |
| Golden images | Eleven tests / 13 image files generated intentionally, human-reviewed, and passed in non-update mode |
| Keyboard/form safety | Targeted widget coverage exists; physical platform matrix pending |
| VoiceOver | Not executed on final candidate |
| TalkBack | Not executed |
| Reduced motion | Source/test contracts exist; manual device confirmation pending |
| Touch targets/focus order | Partial automation; manual review pending |

Automated semantics cannot confirm spoken wording, focus order across every
route, modal return focus, or OS assistive-technology behaviour.

## 10. Performance results

No release-grade device performance profile was executed.

Static and regression work addressed pagination and an avoidable client-CRM
aggregation cost, but no final before/after startup, query, frame, rebuild, or
memory measurements are recorded. The 1, 100, 1,000, and 10,000-record device
matrix remains open.

Do not convert algorithmic reasoning or a passing unit test into an unmeasured
latency claim.

## 11. Load-test results

No backend load test was executed. Exact status:

- backend users seeded: **0**;
- maximum concurrent users tested: **0**;
- requests per second: **not measured**;
- p50/p95/p99: **not measured**;
- error and timeout rates: **not measured**;
- failed writes/data corruption: **not measured**;
- 50,000-user target: **represented by a deterministic generator profile
  only**, not seeded or concurrently simulated.

See [LOAD_TESTING.md](LOAD_TESTING.md).

## 12. Tests not executed

- Clean local Supabase reset and pgTAP: Docker unavailable.
- Authenticated new-user, core-business, failure-recovery, destructive, and
  multiple-account journeys: no disposable staging environment.
- Public booking-request abuse/idempotency/conversion: no isolated deployed
  target.
- Account deletion completion: destructive and no disposable production-like
  account.
- k6 smoke through stress: no staging approval/tooling; production safety and
  cost boundary.
- Real Realtime subscription/reconnect load: not implemented in k6.
- Full app performance/profile/memory matrix: not yet measured.
- Physical Android, TalkBack, permissions, reminders, deep links, reinstall,
  and upgrade: device/manual gap.
- Final VoiceOver and cross-device accessibility matrix.
- Signed Android AAB and iOS IPA: signing credentials absent.
- Store submission, declarations, review account, and public legal/support
  operation: external prerequisites.

## 13. Release blockers and exact next actions

1. Run clean local/CI Supabase replay and all 43 pgTAP assertions.
2. Provision isolated staging and execute authenticated two-account plus
   connected-business E2E.
3. Exercise public booking requests and disposable account deletion.
4. Complete measured performance and staged load work.
5. Complete the iOS/Android physical accessibility, permission, lifecycle,
   offline, reminder, and deep-link matrix.
6. Enable and verify Auth leaked-password protection and email/recovery.
7. Publish and verify privacy, terms, deletion, and monitored support endpoints.
8. Configure release signing, store declarations, review access, and brand
   clearance.
9. Run the corrected hosted CI workflows and retain the run URLs.
10. Preserve the exact verified source in a clean reviewed commit/tag.

The full severity register is [KNOWN_GAPS.md](KNOWN_GAPS.md).

## 14. 2026-07-28 final UI/UX refinement evidence

This pass evolved the existing shell and workflows without changing the
four-destination navigation, product scope, data contracts, or persistence
architecture.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Focused refinement matrix | 76/76 tests passed | Targeted workflow, state, accessibility, responsive, and golden coverage |
| Dart formatting | All `lib` and `test` files clean after formatting one changed test | Formatting only |
| `flutter analyze` | No issues | Static analysis cannot prove runtime service behaviour |
| `flutter test --dart-define-from-file=.env` | 279/279 tests passed | Local automated suite; authenticated staging E2E remains open |
| Golden suite | 11/11 tests passed in non-update mode; reviewed launch surfaces remain stable | Pixel coverage is limited to the declared fixtures |
| `flutter build ios --profile --dart-define-from-file=.env` | Pass; 34.8 MB `Runner.app` | Development signing, not App Store distribution |
| `flutter build apk --profile --dart-define-from-file=.env` | Pass; 113.6 MB APK | Profile artifact, not Play release signing |
| Physical iPhone profile launch | Installed and launched on iOS 26.5.2; Dart VM Service discovered; detached Runner process confirmed | Launch/debugger evidence, not a full manual workflow or VoiceOver pass |

The physical iPhone result confirms installation, launch, and debugger
attachment. Dynamic text, small-phone, keyboard reachability, reduced motion,
semantic actions, and failure recovery were exercised by automated widget
matrices. Physical Android, TalkBack, VoiceOver, permissions, notification
delivery, offline/reconnect, background/foreground lifecycle, reinstall, and
upgrade checks remain manual release gates.

## 15. 2026-07-28 dark-only usability and edge-case evidence

This pass removed the retired appearance preference, lifted the graphite
palette, aligned native startup surfaces, and expanded the responsive matrix.
It found and fixed a real 337-pixel overflow in the booking-request empty state
on a 320x568 viewport at 200% text.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Focused usability matrix | 86/86 tests passed | Dark-only, Settings ownership, responsive, accessibility, action geometry, and golden contracts |
| Launch responsive matrix | 11 surfaces x 6 phone viewports x 2 text scales = 132 render cases, plus keyboard reachability | Automated widget layouts; not a physical assistive-technology pass |
| Dart formatting | 189 `lib` and `test` files checked; no changes required | Formatting only |
| `flutter analyze` | No issues | Static analysis cannot prove deployed services |
| `flutter test --dart-define-from-file=.env` | 280/280 tests passed | Authenticated staging and production backend journeys remain open |
| Golden suite | 11/11 tests passed; 13 launch images visually reviewed | Declared fixtures only |
| iOS profile build | Pass; 34.8 MB `Runner.app` | Development signing, not App Store distribution |
| Android profile APK | Pass; 113.5 MB | Profile artifact, not Play release signing |
| Signed-out iOS simulator journey | 1/1 passed: launch, auth-mode toggle, forgot-password navigation | Does not exercise authenticated business data |
| Physical iPhone profile | Installed and launched on iOS 26.5.2; Dart VM Service discovered; Runner process confirmed | Launch and attachment proof, not a full VoiceOver/workflow matrix |

The iOS build still warns that `device_calendar` and
`flutter_local_notifications` do not declare Swift Package Manager support.
The current CocoaPods build succeeds, but future Flutter toolchain
compatibility should be monitored.

## 16. 2026-07-28 navigation-assist evidence

This pass added a shared top-edge scroll shortcut, independent retained-tab
scroll targets, and safe back-swipe behaviour without changing routes or draft
contracts.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Navigation-assist tests | 5/5 passed | Covers native iOS status-bar forwarding, top-edge return, retained tabs, clean route eligibility, and protected draft invocation |
| Focused navigation/regression set | 11/11 passed | Includes shell geometry, responsive matrix, destructive guards, and client handoff |
| Dart formatting | 190 `lib` and `test` files checked; no changes required | Formatting only |
| `flutter analyze` | No issues | Static analysis cannot assess physical gesture feel |
| `flutter test --dart-define-from-file=.env` | 285/285 tests passed | Automated evidence; authenticated staging remains open |
| iOS profile build | Pass; 34.8 MB `Runner.app` | Development signing |
| Android profile build | Pass; 113.6 MB APK | Profile artifact, not Play signing |
| Physical iPhone profile | Exact final artifact installed and launched on iOS 26.5.2; CoreDevice confirmed PID 34234 | Process/launch proof; human gesture feel checks on representative screens remain |

The protected iOS fallback only activates for a left-edge swipe when the
current route has rejected an immediate pop. It invokes `Navigator.maybePop`,
so existing saving/submission locks and Save/Discard/Keep editing prompts remain
authoritative.

## 17. 2026-07-29 physical navigation regression correction

The earlier automated contract did not match physical-device behaviour on
every screen. This correction replaces selected-controller assumptions with
global vertical-scroll discovery and extends the safe edge fallback to any
routed screen with a real previous/back action.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Navigation-assist tests | 8/8 passed | Includes implicit non-primary scroll discovery, complete clean-route swipe, direct routed-header action, retained tabs, and protected drafts |
| Dart formatting | 190 `lib` and `test` files checked; no changes required | Formatting only |
| `flutter analyze` | No issues | Static analysis cannot assess physical gesture feel |
| `flutter test --dart-define-from-file=.env` | 288/288 tests passed | Automated evidence; authenticated staging remains open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing |
| Android profile build | Pass; 113.7 MB APK | Profile artifact, not Play signing |
| Physical iPhone profile | Rebuilt, installed, and launched on iOS 26.5.2; CoreDevice confirmed PID 37404 | Process/launch proof; the user should re-check gesture feel on representative authenticated screens |

The iOS status-bar detector now remains an eligible, scroll-enabled
`UIScrollView` behind Flutter's rendered view. The Dart side selects only the
current route or active retained-tab scope. Native Cupertino navigation gets a
short first-refusal window; if it has not changed the route, the fallback calls
the registered back action or `Navigator.maybePop`, preserving draft guards.

## 18. 2026-07-29 forgiving navigation interaction correction

Physical use showed two remaining gaps: the top shortcut still required a
precise tap and a fallback edge swipe could be lost when Flutter cancelled the
pointer sequence. The interaction layer now treats the calm top/header area as
the shortcut, resets every visible vertical layer, and commits a deliberate
edge gesture as soon as it crosses the threshold.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Navigation-assist tests | 11/11 passed | Adds broad top-zone, simultaneous vertical layers, interactive-header isolation, wider edge start, and cancelled-pointer coverage |
| Dart formatting | 190 `lib` and `test` files checked; no changes required | Formatting only |
| `flutter analyze` | No issues | Static analysis cannot assess physical gesture feel |
| `flutter test --dart-define-from-file=.env` | 291/291 tests passed | Automated evidence; authenticated staging remains open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing |
| Android profile build | Pass; 113.7 MB APK | Profile artifact, not Play signing |
| Physical iPhone profile | Exact profile artifact installed and launched on iOS 26.5.2; CoreDevice confirmed PID 37437 | Process/launch proof; final human feel confirmation remains with the user |

## 19. 2026-07-29 retained-workspace and Clients navigation correction

Physical use isolated two concrete exceptions. Money, Tasks, and Notes are
retained shell destinations, so they had no Navigator route to pop. Clients
also placed tappable rows under the broad top zone and installed a full-screen
horizontal filter gesture, both of which could win before the app-level top
shortcut.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Navigation-assist tests | 13/13 passed | Adds retained-workspace return and a populated 40-row Clients top-zone journey |
| Clients regression | From a 760-point offset, the top-zone row tap returns to the Clients header instead of opening the row | Widget evidence; physical feel still requires user confirmation |
| Dart formatting | 190 `lib` and `test` files checked; no changes required | Formatting only |
| `flutter analyze` | No issues | Static analysis cannot assess physical gesture feel |
| `flutter test --dart-define-from-file=.env` | 293/293 tests passed | Automated evidence; authenticated staging remains open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing |
| Android profile build | Pass; 113.6 MB APK | Profile artifact, not Play signing |
| Physical iPhone profile | Exact profile artifact installed and launched on iOS 26.5.2; CoreDevice confirmed PID 37567 | Process/launch proof; final human feel confirmation remains with the user |

## 20. 2026-07-31 adaptive appearance and Tools launchpad

This pass restored a persisted System/Light/Dark appearance choice, introduced
a low-glare light palette through the shared theme system, and turned Tools
into a useful launchpad with direct capture actions and live workspace context.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Theme and appearance tests | System default, persistence, rollback, adaptive aliases, contrast, native startup resources, and Settings selection passed | Automated colour and state contracts; not a manual colour-vision review |
| Launch responsive matrix | 12 surfaces x 6 phone viewports x 2 text scales x 2 appearances = 288 render combinations passed | Widget layouts; not a physical VoiceOver or TalkBack pass |
| Golden suite | 14/14 tests passed; updated Tools and Settings dark images plus new light images visually reviewed | Declared fixtures only |
| `flutter analyze` | No issues | Static analysis cannot assess subjective appearance or physical interaction feel |
| `flutter test --dart-define-from-file=.env` | 305/305 tests passed | Authenticated staging and production backend journeys remain open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing, not App Store distribution |
| Android profile APK | Pass; 113.7 MB | Profile artifact, not Play release signing |
| Physical iPhone profile | Exact profile artifact installed on the paired iPhone 15 Pro Max | Automatic launch was denied because the phone was locked; no process-level launch confirmation in this pass |

The iOS build continues to warn that `device_calendar` and
`flutter_local_notifications` do not declare Swift Package Manager support.
The current CocoaPods build succeeds. The adaptive compatibility palette keeps
legacy feature widgets coherent while they are migrated gradually to direct
semantic theme tokens.

## 21. 2026-08-03 cohesive navigation-motion pass

This pass centralised forward motion for retained shell destinations and
refined the shared Android page transition while preserving native iOS
interactive navigation and all existing route and draft contracts.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Navigation-assist tests | 19/19 passed | Covers programmatic shell switching, forward retained-tool entry, reduced motion, native iOS back swipe, cancellation, retained workspaces, and draft guards |
| `flutter analyze` | No issues | Static analysis cannot assess subjective motion feel |
| `flutter test --dart-define-from-file=.env` | 308/308 tests passed | Automated evidence; authenticated staging journeys remain open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing, not App Store distribution |
| Android profile APK | Pass; 113.7 MB | Profile artifact, not Play release signing |
| Physical iPhone profile | Exact profile artifact installed and launched on the paired iPhone 15 Pro Max | CoreDevice launch confirmation; final transition feel remains a human review |

The iOS build continues to warn that `device_calendar` and
`flutter_local_notifications` do not declare Swift Package Manager support.
The current CocoaPods build succeeds.

## 22. 2026-08-03 retained-screen replay regression correction

A physical screen recording exposed repeated Add to Money sheets while moving
among New task, Home, Tools, and Tasks. The transition stack was remounting
retained feature screens and replaying an already-delivered create request.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Recording inspection | 60 frames sampled across the 29.65-second physical recording; repeated Money sheet replay confirmed across unrelated destinations | Visual diagnosis, not instrumentation |
| Navigation-assist tests | 20/20 passed | Includes retained create-request replay across repeated animated destination changes |
| `flutter analyze` | No issues | Static analysis cannot assess subjective motion feel |
| `flutter test --dart-define-from-file=.env` | 309/309 tests passed | Automated evidence; authenticated staging journeys remain open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing, not App Store distribution |
| Physical iPhone profile | Exact corrected artifact installed on the paired iPhone 15 Pro Max | Automatic launch was denied because the phone was locked; final replay check remains with the user |

The corrected stack keeps an identical outer tree and stable keyed layer for
every retained destination. Tools also clears Money, Task, and Note create
inputs after their first frame so remounting elsewhere cannot replay them.

## 23. 2026-08-03 light-mode contrast refinement

Physical dashboard review showed that the first low-glare Light palette was
readable but too tonally compressed. This pass increased layer separation and
added a canonical one-pixel border around neon-filled interactive controls.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Theme contracts | Light surface separation, divider contrast, accent-border contrast, and Material button border roles passed | Numeric and widget contracts; not a colour-vision simulation |
| Golden suite | 14/14 tests passed; 15 images generated, including a new dashboard Light fixture plus refreshed Tools and Settings Light fixtures | Declared deterministic data only |
| Visual review | Dashboard, Tools, and Settings Light fixtures reviewed at 390 x 844; canvas, surfaces, dividers, accent controls, and hierarchy remain distinct | Desktop image inspection, not ambient-light device measurement |
| `flutter analyze` | No issues | Static analysis cannot assess subjective appearance |
| `flutter test --dart-define-from-file=.env` | 310/310 tests passed | Authenticated staging journeys remain open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing, not App Store distribution |
| Physical iPhone profile | Exact refreshed artifact installed on the paired iPhone 15 Pro Max | Automatic launch was denied because the phone was locked; final ambient-light review remains with the user |

The iOS build continues to warn that `device_calendar` and
`flutter_local_notifications` do not declare Swift Package Manager support.
The current CocoaPods build succeeds.

## 24. 2026-08-03 warm-neutral Light mode redesign

The green-grey Light treatment and strong green outlines were replaced with a
warm stone canvas, ivory surfaces, neutral interaction layers, and selective
quiet sage edges around accent-filled controls. Dark mode and product workflows
were not changed.

| Evidence | Observed result | Limit |
| --- | --- | --- |
| Theme contracts | Warm layer separation, semantic text/status contrast, focus visibility, and one-pixel accent-edge roles passed | Numeric and widget contracts; not a colour-vision simulation |
| Golden suite | 14/14 tests passed; Light Dashboard, Tools, and Settings fixtures regenerated | Declared deterministic data only |
| Visual review | Home, Tools, and Settings reviewed at 390 x 844; page, cards, rows, text, and lime actions are clearly separated without green surface tint | Desktop image inspection, not ambient-light device measurement |
| `flutter analyze` | No issues | Static analysis cannot assess subjective appearance |
| `flutter test --dart-define-from-file=.env` | 310/310 tests passed | Authenticated staging journeys remain open |
| iOS profile build | Pass; 34.9 MB `Runner.app` | Development signing, not App Store distribution |
| Physical iPhone profile | Exact refreshed artifact installed on the paired iPhone 15 Pro Max | Automatic launch was denied because the phone was locked; final ambient-light review remains with the user |

The iOS build continues to warn that `device_calendar` and
`flutter_local_notifications` do not declare Swift Package Manager support.
The current CocoaPods build succeeds.
