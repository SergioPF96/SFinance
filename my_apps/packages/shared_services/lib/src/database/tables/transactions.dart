import 'package:drift/drift.dart';
import 'recurring_templates.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();
  TextColumn get description => text().nullable()();

  /// "income" or "expense" — stored via EnumNameConverter.
  TextColumn get transactionType => text()();

  /// ExpenseCategory or IncomeCategory enum name string.
  TextColumn get category => text()();

  DateTimeColumn get date => dateTime()();

  /// Null for one-off transactions.
  IntColumn get templateId =>
      integer().nullable().references(RecurringTemplates, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
