import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../domain/chart_axis.dart';
import '../../providers/chart_providers.dart';

/// Line chart widget for Analisis view.
///
/// Accepts pre-computed [DataPoint] list and a [color].
/// Handles empty state gracefully.
class AnalysisLineChart extends StatelessWidget {
  const AnalysisLineChart({
    super.key,
    required this.dataPoints,
    required this.color,
    required this.label,
  });

  final List<DataPoint> dataPoints;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Sin datos para el período seleccionado',
            style: TextStyle(
                color: AppColors.onBackgroundMuted, fontSize: 13),
          ),
        ),
      );
    }

    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.valueCents.toDouble()))
        .toList();

    final minY = dataPoints
        .map((p) => p.valueCents.toDouble())
        .reduce((a, b) => a < b ? a : b);
    final maxY = dataPoints
        .map((p) => p.valueCents.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final padding = ((maxY - minY) * 0.1).clamp(500.0, double.infinity);

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.surfaceVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: niceInterval((maxY - minY).abs()),
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatAxisLabel(value),
                    style: const TextStyle(
                      color: AppColors.onBackgroundMuted,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: math
                    .max(1, (dataPoints.length / 5).ceil())
                    .toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= dataPoints.length) {
                    return const SizedBox.shrink();
                  }
                  final label = DateFormat('d MMM', 'es')
                      .format(dataPoints[idx].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.onBackgroundMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '€${(s.y / 100).toStringAsFixed(2)}',
                        TextStyle(color: color, fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
