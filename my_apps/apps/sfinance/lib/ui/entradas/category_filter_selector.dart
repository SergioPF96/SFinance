import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../domain/category_filter.dart';

/// Segmented chip selector for the Entradas category filter.
///
/// Renders one [ChoiceChip] per [CategoryFilter] value.
/// Fully keyboard-accessible via Tab + Enter/Space.
class CategoryFilterSelector extends StatelessWidget {
  const CategoryFilterSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CategoryFilter selected;
  final ValueChanged<CategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: CategoryFilter.values.map((filter) {
        final isSelected = filter == selected;
        return ChoiceChip(
          label: Text(filter.label),
          selected: isSelected,
          onSelected: (_) => onChanged(filter),
          selectedColor: AppColors.balance.withValues(alpha: 0.2),
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
