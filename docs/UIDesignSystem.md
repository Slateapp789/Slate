# Workloop UI Design System

Last updated: 2026-08-10

## Workloop Studio — Current Contract

Workloop Studio is the active app-wide visual system. It supersedes Loopline,
the graphite-frame direction, lime-led navigation, and the previous Instrument
Sans geometry. Those systems remain documented below only as product history.

The interface should feel calm, capable and crafted: a mobile business
operating system with clear next actions, not a generic SaaS dashboard. Use
progressive disclosure and real operational state. Graphics must orient the
owner or explain progress; never invent analytics or decorate empty space.

### Colour

Source: `lib/core/theme/app_theme.dart`.

| Role | Light | Dark |
|---|---:|---:|
| Canvas | `#F6F4EF` | `#111318` |
| Surface | `#FFFFFF` | `#1C2027` |
| Raised | `#F0EEF8` | `#252A33` |
| Interactive | `#ECEFF3` | `#2E343F` |
| Divider | `#DDE2E8` | `#3A414D` |
| Strong divider | `#C7CED8` | `#545D6B` |
| Primary text | `#172033` | `#F6F7FB` |
| Secondary text | `#5F6B7A` | `#C5CAD3` |
| Tertiary text | `#7C8795` | `#9CA4B0` |
| Primary indigo | `#4F46E5` | `#9496E8` |
| Pressed indigo | `#4038C9` | `#7D80D4` |
| Indigo tint | `#E9E8FF` | `#2A2D3E` |
| Relationship teal | `#168F83` | `#5FD6C5` |

Module signals are intentionally limited: Home indigo, Clients teal, Bookings
violet, Money amber, Tasks coral, and Notes sky. Use them for identity, a
progress marker, a compact icon field or a quiet tinted surface—not for body
copy or entire screens.

### Typography

Manrope Variable is bundled locally under the OFL. No screen depends on a
network font.

- Display: 34/40, w700.
- Metric: 30/34, w700 with tabular figures where useful.
- Page title: 26/32, w700.
- Section title: 19/24, w600.
- Control title: 16/21, w600.
- Body: 15/22, w400.
- Supporting body: 13/19, w400.
- Labels: 14/18, w600; compact labels 11/14, w600.

Avoid oversized text inside controls and cards. Use weight 700 only for page,
display and metric hierarchy. Keep labels direct and sentence case.

### Spacing, Shape and Depth

- Page inset: 18.
- Core spacing: 4, 8, 12, 16, 20, 24, 32.
- Radii: 8, 10, 14, 18, 24; sheets use 28.
- Capsule geometry is reserved for compact statuses, filters and progress.
- Main buttons and fields are 50–52 points high and use radius 14.
- Primary content surfaces use radius 14–24 according to hierarchy.
- Shadows are soft and sparse. Use them for the floating navigation dock,
  command surfaces and raised launchers, not every list row.

### Composition

- Home opens with a deep indigo command area containing greeting, date, next
  booking and its real schedule path. Supporting content overlaps the command
  area visually but remains scannable and scroll-safe.
- Clients is relationship-led: title, create and search use the same open root
  composition as the other workspaces, followed by compact portfolio filters
  and clear client rows.
- Bookings is time-led and schedule-first. Today, Upcoming, Past and Calendar
  form one full-width navigation rail; there is no redundant List label or
  competing display-mode control. Booking Requests remains owner-local through
  a counted inbox action in the header, which opens the
  dedicated Active/New/Closed triage workspace. The seven-day load graphic is
  intentionally absent because it delayed the actionable booking list without
  changing the user's next decision.
  Calendar mode is month-led: an open seven-column grid, circular
  selected/today states, restrained booking dots, swipe or button month
  navigation, and a selected-day agenda with a visible time rail. List and
  Calendar use one booking-record row for time, status, client, work, location,
  price and navigation; only the surrounding temporal context changes. It
  should borrow the clarity of a native calendar without copying Apple styling
  or replacing Workloop's module colour and typography.
- Money is outcome-led: Made, Spent and Owed use the shared root composition;
  totals, cash movement and target progress use real values and native Flutter
  graphics.
- Tools is a launcher, not a dashboard. Money, Tasks and Notes have expressive
  module surfaces with live status, followed by direct quick-capture actions.
- Notifications is one chronological list with quiet Today/Earlier anchors.
  There are no redundant All/Unread sections and no card stack.
