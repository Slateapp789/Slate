# Slate Decisions Log

Last updated: 2026-07-15

This log consolidates Notion decisions, Git history, and codebase reality.

## May 2026 - Slate Is Focused On Solo Appointment Businesses

Decision:

Slate serves solo appointment-based service businesses first.

Reasoning:

Notion product vision identifies this ICP as the clearest wedge: users have repeated bookings, clients, payments, notes, and daily admin pain.

Consequences:

- V1 prioritises clients, bookings, money, tasks, dashboard, profile, notifications.
- Projects, team/staff, marketplace, generic productivity, advanced analytics, and AI-first workflows are parked.

## May 2026 - Core Loop Is Client -> Booking -> Work -> Payment -> Repeat

Decision:

Every major feature must support the operating loop.

Reasoning:

This keeps Slate from becoming an everything app.

Consequences:

- Dashboard is an HQ.
- Clients, bookings, tasks, and payments are connected.
- Feature proposals are filtered against daily business utility.

## May 2026 - Do Not Rebuild Slate

Decision:

Continue refactoring and building in place.

Reasoning:

Notion technical audit found Slate is already a functioning early MVP with real architecture, onboarding, business logic, and backend integration.

Consequences:

- Architecture is improved incrementally.
- Existing table names are preserved.
- Major rewrites are avoided unless they remove real risk.

## May 2026 - Supabase + Riverpod + Flutter Remain The Stack

Decision:

Keep Flutter, Riverpod, and Supabase.

Reasoning:

This stack supports mobile-first UX, quick iteration, auth, Postgres, RLS, and future Edge Functions.

Consequences:

- Supabase repositories are the backend boundary.
- Riverpod providers are the app state boundary.
- Flutter remains the only app UI implementation.

## May 2026 - Move Secrets To Dart Defines

Decision:

Supabase URL/key are loaded from `.env` through `--dart-define-from-file=.env`.

Reasoning:

Avoid hardcoded environment values and prepare for separate environments.

Consequences:

- `.env` is not committed.
- `.env.example` documents required values.
- Client publishable key is accepted in app bundle; service-role key is forbidden.

## May 2026 - RLS Is Mandatory

Decision:

All workspace-owned tables should have RLS.

Reasoning:

Application bugs must not expose cross-workspace data.

Consequences:

- `supabase/rls_policies.sql` was added.
- Live tables now have RLS enabled.
- Remaining work is policy cleanup/performance, not basic RLS enablement.

## May 2026 - User-Facing Language Changed From Appointments/Invoices To Bookings/Money

Decision:

Use Bookings and Money in product language while preserving `appointments` and `invoices` backend names.

Reasoning:

Bookings/Money are more natural for solo service users. Renaming live DB tables would add risk without enough benefit.

Consequences:

- UI says Bookings and Money.
- Internal code still contains appointment/invoice names.
- Docs must explicitly explain this translation.

## May 2026 - Tasks Need Deliberate Completion

Decision:

Avoid one-tap accidental task completion.

Reasoning:

Tasks can be business-critical. Completion should be intentional.

Consequences:

- Task rows open detail/actions.
- Completion can happen through sheet/action/swipe.
- Checklists and reminders were added.

## May 2026 - Bottom Nav Must Include Tasks

Decision:

Tasks became a first-class bottom-nav tab.

Reasoning:

Users should not have to scroll Dashboard to reach daily tasks.

Consequences:

- Main tabs are Home, Clients, Bookings, Money, Tasks.
- FAB remains for creation actions.

## May 2026 - UI Moved Through Several Theme Experiments

Decision:

Final current direction is neutral northbound greys with glass navigation.

Reasoning:

Pure dark was too harsh; pastel was too light; green-tinted grey felt wrong. Current palette uses soft grey hierarchy and premium neutral surfaces.

Consequences:

- `AppColors` are light neutral greys.
- Some legacy token names remain.
- UI design system needs this documented so future work does not drift.

## May 2026 - Public Profile V1 Is Request Booking, Not Full Slot Selection

Decision:

Public profile ships with static profile/service information and manual booking request.

Reasoning:

Full public slot-selection requires availability engine, conflict detection, confirmations, and more failure states.

Consequences:

- `/p/:handle` exists.
- Booking requests are stored and triaged in-app.
- Owner confirms manually.

## May 2026 - Calendar Sync Starts As A Contained Integration

Decision:

Calendar sync is represented by a contained screen/state and ICS export, not scattered booking logic.

Reasoning:

Avoid premature deep integration while still providing export utility.

Consequences:

