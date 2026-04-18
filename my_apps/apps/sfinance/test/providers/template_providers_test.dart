import 'package:flutter_test/flutter_test.dart';
import 'package:sfinance/providers/template_providers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // computeNextPaymentDate — test-first (Constitution Principle IV)
  // ---------------------------------------------------------------------------
  group('computeNextPaymentDate', () {
    test('paymentDay > today.day → same month, correct day', () {
      final today = DateTime(2026, 4, 10); // day 10
      final result = computeNextPaymentDate(15, today);
      expect(result, DateTime(2026, 4, 15));
    });

    test('paymentDay == today.day → same month, same day (today is payment day)', () {
      final today = DateTime(2026, 4, 15); // day 15
      final result = computeNextPaymentDate(15, today);
      expect(result, DateTime(2026, 4, 15));
    });

    test('paymentDay < today.day → next month, correct day', () {
      final today = DateTime(2026, 4, 20); // day 20
      final result = computeNextPaymentDate(15, today);
      expect(result, DateTime(2026, 5, 15));
    });

    test('paymentDay > days in destination month → clamped to last day of month', () {
      // paymentDay=31, next month is February (28 days in 2026)
      final today = DateTime(2026, 1, 31); // day 31, Jan
      final result = computeNextPaymentDate(31, today);
      // today.day == paymentDay → same month
      expect(result, DateTime(2026, 1, 31));
    });

    test('paymentDay > days in next month → clamped to last day of next month', () {
      // paymentDay=31, today is Feb 5, next occurrence is Feb 28 (2026 is not a leap year)
      final today = DateTime(2026, 2, 5);
      final result = computeNextPaymentDate(31, today);
      // 31 > 5 → try Feb 31 → clamp to Feb 28
      expect(result, DateTime(2026, 2, 28));
    });

    test('paymentDay=1 → standard behavior across month boundary', () {
      final today = DateTime(2026, 4, 5);
      final result = computeNextPaymentDate(1, today);
      // 1 < 5 → next month
      expect(result, DateTime(2026, 5, 1));
    });

    test('December + next month → January of next year', () {
      final today = DateTime(2026, 12, 20);
      final result = computeNextPaymentDate(15, today);
      // 15 < 20 → next month → January 2027
      expect(result, DateTime(2027, 1, 15));
    });
  });

  // ---------------------------------------------------------------------------
  // TemplateDetailNotifier — amount validation (test-first)
  // These tests will be activated in T016 (Phase 5 / US3).
  // ---------------------------------------------------------------------------
  group('TemplateDetailNotifier — amount validation', () {
    late TemplateDetailNotifier notifier;

    setUp(() {
      notifier = TemplateDetailNotifier();
    });

    test('empty string → amountError set, isEditingAmount still true', () {
      notifier.startEditing(1000); // €10.00
      notifier.setAmountText('');
      notifier.confirmEditForTest();
      expect(notifier.state.amountError, isNotNull);
      expect(notifier.state.isEditingAmount, isTrue);
    });

    test('"0" → amountError set', () {
      notifier.startEditing(1000);
      notifier.setAmountText('0');
      notifier.confirmEditForTest();
      expect(notifier.state.amountError, isNotNull);
    });

    test('negative value → amountError set', () {
      notifier.startEditing(1000);
      notifier.setAmountText('-5');
      notifier.confirmEditForTest();
      expect(notifier.state.amountError, isNotNull);
    });

    test('non-numeric → amountError set', () {
      notifier.startEditing(1000);
      notifier.setAmountText('abc');
      notifier.confirmEditForTest();
      expect(notifier.state.amountError, isNotNull);
    });

    test('valid positive decimal → no amountError', () {
      notifier.startEditing(1000);
      notifier.setAmountText('9.99');
      notifier.confirmEditForTest();
      expect(notifier.state.amountError, isNull);
    });

    test('cancelEdit → resets editing state', () {
      notifier.startEditing(1000);
      notifier.setAmountText('bad');
      notifier.cancelEdit();
      expect(notifier.state.isEditingAmount, isFalse);
      expect(notifier.state.amountText, '');
      expect(notifier.state.amountError, isNull);
    });
  });
}
