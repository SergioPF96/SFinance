import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../domain/chart_axis.dart';
import '../../providers/chart_providers.dart';

/// Line chart widget for Analisis view.
///
/// Changes from previous version:
///   - Height increased from 140 → 200.
///   - Y-axis: reservedSize 52 → 68, font 10 → 12, always 4 ticks via
///     [_niceInterval], generous padding when data is nearly flat.
///   - Area gradient fill under the line.
///   - Larger dots (4 px) with surface-colored stroke.
///   - Crosshair + cleaner tooltip.
///   - [_EndLabel] overlay: always-visible pill on the last data point.
///   - [_SparseNotice]: shown when ≤ 2 non-zero data points exist.
class AnalysisLineChart extends StatefulWidget {
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
  State<AnalysisLineChart> createState() => _AnalysisLineChartState();
}

class _AnalysisLineChartState extends State<AnalysisLineChart> {
  // Index of the currently touched spot; -1 means none.
  int _touchedIndex = -1;

  static const double _chartHeight = 200;

  @override
  Widget build(BuildContext context) {
    final dataPoints = widget.dataPoints;
    final color = widget.color;

    // ── Empty state ────────────────────────────────────────────────────────
    if (dataPoints.isEmpty) {
      return const SizedBox(
        height: _chartHeight,
        child: Center(
          child: Text(
            'Sin datos para el período seleccionado',
            style: TextStyle(color: AppColors.onBackgroundMuted, fontSize: 13),
          ),
        ),
      );
    }

    // ── Spots ──────────────────────────────────────────────────────────────
    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.valueCents.toDouble()))
        .toList();

    final values = dataPoints.map((p) => p.valueCents.toDouble()).toList();
    final minY = values.reduce(math.min);
    final maxY = values.reduce(math.max);
    final span = maxY - minY;

    // Pad generously when data is nearly flat (< 2 % of max value) so the
    // line doesn't hug an edge and remains clearly visible.
    final padding = span < maxY * 0.02
        ? (maxY * 0.05).clamp(500.0, double.infinity)
        : (span * 0.15).clamp(500.0, double.infinity);

    final effectiveMin = minY - padding;
    final effectiveMax = maxY + padding;

    // ── Sparse data notice ─────────────────────────────────────────────────
    final nonZeroCount = values.where((v) => v > 0).length;
    final isSparse = nonZeroCount <= 2;

    // ── Gradient fill ──────────────────────────────────────────────────────
    final gradientColors = [
      color.withOpacity(0.20),
      color.withOpacity(0.00),
    ];

    // ── Y-axis interval: aim for exactly 4 ticks ───────────────────────────
    final yInterval = _niceInterval(effectiveMax - effectiveMin, targetTicks: 4);

    // ── x-axis interval: show at most 6 labels ─────────────────────────────
    final xInterval = math.max(1, (dataPoints.length / 6).ceil()).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSparse) const _SparseNotice(),
        if (isSparse) const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
          height: _chartHeight,
          child: Stack(
            children: [
              LineChart(
                LineChartData(
                  minY: effectiveMin,
                  maxY: effectiveMax,

                  // ── Line + area fill ─────────────────────────────────────
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: _touchedIndex == index ? 6 : 4,
                          color: _touchedIndex == index
                              ? Colors.white
                              : color,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],

                  // ── Grid ─────────────────────────────────────────────────
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.surfaceVariant,
                      strokeWidth: 1,
                    ),
                  ),

                  borderData: FlBorderData(show: false),

                  // ── Axes ──────────────────────────────────────────────────
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 68,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          // Skip labels outside the effective range to avoid
                          // duplicates at the boundary.
                          if (value < effectiveMin || value > effectiveMax) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              formatAxisLabel(value),
                              style: const TextStyle(
                                color: AppColors.onBackgroundMuted,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: xInterval,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dataPoints.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              DateFormat('d MMM', 'es')
                                  .format(dataPoints[idx].date),
                              style: const TextStyle(
                                color: AppColors.onBackgroundMuted,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Touch / tooltip ───────────────────────────────────────
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.lineBarSpots?.isNotEmpty == true &&
                            !event.isInterestedForInteractions == false) {
                          _touchedIndex =
                              response!.lineBarSpots!.first.spotIndex;
                        } else {
                          _touchedIndex = -1;
                        }
                      });
                    },
                    getTouchedSpotIndicator: (barData, spotIndexes) =>
                        spotIndexes.map((i) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: AppColors.surfaceVariant,
                          strokeWidth: 1,
                          dashArray: [4, 3],
                        ),
                        FlDotData(
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: color,
                          ),
                        ),
                      );
                    }).toList(),
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surface,
                      tooltipBorder: const BorderSide(
                          color: AppColors.surfaceVariant),
                      tooltipRoundedRadius: 6,
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((s) {
                        return LineTooltipItem(
                          formatAxisLabel(s.y),
                          TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ── End label overlay ─────────────────────────────────────────
              // Only shown when the last point is not currently touched.
              // NOTE: _EndLabel must be a direct Stack child (no RenderObject
              // widget in between) so that its Positioned return value can
              // apply StackParentData correctly.
              if (_touchedIndex != dataPoints.length - 1)
                _EndLabel(
                  containerWidth: constraints.maxWidth,
                  dataPoints: dataPoints,
                  effectiveMin: effectiveMin,
                  effectiveMax: effectiveMax,
                  color: color,
                  chartHeight: _chartHeight,
                  // fl_chart reserves 68px on the left for the Y axis.
                  leftReservedSize: 68,
                  // fl_chart reserves 24px on the bottom for the X axis.
                  bottomReservedSize: 24,
                ),
            ],
          ),
        ),
        ),
      ],
    );
  }
}

