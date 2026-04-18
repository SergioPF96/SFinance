import 'enums/transaction_type.dart';
import 'enums/periodicity.dart';
import 'enums/pay_frequency.dart';

class RecurringTemplate {
  const RecurringTemplate({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.transactionType,
    required this.category,
    required this.periodicity,
    required this.paymentDay,
    required this.startDate,
    required this.endDate,
    this.payFrequency,
    this.extraPayMonth1,
    this.extraPayMonth2,
    this.lastGeneratedPeriod,
    required this.isDeleted,
    required this.createdAt,
  });

  final int id;
  final String name;

  /// Always positive.
  final int amountCents;

  final TransactionType transactionType;

  /// Enum name string: suscripcion/financiacion (expense) or salario (income).
  final String category;

  final Periodicity periodicity;

  /// Day of month (1–31) when this recurring entry is charged or paid.
  /// Immutable after creation (FR-006). Clamped to month length at generation time.
  final int paymentDay;

  final DateTime startDate;
  final DateTime endDate;

  /// Only set when category=salario.
  final PayFrequency? payFrequency;

  /// 1–12. Only set when payFrequency=catorcepagas.
  final int? extraPayMonth1;

  /// 1–12. Must differ from [extraPayMonth1]. Only set when payFrequency=catorcepagas.
  final int? extraPayMonth2;

  /// Period key of the last generated transaction (e.g. "2026-04", "2026-07-extra").
  final String? lastGeneratedPeriod;

  /// Soft-delete flag. Stops future generation without removing past entries.
  final bool isDeleted;

  final DateTime createdAt;
}
