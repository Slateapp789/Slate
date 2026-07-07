# Slate UI Design System

Last updated: 2026-06-04

## Design Intent

Slate should feel premium, calm, modern, mobile-first, and high-trust. It is a working tool for people running real businesses from their phone.

Current design direction is dark graphite with a restrained lime accent. Slate should feel operational and premium: quiet surfaces, clear hierarchy, and colour used sparingly so important actions and statuses are obvious.

## Current Colour System

Source: `lib/core/theme/app_theme.dart`

Current palette:

- Background: `AppColors.bg` `#141713`
- Card: `AppColors.bgCard` `#1D211C`
- Raised: `AppColors.bgRaised` `#282D25`
- Interactive: `AppColors.bgInteract` `#30372D`
- Border: `AppColors.border` `#3E463A`
- Strong border: `AppColors.borderStrong` `#68735F`
- Primary text: `AppColors.t1` `#F3F5EE`
- Secondary text: `AppColors.t2`
- Tertiary text: `AppColors.t3`
- Disabled/faint text: `AppColors.t4`

Accent:

- Primary accent is lime: `AppColors.accentPrimary` / `AppColors.slate` / `AppColors.green` `#B8F24B`.
- Reserve the bright accent for the main CTA on a screen or sheet and active navigation/selection.
- Green/violet aliases remain in code for compatibility and should be gradually renamed only when safe.

Semantic:

- Success: muted green (`AppColors.statusSuccess`), calmer than the primary accent.
- Warning: muted warm grey.
- Error: muted red.

Rule:

Avoid strong colour noise. Lime means "primary action or active place"; success, warning, and error colours communicate state and should not compete with primary actions.

## Typography

Font:

- Inter through `GoogleFonts.interTextTheme`.

Current text scale:

- Display large: 52, w900.
- Display medium: 36, w900.
- Headline large: 26, w900.
- Headline medium: 22, w700.
- Title large: 17, w700.
- Title medium: 15, w600.
- Body large: 15, w400.
- Body medium: 13, w400.
- Label large: 13, w600.
- Label small: 10, w700.

Rules:

- No negative letter spacing.
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
- `pageX`: 24
- `pageTop`: 60
- `minTouch`: 44

Rules:

- Mobile screens should breathe without becoming sparse.
- Use fewer stacked boxes where typography and spacing can carry hierarchy.
- Keep primary actions within comfortable thumb reach.

## Radius

Source: `AppRadius`.

- `xs`: 8
- `sm`: 12
- `md`: 16
- `lg`: 20
- `xl`: 24
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
- Glass surfaces may use blur and transparency, especially navigation/sheets.

## Components

Shared UI primitives live in:

`lib/shared/widgets/slate_ui.dart`

Core components:

- `SlateSurface`
- `SlateGlassSurface`
- `SlateButton`
- `SlateSheetFrame`
- `SlateLoadingBlock`

Rules:

- New repeated UI should use shared primitives.
- Do not create random one-off surface styles.
- If a pattern repeats across two features, promote it into shared widgets.
- Buttons should use clear labels and appropriate icons.
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
- Tabs: Home, Clients, Bookings, Money, Tasks.
- Floating action button opens contextual creation actions.
- Body extends behind nav for blur/transparency.

Rules:

- Core modules should remain in bottom nav.
- Detail/create flows can push screens or sheets.
- Important routes should eventually be represented in GoRouter.

## Interaction Principles

- Completion should be deliberate.
- Destructive actions require confirmation.
- Swipe actions must not accidentally dismiss important business data.
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
- Avoid gimmicky animation that slows business work.

## Current Visual Debt

- Some design tokens still have legacy names (`green`, `violet`) even though the intended role is now `accentPrimary`.
- Large screens still contain local UI variants that should be consolidated.
- Money and Bookings have evolved quickly and need a final consistency pass.
- Current palette is intentionally dark graphite with a single bright accent; future colour experiments should be done as a deliberate theme pass, not piecemeal.

## 2026-07-07 Minimal Refoundation

Workloop's active UI direction is now whitespace-first rather than container-first.

Design rule:

- Typography, spacing, alignment, and subtle dividers should solve grouping before any card or surface is introduced.
- Cards are exceptions for sheets, modal contexts, true controls, and dense framed tools.
- Lists should generally be `Row -> Divider -> Row`, not repeated rounded cards.
- Header stats should read as inline metrics, not boxed dashboard tiles.
- Empty states should be calm inline guidance, not placeholder cards.
- Lime remains the signature accent and should be reserved for primary actions, active navigation, progress, selected state, and important highlights.

Implementation changes:

- `WorkloopThemeTokens` now defines explicit light and OLED-dark token sets.
- Shared primitives in `lib/shared/widgets/slate_ui.dart` include token-aware surfaces, icon buttons, empty states, list rows, and filter chips.
- Main navigation active state uses lime rather than module colours.
- High-traffic screens have started moving from card-heavy rows to divider/list rhythm.

Current dark-mode status:

- The dark token foundation exists, but the app still runs in light mode while static `AppColors` usages are migrated.
- Do not enable system dark mode until major screens, forms, sheets, dialogs, and local feature widgets read from theme tokens instead of static light colours.
