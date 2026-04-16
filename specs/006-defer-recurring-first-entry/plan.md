# Implementation Plan: Diferir primera entrada recurrente mensual según día de pago

**Branch**: `006-defer-recurring-first-entry` | **Date**: 2026-04-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-defer-recurring-first-entry/spec.md`

## Summary

Cambiar la generación de la primera entrada de recurrentes mensuales para que respete `paymentDay`: si el día de pago ya pasó en el mes en curso, diferir al mes siguiente; si aún no ha llegado, programar para ese día (sin generarla prematuramente); si coincide con hoy, generar de inmediato. El cambio unifica la lógica de generación: PeriodGenerator gana filtrado por fecha exacta (no solo por mes), y los form providers dejan de generar la primera entrada manualmente, delegando en RecurringGenerationService.

## Technical Context

**Language/Version**: Dart (Flutter stable channel)  
**Primary Dependencies**: flutter_riverpod, go_router, drift ^2.20.0, shared_ui, shared_models, shared_services  
**Storage**: Drift (SQLite), local on-device only  
**Testing**: flutter_test, Riverpod test utilities  
**Target Platform**: Desktop (primary), Android (planned)  
**Project Type**: desktop-app (Flutter)  
**Performance Goals**: N/A (local single-user app, no change in performance profile)  
**Constraints**: Offline-only, no network calls, no sensitive data in logs  
**Scale/Scope**: Single user, ~dozens of recurring templates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Monorepo & Shared Code | PeriodGenerator lives in `shared_services` — correct location. No public API breakage: `computeDueKeys()` gains an optional `paymentDay` parameter with default value 1. | PASS |
| II. Riverpod-Only State | No new state management. Form notifiers already use Riverpod. | PASS |
| III. UI/Business Logic Separation | The change removes business logic from form providers (first-entry generation) and centralizes it in PeriodGenerator + RecurringGenerationService. Net improvement. No UI changes. | PASS |
| IV. Test-First for Financial Logic | First-entry date calculation is financial logic. Tests MUST be written and confirmed failing before implementation. | ENFORCED |
| V. Offline-First & Privacy | No network calls introduced. No sensitive data exposed. | PASS |
| VI. Financial UX Clarity | No UI changes. Currency/date formatting unaffected. | PASS |
| VII. Simplicity | No new dependencies. Reduces code duplication (eliminates duplicated skip logic from two form notifiers). Architecture becomes simpler: one code path for all entry generation. | PASS |

> No violations. Complexity Tracking table not needed.

## Project Structure

### Documentation (this feature)

```text
specs/006-defer-recurring-first-entry/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (empty — no UI changes)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (files affected)

```text
my_apps/
├── packages/
│   └── shared_services/
│       ├── lib/src/generation/
│       │   └── period_generator.dart        # Add paymentDay-aware date filtering
│       └── test/generation/
│           └── period_generator_test.dart    # New tests for paymentDay filtering
├── apps/
│   └── sfinance/
│       ├── lib/
│       │   ├── providers/
│       │   │   └── form_providers.dart       # Remove manual first-entry generation, delegate to service
│       │   └── services/
│       │       └── recurring_generation_service.dart  # Extract generateForTemplate(), use PeriodGenerator for date computation
│       └── test/
│           ├── services/
│           │   └── recurring_generation_service_test.dart  # Update tests for new behavior
│           └── providers/
│               └── form_providers_test.dart  # Update tests (if existing)
```

**Structure Decision**: No new files or directories. All changes are modifications to existing files within their current locations.

## Architecture

### Current flow (problem)

```
Form save → Form notifier computes firstDate manually (skip logic) →
            Inserts template + first Transaction always →
            Sets lastGeneratedPeriod

App launch → RecurringGenerationService.run() →
             PeriodGenerator.computeDueKeys() (month-level only) →
             Generate entries for due months
```

**Issues**:
1. Form notifiers have duplicated skip logic (ExpenseFormNotifier lines 147–171, IncomeFormNotifier lines 382–394)
2. First entry is always generated at save time, even when paymentDay is in the future (e.g., paymentDay=20, today=16 → creates April 20th entry prematurely on April 16th)
3. PeriodGenerator only checks month-level boundaries, not exact dates within the month

### Target flow (solution)

```
Form save → Form notifier computes startDate (skip logic) →
            Inserts template with lastGeneratedPeriod = null →
            Calls RecurringGenerationService.generateForTemplate() →
            PeriodGenerator.computeDueKeys() (date-level filtering) →
            Generate entries only if computed date ≤ today

App launch → RecurringGenerationService.run() →
             Same PeriodGenerator path for all templates
```

**Improvements**:
1. Single code path: PeriodGenerator handles all date-level filtering
2. No premature entries: paymentDay=20 on April 16 → no entry until April 20
3. Form notifiers only compute startDate and save template, then delegate

### Key design decisions

1. **PeriodGenerator gains `paymentDay` parameter**: `computeDueKeys()` gets `int paymentDay = 1`. After generating month keys, it filters out keys whose computed date (year, month, clamped paymentDay) is strictly after today. This is backward-compatible (default=1 preserves current behavior for callers that don't pass paymentDay).

2. **`_dateForKey()` extracted to PeriodGenerator**: Currently `_dateForPeriod()` lives only in RecurringGenerationService. The date computation logic (period key + paymentDay → DateTime) is moved to PeriodGenerator as a static method, since PeriodGenerator now needs it for filtering. RecurringGenerationService delegates to PeriodGenerator instead of duplicating.

3. **`RecurringGenerationService.generateForTemplate()` extracted**: The per-template loop body from `run()` becomes a public static method. Form providers call it after saving a template. `run()` calls it for each template.

4. **startDate computation stays in form providers**: The "which month is the first eligible month" logic (`paymentDay < today.day → next month`) remains in form providers because it determines the template's `startDate` field. PeriodGenerator doesn't compute startDate; it filters within the range [startDate..today].

5. **Form providers stop generating entries manually**: After saving the template (with `lastGeneratedPeriod = null`), they call `generateForTemplate()`. If paymentDay == today.day, PeriodGenerator includes the current month key, and an entry is generated. If paymentDay > today.day, the key is excluded, and no entry is generated yet.

## Complexity Tracking

> No violations found. Table not needed.
