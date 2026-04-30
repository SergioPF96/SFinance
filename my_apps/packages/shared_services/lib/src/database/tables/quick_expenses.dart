import 'package:drift/drift.dart';

@DataClassName('QuickExpenseRow')
class QuickExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();

  /// ExpenseCategory enum name string (e.g. "producto", "suscripcion").
  TextColumn get category => text()();

  /// Absolute internal-storage path. Null ⇒ show generic icon.
  TextColumn get imagePath => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
