# Slate UI Design System

Last updated: 2026-05-31

## Design Intent

Slate should feel premium, calm, modern, mobile-first, and high-trust. It is a working tool for people running real businesses from their phone.

Current design direction has moved away from very dark charcoal and away from pastel experiments. The live code now uses a neutral northbound grey palette with soft contrast, glass surfaces, and a pill navigation bar.

## Current Colour System

Source: `lib/core/theme/app_theme.dart`

Current palette:

- Background: `AppColors.bg` `#D6D5D1`
- Card: `AppColors.bgCard` `#E9E8E4`
- Raised: `AppColors.bgRaised` `#F5F4F0`
- Interactive: `AppColors.bgInteract` `#C9C8C3`
- Border: `AppColors.border` `#B8B7B1`
- Strong border: `AppColors.borderStrong` `#85847F`
- Primary text: `AppColors.t1` `#242424`
- Secondary text: `AppColors.t2`
- Tertiary text: `AppColors.t3`
- Disabled/faint text: `AppColors.t4`

Accent:

- Current accent is neutral slate: `AppColors.slate` / `AppColors.green` `#5F5F5B`.
- Green/violet aliases remain in code for compatibility and should be gradually renamed only when safe.

Semantic:

- Success: muted grey-green.
- Warning: muted warm grey.
- Error: muted red.

Rule:

Avoid strong colour noise. Slate should use different shades of grey for hierarchy, with semantic colour only when it truly communicates state.

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

- Some design tokens still have legacy names (`green`, `violet`) even though visual direction is neutral grey.
- Large screens still contain local UI variants that should be consolidated.
- Money and Bookings have evolved quickly and need a final consistency pass.
- Current palette is intentionally grey-led; future colour experiments should be done as a deliberate theme pass, not piecemeal.