- Settings uses calm grouped rows. Forms use one field system with visible
  focus, semantic error states and draft protections unchanged.

### Components and Navigation

- `WorkloopTexturedBackdrop` supplies the restrained porcelain/midnight canvas
  fields. Do not add local background art.
- `WorkloopListRow`, `SlateFeatureHeader`, `WorkloopNavigationControl`,
  `WorkloopBottomNav`, `SlateButton`, shared fields, empty states and sheets are
  the canonical primitives.
- The root navigation is a floating five-destination dock: Today, Clients,
  Work, Money and Business. Its neutral outline remains visually quiet; a
  two-pixel indigo line, accent icon and primary label identify the active
  destination without a filled selection block. The dock respects safe areas
  and content always reserves clearance beneath it.
- Peer navigation has one renderer: an open text rail with a two-pixel indigo
  active line. Compact rails may reduce height, but must not introduce a second
  selected-state language. Feature-level creation and
  utility controls may be circular; explicit save, confirmation and destructive
  decisions remain labelled rounded rectangles.

### Motion and Graphics

- Motion timings are 140, 200 and 280 ms; navigation is 220 ms and deliberate
  celebrations may use 440 ms.
- All presentation motion respects reduced-motion settings and settles to the
  same final state.
- The operating-loop mark, schedule path, progress arc and compact bar strips
  are native Flutter drawings. They use product or real business state, remain
  readable in both appearances and do not intercept interaction.
- Home's Today surface is horizontally browsable when several bookings remain,
  with position feedback and reduced-motion-safe transitions.
- The schedule path uses a small quiet current-time tick and a larger selected
  booking node. Swiping the Today carousel moves that node to the selected
  booking and settles with one restrained bounce; do not loop or decorate the
  transition. Reduced Motion renders the final node immediately.
- Prefer one purposeful graphic moment per major surface over dense charts.

### Accessibility and Proof

- Touch targets remain at least 44 points.
- Primary and secondary text and primary actions meet normal-text contrast.
  Tertiary roles are supporting only; disabled roles never carry essential
  information.
- Focus, error and selected states are never communicated by colour alone.
- Every visual-system change must pass analyzer, behavior tests, protected
  light/dark goldens, responsive/text-scale matrices, an iOS profile build and
  manual representative-screen review before its golden baseline is accepted.

## Retired Loopline Documentation (Historical)

Everything below records superseded design decisions and is not an
implementation target.

## Loopline Design Intent

Workloop should feel premium, calm, modern, mobile-first, and high-trust. It is a working tool for people running real businesses from their phone.

The retired design direction supported System, Light, and Dark appearance choices
through the **Loopline interface**. It uses one soft-square control language,
circle-only utility actions, status-only capsules, line-led peer navigation and
an edge-to-edge system bar. Light uses a clean mineral canvas, white content
surfaces and confident ink actions. Dark keeps its lifted graphite personality
and uses the brand lime for its primary actions.

The current visual principle is **editorial utility with graphic moments**:
most screens rely on typography, spacing, and divider-led lists; real business
data earns a restrained native graphic only when it improves orientation.

## Current Colour System

Source: `lib/core/theme/app_theme.dart`

Canonical semantic roles:

| Role | Light | Dark |
|---|---:|---:|
| Background | `#F4F5F2` | `#151A16` |
| Surface | `#FFFFFF` | `#1C231D` |
| Raised surface | `#EBEDE9` | `#252E26` |
| Interactive surface | `#E5E9E3` | `#2C372D` |
| Divider | `#D6DBD4` | `#3E4B3F` |
| Strong divider | `#B6BDB4` | `#5E705F` |
| Primary text | `#121511` | `#F4F7F3` |
| Secondary text | `#464C45` | `#CDD5CC` |
| Tertiary text | `#626A60` | `#A6B1A5` |
| Disabled text | `#7D857A` | `#899588` |
| Primary action | `#171B15` | `#C1FF72` |
| On primary action | `#F7F9F4` | `#17200D` |
| Focus surface | `#FFFFFF` | `#202820` |
| Text on focus surface | `#11130F` | `#F4F7F3` |
| Muted text on focus surface | `#42463F` | `#CDD5CC` |

Accent:

- Brand accent: `#C1FF72`, sampled from the icon and launch artwork.
- `AppColors.brandAccent`, `AppColors.accentPrimaryStrong`, and
  `AppColors.accentInk` resolve to the exact neon.
  `AppColors.onBrandAccent` is dark `#17200D`.
