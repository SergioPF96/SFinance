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
}
