import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<int> insert(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  /// Most recent [limit] transactions, ordered by date DESC.
  Stream<List<TransactionRow>> watchRecent({int limit = 10}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  /// All transactions, ordered by date DESC.
  Stream<List<TransactionRow>> watchAll() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Transactions within the given date range, ordered by date DESC.
  Stream<List<TransactionRow>> watchFiltered({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Transactions within [months] calendar months back from now.
  Stream<List<TransactionRow>> watchMonthly({required int months}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);
    return watchFiltered(start: start, end: now);
  }

  Future<int> deleteById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
