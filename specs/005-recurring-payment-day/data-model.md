# Data Model: 005 — Recurring Payment Day

## Entity Changes

### RecurringTemplate (modified)

**Package**: `shared_models` — `lib/src/recurring_template.dart`

| Field | Type | New? | Constraints | Notes |
|-------|------|------|-------------|-------|
| `id` | `int` | — | PK, autoIncrement | |
| `name` | `String` | — | NOT NULL | |
| `amountCents` | `int` | — | NOT NULL, > 0 | |
| `transactionType` | `String` | — | "income" / "expense" | |
| `category` | `String` | — | enum name | |
| `periodicity` | `Periodicity` | — | "mensual" / "anual" | |
| **`paymentDay`** | **`int`** | **YES** | **1–31, NOT NULL for new rows; nullable at DB level for migration** | **Default: 1. Clamped to month length at generation time.** |
| `startDate` | `DateTime` | — | NOT NULL | |
| `endDate` | `DateTime` | — | NOT NULL | |
| `payFrequency` | `PayFrequency?` | — | nullable | Salary only |
| `extraPayMonth1` | `int?` | — | 1–12, nullable | 14-pagas only |
| `extraPayMonth2` | `int?` | — | 1–12, nullable | 14-pagas only |
| `lastGeneratedPeriod` | `String?` | — | nullable | High-water mark |
| `isDeleted` | `bool` | — | default false | Soft-delete |
| `createdAt` | `DateTime` | — | default now | |

#### Validation Rules

- `paymentDay` must be in range `[1, 31]` at creation time.
- For annual recurring with a specific end-date month, the form UI clamps the selector max to `daysInMonth(endDate)`, but the stored value can be up to 31 (clamping happens at generation time to handle leap years).
- `paymentDay` is immutable after creation (FR-006 / FR-010).

#### State Transitions

No new states. The existing lifecycle is unchanged:
- **Active** (`isDeleted == false`) → generates occurrences
- **Cancelled** (`isDeleted == true`) → no future generation, past entries preserved

---

### RecurringTemplates Drift Table (modified)

**Package**: `shared_services` — `lib/src/database/tables/recurring_templates.dart`

New column:

```dart
/// Day of month for payment/charge (1–31). Null for pre-feature templates
/// (treated as 1 by application logic).
IntColumn get paymentDay => integer().nullable()();
```

#### Migration: v1 → v2

```sql
ALTER TABLE recurring_templates ADD COLUMN payment_day INTEGER;
UPDATE recurring_templates SET payment_day = 1 WHERE payment_day IS NULL;
```

The column is nullable at the DB level. Application logic treats `null` as `1`.

---

### TransactionDisplay (modified — app layer)

**File**: `apps/sfinance/lib/providers/transaction_providers.dart`

New fields for badge display:

| Field | Type | Notes |
|-------|------|-------|
| `paymentDay` | `int?` | From template, null for one-off |
| `periodicity` | `String?` | From template, null for one-off |

These fields flow from the LEFT JOIN in `watchFilteredWithTemplateStatus()`, which already joins `recurring_templates`. The query adds `payment_day` and `periodicity` to the select.

---

### TransactionRow (modified — shared_ui)

**File**: `packages/shared_ui/lib/src/widgets/transaction_row.dart`

New parameter:

| Field | Type | Notes |
|-------|------|-------|
| `recurringDetail` | `String?` | e.g. "Día 15 de cada mes", "10 de junio" |

When non-null, displayed as a small text label near the repeat icon badge.

---

## Relationships

```
RecurringTemplate (1) ──── paymentDay (int, 1-31)
       │
       │ templateId (FK)
       ▼
Transaction (N) ──── date (DateTime, computed from paymentDay + period)
```

No new relationships. The existing `templateId` FK on `Transactions` is unchanged.

---

## Generation Logic Changes

### `RecurringGenerationService._dateForPeriod()`

Currently hardcodes day `1`. Changes to:

```
_dateForPeriod(periodKey, template):
  paymentDay = template.paymentDay ?? 1
  
  if periodKey is "YYYY-MM" or "YYYY-MM-extra":
    year, month = parse(periodKey)
    day = min(paymentDay, daysInMonth(year, month))
    return DateTime(year, month, day)
  
  if periodKey is "YYYY" (annual):
    year = parse(periodKey)
    month = template.endDate.month
    day = min(paymentDay, daysInMonth(year, month))
    return DateTime(year, month, day)
```

### Form submit — first occurrence

Both `ExpenseFormNotifier.submit()` and `IncomeFormNotifier.submit()` change:

```
today = DateTime.now()
clampedDay = min(paymentDay, daysInMonth(today.year, today.month))

if clampedDay < today.day:
  // Day already passed this month → first occurrence next month
  nextMonth = DateTime(today.year, today.month + 1)
  clampedDayNext = min(paymentDay, daysInMonth(nextMonth.year, nextMonth.month))
  firstDate = DateTime(nextMonth.year, nextMonth.month, clampedDayNext)
  periodKey = monthKey(nextMonth)
else:
  firstDate = DateTime(today.year, today.month, clampedDay)
  periodKey = monthKey(today)
```

### `PeriodGenerator`

**No changes needed.** Period keys remain `"YYYY-MM"` / `"YYYY"` / `"YYYY-MM-extra"`. The generator identifies *which* periods are due; `_dateForPeriod` resolves the exact date using `paymentDay`.

However, the `startDate` for the template must be set correctly at creation time so that `PeriodGenerator` includes the right first period:
- If first occurrence is this month → `startDate` = first of current month
- If first occurrence is next month → `startDate` = first of next month
