# Workloop UI Design System

Last updated: 2026-08-03

## Design Intent

Workloop should feel premium, calm, modern, mobile-first, and high-trust. It is a working tool for people running real businesses from their phone.

Current design direction supports System, Light, and Dark appearance choices,
with the exact icon/launch neon as the brand accent. Dark uses slightly lifted
graphite; Light uses a warm stone paper canvas and clean ivory surfaces rather
than pure white or a green-tinted wash.
Both should feel operational and premium: calm layered surfaces, clear
hierarchy, and `#C1FF72` used sparingly so important actions and selected states
are obvious.

## Current Colour System

Source: `lib/core/theme/app_theme.dart`

Canonical semantic roles:

| Role | Light | Dark |
|---|---:|---:|
| Background | `#EEEDE8` | `#151A16` |
| Surface | `#FFFEFA` | `#1C231D` |
| Raised surface | `#F8F7F2` | `#252E26` |
| Interactive surface | `#D9DDD5` | `#2C372D` |
| Divider | `#C6CAC2` | `#3E4B3F` |
| Strong divider | `#929990` | `#5E705F` |
| Primary text | `#171B18` | `#F4F7F3` |
| Secondary text | `#3C443E` | `#CDD5CC` |
| Tertiary text | `#5C655E` | `#A6B1A5` |
| Disabled text | `#7C847E` | `#899588` |

Accent:

- Brand accent: `#C1FF72`, sampled from the icon and launch artwork.
- `AppColors.brandAccent`, `AppColors.accentPrimaryStrong`, and
  `AppColors.accentInk` resolve to the exact neon.
  `AppColors.onBrandAccent` is dark `#17200D`.
- Reserve the brand accent for the main CTA, active navigation, selection, focus, and restrained status emphasis.
- Light uses deep `#355A0C` accent ink for small text, thin icons, and focus
  outlines; the exact neon remains the fill for primary and selected controls.
- In Light, neon-filled controls use a one-pixel `#91B560` semantic accent
  border. This applies to primary buttons, root create actions, selected
  navigation, floating actions, and compact accent chips so the fill remains
  defined without a heavy outline. Neutral cards and hero surfaces keep neutral
  dividers; Dark retains its existing accent edges.
- Legacy green/violet aliases remain in code for compatibility and should be gradually renamed only when safe.

Accessibility refinement (updated 2026-07-31):

- Primary navigation and primary controls use an opaque accent fill. Secondary
  display and time filters use raised graphite with an accent label so they do
  not compete with the screen action.
- Content on a neon fill uses dark `#17200D`.
- Neon is not used as body text; it remains an action, selection, focus, and
  restrained status signal.
- Essential text never uses the disabled role, and tertiary copy remains readable against the page canvas.
- Primary, secondary, tertiary, and accent text roles meet WCAG AA normal-text
  contrast against both canvases. Disabled text is reserved for unavailable
  controls, never essential information.
- Button and active-navigation content always uses dark `#17200D` on the neon
  fill. Light-mode module icons use darker adaptive foregrounds rather than the
  pastel Dark variants.

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

- Display large: 40, w600.
- Display medium: 32, w600.
- Headline large: 26, w600.
- Headline medium: 21, w600.
- Title large: 18, w600.
- Title medium: 15, w600.
- Body large: 16, w400.
- Body medium: 14, w400.
- Label large: 13, w500.
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
- `pageX`: 20
- `screenTop`: 20 inside the platform `SafeArea`
- `minTouch`: 44
- `bottomNavClearance`: 104

Rules:

- Shell page headers begin at `safeArea.top + screenTop`.
- Leave `xl` (24) between a root page header and its first control or section.
- Shell scrolling content uses `bottomNavClearance` rather than local magic
  numbers.
- Mobile screens should breathe without becoming sparse.
- Use fewer stacked boxes where typography and spacing can carry hierarchy.
- Keep primary actions within comfortable thumb reach.

## Radius

Source: `AppRadius`.

- `xs`: 8
- `sm`: 12
- `md`: 14
- `lg`: 18
- `xl`: 22
- `pill`: 999

Rules:

- Repeated cards should generally stay at `md` or `lg`.
- Pills are for navigation, filters, chips, and compact status controls.
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
- Create-capable root screens use one labelled `WorkloopTopAction`; an
  unlabeled `+` is not sufficient as the main screen action.
- Standard section headings use sentence-case title hierarchy. Use the quiet
  section variant only for dense chronological groups and counts. A restrained
  strong-divider marker separates standard sections without spending the neon
  action colour.
- Pushed screens use `WorkloopRouteHeader`; protected editors pass their
  existing guarded back callback and save action into that primitive.
- Empty states are inline by default. Contained empty states are reserved for
  places where the boundary itself communicates useful context.
- A root empty state must not duplicate the labelled primary action already
  present in its feature header.
- Use `SlateSheetFrame` for bottom sheets.

## Cards and Layout

Current app uses a mix of:

- Bento-style dashboard panels.
- List rows.
- Section bands.
- Detail sheets.
- Summary surfaces.

Rules:

- Avoid generic stacked boxes.
- Use list rows for dense operational records.
- Use hero cards only for high-level summary or next action.
- Use detail sheets for context and fast actions.
- Keep one primary action per screen or sheet.

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

- Bottom pill/glass nav.
- Labels appear under icons.
- Tabs: Home, Clients, Bookings, Tools.
- Tools contains Money, Tasks, and Notes as equal full-width workspace rows.
- Tools also provides direct Record money, New task, and New note capture
  actions before the workspace rows. Each row shows a small live orientation
  signal such as money to collect, open tasks, or saved notes.
- Profile and Settings use compact, direct controls in the Home header rather
  than occupying tool rows or permanent bottom-navigation destinations.
- Create-capable feature screens use one labelled top-right action instead of a
  detached global floating action.
- Body extends behind nav for blur/transparency.

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
- Avoid gimmicky animation that slows business work.

## Current Visual Debt

- Some design tokens still have legacy names (`green`, `violet`) even though the intended role is now `accentPrimary`.
- Large screens still contain local UI variants that should be consolidated.
- Money and Bookings have evolved quickly and need a final consistency pass.
- Legacy `AppColors` call sites use an appearance-aware compatibility bridge;
  touched screens should continue migrating to `WorkloopThemeTokens` rather
  than adding local Light/Dark conditions.
- Both palettes intentionally use one bright accent; future colour experiments
  should be done as a deliberate theme pass, not piecemeal.

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
- Use `AppSpacing.bottomNavClearance` for scrollable primary screens that sit behind the floating bottom navigation.
- `WorkloopSegmentedControl` is the preferred control for two-to-four peer filters or tabs when the content is already managed in the screen.

Current scope:

- Dashboard, Business Feed, Clients, Bookings, Money, Tasks, Notes, Settings, Onboarding, bottom navigation, and global workspace error chrome now reference the canonical primitives where they touch shared system UI.
- Bookings and Settings use the shared segmented control instead of local pill-tab containers.
- This section records the 2026-07-07 implementation. As of 2026-07-31,
  System, Light, and Dark are supported again; new work must continue to use
  semantic theme tokens rather than local colours.
