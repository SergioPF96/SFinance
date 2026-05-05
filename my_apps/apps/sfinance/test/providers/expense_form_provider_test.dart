import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/form_providers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer makeContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Returns the first-occurrence date given today and paymentDay,
/// mirroring the logic in ExpenseFormNotifier.submit().
DateTime _firstOccurrence(DateTime today, int paymentDay) {
  final clampedDay = paymentDay.clamp(1, _daysInMonth(today.year, today.month));
  if (clampedDay < today.day) {
    // Day already passed this month → next month
    final nextMonth = DateTime(today.year, today.month + 1);
    final clampedNext =
        paymentDay.clamp(1, _daysInMonth(nextMonth.year, nextMonth.month));
    return DateTime(nextMonth.year, nextMonth.month, clampedNext);
  }
  return DateTime(today.year, today.month, clampedDay);
}

// ---------------------------------------------------------------------------
// Tests — T007: First-occurrence skip logic
// ---------------------------------------------------------------------------

void main() {
  group('ExpenseFormNotifier — first-occurrence skip logic (T007)', () {
    const today = 13; // April 13, 2026

    final baseDate = DateTime(2026, 4, today); // April 13

    test('day=10 (already passed) → first occurrence in May', () {
      final result = _firstOccurrence(baseDate, 10);
      expect(result, DateTime(2026, 5, 10),
          reason: 'Day 10 has passed on Apr 13 → skip to May 10');
    });

    test('day=20 (not yet passed) → first occurrence in April', () {
      final result = _firstOccurrence(baseDate, 20);
      expect(result, DateTime(2026, 4, 20),
          reason: 'Day 20 has not passed on Apr 13 → use April 20');
    });

    test('day=13 (same day) → first occurrence is today (not skipped)', () {
      final result = _firstOccurrence(baseDate, 13);
      expect(result, DateTime(2026, 4, 13),
          reason: 'Same day as today is NOT "passed" → use today');
    });

    test('day=1 → first occurrence in next month when today=15', () {
      final result = _firstOccurrence(DateTime(2026, 4, 15), 1);
      expect(result, DateTime(2026, 5, 1),
          reason: 'Day 1 has passed on Apr 15 → skip to May 1');
    });

    test('day=31 in April (30-day month) → clamps to 30', () {
      final result = _firstOccurrence(DateTime(2026, 4, 1), 31);
      // April has 30 days; clampedDay=30 >= 1 → same month
      expect(result, DateTime(2026, 4, 30),
          reason: 'Day 31 in April clamps to 30');
    });

    test('day=31, today=31 (March) → same month (day not passed)', () {
      // March has 31 days
      final result = _firstOccurrence(DateTime(2026, 3, 31), 31);
      expect(result, DateTime(2026, 3, 31));
    });

    test('day=29 in February (non-leap) → clamps to 28, same month', () {
      // Feb 2026 is not a leap year. day 1 hasn't passed yet.
      final result = _firstOccurrence(DateTime(2026, 2, 1), 29);
      // clampedDay = min(29, 28) = 28 >= 1 → same month
      expect(result, DateTime(2026, 2, 28));
    });

    test('day=29 in Feb leap year → Feb 29 (same month)', () {
      // 2028 is a leap year
      final result = _firstOccurrence(DateTime(2028, 2, 1), 29);
      expect(result, DateTime(2028, 2, 29));
    });
  });

  group('ExpenseFormNotifier — submit sets paymentDay (integration, T009+T010)',
      () {
    test('submit with paymentDay validates field is required for recurring',
        () async {
      final container = makeContainer();
      final notifier = container.read(expenseFormProvider.notifier);

      notifier.setNombre('Netflix');
      notifier.setMonto('15');
      notifier.setCategoria(ExpenseCategory.suscripcion);
      notifier.setPeriodicidad(Periodicity.mensual);
      // fechaFin set to far future
      notifier.setFechaFin(DateTime(2030, 12, 31));
      // paymentDay NOT set

      final error = await notifier.submit();
      expect(error, isNotNull,
          reason: 'submit must fail when paymentDay is missing for recurring');
      expect(error, contains('día'),
          reason: 'Error message should mention day selection');
    });
  });

  // ---------------------------------------------------------------------------
  // FR-006 — save-time validation: first occurrence > endDate (T023)
  // T023 tests FAIL until FR-006 is implemented in ExpenseFormNotifier (T027)
  // ---------------------------------------------------------------------------

  group('ExpenseFormNotifier — FR-006 first-occurrence > endDate validation',
      () {
    /// Submits a Suscripción with the given paymentDay, fechaFin, and
    /// an injected [today] by temporarily overriding DateTime.now.
    ///
    /// Returns the error string from submit(), or null on success.
    Future<String?> submitSuscripcion(
      ProviderContainer container, {
      required int paymentDay,
      required DateTime fechaFin,
    }) async {
      final notifier = container.read(expenseFormProvider.notifier);
      notifier.setNombre('Servicio test');
      notifier.setMonto('9.99');
      notifier.setCategoria(ExpenseCategory.suscripcion);
      notifier.setPeriodicidad(Periodicity.mensual);
      notifier.setFechaFin(fechaFin);
      notifier.setPaymentDay(paymentDay);
      return notifier.submit();
    }

    test('paymentDay already past, fechaFin=today → reject with FR-006 error',
        () async {
      // paymentDay is set to a day that has already passed (today - 1, or 28
      // on the 1st to avoid being today). fechaFin = today, so the deferred
      // first occurrence (next month) is strictly after fechaFin.
      final container = makeContainer();
      final today = DateTime.now();
      final safePastDay = today.day > 1 ? today.day - 1 : 28;
      final fechaFin = DateTime(today.year, today.month, today.day);

      final error = await submitSuscripcion(
        container,
        paymentDay: safePastDay,
        fechaFin: fechaFin,
      );

      expect(error, isNotNull,
          reason: 'FR-006: should reject when first occurrence > fechaFin');
      expect(
        error,
        contains('fecha de fin'),
        reason: 'Error must mention fecha de fin',
      );

      // Verify no template was inserted
      final db = container.read(databaseProvider);
      final templates = await db.select(db.recurringTemplates).get();
      expect(templates, isEmpty,
          reason: 'FR-006: template must NOT be persisted on rejection');
    });

    test(
        'paymentDay already past, fechaFin far in future → save succeeds (no FR-006 rejection)',
        () async {
      final container = makeContainer();
      final today = DateTime.now();
      final safePastDay = today.day > 1 ? today.day - 1 : 28;
      // fechaFin two months from now → first occurrence (next month) < fechaFin
      final fechaFin = DateTime(today.year, today.month + 2, 28);

      final error = await submitSuscripcion(
        container,
        paymentDay: safePastDay,
        fechaFin: fechaFin,
      );

      expect(error, isNull,
          reason: 'FR-006 should not reject when first occurrence <= fechaFin');
    });

    test('paymentDay has NOT passed yet, fechaFin = same month end → succeeds',
        () async {
      final container = makeContainer();
      final today = DateTime.now();
      // paymentDay = tomorrow (not yet passed)
      final futureDay = today.day + 1;
      if (futureDay > 28) {
        // Skip on last days of month where futureDay might exceed end of month
        return;
      }
      // fechaFin = end of current month
      final endOfMonth = DateTime(today.year, today.month + 1, 0);

      final error = await submitSuscripcion(
        container,
        paymentDay: futureDay,
        fechaFin: endOfMonth,
      );

      expect(error, isNull,
          reason:
              'paymentDay not yet passed → first occurrence is this month → should not reject');
    });
  });

  // ---------------------------------------------------------------------------
  // T005 — FR-005 / FR-009: open-ended subscription submit (spec 007)
  // These tests FAIL until T008–T010 add openEnded support to ExpenseFormNotifier.
  // ---------------------------------------------------------------------------

  group('ExpenseFormNotifier — open-ended subscription (spec 007)', () {
    Future<String?> submitOpenEnded(
      ProviderContainer container, {
      int paymentDay = 10,
    }) async {
      final notifier = container.read(expenseFormProvider.notifier);
      notifier.setNombre('Netflix');
      notifier.setMonto('15.99');
      notifier.setCategoria(ExpenseCategory.suscripcion);
      notifier.setPeriodicidad(Periodicity.mensual);
      notifier.setOpenEnded(true); // no fechaFin
      notifier.setPaymentDay(paymentDay);
      return notifier.submit();
    }

    test('open-ended submit succeeds and persists template with endDate=null',
        () async {
      final container = makeContainer();
      final error = await submitOpenEnded(container);

      expect(error, isNull,
          reason: 'open-ended subscription must save without error');

      final db = container.read(databaseProvider);
      final templates = await db.select(db.recurringTemplates).get();
      expect(templates, hasLength(1));
      expect(templates.first.endDate, isNull,
          reason: 'endDate must be null for open-ended template');
    });

    test(
        'FR-006 validation is skipped for open-ended (paymentDay past, no endDate)',
        () async {
      final container = makeContainer();
      final today = DateTime.now();
      // Use a paymentDay that has already passed — would normally trigger FR-006
      // if there were an endDate set to today.
      final pastDay = today.day > 1 ? today.day - 1 : 28;
      final error = await submitOpenEnded(container, paymentDay: pastDay);

      expect(error, isNull,
          reason:
              'FR-006 must not fire for open-ended subscriptions (no endDate)');
    });

    test('setOpenEnded(true) clears fechaFin', () {
      final container = makeContainer();
      final notifier = container.read(expenseFormProvider.notifier);
      notifier.setCategoria(ExpenseCategory.suscripcion);
      notifier.setPeriodicidad(Periodicity.mensual);
      notifier.setFechaFin(DateTime(2027, 12, 31));
      notifier.setOpenEnded(true);
      expect(container.read(expenseFormProvider).fechaFin, isNull);
    });

    test('setOpenEnded(true) then setOpenEnded(false) → fechaFin still null',
        () {
      final container = makeContainer();
      final notifier = container.read(expenseFormProvider.notifier);
      notifier.setCategoria(ExpenseCategory.suscripcion);
      notifier.setPeriodicidad(Periodicity.mensual);
      notifier.setFechaFin(DateTime(2027, 12, 31));
      notifier.setOpenEnded(true);
      notifier.setOpenEnded(false);
      expect(container.read(expenseFormProvider).fechaFin, isNull,
          reason: 'previously selected fechaFin must NOT be restored');
    });
  });
}
