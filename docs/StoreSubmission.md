# Workloop Store Submission Draft

Last updated: 2026-08-13

This copy is a launch draft, not a substitute for App Store Connect, Play
Console, privacy, or trade-mark review.

## Listing identity

- Product name: `Workloop`
- Recommended store title: `Workloop: Solo Business OS`
- iOS subtitle: `Run your service business`
- Android short description:
  `Clients, bookings, money and follow-ups in one calm daily business loop.`
- Primary category: Productivity
- Secondary iOS category: Business
- Support email: `support@workloop.uk`
- Privacy URL: `https://workloop.uk/privacy.html`
- Terms URL: `https://workloop.uk/terms.html`
- Account deletion URL: `https://workloop.uk/delete-account.html`
- Launch device scope: iPhone portrait on iOS; portrait orientation on Android.
  iPad and landscape layouts are not part of the 1.0 store promise.

Reserve the final title before producing screenshots. Similar Workloop names
already exist in both stores.

## Promotional text

Know what is happening, what needs attention, and what to do next. Workloop
connects the daily operation of a solo service business without the clutter of
generic business software.

## Full description

Workloop is the calm business operating system for solo service professionals.
It brings clients, bookings, money, tasks, and notes into one connected daily
workflow, so the next useful action is always clear.

START WITH TODAY

- See today’s bookings and business priorities.
- Surface overdue follow-ups and unpaid work.
- Move directly from attention to action.

KEEP CLIENT CONTEXT TOGETHER

- Store contact details, relationship notes, tags, and client history.
- See linked bookings, tasks, notes, and payments in context.
- Import only the contacts you choose.

RUN BOOKINGS WITH CONFIDENCE

- Create and manage focused one-off bookings. Existing historic recurring
  records remain readable, but new recurring-series creation is outside V1.
- Track status, service, location, price, and client details.
- Export your schedule as a standard calendar file.

UNDERSTAND THE MONEY

- Record income, outstanding amounts, and expenses.
- Review useful week, month, and custom-period summaries.
- Keep operational money context linked to clients and bookings.

FOLLOW THROUGH

- Create tasks, on-device reminders, checklists, and reusable templates.
- Keep business notes and client context close to the work.
- Use focused notifications without turning Workloop into another noisy feed.

BUILT FOR TRUST

- Exact icon-neon accents across Light and OLED dark appearances.
- Workspace export and a protected sole-owner account-deletion workflow.
- Optional contact, calendar, and file imports stay under your control.

Workloop organises business records; it is not a bank, accountant, or
replacement for professional advice.

The default beta build sets `PAYMENT_COLLECTION_ENABLED=false`. Do not add a
Stripe collection claim, payment screenshot, or payment reviewer instruction
unless the submitted build explicitly enables that capability and every
payment release gate has passed.

## Suggested iOS keywords

`business,booking,client,solo,service,task,invoice,expense,calendar,organiser`

Recheck the 100-character App Store limit when entered in App Store Connect.

## Screenshot story

Use real in-app screens with fictional data. Do not composite features that the
release does not contain.

1. **Know what needs attention** — Today with the schedule and next action.
2. **Every client in context** — client overview with linked history.
3. **Bookings without the admin** — booking list and focused detail.
4. **See what you earned** — Money summary with received and outstanding.
5. **Follow through calmly** — tasks/checklist/reminder view.
6. **Your business, one loop** — Business showing the booking page, services,
   working hours, business profile, and Settings; Work keeps Schedule, Tasks,
   and Notes together.

Use the exact icon neon `#C1FF72`, restrained dark or neutral backgrounds, large
legible copy, and no more than one claim per frame.

## Permissions and reviewer explanation

