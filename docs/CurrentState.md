# Workloop Current State

Last updated: 2026-08-12

## Completed / Mostly Working Features

### 2026-08-11 production identity, email and owned-domain cutover

- `workloop.uk` is registered to the owner and is now the canonical Workloop
  web, booking-page, legal and support origin. The previous `workloop.app`
  assumption is retired because that domain is owned by a third party.
- Google and native Apple sign-in are enabled in the hosted Supabase project.
  Google remains in OAuth testing mode for the owner account until the public
  consent-screen requirements and external beta cohort are ready.
- Resend verified `workloop.uk` in Ireland with isolated DKIM and SPF records.
  Supabase Auth uses an encrypted, sending-only API key scoped to that domain,
  sends as `auth@workloop.uk`, and delivered a real password-recovery message.
- Auth email capacity is 30 messages per hour and all seven security-change
  notifications are enabled. UK2 has email two-factor authentication and an
  independent recovery email. DMARC rejects unauthenticated apex and subdomain
  mail after the verified delivery path proved healthy.
- The public Sites deployment has active TLS on both the apex and `www` custom
  domains, and the canonical legal routes respond over HTTPS. Publishing the
  saved legal-contact update is the final web-content handoff.

### 2026-08-11 stable cold-start dashboard reveal

- A cold authenticated launch now keeps the intentional `Opening Workloop`
  state visible until the Today schedule and dashboard-attention calculation
  have either loaded or failed. The ready dashboard then enters with one short,
  reduced-motion-aware crossfade instead of briefly rendering an empty purple
  Today panel and allowing later sections to jump position.
- The opening gate latches after its first successful reveal. Pull-to-refresh,
  workspace refreshes, and provider refreshes keep the dashboard mounted and
  cannot replay the app-opening state.
- Finance and Notes visual fixtures now use explicit reference dates, removing
  day-boundary drift from the protected Money chart and note-date goldens.
- Analysis is clean and the complete Flutter suite passes 353/353 tests,
  including dedicated cold-start/reveal and refresh regression coverage.

### 2026-08-10 operating-loop navigation and Business workspace

- The primary shell now follows the owner's operating loop: Today, Clients,
  Work, Money, and Business. Money is one tap away rather than hidden in an
  overflow page, and the former Tools destination is no longer part of the
  user-facing shell.
- Work is one retained workspace with Schedule, Tasks, and Notes as peer views.
  Each view keeps its existing provider, editor, draft, filters, routes, and
  data contracts; the shared selector changes only information architecture.
- Business now leads with a computed Booking page status, public link, waiting
  request count, and one Manage booking page action. Services, Working hours,
  and Business profile follow as the customer-facing business essentials.
  Settings is reduced to a compact secondary header action.
- The former Tools quick-capture grid is not repeated in the new hierarchy.
  Each feature retains its own contextual `+` action, keeping creation close
  to the destination where the resulting record will live.
- Light and Dark protected visuals cover the five-item navigation, Work
  schedule hierarchy, and Business landing page. The complete Flutter suite
  passes 352/352 tests and analysis is clean. The iOS profile build succeeds at
  70.9 MB, installs on the paired physical iPhone, and launches successfully
  after the device was unlocked. This proves install and launch, not a full
  signed manual workflow or accessibility walkthrough.

### 2026-08-10 muted Dark mode and active-job orientation

- Bookings now prioritises operational work over view controls. Its header copy
  stays on one line and root gaps are tighter. Today, Upcoming, Past and
  Calendar now form one full-width navigation rail; the redundant List label
  and second control are removed. The low-action seven-day load graphic and
  full-width Schedule/Requests switch remain absent, bringing the first booking
  materially higher in the initial viewport. Booking requests remain visibly
  owned by Bookings through a counted inbox action that opens the dedicated
  Active/New/Closed request workspace.
- Calendar mode now uses fixed-height date cells and places the selected-day
  agenda directly beneath the month grid. Calendar and Schedule now render the
  same shared booking-record row: start and end time, slim status marker,
  client, service/location, price, state metadata and divider rhythm. Calendar
  retains its continuous time rail; Schedule retains its time filters and
  grouping.
- Notes now renders pinned and dated collections as flat divider-led rows
  rather than individual rounded cards. Search, filters, imports, editor flows,
  linked-client context and deletion safety are unchanged.
- Dark appearance now uses neutral graphite and slate canvas layers instead of
  violet-tinted surfaces. Periwinkle remains a controlled action, focus and
  selection signal; it no longer colours the entire atmosphere of the app.
- Home's Dark hero uses a deep desaturated indigo field with high-contrast
  white hierarchy. The surrounding backdrop texture is quieter, while cards,
  dividers and secondary copy separate more clearly from the canvas.
- The Home schedule path now distinguishes the current-time tick from the
  selected booking. The selected booking has a larger halo and travels to the
  next booking position with a restrained 280 ms settling bounce when the
  owner swipes the Today carousel. Reduced Motion jumps directly to the stable
  selected state.
- Verification passes formatting across 208 Dart files, clean analysis,
  347/347 Flutter tests, 25/25 Deno tests, the responsive/text-scale checks and
  25/25 protected golden scenarios. Fresh profile builds pass for iOS (70.3
  MB) and universal Android (156.7 MB). The signed build was installed and
  launched on the paired iPhone; the final Notes-list revision was subsequently
  installed and CoreDevice confirmed PID 84974. This proves
  install and launch, not a completed interactive accessibility walkthrough.

### 2026-08-08 command-centre UI polish

- Home keeps the purple Today command panel, while its supporting content is
  calmer and easier to scan. Worth-a-look and feed rows have consistent icon
  insets, Business feed is promoted above Coming up, and Money, Tasks and Notes
  share one divider-led At a glance workspace.
- The Money summary uses real paid-this-month and monthly-target values in a
  compact progress dial. It intentionally lives in At a glance rather than the
  Today panel so financial context does not compete with the owner's immediate
  daily action.
- Bookings now labels its List and Calendar view choice instead of placing a
  detached calendar icon beside Today, Upcoming and Past. The control adapts on
  narrow phones, calendar-to-agenda spacing is reduced, and booking and request
  results render as lists rather than repeated cards.
- Clients also uses a divider-led list. Tools groups Money, Tasks and Notes in
  the same shared row language as Home, without the previous nested border.
- Shared navigation, segmented controls, buttons and selected states use softer
  corner geometry. List-row defaults and explicit legacy call sites provide a
  consistent 18-point horizontal inset so icons no longer touch card edges.
- Verification passes formatting across 208 Dart files, clean analysis,
  347/347 Flutter tests, 25/25 Deno tests and 25/25 protected golden scenarios.
  Fresh profile builds pass for iOS (70.3 MB) and universal Android (156.7 MB).
  The signed candidate was installed and launched on the paired iPhone;
  CoreDevice confirmed the live process as PID 78739. This proves install and
  launch, not a completed interactive or assistive-technology walkthrough.

### 2026-08-08 completion evidence and staging-E2E harness

- Tools now presents Money, Tasks and Notes as one calm, consistent workspace
  group rather than three competing nested colour cards. Module colour is
  limited to useful icon signals; spacing, dividers, typography and tap targets
  follow the shared Workloop surface and list-row system.
- The reviewed visual baseline now includes populated Money, Tasks, Notes,
  booking-request inbox/detail and Profile states. The protected golden suite
  passes 25/25 tests and covers 29 image files in Light/Dark where relevant.
- Three production-safe staging journeys are now implemented: the connected
  client-to-booking-to-work-to-payment/export loop, two-account SDK isolation,
  and signed-out public booking idempotency/owner conversion. They refuse to
  write unless explicit staging credentials and `E2E_ALLOW_WRITES=true` are
  supplied; the runner also rejects the production project URL.
- The complete local suite passes formatting, clean Flutter analysis, 346/346
  Flutter tests, 25/25 Deno tests and deterministic data profiles. The iOS
  simulator launch/Auth journey passes; all three staging journeys compile and
  are safely skipped without staging configuration.
- Fresh profile builds pass for iOS (70.2 MB) and universal Android (156.6 MB).
  The exact iOS profile candidate was subsequently installed and launched on
  the paired iPhone over wireless deployment; CoreDevice confirmed its live
  process as PID 78555. Flutter's wireless Dart VM service did not reconnect,
  so this proves install/launch rather than interactive workflow QA.
