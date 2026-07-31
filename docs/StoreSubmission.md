# Workloop Store Submission Draft

Last updated: 2026-07-26

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
- Support email: `support@workloop.app`
- Privacy URL: `https://workloop.app/privacy.html`
- Terms URL: `https://workloop.app/terms.html`
- Account deletion URL: `https://workloop.app/delete-account.html`
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

- Create one-off and recurring bookings.
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

Workloop organises business records; it is not a bank, card processor,
accountant, or replacement for professional advice.

## Suggested iOS keywords

`business,booking,client,solo,service,task,invoice,expense,calendar,organiser`

Recheck the 100-character App Store limit when entered in App Store Connect.

## Screenshot story

Use real in-app screens with fictional data. Do not composite features that the
release does not contain.

1. **Know what needs attention** — Home with today’s schedule and next action.
2. **Every client in context** — client overview with linked history.
3. **Bookings without the admin** — booking list and focused detail.
4. **See what you earned** — Money summary with received and outstanding.
5. **Follow through calmly** — tasks/checklist/reminder view.
6. **Your business, one loop** — Tools showing Money, Tasks, and Notes, with
   Profile and Settings visible from the Home header.

Use the exact icon neon `#C1FF72`, restrained dark or neutral backgrounds, large
legible copy, and no more than one claim per frame.

## Permissions and reviewer explanation

| Permission | User-triggered purpose | If denied |
| --- | --- | --- |
| Contacts | Review and import selected contacts as clients | Manual client entry remains available |
| Calendar | Review and import selected events as bookings. Android's calendar provider grants the package's required read/write permission pair, but Workloop's launch flow does not modify device events. | Manual booking entry and `.ics` export remain available |
| Files | Select supported exports for reviewed import or save an export | Clipboard/manual entry remains available where offered |
| Notifications | Schedule opted-in on-device task and booking reminders | Workloop remains usable; reminders stay visible in-app |
| Internet | Secure authentication, workspace sync, public booking, and address lookup | Clear retry/error states are shown |

Reviewer notes should explicitly say:

- Contacts and calendar are optional and never imported automatically.
- The Android calendar plugin requires the platform read/write permission pair;
  Workloop V1 only reads events the user reviews for import and does not modify
  the device calendar.
- Google Places is optional; addresses can be entered manually.
- “Money” records operational income/expense information and does not process
  cards or connect to a bank.
- Calendar export is point-in-time `.ics`, not live two-way sync.
- Any reminder delivered in V1 is on-device, not marketing or remote push.
- Public booking is a request that the owner reviews and confirms; V1 does not
  advertise live slot selection, deposits, card processing, or pay-now.
- The iOS review build is iPhone-only and both platform builds are
  portrait-oriented; do not supply landscape or iPad marketing media.

## Apple privacy declaration working map

Review the final App Store Connect definitions before submission.

| Data type | Collected | Linked to user | Tracking | Purpose |
| --- | --- | --- | --- | --- |
| Name and email | Yes | Yes | No | Account and app functionality |
| Phone/address | Optional | Yes | No | Business/client workflow |
| Contacts | Optional | Yes | No | User-selected client import |
| User content | Yes | Yes | No | Notes, tasks, bookings, support, business records |
| Other financial info | Optional | Yes | No | User-entered income and expense tracking |
| User ID | Yes | Yes | No | Authentication and security |
| Calendar events | Optional | Yes | No | User-selected booking import |
| Diagnostics | Support-only, user initiated | Potentially | No | Troubleshooting |

The current source has no advertising SDK and no cross-app tracking SDK.
Supabase and Google Places are service providers; their processing must still
be described in the public privacy policy and store answers.

## Google Play Data safety working map

- Data is encrypted in transit.
- Account deletion can be requested in-app and through the public deletion URL.
- Data collected for account/app functionality may include personal info,
  contacts, calendar events, files selected for import, user-generated content,
  and user-entered financial records.
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