| Permission | User-triggered purpose | If denied |
| --- | --- | --- |
| Contacts | Review and import selected contacts as clients | Manual client entry remains available |
| Calendar | Review and import selected events as bookings. Android's calendar provider grants the package's required read/write permission pair, but Workloop's launch flow does not modify device events. | Manual booking entry and `.ics` export remain available |
| Files | Select supported exports for reviewed import or save an export | Clipboard/manual entry remains available where offered |
| Notifications | Schedule opted-in on-device task and booking reminders | Workloop remains usable; reminders stay visible in-app |
| Location / Bluetooth / NFC | Connect to an eligible Stripe reader or Tap to Pay flow only in a payment-enabled build on supported hardware | Manual payment records remain available |
| Internet | Secure authentication, workspace sync, public booking, and address lookup | Clear retry/error states are shown |

Reviewer notes should explicitly say:

- Contacts and calendar are optional and never imported automatically.
- The Android calendar plugin requires the platform read/write permission pair;
  Workloop V1 only reads events the user reviews for import and does not modify
  the device calendar.
- Google Places is optional; addresses can be entered manually.
- The iOS file-picker dependency links camera/photo chooser support, which is
  why the binary includes purpose strings. Workloop V1 exposes only reviewed
  CSV, text and Markdown imports plus ICS/JSON export; it does not expose a
  camera or photo-library import workflow.
- “Money” records operational income/expense information and does not connect
  to a bank feed. In the default beta, Stripe collection entry points are off.
  In a separately approved payment-enabled build, Stripe processes collection
  for an eligible connected business and Workloop does not store full card
  numbers.
- Calendar export is point-in-time `.ics`, not live two-way sync.
- Any reminder delivered in V1 is on-device, not marketing or remote push.
- Public booking is a request that the owner reviews and confirms; V1 does not
  advertise live slot selection or automatic confirmation. Payment collection
  must be described only if the submitted build and connected-account operation
  have completed their payment release gates.
- The iOS review build is iPhone-only and both platform builds are
  portrait-oriented; do not supply landscape or iPad marketing media.

## Apple privacy declaration working map

Review the final App Store Connect definitions before submission.

| Data type | Collected | Linked to user | Tracking | Purpose |
| --- | --- | --- | --- | --- |
| Name and email | Yes | Yes | No | Account, public booking requests and confirmations, app functionality, and optional Stripe receipt delivery when payment collection is enabled |
| Phone/address | Optional | Yes | No | Business/client workflow |
| Contacts | Optional | Yes | No | User-selected client import |
| User content | Yes | Yes | No | Notes, tasks, bookings, support, business records |
| Other financial info | Optional | Yes | No | User-entered income/expense tracking and payment status/provider references |
| User ID | Yes | Yes | No | Authentication and security |
| Calendar events | Optional | Yes | No | User-selected booking import |
| Diagnostics | Support-only, user initiated | Potentially | No | Troubleshooting |

The current source has no advertising SDK and no cross-app tracking SDK.
Supabase, Stripe, Resend, Google OAuth and Google Places are service providers;
their actual processing must be reflected in the public privacy policy and
store answers.

## Google Play Data safety working map

- Data is encrypted in transit.
- Account deletion can be requested in-app and through the public deletion URL.
- Data collected for account/app functionality may include personal info,
  contacts, calendar events, files selected for import, user-generated content,
  and user-entered financial records. A payment-enabled build may additionally
  process connected-account identity, provider transaction/refund/dispute
  references, a public booking requester's email used for confirmation through
  Resend, and a customer email supplied for receipt delivery through Stripe.
- Contacts, calendar, files, and notifications are optional.
- No data is sold and the current source has no advertising SDK.
- Confirm Play’s current distinction between service-provider processing and
  “sharing” before answering the form.

## Accessibility evidence to capture

Do not claim a store accessibility feature until the release candidate is
manually exercised:

- VoiceOver and TalkBack announce navigation destinations and icon actions.
- Dynamic text does not clip primary workflows at large system sizes.
- Reduced-motion settings suppress non-essential UI motion.
- Contrast remains readable in light and OLED dark appearances.
- Every workflow is usable without relying on colour alone.

## TestFlight beta 4 handoff draft

Build name: `Workloop 1.0.0 (4) - Payments-off beta`

### Plain-English release notes