- Executing the new write-capable journeys remains gated on approval for a
  disposable Supabase branch at the quoted $0.01344/hour plus two disposable
  accounts. Production data will not be used for destructive or isolation QA.

### 2026-08-08 final completion and release-candidate sweep

- The unfinished recurring-series control is no longer exposed in New booking.
  V1 creates one booking at a time until series editing, exception handling and
  series-level conflict recovery can be completed safely. Existing recurrence
  fields, payload support and read-only labels remain compatible so historic
  records are not rewritten or hidden.
- Current verification passes formatting across 205 Dart files, clean Flutter
  analysis, 340/340 Flutter tests, 49.68% line coverage, 19/19 protected golden
  tests covering 23 image files, and the signed-out iOS simulator journey 1/1.
- Edge verification passes formatting and lint, all eight checked entry points,
  and 25/25 Deno tests. The four deterministic data profiles pass in dry-run
  mode. No migration or Edge deployment was changed during this sweep.
- Profile builds pass for iOS (70.7 MB), universal Android (155.6 MB), Android
  arm64 (129.4 MB), and web release (43 MB). The arm64 APK passes 16 KB
  alignment and v2 signature checks; the iOS app passes strict code-signature
  verification.
- The exact iOS candidate installed and launched on the paired iPhone 15 Pro
  Max after an initial locked-device denial. CoreDevice confirmed the running
  process. This proves install/launch, not a completed interactive workflow or
  assistive-technology pass.
- Read-only live Supabase inspection reports an active healthy Postgres 17.6.1
  project. All 23 public and all four private application tables have RLS;
  anonymous application-table grants are zero; private tables have no client
  grants; and `account_deletion_audit` remains the only public table without an
  authenticated client grant. The sole security-advisor warning remains leaked
  password protection. Clean local replay and pgTAP remain unexecuted because
  this machine has no Docker engine.

### 2026-08-07 app-wide uniformity, booking browse and data graphics

- Root workspaces now use one 18-point page inset, 12-point safe-area top
  inset, 20-point header-to-control gap and 24-point major-section rhythm.
  Clients no longer double-applies its horizontal inset, and Clients, Bookings
  and Money no longer place their page headers inside competing tinted cards.
- Every two-to-four option peer control now resolves through the same shared
  navigation renderer. Bookings Today/Upcoming/Past intentionally no longer
  looks like a separate control family from List/Calendar, Tasks, Notes or
  Money.
- Home's Today booking is a horizontal carousel when multiple bookings remain.
  It exposes booking position, a next-card preview, haptic page changes and an
  accessible swipe instruction while preserving direct booking actions.
- Money adds a compact cash-movement strip calculated from paid records in the
  selected period. Bookings intentionally avoids a second schedule summary and
  leads directly into its actionable list or calendar.
- The launch wordmark assets are transparent on one native `#6362EB`
  background, removing the differently rendered purple square while retaining
  the supplied solid-purple app icon.
- Verification passes clean analysis, 337/337 Flutter tests, 17/17 protected
  golden scenarios after visual review, `git diff --check`, a 70.7 MB iOS
  profile build and a 155.6 MB Android profile APK. The exact iOS artifact was
  installed and launched on the paired iPhone 15 Pro Max; CoreDevice confirmed
  launch before its intermittent device tunnel dropped again.

### 2026-08-06 Studio composition and native-brand refinement

- The approved purple Home command panel remains the defining Home moment but
  is materially tighter: greeting utilities adapt at compact widths and large
  text, the daily card uses explicit on-hero contrast roles, and the schedule,
  supporting copy and action have a more compact rhythm.
- Root and retained shell workspaces now share one calculated bottom-clearance
  contract: 72-point dock + 12-point offset + the real device bottom safe area
  + 22 points of breathing room. Home, Clients, Bookings, Tools, Money, Tasks
  and Notes no longer rely on a fixed device-specific padding guess.
- Home's accumulated double section gaps are removed. Bookings has a shorter
  header, a quieter compact time filter, a counted request inbox and an inset
  booking time rail.
- The supplied `W` artwork is now the complete iOS and Android launcher-icon
  set. The supplied `workloop` artwork is the native launch image, with its
  exact `#6362EB` background used on both platforms to avoid a visible seam.
- Verification passes clean analysis, 336/336 Flutter tests, 17/17 protected
  goldens after manual review, the full six-device Light/Dark and 100%/200%
  text matrix, a 70.7 MB iOS profile build and a 155.6 MB Android profile APK.
  The exact iOS build is installed and running on the paired iPhone 15 Pro Max
  with CoreDevice process confirmation.

### 2026-08-06 Workloop Studio complete visual reset

- Workloop Studio supersedes Loopline and the previous lime/graphite identity.
  The active system uses a porcelain `#F6F4EF` Light canvas, midnight
  `#10131E` Dark canvas, confident indigo actions, relationship teal, selective
  module signals and bundled Manrope Variable typography.
- The reset is structural rather than token-only: Home has a deep indigo daily
  command composition; Clients has an integrated relationship/search header;
  Bookings is timeline-led; Money uses outcome cards and a real target arc;
  Tools has expressive live module launchers; Auth and onboarding use the
  operating-loop graphic; Settings and Notifications use calm grouped/list
  hierarchies.
- The root shell is again a floating four-destination dock, but with a compact
  contained active state rather than the previous glass pill or edge bar.
  Shared buttons, fields, lists, headers, navigation rails, sheets, empty
  states, motion, shadows and backdrop drawing now come from one central Studio
  system.
- Notifications remains one chronological list with Today/Earlier anchors and
  no redundant All/Unread sections. Purposeful graphics use native Flutter
  drawing and real or explanatory state; no decorative analytics or invented
  business data were introduced.
- Native startup backgrounds now use Studio indigo and no longer flash the
  retired lime launch artwork. Routes, retained workspaces, native back
  behaviour, draft guards, providers, repositories, Supabase contracts and
  operational workflows are unchanged.
- Verification passes `flutter analyze`, 334/334 Flutter tests, 17/17 golden
  scenarios with 21 manually inspected images, the complete phone/text-scale
  matrix, a 70.7 MB iOS profile build and a 155.5 MB Android profile APK. The
  exact iOS artifact is installed and launched on the paired iPhone 15 Pro Max,
  with the running process confirmed through CoreDevice.

### 2026-08-06 Loopline app-wide UI reset

- Workloop now uses one coherent geometry system across every shared control:
  soft-square functional controls, circular icon utilities, status-only
  capsules, line-led peer navigation and a docked edge-to-edge bottom bar.
- Light has a new mineral `#F4F5F2` canvas, stronger white/neutral layer
  separation and ink primary actions. Dark keeps its established graphite and
  lime personality.
- The floating pill dock, selected navigation plates, pill segmented rails,
  `StadiumBorder`, literal `999` control radii and the legacy pill radius have
  been removed. A source contract prevents them returning.
- Auth is open and wordmark-led, Home uses one restrained real schedule focus,
  Tools uses a flat capture grid, Settings is fully list-led, Client portfolio
  and client workspace navigation share the line system, and public-profile
  sections no longer stack generic cards.
- Existing routes, retained workspaces, native back behaviour, draft guards,
  providers, repositories, Supabase contracts and operational workflows remain
  unchanged.
- Verification is clean: `flutter analyze`, 334/334 Flutter tests, 17/17
  protected golden tests, the complete phone/text-scale matrix,
  `git diff --check`, and the 70.7 MB iOS profile build all pass. The paired
  iPhone is currently reported offline by CoreDevice despite the saved pairing,
  so install and interactive launch remain a separate device-state check.

### 2026-08-06 soft-editorial UI replacement

- The rejected graphite-frame direction has been superseded. Light is now an
  open `#F7F7F4` canvas with white content surfaces, quiet neutral controls,
  crisp ink typography, and no large black structural panels.
- Root and route headers are typographic rather than logo-led, section chrome
  is reduced, and the floating four-destination dock uses a light neutral rail,
  a quiet active surface, visible labels, and a small lime position marker.
- Home, Money, Tools, Auth, onboarding, public profile, filters, empty states,
  forms, notifications, and settings share the softer system. The real daily
  schedule path and onboarding operating loop remain the purposeful graphics;
  no decorative analytics or invented data were added.
- Dark keeps its established lifted graphite palette but replaces harsh inner
  black frames and bright white selected plates with quieter semantic layers.