- Reserve the brand accent for active position, focus, progress and restrained
  status emphasis. In Light, large primary actions use ink so lime remains a
  recognisable signal rather than becoming the page background colour.
- Light uses deep `#355A0C` accent ink for small text, thin icons, and focus
  outlines; the exact neon remains the fill for primary controls and a small
  marker for selected navigation.
- In Light, neon-filled controls use a one-pixel `#A3CD6E` semantic accent
  border. This applies to primary buttons, root create actions, floating
  actions, and genuinely accent-filled chips so the fill remains defined
  without a heavy outline. Neutral cards, navigation and focus surfaces keep
  neutral dividers; Dark retains its existing accent edges.
- Legacy green/violet aliases remain in code for compatibility and should be gradually renamed only when safe.

Accessibility refinement (updated 2026-07-31):

- Light primary controls use an opaque ink fill; Dark primary controls use the
  exact brand lime. Navigation and peer controls use a two-pixel lime position
  line so they do not compete with the screen action.
- Content on a neon fill uses dark `#17200D`.
- Neon is not used as body text; it remains an action, selection, focus, and
  restrained status signal.
- Essential text never uses the disabled role, and tertiary copy remains readable against the page canvas.
- Primary, secondary, tertiary, and accent text roles meet WCAG AA normal-text
  contrast against both canvases. Disabled text is reserved for unavailable
  controls, never essential information.
- Button content uses dark `#17200D` on the neon fill. Active-navigation
  content uses semantic ink plus a small lime marker. Light-mode module icons
  use darker adaptive foregrounds rather than the pastel Dark variants.

Semantic:

- Success: muted green (`AppColors.statusSuccess`), calmer than the primary accent.
- Warning: muted warm grey.
- Error: muted red.

Rule:

Avoid strong colour noise. Neon means "primary action or active place"; success, warning, and error colours communicate state and should not compete with primary actions.

## Typography

Font:

- Bundled Instrument Sans variable font with the OFL licence included in
  `assets/fonts`.

Current text scale:

- Display large: 32, w600.
- Display medium: 26, w600.
- Headline large: 22, w600.
- Headline medium: 18, w600.
- Title large: 16, w600.
- Title medium: 14, w500.
- Body large: 15, w400.
- Body medium: 13, w400.
- Label large: 12, w500.
- Label small: 10, w600.

Rules:

- Use only restrained negative tracking on display type; body and control copy remain neutral.
- Cap interface typography at w600. Use size, spacing, and colour before adding
  weight.
- Do not use hero-scale type inside compact cards or controls.
- Prioritise scannable hierarchy.
- Keep labels short and practical.

## Spacing

Source: `AppSpacing`.

- `xxs`: 4
- `xs`: 8
- `sm`: 12
- `md`: 16
- `lg`: 20
- `xl`: 24
- `xxl`: 32
- `section`: 24
- `pageX`: 18
- `screenTop`: 12 inside the platform `SafeArea`
- `minTouch`: 44
- `bottomNavHeight`: 72
- `bottomNavOffset`: 12
- `bottomNavBreathingRoom`: 22

Rules:

- Shell page headers begin at `safeArea.top + screenTop`.
- Use 12–16 between related components and 20–24 between major sections.
- Shell scrolling content uses `shellBottomClearance(context)` so the final
  row clears the dock, its offset, the real device safe area and 22 points of
  breathing room.
- Mobile screens should breathe without becoming sparse.
- Use fewer stacked boxes where typography and spacing can carry hierarchy.
- Keep primary actions within comfortable thumb reach.

## Radius

Source: `AppRadius`.

- `xs`: 4
- `sm`: 8
- `md`: 10
- `lg`: 16
- `xl`: 22
- `capsule`: 999

Rules:

- Repeated cards should generally stay at `md` or `lg`.
- General controls use `sm` or `md`; large focus surfaces use `lg` or `xl`.
- Capsules are reserved for true status labels and slim progress tracks.
- Icon-only utilities are circular. Avatars and unread dots may also be round.
- Navigation, filters and ordinary buttons must not use capsule geometry.
- Avoid nested card-on-card compositions unless the inner card is a true item.

## Shadows and Depth

Source: `AppShadows`.

Current depth is soft and low contrast.

Rules:

- Use shadow sparingly.
- Prefer surface contrast and spacing over heavy elevation.
- Navigation and sheets may use restrained blur, but their fill and selected states must remain opaque enough to preserve contrast.

## Components

