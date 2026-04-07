import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';
import 'kpi_provider.dart';

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
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String nombre;
  final String monto;
  final String descripcion;
  final ExpenseCategory? categoria;
  final Periodicity? periodicidad;
  final DateTime? fechaFin;
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
    );
  }

  void setPeriodicidad(Periodicity? v) =>
      state = state.copyWith(periodicidad: v, fechaFin: null);

  void setFechaFin(DateTime? v) => state = state.copyWith(fechaFin: v);

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
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final dao = ref.read(transactionDaoProvider);
      final capitalDao = ref.read(initialCapitalDaoProvider);

      if (s.isRecurring) {
        // Create RecurringTemplate + first Transaction entry
        final templateDao = ref.read(templateDaoProvider);
        final today = DateTime.now();

        final templateId = await templateDao.insert(
          RecurringTemplatesCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'expense',
            category: s.categoria!.name,
            periodicity: s.periodicidad!.name,
            startDate: today,
            endDate: s.fechaFin!,
          ),
        );

        final periodKey = s.periodicidad == Periodicity.mensual
            ? '${today.year}-${today.month.toString().padLeft(2, '0')}'
            : '${today.year}';

        await dao.insert(
          TransactionsCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'expense',
            category: s.categoria!.name,
            date: today,
            templateId: Value(templateId),
          ),
        );

        await templateDao.updateLastGeneratedPeriod(templateId, periodKey);
      } else {
        // One-off expense
        final today = DateTime.now();
        final wasEmpty = !(ref.read(kpiProvider).value?.hasTransactions ?? false);

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

        if (wasEmpty) await capitalDao.deactivate();
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
    );
  }

  void setNumeroPagas(PayFrequency? v) {
    state = state.copyWith(
      numeroPagas: v,
      primeraPagaExtra: null,
      segundaPagaExtra: null,
    );
  }

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
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final dao = ref.read(transactionDaoProvider);
      final capitalDao = ref.read(initialCapitalDaoProvider);
      final today = DateTime.now();
      final wasEmpty =
          !(ref.read(kpiProvider).value?.hasTransactions ?? false);

      if (s.isSalario) {
        final templateDao = ref.read(templateDaoProvider);

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
            startDate: today,
            endDate: farFuture,
            payFrequency: Value(s.numeroPagas!.name),
            extraPayMonth1: Value(
                s.isCatorcepagas ? s.primeraPagaExtra : null),
            extraPayMonth2: Value(
                s.isCatorcepagas ? s.segundaPagaExtra : null),
          ),
        );

        final periodKey =
            '${today.year}-${today.month.toString().padLeft(2, '0')}';

        await dao.insert(
          TransactionsCompanion.insert(
            name: trimmedNombre,
            amountCents: amountCents,
            transactionType: 'income',
            category: IncomeCategory.salario.name,
            date: today,
            templateId: Value(templateId),
            description: Value(s.descripcion.trim().isEmpty
                ? null
                : s.descripcion.trim()),
          ),
        );

        // Also generate extra entry if today is a bonus month
        if (extraMonths.contains(today.month)) {
          await dao.insert(
            TransactionsCompanion.insert(
              name: trimmedNombre,
              amountCents: amountCents,
              transactionType: 'income',
              category: IncomeCategory.salario.name,
              date: today,
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

      if (wasEmpty) await capitalDao.deactivate();

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
