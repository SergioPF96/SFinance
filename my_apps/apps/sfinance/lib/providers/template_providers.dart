import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';

/// Display model for a recurring template row in the Recurrentes tab.
class TemplateDisplay {
  const TemplateDisplay({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.periodicity,
    required this.endDate,
    required this.transactionType,
  });

  final int id;
  final String name;
  final String categoryLabel;
  final String periodicity;
  final DateTime endDate;
  final TransactionType transactionType;
}

TemplateDisplay _toDisplay(RecurringTemplateRow row) {
  // Category label
  String catLabel;
  if (row.transactionType == 'income') {
    final cat = IncomeCategory.values
        .where((c) => c.name == row.category)
        .firstOrNull;
    catLabel = cat?.displayLabel ?? row.category;
  } else {
    final cat = ExpenseCategory.values
        .where((c) => c.name == row.category)
        .firstOrNull;
    catLabel = cat?.displayLabel ?? row.category;
  }

  // Periodicity label
  final per = Periodicity.values
      .where((p) => p.name == row.periodicity)
      .firstOrNull;
  final perLabel = per?.displayLabel ?? row.periodicity;

  return TemplateDisplay(
    id: row.id,
    name: row.name,
    categoryLabel: catLabel,
    periodicity: perLabel,
    endDate: row.endDate,
    transactionType: row.transactionType == 'income'
        ? TransactionType.income
        : TransactionType.expense,
  );
}

/// All active (non-deleted) recurring templates.
final activeTemplatesProvider =
    StreamProvider<List<TemplateDisplay>>((ref) {
  return ref
      .watch(templateDaoProvider)
      .watchActive()
      .map((rows) => rows.map(_toDisplay).toList());
});
