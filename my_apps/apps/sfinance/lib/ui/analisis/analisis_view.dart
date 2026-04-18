import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/kpi_provider.dart';
import '../../providers/chart_providers.dart';
import 'time_range_selector.dart';
import 'analysis_line_chart.dart';

/// Analisis view — KPI strip + three independent line charts with time selectors.
///
/// Each chart (Balance, Gastos, Ingresos) maintains its own [TimeRange] state
/// independently. Defaults to [TimeRange.ultimos7Dias] on first load.
class AnalisisView extends ConsumerStatefulWidget {
  const AnalisisView({super.key});

  @override
  ConsumerState<AnalisisView> createState() => _AnalisisViewState();
}

class _AnalisisViewState extends ConsumerState<AnalisisView> {
  var _balanceRange = TimeRange.ultimos7Dias;
  var _gastosRange = TimeRange.ultimos7Dias;
  var _ingresosRange = TimeRange.ultimos7Dias;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KpiStrip(),
          const SizedBox(height: 32),
          _ChartSection(
            title: 'Balance',
            color: AppColors.balance,
            chartType: ChartType.balance,
            selectedRange: _balanceRange,
            onRangeChanged: (r) => setState(() => _balanceRange = r),
          ),
          const SizedBox(height: 32),
          _ChartSection(
            title: 'Gastos',
            color: AppColors.expense,
            chartType: ChartType.gastos,
            selectedRange: _gastosRange,
            onRangeChanged: (r) => setState(() => _gastosRange = r),
          ),
          const SizedBox(height: 32),
          _ChartSection(
            title: 'Ingresos',
            color: AppColors.income,
            chartType: ChartType.ingresos,
            selectedRange: _ingresosRange,
            onRangeChanged: (r) => setState(() => _ingresosRange = r),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(kpiProvider);
    return kpiAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: AppColors.expense)),
      data: (kpi) => Row(
        children: [
          Expanded(
            child: KpiCard(
              label: 'Ingresos',
              amountCents: kpi.ingresosCents,
              color: AppColors.income,
              isIncome: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              label: 'Gastos',
              amountCents: kpi.gastosCents,
              color: AppColors.expense,
              isIncome: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              label: 'Balance',
              amountCents: kpi.balanceCents.abs(),
              color: kpi.balanceCents >= 0
                  ? AppColors.balance
                  : AppColors.expense,
              isIncome: kpi.balanceCents >= 0,
              showSign: kpi.balanceCents != 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({
    required this.title,
    required this.color,
    required this.chartType,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final String title;
  final Color color;
  final ChartType chartType;
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = selectedRange.toDateRange();
    final param = AnalysisChartParam(
      chartType: chartType,
      start: dateRange.start,
      end: dateRange.end,
    );
    final dataAsync = ref.watch(analysisChartProvider(param));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TimeRangeSelector(
          selected: selectedRange,
          onChanged: onRangeChanged,
        ),
        const SizedBox(height: 12),
        dataAsync.when(
          loading: () => const SizedBox(
              height: 140, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Error: $e',
              style: const TextStyle(color: AppColors.expense)),
          data: (points) => AnalysisLineChart(
            dataPoints: points,
            color: color,
            label: title,
          ),
        ),
      ],
    );
  }
}
