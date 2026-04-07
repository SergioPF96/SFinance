import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'database_provider.dart';

/// DAO providers — globally scoped, one per table.

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(databaseProvider).transactionDao;
});

final templateDaoProvider = Provider<TemplateDao>((ref) {
  return ref.watch(databaseProvider).templateDao;
});

final initialCapitalDaoProvider = Provider<InitialCapitalDao>((ref) {
  return ref.watch(databaseProvider).initialCapitalDao;
});

/// Internal stream providers — re-emit whenever the underlying DB table changes.

final allTransactionsStreamProvider =
    StreamProvider<List<TransactionRow>>((ref) {
  return ref.watch(transactionDaoProvider).watchAll();
});

final initialCapitalStreamProvider =
    StreamProvider<InitialCapitalRow?>((ref) {
  return ref.watch(initialCapitalDaoProvider).watch();
});