- Routes, navigation behaviour, state retention, Riverpod providers,
  repositories, Supabase contracts, and durable workflows remain unchanged.
- Verification is clean: `flutter analyze`, 333/333 Flutter tests, 17/17
  protected golden tests with 21 manually reviewed images, the full primary
  and secondary responsive matrices, a 70.7 MB iOS profile build, and a
  155.4 MB Android profile APK. No physical iPhone was connected for this pass.

### 2026-08-05 graphite-frame UI revamp

- Workloop now has a visibly new app-wide interface rather than a token-only
  refinement: a shared graphite frame, lime signal, two-line operating-loop
  mark, editorial header rules, square action geometry, and a cool-chalk Light
  canvas connect the application.
- The floating shell navigation is graphite in both appearances, keeps all four
  destination labels visible, and uses a lime active plate. Peer navigation and
  compact segmented controls follow the same hierarchy without changing any
  destination, route, retained state, or back behaviour.
- Home's real schedule path and Money's real period total use strong graphite
  focus panels. Tools has a dedicated quick-capture command panel. Auth,
  onboarding, public profile, search, empty states, settings, notifications,
  and pushed-route headers share the new graphic language.
- Light uses `#F3F4F0` chalk, `#FCFDF9` content surfaces, stronger neutral
  interaction layers, and the same graphite anchors as Dark. No invented
  charts, analytics, packages, providers, repositories, schema, or workflow
  changes were introduced.
- Verification is clean: `flutter analyze`, 332/332 Flutter tests, 16/16
  protected golden tests with 19 reviewed images, the full primary and
  secondary responsive matrices, a 70.7 MB iOS profile build, and a 155.4 MB
  Android profile APK. The exact iOS artifact installed on the paired iPhone;
  automatic launch was denied only because the phone was locked.

### 2026-08-05 free launch-hardening sweep

- Home now exposes the notification inbox with an unread count, includes real
  pending booking requests in its attention queue, and routes client follow-up
  prompts to the exact client. The retired `pending`/`unconfirmed` appointment
  assumption is gone; active clients without activity for 42 days become calm
  follow-up prompts unless they already have an upcoming booking.
- Home Money, Coming up, Recent activity, and Business settings failures now
  remain honest and retryable. Money date/mode/payment-row interactions use
  labelled 44-point controls, and deleting income is discoverable without a
  hidden long press.
- Business Feed now starts concurrent, date-bounded and row-limited repository
  reads instead of materialising every feature table. The booking look-ahead is
  bounded to 90 days / 80 rows, which is an intentional dense-workspace limit.
- Sign-up, recovery, and in-app password changes share a 12-character minimum.
  This reduces weak-password risk but does not replace Supabase breached-
  password protection.
- Stripe payment-link, Terminal, refund, and webhook retries retain a stable
  operation key. Failed and stale webhook deliveries are reclaimable; completed
  events remain final; refund reconciliation is computed from succeeded rows.
- Live test-mode Supabase now contains migrations
  `20260805210418_harden_stripe_retries_and_private_rls` and
  `20260805210559_document_private_ledger_deny_policies`.
  `stripe-payments` v2 and `stripe-webhook` v2 are active. Client roles have no
  private-ledger DML, the security advisor reports only the paid leaked-password
  warning, and unsigned/unauthenticated smoke requests are rejected.
- Combined evidence: clean formatting and analysis; 324/324 Flutter tests;
  14/14 reviewed goldens; 25/25 Deno tests; 47.15% line coverage; live
  transaction-wrapped 47-assertion schema and 14-assertion tenant-isolation
  scripts; 70.7 MB iOS, 155.0 MB universal Android, and 69.9 MB arm64 Android
  profile builds; APK alignment and signature checks; physical iPhone install
  and CoreDevice launch.
- No live Stripe key, platform fee, Apple proximity-reader entitlement, paid
  Supabase control, store signing, or public legal/support service was enabled.

### 2026-08-05 editorial UI sweep

- Shared typography, spacing, radii, fields, buttons, navigation, surfaces, and
  list rows are denser across the entire app while retaining 44-point minimum
  interaction targets.
- Light now uses a crisp `#F7F7F4` canvas, pure-white surfaces, neutral grey
  hierarchy, and restrained lime. Dark retains its established graphite and
  lime colour personality with the same more compact geometry.
- Notifications are one chronological divider-led list. Unread state uses a
  small lime dot and stronger title weight; redundant All and Unread sections
  are removed.
- Home's daily-focus surface includes a native schedule path based on the real
  current time and remaining booking positions. Existing Money target and
  category visuals remain the purposeful reporting layer; no invented trends
  or analytics were added.
- Tools quick capture is tighter and its Money, Tasks, and Notes destinations
  now use list rhythm instead of three large cards.
- Verification is clean: `flutter analyze`, 325/325 Flutter tests, the 15/15
  golden suite (18 reviewed images), the full responsive appearance matrix, and
  a 70.7 MB iOS profile build all passed. The exact app installed on the paired
  iPhone 15 Pro Max; automatic launch was denied because the development profile
  is not currently trusted on the device, so interactive phone review remains
  open.

### 2026-08-05 final visual-system acceptance pass

- The final route inventory covered authentication, recovery, onboarding,
  Home, Clients, Bookings, Money, Tasks, Notes, Tools, Business Feed,
  Notifications, Profile, Settings, calendar/import tools, legal/support,
  public profile, booking requests, and the main create/edit flows.
- Page-level content, onboarding steps, secondary workspaces, public surfaces,
  and modal forms now share the canonical 18-point horizontal grid. Existing
  routes, repositories, providers, Supabase contracts, retained state, and
  draft safeguards are unchanged.
- Feature selection, keyboard, calendar, client workspace, progress, sheet
  cleanup, and expand/collapse animations now honour reduced-motion settings.
  A source contract prevents raw feature colours, weights above 600, and
  unguarded canonical motion durations from reappearing.
- Onboarding now contains one restrained Flutter-native operating-loop visual:
  Client to Booking to Work to Payment to Repeat. It is orientation, not
  analytics, and remains semantic and scrollable at 200% text.
- Final evidence: clean analysis; 331/331 Flutter tests; 16/16 golden tests with
  19 reviewed images; the six-device primary responsive matrix plus an
  18-combination secondary-route Light/Dark, 200%-text, reduced-motion matrix;
  70.7 MB iOS and 129.4 MB Android profile builds; exact iOS artifact installed
  and launched on the unlocked paired iPhone 15 Pro Max with the Workloop
  process confirmed running.
- Manual VoiceOver/TalkBack traversal, a physical Android run, authenticated
  staging journeys, and store-distribution signing remain release QA rather
  than visual-system implementation gaps.

### 2026-07-31 appearance and Tools workflow pass

- Workloop supports persisted System, Light, and Dark appearances from a
  dedicated Settings destination. System follows the phone; manual choices
  apply immediately and survive relaunch.
- Light uses a low-glare warm-stone `#EEEDE8` canvas, ivory content surfaces,
  neutral grey interaction layers, dark operational text, and the exact
  `#C1FF72` neon only for confident fills and selected states. Accent-filled
  controls have a quiet one-pixel sage edge; neutral cards stay neutral. Dark
  retains the existing lifted graphite palette.
- Legacy screen colours now resolve through the effective appearance while
  current shared components continue to use semantic tokens. Native iOS and
  Android startup configuration no longer forces Dark when the system is Light.
- Tools now leads with Record money, New task, and New note capture actions.
  These open the existing canonical creation flows directly, while the three
  workspace rows retain equal hierarchy and add live money/task/note context.
- Theme tests protect text, status, module-icon, focus, button, navigation, and
  disabled-state contrast in both appearances. The responsive launch matrix
  now renders Light and Dark across six phone sizes and two text scales.

### 2026-07-30 visual hierarchy and daily-focus pass

- Root workspaces now separate three attention levels: one semantic primary
  create action, one contextual focus area where the feature needs it, and
  quieter filters/content. Clients, Bookings, Money, Tasks, and Notes use a
  visible `+` with a feature-specific accessibility label.
- Home now leads with a state-driven daily-focus surface for an in-progress
  booking, the next booking today, or a clear day. The greeting is quieter,
  the focus action is explicit, and in-progress bookings remain visible until
  their end time.
- Dashboard attention uses the existing actionable copy and prioritises an
  imminent unconfirmed booking, then overdue work, overdue payment follow-up,
  and stale leads. Task and note shortcuts show live counts when available.
