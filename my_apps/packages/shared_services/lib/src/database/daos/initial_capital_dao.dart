import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/initial_capital.dart';

part 'initial_capital_dao.g.dart';

@DriftAccessor(tables: [InitialCapitalTable])
class InitialCapitalDao extends DatabaseAccessor<AppDatabase>
    with _$InitialCapitalDaoMixin {
  InitialCapitalDao(super.db);

  /// Returns the single InitialCapital row, or null if not set yet.
  Future<InitialCapitalRow?> get() {
    return (select(initialCapitalTable)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  /// Inserts or updates the single capital row (id always = 1).
  Future<void> upsert(int amountCents) async {
    await into(initialCapitalTable).insertOnConflictUpdate(
      InitialCapitalTableCompanion.insert(
        id: const Value(1),
        amountCents: amountCents,
        isActive: const Value(true),
      ),
    );
  }

  /// Sets isActive=false. Called when the first transaction is saved.
  Future<void> deactivate() async {
    await (update(initialCapitalTable)..where((t) => t.id.equals(1))).write(
      const InitialCapitalTableCompanion(isActive: Value(false)),
    );
  }

  Stream<InitialCapitalRow?> watch() {
    return (select(initialCapitalTable)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }
}
