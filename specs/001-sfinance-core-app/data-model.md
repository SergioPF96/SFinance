# Data Model: SFinance Core Application

**Branch**: `001-sfinance-core-app` | **Date**: 2026-04-06

## Enums

### TransactionType
```
income, expense
```
Discriminates the sign of a transaction for display and aggregation.

### ExpenseCategory
```
producto, servicio, suscripcion, suministroVariable, financiacion
```
Display labels: "Producto", "Servicio", "Suscripcion", "Suministro variable", "Financiacion".
Stored as lowercase enum name via `EnumNameConverter`.

### IncomeCategory
```
salario, venta, servicio
```
Display labels: "Salario", "Venta", "Servicio".

### Periodicity
```
mensual, anual
```

### PayFrequency
```
docepagas, catorcepagas
```
Only applicable when IncomeCategory is `salario`.

## Entities

### Transaction

The fundamental financial event record. Immutable after creation (read-only; deletable only from Entradas > Transacciones).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | `int` (autoincrement PK) | NOT NULL, UNIQUE | Drift-generated |
| name | `String` | NOT NULL, non-empty | User-provided label |
| amountCents | `int` | NOT NULL, > 0 | Always positive; sign determined by `transactionType` |
| description | `String?` | nullable | Optional user note |
| transactionType | `TransactionType` | NOT NULL | `income` or `expense` |
| category | `String` | NOT NULL | Stored as enum name string. Represents either an ExpenseCategory or IncomeCategory depending on transactionType |
| date | `DateTime` | NOT NULL | Date of the financial event |
| templateId | `int?` | nullable, FK -> RecurringTemplate.id (SET NULL on delete) | NULL for one-off transactions; points to source template for generated entries |
| createdAt | `DateTime` | NOT NULL, default now | Record creation timestamp |

**Validation rules**:
- `amountCents` must be strictly positive (> 0). Zero and negative rejected at form level.
- `name` must be non-empty after trimming.
- `category` must be a valid member of ExpenseCategory (when transactionType=expense) or IncomeCategory (when transactionType=income).
- `date` is system-set (today for one-off, period date for generated).

**Indexes**:
- `(date DESC)` — primary query pattern for all transaction lists.
- `(templateId)` — for checking generated entries per template.

### RecurringTemplate

Blueprint for automatic transaction generation. Immutable after creation; can only be deleted (stops future generation, preserves past entries).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | `int` (autoincrement PK) | NOT NULL, UNIQUE | Drift-generated |
| name | `String` | NOT NULL, non-empty | User-provided label |
| amountCents | `int` | NOT NULL, > 0 | Monthly/annual amount in cents |
| transactionType | `TransactionType` | NOT NULL | `income` or `expense` |
| category | `String` | NOT NULL | Must be one of: suscripcion, financiacion (expense) or salario (income) |
| periodicity | `Periodicity` | NOT NULL | `mensual` or `anual` |
| startDate | `DateTime` | NOT NULL | Always set to creation date (today) |
| endDate | `DateTime` | NOT NULL | User-selected; must be >= startDate |
| payFrequency | `PayFrequency?` | nullable | Only for salario: docepagas or catorcepagas |
| extraPayMonth1 | `int?` | nullable, 1-12 | First extra-payment month (only for 14 pagas) |
| extraPayMonth2 | `int?` | nullable, 1-12 | Second extra-payment month (only for 14 pagas); must differ from extraPayMonth1 |
| lastGeneratedPeriod | `String?` | nullable | Period key of last generated transaction (e.g., "2026-04", "2026-07-extra") |
| isDeleted | `bool` | NOT NULL, default false | Soft-delete flag; stops generation but preserves record for FK integrity |
| createdAt | `DateTime` | NOT NULL, default now | Record creation timestamp |

**Validation rules**:
- `category` must be `suscripcion` or `financiacion` when transactionType=expense; `salario` when transactionType=income.
- `endDate` must be >= today (enforced at form level).
- `extraPayMonth1` and `extraPayMonth2` must be distinct when both are set.
- `payFrequency` is required when category=salario; null otherwise.
- `extraPayMonth1` and `extraPayMonth2` are required when payFrequency=catorcepagas; null otherwise.

**Note on deletion**: Uses soft-delete (`isDeleted = true`) rather than hard delete to preserve FK integrity with existing Transaction records. The generation algorithm filters out templates where `isDeleted = true`.

### InitialCapital

Single-row table representing the user's starting balance before any transactions exist.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | `int` | NOT NULL, PK, CHECK(id = 1) | Fixed to 1; enforces single row |
| amountCents | `int` | NOT NULL, >= 0 | Initial capital in cents |
| isActive | `bool` | NOT NULL, default true | Set to false when first transaction is saved; never reactivated |

**Validation rules**:
- Only one row can ever exist (enforced by fixed PK).
- `isActive` transitions from true -> false exactly once (when first transaction is saved) and never reverts.
- When `isActive` is false, `amountCents` is irrelevant to Balance computation.

**State transitions**:
```
[No row exists] --(user enters initial capital)--> [id=1, amountCents=X, isActive=true]
[isActive=true]  --(first transaction saved)-----> [isActive=false]
```

## Relationships

```
RecurringTemplate 1 ----> * Transaction
  (via Transaction.templateId FK, SET NULL on template hard-delete)

InitialCapital (standalone, no FK relationships)
```

- A `Transaction` with `templateId = NULL` is a one-off entry.
- A `Transaction` with `templateId != NULL` was generated from that template.
- Deleting a template (soft-delete) does NOT cascade to transactions; generated entries persist unchanged.

## Computed Values (never stored)

These are always computed at read-time, never cached in the database:

| Value | Computation |
|-------|-------------|
| Monthly Ingresos | SUM(amountCents) WHERE transactionType=income AND date in current calendar month |
| Monthly Gastos | SUM(amountCents) WHERE transactionType=expense AND date in current calendar month |
| Balance | SUM(amountCents WHERE transactionType=income) - SUM(amountCents WHERE transactionType=expense) + (initialCapital.amountCents IF isActive) |
| Chart data points | Aggregated per period from Transaction table with date range filters |

## Period Key Specification

Used in `RecurringTemplate.lastGeneratedPeriod` to track generation progress:

| Periodicity | Format | Example | Sort order |
|-------------|--------|---------|------------|
| Monthly | `"YYYY-MM"` | `"2026-04"` | Lexicographic |
| Annual | `"YYYY"` | `"2026"` | Lexicographic |
| 14-paga extra | `"YYYY-MM-extra"` | `"2026-07-extra"` | After regular `"YYYY-MM"` for same month |

For 14-paga salary in a bonus month, two keys are generated in order:
1. `"2026-07"` (regular monthly salary)
2. `"2026-07-extra"` (bonus payment)

Both produce separate Transaction entries of equal `amountCents`.
