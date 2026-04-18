# Implementation Plan: SFinance Core Application

**Branch**: `001-sfinance-core-app` | **Date**: 2026-04-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-sfinance-core-app/spec.md`

## Summary

Build SFinance, a personal finance desktop app (Flutter) that tracks income and expenses, computes real-time financial KPIs, visualizes trends over time, and automatically generates recurring transaction entries (subscriptions, financing, salary with 14-paga support). All data is stored locally on-device using Drift (SQLite). State managed exclusively via Riverpod with globally-scoped providers. Three main views: Resumen (dashboard), Analisis (trend charts), Entradas (full transaction list + template management).

## Technical Context

**Language/Version**: Dart (Flutter stable channel)
**Primary Dependencies**: flutter_riverpod, go_router, drift, fl_chart, intl
**Storage**: Drift (SQLite) — local on-device only
**Testing**: flutter_test, Riverpod test utilities
**Target Platform**: Desktop (Windows/macOS/Linux) primary; Android planned
**Project Type**: Desktop application (Flutter)
**Performance Goals**: <3s launch with correct data (SC-005), 60fps UI
**Constraints**: Fully offline, no network calls, no telemetry, integer-cents arithmetic
**Scale/Scope**: Single user, 3 views, 7 user stories, ~4 database tables

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Monorepo & Shared Code | Does any new code belong in `packages/` rather than `apps/`? Does this change any existing package public API (breaking change)? | **PASS**. Models -> shared_models (pure Dart). Storage/DAOs -> shared_services. Theme/formatters/common widgets -> shared_ui. App-specific UI/routing/providers in apps/sfinance/. No existing APIs to break (greenfield). |
| II. Riverpod-Only State | No `setState`, no non-Riverpod state management, all providers globally scoped? | **PASS**. All state via Riverpod. Providers globally scoped. No setState permitted. |
| III. UI/Business Logic Separation | Zero business logic in widgets? Centralized routing used? Models are pure Dart? | **PASS**. Widgets purely presentational. Business logic in providers + services. Models in shared_models (pure Dart, no Flutter imports). go_router for centralized routing. |
| IV. Test-First for Financial Logic | Are unit tests written and confirmed failing before financial calculation implementation? | **PASS**. Plan enforces Red-Green-Refactor for: KPI computations, recurring generation algorithm, amount formatting, period-key calculation. |
| V. Offline-First & Privacy | No network calls introduced? No sensitive data in logs or errors? | **PASS**. No network dependencies. Drift is local-only. No telemetry packages. Sensitive data (amounts, balances) excluded from log/error output. |
| VI. Financial UX Clarity | Currency formatted correctly? Dates unambiguous? Positive/negative explicit? Accessibility covered? Android-compatible patterns? | **PASS**. EUR symbol always shown. Locale-aware formatting via intl. Explicit +/- signs with green/red colors. WCAG AA contrast. Keyboard navigation. Touch-compatible fallbacks (no hover-only or right-click-only). |
| VII. Simplicity | New dependencies justified? No premature abstractions? Architecture understandable to single returning developer? | **PASS**. 6 dependencies, each justified (see research.md). No unnecessary abstractions. Flat package dependency graph. Architecture fits a "3-layer" mental model: UI -> Providers -> Services/DAOs. |

> No violations found. Complexity Tracking table is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-sfinance-core-app/
├── plan.md              # This file
├── research.md          # Phase 0 output — technology decisions
├── data-model.md        # Phase 1 output — entities and relationships
├── quickstart.md        # Phase 1 output — setup instructions
├── contracts/
│   └── ui-contracts.md  # Phase 1 output — UI/provider interface contracts
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
my_apps/
├── apps/
│   └── sfinance/
│       ├── lib/
│       │   ├── main.dart                          # Entry point + ProviderScope
│       │   ├── app.dart                           # MaterialApp.router + theme
│       │   ├── providers/                         # Globally-scoped Riverpod providers
│       │   │   ├── kpi_provider.dart              # KPI strip state
│       │   │   ├── chart_providers.dart           # Chart data (bar + line)
│       │   │   ├── transaction_providers.dart     # Transaction lists (recent, filtered)
│       │   │   ├── template_providers.dart        # Active recurring templates
│       │   │   ├── form_providers.dart            # Form state + validation
│       │   │   └── initial_capital_provider.dart  # Initial capital state
│       │   ├── ui/                                # Presentational widgets only
│       │   │   ├── shell/                         # App shell + top nav bar
│       │   │   ├── resumen/                       # KPI cards, bar chart, recent list
│       │   │   ├── analisis/                      # 3 line charts with time selectors
│       │   │   ├── entradas/                      # Transaction list + template list (tabs)
│       │   │   └── forms/                         # Income/expense modal forms
│       │   ├── routing/
│       │   │   └── app_router.dart                # go_router configuration
│       │   └── services/
│       │       └── recurring_generation_service.dart  # On-launch generation logic
│       └── test/
│           ├── providers/                         # Provider unit tests
│           └── services/                          # Generation service tests
├── packages/
│   ├── shared_models/
│   │   ├── lib/
│   │   │   ├── shared_models.dart                 # Barrel export
│   │   │   └── src/
│   │   │       ├── enums/                         # TransactionType, categories, periodicity, etc.
│   │   │       ├── transaction.dart               # Transaction model (pure Dart)
│   │   │       ├── recurring_template.dart        # RecurringTemplate model
│   │   │       └── initial_capital.dart           # InitialCapital model
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── shared_ui/
│   │   ├── lib/
│   │   │   ├── shared_ui.dart                     # Barrel export
│   │   │   └── src/
│   │   │       ├── theme/                         # Dark theme definition, color constants
│   │   │       ├── widgets/                       # KPI card, transaction row, confirmation dialog
│   │   │       └── formatters/                    # Currency formatter, date formatter
│   │   ├── test/
│   │   └── pubspec.yaml                           # depends on: shared_models, flutter, fl_chart, intl
│   └── shared_services/
│       ├── lib/
│       │   ├── shared_services.dart               # Barrel export
│       │   └── src/
│       │       ├── database/
│       │       │   ├── app_database.dart           # Drift database class
│       │       │   ├── tables/                     # Drift table definitions
│       │       │   │   ├── transactions.dart
│       │       │   │   ├── recurring_templates.dart
│       │       │   │   └── initial_capital.dart
│       │       │   └── daos/                       # One DAO per table
│       │       │       ├── transaction_dao.dart
│       │       │       ├── template_dao.dart
│       │       │       └── initial_capital_dao.dart
│       │       └── generation/
│       │           └── period_generator.dart        # Period key computation + generation logic
│       ├── test/
│       └── pubspec.yaml                            # depends on: shared_models, drift, sqlite3_flutter_libs
└── melos.yaml
```

**Structure Decision**: Flutter monorepo with Melos. Three shared packages (models, UI, services) under `packages/`. App-specific code under `apps/sfinance/`. This directly follows the constitution's mandated structure. The app depends directly on all three packages — no unnecessary indirection layers.

## Complexity Tracking

> **No violations found. Table is empty.**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | | |
