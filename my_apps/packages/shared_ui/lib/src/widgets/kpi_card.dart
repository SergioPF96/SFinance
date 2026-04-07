import 'package:flutter/material.dart';
import '../formatters/currency_formatter.dart';
import '../theme/app_theme.dart';

/// Presentational KPI card widget.
///
/// Displays a label and a formatted currency amount with an explicit sign.
/// Used in the KPI strip on Resumen and Analisis views.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.amountCents,
    required this.color,
    this.isIncome = true,
    this.showSign = true,
    this.child,
  });

  final String label;

  /// Amount in integer cents. Always non-negative; sign controlled by [isIncome].
  final int amountCents;

  final Color color;

  /// True → format as income (+). False → format as expense (−).
  final bool isIncome;

  /// Whether to show a +/− sign prefix.
  final bool showSign;

  /// Optional child widget rendered below the amount (e.g. initial capital editor).
  final Widget? child;

  String get _formattedAmount => showSign
      ? CurrencyFormatter.format(amountCents, isIncome: isIncome)
      : CurrencyFormatter.formatUnsigned(amountCents);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.onBackgroundMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formattedAmount,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 8),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
