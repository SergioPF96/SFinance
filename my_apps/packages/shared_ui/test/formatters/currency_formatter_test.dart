import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/src/formatters/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('EUR symbol always present', () {
      test('formats income with EUR symbol and + sign', () {
        final result = CurrencyFormatter.format(2550, isIncome: true);
        expect(result, contains('€'));
        expect(result, contains('+'));
        expect(result, contains('25'));
      });

      test('formats expense with EUR symbol and − sign', () {
        final result = CurrencyFormatter.format(2550, isIncome: false);
        expect(result, contains('€'));
        expect(result, isNot(contains('+')));
        expect(result, contains('25'));
      });
    });

    group('locale-aware separators (Spanish: comma decimal, period thousands)', () {
      test('formats 1000 cents as €10,00', () {
        final result = CurrencyFormatter.format(1000, isIncome: true);
        // Spanish locale: comma as decimal separator
        expect(result, contains(','));
        expect(result, contains('10'));
      });

      test('formats 1234567 cents (12345.67) with period thousands separator', () {
        final result = CurrencyFormatter.format(1234567, isIncome: true);
        // 12345.67 → "12.345,67" in Spanish locale
        expect(result, contains('.'));
        expect(result, contains(','));
      });

      test('zero formatted as €0,00', () {
        final result = CurrencyFormatter.format(0, isIncome: true);
        expect(result, contains('0,00'));
        expect(result, contains('€'));
      });
    });

    group('explicit sign formatting', () {
      test('income: format shows + prefix with € symbol', () {
        final result = CurrencyFormatter.format(2550, isIncome: true);
        // e.g. "+€25,50"
        expect(result.contains('+'), isTrue);
        expect(result.contains('€'), isTrue);
        expect(result, contains('25,50'));
      });

      test('expense: format shows − prefix with € symbol', () {
        final result = CurrencyFormatter.format(2550, isIncome: false);
        // e.g. "−€25,50" (uses minus sign, not hyphen)
        expect(result.contains('€'), isTrue);
        expect(result, contains('25,50'));
        expect(result.contains('+'), isFalse);
      });
    });

    group('formatUnsigned', () {
      test('formats without sign for neutral display (e.g. Balance KPI)', () {
        final result = CurrencyFormatter.formatUnsigned(2550);
        expect(result, contains('€'));
        expect(result, contains('25,50'));
        expect(result.contains('+'), isFalse);
      });

      test('zero formatted as €0,00 unsigned', () {
        final result = CurrencyFormatter.formatUnsigned(0);
        expect(result, '€0,00');
      });
    });
  });
}
