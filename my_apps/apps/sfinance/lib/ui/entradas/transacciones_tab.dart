import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/dao_providers.dart';
import '../analisis/time_range_selector.dart';

/// Transacciones tab in the Entradas view.
///
/// Shows all transactions for the selected [TimeRange] with delete affordance.
/// Delete requires confirmation and is permanent.
class TransaccionesTab extends ConsumerStatefulWidget {
  const TransaccionesTab({super.key});

  @override
  ConsumerState<TransaccionesTab> createState() => _TransaccionesTabState();
}

class _TransaccionesTabState extends ConsumerState<TransaccionesTab> {
  var _selectedRange = TimeRange.ultimos7Dias;

  @override
  Widget build(BuildContext context) {
    final dateRange = _selectedRange.toDateRange();
    final txAsync = ref.watch(
      filteredTransactionsProvider(
        DateTimeRange(start: dateRange.start, end: dateRange.end),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TimeRangeSelector(
            selected: _selectedRange,
            onChanged: (r) => setState(() => _selectedRange = r),
          ),
        ),
        const Divider(color: AppColors.surfaceVariant, height: 1),
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.expense)),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Sin transacciones para este período.',
                      style: TextStyle(color: AppColors.onBackgroundMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                itemBuilder: (_, i) {
                  final tx = transactions[i];
                  return TransactionRow(
                    name: tx.name,
                    categoryLabel: tx.categoryLabel,
                    date: tx.date,
                    amountCents: tx.amountCents,
                    transactionType: tx.transactionType,
                    onDelete: () => _confirmDelete(context, tx.id, tx.name),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, int id, String name) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Eliminar transaccion',
      message: '¿Eliminar "$name"? Esta accion no se puede deshacer.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
    );
    if (confirmed && mounted) {
      await ref.read(transactionDaoProvider).deleteById(id);
    }
  }
}
