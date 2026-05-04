# SFinance Development Guidelines

## Project

Flutter personal finance desktop app — first in a planned multi-app ecosystem.
Local-only data. No server, no accounts, no cloud sync. Single indie developer.

Full governing rules: `.specify/memory/constitution.md`

## Monorepo Structure

```
my_apps/
├── apps/
│   ├── sfinance/        ← this app
│   └── dashboard/       (planned)
├── packages/
│   ├── shared_ui/       # common widgets, themes
│   ├── shared_models/   # data models used across apps
│   └── shared_services/ # storage, etc.
└── melos.yaml
```

Code that is or could be shared across apps MUST go in `packages/`, never
duplicated inside `apps/`. Public package APIs MUST NOT be broken without an
explicit instruction and a migration plan.

## Non-Negotiable Rules

**State management**: Riverpod only. No `setState`, no other libraries.
All providers must be globally scoped — no widget-local providers.

**UI layer**: Widgets are purely presentational. Zero business logic in
`build` methods or widget lifecycle callbacks. Navigation via one centralized
routing solution throughout the app.

**Models**: Pure Dart — no Flutter or UI imports.

**Financial logic**: Unit tests written and confirmed failing BEFORE
implementation. No financial feature is done without passing tests.

**Data privacy**: No network calls, no telemetry, no analytics. Sensitive
data (balances, amounts, categories) must never appear in logs or errors.

**UX**: Currency amounts locale-formatted with explicit symbols. Dates
unambiguous. Positive/negative values always have explicit indicators.
WCAG AA contrast minimum. Keyboard navigation and screen reader support.
No desktop-only interaction patterns without a touch-compatible fallback.

**Dependencies**: Every new package must be justified. Prefer boring and
well-maintained over cutting-edge. No premature abstractions.

## Active Technologies
- Dart 3.x (Flutter stable channel) (013-pin-auth-encryption)
- SQLite via Drift, on-device only. Schema version stays at (013-pin-auth-encryption)

- **Framework**: Flutter (stable channel)
- **Language**: Dart
- **State**: Riverpod
- **Monorepo**: Melos
- **Storage**: Local on-device
- **Testing**: `flutter_test`, Riverpod test utilities

## Key Paths

| What | Where |
|------|-------|
| App source | `my_apps/apps/sfinance/lib/` |
| App tests | `my_apps/apps/sfinance/test/` |
| Providers | `lib/providers/` |
| Widgets (UI only) | `lib/ui/` |
| Domain / services | `lib/domain/` or `lib/services/` |
| Shared models | `my_apps/packages/shared_models/` |
| Shared widgets | `my_apps/packages/shared_ui/` |
| Shared services | `my_apps/packages/shared_services/` |

## Spec-Kit Workflow

Feature work follows the spec-kit flow:

```
/speckit.specify   → write the spec
/speckit.plan      → research + design
/speckit.tasks     → generate task list
/speckit.implement → implement task by task
```

Constitution Check in every plan MUST be reviewed before Phase 0 and
re-checked after Phase 1. Violations require a Complexity Tracking entry
before work proceeds.

## Commands

```bash
# Run all tests
melos run test

# Run tests for a single package
flutter test                        # from within the package directory

# Analyze
flutter analyze

# Format
dart format .
```

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
