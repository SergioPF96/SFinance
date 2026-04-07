import 'package:flutter/material.dart';
import '../formatters/currency_formatter.dart';
import '../formatters/date_formatter.dart';
import '../theme/app_theme.dart';
import 'package:shared_models/shared_models.dart';

/// Presentational row widget for a single transaction.
///
/// Displays: colored circular icon, name, "category · date" subtitle,
/// and a signed amount (income=green +, expense=red −).
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.name,
    required this.categoryLabel,
    required this.date,
    required this.amountCents,
    required this.transactionType,
    this.onDelete,
  });

  final String name;
  final String categoryLabel;
  final DateTime date;
  final int amountCents;
  final TransactionType transactionType;

  /// If non-null, a delete icon button is shown on the trailing side.
  final VoidCallback? onDelete;

  bool get _isIncome => transactionType == TransactionType.income;

  Color get _color =>
      _isIncome ? AppColors.income : AppColors.expense;

  @override
  Widget build(BuildContext context) {
    final amountText = CurrencyFormatter.format(
      amountCents,
      isIncome: _isIncome,
    );
    final subtitle = '$categoryLabel · ${DateFormatter.format(date)}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color.withOpacity(0.15),
        child: Icon(
          _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
          color: _color,
          semanticLabel: _isIncome ? 'Ingreso' : 'Gasto',
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(color: AppColors.onBackground),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.onBackgroundMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amountText,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.danger,
              tooltip: 'Eliminar',
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
