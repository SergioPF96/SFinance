import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/dao_providers.dart';
import '../../providers/template_providers.dart';

/// Modal showing full details of a recurring template.
///
/// Actions available:
/// - Edit amount (inline, within this modal).
/// - Delete with confirmation dialog.
class TemplateDetailModal extends ConsumerWidget {
  const TemplateDetailModal({super.key, required this.template});

  final TemplateDisplay template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templateDetailProvider);
    final notifier = ref.read(templateDetailProvider.notifier);
    final dao = ref.read(templateDaoProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.onBackgroundMuted),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Info fields ──────────────────────────────────────────────
              _InfoRow(label: 'Tipo', value: template.categoryLabel),
              _InfoRow(label: 'Periodicidad', value: template.periodicity),
              _InfoRow(
                label: 'Fecha inicio',
                // endDate is used here just for type illustration;
                // startDate would need a separate field — approximated from
                // the template row. We show it via the display model.
                // Since TemplateDisplay doesn't carry startDate, we derive
                // it from context. For now show a placeholder.
                // TODO(009): expose startDate in TemplateDisplay if needed.
                value: template.paymentDay != null
                    ? 'Día ${template.paymentDay} de cada mes'
                    : 'Día 1 de cada mes',
              ),
              _InfoRow(
                label: 'Fecha fin',
                value: template.endDate != null
                    ? DateFormatter.format(template.endDate!)
                    : 'Sin fecha límite',
              ),
              _InfoRow(
                label: 'Próximo pago',
                value: DateFormatter.format(template.nextPaymentDate),
              ),
              const SizedBox(height: 8),

              // ── Amount section ───────────────────────────────────────────
              const Divider(color: AppColors.onBackgroundMuted),
              const SizedBox(height: 8),
              if (!state.isEditingAmount) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monto actual',
                          style: TextStyle(
                            color: AppColors.onBackgroundMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            template.amountCents,
                            isIncome: template.transactionType ==
                                TransactionType.income,
                          ),
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () =>
                          notifier.startEditing(template.amountCents),
                      child: const Text('Editar monto'),
                    ),
                  ],
                ),
              ] else ...[
                // Inline amount editor
                const Text(
                  'Nuevo monto (€)',
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: state.amountText,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.onBackground),
                  decoration: InputDecoration(
                    prefixText: '€ ',
                    prefixStyle:
                        const TextStyle(color: AppColors.onBackgroundMuted),
                    enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.onBackgroundMuted),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.balance),
                    ),
                    errorText: state.amountError,
                    errorStyle:
                        const TextStyle(color: AppColors.danger),
                  ),
                  onChanged: notifier.setAmountText,
                ),
                const SizedBox(height: 8),
                const Text(
                  'El nuevo monto aplica solo a pagos futuros. Las entradas ya generadas no se modifican.',
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: notifier.cancelEdit,
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.onBackgroundMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => notifier.confirmEdit(template.id, dao),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.balance,
                        foregroundColor: Colors.white,
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirmar'),
                    ),
                  ],
                ),
              ],

              // ── Delete section ───────────────────────────────────────────
              const SizedBox(height: 16),
              const Divider(color: AppColors.onBackgroundMuted),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _confirmDelete(context, ref, dao),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  child: const Text('Eliminar template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TemplateDao dao,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar este template?',
      message:
          'No se generarán más entradas para "${template.name}". '
          'Las entradas ya registradas se conservan en tu historial.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
    );
    if (confirmed && context.mounted) {
      await ref
          .read(templateDetailProvider.notifier)
          .deleteTemplate(template.id, dao);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Info row helper
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onBackgroundMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
