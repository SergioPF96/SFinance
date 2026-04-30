import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/chart_providers.dart';

/// Grouped bar chart showing income (green) and expenses (red) for the last
/// 6 calendar months.
class MonthlyBarChart extends ConsumerWidget {
  const MonthlyBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(monthlyChartProvider(null));

    return dataAsync.when(
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: AppColors.expense)),
      data: (data) => _Chart(data: data),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.data});

  final MonthlyChartData data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.months.fold<double>(
          1000,
          (max, m) {
            final monthMax = [
              m.ingresosCents.toDouble(),
              m.gastosCents.toDouble()
            ].reduce((a, b) => a > b ? a : b);
            return monthMax > max ? monthMax : max;
          },
        ) *
        1.2; // 20% headroom

    final barGroups = data.months.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: m.ingresosCents.toDouble(),
            color: AppColors.income,
            width: 10,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: m.gastosCents.toDouble(),
            color: AppColors.expense,
            width: 10,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen Mensual',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.surfaceVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.months.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          data.months[i].label,
                          style: const TextStyle(
                              color: AppColors.onBackgroundMuted, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                    final cents = rod.toY.toInt();
                    final formatted = '€${(cents / 100).toStringAsFixed(2)}';
                    return BarTooltipItem(
                      '$label\n$formatted',
                      const TextStyle(
                          color: AppColors.onBackground, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
