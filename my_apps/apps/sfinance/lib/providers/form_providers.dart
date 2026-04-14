import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';

// ---------------------------------------------------------------------------
// Expense Form
// ---------------------------------------------------------------------------

class ExpenseFormState {
  const ExpenseFormState({
    this.nombre = '',
    this.monto = '',
    this.descripcion = '',
    this.categoria,
    this.periodicidad,
    this.fechaFin,
    this.paymentDay,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String nombre;
  final String monto;
  final String descripcion;
  final ExpenseCategory? categoria;
  final Periodicity? periodicidad;
  final DateTime? fechaFin;

  /// Day of month (1–31) selected for recurring expenses. Null until set.
  final int? paymentDay;

  final bool isSubmitting;
  final String? errorMessage;

  bool get isRecurring =>
      categoria == ExpenseCategory.suscripcion ||
      categoria == ExpenseCategory.financiacion;

  ExpenseFormState copyWith({
    String? nombre,
    String? monto,
    String? descripcion,
    ExpenseCategory? categoria,
    Object? periodicidad = _sentinel,
    Object? fechaFin = _sentinel,
    Object? paymentDay = _sentinel,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
  }) {
    return ExpenseFormState(
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      periodicidad: periodicidad == _sentinel
          ? this.periodicidad
          : periodicidad as Periodicity?,
      fechaFin: fechaFin == _sentinel ? this.fechaFin : fechaFin as DateTime?,
      paymentDay:
          paymentDay == _sentinel ? this.paymentDay : paymentDay as int?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// Sentinel object for nullable copyWith fields.
const _sentinel = Object();

class ExpenseFormNotifier extends Notifier<ExpenseFormState> {
  @override
  ExpenseFormState build() => const ExpenseFormState();

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setMonto(String v) => state = state.copyWith(monto: v);
  void setDescripcion(String v) => state = state.copyWith(descripcion: v);

  void setCategoria(ExpenseCategory? v) {
    // Clear recurring fields when switching away from recurring categories.
    state = state.copyWith(
      categoria: v,
      periodicidad: null,
      fechaFin: null,
      paymentDay: null,
    );
  }

  void setPeriodicidad(Periodicity? v) =>
      state = state.copyWith(periodicidad: v, fechaFin: null, paymentDay: null);

  void setFechaFin(DateTime? v) {
    if (v != null && state.periodicidad == Periodicity.anual) {
      // Clamp paymentDay to the new month's length (FR-009)
      final maxDay = DateTime(v.year, v.month + 1, 0).day;
      final clamped = state.paymentDay?.clamp(1, maxDay);
      state = state.copyWith(fechaFin: v, paymentDay: clamped);
    } else {
      state = state.copyWith(fechaFin: v);
    }
  }

  void setPaymentDay(int? v) => state = state.copyWith(paymentDay: v);

  /// Validates and submits the form.
  /// Returns null on success, error message string on failure.
  Future<String?> submit() async {
    final s = state;
    final trimmedNombre = s.nombre.trim();

    if (trimmedNombre.isEmpty) return 'El nombre es obligatorio';

    final amountDouble = double.tryParse(s.monto.replaceAll(',', '.'));
    if (amountDouble == null || amountDouble <= 0) {
      return 'Introduce un importe valido mayor que 0';
    }
    final amountCents = (amountDouble * 100).round();

    if (s.categoria == null) return 'Selecciona una categoria';

    if (s.isRecurring) {
      if (s.periodicidad == null) return 'Selecciona la periodicidad';
      if (s.fechaFin == null) return 'Selecciona la fecha de fin';
      final today = DateTime.now();
      if (s.fechaFin!.isBefore(DateTime(today.year, today.month, today.day))) {
        return 'La fecha de fin debe ser hoy o posterior';
      }
      if (s.paymentDay == null) {
        return 'Selecciona el día de cobro/pago';
      }
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final dao = ref.read(transactionDaoProvider);

      if (s.isRecurring) {
        // Create RecurringTemplate + first Transaction entry
        final templateDao = ref.read(templateDaoProvider);
        final today = DateTime.now();
        final paymentDay = s.paymentDay!;

        // Compute first-occurrence date using paymentDay skip logic.
        final DateTime firstDate;
        final String periodKey;
        if (s.periodicidad == Periodicity.mensual) {
          final daysThisMonth =
              DateTime(today.year, today.month + 1, 0).day;
          final clampedDay = paymentDay.clamp(1, daysThisMonth);
          if (clampedDay < today.day) {
            // Day already passed this month → next month
            final nextMonth = DateTime(today.year, today.month + 1);
            final daysNext =
                DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
            final clampedNext = paymentDay.clamp(1, daysNext);
            firstDate =
                DateTime(nextMonth.year, nextMonth.month, clampedNext);
          } else {
            firstDate = DateTime(today.year, today.month, clampedDay);
          }
          periodKey =
              '${firstDate.year}-${firstDate.month.toString().padLeft(2, '0')}';
        } else {
          // Annual — first occurrence is in the year's endDate month
          firstDate = today;
          periodKey = '${today.year}';
        }

        // startDate = first of the firstDate month so PeriodGenerator
        // includes the correct first period.
        final startDate = DateTime(firstDate.year, firstDate.month, 1);

        final templateId = await templateDao.insert(
          RecurringTemplatesCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'expense',
            category: s.categoria!.name,
            periodicity: s.periodicidad!.name,
            startDate: startDate,
            endDate: s.fechaFin!,
            paymentDay: Value(paymentDay),
          ),
        );

        await dao.insert(
          TransactionsCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'expense',
            category: s.categoria!.name,
            date: firstDate,
            templateId: Value(templateId),
          ),
        );

        await templateDao.updateLastGeneratedPeriod(templateId, periodKey);
      } else {
        // One-off expense
        final today = DateTime.now();

        await dao.insert(
          TransactionsCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'expense',
            category: s.categoria!.name,
            date: today,
            description: Value(s.descripcion.trim().isEmpty
                ? null
                : s.descripcion.trim()),
          ),
        );
      }

      // Reset form
      state = const ExpenseFormState();
      return null;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error al guardar. Inténtalo de nuevo.',
      );
      return state.errorMessage;
    }
  }
}

final expenseFormProvider =
    NotifierProvider<ExpenseFormNotifier, ExpenseFormState>(
        ExpenseFormNotifier.new);

// ---------------------------------------------------------------------------
// Income Form (added in US2 — T042)
// ---------------------------------------------------------------------------

class IncomeFormState {
  const IncomeFormState({
    this.nombre = '',
    this.monto = '',
    this.descripcion = '',
    this.categoria,
    this.numeroPagas,
    this.primeraPagaExtra,
    this.segundaPagaExtra,
    this.paymentDay,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String nombre;
  final String monto;
  final String descripcion;
  final IncomeCategory? categoria;
  final PayFrequency? numeroPagas;
  final int? primeraPagaExtra;
  final int? segundaPagaExtra;

  /// Day of month (1–31) for salary deposit. Null until set.
  final int? paymentDay;

  final bool isSubmitting;
  final String? errorMessage;

  bool get isSalario => categoria == IncomeCategory.salario;
  bool get isCatorcepagas => numeroPagas == PayFrequency.catorcepagas;

  IncomeFormState copyWith({
    String? nombre,
    String? monto,
    String? descripcion,
    IncomeCategory? categoria,
    Object? numeroPagas = _sentinel,
    Object? primeraPagaExtra = _sentinel,
    Object? segundaPagaExtra = _sentinel,
    Object? paymentDay = _sentinel,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
  }) {
    return IncomeFormState(
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      numeroPagas: numeroPagas == _sentinel
          ? this.numeroPagas
          : numeroPagas as PayFrequency?,
      primeraPagaExtra: primeraPagaExtra == _sentinel
          ? this.primeraPagaExtra
          : primeraPagaExtra as int?,
      segundaPagaExtra: segundaPagaExtra == _sentinel
          ? this.segundaPagaExtra
          : segundaPagaExtra as int?,
      paymentDay:
          paymentDay == _sentinel ? this.paymentDay : paymentDay as int?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class IncomeFormNotifier extends Notifier<IncomeFormState> {
  @override
  IncomeFormState build() => const IncomeFormState();

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setMonto(String v) => state = state.copyWith(monto: v);
  void setDescripcion(String v) => state = state.copyWith(descripcion: v);

  void setCategoria(IncomeCategory? v) {
    state = state.copyWith(
      categoria: v,
      numeroPagas: null,
      primeraPagaExtra: null,
      segundaPagaExtra: null,
      paymentDay: null,
    );
  }

  void setNumeroPagas(PayFrequency? v) {
    state = state.copyWith(
      numeroPagas: v,
      primeraPagaExtra: null,
      segundaPagaExtra: null,
      paymentDay: null,
    );
  }

  void setPaymentDay(int? v) => state = state.copyWith(paymentDay: v);

  void setPrimeraPagaExtra(int? v) =>
      state = state.copyWith(primeraPagaExtra: v);

  void setSegundaPagaExtra(int? v) =>
      state = state.copyWith(segundaPagaExtra: v);

  Future<String?> submit() async {
    final s = state;
    final trimmedNombre = s.nombre.trim();

    if (trimmedNombre.isEmpty) return 'El nombre es obligatorio';

    final amountDouble = double.tryParse(s.monto.replaceAll(',', '.'));
    if (amountDouble == null || amountDouble <= 0) {
      return 'Introduce un importe valido mayor que 0';
    }
    final amountCents = (amountDouble * 100).round();

    if (s.categoria == null) return 'Selecciona una categoria';

    if (s.isSalario) {
      if (s.numeroPagas == null) return 'Selecciona el numero de pagas';
      if (s.isCatorcepagas) {
        if (s.primeraPagaExtra == null || s.segundaPagaExtra == null) {
          return 'Selecciona los meses de paga extra';
        }
        if (s.primeraPagaExtra == s.segundaPagaExtra) {
          return 'Los meses de paga extra deben ser distintos';
        }
      }
      if (s.paymentDay == null) {
        return 'Selecciona el día de cobro del salario';
      }
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final dao = ref.read(transactionDaoProvider);
      final today = DateTime.now();

      if (s.isSalario) {
        final templateDao = ref.read(templateDaoProvider);
        final paymentDay = s.paymentDay!;

        // Compute first-occurrence date using paymentDay skip logic.
        final daysThisMonth = DateTime(today.year, today.month + 1, 0).day;
        final clampedDay = paymentDay.clamp(1, daysThisMonth);
        final DateTime firstDate;
        if (clampedDay < today.day) {
          final nextMonth = DateTime(today.year, today.month + 1);
          final daysNext =
              DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final clampedNext = paymentDay.clamp(1, daysNext);
          firstDate = DateTime(nextMonth.year, nextMonth.month, clampedNext);
        } else {
          firstDate = DateTime(today.year, today.month, clampedDay);
        }

        final periodKey =
            '${firstDate.year}-${firstDate.month.toString().padLeft(2, '0')}';

        // startDate = first of the firstDate month
        final startDate = DateTime(firstDate.year, firstDate.month, 1);

        // End date = far future for open-ended salary
        final farFuture = DateTime(today.year + 50, 12, 31);
        final extraMonths = s.isCatorcepagas
            ? [s.primeraPagaExtra!, s.segundaPagaExtra!]
            : <int>[];

        final templateId = await templateDao.insert(
          RecurringTemplatesCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'income',
            category: IncomeCategory.salario.name,
            periodicity: Periodicity.mensual.name,
            startDate: startDate,
            endDate: farFuture,
            payFrequency: Value(s.numeroPagas!.name),
            extraPayMonth1: Value(
                s.isCatorcepagas ? s.primeraPagaExtra : null),
            extraPayMonth2: Value(
                s.isCatorcepagas ? s.segundaPagaExtra : null),
            paymentDay: Value(paymentDay),
          ),
        );

        await dao.insert(
          TransactionsCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'income',
            category: IncomeCategory.salario.name,
            date: firstDate,
            templateId: Value(templateId),
            description: Value(s.descripcion.trim().isEmpty
                ? null
                : s.descripcion.trim()),
          ),
        );

        // Also generate extra entry if firstDate's month is a bonus month
        if (extraMonths.contains(firstDate.month)) {
          await dao.insert(
            TransactionsCompanion.insert(
              name: trimmedNombre,
              amountCents: amountCents,
              transactionType: 'income',
              category: IncomeCategory.salario.name,
              date: firstDate,
              templateId: Value(templateId),
            ),
          );
          await templateDao.updateLastGeneratedPeriod(
              templateId, '$periodKey-extra');
        } else {
          await templateDao.updateLastGeneratedPeriod(templateId, periodKey);
        }
      } else {
        // One-off income
        await dao.insert(
          TransactionsCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'income',
            category: s.categoria!.name,
            date: today,
            description: Value(s.descripcion.trim().isEmpty
                ? null
                : s.descripcion.trim()),
          ),
        );
      }

      state = const IncomeFormState();
      return null;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error al guardar. Inténtalo de nuevo.',
      );
      return state.errorMessage;
    }
  }
}

final incomeFormProvider =
    NotifierProvider<IncomeFormNotifier, IncomeFormState>(
        IncomeFormNotifier.new);
