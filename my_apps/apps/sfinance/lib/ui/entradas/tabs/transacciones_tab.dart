import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../../providers/transaction_providers.dart';
import '../../analisis/time_range_selector.dart';
import '../category_filter_selector.dart';

/// Entradas list: date range filter + category filter + transactions ListView.
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimeRangeSelector(
                selected: selectedRange,
                onChanged: (r) =>
                    ref.read(selectedTimeRangeProvider.notifier).state = r,
              ),
              const SizedBox(height: 8),
              CategoryFilterSelector(
                selected: selectedCategory,
                onChanged: (c) =>
                    ref.read(selectedCategoryFilterProvider.notifier).state = c,
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
                  return TransactionRow(
                    name: entry.name,
                    categoryLabel: entry.categoryLabel,
                    date: entry.date,
                    amountCents: entry.amountCents,
                    transactionType: entry.transactionType,
                    isRecurring: entry.isRecurring,
                    recurringDetail: entry.recurringDetail,
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
