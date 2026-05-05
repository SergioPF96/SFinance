import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../../providers/quick_expenses_provider.dart';
import '../quick_expense_edit_dialog.dart';

/// Tab listing saved quick expense shortcuts with edit and delete affordances.
class FrecuentesTab extends ConsumerWidget {
  const FrecuentesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickExpensesAsync = ref.watch(quickExpensesStreamProvider);

    return quickExpensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text(
          'Error al cargar gastos comunes.',
          style: TextStyle(color: AppColors.expense),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No hay gastos comunes guardados',
                style: TextStyle(color: AppColors.onBackgroundMuted),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) =>
              const Divider(color: AppColors.surfaceVariant, height: 1),
          itemBuilder: (context, i) => _FrecuenteRow(row: rows[i]),
        );
      },
    );
  }
}

class _FrecuenteRow extends ConsumerWidget {
  const _FrecuenteRow({required this.row});

  final QuickExpenseRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountStr = CurrencyFormatter.formatUnsigned(row.amountCents);

    return ListTile(
      leading: _Thumbnail(imagePath: row.imagePath),
      title: Text(
        row.name,
        style: const TextStyle(color: AppColors.onBackground),
      ),
      subtitle: Text(
        '$amountStr · ${row.category}',
        style:
            const TextStyle(color: AppColors.onBackgroundMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.onBackgroundMuted),
            tooltip: 'Editar',
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => QuickExpenseEditDialog(id: row.id),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.onBackgroundMuted),
            tooltip: 'Eliminar',
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: 'Eliminar gasto común',
                message:
                    '¿Eliminar "${row.name}"? Esta acción no se puede deshacer.',
                confirmLabel: 'Eliminar',
                cancelLabel: 'Cancelar',
              );
              if (confirmed && context.mounted) {
                await ref
                    .read(quickExpenseEditFormProvider(row.id).notifier)
                    .deleteThis(row.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(imagePath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.bolt_outlined,
        size: 24,
        color: AppColors.onBackgroundMuted,
      ),
    );
  }
}
