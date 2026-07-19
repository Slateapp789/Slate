# Agent Router

This document tells Codex which Workloop agent perspective to use for a task.

When given a task:

1. Read this router.
2. Decide which agent or agents apply.
3. State the chosen agent(s) before proceeding.
4. Use the minimum useful set.
5. Read relevant `/docs` files.
6. Inspect source files before coding.

Do not use every agent for every task.

## Primary Routing Rules

Use Product Architect for:

- Product ideas
- Feature scope
- Roadmap decisions
- MVP decisions
- Product tradeoffs
- User workflow definition
- Deciding whether a feature belongs in Workloop

Use Flutter Lead for:

- Flutter implementation
- Dart structure
- Riverpod state
- Supabase repositories and services
- GoRouter navigation
- Refactoring
- Models and typed data flow
- Build, analysis, and test failures

Use UI Director for:

- Screen design
- Visual polish
- Spacing
- Typography
- Animations
- Haptics
- Premium feel
- Loading, empty, and error states

Use QA Reviewer for:

- Testing
- Bugs
- Regressions
- Edge cases
- Review
- Verification plans
- Risk analysis

Use Technical Librarian for:

- Documentation
- Current status updates
- Engineering log entries
- Decision log entries
- README updates
- Keeping project memory accurate

Use System Integrator for:

- Cross-module changes
- Architecture consequences
- Workflow impact
- Data flow across features
- Navigation consequences
- Ensuring the app still feels like one operating system

## Multi-Agent Rules

UI system work:

1. UI Director
2. Product Architect
3. Flutter Lead
4. System Integrator
5. QA Reviewer
6. Technical Librarian

Bug fix:

1. Flutter Lead
2. QA Reviewer

Major architecture change:

1. System Integrator
2. Flutter Lead
3. Technical Librarian

## Conflict Resolution

If perspectives conflict:

1. Product promise wins: the app should clarify what is happening, what needs attention, and what to do next.
2. Existing architecture wins over a new abstraction.
3. Mobile-first usability wins over feature breadth.
4. Simplicity wins unless complexity clearly reduces user burden.
5. Documentation must record major decisions after they are made.