- `CalendarSyncScreen`, `CalendarSyncRepository`, `calendar_sync_accounts`, and `buildSlateIcs`.
- True external provider sync remains future work.

## 2026-05-30 - Foundation Hardening

Decision:

Repository layer, schema contract, RLS docs, env setup, tests, and Git baseline were introduced before heavy feature expansion.

Reasoning:

The user explicitly paused feature expansion to strengthen the foundation.

Consequences:

- GitHub remote is connected.
- Commits and pushes happen regularly.
- `docs/foundation.md`, `docs/security.md`, `supabase/schema_contract.sql`, and `supabase/rls_policies.sql` exist.

## 2026-05-30 - Major UX Passes

Decision:

Dashboard, core layouts, tasks, bookings, and CRM were elevated with stronger UX.

Reasoning:

The app was functional but felt too generic/blocky.

Consequences:

- Dashboard was reorganized around revenue, pulse, schedule, tasks.
- Tasks gained templates, reminders, checklists, detail sheets.
- Bookings gained calendar, next booking, location, custom services, inline client creation, edit flow.
- CRM was expanded, then simplified after user feedback.

## 2026-05-31 - Money Tracking Expansion

Decision:

Money should track paid, unpaid, expenses, weekly target, and comparisons.

Reasoning:

The user compared against an older prototype and identified current Money as insufficient.

Consequences:

- `expenses` table/model/repository/provider added.
- Money screen tracks paid, unpaid, expenses, profit, target progress, comparisons.
- Weekly target derives from monthly onboarding/settings target.

## 2026-05-31 - Project Memory Created

Decision:

Create durable `/docs` memory for product, architecture, database, UI, current state, roadmap, Notion sync, and constitution.

Reasoning:

Prevent loss of project knowledge between threads.

Consequences:

- Future feature work should start from these docs.
- Notion remains product truth unless code has clearly superseded it.

## 2026-07-07 - UI Refounded Around Whitespace First

Decision:

Workloop's visual system should use whitespace, typography, alignment, and subtle dividers as the default grouping tools. Cards and heavy surfaces should become exceptions, not the default layout primitive.

Reasoning:

Real-device review showed that even after polish, the app still felt too boxed, too card-heavy, and too visually equal-weighted for the premium Apple/Linear/Notion-inspired product target.

Consequences:

- Shared UI primitives now include token-aware list rows and filter chips.
- Header stats should read as inline metrics rather than boxed mini cards.
- Activity feeds, clients, notes, bookings, tasks, and money summaries should prefer row/divider layouts.
- Lime is the active/accent system; module colours should be secondary semantic hints only.
- A light/dark token foundation exists, but full dark mode remains gated on migrating static `AppColors` usage.

## 2026-07-07 - Workloop Primitives Become Canonical

Decision:

Use `Workloop*` as the canonical screen-facing UI primitive layer for the final minimal premium system while keeping existing `Slate*` classes as compatibility foundations.

Reasoning:

The product needs one durable UI vocabulary across primary screens, bottom navigation, filters, metrics, rows, empty states, and actions. Renaming the screen-facing layer to Workloop makes the design system explicit without rewriting the app architecture or changing workflows.

Consequences:

- `lib/shared/widgets/slate_ui.dart` now exposes `WorkloopPage`, `WorkloopPageHeader`, `WorkloopMetricItem`, `WorkloopListRow`, `WorkloopSegmentedControl`, `WorkloopBottomNav`, `WorkloopFAB`, and related primitives.
- Primary screens now reference the canonical primitives for shared UI patterns.
- Locally hand-built segmented controls in Bookings and Settings have been replaced by `WorkloopSegmentedControl`.
- Dark mode remains staged, not enabled, until local static-colour widgets are migrated.

## 2026-07-15 - Primary Navigation Reduced To Four Destinations

Decision:

Use Home, Clients, Bookings, and More as the four bottom-navigation destinations. Move Money, Tasks, Notes, Profile, and Settings into More, remove the global floating create action, and place creation at the top of each create-capable feature.

Reasoning:

The six-destination navigation plus detached floating action was visually crowded and made creation feel disconnected from its feature context. A four-item navigation keeps the operating core legible while More preserves one-tap access to secondary modules. Feature-local creation makes the destination and resulting workflow unambiguous.

Consequences:

- Money, Tasks, and Notes retain their full existing screens and deep links, with More highlighted in the bottom navigation.
- Clients, Bookings, Money, Tasks, and Notes use the shared compact top action pattern.
- Dashboard provides minimal Tasks and Notes shortcuts so frequent capture and follow-up remain close at hand.
- No database, repository, provider, or package changes are required.

