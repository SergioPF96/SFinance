# Implementation Plan: Diferir primera entrada recurrente mensual según día de pago

**Branch**: `006-defer-recurring-first-entry` | **Date**: 2026-04-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-defer-recurring-first-entry/spec.md`

## Summary

Monthly recurring templates (Suscripción, Financiación, Salario) defer their first generated entry according to the rule: `paymentDay ≥ today → current month`; `paymentDay < today → next month`. The core deferral pipeline is already implemented via `PeriodGenerator.computeDueKeys` (shared_services) plus form-provider logic that shifts `startDate` forward when `paymentDay` has already passed. This plan covers the remaining work introduced by the 2026-04-18 clarifications:

1. **FR-006 (new)** — Save-time validation: reject template persistence when the calculated first occurrence falls after `endDate`. Pure-logic check added to form providers before the insert.
2. **FR-005 clarification (extra pagas)** — Verify that 14-paga extra entries respect `paymentDay`. `PeriodGenerator.dateForKey` already clamps `paymentDay` for `YYYY-MM-extra` keys; coverage adds explicit regression tests.
3. **FR-005 clarification (open-ended Suscripción)** — Tolerate `endDate = null` in the calc pipeline. Full schema/UI for nullable endDate is owned by spec 001's open-ended subscription amendment; this plan delivers only the generator/validator tolerance for null so the two features compose cleanly.

No new dependencies. No UI layout changes (error toast/inline message reuses existing form error surface).

## Technical Context

**Language/Version**: Dart (Flutter stable channel)
**Primary Dependencies**: Riverpod, Drift, intl (all already in use)
**Storage**: SQLite via Drift on-device
**Testing**: `flutter_test`, Riverpod test utilities
**Target Platform**: Desktop (Windows/macOS/Linux); Android planned
**Project Type**: Flutter monorepo (Melos)
**Performance Goals**: First-occurrence calculation < 1 ms; save-time validation adds no perceptible latency
**Constraints**: Offline-only; no network, no telemetry; no UI redesign
**Scale/Scope**: Single user; < 10 000 templates lifetime

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Monorepo & Shared Code | New pure logic extends `PeriodGenerator` in `packages/shared_services`; form validation hook stays in `apps/sfinance`. No package public API breakage (only additive helper and null-tolerance). | PASS |
| II. Riverpod-Only State | Save-time validation lives in the existing `expenseFormProvider` / `incomeFormProvider` (Riverpod `StateNotifier`s). No `setState`. | PASS |
| III. UI/Business Logic Separation | Calculation + validation rules are pure Dart in `shared_services`; providers orchestrate; widgets only display the error string. Models remain pure Dart. | PASS |
| IV. Test-First for Financial Logic | New `PeriodGenerator.firstOccurrenceDate` helper and the provider's pre-insert validation path are financial logic. Unit tests written and confirmed failing before implementation. | PASS (enforced in tasks) |
| V. Offline-First & Privacy | No network. Error messages contain no amount/balance/category data — only date-range wording. | PASS |
| VI. Financial UX Clarity | Error string locale-aware (Spanish), renders via existing inline form error with WCAG-AA contrast. Touch/keyboard parity preserved. | PASS |
| VII. Simplicity | No new dependencies. One new pure function. Validation is a one-liner at the top of the existing save path. No new abstraction layers. | PASS |

No violations → Complexity Tracking table stays empty.

### Post-Phase-1 re-check

Re-evaluated after data-model.md, contracts/period_generator.md, and quickstart.md were written:

- **Principle I** — `firstOccurrenceDate` goes into the existing `PeriodGenerator` in `packages/shared_services`; no new package, no public API breakage (additive). ✅
- **Principle II** — No changes to state management; validation lives in the existing Riverpod `StateNotifier`. ✅
- **Principle III** — Contract (`contracts/period_generator.md`) confirms pure-Dart helper with no Flutter imports. Error message is a const string consumed by the existing widget that already displays `errorMessage`. ✅
- **Principle IV** — Tasks file will enforce test-first; helper + validator are financial-logic candidates. ✅
- **Principle V** — No network, no logging of amounts/categories in the new error path. ✅
- **Principle VI** — Spanish error string is unambiguous, renders via the existing accessible inline error; no hover-only affordance. ✅
- **Principle VII** — One pure function + one if-block. No new package, no new layer. ✅

Gate still PASS. Complexity Tracking remains empty.

## Project Structure

### Documentation (this feature)

```text
specs/006-defer-recurring-first-entry/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (pure-function contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (monorepo)

```text
my_apps/
├── apps/
│   └── sfinance/
│       ├── lib/
│       │   └── providers/
│       │       └── form_providers.dart          # add pre-insert validation (FR-006)
│       └── test/
│           └── providers/
│               ├── expense_form_provider_test.dart   # new FR-006 cases
│               └── income_form_provider_test.dart    # new FR-006 cases
└── packages/
    └── shared_services/
        ├── lib/
        │   └── src/
        │       └── generation/
        │           └── period_generator.dart    # add firstOccurrenceDate(); null-tolerant endDate
        └── test/
            └── generation/
                └── period_generator_test.dart   # new firstOccurrenceDate + extra-paga + null-endDate cases
```

**Structure Decision**: Pure calculation helper lives in `packages/shared_services/lib/src/generation/period_generator.dart` (where `PeriodGenerator.dateForKey` and `computeDueKeys` already live). Save-time validation hook and user-facing error message live in `apps/sfinance/lib/providers/form_providers.dart` where the existing recurring-template save path already resides. This preserves Principle I (shared logic in packages) and Principle III (UI layer free of business logic).

## Complexity Tracking

> Fill ONLY if Constitution Check has violations that must be justified.

No violations. Table intentionally empty.
