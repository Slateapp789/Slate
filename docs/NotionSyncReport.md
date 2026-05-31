# Slate Notion Sync Report

Last updated: 2026-05-31

## Sources Reviewed

Fetched and compared:

- Slate HQ
- What Slate Is
- What Slate Is Not
- V1 Scope Lock
- Product Vision
- Features Index
- Technical Audit & Architecture Plan
- Business Profile Page
- Notifications & Comms
- UI Design System v2
- Core Architecture
- Database Schema
- Current Sprint

Also compared against:

- Current codebase
- Git history through `44c596f`
- Live Supabase project `imtbyrvsonzvtddswbtb`

## Authoritative Notion Pages

These should remain primary product truth unless intentionally superseded:

- `What Slate Is`
- `What Slate Is Not`
- `V1 Scope Lock`
- `Product Vision`
- `Business Profile Page`
- `Notifications & Comms`
- `Features Index` for MVP/V2 boundaries

These define why Slate exists, who it serves, what belongs in V1, and what should be excluded.

## Partially Authoritative Pages

These are useful but now need updates:

- `Slate HQ`
- `Technical Audit & Architecture Plan`
- `Core Architecture`
- `Database Schema`
- `UI Design System v2`
- `Current Sprint`

They contain valid direction but do not fully reflect the latest codebase.

## Outdated or Superseded Information

`Slate HQ`

- Still says "GoGetter" in places.
- Design style says premium dark UI/glassmorphism; current app is neutral light-grey glass.
- HQ links remain useful.

`Current Sprint`

- Last updated May 27.
- Lists older state: green/dark theme, RLS disabled on some tables, missing public booking page/push/calendar/recurring.
- Code has since moved well beyond this.

`UI Design System v2`

- Specifies dark-first palette and Slate Violet.
- Current implementation moved to neutral light/dark greys after multiple user-directed design iterations.
- The interaction principles remain useful, but colour/token specifics are superseded.

`Database Schema`

- Describes a simplified older MVP schema.
- Live DB now includes expenses, booking requests, notification preferences, push tokens, calendar sync accounts, task checklist items, account deletion requests, and additional profile fields.
- Some future tables listed there remain V2.

`Technical Audit`

- Main warning about technical entropy remains valid.
- File sizes and architecture state are partly outdated because repositories/models/RLS have improved, but large files still exist.

## Information In Notion But Not Fully In Code

- Full recurring booking UX and exception handling.
- Real external calendar sync.
- Push notification delivery with APNs/FCM/Edge Functions.
- Smart notification timing, quiet hours depth, snooze/grouping/frequency limits.
- Public profile QR code.
- Closure dates.
- Intake forms.
- Reviews system with client submissions.
- Portfolio item table and upload workflow beyond profile JSON/gallery fields.
- Pay-now/Stripe links.
- Full account deletion purge process.
- 2FA, biometric lock, certificate pinning.
- Offline mode/queued writes.
- Advanced analytics and AI assistant.

## Information In Code But Not Fully Reflected In Notion

- Current neutral grey UI palette.
- Glass pill bottom navigation with five tabs including Tasks.
- Money screen with paid/unpaid/expenses/profit/weekly target comparisons.
- Live `expenses` table and RLS.
- Task checklist item system.
- Booking request triage and confirmation implementation.
- Public profile route and request form implementation.
- Calendar sync placeholder plus ICS export.
- Privacy export and deletion request repository.
- Demo data seeding.
- GitHub remote and active commit history.
- Supabase RLS now enabled on current public tables.

## Recommended Notion Updates

1. Update `Current Sprint` to reflect the true current state from `docs/CurrentState.md`.
2. Update `Database Schema` from `docs/DatabaseRules.md` and `supabase/schema_contract.sql`.
3. Update `UI Design System v2` or create `UI Design System v3` matching current neutral grey direction.
4. Update `Slate HQ` to remove GoGetter naming and outdated dark UI claim.
5. Add links from Notion HQ to the new `/docs` memory files or copy their content into Notion.
6. Add a Notion decision entry for:
   - Bookings/Money language while preserving appointments/invoices tables.
   - Neutral grey palette.
   - Tasks as bottom-nav tab.
   - Money tracking expansion.
   - Project memory/constitution creation.

## Sync Rule Going Forward

Treat Notion as primary product truth unless code has already clearly superseded it.

When code supersedes Notion:

- Record the decision.
- Update Notion within the same work cycle or add it to `NotionSyncReport.md`.
- Do not let stale Notion specs silently contradict live product behavior.

When Notion proposes future features:

- Check `SlateConstitution.md`.
- Check whether the feature improves the V1 operating loop.
- Avoid implementing V2 ideas early unless the user explicitly changes scope.
