import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/domain/category_filter.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/transaction_providers.dart';

ProviderContainer makeContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

Future<void> insertTx(
  AppDatabase db, {
  required String category,
  String type = 'expense',
  int amountCents = 1000,
  DateTime? date,
}) async {
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          name: 'Test $category',
          amountCents: amountCents,
          transactionType: type,
          category: category,
          date: date ?? DateTime.now(),
        ),
      );
}

/// Reads filteredEntriesProvider by first awaiting the underlying stream.
Future<List<TransactionDisplay>> readFiltered(
    ProviderContainer container) async {
  final range = container.read(selectedTimeRangeProvider).toDateRange();
  await container.read(
    unifiedEntriesProvider(
      DateTimeRange(start: range.start, end: range.end),
    ).future,
  );
  return container.read(filteredEntriesProvider).requireValue;
}

void main() {
  group('filteredEntriesProvider', () {
    test('CategoryFilter.all returns all entries', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, category: 'suscripcion');
      await insertTx(db, category: 'producto');
      await insertTx(db, category: 'financiacion');

      container.read(selectedCategoryFilterProvider.notifier).state =
          CategoryFilter.all;

      final result = await readFiltered(container);
      expect(result.length, 3);
    });

    test('CategoryFilter.suscripcion returns only suscripcion entries',
        () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, category: 'suscripcion');
      await insertTx(db, category: 'producto');
      await insertTx(db, category: 'financiacion');

      container.read(selectedCategoryFilterProvider.notifier).state =
          CategoryFilter.suscripcion;

      final result = await readFiltered(container);
      expect(result.length, 1);
      expect(result.first.rawCategory, 'suscripcion');
    });

    test('filter by product', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, category: 'producto');
      await insertTx(db, category: 'suscripcion');

      container.read(selectedCategoryFilterProvider.notifier).state =
          CategoryFilter.producto;

      final result = await readFiltered(container);
      expect(result.length, 1);
      expect(result.first.rawCategory, 'producto');
    });

    test('filter with no matching entries returns empty list', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, category: 'suscripcion');

      container.read(selectedCategoryFilterProvider.notifier).state =
          CategoryFilter.venta;

      final result = await readFiltered(container);
      expect(result, isEmpty);
    });

    test('rawCategory is correctly populated in filtered results', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, category: 'financiacion');

      container.read(selectedCategoryFilterProvider.notifier).state =
          CategoryFilter.all;

      final result = await readFiltered(container);
      expect(result.first.rawCategory, 'financiacion');
    });
  });
}
