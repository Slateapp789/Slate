# Slate Constitution

Last updated: 2026-05-31

This document governs future Slate work. Future development should comply unless the user explicitly changes direction and records the decision.

## Product Principles

1. Slate serves solo appointment-based business owners first.
2. The core loop is `Client -> Booking -> Work -> Payment -> Repeat`.
3. Daily utility matters more than feature count.
4. Calm beats clutter.
5. Mobile-first is non-negotiable.
6. Business context comes before generic productivity.
7. V1 must stay focused.
8. Do not build an everything app.

## Scope Rules

V1 features should improve at least one of:

- Bookings
- Clients
- Payments/Money
- Tasks/follow-ups
- Daily control
- Trust/security
- Business profile/request flow

Features usually not V1:

- AI assistant
- Marketplace
- Team/staff management
- Generic project management
- Visual automation builder
- Advanced analytics module
- Full accounting
- Messaging/WhatsApp replacement

If a feature feels exciting but does not reduce daily admin or improve the core loop, park it.

## Architecture Principles

1. Do not rebuild Slate from scratch.
2. Preserve live backend names unless there is a strong migration reason.
3. UI should not call Supabase tables directly.
4. Use repositories as the data boundary.
5. Use Riverpod providers as the app state boundary.
6. Convert Supabase rows to typed models before broad UI use where practical.
7. Keep screen files from becoming dumping grounds.
8. Extract reusable widgets when patterns repeat.
9. Update schema contract and RLS contract when database shape changes.
10. Run analyzer/tests before claiming work is complete.

Target flow:

```text
Screen -> Widgets -> Provider -> Repository -> Supabase
```

## Database Principles

1. Every workspace-owned row must include `workspace_id`.
2. Every workspace-owned table must have RLS.
3. Workspace access is through `workspace_members`.
4. Public profile reads should expose only intended public data.
5. Public writes should be narrow and validated by RLS.
6. No service-role key in Flutter.
7. Migrations are named, documented, and reflected in code tests.
8. Backend table names can differ from user-facing product language.

## Design Principles

1. Premium, calm, high-trust.
2. Neutral grey visual language unless a deliberate theme decision replaces it.
3. One primary action per screen/sheet.
4. Avoid stacked generic cards.
5. Use hierarchy, spacing, typography, and subtle depth.
6. Use glass/transparency carefully for navigation and sheets.
7. Keep tap targets thumb-friendly.
8. Completion/destruction must be deliberate.
9. Motion should be subtle, fast, and useful.
10. New UI should use existing tokens/components.

## Development Principles

1. Make small, verifiable changes.
2. Prefer improving current features over adding disconnected modules.
3. Keep Git history meaningful.
4. Do not revert user work.
5. Do not commit `.env` or secrets.
6. Update docs when decisions change.
7. Add tests around model/schema changes.
8. Manual QA matters for mobile sheets, keyboard, safe area, and navigation.

## AI Operating Instructions

When an AI agent continues Slate:

1. Read this constitution first.
2. Read `CurrentState.md`, `Architecture.md`, and the relevant feature files.
3. Check Notion if product scope is unclear.
4. Treat Notion as product truth unless code has clearly superseded it.
5. If code supersedes Notion, document the difference.
6. Do not blindly agree with user suggestions. Push back when a suggestion adds clutter, risk, or weakens the product.
7. Do not build feature code during audit/documentation tasks.
8. Before schema changes, inspect live Supabase and schema contract.
9. After implementation, run `flutter analyze` and `flutter test --dart-define-from-file=.env`.
10. Prefer one cohesive sweep only when the scope is clear and the risk is contained.

## Definition Of Done

For feature work:

- User-facing behavior works.
- UI fits mobile safe areas.
- Empty/loading/error states exist where needed.
- Data access goes through repositories.
- RLS/schema implications are handled.
- Tests/analyzer pass.
- Git commit is clear.
- Docs are updated if product or architecture changed.

For foundation work:

- No new product behavior unless explicitly requested.
- Findings are documented.
- Risks and next actions are ranked.
- No knowledge is left only in chat.
