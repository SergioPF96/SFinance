import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/quick_expenses.dart';

part 'quick_expense_dao.g.dart';

@DriftAccessor(tables: [QuickExpenses])
class QuickExpenseDao extends DatabaseAccessor<AppDatabase>
    with _$QuickExpenseDaoMixin {
  QuickExpenseDao(super.db);

  /// Inserts a new quick expense and returns its generated id.
  Future<int> insert(QuickExpensesCompanion entry) =>
      into(quickExpenses).insert(entry);

  /// Updates name, amount, category, and/or imagePath of an existing row.
  /// Returns the number of rows affected (0 or 1).
  Future<int> updateById(int id, QuickExpensesCompanion patch) {
    return (update(quickExpenses)..where((t) => t.id.equals(id))).write(patch);
  }

  /// Hard-deletes the row. Caller is responsible for image file cleanup.
  Future<int> deleteById(int id) {
    return (delete(quickExpenses)..where((t) => t.id.equals(id))).go();
  }

  /// Stream all quick expenses ordered by createdAt ASC (oldest first).
  Stream<List<QuickExpenseRow>> watchAll() {
    return (select(quickExpenses)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// One-shot fetch by id. Returns null if not found.
  Future<QuickExpenseRow?> findById(int id) {
    return (select(quickExpenses)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
