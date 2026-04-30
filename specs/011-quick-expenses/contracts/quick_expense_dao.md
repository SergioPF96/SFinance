# Contract: `QuickExpenseDao`

**Location**: `packages/shared_services/lib/src/database/daos/quick_expense_dao.dart`

The DAO is the only API the app layer uses to read or write quick expenses.
It is a Drift `DatabaseAccessor` over the `QuickExpenses` table, mirroring
the pattern of `TransactionDao` and `TemplateDao`.

## Public API (target signatures)

```dart
@DriftAccessor(tables: [QuickExpenses])
class QuickExpenseDao extends DatabaseAccessor<AppDatabase>
    with _$QuickExpenseDaoMixin {
  QuickExpenseDao(super.db);

  /// Inserts a new quick expense and returns its generated id.
  /// Throws [InvalidDataException] if `name` is empty or `amountCents <= 0`.
  Future<int> insert(QuickExpensesCompanion entry);

  /// Updates name, amount, category, and/or imagePath of an existing row.
  /// Returns the number of rows affected (0 or 1).
  /// Pass `Value(null)` for `imagePath` to remove an image association.
  Future<int> update(int id, QuickExpensesCompanion patch);

  /// Hard-deletes the row. Returns the number of rows affected.
  /// The caller (provider) is responsible for asking ImageStorageService to
  /// delete the associated image file, if any.
  Future<int> deleteById(int id);

  /// Stream all quick expenses ordered by createdAt ASC (oldest first).
  /// Used by both the "+Gasto" card row and the Frecuentes tab.
  Stream<List<QuickExpenseRow>> watchAll();

  /// One-shot fetch (used during edit-dialog initialization to avoid
  /// race conditions with the stream).
  Future<QuickExpenseRow?> findById(int id);
}
```

## Behavioral contract

- **Ordering**: `watchAll()` emits rows in `createdAt ASC` order. UI
  treats this as "oldest first" (per spec assumption).
- **Reactivity**: The stream re-emits whenever the table is mutated, so
  `quickExpensesStreamProvider` re-renders both the +Gasto card row and the
  Frecuentes tab without manual invalidation.
- **No soft delete**: Unlike `TemplateDao.softDelete`, `deleteById` removes
  the row entirely (rationale in research R-4).
- **No filesystem awareness**: The DAO does not touch image files; that is
  the `ImageStorageService`'s responsibility.

## Test contract (`quick_expense_dao_test.dart`)

Tests use `AppDatabase.forTesting(NativeDatabase.memory())`.

- `insert` happy path → row appears in `watchAll()` stream
- `insert` rejects empty name (validated at DAO level via Drift constraint
  or wrapping in companion-validating helper — implementation detail)
- `update` with all fields → row reflects new values
- `update` with `imagePath: Value(null)` → row's `imagePath` becomes null
- `deleteById` removes row → next stream emit excludes it
- `watchAll` ordering is stable across consecutive emits and across inserts
- `findById` returns `null` for unknown id, row for known id