Shared UI primitives live in:

`lib/shared/widgets/slate_ui.dart`

Core components:

- `SlateSurface`
- `SlateGlassSurface`
- `SlateButton`
- `SlateSheetFrame`
- `SlateLoadingBlock`
- `WorkloopTopAction`
- `WorkloopSectionHeader`
- `WorkloopEmptyState`
- `WorkloopRouteHeader`
- `WorkloopInteractiveWorkspaceStack`

Rules:

- New repeated UI should use shared primitives.
- Do not create random one-off surface styles.
- If a pattern repeats across two features, promote it into shared widgets.
- Buttons should use clear labels and appropriate icons.
- Create-capable feature headers use one circular `WorkloopTopAction`. Its
  visible symbol is `+`; its feature-specific label remains mandatory in
  semantics. Form submission and ambiguous workflow actions stay visibly
  labelled.
- Standard section headings use sentence-case title hierarchy. Use the quiet
  section variant only for dense chronological groups and counts; headings do
  not need decorative lime bars.
- Root headers are typographic and open. Pushed routes use a quiet neutral back
  control without a decorative header rule.
- Pushed screens use `WorkloopRouteHeader`; protected editors pass their
  existing guarded back callback and save action into that primitive.
- Empty states are inline by default. Contained empty states are reserved for
  places where the boundary itself communicates useful context.
- A root empty state must not duplicate the labelled primary action already
  present in its feature header.
- Use `SlateSheetFrame` for bottom sheets.

## Cards and Layout

Current app uses a mix of:

- One focused operational surface where the next decision needs a boundary.
- List rows.
- Section bands.
- Detail sheets.
- Summary surfaces.

Floating navigation, peer navigation, filters, and focus summaries use neutral
semantic layers. Large dark structural panels are not used in Light mode.

Rules:

- Avoid generic stacked boxes.
- Use list rows for dense operational records.
- Use hero cards only for high-level summary or next action.
- Use detail sheets for context and fast actions.
- Keep one primary action per screen or sheet.

## Graphics and Data Visuals

- A graphic must clarify a real state, relationship, rhythm, or next action.
- Prefer native vector drawing and existing data over bitmap decoration or
  invented trends.
- Keep the default composition to one visual, up to three facts, and one action.
- Home may use the real schedule path; Money may use target/category progress;
  Bookings may use calendar rhythm; onboarding may explain the real Client to
  Booking to Work to Payment to Repeat operating loop. Notifications, Tasks,
  Notes, and Settings remain list-led unless a visual genuinely reduces mental
  effort.
- Never make a calm operating screen feel like a generic analytics dashboard.

## Forms

Current forms use standard `TextField`, date/time pickers, chips, sheets, and domain-specific selectors.

Rules:

- New and edit flows should be as close to identical as possible.
- Use progressive disclosure for optional fields.
- Use client/service pickers with inline creation where operationally useful.
- Save buttons should be explicit when editing durable data.
- Avoid accidental destructive or completion actions.

## Navigation

Current main navigation:

- Docked edge-to-edge bottom system bar with one top divider.
- Labels remain visible under icons and selection uses a short lime line.
- Tabs: Home, Clients, Bookings, Tools.
- Tools contains Money, Tasks, and Notes as equal full-width workspace rows.
- Tools also provides direct Record money, New task, and New note capture
  actions before the workspace rows. Each row shows a small live orientation
  signal such as money to collect, open tasks, or saved notes.
- Profile and Settings use compact, direct controls in the Home header rather
  than occupying tool rows or permanent bottom-navigation destinations.
- Create-capable feature screens use one labelled top-right action instead of a
  detached global floating action.
- Body does not extend behind the bar; content receives a small final inset.
- Peer destinations and compact segmented controls are text-led rows with an
  animated bottom indicator, not rounded rails with sliding pills.

Rules:

- Core modules should remain in bottom nav.
- Detail/create flows can push screens or sheets.
- A short tap in the status/top-edge area returns the visible vertical screen
  to its beginning. The calm, non-interactive top/header zone is deliberately
  forgiving, and all visible vertical layers return together. Interactive
  header controls keep their own tap. All vertical scroll views register
  centrally, including implicit and nested controllers. Actual painted and
  hit-test visibility prevents hidden `PageView` or `TabBarView` children from
  being reset. Retained shell tabs keep independent scroll positions, and deep
  returns use a distance-aware animation capped at 600 milliseconds.
