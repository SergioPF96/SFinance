import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../domain/time_range.dart';

export '../../domain/time_range.dart';

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