// ── End Label ────────────────────────────────────────────────────────────────
//
// Positions a pill containing the last data point's formatted value directly
// on the chart. Floats above the dot when the value is in the lower half of
// the range, and below when it is in the upper half, to avoid covering the
// line.
class _EndLabel extends StatelessWidget {
  const _EndLabel({
    required this.containerWidth,
    required this.dataPoints,
    required this.effectiveMin,
    required this.effectiveMax,
    required this.color,
    required this.chartHeight,
    required this.leftReservedSize,
    required this.bottomReservedSize,
  });

  /// Width of the containing Stack, passed in so this widget can return a
  /// Positioned directly (no LayoutBuilder wrapper) — required for Positioned
  /// to correctly apply StackParentData to RenderStack.
  final double containerWidth;
  final List<DataPoint> dataPoints;
  final double effectiveMin;
  final double effectiveMax;
  final Color color;
  final double chartHeight;
  final double leftReservedSize;
  final double bottomReservedSize;

  @override
  Widget build(BuildContext context) {
    final plotW = containerWidth - leftReservedSize;
    final plotH = chartHeight - bottomReservedSize;

    final last = dataPoints.last;
    final range = (effectiveMax - effectiveMin).abs();

    // X: last point is always at the far right of the plot area.
    final dotX = leftReservedSize + plotW;

    // Y: map value into plot area (fl_chart origin is top-left).
    final normalised =
        ((last.valueCents.toDouble() - effectiveMin) / range).clamp(0.0, 1.0);
    final dotY = plotH * (1.0 - normalised);

    final labelText = formatAxisLabel(last.valueCents.toDouble());

    // Determine whether to float above or below the dot.
    final above = dotY > plotH / 2;
    const pillH = 24.0;
    const pillPadH = 10.0; // gap between dot and pill

    final top = above
        ? (dotY - pillH - pillPadH).clamp(0.0, plotH - pillH)
        : (dotY + pillPadH).clamp(0.0, plotH - pillH);

    // Keep pill within horizontal bounds (allow it to drift left of dot).
    const pillW = 80.0;
    final left =
        (dotX - pillW / 2).clamp(leftReservedSize, containerWidth - pillW);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: pillW,
        height: pillH,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          labelText,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Sparse data notice ────────────────────────────────────────────────────────
class _SparseNotice extends StatelessWidget {
  const _SparseNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.info_outline, size: 13, color: AppColors.onBackgroundMuted),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'Pocos datos en el período — el gráfico mejorará con más transacciones',
            style: TextStyle(
              color: AppColors.onBackgroundMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns a "nice" interval that produces approximately [targetTicks] ticks
/// over [span]. Uses 1/2/5 multiples of powers of 10.
double _niceInterval(double span, {int targetTicks = 4}) {
  if (span <= 0) return 1;
  final rawStep = span / (targetTicks - 1);
  final magnitude = math.pow(10, rawStep.abs().toStringAsFixed(0).length - 1);
  final candidates = [1.0, 2.0, 5.0, 10.0].map((m) => m * magnitude);
  return candidates.firstWhere((c) => c >= rawStep, orElse: () => rawStep);
}
