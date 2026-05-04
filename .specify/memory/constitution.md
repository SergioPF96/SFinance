<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0 (minor — Principle V materially expanded)

Modified principles:
  - V. Offline-First & Data Privacy
    → V. Offline-First, Data Privacy & Encryption
    Added: full-database encryption mandate (SQLCipher AES-256), master key
    architecture, PIN authentication gate, exponential lockout policy,
    flutter_secure_storage requirements, biometric extensibility contract.
    No existing text removed or weakened.

Added sections: none
Removed sections: none

Templates updated:
  ✅ .specify/templates/plan-template.md — Constitution Check row V updated
  ✅ .specify/templates/spec-template.md — no structural changes needed
  ✅ .specify/templates/tasks-template.md — no structural changes needed

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

### V. Offline-First, Data Privacy & Encryption

All financial data MUST remain on-device. The application MUST NOT make
network calls, transmit telemetry, collect analytics, or contact any external
service unless explicitly and deliberately initiated by the user as a
first-class, documented feature.

Sensitive data (account balances, transaction amounts, category names) MUST
NEVER appear in logs, crash reports, or error messages. No plaintext
cryptographic material (keys, derived keys, salts, IVs, authentication tags)
may ever be written to disk, appear in logs, or surface in error messages.

**Encryption at Rest**: All on-device data MUST be encrypted at rest using
SQLCipher (AES-256 full-database encryption). Field-level encryption is
explicitly prohibited as a substitute for full-database encryption.

**Master Key Architecture**:
- The database MUST be opened with a master key — never with the user's PIN
  directly. The master key is a cryptographically random 32-byte value
  generated once at first launch and never regenerated unless the user
  explicitly resets the app.
- The master key MUST be stored encrypted (AES-256-GCM) using a key derived
  from the user's PIN via PBKDF2-SHA256 with a random 16-byte salt and a
  minimum of 500,000 iterations. The derived key MUST NEVER be written to
  disk or appear in logs — it exists only in memory during unlock.
- The encrypted master key blob, GCM authentication tag, and salt MUST be
  stored via `flutter_secure_storage`. No plaintext cryptographic material may
  ever be written to disk, logs, or error messages.

**Authentication & Lockout**:
- The app MUST require PIN authentication on every launch before any financial
  data is accessible or rendered. No data screen, widget, or route may be
  reachable before successful authentication.
- The lockout policy MUST be enforced entirely before any decryption is
  attempted. After every 3 consecutive failed PIN attempts, the user MUST wait
  before retrying. Wait times follow an exponential progression (×5 per
  block): 1 min after block 1, 5 min after block 2, 25 min after block 3,
  125 min after block 4, and so on. The consecutive-failure counter resets on
  successful authentication.

**Biometric Extensibility**: The architecture MUST be designed to support
adding biometric authentication (Android) in a future phase by unlocking the
same master key via the platform keystore — without re-encrypting the database
or modifying the master key scheme.

**Rationale**: Users trust a local-first finance app specifically because their
financial life is not on a server. Violating this — even incidentally — breaks
that trust irreversibly. Physical device access (theft, loss) is a realistic
threat for mobile and desktop users; encryption at rest closes this attack
vector without requiring a server.

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
  more than three layers, the design is likely over-engineered (treat this as
  a warning, not a full prohibition).
- Complexity MUST be justified in the plan's Complexity Tracking table before
  it is introduced.

**Rationale**: This project is maintained by a single developer. Clever
architecture that cannot be held in one head is a liability, not an asset.

## Technology Stack

- **Framework**: Flutter (stable channel)
- **Language**: Dart
- **State Management**: Riverpod (exclusive — see Principle II)
- **Monorepo Tooling**: Melos
- **Storage**: Local on-device only, encrypted at rest (see Principle V)
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

**Version**: 1.1.0 | **Ratified**: 2026-04-05 | **Last Amended**: 2026-05-04