- Clean pushed routes use the native iOS interactive edge swipe and Android
  system back gesture so the previous screen tracks the user's finger and a
  cancelled swipe restores the current page.
- A left-edge swipe uses the route's existing back action. Draft-protected iOS
  editors therefore invoke their existing Save/Discard/Keep editing decision;
  the fallback runs only after pointer-up and must never bypass draft
  protection.
- Money, Tasks, and Notes use a progress-driven retained-workspace transition:
  the current page follows the left-edge drag, the preceding workspace is
  revealed with restrained parallax, and distance or velocity decides whether
  the gesture completes or cancels. Home, Clients, Bookings, and Tools remain
  root destinations.
- On a long list whose rows occupy the top zone after scrolling, the top
  shortcut takes precedence over opening that row. Clients follows this rule.
- Important routes should eventually be represented in GoRouter.

## Interaction Principles

- Completion should be deliberate.
- Destructive actions require confirmation.
- Swipe actions must not accidentally dismiss important business data.
- Back gestures must follow the same validation, saving, and draft-protection
  path as the visible back control.
- Tapping a record should usually open detail/context, not mutate state.
- Use snackbars for lightweight success/failure feedback.

## Animation Principles

Source: `AppMotion`.

- Fast: 160ms.
- Standard: 240ms.
- Deliberate: 360ms.
- Curves: `easeOutCubic`, `easeOutBack`.

Rules:

- Motion should feel calm and premium.
- Animate navigation state, sheet entry, filter/pill transitions, completion affordances, and empty state transitions.
- Programmatic shell changes use one 240ms fade-through with a restrained
  14-point directional offset. The outgoing destination remains mounted until
  the incoming destination is established, so retained state never flashes or
  rebuilds. Each retained destination keeps one stable keyed layer throughout
  every animation phase; transition wrappers must never reparent a feature
  screen or replay one-shot create intents.
- Pushed routes inherit the app theme transition instead of defining local
  animation. Android uses the same restrained fade and horizontal offset;
  iOS keeps the native Cupertino transition so interactive back remains
  finger-tracked and cancellable.
- Reduced-motion users receive an immediate destination change. Navigation
  motion must never delay saving, validation, draft guards, or destructive
  confirmation.
- Local presentation animations must use `AppMotion.responsive(context, ...)`
  or explicitly jump to their stable state when motion is disabled. This
  includes selection, calendar, keyboard-inset, progress, expand/collapse, and
  retained-workspace motion.
- Avoid gimmicky animation that slows business work.

## Current Visual Debt

- Some design tokens still have legacy names (`green`, `violet`) even though the intended role is now `accentPrimary`.
- Large legacy screens still contain local layout containers. Consolidate a
  repeated pattern only when at least two features need it; do not create a
  second component system to remove harmless local structure.
- Legacy `AppColors` call sites use an appearance-aware compatibility bridge;
  touched screens should continue migrating to `WorkloopThemeTokens` rather
  than adding local Light/Dark conditions.
- Both palettes intentionally use one bright accent; future colour experiments
  should be done as a deliberate theme pass, not piecemeal.

## 2026-08-06 Loopline Interface Reset

The canonical interface is now geometry-led rather than card- or pill-led.

- All functional controls use the shared soft-square scale.
- The retired pill radius, `StadiumBorder`, and literal `999` control radii are
  rejected by `test/ui_system_contract_test.dart`.
- `AppRadius.capsule` remains available only for real status labels and slim
  progress tracks.
- Root navigation is a docked system bar. Workspace and segmented navigation
  use stable text rows with a two-pixel lime position line.
- Light primary actions use ink; Dark primary actions preserve the exact brand
  lime. Icon-only utility actions are circular.
- Auth uses an open wordmark and horizontal loopline rather than a framed brand
  card. Tools uses a flat capture grid and divider-led workspace rows. Settings
  and public-profile sections no longer default to stacked cards.
- The real Home schedule path, Money progress and onboarding operating-loop
  visual remain the purposeful graphics. No invented analytics were added.

## 2026-08-08 Command-Centre Polish

- Keep the purple Home Today panel as the daily command surface. Do not add
  unrelated dashboard metrics inside it.
- Use `WorkloopModuleRow` for Money, Tasks and Notes wherever they appear on
  Home or Tools. Module rows use a 44-point tinted icon tile, one shared text
  hierarchy, a chevron and dividers inside one enclosing surface.
