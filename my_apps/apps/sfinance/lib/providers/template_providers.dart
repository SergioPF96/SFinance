import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';

// ---------------------------------------------------------------------------
// Pure helper — testable without widgets or DB
// ---------------------------------------------------------------------------

/// Returns the next calendar date on which [paymentDay] occurs, at or after
/// [today].
///
/// If [paymentDay] exceeds the number of days in the target month, the result
/// is clamped to the last day of that month.
DateTime computeNextPaymentDate(int paymentDay, DateTime today) {
  // Try same month first.
  final sameMonth = _clampedDate(today.year, today.month, paymentDay);
  if (!sameMonth.isBefore(DateTime(today.year, today.month, today.day))) {
    return sameMonth;
  }
  // Otherwise advance to next month.
  final nextMonth = today.month == 12 ? 1 : today.month + 1;
  final nextYear = today.month == 12 ? today.year + 1 : today.year;
  return _clampedDate(nextYear, nextMonth, paymentDay);
}

/// Creates a [DateTime] for the given year/month/day, clamping day to the
/// last valid day of that month.
DateTime _clampedDate(int year, int month, int day) {
  // DateTime with day=0 gives the last day of the previous month, so
  // DateTime(year, month+1, 0) gives the last day of [month].
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDay));
}

// ---------------------------------------------------------------------------
// Display model
// ---------------------------------------------------------------------------

/// Display model for a recurring template row in the Recurrentes tab.
class TemplateDisplay {
  const TemplateDisplay({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.periodicity,
    required this.endDate,
    required this.transactionType,
    required this.amountCents,
    required this.paymentDay,
    required this.nextPaymentDate,
  });

  final int id;
  final String name;
  final String categoryLabel;
  final String periodicity;

  /// Null for open-ended subscriptions ("Sin fecha de fin").
  final DateTime? endDate;
  final TransactionType transactionType;

  /// Current amount in cents.
  final int amountCents;

  /// Day of month configured for this template (1–31). Null = legacy → 1.
  final int? paymentDay;

  /// Next calendar date on which this payment is due.
  final DateTime nextPaymentDate;
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

  final effectiveDay = row.paymentDay ?? 1;

  return TemplateDisplay(
    id: row.id,
    name: row.name,
    categoryLabel: catLabel,
    periodicity: perLabel,
    endDate: row.endDate,
    transactionType: row.transactionType == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    amountCents: row.amountCents,
    paymentDay: row.paymentDay,
    nextPaymentDate: computeNextPaymentDate(effectiveDay, DateTime.now()),
  );
}

/// All active (non-deleted) recurring templates, ordered by creation date asc.
final activeTemplatesProvider =
    StreamProvider<List<TemplateDisplay>>((ref) {
  return ref
      .watch(templateDaoProvider)
      .watchActive()
      .map((rows) => rows.map(_toDisplay).toList());
});

// ---------------------------------------------------------------------------
// Template detail modal state
// ---------------------------------------------------------------------------

class TemplateDetailState {
  const TemplateDetailState({
    this.isEditingAmount = false,
    this.amountText = '',
    this.amountError,
    this.isSubmitting = false,
  });

  final bool isEditingAmount;
  final String amountText;
  final String? amountError;
  final bool isSubmitting;

  TemplateDetailState copyWith({
    bool? isEditingAmount,
    String? amountText,
    Object? amountError = _sentinel,
    bool? isSubmitting,
  }) {
    return TemplateDetailState(
      isEditingAmount: isEditingAmount ?? this.isEditingAmount,
      amountText: amountText ?? this.amountText,
      amountError:
          amountError == _sentinel ? this.amountError : amountError as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

const _sentinel = Object();

class TemplateDetailNotifier extends StateNotifier<TemplateDetailState> {
  TemplateDetailNotifier() : super(const TemplateDetailState());

  /// Activates inline edit mode, pre-filling with the current amount in euros.
  void startEditing(int currentAmountCents) {
    final euros = (currentAmountCents / 100).toStringAsFixed(2);
    state = state.copyWith(
      isEditingAmount: true,
      amountText: euros,
      amountError: null,
    );
  }

  void setAmountText(String text) {
    state = state.copyWith(amountText: text, amountError: null);
  }

  void cancelEdit() {
    state = state.copyWith(
      isEditingAmount: false,
      amountText: '',
      amountError: null,
    );
  }

  /// Validates and persists the edited amount. Calls [dao.updateAmount] on
  /// success. Used in production code.
  Future<void> confirmEdit(int templateId, TemplateDao dao) async {
    final error = _validateAmount(state.amountText);
    if (error != null) {
      state = state.copyWith(amountError: error);
      return;
    }
    final cents = (double.parse(state.amountText) * 100).round();
    state = state.copyWith(isSubmitting: true, amountError: null);
    await dao.updateAmount(templateId, cents);
    state = state.copyWith(
      isEditingAmount: false,
      isSubmitting: false,
      amountText: '',
    );
  }

  /// Validates and updates state without a real DAO — used in unit tests.
  void confirmEditForTest() {
    final error = _validateAmount(state.amountText);
    if (error != null) {
      state = state.copyWith(amountError: error);
      return;
    }
    state = state.copyWith(
      isEditingAmount: false,
      amountText: '',
      amountError: null,
    );
  }

  /// Soft-deletes the template.
  Future<void> deleteTemplate(int id, TemplateDao dao) async {
    await dao.softDelete(id);
  }

  static String? _validateAmount(String text) {
    if (text.trim().isEmpty) return 'El monto no puede estar vacío';
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) return 'Introduce un número válido';
    if (value <= 0) return 'El monto debe ser mayor que cero';
    return null;
  }
}

/// Auto-disposed so modal state resets when no widget is listening.
final templateDetailProvider = StateNotifierProvider.autoDispose<
    TemplateDetailNotifier, TemplateDetailState>(
  (_) => TemplateDetailNotifier(),
);
