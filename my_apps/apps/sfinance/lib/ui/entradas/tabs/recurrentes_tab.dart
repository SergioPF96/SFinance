import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../../domain/category_filter.dart';
import '../../../providers/template_providers.dart';
import '../../recurrentes/template_detail_modal.dart';

/// Recurring templates list with category filter and column headers.
class RecurrentesTab extends ConsumerWidget {
  const RecurrentesTab({super.key});

  // Only categories that can appear on recurring templates.
  static const _filterValues = [
    CategoryFilter.all,
    CategoryFilter.suscripcion,
    CategoryFilter.financiacion,
    CategoryFilter.salario,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedRecurrentesCategoryFilterProvider);
    final filteredAsync = ref.watch(filteredTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: DropdownButton<CategoryFilter>(
            value: selectedCategory,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.onBackground, fontSize: 13),
            underline: Container(height: 1, color: AppColors.balance),
            isDense: true,
            items: _filterValues
                .map(
                  (f) => DropdownMenuItem<CategoryFilter>(
                    value: f,
                    child: Text(f.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref
                    .read(selectedRecurrentesCategoryFilterProvider.notifier)
                    .state = v;
              }
            },
          ),
        ),
        const Divider(color: AppColors.surfaceVariant, height: 1),
        // Column headers
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Nombre · Categoría',
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Importe',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  'Próximo pago',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  'Fecha fin',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.surfaceVariant, height: 1),
        Expanded(
          child: filteredAsync.when(
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
                itemBuilder: (context, i) =>
                    _TemplateRow(template: templates[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

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
            Expanded(
              flex: 2,
              child: Text(
                nextPaymentStr,
                textAlign: TextAlign.end,
                style: const TextStyle(color: AppColors.onBackground),
              ),
            ),
            const SizedBox(width: 12),
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
