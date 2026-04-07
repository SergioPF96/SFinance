import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
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
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Sin datos para el período seleccionado',
            style: const TextStyle(
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
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.surfaceVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
