<!--
SYNC IMPACT REPORT
==================
Version change: N/A → 1.0.0 (initial ratification)

Added sections:
  - Core Principles I–VII (all new)
  - Technology Stack
  - Development Workflow
  - Governance

Removed sections: none (initial ratification)

Modified principles: N/A (initial)

Templates updated:
  ✅ .specify/templates/plan-template.md  — Constitution Check gates updated
  ✅ .specify/templates/tasks-template.md — Path Conventions updated for monorepo
  ✅ .specify/templates/spec-template.md  — no structural changes needed

Deferred TODOs: none
-->

# SFinance Constitution

## Core Principles

### I. Monorepo & Shared Code Contract

All code that is or could become shared across ecosystem apps MUST live in
`packages/` (e.g., `shared_ui/`, `shared_models/`, `shared_services/`). It
MUST NOT be duplicated inside an `apps/` directory.

Once a public contract between packages and apps is established, it MUST NOT
be broken without an explicit instruction and a documented migration plan. Any
change that modifies a package's public API is a breaking change and requires
deliberate versioning treatment.

**Rationale**: SFinance is the first app in a planned ecosystem. Structural
decisions made now propagate to every future app. Duplicated code and broken
contracts are the primary sources of long-term maintenance debt in monorepos.

### II. Riverpod-Only State Management

Riverpod is the sole permitted state management solution across the entire
codebase. The use of `setState`, `InheritedWidget`-based state, `BLoC`,
`Provider` (non-Riverpod), `MobX`, or any other state management library is
PROHIBITED without exception.

All providers MUST be globally scoped. Widget-local providers are not
permitted. Provider logic MUST be independently testable without instantiating
any widget.

**Rationale**: A single, consistent state management approach makes the
codebase predictable and navigable for a single developer returning after time
away. Mixing approaches creates hidden coupling and onboarding friction.

### III. UI / Business Logic Separation

Widgets are purely presentational. Business logic, validation, and data
transformation MUST reside in providers, services, or domain-layer classes —
never inside a widget's `build` method or lifecycle callbacks.

Models MUST be pure Dart classes with no Flutter or UI-layer dependencies.
Navigation MUST be handled by a single, centralized routing solution applied
consistently across the entire app.

**Rationale**: Decoupling the UI layer is the prerequisite for reusing core
functionality on Android (and any future platform) without rewriting business
logic. It also enables unit-testing the logic without a widget test harness.

### IV. Test-First for Financial Logic

Unit tests are REQUIRED for all financial calculation logic before that logic
is considered done. Money is sensitive: off-by-one errors, floating-point
imprecision, and rounding mistakes have real-world consequences.

The Red-Green-Refactor cycle is enforced for financial logic:
tests MUST be written and confirmed failing before implementation begins.
No financial feature is "done" without passing tests.

Provider logic MUST be independently testable without spinning up the UI.

**Rationale**: A personal finance app's primary trust contract with its user
is numeric accuracy. This principle is non-negotiable regardless of timeline
pressure.

### V. Offline-First & Data Privacy

All financial data MUST remain on-device. The application MUST NOT make
network calls, transmit telemetry, collect analytics, or contact any external
service unless explicitly and deliberately initiated by the user as a
first-class, documented feature.

Sensitive data (account balances, transaction amounts, category names) MUST
NEVER appear in logs, crash reports, or error messages.

**Rationale**: Users trust a local-first finance app specifically because their
financial life is not on a server. Violating this — even incidentally — breaks
that trust irreversibly.

### VI. Financial UX Clarity & Accessibility

Financial data MUST always be legible and unambiguous:
- Currency amounts MUST use correct locale-aware formatting with explicit
  currency symbols.
- Dates MUST use unambiguous formats (no MM/DD vs DD/MM ambiguity).
- Positive and negative values MUST have explicit visual indicators
  (sign, color, or both) — never rely on absence of a sign alone.

UI components MUST support keyboard navigation, sufficient color contrast
(WCAG AA minimum), and screen reader compatibility.

All design decisions MUST account for future Android adaptation. Patterns
that are desktop-only by nature (e.g., hover states as sole affordances,
right-click-only actions) MUST be accompanied by a touch-compatible fallback.

**Rationale**: Misread financial data leads to user error. Accessibility is
not a post-launch concern — retrofitting it is far more costly than building
it in.

### VII. Simplicity & Sustainable Architecture

- Prefer well-maintained, widely-used packages over cutting-edge alternatives.
  Every dependency is a future maintenance obligation; each one MUST be
  justified.
- No premature abstractions. Add a layer of indirection only when a second
  concrete use case demands it.
- The architecture MUST remain understandable to the sole developer returning
  to the codebase after months away. If an explanation requires a diagram with
  more than three layers, the design is likely over-engineered (Treat this as a warning, not a full prohibition).
- Complexity MUST be justified in the plan's Complexity Tracking table before
  it is introduced.

**Rationale**: This project is maintained by a single developer. Clever
architecture that cannot be held in one head is a liability, not an asset.

## Technology Stack

- **Framework**: Flutter (stable channel)
- **Language**: Dart
- **State Management**: Riverpod (exclusive — see Principle II)
- **Monorepo Tooling**: Melos
- **Storage**: Local on-device only (see Principle V)
- **Testing**: Flutter test (`flutter_test`), Riverpod test utilities
- **Target Platforms**: Desktop (primary), Android (planned)

Package structure (non-negotiable — see Principle I):

```
my_apps/
├── apps/
│   ├── dashboard/
│   ├── sfinance/       ← this app
│   └── ...
├── packages/
│   ├── shared_ui/
│   ├── shared_models/
│   └── shared_services/
└── melos.yaml
```

## Development Workflow

- Every feature MUST have a spec before implementation begins.
- Financial logic tasks MUST include test tasks written and confirmed failing
  before the corresponding implementation task is started.
- Breaking changes to any `packages/` public API MUST be documented in the
  plan's Complexity Tracking table with a migration note.
- Commits MUST be scoped to a single logical change. Large, mixed-purpose
  commits are not permitted.
- The Complexity Tracking table in each plan is the designated place to justify
  any deviation from these principles. Undocumented deviations are violations.

## Governance

This constitution supersedes all other development guidelines, README
conventions, and informal practices. In case of conflict, the constitution
wins.

**Amendment procedure**:
1. Propose the change with a written rationale.
2. Identify which existing features or specs are affected.
3. Document a migration plan if the amendment changes an established contract.
4. Increment the version according to semantic rules below.
5. Update `LAST_AMENDED_DATE`.

**Versioning policy**:
- MAJOR: Removal or redefinition of a principle; backward-incompatible
  governance change.
- MINOR: New principle or section added; materially expanded guidance.
- PATCH: Clarifications, wording fixes, non-semantic refinements.

**Compliance**: Every plan's Constitution Check gate MUST be reviewed before
Phase 0 research and re-checked after Phase 1 design. Violations require an
entry in the Complexity Tracking table before work proceeds.

**Version**: 1.0.0 | **Ratified**: 2026-04-05 | **Last Amended**: 2026-04-05
