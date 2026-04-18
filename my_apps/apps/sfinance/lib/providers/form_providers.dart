import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';
import 'database_provider.dart';
import '../services/recurring_generation_service.dart';

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
    this.openEnded = false,
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

  /// Whether this Suscripción has no end date ("Sin fecha de fin").
  /// When true, fechaFin is null and no end date is required or stored.
  final bool openEnded;

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
    bool? openEnded,
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
      openEnded: openEnded ?? this.openEnded,
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
    // Clear all recurring fields (including openEnded) when switching category.
    state = state.copyWith(
      categoria: v,
      periodicidad: null,
      fechaFin: null,
      paymentDay: null,
      openEnded: false,
    );
  }

  void setPeriodicidad(Periodicity? v) => state = state.copyWith(
      periodicidad: v, fechaFin: null, paymentDay: null, openEnded: false);

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

  /// Toggles "Sin fecha de fin" mode. When [v] is true, clears fechaFin.
  /// When [v] is false, fechaFin remains null (user must select a date again).
  void setOpenEnded(bool v) =>
      state = state.copyWith(openEnded: v, fechaFin: null);

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
      // fechaFin only required when not open-ended.
      if (!s.openEnded && s.fechaFin == null) {
        return 'Selecciona la fecha de fin';
      }
      final today = DateTime.now();
      if (!s.openEnded &&
          s.fechaFin!.isBefore(DateTime(today.year, today.month, today.day))) {
        return 'La fecha de fin debe ser hoy o posterior';
      }
      if (s.paymentDay == null) {
        return 'Selecciona el día de cobro/pago';
      }
      // FR-006: for monthly templates, reject if the calculated first occurrence
      // falls after fechaFin. Skipped for open-ended (no fechaFin), for annual
      // (paymentDay irrelevant there).
      if (!s.openEnded && s.periodicidad == Periodicity.mensual) {
        final firstOccurrence = PeriodGenerator.firstOccurrenceDate(
          today: today,
          paymentDay: s.paymentDay!,
        );
        if (firstOccurrence.isAfter(s.fechaFin!)) {
          return 'El día de pago ya pasó este mes y la fecha de fin no alcanza al mes siguiente';
        }
      }
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final dao = ref.read(transactionDaoProvider);

      if (s.isRecurring) {
        // Create RecurringTemplate, then delegate first-entry generation to
        // RecurringGenerationService (which uses PeriodGenerator with
        // date-level filtering).
        final templateDao = ref.read(templateDaoProvider);
        final db = ref.read(databaseProvider);
        final today = DateTime.now();
        final paymentDay = s.paymentDay!;

        if (s.periodicidad == Periodicity.mensual) {
          // Compute startDate: if paymentDay already passed this month, the
          // first eligible month is next month; otherwise it is this month.
          // PeriodGenerator's date-level filter then decides whether to
          // generate the entry immediately (paymentDay == today) or defer it.
          final daysThisMonth =
              DateTime(today.year, today.month + 1, 0).day;
          final clampedDay = paymentDay.clamp(1, daysThisMonth);
          final DateTime startDate;
          if (clampedDay < today.day) {
            // Day already passed this month → first eligible month is next month
            startDate = DateTime(today.year, today.month + 1, 1);
          } else {
            startDate = DateTime(today.year, today.month, 1);
          }

          final templateId = await templateDao.insert(
            RecurringTemplatesCompanion.insert(
              name: trimmedNombre,
              amountCents: amountCents,
              transactionType: 'expense',
              category: s.categoria!.name,
              periodicity: s.periodicidad!.name,
              startDate: startDate,
              endDate: Value(s.openEnded ? null : s.fechaFin),
              paymentDay: Value(paymentDay),
            ),
          );

          // Fetch the saved template row and delegate entry generation.
          // generateForTemplate() will produce an entry only if paymentDay
          // has arrived (≤ today); otherwise it does nothing and the entry
          // will be created on the next app launch when the date arrives.
          final template = await (db.select(db.recurringTemplates)
                ..where((t) => t.id.equals(templateId)))
              .getSingle();
          await RecurringGenerationService.generateForTemplate(
            db,
            template,
            today: today,
          );
        } else {
          // Annual — keep existing behavior: generate first entry for today
          // (annual out of scope for this feature).
          final firstDate = today;
          final periodKey = '${today.year}';
          final startDate = DateTime(firstDate.year, firstDate.month, 1);

          final templateId = await templateDao.insert(
            RecurringTemplatesCompanion.insert(
              name: trimmedNombre,
              amountCents: amountCents,
              transactionType: 'expense',
              category: s.categoria!.name,
              periodicity: s.periodicidad!.name,
              startDate: startDate,
              endDate: Value(s.fechaFin),
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
        }
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
        // Salario is always monthly — compute startDate using skip logic, then
        // delegate first-entry generation to RecurringGenerationService.
        final templateDao = ref.read(templateDaoProvider);
        final db = ref.read(databaseProvider);
        final paymentDay = s.paymentDay!;

        // Determine the first eligible month (same skip logic as expense).
        final daysThisMonth = DateTime(today.year, today.month + 1, 0).day;
        final clampedDay = paymentDay.clamp(1, daysThisMonth);
        final DateTime startDate;
        if (clampedDay < today.day) {
          startDate = DateTime(today.year, today.month + 1, 1);
        } else {
          startDate = DateTime(today.year, today.month, 1);
        }

        // End date = far future for open-ended salary
        final farFuture = DateTime(today.year + 50, 12, 31);

        final templateId = await templateDao.insert(
          RecurringTemplatesCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'income',
            category: IncomeCategory.salario.name,
            periodicity: Periodicity.mensual.name,
            startDate: startDate,
            endDate: Value(farFuture),
            payFrequency: Value(s.numeroPagas!.name),
            extraPayMonth1: Value(
                s.isCatorcepagas ? s.primeraPagaExtra : null),
            extraPayMonth2: Value(
                s.isCatorcepagas ? s.segundaPagaExtra : null),
            paymentDay: Value(paymentDay),
          ),
        );

        // Fetch saved template and delegate entry generation. The service
        // handles both regular and 14-paga extra entries via PeriodGenerator.
        final template = await (db.select(db.recurringTemplates)
              ..where((t) => t.id.equals(templateId)))
            .getSingle();
        await RecurringGenerationService.generateForTemplate(
          db,
          template,
          today: today,
        );
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