## 2026-07-15 - Dashboard Prioritises Calm Daily Awareness

Decision:

Order the dashboard around the owner's day rather than large performance figures: Today first, an optional and softly worded Worth a look section, compact Money and utility access, then Coming up and Recent activity.

Reasoning:

The dashboard should clarify the day without creating anxiety. Large financial heroes, urgency language, warning colours, long lists, and repeated module previews increase cognitive load even when the underlying information is useful.

Consequences:

- Worth a look is hidden when empty and capped at two neutral rows.
- The dashboard does not surface alarming totals, red badges, or labels such as urgent.
- Today and Coming up do not duplicate bookings, and Coming up is capped at three.
- Money remains informative but visually subordinate to the day's work.
- Every actionable row opens its booking detail or owning feature.

## 2026-07-16 - Keyboard Dismissal Is App-Wide Interaction Behaviour

Decision:

Override Flutter's mobile tap-outside editing intent once at the app boundary so tapping outside any active text field dismisses the keyboard, while tapping within the field preserves focus.

Reasoning:

Search, forms, notes, tasks, bookings, settings, and onboarding should all respond consistently. Screen-specific unfocus handlers are easy to miss and make a basic mobile interaction feel unreliable.

Consequences:

- All current and future editable fields inherit the same tap-away behaviour without feature-level wiring.
- Existing field tap regions remain authoritative, so selection, cursor movement, and editing inside a field are preserved.
- Widget tests protect both outside dismissal and inside focus retention.

## 2026-07-16 - Client Portfolio Uses Three Calm Views

Decision:

Keep All, Active, and Leads as the permanent client-list views, ordered from broadest to most specific. Present them as one bottom-navigation-inspired pill control and allow horizontal screen swipes to move between adjacent views.

Reasoning:

These three views answer distinct daily questions without turning the client screen into a CRM dashboard. Inactive contacts still need to remain discoverable, but they do not justify a fourth permanent destination for most solo operators.

Consequences:

- All contains every contact, Active contains only contacts explicitly marked active, and Leads contains contacts marked as leads.
- Inactive contacts remain accessible through All and search.
- Left and right swipes change one adjacent view at a time, while short incidental horizontal movements do nothing.
- The selector shares the floating glass surface, draggable animated capsule, stepped haptics, restrained accent, and rounded geometry of the main bottom navigation.

## 2026-07-16 - Inactive Becomes A First-Class Client View

Decision:

Supersede the three-view client portfolio with All, Active, Leads, and Inactive. Keep Inactive visually neutral and make it the final adjacent destination.

Reasoning:

Inactive is already an intentional, user-maintained client status rather than an inferred segment. Giving it a dedicated view makes paused relationships reliably retrievable and keeps Active semantically accurate.

Consequences:

- The draggable selector and full-screen swipe order are All, Active, Leads, then Inactive.
- Changing views returns the screen to the top instead of retaining an irrelevant position from the previous list.
- Empty views explain their category calmly, while active searches use search-specific no-results guidance.
- Inactive rows receive a quiet text marker inside All without warning colours or attention styling.

## 2026-07-16 - Client Detail Becomes A Relationship Workspace

Decision:

Organise client detail around the next booking, relationship context, calm follow-up signals, and short recent activity. Keep bookings, money, and tasks as linked views backed by their existing repositories rather than duplicating client-only records.

Reasoning:

A long contact-details card followed by repeated module histories gives every field equal weight and hides what helps the owner act. The client workspace should answer who this is, what happens next, and whether a small follow-up is useful without behaving like a dense CRM dashboard.

Consequences:

- The overview caps recent activity and progressively discloses secondary contact metadata.
- New bookings and payments begin with the current client selected.
- Client tasks remain canonical Tasks records through `contact_id`, and the client view provides an explicit route to the full Tasks workspace.
- Financial summaries use received and remaining amounts, including partial payments, with neutral language and colour.
- The workspace reuses the dashboard backdrop, typography, spacing, dividers, and draggable capsule navigation.

## 2026-07-16 - Client Data Entry Has One Canonical Form

Decision:

Use one shared mobile client form for both creation and editing. Organise it as Contact information, Client settings, Booking address, Client notes, and progressively disclosed Additional information.

Reasoning:

Add and Edit previously used separate field components, labels, spacing, and selection controls, which allowed validation and visual behaviour to drift. Familiar CRM terminology is useful, but Workloop should retain only the fields that support the client, booking, work, payment, and repeat workflow.

Consequences:

