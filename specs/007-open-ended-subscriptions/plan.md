# Implementation Plan: Open-Ended Subscriptions

**Branch**: `007-open-ended-subscriptions` | **Date**: 2026-04-18 | **Spec**: spec.md

## Summary

Add a "Sin fecha de fin" toggle to the expense form for Suscripción. When active, the template is persisted with `endDate = null` and generates entries indefinitely. Requires a Drift schema migration (v2→v3), a nullable-endDate update to `PeriodGenerator.computeDueKeys`, and null-safe handling in `RecurringGenerationService`. The `TemplateDisplay` model also needs `endDate` made nullable so any UI rendering null-dates shows "Sin fecha de fin".

## Technical Context

**Language/Version**: Dart (Flutter stable)  
**Primary Dependencies**: Drift (SQLite), Riverpod, flutter_test  
**Storage**: Local SQLite via Drift (`shared_services`)  
**Testing**: flutter_test, Riverpod ProviderContainer  
**Target Platform**: Windows desktop (primary), Android (planned)  
**Project Type**: Flutter desktop app — monorepo  
**Performance Goals**: No latency targets; single-user local app  
**Constraints**: Offline-only; no network; schema migration must be non-destructive  
**Scale/Scope**: Single device; ~100 recurring templates at most  

## Constitution Check

| Principle | Gate | Status |
|-----------|------|--------|
| I — Shared Code | `PeriodGenerator` + `RecurringTemplates` changes go in `packages/` | ✅ PASS |
| I — No broken contracts | `computeDueKeys` signature changes (endDate nullable) — public API breaking change; migration documented in Complexity Tracking | ✅ PASS (documented) |
| II — Riverpod only | New `openEnded` state managed in `ExpenseFormNotifier` | ✅ PASS |
| III — UI/logic separation | Toggle state lives in provider; widget reads state only | ✅ PASS |
| IV — Test-first | `PeriodGenerator` null-endDate tests written before implementation; `ExpenseFormNotifier` open-ended tests written before implementation | ✅ PASS (enforced in tasks) |
| V — Offline-first | No network calls introduced | ✅ PASS |
| VI — UX clarity | "Sin fecha de fin" label is unambiguous; toggle is a standard Flutter Switch widget with a touch-compatible fallback | ✅ PASS |
| VII — Simplicity | Nullable endDate at the table level is the simplest correct approach; no extra sentinel values or shadow columns | ✅ PASS |

## Complexity Tracking

| Item | Justification |
|------|---------------|
| Breaking change: `computeDueKeys(endDate: DateTime?)` | `endDate` was `required DateTime`, now `required DateTime?`. Only one call site (`RecurringGenerationService`) — migration is trivial. The change is necessary to represent open-ended templates without a sentinel value. |
| Drift schema migration v2→v3 | ALTER COLUMN to nullable is additive. Existing rows keep their endDate. Required for nullable endDate support. |

## Project Structure — Files Touched

| File | Change |
|------|--------|
| `packages/shared_services/lib/src/database/tables/recurring_templates.dart` | `endDate` → `dateTime().nullable()()` |
| `packages/shared_services/lib/src/database/app_database.dart` | `schemaVersion` 2→3; add migration step |
| `packages/shared_services/lib/src/generation/period_generator.dart` | `endDate: required DateTime` → `required DateTime?`; when null use `today` as sole upper bound |
| `packages/shared_services/test/generation/period_generator_test.dart` | Add null-endDate tests (TDD) |
| `apps/sfinance/lib/services/recurring_generation_service.dart` | Handle `template.endDate` being null |
| `apps/sfinance/lib/providers/form_providers.dart` | Add `openEnded` field; `setOpenEnded()`; reset in `setCategoria`/`setPeriodicidad`; skip FR-006 when open-ended; pass `endDate: null` to Drift insert |
| `apps/sfinance/lib/providers/template_providers.dart` | `TemplateDisplay.endDate` → `DateTime?` |
| `apps/sfinance/test/providers/expense_form_provider_test.dart` | Add open-ended submit tests (TDD) |
| `apps/sfinance/lib/ui/` | Add "Sin fecha de fin" toggle to expense form widget; show "Sin fecha de fin" in Recurrentes display |

## Research Findings

- **R1 — Drift nullable migration**: Drift supports `MigrationStrategy.onUpgrade` with `customStatement('ALTER TABLE recurring_templates ALTER COLUMN end_date DROP NOT NULL')` on SQLite ≥ 3.35. For older SQLite: recreate table with `CREATE TABLE new_t … ; INSERT INTO new_t SELECT … ; DROP TABLE old_t ; ALTER TABLE new_t RENAME TO recurring_templates`. Use `database.customStatement` inside `onUpgrade`.
- **R2 — PeriodGenerator null endDate**: When `endDate` is null, the upper bound is `today` only (no endDate cap). The single-line change: `final upperBound = endDate == null ? now : (endDate.isBefore(now) ? endDate : now);`
- **R3 — FR-006 skip**: The existing validation block `if (s.periodicidad == Periodicity.mensual)` already guards with `s.fechaFin!` — if we add `if (!s.openEnded)` guard before it, FR-006 is fully bypassed for open-ended templates.
- **R4 — TemplateDisplay**: Currently `endDate` is `final DateTime endDate`. Making it `DateTime?` is a non-breaking change within `sfinance` (only internal consumers). Any rendering site must handle null with the label "Sin fecha de fin".
- **R5 — Toggle reset policy**: `setOpenEnded(false)` clears `fechaFin` (spec edge case: no stale date restored). `setCategoria` and `setPeriodicidad` reset `openEnded` to false (consistent with resetting all recurring-specific fields).

## Post-Phase-1 Constitution Re-check

| Principle | Verdict |
|-----------|---------|
| I | Schema change in `packages/shared_services` ✅; breaking `computeDueKeys` documented ✅ |
| IV | Test tasks precede every implementation task ✅ |
| VII | No new abstractions; nullable column is the minimal correct model ✅ |
