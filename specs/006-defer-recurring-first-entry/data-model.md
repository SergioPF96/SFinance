# Data Model: 006-defer-recurring-first-entry

**Date**: 2026-04-16  
**Branch**: `006-defer-recurring-first-entry`

## Schema Changes

**None.** All required fields already exist from feature 005.

## Existing Entities (unchanged schema, changed behavior)

### RecurringTemplate

| Field | Type | Change |
|-------|------|--------|
| `id` | int (PK, autoincrement) | — |
| `name` | text | — |
| `amountCents` | int | — |
| `transactionType` | text ('expense' / 'income') | — |
| `category` | text | — |
| `periodicity` | text ('mensual' / 'anual') | — |
| `startDate` | DateTime | **Behavioral**: now always set to the 1st of the first eligible month (unchanged computation, but entry generation no longer happens at save time) |
| `endDate` | DateTime | — |
| `paymentDay` | int? (nullable, default 1) | **Behavioral**: used by PeriodGenerator for date-level filtering |
| `lastGeneratedPeriod` | text? (nullable) | **Behavioral**: now starts as `null` when template is saved (previously set to first period immediately) |
| `payFrequency` | text? | — |
| `extraPayMonth1` | int? | — |
| `extraPayMonth2` | int? | — |
| `isDeleted` | bool | — |

### Transaction

No changes. Transactions are still generated with the same fields; only the timing of the first insertion changes.

## Behavioral Changes

### startDate computation (form providers)

**Before**: `startDate` = 1st of the month containing `firstDate` (which accounts for skip logic).  
**After**: Same computation. No change to what's stored.

### lastGeneratedPeriod at save time

**Before**: Set to the first period key immediately on save (e.g., `'2026-04'`), because the first transaction was always generated at save time.  
**After**: Remains `null` after template insert. Set by `RecurringGenerationService.generateForTemplate()` only if an entry is actually generated (i.e., `paymentDay <= today.day`).

### PeriodGenerator.computeDueKeys()

**New parameter**: `int paymentDay = 1` (optional, backward-compatible).

**New filtering**: After generating all month keys, computes the actual date for each key using `paymentDay` (clamped to month length). Excludes keys whose date is strictly after `today`. This prevents premature entry generation for months where the payment day hasn't arrived yet.

### PeriodGenerator.dateForKey() (new public method)

Computes the `DateTime` for a given period key + paymentDay + endDate (for annual month resolution). Extracted from `RecurringGenerationService._dateForPeriod()`.

**Signature**: `static DateTime dateForKey(String periodKey, int paymentDay, {int? annualMonth})`

### RecurringGenerationService.generateForTemplate() (new public method)

Extracts the per-template generation loop from `run()`. Called by form providers after saving a template and by `run()` for each active template.

**Signature**: `static Future<void> generateForTemplate(AppDatabase db, RecurringTemplateRow template, {DateTime? today})`

## Validation Rules

- `paymentDay` clamped to `[1, daysInMonth]` at generation time (existing, unchanged).
- `startDate` must be the 1st of a month (enforced by form providers, existing).
- `lastGeneratedPeriod` lexicographic ordering ensures no duplicates (existing).

## State Transitions

```
Template save attempt
  → Form provider computes firstOccurrenceDate(today, paymentDay)
  → If endDate != null AND firstOccurrenceDate > endDate:
      → Reject save, set errorMessage, do NOT insert template (FR-006)
  → Else:
      → Insert template (lastGeneratedPeriod = null)
      → generateForTemplate() called
        → PeriodGenerator.computeDueKeys(paymentDay: X)
          → If paymentDay <= today.day AND month is current:
              → Generate entry, set lastGeneratedPeriod = current period key
          → If paymentDay > today.day:
              → No entry generated, lastGeneratedPeriod stays null
          → If startDate is next month (paymentDay < today.day):
              → No keys due, lastGeneratedPeriod stays null

App launch (RecurringGenerationService.run())
  → For each template with lastGeneratedPeriod = null or behind:
    → PeriodGenerator.computeDueKeys(paymentDay: X)
    → Generate entries for all due keys
    → Update lastGeneratedPeriod
```

---

## Addendum — 2026-04-18 clarification deltas

### New pure helper: `PeriodGenerator.firstOccurrenceDate`

**Signature**: `static DateTime firstOccurrenceDate({required DateTime today, required int paymentDay})`

**Contract**:
- If `paymentDay >= today.day` → returns `DateTime(today.year, today.month, clamp(paymentDay, 1, daysInMonth(today.year, today.month)))`.
- If `paymentDay < today.day` → returns `DateTime(today.year, today.month + 1, clamp(paymentDay, 1, daysInMonth(nextMonth)))`, handling December wraparound normally via `DateTime` constructor.

**Used by**: form providers (FR-006 validation); also re-exported for tests.

### FR-006 save-time validation (form provider)

**Applies to**: Monthly recurring templates where `endDate != null`. Skipped for open-ended subscriptions (`endDate == null`) and for annual templates.

**Check**: `firstOccurrenceDate(today, paymentDay).isAfter(endDate)` → reject with `errorMessage = "El día de pago ya pasó este mes y la fecha de fin no alcanza al mes siguiente"`.

**Ordering**: Runs after existing paymentDay-required check and endDate-in-future check; runs before `templateDao.insert`.

### Extra-paga clarification (no data-model change)

The existing `dateForKey` resolution of `YYYY-MM-extra` keys — using `paymentDay` clamped to the extra month's length — is the documented contract. No field additions, no behaviour change; regression tests added to lock it in.

### Open-ended Suscripción tolerance (forward compatibility)

`firstOccurrenceDate` does not reference `endDate` → inherently null-tolerant. FR-006 validation explicitly short-circuits on null. `computeDueKeys` keeps its current non-null `endDate` signature; feature 001's open-ended work will decide whether to relax the signature or pass a sentinel far-future date.
