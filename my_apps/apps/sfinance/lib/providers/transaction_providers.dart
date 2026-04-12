import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'package:shared_ui/shared_ui.dart' hide TransactionRow;
import 'package:shared_models/shared_models.dart';
import 'dao_providers.dart';

/// Display model for a single transaction row in the UI.
class TransactionDisplay {
  const TransactionDisplay({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.date,
    required this.amountCents,
    required this.transactionType,
    required this.iconColor,
  });

  final int id;
  final String name;
  final String categoryLabel;
  final DateTime date;
  final int amountCents;
  final TransactionType transactionType;
  final Color iconColor;
}

/// Maps a raw [TransactionRow] to a UI-ready [TransactionDisplay].
TransactionDisplay _toDisplay(TransactionRow row) {
  final isIncome = row.transactionType == 'income';
  final type = isIncome ? TransactionType.income : TransactionType.expense;
  final color = isIncome ? AppColors.income : AppColors.expense;

  String label;
  if (isIncome) {
    final cat = IncomeCategory.values.where((c) => c.name == row.category).firstOrNull;
    label = cat?.displayLabel ?? row.category;
  } else {
    final cat = ExpenseCategory.values.where((c) => c.name == row.category).firstOrNull;
    label = cat?.displayLabel ?? row.category;
  }

  return TransactionDisplay(
    id: row.id,
    name: row.name,
    categoryLabel: label,
    date: row.date,
    amountCents: row.amountCents,
    transactionType: type,
    iconColor: color,
  );
}

/// Most recent 10 transactions for the Resumen view. No delete affordance.
final recentTransactionsProvider =
    StreamProvider<List<TransactionDisplay>>((ref) {
  return ref
      .watch(transactionDaoProvider)
      .watchRecent(limit: 10)
      .map((rows) => rows.map(_toDisplay).toList());
});

/// All transactions matching a [TimeRange] for the Entradas view.
/// [TimeRange] is a string key defined in the analysis contracts.
final filteredTransactionsProvider =
    StreamProvider.family<List<TransactionDisplay>, DateTimeRange>(
  (ref, range) {
    return ref
        .watch(transactionDaoProvider)
        .watchFiltered(start: range.start, end: range.end)
        .map((rows) => rows.map(_toDisplay).toList());
  },
);
