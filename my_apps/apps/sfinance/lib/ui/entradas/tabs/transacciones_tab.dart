import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../../domain/category_filter.dart';
import '../../../domain/time_range.dart';
import '../../../providers/transaction_providers.dart';
import '../transaction_detail_modal.dart';

/// Entradas list: two dropdown filters side by side + header row + tappable transactions.
class TransaccionesTab extends ConsumerWidget {
  const TransaccionesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(selectedTimeRangeProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final entriesAsync = ref.watch(filteredEntriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              _FilterDropdown<TimeRange>(
                value: selectedRange,
                items: TimeRange.values,
                labelOf: (r) => r.label,
                onChanged: (r) =>
                    ref.read(selectedTimeRangeProvider.notifier).state = r,
              ),
              const SizedBox(width: 16),
              _FilterDropdown<CategoryFilter>(
                value: selectedCategory,
                items: CategoryFilter.values,
                labelOf: (c) => c.label,
                onChanged: (c) =>
                    ref.read(selectedCategoryFilterProvider.notifier).state = c,
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.surfaceVariant, height: 1),
        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: const [
              SizedBox(width: 56),
              Expanded(
                child: Text(
                  'Nombre · Categoría',
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Importe',
                style: TextStyle(
                  color: AppColors.onBackgroundMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.surfaceVariant, height: 1),
        Expanded(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(
              child: Text(
                'Error al cargar entradas',
                style: TextStyle(color: AppColors.expense),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Sin entradas para este período.',
                      style: TextStyle(color: AppColors.onBackgroundMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                itemBuilder: (_, i) {
                  final entry = entries[i];
                  return InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          TransactionDetailModal(entry: entry),
                    ),
                    child: TransactionRow(
                      name: entry.name,
                      categoryLabel: entry.categoryLabel,
                      date: entry.date,
                      amountCents: entry.amountCents,
                      transactionType: entry.transactionType,
                      isRecurring: entry.isRecurring,
                      recurringDetail: entry.recurringDetail,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.onBackground, fontSize: 13),
      underline: Container(height: 1, color: AppColors.balance),
      isDense: true,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelOf(item)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
