# Workloop V1 Manual QA

Last updated: 2026-08-13

Use this checklist only against an isolated local or staging environment before
treating a build as ready for test users. Never use production accounts or data
for destructive, cross-account, booking-abuse, payment, or load checks.

For every run record the device, OS, app version/build, full commit SHA,
appearance, system text size, pass/fail result, evidence link, and defect ID.

## Core operating loop

- Sign up with email, open Terms and Privacy while signed out, and complete
  onboarding in under three minutes.
- Create a workspace with services, working hours, revenue target, handle, and
  first booking.
- Add and edit a client; verify the Clients list and linked history update.
- Add a one-off booking, edit its time/service/price, mark it complete, and
  cancel a separate booking.
- Record received and outstanding income manually; verify Today and Money.
- Add a client-linked task; verify it in Work > Tasks and the client detail.
- Submit a public booking request in disposable staging, review it under the
  booking Requests view, and convert or decline it without automatic
  confirmation wording.

## Current V1 surfaces

- Exercise Today, Clients, Work > Schedule, Work > Tasks, Work > Notes, Money,
  Business, Notifications, and Business > Settings.
- From Business, verify booking-page readiness, preview, sharing, services,
  working hours, business profile, and Settings ownership.
- From Business > Settings > Notifications, toggle every preference and verify
  persistence after relaunch.
- From Business > Settings > App preferences > Calendar, verify point-in-time
  import/export without live-sync wording.
- Verify Privacy, Terms, Help & support, diagnostics, workspace export, and
  Business > Settings > Account > Delete account.
- Confirm `PAYMENT_COLLECTION_ENABLED=false` hides Stripe setup, card-collection
  actions, and booking-completion card actions while manual Money workflows
  remain available. Run payment-enabled flows only as a separately authorised
  pilot against the approved environment.

## Accessibility and physical devices

- On a physical iPhone, use VoiceOver through Auth, onboarding, every shell
  destination, detail/editor screens, sheets, legal/support, and deletion.
- On a small and current physical Android phone, repeat with TalkBack.
- Confirm focus order, spoken labels and values, rotor/navigation behaviour,
  live-region errors, destructive confirmations, and focus return after sheets
  and pushed routes.
- Verify offstage retained destinations are not focusable and the five shell
  destinations are announced in their visual order.
- At the largest supported text size, complete Auth, client and booking forms,
  booking completion, Money, Business, legal/support, and permission recovery
  without clipping or unreachable actions.
- Verify System, Light, and Dark appearances; reduced motion; colour-independent
  meaning; readable contrast; and minimum 44-point interactive targets.
- Exercise keyboard traversal/dismissal, password visibility, autofill, modal
  focus, and scroll recovery on the smallest supported viewports.

## Permissions, lifecycle, and recovery

- Test contacts, calendar, notifications, and payment-only permissions when
  accepted, denied, later revoked, and restored through system settings.
- Verify reminder scheduling, rescheduling, notification tap-through, restart,
  time-zone change, and denied-permission behaviour.
- Test fresh install, upgrade, background/resume, offline launch, interrupted
  submissions, retry, deep links, password recovery, sign-out, and returning
  session.
- Exercise empty, realistic, and high-volume workspaces plus UK daylight-saving
  and cross-midnight bookings.

## Security and backend evidence

- Run clean migration replay and all current pgTAP assertions on the release SHA.
- In disposable staging, prove two accounts cannot select, insert, update,
  delete, or export each other's workspace data.
- Run the guarded core, public-booking, deletion, Auth-lifecycle, and payment
  journeys with retained logs and cleanup evidence.

## Release regression

- Run formatting, `flutter analyze`, the full Flutter suite, Edge checks/tests,
  candidate preflight, and supported signed builds without skipped failures.
- Install the exact signed candidate on supported iOS and Android devices.
- Treat build/install/launch, interactive workflow QA, accessibility QA,
  store-console completion, and payment operation as separate evidence.
