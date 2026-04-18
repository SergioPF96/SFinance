# Data Model: Unified Entries View

**Branch**: `003-unify-entries-view` | **Date**: 2026-04-12

## Existing Entities (no schema changes)

### Transactions table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | int | no | PK, auto-increment |
| name | text | no | |
| amountCents | int | no | |
| description | text | yes | |
| transactionType | text | no | "income" or "expense" |
| category | text | no | Enum name string |
| date | datetime | no | |
| templateId | int | yes | FK → RecurringTemplates.id. **Null for one-off entries.** |
| createdAt | datetime | no | Default: current time |

### RecurringTemplates table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | int | no | PK, auto-increment |
| name | text | no | |
| amountCents | int | no | |
| transactionType | text | no | "income" or "expense" |
| category | text | no | |
| periodicity | text | no | "mensual" or "anual" |
| startDate | datetime | no | |
| endDate | datetime | no | |
| payFrequency | text | yes | "docepagas" or "catorcepagas" |
| extraPayMonth1 | int | yes | |
| extraPayMonth2 | int | yes | |
| lastGeneratedPeriod | text | yes | |
| isDeleted | bool | no | Default: false. **Soft-delete flag.** |
| createdAt | datetime | no | Default: current time |

## Derived Display Model (provider layer)

### TransactionDisplay (modified)

Existing model in `transaction_providers.dart`, extended with one new field:

| Field | Type | Source | New? |
|-------|------|--------|------|
| id | int | TransactionRow.id | no |
| name | String | TransactionRow.name | no |
| categoryLabel | String | Derived from category enum | no |
| date | DateTime | TransactionRow.date | no |
| amountCents | int | TransactionRow.amountCents | no |
| transactionType | TransactionType | Derived from text column | no |
| iconColor | Color | Derived from transactionType | no |
| **isRecurring** | **bool** | **templateId != null AND template.isDeleted == false** | **yes** |
| **templateId** | **int?** | **TransactionRow.templateId** | **yes** |

### Recurrence status derivation

```
isRecurring = (transaction.templateId != null) AND (template.isDeleted == false)
```

- `templateId == null` → one-off entry → `isRecurring = false`
- `templateId != null` AND `template.isDeleted == false` → active recurring → `isRecurring = true`
- `templateId != null` AND `template.isDeleted == true` → orphaned entry (template cancelled) → `isRecurring = false`

## State Transitions (template lifecycle relevant to this feature)

```
RecurringTemplate: ACTIVE ──(softDelete)──→ CANCELLED (isDeleted = true)
                                              │
                                              ├── Future generation stops
                                              ├── All existing entries preserved
                                              └── Entries lose isRecurring = true (via join)
```

## New Query: watchFilteredWithTemplateStatus

**Location**: `TransactionDao` (shared_services)

**Purpose**: Returns transactions in a date range with their recurring status resolved via a left join to `RecurringTemplates`.

**Query shape** (Drift builder):
```
SELECT t.*, rt.isDeleted AS templateIsDeleted
FROM transactions t
LEFT JOIN recurring_templates rt ON t.templateId = rt.id
WHERE t.date BETWEEN :start AND :end
ORDER BY t.date DESC
```

Returns a stream of custom result objects containing all `TransactionRow` columns plus a nullable `bool templateIsDeleted`. The provider maps this to `TransactionDisplay` with the derived `isRecurring` flag.

## New Provider: selectedTimeRangeProvider

**Location**: `transaction_providers.dart`

**Purpose**: Replaces the `setState` usage for time range selection in the old `TransaccionesTab`.

**Type**: `StateProvider<TimeRange>` with default `TimeRange.ultimos7Dias`.

## Relationships

```
TransactionDisplay ←derives── TransactionRow ──FK(templateId)──→ RecurringTemplateRow
                                                                    │
                                                              isDeleted flag
                                                              determines badge
```

No new relationships. No schema changes. No migration needed.
