import 'package:drift/drift.dart';

@DataClassName('RecurringTemplateRow')
class RecurringTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();

  /// "income" or "expense".
  TextColumn get transactionType => text()();

  /// "suscripcion", "financiacion" (expense) or "salario" (income).
  TextColumn get category => text()();

  /// "mensual" or "anual".
  TextColumn get periodicity => text()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  /// "docepagas" or "catorcepagas". Null for non-salary templates.
  TextColumn get payFrequency => text().nullable()();

  /// 1–12. Null unless payFrequency = catorcepagas.
  IntColumn get extraPayMonth1 => integer().nullable()();

  /// 1–12. Must differ from extraPayMonth1.
  IntColumn get extraPayMonth2 => integer().nullable()();

  /// Period key of the last generated transaction. Null before first generation.
  TextColumn get lastGeneratedPeriod => text().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
