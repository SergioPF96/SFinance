import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/template_providers.dart';
import '../../providers/dao_providers.dart';

/// Recurrentes tab in the Entradas view.
///
/// Lists all active recurring templates with delete (soft-delete) affordance.
/// Past generated transactions are preserved when a template is deleted.
class RecurrentesTab extends ConsumerWidget {
  const RecurrentesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(activeTemplatesProvider);

    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.expense)),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Sin entradas recurrentes activas.',
                style: TextStyle(color: AppColors.onBackgroundMuted),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: templates.length,
          separatorBuilder: (_, __) =>
              const Divider(color: AppColors.surfaceVariant, height: 1),
          itemBuilder: (_, i) {
            final t = templates[i];
            final isIncome = t.transactionType == TransactionType.income;
            final color = isIncome ? AppColors.income : AppColors.expense;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  Icons.repeat,
                  color: color,
                  semanticLabel: isIncome ? 'Ingreso recurrente' : 'Gasto recurrente',
                ),
              ),
              title: Text(t.name,
                  style: const TextStyle(color: AppColors.onBackground)),
              subtitle: Text(
                '${t.categoryLabel} · ${t.periodicity}',
                style: const TextStyle(
                    color: AppColors.onBackgroundMuted, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hasta ${t.endDate.year}-${t.endDate.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.onBackgroundMuted, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.danger,
                    tooltip: 'Eliminar plantilla',
                    onPressed: () =>
                        _confirmDelete(context, ref, t.id, t.name),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Eliminar plantilla recurrente',
      message:
          '¿Eliminar "$name"? Las entradas ya generadas se conservan. '
          'No se generarán nuevas entradas.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
    );
    if (confirmed) {
      await ref.read(templateDaoProvider).softDelete(id);
    }
  }
}
