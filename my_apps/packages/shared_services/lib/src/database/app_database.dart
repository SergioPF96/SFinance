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
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sfinance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
