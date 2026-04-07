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
    });
  });
}