- Bookings is schedule-first. Today/Upcoming/Past/Calendar use one quiet
  graphite navigation rail, while the counted request inbox opens the
  dedicated triage workspace. Client, task, note, and other filter states use
  the same subordinate hierarchy.
- Shared section headings now form visible sentence-case divisions; dense
  chronological groups use a quiet variant. Empty states are inline by default
  so whitespace and typography carry hierarchy without another bordered card.
- Booking completion/cancellation decisions sit directly below the booking
  hero and time context rather than after every disclosure. Public profiles
  expose a prominent booking-request action beside the business proposition.
- Tools replaces the generic More label and presents Money, Tasks, and Notes as
  three equal full-width workspace rows. Profile and Settings move to compact
  direct controls beside the Home greeting.
- Root empty states no longer repeat the same neon create action already
  present in the header. Imports remain available as quiet secondary paths.
- Bookings keeps Today/Upcoming/Past/Calendar in one compact rail. Requests use
  a counted header inbox rather than consuming a full-width workspace decision.
- Pushed detail, editor, import, support, legal, calendar, task, note, client,
  booking, income, and expense screens now share `WorkloopRouteHeader`.
- Settings makes the identity surface the Account destination, Profile removes
  duplicated snapshot links, Booking Requests uses Active/New/Closed, and
  import screens use one route title instead of competing headlines.

### Final application foundation

- Workloop ships coordinated System, Light, and Dark appearances. Dark uses the
  lifted `#151A16` graphite canvas; Light uses cool `#F3F4F0` chalk. The
  exact icon and launch-artwork neon `#C1FF72` remains the restrained brand
  accent, with dark `#17200D` content on neon fills and tested contrast pairs.
- Instrument Sans is bundled with its licence so launch typography does not
  depend on a runtime font download. The app-wide weight scale is capped at
  semibold, with regular-weight body copy for a calmer, more minimal hierarchy.
- A shared, restrained textured backdrop now connects the main application, onboarding, profile, settings, support, calendar tools, notifications, and import flows.
- Shared fields, search, pickers, sheets, dialogs, buttons, switches, haptics, motion, loading, empty, error, and success states form the canonical interaction system.
- A resumable onboarding preferences step, real-record dashboard setup checklist, and action-led empty states guide first value without inserting demo data.
- Privacy-first import supports selected contacts, one-time calendar events, client CSV, task text, and note text/Markdown. Partial attempts retain only failed records for retry so already-created records are not duplicated. Unsupported private stores are labelled honestly.
- In-app notifications and on-device task/booking reminders are supported on iOS and Android. Task reminders follow the selected timing; opted-in booking reminders are scheduled about 15 minutes before the booking. Tapping a reminder routes back into Workloop. Remote APNs/FCM push delivery is not claimed.
- See `docs/LaunchReadiness.md` for the current release gate. `docs/FinalPolishAudit.md` remains a historical snapshot of the earlier July polish pass.

### 2026-07-28 final UI/UX refinement

- The four-destination shell remains Home, Clients, Bookings, and Tools. Root
  screens keep one measured header grid, while pushed Profile, Settings, and
  Notifications routes now use one responsive route-header primitive.
- Bookings now opens directly into the schedule, separates display controls
  (List and Calendar) from time filters, and exposes Booking Requests through
  a compact counted inbox action. The next booking is not repeated in list
  mode, and failed schedule/request loads offer a specific retry in their
  respective workspaces.
- Booking creation and request conversion retain entered context through
  recoverable failures. Public requests use persistent labels and inline
  validation; conversion keeps its sheet and draft open, checks conflicts and
  working hours, and reports the exact recovery action. Booking-to-client
  navigation resolves the canonical client instead of constructing a partial
  record.
- Money renders each operating section from its own provider state, so a
  target, invoice, or expense failure does not hide unrelated financial
  information. Tasks, Business Feed, Notifications, deletion, onboarding
  handle checks, and calendar import now expose bounded retry paths.
- Calendar imports use the same validated, atomic, idempotent booking workflow
  as manual creation. Failed events remain selected with their exact reason.
- Bottom navigation and Tools launchers expose invokable semantic actions;
  checklist controls keep a compact appearance with 44-point targets; success
  and error feedback use live regions where appropriate; reduced-motion and
  large-text layouts are protected by responsive tests.
- Final local UI evidence: formatting is clean, Flutter analysis reports no
  issues, all 285 Flutter tests pass, the 11-test golden suite passes in
  non-update mode, iOS and Android profile artifacts compile, and the current
  iOS profile launched on the physical iPhone with a Dart VM Service and a
  confirmed running process. Manual VoiceOver, TalkBack, permission, offline,
  lifecycle, and physical Android coverage remain launch gates.

### 2026-07-28 dark-only usability and edge-case pass

- System and Light appearance selection, persisted theme preference logic, and
  the Settings appearance destination were removed. Native iOS and Android
  launch windows now use the same graphite background, preventing a white
  startup flash before Flutter paints.
- The responsive matrix now renders 11 launch surfaces across six phone
  viewports and two text scales: 132 combinations plus keyboard reachability.
  Settings and the booking-request inbox are included.
- A booking-request empty state that overflowed by 337 logical pixels on a
  320x568 phone at 200% text now scrolls and remains centred when space allows.
- Dark-only theme contracts, native startup colour, Settings ownership, and
  feature-action geometry are protected by targeted regression tests.
- The focused usability suite passes 86/86 tests, the full Flutter suite passes
  280/280, formatting and static analysis are clean, and iOS/Android profile
  builds pass. The signed-out simulator integration journey passes and the
  physical iPhone profile exposed a Dart VM Service with a confirmed running
  process.

### Auth

- Email/password sign up.
- Email/password sign in.
- Sign out.
- Password update from settings.
- Password recovery through the `workloop://reset-password` deep link, subject to the production Supabase redirect and email-delivery configuration.
- Session-based auth gate.
- Workspace gate.

### Onboarding

- Multi-step onboarding.
- Captures business profile basics.
- Persists the owner's preferred first name in Supabase Auth metadata for personalised app greetings.
- Captures public handle.
- Captures services.
- Captures working hours, including split working blocks with breaks.
- Captures monthly revenue target, used as weekly finance target.
- Optional first booking.
- Creates workspace, member, settings, business profile, services, and first booking.

### Navigation

- GoRouter top-level routes.
- Main shell with a docked four-item bottom system bar: Home, Clients,
  Bookings, Tools.
- Tools presents Money, Tasks, and Notes as equal, full-width operating
  workspaces with live orientation text, plus direct Record money, New task,
  and New note capture. Profile and Settings are direct secondary controls in
  the Home header rather than content sections in the daily dashboard.
- Clients, Bookings, Money, Tasks, and Notes expose the same circular `+`
  create action in each feature header, with the specific action retained as
  its accessibility label. Money opens a two-choice sheet for income or expense
  instead of mixing unrelated controls.
- Shell headers share one safe-area top grid, header type treatment, 24-point
  header-to-content rhythm, and bottom-navigation clearance.
- Tasks, Notes, Work/Bookings, and Payments routes can deep-link to their shell
  screens while Tools remains the active navigation destination for secondary
  modules.
- Business Feed route opens from Home without adding a bottom navigation tab.
- Tapping outside an active text field dismisses the keyboard consistently across every route while taps within the field keep editing active.
- Tapping the native iOS status bar or the app's top edge returns the visible
  vertical screen to its beginning. Every vertical scroll view is discovered
  centrally, including implicit and nested controllers. Render visibility and
  hit testing exclude hidden PageView/TabBarView children. One tap across the
  non-interactive top/header zone resets every visible vertical layer with a
  distance-aware animation while leaving header buttons to perform only their
  own actions. Home, Clients, Bookings, Money, Tasks, Notes, and Tools retain
  independent scroll targets rather than resetting an offstage tab.
- Clean pushed routes retain native iOS interactive back swipes and Android
  system back gestures, including finger-tracked reveal and cancellation. A
  route-aware fallback is reserved for direct routes and draft-protected
  editors; it acts only after pointer-up and still invokes the same
  Save/Discard/Keep editing decision. Reminder navigation pushes onto the
  current history instead of replacing it.
