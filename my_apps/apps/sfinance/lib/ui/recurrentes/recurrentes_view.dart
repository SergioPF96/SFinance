import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/template_providers.dart';
import 'template_detail_modal.dart';

/// Tab view listing all active recurring templates in compact rows.
///
/// Ordered by creation date ascending (oldest first).
/// Tapping a row opens [TemplateDetailModal].
class RecurrentesView extends ConsumerWidget {
  const RecurrentesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTemplates = ref.watch(activeTemplatesProvider);

    return asyncTemplates.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text(
          'Error cargando los templates recurrentes.',
          style: TextStyle(color: AppColors.onBackgroundMuted),
        ),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return const _EmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          separatorBuilder: (_, __) => const Divider(
            color: AppColors.onBackgroundMuted,
            height: 1,
          ),
          itemBuilder: (context, i) => _TemplateRow(template: templates[i]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Row widget
// ---------------------------------------------------------------------------

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template});

  final TemplateDisplay template;

  @override
  Widget build(BuildContext context) {
    final amountStr = CurrencyFormatter.format(
      template.amountCents,
      isIncome: template.transactionType == TransactionType.income,
    );
    final nextPaymentStr = DateFormatter.format(template.nextPaymentDate);
    final endDateStr = template.endDate != null
        ? DateFormatter.format(template.endDate!)
        : 'Sin fecha límite';

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TemplateDetailModal(template: template),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // Name + category
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.categoryLabel,
                    style: const TextStyle(
                      color: AppColors.onBackgroundMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Expanded(
              flex: 2,
              child: Text(
                amountStr,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: template.transactionType == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Next payment date
            Expanded(
              flex: 2,
              child: Text(
                nextPaymentStr,
                textAlign: TextAlign.end,
                style: const TextStyle(color: AppColors.onBackground),
              ),
            ),
            const SizedBox(width: 12),
            // End date
            Expanded(
              flex: 2,
              child: Text(
                endDateStr,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.onBackgroundMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: 48, color: AppColors.onBackgroundMuted),
          SizedBox(height: 16),
          Text(
            'Sin compromisos recurrentes',
            style: TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los templates de suscripción, financiación y salario\naparecerán aquí una vez creados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onBackgroundMuted),
          ),
        ],
      ),
    );
  }
}
