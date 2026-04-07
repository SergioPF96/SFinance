import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Available time ranges for Analisis charts and Entradas filter.
enum TimeRange {
  ultimos7Dias,
  ultimoMes,
  ultimos3Meses,
  ultimoAnio,
  desdeOrigen;

  String get label {
    switch (this) {
      case TimeRange.ultimos7Dias:
        return 'Últimos 7 días';
      case TimeRange.ultimoMes:
        return 'Último mes';
      case TimeRange.ultimos3Meses:
        return 'Últimos 3 meses';
      case TimeRange.ultimoAnio:
        return 'Último año';
      case TimeRange.desdeOrigen:
        return 'Desde origen';
    }
  }

  /// Returns [start, end] datetime pair for this range.
  ({DateTime start, DateTime end}) toDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1));

    switch (this) {
      case TimeRange.ultimos7Dias:
        return (start: today.subtract(const Duration(days: 6)), end: end);
      case TimeRange.ultimoMes:
        return (
          start: DateTime(now.year, now.month - 1, now.day),
          end: end,
        );
      case TimeRange.ultimos3Meses:
        return (
          start: DateTime(now.year, now.month - 3, now.day),
          end: end,
        );
      case TimeRange.ultimoAnio:
        return (
          start: DateTime(now.year - 1, now.month, now.day),
          end: end,
        );
      case TimeRange.desdeOrigen:
        return (
          start: DateTime(2000, 1, 1),
          end: end,
        );
    }
  }
}

/// Segmented control allowing the user to select a [TimeRange].
///
/// Fully keyboard-accessible via Tab + Enter/Space.
class TimeRangeSelector extends StatelessWidget {
  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: TimeRange.values.map((range) {
        final isSelected = range == selected;
        return ChoiceChip(
          label: Text(range.label),
          selected: isSelected,
          onSelected: (_) => onChanged(range),
          selectedColor: AppColors.balance.withOpacity(0.2),
          backgroundColor: AppColors.surfaceVariant,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.balance : AppColors.onBackgroundMuted,
            fontSize: 12,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.balance : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }
}