- Money, Tasks, and Notes also retain the shell workspace that launched them.
  Their iOS back swipe now moves with the finger, reveals that workspace with
  Cupertino-style parallax, and can be cancelled before returning—normally to
  Tools, or Home when Money was opened from a Home follow-up.
- Every programmatic shell destination change now uses the same restrained
  240ms fade-through and directional offset. This covers Home, Clients,
  Bookings, Tools, and forward entry into Money, Tasks, and Notes while
  preserving each destination's mounted state and scroll position. Reduced
  motion switches immediately. Retained destinations keep a stable keyed layer
  through every animation phase, and Tools create requests are cleared after
  their first delivery so Money, Task, or Note creation cannot replay later.
- Clients gives the top shortcut precedence over a tappable client row occupying
  the top zone after scrolling. Filter changes remain explicit through the
  visible filter rail rather than a competing full-screen horizontal gesture.

### Dashboard

- Calm daily overview ordered around Today, Worth a look, Money, quick access,
  Coming up, and Recent activity.
- Today is the single focal surface. It distinguishes an in-progress booking,
  the next booking, and a clear day, then exposes one explicit action.
- Time-aware personalised greeting includes the current date.
- Today keeps an in-progress booking visible until its end time and adds a quiet
  count of later bookings; Coming up excludes today and is capped at three rows.
- Worth a look is optional, capped at two rows, and keeps direct action-led copy
  without alarm-heavy colour.
- Money is a compact received-this-month row rather than a dominant hero card.
- Tasks and Notes use two small, low-contrast utility cards with live counts so
  they read separately from Money without adding visual noise.
- Recent activity is capped at three calm items and excludes attention/overdue/unpaid warning states.
- Dashboard rows and section actions open the related booking detail or owning feature.
- Pull-to-refresh.
- Navigation callbacks into core modules.

### Business Feed

- Computed feed generated from existing bookings, clients, payments, expenses, tasks, notes, booking requests, and weekly target progress.
- Feed item types include today's bookings, upcoming bookings, payment received, unpaid/overdue invoices, expenses, due/overdue tasks, notes, client follow-ups, booking requests, quiet-day detection, daily summary, and weekly target progress.
- Home preview appears inside Daily Command with a View all action.
- Full Business Feed screen includes All, Needs attention, Money, Bookings, Tasks, and Clients filters.
- Feed row taps route to the most useful existing module or booking request screen where exact detail routes do not yet exist.
- No persisted feed table or AI dependency has been introduced.

### Clients / CRM

- Calm, whitespace-first client list aligned with the dashboard's title scale, top spacing, paper-like backdrop, text hierarchy, and continuous divider-led rows.
- Client sorting supports Next booking, A–Z, Recently booked, Recently added, and Most booked without additional database queries.
- Client sorting is presented as a compact single-line choice menu with a quiet selected state rather than a second list of full record-style rows.
- Search across client names, contact details, and tags, with line-led
  All/Active/Leads/Inactive views that can be changed by tapping or dragging
  across the selector.
- Active and Inactive remain distinct status views; inactive contacts also carry a quiet neutral label inside All.
- Changing client views returns the portfolio to the top, and each empty category has calm, contextual guidance.
- Add and Edit client use one canonical form with the dashboard/client textured shell, shared field styling, and identical Contact information, Client settings, Booking address, Client notes, and Additional information sections.
- The shared Booking address field supports debounced UK Google Places autocomplete through an authenticated Supabase Edge Function, suggestions that remain visible while the surrounding form is repositioned, and an independently scrollable and explicitly dismissible result list. It deliberately stays as one field: users start with the first line of an address for suggestions, or keep any manually typed value such as a postcode. Building-level matches preserve typed flat/unit labels, selection remains immediate with manual fallback, and the Google key stays out of the mobile app.
- Saved client booking addresses open driving directions in Apple Maps or Google Maps. Users can choose per launch, remember a choice from the directions sheet, or change the device-level default under App settings.
- Client entry validates optional email addresses, explains relationship statuses, warns when the selected contact channel has no matching detail, and blocks duplicate phone/email records before saving.
- Lead source, tags, and birthday remain progressively disclosed; destructive deletion stays separate from Save, and backing out of an edited client offers to preserve or discard the draft.
- Delete client with confirmation.
- Client workspace with a compact relationship header, call/email actions, textured backdrop, and draggable Overview/Bookings/Money/Tasks navigation aligned with the app shell.
- Notes and important notes.
- Status/source/tags/birthday/preferred contact method fields.
- Client overview prioritises the next booking, a restrained relationship snapshot, calm follow-up rows, useful context, and three recent activities rather than repeating full module histories.
- Client booking history is repository-backed, opens canonical booking details, and creates bookings with the client preselected.
- Client payment history is repository-backed, supports direct recording/editing, and distinguishes received, remaining, paid, part-paid, and unpaid amounts without alarm styling.
- Client task history uses the shared task repository and contact relationship, invalidates the main Tasks state, and links directly to the full Tasks workspace.

### Bookings

- User-facing Bookings built on `appointments`.
- Calm schedule-first workspace using the same textured backdrop, typography,
  spacing, controls, and feature-header action as Home and Clients. A counted
  inbox opens the dedicated Booking Requests workspace.
- List mode with Today / Upcoming / Past views and direct booking rows.
- Calendar mode uses an open Apple-inspired month grid with swipe and button
  navigation, a Today shortcut, clear selected/today circles, booking-density
  dots, and a selected-day time-rail agenda. Adding from the agenda continues
  to hand the selected date into the canonical New booking flow.
- Add and inline Edit booking forms share the client form visual language, keyboard dismissal, calm input surfaces, and progressive booking sections.
- Change date/time/duration/service/price/client/location/notes/status.
- Business/client/online location choices; physical locations use the shared Google Places address search and can reuse the selected client's saved booking address.
- Saved physical booking locations open directions using the shared Apple Maps / Google Maps device preference.
- Booking creation is routed through an authenticated, atomic, idempotent workflow that validates workspace relationships, serialises conflict checks, and can create an inline client, a linked payment, a follow-up task, request status, and in-app notification without exposing a partially-created workflow. Recurrence payload compatibility remains in the data layer, but series creation is not exposed in the V1 UI.
- Booking completion and its linked payment/notification handling use a separate atomic, idempotent workflow.
- Inline client creation in new booking.
- Custom service name, duration, and price.
- Working-hours exceptions show a calm confirmation and remain bookable by choice; real appointment conflicts remain blocked.
- New and edited clients and bookings protect changed drafts with Save, Discard, and Keep editing choices before leaving.
- Linked tasks in booking detail.
- Booking status controls: scheduled, completed, cancelled/no-show style workflows.
- Explicit calendar-event import and a point-in-time `.ics` file export. Workloop does not represent this as live or two-way calendar sync.
- Dashboard and client booking rows continue to open the canonical booking detail; booking detail links back to the canonical client workspace and shared Money and Tasks records.

### Tasks

- Calm Now/Later/Done workspace with Overdue, Today, Anytime, and future sections.
- Task rows open a dedicated detail screen while preserving deliberate completion actions.
- Add and Edit task use a full-screen form aligned with Client and Booking creation, including progressive options and Save/Discard/Keep editing protection.
- Delete task.
- Reopen task.
- Deliberate completion.
- Priority.
- Due date shortcuts/custom date.
- Reminder timing.
- Client and booking linking.
- Quick task templates.
- New task and initial checklist creation is one authenticated, atomic, idempotent workflow.
- Checklist item creation, editing, toggling, deletion.
- Real on-device reminders with permission-aware validation and safe reconciliation on app resume.
- Client task rows no longer complete instantly.

### Notes

- Calm searchable notes workspace with All, Pinned, Clients, and Bookings filters.
- Full-screen note editor aligned with the shared textured app shell and page hierarchy.
- First line acts as the note title while the remaining text supports paragraphs, checklists, and bullets.
- Pin remains a visible editor action; delete sits behind a secondary actions menu and retains confirmation.
- Compact labelled checklist and bullet controls remain available above the keyboard and preserve layout stability.

### Profile

- Business profile is a dedicated business-identity overview instead of an alias for the Business settings tab.
- The identity area stays business-focused and uses the shared textured workspace shell and Workloop typography. Personal account controls live only in Settings.
- Business details, Services, and Working hours use dedicated Profile-owned screens while reusing the established repositories and save logic.
- Public link setup, preview, sharing, readiness and booking-request access now live in the separate Booking page hub so owner identity and customer acquisition are not mixed together.
- Booking requests retain one canonical compact, filterable inbox. Each request opens a focused detail screen for calling, marking contacted, declining, or converting into a booking.
- Settings is intentionally separate and contains Account, Notifications, and
  App preferences. Appearance is a dedicated Settings destination rather than
  being mixed into general app connections.

