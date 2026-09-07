# Booking fixes and remote access — 7 September 2026

## Result

- Requested dates/times now prefill confirmation correctly, including existing text-only requests. The reported `2026-09-11 at 07:41` resolves to 11 September at 07:41 in the business timezone; the London UTC payload is `2026-09-11T06:41:00Z`.
- Exact booking links render the target directly. They no longer briefly show Today or add an unnecessary Back step.
- Tomorrow briefing displays normal business-local `HH:mm` without BST/GMT. Actual timezone conversion is preserved. Customer message content and explicit repeated-hour disambiguation retain their relevant timezone information.
- The public website now sends a validated exact timestamp and business timezone for manually entered dates/times. New requests no longer depend solely on display text. General enquiries remain possible; a partial, invalid or ambiguous time cannot silently become another booking time.

## Files and reasons

The [request prefill report](2026-09-07-booking-request-prefill.md) lists the helper, form, repository and regression files. The [direct navigation report](2026-09-07-direct-tomorrow-booking-navigation.md) lists the route, detail accessibility label and Tomorrow changes. `pubspec.yaml` is now `1.0.0+14` to distinguish the corrected local build from uploaded build 13.

The marketing checkout at `/Users/ismaeelsmiley/Documents/Workloop Website` changes the public request form, page and profile typing; adds `app/booking-request-time.ts`, its behavior tests and `docs/BOOKING_REQUEST_TIME.md`; and updates the existing form-wiring assertion to the validated result. No schema, dependency or customer-data rewrite is involved.

## Integrated validation

- `flutter analyze`: clean (`/tmp/workloop-build14-analyze.log`).
- Full `.env` suite: **1,011 passed, six payment-capability tests skipped** (`/tmp/workloop-build14-tests.log`).
- Those gated payment suites rerun with payment collection and subscriptions enabled: **7 passed, zero skips** (`/tmp/workloop-build14-enabled-payment-tests.log`; one existing ungated test is included again).
- Signed iOS profile build succeeded, 76.2 MB, bundle `com.ismaeel.workloop`, version `1.0.0 (14)`. Payment collection, subscriptions and crash reporting enabled, matching the previous candidate configuration. Both location-purpose strings verified in the built Info.plist. Log: `/tmp/workloop-build14-profile.log`.
- App `git diff --check`: clean. Prior dirty work preserved; uploaded build 13's isolated source/artifact untouched.
- Website TypeScript and lint clean. Final production build and **43 tests** passed. Eight additional actual React form/browser fixture checks passed in an America/Los_Angeles browser against a London business, with request writes intercepted. No real customer requests or emails were sent.
- One old website source assertion expected the former `requestedFor: selectedSlot` wiring. It was updated to require the validated time result; the behavior tests separately verify both manual and selected-slot payloads. The final full website run passed.

## Website publication

Public Workloop website version **37**, source commit `d6a86d4d7b6891cee1be5f9157562f64e7f122a8`, deployed successfully to the existing public audience. Project: `appgprj_6a6926a374f881918d8aed9f3b21307e`; deployment: `appgdep_6a9e626ff82481919f3e4507aff72898`.

The live `https://workloop.uk/testshop` response independently returned HTTP 200 and the exact `explicit-business-time-v1` marker. Receipt: `/tmp/workloop-booking-time-live-verification.json`. Browser fixture evidence and the reviewed patch remain in `/Users/ismaeelsmiley/Documents/Workloop Website Review/2026-09-06-launch/booking-time-origin`.

## Device and release limits

Build 14 is compiled locally, **not installed or uploaded to TestFlight**. Installation could not find the phone; a fresh Apple device listing shows it paired but with its tunnel unavailable. iPhone Mirroring reports the phone in use. The user has been asked to restore cable/Wi-Fi connectivity for installation. Physical validation of these fixes therefore remains pending. Build 13 remains the previously uploaded binary.

Existing incorrectly confirmed bookings are not silently moved. Their owner must explicitly correct them. A legacy request with no historical timezone uses its current workspace timezone; an undocumented past timezone change cannot be reconstructed.

## Remote Codex access

The user's Settings screenshot confirmed the iPhone pairing, Allow connections and Keep this Mac awake already enabled. The user opened this task over 5G and subsequently confirmed current messages were working after reopening. No new VPN, public port or account change was needed. Keep the Mac online, plugged in and running ChatGPT; laptop lid open unless using a supported external-display setup. Setup guidance: https://learn.chatgpt.com/docs/remote-connections.

Suggested app commit: `fix: preserve requested booking times and open exact bookings directly`.