- Add and Edit now render the same input controls, status explanations, contact preferences, optional metadata, and field ordering.
- Client name is required and optional email addresses are validated before writes.
- Matching phone numbers and email addresses are checked against existing clients to reduce accidental duplicates without requiring schema changes.
- Lead source, tags, and birthday remain optional and collapsed by default unless an edited client already contains them.
- Important notes remain distinct because they are surfaced prominently in the relationship workspace.
- The change reuses the existing contacts schema, repository, providers, and security model.

## 2026-07-16 - Booking Address Search Uses a Trusted Server Boundary

Decision:

Use Google Places API (New) for client booking-address autocomplete through an authenticated Supabase Edge Function, rather than placing a Google web-service key in Flutter.

Reasoning:

Address entry should be fast and reliable on both iOS and future Android builds. A shared server boundary keeps provider credentials out of the downloadable app, centralises UK/language restrictions and field masks, and gives Workloop one integration to secure and monitor.

Consequences:

- Add and Edit Client share the same debounced Booking address search with manual entry fallback.
- Address entry deliberately remains a single-field workflow. Users start with the first line of an address for dependable suggestions; a postcode or any other manually typed location can be saved as entered. Workloop does not attempt a fragile postcode-to-property refinement flow.
- Suggestions remain interactive while being selected or scrolled, and a chosen result populates the field before canonical Place Details resolution.
- Scrolling the surrounding client form no longer clears suggestions; results close after selection or through their explicit Close action, avoiding accidental dismissal during one-handed repositioning.
- Saved booking addresses use standards-based Apple Maps and Google Maps direction URLs. The preferred maps app is a non-critical device preference, stored locally rather than adding workspace schema solely for a platform-specific choice.
- The function accepts authenticated users only, validates and limits input, uses Google session tokens, and requests only the minimum suggestion and address fields.
- No database migration is required; the selected formatted address continues to use the existing contact `address` field.
- Google Places billing, API enablement, an API-restricted key, quotas, and a Supabase function secret are required before live suggestions work.
- Coordinates are returned but deliberately not persisted until routing needs justify a contacts schema addition.
- Unit-prefixed input searches both the building and the full text, then keeps
  the typed flat/apartment/unit label when Google only identifies the building.
  This improves subpremise entry without adding another provider or schema.
- Public legal pages must include the Google Maps terms/privacy references before release.

## 2026-07-19 - Bookings Uses One Calm Connected Workspace

Decision:

Present Bookings as a calm Schedule / Requests workspace with explicit List and Calendar modes. Reuse the same textured backdrop, typography, spacing, segmented controls, compact header action, and form surfaces established by Home and Clients while preserving the existing appointment repository and workflows.

Reasoning:

The existing booking system already supports the important operating loop, but duplicated mode controls, dashboard-like metrics, and locally styled forms made it feel like a separate product. A solo operator primarily needs to see the next commitment, move between a chronological list and calendar, and create or update work without losing client, payment, or task context.

Consequences:

- Schedule and Requests remain first-class but visually restrained destinations; List and Calendar are explicit schedule views rather than duplicate header actions.
- Today, Upcoming, and Past use the shared segmented-control behaviour and remain swipeable through the existing tab view.
- Calendar creation carries the selected day into New booking and adds a direct Today shortcut.
- New and Edit booking use the same backdrop, header hierarchy, input treatment, and keyboard dismissal conventions as client data entry.
- Selecting a client can reuse that client's saved booking address, and saved physical booking locations use the shared Maps preference for directions.
- Dashboard, client detail, booking detail, Money, and Tasks continue to share canonical records and providers; no booking-only duplicate data or database migration is introduced.

## 2026-07-19 - Selection Lists Use One Mobile Picker Pattern

Decision:

Replace Flutter's native dropdown menus with a shared Workloop picker sheet for all in-app selection fields.

Reasoning:

The platform dropdown expands into a visually heavy, desktop-style menu that does not match Workloop's calm mobile design language. A bottom sheet keeps choices within thumb reach, supports long business lists, and gives every workflow the same interaction and selection hierarchy.

Consequences:

- Short option sets use a compact rounded sheet with a clear selected state.
- Longer sets, including clients, add search automatically and remain independently scrollable.
- Picker fields, rows, typography, spacing, haptics, and dismissal behaviour come from one shared component.
- Booking, onboarding, public-profile, task, and payment selectors now use the same interaction.
- No package, database, repository, or navigation change is introduced.

## 2026-07-19 - Booking Guardrails Inform Without Blocking Intent

Decision:

Reuse the authenticated Google Places booking-address field across client and booking capture, protect changed client and booking drafts before navigation, and treat saved working hours as guidance rather than an absolute booking restriction.

