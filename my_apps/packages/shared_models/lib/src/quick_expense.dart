import 'enums/expense_category.dart';

class QuickExpense {
  const QuickExpense({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.category,
    this.imagePath,
    required this.createdAt,
  });

  final int id;

  /// Display name. Non-empty after trimming — enforced at save time.
  final String name;

  /// Always positive. Parsed via (double × 100).round().
  final int amountCents;

  final ExpenseCategory category;

  /// Absolute path to internal-storage copy. Null → show generic icon.
  final String? imagePath;

  /// Used only for display ordering (oldest-first). Not shown to the user.
  final DateTime createdAt;
}
