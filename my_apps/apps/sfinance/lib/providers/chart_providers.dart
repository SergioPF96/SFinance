import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';

// ---------------------------------------------------------------------------
// Monthly Bar Chart (Resumen Mensual — US4)
// ---------------------------------------------------------------------------

class MonthData {
  const MonthData({
    required this.label,
    required this.ingresosCents,
    required this.gastosCents,
  });

  /// Abbreviated Spanish month name, e.g. "Ene", "Feb".
  final String label;
  final int ingresosCents;
  final int gastosCents;
}

class MonthlyChartData {
  const MonthlyChartData({required this.months});

  /// Last 6 months ordered chronologically (oldest first, current month last).
  final List<MonthData> months;
}

class _MonthlyChartNotifier
    extends AutoDisposeFamilyAsyncNotifier<MonthlyChartData, DateTime?> {
  static const _spanishMonths = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  Future<MonthlyChartData> build(DateTime? arg) async {
    final allTx = await ref.watch(allTransactionsStreamProvider.future);
    return _compute(allTx, arg ?? DateTime.now());
  }

  MonthlyChartData _compute(List<TransactionRow> txs, DateTime today) {
    final months = <MonthData>[];

    for (int i = 5; i >= 0; i--) {
      // Compute the calendar month i months back from today
      int month = today.month - i;
      int year = today.year;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }

      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 1);

      int income = 0;
      int expense = 0;
      for (final tx in txs) {
        if (!tx.date.isBefore(monthStart) && tx.date.isBefore(monthEnd)) {
          if (tx.transactionType == 'income') {
            income += tx.amountCents;
          } else {
            expense += tx.amountCents;
          }
        }
      }

      months.add(MonthData(
        label: _spanishMonths[month],
        ingresosCents: income,
        gastosCents: expense,
      ));
    }

    return MonthlyChartData(months: months);
  }
}

/// Family arg is [DateTime?] so tests can inject a fixed "today".
/// In production, pass null to use DateTime.now().
final monthlyChartProvider =
    AsyncNotifierProvider.autoDispose.family<_MonthlyChartNotifier,
        MonthlyChartData, DateTime?>(
  _MonthlyChartNotifier.new,
);

// ---------------------------------------------------------------------------
// Initial Capital Provider (US4)
// ---------------------------------------------------------------------------

class InitialCapitalState {
  const InitialCapitalState({
    required this.amountCents,
    required this.isActive,
  });

  final int amountCents;
  final bool isActive;

  static const empty = InitialCapitalState(amountCents: 0, isActive: false);
}

class _InitialCapitalNotifier extends AsyncNotifier<InitialCapitalState> {
  @override
  Future<InitialCapitalState> build() async {
    final row = await ref.watch(initialCapitalStreamProvider.future);
    if (row == null) return InitialCapitalState.empty;
    return InitialCapitalState(
      amountCents: row.amountCents,
      isActive: row.isActive,
    );
  }

  Future<void> setInitialCapital(int amountCents) async {
    final dao = ref.read(initialCapitalDaoProvider);
    await dao.upsert(amountCents);
  }
}

final initialCapitalProvider =
    AsyncNotifierProvider<_InitialCapitalNotifier, InitialCapitalState>(
        _InitialCapitalNotifier.new);

// ---------------------------------------------------------------------------
// Analysis Line Charts (Analisis view — US5)
// ---------------------------------------------------------------------------

enum ChartType { balance, gastos, ingresos }

class DataPoint {
  const DataPoint({required this.date, required this.valueCents});
  final DateTime date;
  final int valueCents;
}

/// Parameter for the analysisChartProvider family.
class AnalysisChartParam {
  const AnalysisChartParam({
    required this.chartType,
    required this.start,
    required this.end,
  });

  final ChartType chartType;
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is AnalysisChartParam &&
      other.chartType == chartType &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(chartType, start, end);
}

class _AnalysisChartNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<DataPoint>, AnalysisChartParam> {
  @override
  Future<List<DataPoint>> build(AnalysisChartParam arg) async {
    final allTx = await ref.watch(allTransactionsStreamProvider.future);
    return _compute(allTx, arg.chartType, arg.start, arg.end);
  }

  List<DataPoint> _compute(
    List<TransactionRow> allTx,
    ChartType chartType,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final sorted = [...allTx]..sort((a, b) => a.date.compareTo(b.date));

    if (chartType == ChartType.balance) {
      return _computeBalance(sorted, rangeStart, rangeEnd);
    }

    final isIncome = chartType == ChartType.ingresos;
    final byDay = <DateTime, int>{};

    for (final tx in sorted) {
      if (tx.date.isBefore(rangeStart) || !tx.date.isBefore(rangeEnd)) {
        continue;
      }
      if (isIncome && tx.transactionType != 'income') continue;
      if (!isIncome && tx.transactionType != 'expense') continue;

      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      byDay[day] = (byDay[day] ?? 0) + tx.amountCents;
    }

    return (byDay.entries
            .map((e) => DataPoint(date: e.key, valueCents: e.value))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)));
  }

  List<DataPoint> _computeBalance(
    List<TransactionRow> sorted,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    // Pre-compute balance before range start
    int running = 0;
    for (final tx in sorted) {
      if (tx.date.isBefore(rangeStart)) {
        running += tx.transactionType == 'income'
            ? tx.amountCents
            : -tx.amountCents;
      }
    }

    // Per-day deltas within range
    final byDay = <DateTime, int>{};
    for (final tx in sorted) {
      if (tx.date.isBefore(rangeStart) || !tx.date.isBefore(rangeEnd)) {
        continue;
      }
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final delta = tx.transactionType == 'income'
          ? tx.amountCents
          : -tx.amountCents;
      byDay[day] = (byDay[day] ?? 0) + delta;
    }

    final days = byDay.keys.toList()..sort();
    final points = <DataPoint>[];
    for (final day in days) {
      running += byDay[day]!;
      points.add(DataPoint(date: day, valueCents: running));
    }
    return points;
  }
}

final analysisChartProvider =
    AsyncNotifierProvider.autoDispose.family<_AnalysisChartNotifier,
        List<DataPoint>, AnalysisChartParam>(
  _AnalysisChartNotifier.new,
);
