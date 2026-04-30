import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_services/shared_services.dart';
import 'package:shared_ui/shared_ui.dart';

/// Horizontal strip of 64×64 tappable cards — one per quick expense.
/// Returns an empty widget when [items] is empty.
class QuickExpenseCardRow extends StatelessWidget {
  const QuickExpenseCardRow({
    super.key,
    required this.items,
    required this.onSelected,
  });

  final List<QuickExpenseRow> items;
  final void Function(QuickExpenseRow) onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final row = items[index];
          return _QuickExpenseCard(row: row, onTap: () => onSelected(row));
        },
      ),
    );
  }
}

class _QuickExpenseCard extends StatelessWidget {
  const _QuickExpenseCard({required this.row, required this.onTap});

  final QuickExpenseRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: row.name,
      preferBelow: false,
      triggerMode: TooltipTriggerMode.longPress,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 64,
          height: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: row.imagePath != null
                ? Image.file(File(row.imagePath!), fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceVariant,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bolt_outlined,
                      size: 32,
                      color: AppColors.onBackgroundMuted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
