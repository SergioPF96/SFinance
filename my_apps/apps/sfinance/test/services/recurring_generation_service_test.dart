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
  int? paymentDay,
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
          paymentDay: Value(paymentDay),
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

  // -------------------------------------------------------------------------
  // T006 — _dateForPeriod() with paymentDay (monthly + annual)
  // These tests FAIL until T008 and T016 are implemented.
  // -------------------------------------------------------------------------
  group('_dateForPeriod() with paymentDay — T006', () {
    test('monthly: paymentDay=15 → 15th of period month', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Sub 15',
          periodicity: 'mensual',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          lastGeneratedPeriod: '2026-03',
          transactionType: 'expense',
          category: 'suscripcion',
          paymentDay: 15,
      );

      final today = DateTime(2026, 4, 15);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 1);
      expect(txs.first.date.day, 15,
          reason: 'Transaction date must be the 15th');
    });

    test('monthly: paymentDay=31 in February → last day of Feb (28)', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Sub 31',
          periodicity: 'mensual',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2027, 12, 31),
          lastGeneratedPeriod: '2026-01',
          transactionType: 'expense',
          category: 'suscripcion',
          paymentDay: 31,
      );

      final today = DateTime(2026, 2, 28);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 1);
      expect(txs.first.date, DateTime(2026, 2, 28),
          reason: 'Day 31 clamped to 28 in February 2026');
    });

    test('monthly: paymentDay=31 in March → 31st of March', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Sub 31',
          periodicity: 'mensual',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2027, 12, 31),
          lastGeneratedPeriod: '2026-02',
          transactionType: 'expense',
          category: 'suscripcion',
          paymentDay: 31,
      );

      final today = DateTime(2026, 3, 31);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 1);
      expect(txs.first.date, DateTime(2026, 3, 31),
          reason: 'March has 31 days — no clamping needed');
    });

    test('annual: paymentDay=10, endDate.month=6 → June 10 of period year', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Seguro Anual',
          periodicity: 'anual',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 6, 30), // June
          lastGeneratedPeriod: '2025',
          transactionType: 'expense',
          category: 'suscripcion',
          paymentDay: 10,
      );

      final today = DateTime(2026, 6, 30);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 1);
      expect(txs.first.date, DateTime(2026, 6, 10),
          reason: 'Annual: paymentDay=10, month=June → June 10');
    });

    test('annual: paymentDay=30, endDate.month=2 → Feb 28 (non-leap)', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTemplate(db,
          name: 'Seguro Feb',
          periodicity: 'anual',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 28), // February
          lastGeneratedPeriod: '2025',
          transactionType: 'expense',
          category: 'suscripcion',
          paymentDay: 30,
      );

      final today = DateTime(2026, 2, 28);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 1);
      expect(txs.first.date, DateTime(2026, 2, 28),
          reason: 'Annual Feb (non-leap): day 30 clamps to 28');
    });

    test('annual: paymentDay=29, endDate.month=2, leap year 2028 → Feb 29', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      // endDate month = February; year is irrelevant for month extraction
      await insertTemplate(db,
          name: 'Seguro Leap',
          periodicity: 'anual',
          startDate: DateTime(2028, 1, 1),
          endDate: DateTime(2028, 2, 29), // February in a leap year
          lastGeneratedPeriod: '2027',
          transactionType: 'expense',
          category: 'suscripcion',
          paymentDay: 29,
      );

      final today = DateTime(2028, 2, 29);
      await RecurringGenerationService.run(db, today: today);
      final txs = await getTransactions(db);

      expect(txs.length, 1);
      expect(txs.first.date, DateTime(2028, 2, 29),
          reason: 'Annual Feb (leap year 2028): day 29 exists → Feb 29');
    });
  });
}