Reasoning:

Physical work needs the same dependable address capture wherever it is created. Accidental navigation should not lose customer or schedule edits, while a solo operator must still be able to accept legitimate early, late, or exceptional work without changing business settings first.

Consequences:

- New and edited physical bookings use the same address search and manual fallback as client booking addresses.
- Leaving a changed New/Edit Client or New/Edit Booking screen offers Save, Discard changes, or Keep editing.
- A booking outside saved working hours explains the exception and can continue through an explicit Book anyway action.
- Appointment overlap checks remain mandatory and cannot be bypassed by the working-hours confirmation.
- Existing repositories, Supabase security, routes, schema, and booking records remain unchanged.

## 2026-07-19 - Money Uses One Calm Ledger Hierarchy

Decision:

Present Money as a quiet period overview followed by target progress, money to collect, and one chronological activity ledger. Use a dedicated shared form vocabulary for income and expenses while preserving the existing payment and expense data model.

Reasoning:

The previous screen exposed the right capabilities but stacked several competing cards, metric tiles, pills, status colours, and locally styled forms. A solo operator needs to understand money received, money spent, what remains to collect, and recent movement without reading an accounting dashboard.

Consequences:

- Received is the primary period figure; Expenses and Net are supporting metrics rather than competing cards.
- Week, Month, and Custom use the canonical Workloop segmented control.
- Weekly target progress is a slim section with secondary comparison text.
- Empty expense categories are hidden, and income/expense activity remains visible even when one record type is empty.
- Collection rows retain due and overdue meaning with restrained styling rather than alarm-heavy surfaces.
- Income and expense creation/editing use shared Money fields and protect changed drafts before navigation.
- Existing Riverpod providers, repositories, Supabase tables, RLS, booking links, client links, and CRUD capabilities remain unchanged.

## 2026-07-19 - Money Separates Income, Outgoing, and Outstanding

Decision:

Use a first-class three-section navigation bar inside Money. Income, Outgoing, and Outstanding each own their summary, supporting information, empty state, and activity list.

Reasoning:

A combined money overview remained visually calm but required users to interpret received money, spending, and collection work in one long page. These are three distinct questions with different actions and time horizons. Separating them improves scanning while keeping all three one gesture away.

Consequences:

- Income shows period-filtered received money, weekly target progress, and received-income history.
- Outgoing shows period-filtered spending, category distribution, and expense history.
- Outstanding shows all currently uncollected money, split into Upcoming and Past due without applying an arbitrary period filter.
- Dashboard follow-up links open Money with Outstanding selected.
- The large navigation capsule represents peer Money destinations; the smaller Week / Month / Custom control remains a local filter inside Income and Outgoing.
- Add/Edit Income, Add/Edit Expense, repository behavior, Supabase schema, RLS, client links, and booking links are unchanged.

## 2026-07-19 - Money Uses Plain Business Language

Decision:

Name the three Money destinations Made, Spent, and Owed. Each destination answers one question with one primary figure. Keep payment timing on individual owed rows instead of presenting Upcoming and Past due as competing summary totals.

Reasoning:

Income, Outgoing, and Outstanding describe accounting states rather than the questions a solo business owner naturally asks. Made, Spent, and Owed are faster to understand and reduce the overview to the three figures that matter.

Consequences:

- Made is sourced from received payment records in the selected period.
- Spent is sourced from expense records in the selected period.
- Owed is the remaining balance across every unpaid payment, including future and overdue payments.
- Weekly and monthly views show the matching income target, percentage complete, and amount left; custom ranges do not show a misleading target.
- Due and overdue status remains visible on individual payment rows for action context.

## 2026-07-19 - Tasks Use Dedicated Working Screens

Decision:

Present Tasks as Now, Later, and Done. Open task detail, creation, and editing as dedicated screens instead of temporary sheets.

Reasoning:

A task can carry client context, timing, reminders, priority, a checklist, and deliberate completion actions. Full screens give that work the same stable hierarchy as Clients and Bookings, while the task list can remain a lightweight scanning surface.

Consequences:

- Now groups Overdue, Today, and Anytime tasks; Later contains future work; Done contains completed work.
- Tapping a task opens one canonical detail screen with checklist and completion actions.
- New and Edit Task use the same page header, textured backdrop, spacing rhythm, top save action, and progressive disclosure as Client and Booking forms.
- Changed task drafts offer Save, Discard, or Keep editing before leaving.
- Task repositories, providers, reminders, linked clients, checklists, deliberate completion, swipe actions, and Supabase records remain unchanged.
