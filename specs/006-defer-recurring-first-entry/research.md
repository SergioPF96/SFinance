# Research: 006-defer-recurring-first-entry

**Date**: 2026-04-16  
**Branch**: `006-defer-recurring-first-entry`

## R1: Where is the first-entry generation logic?

**Decision**: First-entry generation happens in form providers, not in PeriodGenerator or RecurringGenerationService.

**Rationale**: Code inspection reveals:
- `ExpenseFormNotifier.submit()` (form_providers.dart:141–201): Computes `firstDate` using paymentDay skip logic (`clampedDay < today.day`), inserts template, inserts first transaction, sets `lastGeneratedPeriod`.
- `IncomeFormNotifier.submit()` (form_providers.dart:378–456): Same pattern for Salario, plus 14-paga extra entry logic.
- `RecurringGenerationService.run()` only handles subsequent entries on app launch, relying on `lastGeneratedPeriod` already being set.

**Alternatives considered**:
- PeriodGenerator: Pure computation, no DB access — correct for this role, but currently doesn't influence first entry.
- RecurringGenerationService: Only runs on app startup, not triggered on form save.

## R2: Why are entries generated prematurely for future paymentDay?

**Decision**: The current skip logic only handles "day already passed → next month" but not "day hasn't arrived yet this month."

**Rationale**: The condition `if (clampedDay < today.day)` correctly defers to next month when paymentDay has already passed. But the `else` branch always generates the entry at save time, even when `paymentDay > today.day` (e.g., paymentDay=20 on April 16 → creates an April 20 entry on April 16). The entry is dated correctly but exists in the DB before the actual day.

**Alternatives considered**:
- Adding a second condition in form providers (`if paymentDay == today.day`) — would fix the immediate problem but keeps duplicated logic.
- Moving all generation to PeriodGenerator + service — cleaner, eliminates duplication, and ensures one code path for all generation. **Selected**.

## R3: PeriodGenerator filtering granularity

**Decision**: Add date-level filtering to PeriodGenerator using the new `paymentDay` parameter.

**Rationale**: PeriodGenerator currently uses month-level granularity: `_generateAllKeys()` builds keys up to `upperBound` month. It doesn't consider whether the specific day within the month has arrived. Adding a filter step after key generation — computing the actual date for each key and excluding dates after today — resolves this without changing the key generation logic.

**Alternatives considered**:
- Changing `_generateAllKeys` to exclude the last month if paymentDay > today.day — less clean, couples two concerns.
- Adding a separate "first entry resolver" — over-engineering for what is essentially a filter condition.

## R4: _dateForPeriod duplication

**Decision**: Move `_dateForPeriod()` logic from RecurringGenerationService to PeriodGenerator as a public static method `dateForKey()`. RecurringGenerationService calls PeriodGenerator.dateForKey() instead of its own copy.

**Rationale**: PeriodGenerator needs date computation for the new filtering. Having the same logic in two places is a maintenance hazard. Since PeriodGenerator is the canonical "period computation" class, it should own this method.

**Alternatives considered**:
- Keeping both copies — violates DRY, risk of divergence.
- Creating a separate utility — over-engineering for one shared function.

## R5: How form providers delegate to the service

**Decision**: Form providers call `RecurringGenerationService.generateForTemplate(db, template, today)` after saving the template with `lastGeneratedPeriod = null`.

**Rationale**: Extracting the per-template loop body from `run()` into a public method allows both `run()` (startup) and form providers (save time) to use the same code path. The form provider needs to read the template back after insert to get the full `RecurringTemplateRow` for the service call.

**Alternatives considered**:
- Calling `run()` from form providers — would process ALL templates, not just the new one. Wasteful.
- Inlining PeriodGenerator in form providers — still duplicates the generation loop logic.

## R6: Impact on existing tests

**Decision**: Existing PeriodGenerator tests need updating to pass `paymentDay` parameter. Existing form provider tests need updating to remove first-entry assertions and add delegation assertions.

**Rationale**:
- PeriodGenerator tests currently don't pass `paymentDay` — they'll use the default (1) and continue passing. New tests are needed for paymentDay-aware filtering.
- RecurringGenerationService tests need updating since `_dateForPeriod()` moves to PeriodGenerator.
- Form provider tests must verify that templates are saved without first entry and that `generateForTemplate()` is called.

## R7: No schema changes needed

**Decision**: No Drift migration or schema changes required.

**Rationale**: `paymentDay` already exists in the `recurring_templates` table (added in feature 005). `lastGeneratedPeriod` already supports null values (indicates no entries generated yet). The change is purely in the logic layer.
