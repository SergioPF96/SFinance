import 'package:drift/drift.dart';

@DataClassName('InitialCapitalRow')
class InitialCapitalTable extends Table {
  @override
  String get tableName => 'initial_capital';

  /// Fixed to 1 — enforces single-row constraint.
  IntColumn get id => integer()();

  IntColumn get amountCents => integer()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