This beta strengthens Workloop's connected Today -> Client -> Work -> Money ->
Repeat workflow. It includes the five-part Today, Clients, Work, Money and
Business workspace, improved booking-request and calendar recovery, clearer
first-run account and legal access, responsive Light/Dark layouts, and safer
workspace export and account-deletion boundaries.

Card collection, Tap to Pay and payment links are intentionally unavailable.
Money records remain manual, and customer booking submissions are requests that
the business owner reviews rather than automatic confirmations.

### What to Test

- Create an account, confirm the email, sign in and complete business setup.
- Add and edit a client; create, edit, complete and cancel one-off bookings.
- Use Work > Schedule, Tasks and Notes and confirm each retained view keeps its
  place and context.
- Record received, outstanding and expense entries manually; verify Today,
  Money and client history stay aligned.
- Configure and share the booking page; submit a signed-out request and approve
  or decline it as the owner.
- Exercise reminder settings, calendar import/export, support, Terms, Privacy,
  workspace export, sign-out and password recovery.
- Confirm no Stripe setup, Tap to Pay, card collection or payment-link entry
  point is visible.

Report the screen, action, expected result, actual result, screenshot, device,
OS version and Workloop build number to `support@workloop.uk`.

## TestFlight beta 5 handoff draft

Build name: `Workloop 1.0.0 (5) - Booking confirmations`

### Plain-English release notes

This build adds customer email to public booking requests. A request is still
not a booking: after the business accepts and schedules it, Workloop sends the
customer a confirmation with the agreed service, date/time and location. Email
delivery is queued safely if the provider is temporarily unavailable.

### Additional What to Test

- Submit a signed-out booking request with a real controlled email address and
  confirm the receipt says nothing is booked yet.
- As the owner, verify the same email is shown, choose the agreed date/time and
  create the booking.
- Confirm the customer receives exactly one accurate email and the new client
  record retains the address.
- Retry a submission or confirmation after a connection interruption and
  report any duplicate request, booking or email.

Card collection, payment links and Tap to Pay remain disabled for this beta.
Do not distribute Build 5 until the backend migration, three booking functions,
Resend secrets and scheduled retry worker have passed the controlled-inbox
staging gate.

### Known beta limitations

- One-off booking creation only; historic recurring records remain readable.
- Public booking is a request, not live availability or automatic confirmation.
- Calendar export is point-in-time ICS, not live two-way sync.
- Reminders are on-device; remote push is not a beta capability.
- Card collection, payment links and Tap to Pay are disabled.
- No bank feed, accounting replacement, staff/team operation or AI workflow.
- iPhone portrait is the TestFlight layout promise; iPad and landscape are not.

### App Store Connect completion checklist

- App Privacy: use the data map above and recheck Apple's current definitions.
- Export compliance: `ITSAppUsesNonExemptEncryption=false`; answer that the app
  does not use non-exempt encryption.
- Reviewer contact: the owner must enter a monitored name, phone and
  `support@workloop.uk`; do not invent those details in source.
- Review access: provide a dedicated fictional-data account only after its Auth
  confirmation/recovery journey passes and it is intentionally created for
  Apple.
- Internal testers: prepare the existing internal group, but do not attach the
  build or add testers until upload approval and processing succeed.
- External testers: defer until internal smoke, support monitoring, legal
  controller details and external-beta review information are complete.

### 2026-08-15 live TestFlight handoff

- Build 5 is uploaded, processed and marked Ready to Submit.
- What to Test, beta description, feedback email, marketing/privacy URLs and
  honest payments-off/request-only review notes are entered.
- `Workloop Private Beta` exists as the external group.
- A confirmed dedicated reviewer account is entered with credentials retained
  only in App Store Connect and the owner's local Keychain. Production Auth now
  redirects web confirmations to `workloop.uk`; the retired `workloop.app`
  allow-list entry has been removed.
- Apple still requires the owner's monitored reviewer phone number before the
  contact form can be saved and Build 5 can be submitted for Beta App Review.
- After approval, enable the group's public link and share that link with the
  intended tester cohort; do not publish an invitation URL before Apple has
  made it active.
