import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/kpi_provider.dart';

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

Future<void> insertIncome(
  AppDatabase db, {
  required int amountCents,
  required String category,
  required DateTime date,
}) async {
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          name: 'Test income',
          amountCents: amountCents,
          transactionType: 'income',
          category: category,
          date: date,
        ),
      );
}

Future<void> insertExpense(
  AppDatabase db, {
  required int amountCents,
  required String category,
  required DateTime date,
}) async {
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          name: 'Test expense',
          amountCents: amountCents,
          transactionType: 'expense',
          category: category,
          date: date,
        ),
      );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);

  group('kpiProvider', () {
    test('initial state: all zeros, hasTransactions=false', () async {
      final container = makeContainer();
      final kpi = await container.read(kpiProvider.future);

      expect(kpi.ingresosCents, 0);
      expect(kpi.gastosCents, 0);
      expect(kpi.balanceCents, 0);
      expect(kpi.hasTransactions, false);
      expect(kpi.initialCapitalActive, false);
    });

    test('monthly Ingresos includes only current-month income', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertIncome(db,
          amountCents: 200000, category: 'salario', date: thisMonthStart);
      await insertIncome(db,
          amountCents: 50000, category: 'salario', date: lastMonthStart);

      final kpi = await container.read(kpiProvider.future);
      expect(kpi.ingresosCents, 200000);
    });

    test('monthly Gastos includes only current-month expenses', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertExpense(db,
          amountCents: 2550, category: 'servicio', date: thisMonthStart);
      await insertExpense(db,
          amountCents: 10000, category: 'producto', date: lastMonthStart);

      final kpi = await container.read(kpiProvider.future);
      expect(kpi.gastosCents, 2550);
    });

    test('Balance = all-time income minus all-time expenses', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertIncome(db,
          amountCents: 100000, category: 'salario', date: lastMonthStart);
      await insertExpense(db,
          amountCents: 30000, category: 'producto', date: thisMonthStart);

      final kpi = await container.read(kpiProvider.future);
      expect(kpi.balanceCents, 70000);
    });

    test('Balance includes active initial capital', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await db.into(db.initialCapitalTable).insert(
            InitialCapitalTableCompanion.insert(
              id: const Value(1),
              amountCents: 50000,
              isActive: const Value(true),
            ),
          );
      await insertIncome(db,
          amountCents: 10000, category: 'salario', date: thisMonthStart);

      final kpi = await container.read(kpiProvider.future);
      expect(kpi.balanceCents, 60000);
      expect(kpi.initialCapitalActive, true);
    });

    test('Balance excludes inactive initial capital', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await db.into(db.initialCapitalTable).insert(
            InitialCapitalTableCompanion.insert(
              id: const Value(1),
              amountCents: 50000,
              isActive: const Value(false),
            ),
          );
      await insertIncome(db,
          amountCents: 10000, category: 'salario', date: thisMonthStart);

      final kpi = await container.read(kpiProvider.future);
      expect(kpi.balanceCents, 10000);
      expect(kpi.initialCapitalActive, false);
    });

    test('hasTransactions is true after first transaction', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertExpense(db,
          amountCents: 100, category: 'producto', date: thisMonthStart);

      final kpi = await container.read(kpiProvider.future);
      expect(kpi.hasTransactions, true);
    });
  });
}