- Money target progress belongs in Home's At a glance group. It must be driven
  by real paid-this-month and configured-target values and must not imply
  forecast data.
- Promote Business feed ahead of Coming up so recent business events are
  discoverable without turning Home into an activity dashboard.
- Client, booking and booking-request collections use flat divider-led lists.
  Repeated cards are reserved for genuinely self-contained objects or controls.
- Notes uses the same flat divider-led list grammar beneath quiet Pinned and
  date headers. Individual notes are documents in a collection, not cards.
- Bookings presents Today, Upcoming, Past and Calendar as one navigation rail.
  Selecting Calendar opens the month workspace; selecting a time view returns
  directly to its schedule list without an intermediate List mode decision.
- Calendar date cells use a compact fixed vertical extent. The selected-day
  divider begins immediately after the month grid, with no flexible or
  decorative spacer. Agenda bookings are flat rows aligned to the time rail,
  not tinted rounded cards.
- Shared rows use an 18-point horizontal content inset by default. When a local
  row specifies vertical padding it must also preserve an explicit horizontal
  inset so its leading icon cannot touch the surface edge.
- Bottom navigation keeps a compact floating surface with a 28-point outer
  radius. Active destinations and peer selections use line-led emphasis rather
  than filled pills; buttons retain the shared 14-to-18-point soft-corner scale.

## 2026-07-07 Minimal Refoundation

Workloop's active UI direction is now whitespace-first rather than container-first.

Design rule:

- Typography, spacing, alignment, and subtle dividers should solve grouping before any card or surface is introduced.
- Cards are exceptions for sheets, modal contexts, true controls, and dense framed tools.
- Lists should generally be `Row -> Divider -> Row`, not repeated rounded cards.
- Header stats should read as inline metrics, not boxed dashboard tiles.
- Empty states should be calm inline guidance, not placeholder cards.
- Lime remains the signature accent and should be reserved for primary actions, active navigation, progress, selected state, and important highlights.

Historical implementation changes:

- `WorkloopThemeTokens` defined explicit light and OLED-dark token sets during
  this refoundation.
- Shared primitives in `lib/shared/widgets/slate_ui.dart` include token-aware surfaces, icon buttons, empty states, list rows, and filter chips.
- Main navigation active state uses lime rather than module colours.
- High-traffic screens have started moving from card-heavy rows to divider/list rhythm.

Historical appearance status:

- System, Light, and OLED-aware Dark appearances were available from Settings >
  App appearance.
- This choice and its compatibility bridge were superseded by the
  2026-07-28 dark-only launch decision, then restored on 2026-07-31 with a
  softer Light canvas, persisted System/Light/Dark choice, and expanded
  cross-appearance contrast and responsive coverage.

## 2026-07-07 Final UI System Implementation

Canonical screen-facing primitives now use `Workloop*` names in `lib/shared/widgets/slate_ui.dart`.

Core primitives:

- `WorkloopPage`
- `WorkloopPageHeader`
- `WorkloopMetricRow`
- `WorkloopMetricItem`
- `WorkloopSectionHeader`
- `WorkloopListRow`
- `WorkloopDivider`
- `WorkloopEmptyState`
- `WorkloopPrimaryButton`
- `WorkloopTextButton`
- `WorkloopIconButton`
- `WorkloopSegmentedControl`
- `WorkloopFilterChip`
- `WorkloopBottomNav`
- `WorkloopFAB`
- `WorkloopSurface`

Rules:

- New screen UI should use `Workloop*` primitives first.
- Existing `Slate*` primitives remain as compatibility foundations while older widgets migrate.
- Bottom navigation, FAB, feature headers, header metrics, filters, list rows, empty states, and primary actions should not be reimplemented locally.
- Use `AppSpacing.shellBottomClearance(context)` for the final content inset on
  root and retained workspaces where the floating dock remains visible. Do not
  add it to pushed routes or sheets that do not show the shell navigation.
- `WorkloopSegmentedControl` is the preferred control for two-to-four peer filters or tabs when the content is already managed in the screen.

Current scope:

- Dashboard, Business Feed, Clients, Bookings, Money, Tasks, Notes, Settings, Onboarding, bottom navigation, and global workspace error chrome now reference the canonical primitives where they touch shared system UI.
- Bookings and Settings use the shared segmented control instead of local pill-tab containers.
- This section records the 2026-07-07 implementation. As of 2026-07-31,
  System, Light, and Dark are supported again; new work must continue to use
  semantic theme tokens rather than local colours.
