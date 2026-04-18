# Contract: PeriodGenerator (shared_services)

**Feature**: 006-defer-recurring-first-entry
**File**: `my_apps/packages/shared_services/lib/src/generation/period_generator.dart`

This contract documents the public surface of `PeriodGenerator` as it stands after the 2026-04-18 clarifications. Existing methods (`computeDueKeys`, `dateForKey`) are carried forward unchanged; the new method `firstOccurrenceDate` is introduced for FR-006 and reused internally where convenient.

## Existing surface (unchanged)

### `computeDueKeys`

```dart
static List<String> computeDueKeys({
  required DateTime startDate,
  required DateTime endDate,
  required String periodicity,                 // 'mensual' | 'anual'
  String? lastGeneratedPeriod,
  List<int>? extraPayMonths,
  int paymentDay = 1,
  DateTime? today,
})
```

Returns ordered period keys due for generation, applying month-level and date-level filters. Non-nullable `endDate` remains required; open-ended subscriptions will be supported via spec 001's storage-layer change (out of scope here).

### `dateForKey`

```dart
static DateTime dateForKey(
  String periodKey,           // 'YYYY-MM' | 'YYYY-MM-extra' | 'YYYY'
  int paymentDay,
  { int? annualMonth }        // required when periodKey is annual
)
```

Resolves a period key to a concrete `DateTime` using `paymentDay` clamped to the month's length. For `YYYY-MM-extra`, uses the same clamped paymentDay within that month — the canonical contract referenced by the extra-paga clarification.

## New surface (added by this feature)

### `firstOccurrenceDate`

```dart
static DateTime firstOccurrenceDate({
  required DateTime today,
  required int paymentDay,    // 1..31
})
```

**Behaviour**:
- Let `d = paymentDay.clamp(1, daysInMonth(today.year, today.month))`.
- If `d >= today.day`: return `DateTime(today.year, today.month, d)`.
- Else: return `DateTime(today.year, today.month + 1, paymentDay.clamp(1, daysInMonth(nextMonth)))`. December rollover is handled implicitly by the `DateTime` constructor.

**Purity**: No I/O; deterministic on `(today, paymentDay)`.

**Preconditions**:
- `paymentDay ∈ [1, 31]`.
- `today` is a calendar date (time-of-day ignored by callers, though not stripped internally — callers must normalize if they need midnight comparisons).

**Postconditions**:
- Result is **today or later** (never in the past).
- For the `paymentDay == today.day` case, returns `today` at 00:00 of that calendar day (matches acceptance scenario US1 A1).

**Failure modes**: none. Pure function; no throws.

## FR-006 consumer-side contract

Consumers (form providers) MUST:
1. Compute `first = PeriodGenerator.firstOccurrenceDate(today: now, paymentDay: s.paymentDay!)`.
2. If `s.fechaFin != null` and `first.isAfter(s.fechaFin)`, abort save with:
   - `errorMessage = "El día de pago ya pasó este mes y la fecha de fin no alcanza al mes siguiente"`.
   - No call to `templateDao.insert`.
   - No call to `RecurringGenerationService.generateForTemplate`.
3. Otherwise proceed with the existing save path.

Validation runs only for `periodicity == Periodicity.mensual`. Annual templates are out of scope (per FR-005).
