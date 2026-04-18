import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/transactions.dart';
import 'tables/recurring_templates.dart';
import 'tables/initial_capital.dart';
import 'daos/transaction_dao.dart';
import 'daos/template_dao.dart';
import 'daos/initial_capital_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, RecurringTemplates, InitialCapitalTable],
  daos: [TransactionDao, TemplateDao, InitialCapitalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Add payment_day column (nullable for backward compatibility).
          await migrator.addColumn(
            recurringTemplates,
            recurringTemplates.paymentDay,
          );
          // Backfill existing rows: treat all pre-feature templates as day 1.
          await customStatement(
            'UPDATE recurring_templates SET payment_day = 1 WHERE payment_day IS NULL',
          );
        }
        if (from < 3) {
          // Make end_date nullable to support open-ended subscriptions (spec 007).
          // SQLite does not support ALTER COLUMN, so we recreate the table.
          await customStatement('''
            CREATE TABLE recurring_templates_new (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              amount_cents INTEGER NOT NULL,
              transaction_type TEXT NOT NULL,
              category TEXT NOT NULL,
              periodicity TEXT NOT NULL,
              start_date INTEGER NOT NULL,
              end_date INTEGER,
              pay_frequency TEXT,
              extra_pay_month1 INTEGER,
              extra_pay_month2 INTEGER,
              payment_day INTEGER,
              last_generated_period TEXT,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
          ''');
          await customStatement('''
            INSERT INTO recurring_templates_new
              SELECT id, name, amount_cents, transaction_type, category,
                     periodicity, start_date, end_date, pay_frequency,
                     extra_pay_month1, extra_pay_month2, payment_day,
                     last_generated_period, is_deleted, created_at
              FROM recurring_templates
          ''');
          await customStatement('DROP TABLE recurring_templates');
          await customStatement(
              'ALTER TABLE recurring_templates_new RENAME TO recurring_templates');
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sfinance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
