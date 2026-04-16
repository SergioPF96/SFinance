import 'package:test/test.dart';
import 'package:shared_services/src/generation/period_generator.dart';

void main() {
  group('PeriodGenerator', () {
    final jan1 = DateTime(2026, 1, 1);
    final mar31 = DateTime(2026, 3, 31);

    group('monthly period keys', () {
      test('returns correct "YYYY-MM" format for each month', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: jan1,
          endDate: DateTime(2026, 3, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: mar31,
        );
        expect(keys, ['2026-01', '2026-02', '2026-03']);
      });

      test('single month when startDate == endDate (same month)', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 30),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: DateTime(2026, 4, 7),
        );
        expect(keys, ['2026-04']);
      });

      test('keys are ordered chronologically', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: jan1,
          endDate: DateTime(2026, 6, 30),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: DateTime(2026, 6, 1),
        );
        expect(keys, ['2026-01', '2026-02', '2026-03', '2026-04', '2026-05', '2026-06']);
      });
    });

    group('annual period keys', () {
      test('returns correct "YYYY" format', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'anual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: DateTime(2026, 4, 7),
        );
        expect(keys, ['2025', '2026']);
      });

      test('returns single key when start and today are same year', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2028, 12, 31),
          periodicity: 'anual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: DateTime(2026, 4, 7),
        );
        expect(keys, ['2026']);
      });
    });

    group('14-paga extra keys', () {
      test('generates regular + extra key for bonus months', () {
        // July (7) and December (12) are bonus months
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: [7, 12],
          today: DateTime(2026, 12, 1),
        );
        expect(keys, [
          '2026-07',
          '2026-07-extra',
          '2026-08',
          '2026-09',
          '2026-10',
          '2026-11',
          '2026-12',
          '2026-12-extra',
        ]);
      });

      test('extra key sorts after regular key for same month', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: [7],
          today: DateTime(2026, 7, 31),
        );
        expect(keys, ['2026-07', '2026-07-extra']);
      });
    });

    group('lastGeneratedPeriod filtering', () {
      test('excludes keys <= lastGeneratedPeriod', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: jan1,
          endDate: mar31,
          periodicity: 'mensual',
          lastGeneratedPeriod: '2026-01',
          extraPayMonths: null,
          today: mar31,
        );
        expect(keys, ['2026-02', '2026-03']);
      });

      test('returns empty when all periods already generated', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: jan1,
          endDate: mar31,
          periodicity: 'mensual',
          lastGeneratedPeriod: '2026-03',
          extraPayMonths: null,
          today: mar31,
        );
        expect(keys, isEmpty);
      });

      test('same-day re-launch returns empty when current period already generated', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 7),
          endDate: DateTime(2027, 4, 7),
          periodicity: 'mensual',
          lastGeneratedPeriod: '2026-04',
          extraPayMonths: null,
          today: DateTime(2026, 4, 7),
        );
        expect(keys, isEmpty);
      });

      test('filters correctly for extra period keys', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: '2026-07',
          extraPayMonths: [7, 12],
          today: DateTime(2026, 9, 1),
        );
        // '2026-07' already generated; '2026-07-extra' comes after it so included
        expect(keys, ['2026-07-extra', '2026-08', '2026-09']);
      });
    });

    group('edge cases', () {
      test('caps generation at min(today, endDate)', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: jan1,
          endDate: DateTime(2026, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: DateTime(2026, 3, 15), // today is in March
        );
        // Should only include Jan, Feb, Mar (not beyond today's month)
        expect(keys, ['2026-01', '2026-02', '2026-03']);
      });

      test('end date in the past returns empty when all generated', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 3, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: '2025-03',
          extraPayMonths: null,
          today: DateTime(2026, 4, 7),
        );
        expect(keys, isEmpty);
      });

      test('start date in future returns empty', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2027, 1, 1),
          endDate: DateTime(2028, 1, 1),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          extraPayMonths: null,
          today: DateTime(2026, 4, 7),
        );
        expect(keys, isEmpty);
      });

      // paymentDay=1 default: existing tests without paymentDay param use
      // default=1, so day 1 of any month is <= any today in that month → no
      // regressions.
      test('default paymentDay=1 does not break existing callers (no param passed)', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: jan1,
          endDate: DateTime(2026, 3, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          today: mar31,
        );
        expect(keys, ['2026-01', '2026-02', '2026-03']);
      });
    });

    // -------------------------------------------------------------------------
    // paymentDay date-level filtering (feature 006)
    // -------------------------------------------------------------------------

    group('paymentDay date-level filtering', () {
      // US1 — T003: paymentDay == today → key included
      test('[US1] paymentDay=16, today=April 16 → current month included', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 16,
          today: DateTime(2026, 4, 16),
        );
        expect(keys, ['2026-04']);
      });

      test('[US1] paymentDay=1, today=April 1 → included (first day of month)', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 1,
          today: DateTime(2026, 4, 1),
        );
        expect(keys, ['2026-04']);
      });

      test('[US1] paymentDay=31, today=March 31 → included (month has 31 days)', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 31,
          today: DateTime(2026, 3, 31),
        );
        expect(keys, ['2026-03']);
      });

      // US2 — T009/T010: paymentDay > today in current month → key excluded
      // NOTE: These tests FAIL with PeriodGenerator before feature-006 is
      // implemented. They are the Constitution Principle IV failing tests.
      test('[US2] paymentDay=20, today=April 16 → current month excluded', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 20,
          today: DateTime(2026, 4, 16),
        );
        expect(keys, isEmpty);
      });

      test('[US2] paymentDay=31, today=April 16 → clamped to April 30, still future → excluded', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 31,
          today: DateTime(2026, 4, 16),
        );
        expect(keys, isEmpty);
      });

      test('[US2] paymentDay=30, today=April 30 → clamped to April 30, equals today → included', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 30,
          today: DateTime(2026, 4, 30),
        );
        expect(keys, ['2026-04']);
      });

      test('[US2] paymentDay=20 arrives: today=April 20 → included', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 20,
          today: DateTime(2026, 4, 20),
        );
        expect(keys, ['2026-04']);
      });

      // US3 — T014/T015: paymentDay < today, startDate = next month → no key yet
      test('[US3] startDate=May 1, paymentDay=10, today=April 16 → no keys yet', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 10,
          today: DateTime(2026, 4, 16),
        );
        expect(keys, isEmpty);
      });

      test('[US3] startDate=May 1, paymentDay=10, today=May 10 → first key generated', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 10,
          today: DateTime(2026, 5, 10),
        );
        expect(keys, ['2026-05']);
      });

      test('[US3] startDate=May 1, paymentDay=10, today=May 9 → not yet', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 10,
          today: DateTime(2026, 5, 9),
        );
        expect(keys, isEmpty);
      });

      // paymentDay filter does not affect annual templates
      test('annual template: paymentDay filter not applied', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'anual',
          lastGeneratedPeriod: null,
          paymentDay: 25, // day 25, e.g. December 25 — but annual is not filtered
          today: DateTime(2026, 4, 16),
        );
        // Annual key '2026' should be included regardless of paymentDay vs today
        expect(keys, ['2026']);
      });

      // multi-month catch-up: paymentDay=10, past months included
      test('past months (paymentDay=10, today=June 16) → May and June pending (Jun not yet reached)', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 10,
          today: DateTime(2026, 6, 8), // June 8 — June 10 not yet arrived
        );
        // May 10 ≤ June 8 → included; June 10 > June 8 → excluded
        expect(keys, ['2026-05']);
      });

      test('past months (paymentDay=10, today=June 10) → May and June both included', () {
        final keys = PeriodGenerator.computeDueKeys(
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2027, 12, 31),
          periodicity: 'mensual',
          lastGeneratedPeriod: null,
          paymentDay: 10,
          today: DateTime(2026, 6, 10),
        );
        expect(keys, ['2026-05', '2026-06']);
      });
    });

    group('dateForKey', () {
      test('monthly key → paymentDay of that month', () {
        expect(
          PeriodGenerator.dateForKey('2026-04', 15),
          DateTime(2026, 4, 15),
        );
      });

      test('monthly key → paymentDay clamped to month length (Feb)', () {
        expect(
          PeriodGenerator.dateForKey('2026-02', 31),
          DateTime(2026, 2, 28),
        );
      });

      test('extra key → same date as regular monthly key', () {
        expect(
          PeriodGenerator.dateForKey('2026-07-extra', 15),
          DateTime(2026, 7, 15),
        );
      });

      test('annual key → paymentDay in annualMonth', () {
        expect(
          PeriodGenerator.dateForKey('2026', 10, annualMonth: 6),
          DateTime(2026, 6, 10),
        );
      });

      test('annual key → paymentDay clamped in February', () {
        expect(
          PeriodGenerator.dateForKey('2026', 30, annualMonth: 2),
          DateTime(2026, 2, 28),
        );
      });
    });
  });
}
