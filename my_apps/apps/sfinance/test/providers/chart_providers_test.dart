import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/chart_providers.dart';

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

Future<void> insertTx(
  AppDatabase db, {
  required String type,
  required int amountCents,
  required DateTime date,
  String category = 'servicio',
}) async {
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          name: 'Test',
          amountCents: amountCents,
          transactionType: type,
          category: category,
          date: date,
        ),
      );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Fixed "today" for deterministic month windows
  final today = DateTime(2026, 4, 7);

  group('monthlyChartProvider', () {
    test('returns exactly 6 months', () async {
      final container = makeContainer();
      final data =
          await container.read(monthlyChartProvider(today).future);
      expect(data.months.length, 6);
    });

    test('months with no transactions are all zeros', () async {
      final container = makeContainer();
      final data =
          await container.read(monthlyChartProvider(today).future);
      for (final m in data.months) {
        expect(m.ingresosCents, 0);
        expect(m.gastosCents, 0);
      }
    });

    test('aggregates income and expenses per calendar month', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, type: 'income', amountCents: 200000,
          date: DateTime(2026, 4, 1));
      await insertTx(db, type: 'expense', amountCents: 5000,
          date: DateTime(2026, 4, 5));
      await insertTx(db, type: 'income', amountCents: 150000,
          date: DateTime(2026, 3, 15));

      final data =
          await container.read(monthlyChartProvider(today).future);

      final april = data.months.last; // current month is last
      expect(april.ingresosCents, 200000);
      expect(april.gastosCents, 5000);

      final march = data.months[data.months.length - 2];
      expect(march.ingresosCents, 150000);
      expect(march.gastosCents, 0);
    });

    test('current month is the last entry', () async {
      final container = makeContainer();
      final data =
          await container.read(monthlyChartProvider(today).future);
      expect(data.months.last.label, 'Abr'); // April
    });

    test('months are ordered chronologically, oldest first', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      await insertTx(db, type: 'income', amountCents: 100,
          date: DateTime(2026, 4, 1));
      await insertTx(db, type: 'income', amountCents: 200,
          date: DateTime(2026, 2, 1));

      final data =
          await container.read(monthlyChartProvider(today).future);

      // Months: Nov, Dec, Jan, Feb, Mar, Apr
      final feb = data.months[data.months.length - 3];
      expect(feb.ingresosCents, 200);
      final april = data.months.last;
      expect(april.ingresosCents, 100);
    });
  });

  group('analysisChartProvider', () {
    test('balance chart computes cumulative running total', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final start = DateTime(2026, 4, 1);
      await insertTx(db, type: 'income', amountCents: 10000, date: start);
      await insertTx(db, type: 'expense', amountCents: 3000,
          date: start.add(const Duration(days: 1)));
      await insertTx(db, type: 'income', amountCents: 5000,
          date: start.add(const Duration(days: 2)));

      final param = AnalysisChartParam(
        chartType: ChartType.balance,
        start: start,
        end: start.add(const Duration(days: 7)),
      );
      final data = await container.read(analysisChartProvider(param).future);

      // Day 0: +10000 → balance 10000
      // Day 1: -3000  → balance 7000
      // Day 2: +5000  → balance 12000
      expect(data.length, 3);
      expect(data[0].valueCents, 10000);
      expect(data[1].valueCents, 7000);
      expect(data[2].valueCents, 12000);
    });

    test('gastos chart aggregates expenses per day, excludes income', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final start = DateTime(2026, 4, 1);
      await insertTx(db, type: 'expense', amountCents: 1000, date: start);
      await insertTx(db, type: 'expense', amountCents: 2000, date: start);
      await insertTx(db, type: 'income', amountCents: 9999, date: start);

      final param = AnalysisChartParam(
        chartType: ChartType.gastos,
        start: start,
        end: start.add(const Duration(days: 2)),
      );
      final data = await container.read(analysisChartProvider(param).future);

      expect(data.length, 1);
      expect(data.first.valueCents, 3000);
    });

    test('ingresos chart aggregates income per day, excludes expenses', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final start = DateTime(2026, 4, 1);
      await insertTx(db, type: 'income', amountCents: 5000, date: start);
      await insertTx(db, type: 'expense', amountCents: 9999, date: start);

      final param = AnalysisChartParam(
        chartType: ChartType.ingresos,
        start: start,
        end: start.add(const Duration(days: 2)),
      );
      final data = await container.read(analysisChartProvider(param).future);

      expect(data.length, 1);
      expect(data.first.valueCents, 5000);
    });

    test('independent state per chart type', () async {
      final container = makeContainer();
      final db = container.read(databaseProvider);

      final start = DateTime(2026, 4, 1);
      await insertTx(db, type: 'income', amountCents: 10000, date: start);
      await insertTx(db, type: 'expense', amountCents: 3000, date: start);

      final end = start.add(const Duration(days: 2));

      final [balanceData, gastosData, ingresosData] = await Future.wait([
        container.read(analysisChartProvider(
            AnalysisChartParam(chartType: ChartType.balance,
                start: start, end: end)).future),
        container.read(analysisChartProvider(
            AnalysisChartParam(chartType: ChartType.gastos,
                start: start, end: end)).future),
        container.read(analysisChartProvider(
            AnalysisChartParam(chartType: ChartType.ingresos,
                start: start, end: end)).future),
      ]);

      expect(balanceData.last.valueCents, 7000);
      expect(gastosData.first.valueCents, 3000);
      expect(ingresosData.first.valueCents, 10000);
    });
  });
}
