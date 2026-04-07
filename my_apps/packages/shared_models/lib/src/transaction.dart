import 'enums/transaction_type.dart';

class Transaction {
  const Transaction({
    required this.id,
    required this.name,
    required this.amountCents,
    this.description,
    required this.transactionType,
    required this.category,
    required this.date,
    this.templateId,
    required this.createdAt,
  });

  final int id;
  final String name;

  /// Always positive. Sign is determined by [transactionType].
  final int amountCents;

  final String? description;
  final TransactionType transactionType;

  /// Enum name string — either an ExpenseCategory or IncomeCategory name.
  final String category;

  final DateTime date;

  /// Null for one-off transactions; non-null for generated recurring entries.
  final int? templateId;

  final DateTime createdAt;
}
