import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/transaction_providers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

final _range = DateTimeRange(
  start: DateTime(2024, 1, 1),
  end: DateTime(2030, 12, 31),
);

Future<int> insertTemplate(AppDatabase db) async {
  return db.into(db.recurringTemplates).insert(
        RecurringTemplatesCompanion.insert(
          name: 'Salario',
          amountCents: 200000,
          transactionType: 'income',
          category: 'salario',
          periodicity: 'mensual',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );
}

Future<void> insertTransactionForTemplate(
  AppDatabase db,
  int templateId, {
  required DateTime date,
}) async {
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          name: 'Salario',
          amountCents: 200000,
          transactionType: 'income',
          category: 'salario',
          date: date,
          templateId: Value(templateId),
        ),
      );
}

Future<void> insertOneOffTransaction(AppDatabase db, {required DateTime date}) async {
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          name: 'One-off income',
          amountCents: 50000,
          transactionType: 'income',
          category: 'salario',
          date: date,
        ),
      );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('unifiedEntriesProvider — isRecurring derivation', () {
    test(
        'one-off transaction (no templateId) → isRecurring = false',
        () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertOneOffTransaction(db, date: DateTime(2025, 6, 1));

      final entries = await container.read(unifiedEntriesProvider(_range).future);

      expect(entries.length, 1);
      expect(entries.first.isRecurring, false);
      expect(entries.first.templateId, null);
    });

    test(
        'transaction from active template → isRecurring = true',
        () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final templateId = await insertTemplate(db);
      await insertTransactionForTemplate(db, templateId, date: DateTime(2025, 6, 1));

      final entries = await container.read(unifiedEntriesProvider(_range).future);

      expect(entries.length, 1);
      expect(entries.first.isRecurring, true);
      expect(entries.first.templateId, templateId);
    });

    test(
        'transaction from cancelled template → isRecurring = false',
        () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final templateId = await insertTemplate(db);
      await insertTransactionForTemplate(db, templateId, date: DateTime(2025, 6, 1));

      // Cancel the template
      await db.transactionDao.watchFilteredWithTemplateStatus(
        start: DateTime(2024, 1, 1),
        end: DateTime(2030, 1, 1),
      ).first; // warm up stream
      await (db.update(db.recurringTemplates)
            ..where((t) => t.id.equals(templateId)))
          .write(const RecurringTemplatesCompanion(isDeleted: Value(true)));

      final entries = await container.read(unifiedEntriesProvider(_range).future);

      expect(entries.length, 1);
      expect(entries.first.isRecurring, false);
    });

    test('results ordered by date DESC', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertOneOffTransaction(db, date: DateTime(2025, 3, 1));
      await insertOneOffTransaction(db, date: DateTime(2025, 6, 1));
      await insertOneOffTransaction(db, date: DateTime(2025, 1, 1));

      final entries = await container.read(unifiedEntriesProvider(_range).future);

      expect(entries.length, 3);
      expect(entries[0].date, DateTime(2025, 6, 1));
      expect(entries[1].date, DateTime(2025, 3, 1));
      expect(entries[2].date, DateTime(2025, 1, 1));
    });

    test('mix of one-off and recurring in same list', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final templateId = await insertTemplate(db);
      await insertTransactionForTemplate(db, templateId, date: DateTime(2025, 6, 1));
      await insertOneOffTransaction(db, date: DateTime(2025, 5, 1));

      final entries = await container.read(unifiedEntriesProvider(_range).future);

      expect(entries.length, 2);
      final recurring = entries.firstWhere((e) => e.isRecurring);
      final oneOff = entries.firstWhere((e) => !e.isRecurring);
      expect(recurring.templateId, templateId);
      expect(oneOff.templateId, null);
    });
  });
}
