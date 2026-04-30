# Phase 1: Data Model — Quick Expenses

## Entity: QuickExpense

A reusable shortcut that pre-fills the "+Gasto" expense form. Stored in a
new `quick_expenses` Drift table; mirrored as a pure-Dart `QuickExpense`
class in `shared_models`.

### Fields

| Field          | Dart type             | Drift column          | Required | Notes                                                                                |
|----------------|-----------------------|-----------------------|----------|--------------------------------------------------------------------------------------|
| `id`           | `int`                 | `IntColumn` autoIncrement PK | yes      | Drift-managed surrogate key.                                                         |
| `name`         | `String`              | `TextColumn`          | yes      | Trimmed; non-empty enforced at save time. No uniqueness constraint (per spec edge case). |
| `amountCents`  | `int`                 | `IntColumn`           | yes      | Always `int`, never `double`. Parsed via the same algorithm as `ExpenseFormNotifier.submit()`: `(double × 100).round()`. |
| `category`     | `ExpenseCategory`     | `TextColumn` (enum name) | yes      | Stored as `enum.name` string for forward-compat; reuses the existing `ExpenseCategory` enum. |
| `imagePath`    | `String?`             | `TextColumn().nullable()` | no       | Absolute path to the internal-storage copy. `null` ⇒ render generic icon on the card. |
| `createdAt`    | `DateTime`            | `DateTimeColumn` `withDefault(currentDateAndTime)` | yes (auto) | Used solely to order cards and Frecuentes-tab rows oldest-first.                     |

### Constraints / invariants

- `name` MUST be non-empty after trimming. Enforced in
  `QuickExpenseEditFormNotifier.save()`. The "Guardar como gasto común" button
  in the +Gasto modal is `disabled` when name **or** amount is empty
  (FR-004); the edit dialog applies the same check before allowing confirm.
- `amountCents` MUST be `> 0`. Same parsing rules as the existing expense
  form. Enforced before insert/update.
- `category` MUST be a valid `ExpenseCategory` enum value. The dropdown only
  exposes legal values, so the constraint is enforced by the UI and again
  defensively when reading rows back (`ExpenseCategory.values.byName(...)`,
  with a logged-and-discarded fallback if the database holds a stale name from
  a future schema downgrade — defensive only, not expected to fire).
- `imagePath`, when non-null, MUST point inside the
  `quick_expense_images/` directory under
  `getApplicationDocumentsDirectory()`. The DAO does not enforce this — it is
  the responsibility of `ImageStorageService` to only ever return such paths.

### State transitions

QuickExpense has a simple lifecycle:

```text
                ┌─────────┐
   create() ──▶ │ Created │
                └────┬────┘
                     │ (any field changed via edit dialog)
                     ▼
                ┌─────────┐
                │ Edited  │ ◀── update() ──┐
                └────┬────┘                 │
                     │                       │ (image replaced or removed
                     │ delete()              │  → Edited again, image file
                     ▼                       │  cleanup is best-effort)
                ┌─────────┐                  │
                │ Deleted │ ◀────────────────┘
                └─────────┘
                     │ image file (if any) removed from
                     │ quick_expense_images/ after row delete commits
```

## Entity: image file (logical, not stored in DB)

For each QuickExpense whose `imagePath` is non-null, exactly one file exists
at that path inside `quick_expense_images/`.

### Naming

`<quickExpenseId>_<copyTimestampMs>.<ext>` — for example
`12_1714400000000.jpg`. The id and timestamp guarantee uniqueness even when
the same QuickExpense's image is replaced repeatedly within a session.

### Lifecycle (managed by `ImageStorageService`)

1. **Create**: copy picked file → new internal filename → return absolute
   path. If `File.copy` throws, surface error and do not modify any state.
2. **Replace** (existing image → new image): copy first under a new filename
   → DAO update writes the new path → on success, delete old file
   (best-effort).
3. **Remove** (existing image → no image): DAO update sets `imagePath = null`
   → delete old file (best-effort).
4. **QuickExpense delete**: DAO `DELETE` row → delete file (best-effort).

## Relationships

QuickExpense has **no foreign keys** — it does not reference any other table.
It is a self-contained shortcut. Importantly:
- It does **not** reference `transactions` (a generated expense from a
  shortcut is a normal `TransactionRow` with no link back to the shortcut).
- It does **not** reference `recurring_templates` (shortcuts are not
  recurring templates).

## Drift schema (target SQL, schemaVersion 4)

```sql
CREATE TABLE quick_expenses (
  id            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  amount_cents  INTEGER NOT NULL,
  category      TEXT    NOT NULL,
  image_path    TEXT,
  created_at    INTEGER NOT NULL DEFAULT (strftime('%s','now'))
);
```

(Drift generates equivalent SQL from the `Table` subclass; this is the
expected output, used for migration test assertions.)

## Migration v3 → v4

```dart
if (from < 4) {
  await m.createTable(quickExpenses);
}
```

No data backfill; the table starts empty.

## Test data shape (used in `quick_expense_dao_test.dart`)

A canonical fixture row used across tests:

```dart
const fixtureCafe = QuickExpensesCompanion(
  name: Value('Café'),
  amountCents: Value(150),
  category: Value('producto'),
  imagePath: Value(null),
);
```

A second fixture with image:

```dart
final fixtureSpotify = QuickExpensesCompanion(
  name: const Value('Spotify'),
  amountCents: const Value(999),
  category: const Value('suscripcion'),
  imagePath: Value('${tmpDir.path}/quick_expense_images/2_1714400000000.png'),
);
```
