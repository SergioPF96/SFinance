# Implementation Plan: Recurring Payment Day

**Branch**: `005-recurring-payment-day` | **Date**: 2026-04-13 | **Spec**: `specs/005-recurring-payment-day/spec.md`
**Input**: Feature specification from `/specs/005-recurring-payment-day/spec.md`

## Summary

Allow users to select the exact day of month (1–31) when recurring entries (expenses and income) should occur. Currently all recurring transactions are generated on the 1st. This feature adds a `paymentDay` field to `RecurringTemplate`, modifies the generation service to use it for date resolution (with month-length clamping), adds a day selector to both forms, and displays the selected day in the Entradas list badge. Requires Drift schema migration v1 → v2.

## Technical Context

**Language/Version**: Dart (Flutter stable channel)
**Primary Dependencies**: flutter_riverpod, go_router, drift ^2.20.0, shared_ui, shared_models, shared_services
**Storage**: Drift (SQLite) — local on-device only
**Testing**: flutter_test, Riverpod test utilities
**Target Platform**: Desktop (Windows primary), Android (planned)
**Project Type**: Desktop app (Flutter monorepo)
**Performance Goals**: N/A — form interaction, no hot path
**Constraints**: Offline-only, no network calls, sensitive data never logged
**Scale/Scope**: Single user, ~3 tables, 2 forms affected

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Pre-Phase 0 | Post-Phase 1 |
|-----------|-------|-------------|--------------|
| I. Monorepo & Shared Code | Does any new code belong in `packages/` rather than `apps/`? Does this change any existing package public API (breaking change)? | `paymentDay` field added to `RecurringTemplate` (shared_models) and column to Drift table (shared_services). `TransactionRow` gains optional param (shared_ui). All additive, non-breaking. | PASS — all changes are additive. `TransactionRow.recurringDetail` is optional with default `null`. `RecurringTemplate.paymentDay` requires a model constructor change but no downstream consumer breaks (only sfinance uses it). |
| II. Riverpod-Only State | No `setState`, no non-Riverpod state management, all providers globally scoped? | PASS — `paymentDay` added to existing Notifier states (`ExpenseFormNotifier`, `IncomeFormNotifier`). No new providers needed. | PASS |
| III. UI/Business Logic Separation | Zero business logic in widgets? Centralized routing used? Models are pure Dart? | PASS — day selector is purely presentational; first-occurrence logic and clamping live in providers/service. `RecurringTemplate` remains pure Dart. | PASS |
| IV. Test-First for Financial Logic | Are unit tests written and confirmed failing before financial calculation implementation? | REQUIRED — `_dateForPeriod` with `paymentDay`, month clamping, first-occurrence skip logic are all financial calculations. Tests must be written first. | PASS — test plan covers all financial logic paths. |
| V. Offline-First & Privacy | No network calls introduced? No sensitive data in logs or errors? | PASS — no network. No amounts in badge display (only day number). | PASS |
| VI. Financial UX Clarity | Currency formatted correctly? Dates unambiguous? Positive/negative explicit? Accessibility covered? Android-compatible patterns? | PASS — day selector is a standard dropdown (keyboard-navigable, touch-compatible). Badge text is unambiguous ("Día 15 de cada mes"). | PASS |
| VII. Simplicity | New dependencies justified? No premature abstractions? Architecture understandable to single returning developer? | PASS — no new dependencies. Single integer field + dropdown. No new abstractions. | PASS |

> No violations. Complexity Tracking table not needed.

## Project Structure

### Documentation (this feature)

```text
specs/005-recurring-payment-day/
├── plan.md              # This file
├── research.md          # Phase 0 output — 8 decisions documented
├── data-model.md        # Phase 1 output — entity changes, migration, generation logic
├── quickstart.md        # Phase 1 output — key files, commands
├── contracts/
│   └── ui-contracts.md  # Phase 1 output — day selector, badge, form state contracts
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
my_apps/
├── apps/sfinance/
│   ├── lib/
│   │   ├── providers/
│   │   │   ├── form_providers.dart          # +paymentDay to both form states
│   │   │   └── transaction_providers.dart   # +paymentDay/periodicity to TransactionDisplay
│   │   ├── services/
│   │   │   └── recurring_generation_service.dart  # _dateForPeriod uses paymentDay
│   │   └── ui/
│   │       ├── forms/
│   │       │   ├── expense_form.dart        # +day selector dropdown
│   │       │   └── income_form.dart         # +day selector dropdown
│   │       └── entradas/
│   │           └── entradas_view.dart       # pass recurringDetail to TransactionRow
│   └── test/
│       ├── services/
│       │   └── recurring_generation_service_test.dart  # NEW: paymentDay date resolution
│       └── providers/
│           └── form_providers_test.dart     # NEW or extended: first-occurrence logic
├── packages/
│   ├── shared_models/lib/src/
│   │   └── recurring_template.dart          # +paymentDay field
│   ├── shared_services/lib/src/
│   │   ├── database/
│   │   │   ├── app_database.dart            # schemaVersion 2 + migration
│   │   │   └── tables/
│   │   │       └── recurring_templates.dart # +paymentDay column
│   │   └── generation/
│   │       └── period_generator.dart        # NO CHANGES
│   └── shared_ui/lib/src/widgets/
│       └── transaction_row.dart             # +recurringDetail param
```

**Structure Decision**: Existing monorepo structure. No new directories or packages. All changes fit within existing file boundaries except for new test files.

## Complexity Tracking

> No Constitution violations. Table empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