### Money

- User-facing Money built partly on `invoices`.
- Calm three-section Money workspace aligned with Home, Clients, and Bookings: plain-language Made / Spent / Owed navigation, one primary figure per section, period controls for Made and Spent, period-aware target progress, category summaries, and one divider-led owed list.
- Compact top actions create income or expense entries without a floating action button.
- Record payment.
- Edit payment.
- Mark payment as received.
- Delete payment.
- Paid/unpaid tracking.
- Overdue refresh logic.
- Add expense.
- Edit expense.
- Delete expense.
- Expense category summary.
- Week/month/custom period switcher.
- Weekly target progress.
- Weekly/monthly target editing from Money.
- Comparisons vs last week/month/custom period foundation.
- Paid/unpaid/expenses/profit summary.
- Booking-linked payment rows through `appointment_id`.
- Supabase-backed `expenses` table with RLS.
- Add/Edit Income and Add/Edit Expense use the same Money form sections, amount field, picker treatment, date rows, page hierarchy, keyboard behaviour, and Save/Discard/Keep editing protection.

### Public Business Profile

- Owner preview route `/p/:handle`; the deployed customer route is `https://workloop.uk/:handle` once custom-domain SSL is active.
- Business info.
- Services.
- Working hours.
- Notice banner.
- Request-booking form.
- The customer page is a request experience, not instant slot booking. It asks for a real preferred date/time and repeatedly explains that the owner must confirm.
- Public request creation through the bounded `create-booking-request` Edge
  Function; anonymous clients do not write the table directly.
- The request path uses a stable client request token, bounded server validation, a honeypot, source/phone rate limits, profile/service ownership checks, and a server-created owner notification. Manual entry remains available if public booking is unavailable.

### Booking Requests

- In-app booking request triage.
- Status update.
- Manual confirmation flow that checks/edits client, phone, service, date, time, duration, price, location, private notes, and optional payment due before atomically creating the booking and updating the request.
- Decline confirmation before closing a request.
- Notification creation on request/confirmation paths.

### Notifications

- Notification centre.
- Read/unread state.
- Mark read/all read.
- Preferences screen.
- App-side notification records for selected events.
- On-device task and booking reminders with tap-through navigation.
- Push token table exists for future push delivery.

### Settings

- Calm Settings overview with account identity and dedicated Account,
  Notifications, and App preferences destinations.
- System, Light, and Dark appearance choice is stored locally and applied at
  the app boundary; no workspace schema or account data is involved.
- App preferences is reserved for maps, calendar, and Workloop information.
- Account owns preferred name, email, password, workspace export, account deletion request, and sign out.
- Notifications owns booking, payment, task, follow-up, digest, summary, and quiet-time preferences.
- App preferences owns the default maps choice, calendar connection entry point, and concise build information.
- Business details, services, and working hours remain in Business profile. Public link setup and booking requests live in Booking page. Neither is duplicated in Settings.
- Legacy tab navigation, nested settings cards, unfinished payment placeholders, and duplicate feature-directory links have been removed.

### Security / Foundation

- `.env`-based Supabase config.
- `.env.example`.
- RLS policy contract.
- Live RLS enabled on current public tables.
- Public profile and booking request access routed through Edge Functions.
- Account deletion request/completion Edge Functions exist; completion remains admin-token gated.
- Request and completion source independently require the requester to be the workspace's sole member before destructive deletion can proceed.
- Authenticated task and booking workflow RPCs use bounded public wrappers, private tenant-validating implementations, and per-user/workspace idempotency records.
- Public booking and Places Edge Function paths use private rate-limit state; direct anonymous table grants remain removed.
- Six launch migrations are live: `20260726000048`, `20260726000057`,
  `20260726000102`, `20260726000110`, `20260726000118`, and the explicit
  client-deny policy `20260726000520`. Current Edge deployments are
  `create-booking-request` v8, `places-address-search` v8,
  `get-public-profile` v6, `request-account-deletion` v6, and
  `complete-account-deletion` v9; structural, grant, and advisor smoke checks
  passed.
- The audit candidate additionally contains migration `20260726005736` and
  updated booking-request Edge source. Production was not changed during this
  audit; clean replay and isolated staging validation are required before
  promotion.
- Schema contract.
- GitHub remote connected.
- iOS launch scope is iPhone portrait on iOS 15+; Android is portrait with minimum API 26 and target/compile API 36. Tap to Pay has stricter runtime device requirements.
- CI is defined for Flutter 3.44.8 formatting, analysis, tests, Deno formatting/type checks/tests, Android profile and web builds, plus a separate unsigned iOS profile build on macOS. Android uses Gradle 8.14.3, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, and Java 17.
- Model serialization tests.
- `flutter analyze` clean at latest verification.
- `flutter test --dart-define-from-file=.env` passing at latest verification.

### 2026-07-26 comprehensive-audit candidate evidence

- Dart formatting checked 186 files with no changes; `flutter analyze` reported
  no issues; all 249 Flutter tests passed in approximately 33 seconds with
  40.10% line coverage.
- Eleven launch-golden tests produced 13 reviewed images and passed again
  without updating expectations. The responsive harness passed 108 phone/text-scale
  renders plus keyboard safety.
- All 19 Edge Function unit tests passed, with Deno formatting, lint, and six
  entry-point type checks clean.
- OSV-Scanner 2.4.0 found no known issue in 132 resolved Dart packages. Deno
  and CocoaPods lock formats were unsupported by that scanner; six direct
  Flutter packages are behind latest and were reviewed without blind upgrades.
- Signed-out Auth/navigation integration passed on an iPhone 17 Pro simulator.
  iOS simulator debug plus unsigned device profile/release compilation passed,
  and the `workloop://` recovery scheme is registered.
- The current 34.8 MB profile installed and launched on the physical iPhone;
  the launch command completed successfully and the Workloop process was
  confirmed running through CoreDevice.
- Android debug/profile compilation passed with package
  `com.ismaeel.workloop`, minimum API 26, target/compile API 36, and portrait
  activity. The profile APK passed `zipalign -c -P 16 -v 4` and signature
  verification.
- The web release build passed. Android App Bundle release signing fails closed
  until the production upload keystore is supplied; no debug-signing fallback
  exists. iOS App Store export remains blocked by missing Distribution signing.
- Clean database replay, all 43 pgTAP assertions, authenticated/two-account
  staging E2E, public booking conversion, deletion completion, measured
  performance/load, physical Android, and full assistive-technology QA remain
  open. The evidence-based verdict is not public-launch ready.

## Partially Completed Features

- Money-to-booking workflow: new bookings and completed bookings use atomic linked-payment workflows; production-like end-to-end and real-device QA is still needed.
- Calendar integration: explicit event import and point-in-time `.ics` export exist; real external provider sync does not.
- Notifications: in-app centre/preferences and on-device task/booking reminders exist; APNs/FCM cross-device push delivery does not.
- Recurring bookings: series creation is intentionally hidden from V1 until
  create/edit scope, exceptions and series-level conflict recovery can be
  completed. Existing recurrence data remains readable and compatible.
- Public profile: request-booking MVP exists; full slot-selection/self-booking/pay-now is not complete.
- Privacy: export and sole-owner-guarded account deletion request/completion are deployed; the production secret, destructive disposable-account test, and operational SLA still require release evidence.
- Security: RLS enabled, public profile/request tables are no longer directly
  public, and the security advisor now reports only the leaked-password
  protection warning. Low-traffic unused-index notices belong to the separate
  performance advisor.
- Typed models: main models exist; some features still pass raw maps.
- Navigation: GoRouter exists, but many flows still use `MaterialPageRoute`.
- Testing: 331 Flutter tests, 25 Deno tests, responsive/golden suites, a
  signed-out iOS integration smoke, database contracts, and generator/load
  harnesses exist; dynamic database, authenticated staging, repository-fake,
  load, and physical-device coverage is still thinner than the launch risk
  warrants.

## Planned Features

Near-term:

- QA Money daily-use workflow across real device and simulator.
- QA Money-to-Bookings across new booking, completed booking, paid/unpaid, and dashboard refresh.
- QA booking request confirmation on real device.
- Monitor Supabase advisors and enable leaked password protection before beta.
- Continue splitting oversized files.

V1 before beta:

- Production validation of on-device reminder behaviour across permission, reboot, timezone, daylight-saving, and notification-tap states.
- Optional remote push foundation only after APNs/FCM can be operated reliably.
- Calendar sync hardening.
- Data export/delete operational hardening.
- More robust QA around onboarding, auth, bookings, money, tasks, public profile.

Post-V1 / V2:

- Stripe payment collection is deployed in test mode: Connect uses direct
  merchant charges, the connected-account webhook and authenticated payment
  API are active, database/RLS tests pass, platform fees are disabled, and
  live keys remain blocked. Test connected-account onboarding, simulated and
  physical payment/refund QA, Apple entitlements, and explicit live-mode
  approval remain. Deposits remain future scope.
- Full public slot-selection booking engine.
- Reviews system.
- Intake forms.
- QR code export.
- Closure dates.
- Advanced analytics.
- Teams/staff.
- Marketplace/discovery only if product direction changes.

## Technical Debt

- UI system: the canonical `Workloop*` primitives now cover headers, metrics, rows, filters, segmented controls, empty states, buttons, bottom navigation, fields, search, sheets, dialogs, pickers, haptics, motion, texture, and theme semantics. System/Light/Dark modes are enabled. Some large legacy screens still mix shared primitives with local layout containers and should be migrated gradually when those screens next change.
- Large files:
  - `lib/features/tasks/tasks_screen.dart` ~946 lines after extracting task card, task logic, task detail, and task editor parts.
  - `lib/features/tasks/task_logic.dart` ~280 lines.
  - `lib/features/tasks/task_card.dart` ~259 lines.
  - `lib/features/tasks/task_detail_widgets.dart` ~320 lines.
  - `lib/features/tasks/task_editor_widgets.dart` ~497 lines.
  - `lib/features/appointments/add_appointment_screen.dart` ~1200 lines after extracting appointment logic and reusable booking form widgets.
  - `lib/features/appointments/add_appointment_logic.dart` ~45 lines.
  - `lib/features/appointments/add_appointment_widgets.dart` ~328 lines.
  - `lib/features/appointments/appointment_detail_screen.dart` ~1217 lines after extracting private detail sections and time picker.
  - `lib/features/appointments/appointment_detail_sections.dart` ~375 lines.
  - `lib/features/settings/widgets/settings_business_tab.dart` ~1215 lines.
  - `lib/features/finance/finance_screen.dart` ~1087 lines after extracting target/activity widgets.
  - `lib/features/finance/finance_screen_widgets.dart` ~394 lines.
  - `lib/features/clients/client_detail_screen.dart` ~1061 lines.
- Mixed routing approach.
- Raw map payloads still used in several areas.
- Some legacy product/code names remain.
- Supabase security advisor was cleared by the 2026-08-11 Auth/database
  hardening. Separate performance-advisor output still includes expected
  low-traffic unused-index notices.
- CI has not yet accumulated hosted-run history for this launch branch.
- `device_calendar` and `flutter_local_notifications` still use CocoaPods on
  iOS. Flutter 3.44 supports this hybrid build, but their Swift Package Manager
  support must be revisited before a future Flutter release makes it mandatory.
- No repository tests with mocked Supabase.
- Limited widget/integration tests.
- No crash/error reporting.
- No environment separation docs beyond `.env`.

## Priority Queue

1. Complete signed-out abuse, authenticated workflow, and destructive disposable-account end-to-end tests against the deployed Edge Functions and migrations.
2. Prove fresh external signup/confirmation/recovery/password-change and
   existing-email OAuth linking; verify the deletion secret and Google Places
   key restrictions without exposing either value.
3. QA booking/payment, task/reminder, public-request, import-retry, export, and deletion loops on a physical Android device and finish the accessibility/device matrix.
4. Publish the legal/support web surface, complete iOS/Android distribution signing, and finish both store declarations.
5. Preserve the release candidate in a reviewed clean commit/tag and run the
   provenance preflight before any signed store artifact.
6. Add repository fakes, end-to-end flow coverage, and production crash/error reporting.
7. Continue refactoring the largest files only in small behaviour-preserving slices.

## Current Risk Level

Product risk: medium-low. The core loop is coherent.

Architecture risk: medium. The app is improving but several screens remain large.

Security risk: medium before production. RLS/public boundaries and Auth
controls are stronger, but clean replay, two-account dynamic isolation,
production-secret verification and live deletion/abuse-control evidence remain
release gates.

UX risk: medium-low in source, with physical-device accessibility, text-scale, compact-phone, permission, error, and Android coverage still required before launch.

### 2026-08-10 booking-page ownership and live-web verification

- Home now keeps Notifications as its sole utility. Tools owns Booking page,
  Business profile, and Settings beneath the existing Money, Tasks and Notes
  workflows.
- Booking page is an owner workflow with readiness, request state, preview,
  copy/share actions, editing entry points, and the canonical request inbox.
  Business profile is limited to business details, services and working hours.
- The public Workloop website now renders real `/:handle` customer pages and
  proxies requests to the existing bounded Supabase Edge Function. Privacy,
  terms and deletion pages are public. A safe live honeypot submission returned
  the expected 202 response without inserting a request.
- `workloop.app` and `www.workloop.app` are attached to the managed deployment
  but remain pending DNS and SSL validation; the temporary public deployment
  URL is operational.
- Dart formatting is clean across 206 files, Flutter analysis reports no
  issues, all 349 Flutter tests pass, and the iOS profile build succeeds at
  71.0 MB.
- That exact iOS profile build installed and launched on the paired physical
  iPhone. Install/launch remains distinct from a signed manual workflow and
  accessibility pass.

### 2026-08-11 atomic appearance switching

- Manual Light/Dark changes now resolve the compatibility palette before the
  app tree builds, so legacy colours cannot trail the active semantic theme by
  one frame.
- System appearance changes rebuild the app boundary and use the current
  platform brightness through the same atomic path.
- Settings identity and row-icon surfaces now read semantic theme tokens
  directly. A widget regression switches appearance and verifies both surfaces
  after exactly one frame.
- Flutter analysis is clean, all 355 Flutter tests pass, and the signed iOS
  profile build succeeds at 71.0 MB.
- That exact profile build installed and launched on the paired physical iPhone;
  CoreDevice confirmed the running `Runner` process. Human rapid-toggle review
  remains the final perceptual check.

### 2026-08-11 beta interface uniformity sweep

- Work is now one retained command workspace. Its title, description, request
  inbox and create action stay mounted while Schedule, Tasks and Notes change
  below them; each view retains its own content state.
- Primary screens share the same feature-header geometry and 46-point circular
  create action. Root and peer navigation now use a quieter neutral surface and
  a two-pixel indigo active line instead of large filled selection blocks.
- Money uses the same neutral/indigo semantic palette as the rest of Workloop.
  Business setup rows no longer assign unrelated colours to Services, Working
  hours and Business profile.
- Flutter analysis is clean, all 359 Flutter tests pass, and 27 protected launch
  goldens pass after visual review. An unsigned 70.8 MB iOS profile artifact
  builds successfully. A temporary QA copy using the existing development
  profile installed and launched on the paired iPhone as PID 90668.
- Xcode now has the Apple Developer account and regenerated signing assets. A
  signed profile build succeeds, and the App Store export produces a 34.3 MB
  `Workloop.ipa` with `beta-reports-active=true` and `get-task-allow=false`.

### 2026-08-11 Stripe beta-readiness pass

- Payment collection now offers system sharing and copy fallback for secure
  links, optional Stripe email receipts for contactless payments, completed
  receipt access, explicit processing/refund states, and keyboard-safe scrolling.
- Stripe Terminal 5.7 is installed on iOS and Android. The authenticated
  `stripe-payments` Edge Function is active as v8; live mode is enabled after a
  supervised secret cutover. Connected-account creation and hosted onboarding
  now use Stripe Accounts v2 with the Merchant configuration, full Dashboard
  access and Stripe-owned fee/loss responsibility, matching the live platform
  setup. Stripe platform-configuration failures are mapped
  to a stable public error and the Flutter sheet now uses the standard inline
  error state instead of exposing backend exception details or dashboard URLs.
- Apple Sign in is enabled on the Workloop App ID. The Tap to Pay entitlement
  request was submitted and is awaiting Apple review; no entitlement was added
  to the app before approval.
- Flutter analysis and all 360 Flutter tests pass. Signed profile and App Store
  IPA builds succeed with the refreshed Apple account and profiles.
- Stripe reports business and platform identity verification complete, and the
  public `@workloopapp` Stripe profile is active. The direct-charge Connect
  model and Connect Platform Agreement are confirmed in the dashboard.
- Four public Stripe handoff routes for setup return/expiry and Checkout
  success/cancellation are implemented, validated and deployed in Workloop
  website version 5. All four production URLs return HTTP 200.
- A production connected-account webhook is active for payment, Checkout,
  refund, dispute and account events. Its signing secret and all four public
  handoff URLs are stored in Supabase. The authenticated live Stripe API key is
  installed and `STRIPE_LIVE_MODE_ALLOWED=true` is active.
- The approved one-time cleanup removed one test connected account, two
  non-succeeded test transactions, 18 test webhook events and the legacy test
  account pointer. Payment/refund/webhook tables are empty and invoice Stripe
  attribution remains zero.
- A read-only Stripe account request returned HTTP 200 for the expected Workloop
  platform with charges and payouts enabled. An unauthenticated payment-function
  probe now reaches the expected HTTP 401 boundary rather than the live-mode
  HTTP 503 block. Stripe records the negative-balance liability and ongoing
  seller-compliance acknowledgements as completed on 12 August 2026. The first
  live Accounts v2 merchant account was created for the authenticated production
  workspace and is pending hosted onboarding; charges and payouts remain disabled.
  No charge, refund or live webhook has been created. Hosted onboarding and one
  bounded payment/refund smoke test remain.

### 2026-08-11 authentication and backend hardening

- Confirmed email/password, native Apple sign-in, Google OAuth entry and TOTP
  setup/challenge flows are implemented. Apple and Google are enabled live;
  Google is limited to the owner while its consent screen remains in testing.
- Supabase now rejects leaked passwords and passwords below the 12-character,
  uppercase/lowercase/number/symbol baseline. Sessions are capped at 30 days
  and expire after 7 inactive days; refresh-token replay detection remains on.
- Opted-in MFA is enforced at both the Flutter auth gate and database boundary.
  Twenty-two authenticated public tables received a restrictive AAL2 policy,
  while accounts without a verified factor retain existing AAL1 access.
- Trigger-only functions are closed to mobile RPC use, direct Postgres requires
  SSL, and the live Supabase security advisor reports no findings.
- Auth connection allocation now uses the dashboard-recommended 17% strategy,
  preserving the current 10-of-60 ceiling while scaling with future compute.
  Performance advisor output is otherwise limited to pre-beta unused-index
  information; relationship, workflow and cleanup indexes were retained until
  representative production telemetry exists.
- App Store Connect contains the Workloop record (`6800472527`). Xcode signing
  is connected and App Store IPAs export successfully. Apple rejected build 1
  for missing camera and photo-library purpose strings referenced by the file
  import dependency; the truthful strings are now present and replacement
  build 2 passed processing and is `Ready to Submit`. The automatically
  distributed `Workloop Internal Beta` group contains the build and its focused
  testing guidance; adding the sole Account Holder is currently disabled by
  App Store Connect despite the documented eligible role.
- The verified `auth@workloop.uk` SMTP path delivered a real Supabase recovery
  email and the seven security-change notifications are enabled. External beta
  still needs a fresh-account confirmation test outside the development team.
  The newest visible scheduled database backup is 8 August and must be
  rechecked after the Pro upgrade produces its next scheduled snapshot.

### 2026-08-12 QA and release-candidate truth refresh

- The latest observed safe local source run reports clean Flutter analysis and
  360/360 unit/widget tests. This does not supersede the release-candidate gate:
  the signed-out iOS simulator integration currently fails because the Auth mode
  toggle is below the tappable 402 x 874 viewport and its tap does not reach the
  Create-account state.
- The repository now authors 82 pgTAP assertions (51 schema/security, 16 tenant
  isolation and 15 privileged-MFA/payment-retention). No clean replay or pgTAP
  pass was produced locally because
  Docker and the Supabase CLI are unavailable; historical rolled-back live
  scripts are not a substitute.
- The production-refusing staging SDK isolation harness now covers practical
  core mutations across contacts, services, appointments, invoices and line
  items, expenses, tasks and checklists, notes, notifications, booking requests,
  push tokens and calendar-sync accounts. It records every disposable row
  for owner cleanup and still has no passing staging result. Its canonical
  runner requires the declared staging project ref to match the Supabase URL,
  enforces the same guard inside each test process, and supplies credentials
  through a private temporary Dart-define file rather than command arguments.
- Android key properties and keystore patterns are ignored. CI and signed-build
  commands use `scripts/qa_release_candidate.sh`, which refuses tracked or
  untracked changes, verifies an optional expected full SHA, rejects tracked
  signing material and stale target artifacts, then records
  commit/version/toolchain provenance plus new artifact sizes and SHA-256. The current
  owner worktree is intentionally dirty, so it is not a releasable candidate.
- The local privacy/terms source and deletion instructions now reflect the
  canonical `workloop.uk` surface, `support@workloop.uk`, Stripe processing and
  the current Business > Settings > Account navigation. The deployed 10 August
  legal pages remain older; publication, legal-controller details, mailbox
  monitoring and launch-market legal review remain external.
- Build 3 remains a valid local signed archive only. It was not accepted by App
  Store Connect and predates current source/backend payment work, so it must not
  be used as the beta artifact.
- Stripe live configuration exists, but the merchant remains pending hosted
  onboarding and no live charge/refund has run. Tap to Pay still lacks Apple's
  entitlement. Payment collection remains gated rather than beta-operational.

Current verdict: continue developer testing. Do not invite even a small external
beta until the Auth integration defect, clean database/pgTAP run, disposable
staging workflows/isolation, external Auth lifecycle and current clean signed
artifact are green. Physical Android/accessibility, observability,
performance/load, complete payment operations and store/legal operations remain
explicit public-launch gates.

### 2026-08-12 beta-blocker remediation and integrated verification

- The first-run Auth action now appears above the fold. The signed-out journey
  passes on the 402 x 874 iPhone 17 Pro simulator and still covers account-mode
  switching, returning to sign in, and password recovery. This supersedes the
  red Auth result immediately above.
- A forward migration now protects privileged onboarding/task/booking RPCs with
  the existing opt-in MFA policy, removes authenticated access to private
  implementations, gives authenticated Edge Functions a bounded policy check,
  links Stripe webhook events to workspaces, and limits full webhook payload
  retention to 30 days with deletion-time and scheduled scrubbing.
- Stripe readiness now requires details, charges, and payouts. Privacy export
  includes connected-account, provider transaction, and refund records. Account
  deletion fails closed until Workloop's Stripe Accounts v2 merchant account is
  confirmed closed.
- Booking/request language, calendar permission recovery, calendar-copy error
  handling, in-app and local public payment/legal disclosures, Android signing-secret
  ignores, compact Business/booking layouts, current responsive coverage, and
  clean-candidate provenance checks are implemented.
- Integrated local evidence is clean: 220 Dart files formatted, no analyzer
  findings, 371/371 Flutter tests, 52.84% line coverage, 27/27 protected
  goldens after reviewing the three intentional baseline changes, 30/30 Deno
  tests, eight Edge entry-point checks, four data-profile dry runs, signed-out
  simulator smoke, signed iOS profile (71.3 MB), Android profile APK (158.7 MB,
  16 KB aligned and v2 signed), and web release compilation.
- That fresh signed profile installed and launched on the paired iPhone 15 Pro
  Max; CoreDevice confirmed the current Runner process (PID 95655). This is
  install/launch evidence, not manual workflow or VoiceOver evidence.
- Production remains unchanged. The new migration's 82 authored pgTAP
  assertions still require a clean replay, and the expanded core/public/two-user
  staging journeys still require a disposable non-production project. The
  clean-candidate preflight correctly rejects the current owner worktree.

Current verdict: the source-level Auth, MFA-boundary, payment-data, legal-copy,
responsive and release-process defects found in the audit are remediated. An
external beta remains gated by clean database/staging evidence, external Auth
lifecycle proof, support/legal operation, and a clean tagged TestFlight build.
