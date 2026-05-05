import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/transaction_providers.dart';

/// Read-only modal showing all details of a single transaction entry.
class TransactionDetailModal extends StatelessWidget {
  const TransactionDetailModal({super.key, required this.entry});

  final TransactionDisplay entry;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.transactionType == TransactionType.income;
    final amountStr = CurrencyFormatter.format(
      entry.amountCents,
      isIncome: isIncome,
    );

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
              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
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

              // ── Info fields ───────────────────────────────────────────────
              _InfoRow(
                label: 'Tipo',
                value: isIncome ? 'Ingreso' : 'Gasto',
              ),
              _InfoRow(label: 'Categoría', value: entry.categoryLabel),
              _InfoRow(
                label: 'Fecha',
                value: DateFormatter.format(entry.date),
              ),
              if (entry.recurringDetail != null)
                _InfoRow(label: 'Recurrencia', value: entry.recurringDetail!),
              if (entry.description != null &&
                  entry.description!.trim().isNotEmpty)
                _InfoRow(label: 'Descripción', value: entry.description!),

              const SizedBox(height: 8),
              const Divider(color: AppColors.onBackgroundMuted),
              const SizedBox(height: 8),

              // ── Amount ────────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Importe',
                    style: TextStyle(
                      color: AppColors.onBackgroundMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    amountStr,
                    style: TextStyle(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
