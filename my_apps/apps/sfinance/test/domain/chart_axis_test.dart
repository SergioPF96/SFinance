import 'package:flutter_test/flutter_test.dart';
import 'package:sfinance/domain/chart_axis.dart';

void main() {
  group('niceInterval', () {
    test('zero range returns 1', () {
      expect(niceInterval(0), 1.0);
    });

    test('small range (100 cents = €1)', () {
      final interval = niceInterval(100);
      expect(interval, greaterThan(0));
      expect(interval, lessThanOrEqualTo(100));
    });

    test('medium range (1234 cents ≈ €12)', () {
      final interval = niceInterval(1234);
      expect(interval, greaterThan(0));
      // Should produce a "nice" value like 200, 500
      expect(interval, anyOf(equals(200.0), equals(500.0)));
    });

    test('large range (12345 cents ≈ €123)', () {
      final interval = niceInterval(12345);
      expect(interval, greaterThan(0));
      expect(interval, anyOf(equals(2000.0), equals(5000.0)));
    });

    test('very large range (999999 cents ≈ €9999)', () {
      final interval = niceInterval(999999);
      expect(interval, greaterThan(0));
      // Should be in the range of 200000
      expect(interval, anyOf(equals(200000.0), equals(500000.0)));
    });

    test('million+ range (1000000 cents = €10000)', () {
      final interval = niceInterval(1000000);
      expect(interval, greaterThan(0));
      expect(interval, anyOf(equals(200000.0), equals(500000.0)));
    });

    test('result divides range into ~4 intervals', () {
      for (final range in [500.0, 1500.0, 10000.0, 100000.0]) {
        final interval = niceInterval(range);
        final count = range / interval;
        expect(count, greaterThan(1), reason: 'range=$range interval=$interval');
        expect(count, lessThan(10), reason: 'range=$range interval=$interval');
      }
    });
  });

  group('formatAxisLabel', () {
    test('zero', () {
      expect(formatAxisLabel(0), '€0');
    });

    test('small amount (42 cents)', () {
      expect(formatAxisLabel(42), '€0');
    });

    test('whole euros (4200 cents = €42)', () {
      expect(formatAxisLabel(4200), '€42');
    });

    test('just under 1k (99900 cents = €999)', () {
      expect(formatAxisLabel(99900), '€999');
    });

    test('1k+ (120000 cents = €1200)', () {
      expect(formatAxisLabel(120000), '€1,2k');
    });

    test('25k (2500000 cents)', () {
      expect(formatAxisLabel(2500000), '€25k');
    });

    test('1M+ (100000000 cents = €1000000)', () {
      expect(formatAxisLabel(100000000), '€1M');
    });

    test('negative value', () {
      final label = formatAxisLabel(-1000);
      expect(label, isNotEmpty);
    });
  });
}
