import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/services/recurring_generation_service.dart';

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

Future<int> insertTemplate(
  AppDatabase db, {
  required String name,
  required String periodicity,
  required DateTime startDate,
  required DateTime endDate,
  String? lastGeneratedPeriod,
  String transactionType = 'income',
  String category = 'salario',
  bool isDeleted = false,
  String? payFrequency,
  int? extraPayMonth1,
  int? extraPayMonth2,
}) async {
  return db.into(db.recurringTemplates).insert(
        RecurringTemplatesCompanion.insert(
          name: name,
          amountCents: 100000,
          transactionType: transactionType,
          category: category,
          periodicity: periodicity,
          startDate: startDate,
          endDate: endDate,
          lastGeneratedPeriod: Value(lastGeneratedPeriod),
          isDeleted: Value(isDeleted),
          payFrequency: Value(payFrequency),
          extraPayMonth1: Value(extraPayMonth1),
          extraPayMonth2: Value(extraPayMonth2),
        ),
      );
}

Future<List<TransactionRow>> getTransactions(AppDatabase db) {
  return db.select(db.transactions).get();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RecurringGenerationService', () {
    final jan2026 = DateTime(2026, 1, 1);
    final dec2026 = DateTime(2026, 12, 31);

    test('generates exactly one entry on first save (current period)', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Salario',
          periodicity: 'mensual',
          startDate: jan2026,
          endDate: dec2026,
          lastGeneratedPeriod: '2026-01', // already generated first entry
      );

      final today = DateTime(2026, 2, 15);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      // Should generate one entry for Feb 2026
      expect(txs.length, 1);
      expect(txs.first.name, 'Salario');
    });

    test('generates all due periods when app not opened for months', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Suscripcion',
          periodicity: 'mensual',
          startDate: jan2026,
          endDate: dec2026,
          lastGeneratedPeriod: '2026-01',
          transactionType: 'expense',
          category: 'suscripcion',
      );

      // Simulate app launched 4 months later
      final today = DateTime(2026, 5, 1);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      // Should generate Feb, Mar, Apr, May = 4 entries
      expect(txs.length, 4);
    });

    test('generates extra entry for 14-paga bonus months', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      // Template: monthly salary, 14-paga, bonus in July and December
      final templateId = await insertTemplate(db,
          name: 'Salario 14 pagas',
          periodicity: 'mensual',
          startDate: jan2026,
          endDate: dec2026,
          lastGeneratedPeriod: '2026-06',
          payFrequency: 'catorcepagas',
          extraPayMonth1: 7,
          extraPayMonth2: 12,
      );

      // Launch in July: should generate regular July + extra July
      final today = DateTime(2026, 7, 1);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 2);
      expect(txs.every((t) => t.templateId == templateId), isTrue);
    });

    test('does not duplicate already-generated periods', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Salario',
          periodicity: 'mensual',
          startDate: jan2026,
          endDate: dec2026,
          lastGeneratedPeriod: '2026-04',
      );

      // Same-day re-launch — April already generated
      final today = DateTime(2026, 4, 15);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs, isEmpty);
    });

    test('stops generation at endDate', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Suscripcion',
          periodicity: 'mensual',
          startDate: jan2026,
          endDate: DateTime(2026, 3, 31), // ends in March
          lastGeneratedPeriod: '2026-01',
          transactionType: 'expense',
          category: 'suscripcion',
      );

      // Launch in June — should only generate Feb and Mar
      final today = DateTime(2026, 6, 1);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 2); // Feb and Mar only
    });

    test('skips soft-deleted templates', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Deleted sub',
          periodicity: 'mensual',
          startDate: jan2026,
          endDate: dec2026,
          lastGeneratedPeriod: '2026-01',
          isDeleted: true,
          transactionType: 'expense',
          category: 'suscripcion',
      );

      final today = DateTime(2026, 3, 1);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs, isEmpty);
    });

    test('annual template generates one entry per year', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Seguro',
          periodicity: 'anual',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2026, 12, 31),
          lastGeneratedPeriod: '2024',
          transactionType: 'expense',
          category: 'suscripcion',
      );

      final today = DateTime(2026, 4, 7);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 2); // 2025 and 2026
    });
  });
}
