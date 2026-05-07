import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/src/auth/lockout_policy.dart';

void main() {
  group('LockoutPolicy.lockoutFor', () {
    test('0 attempts → null', () {
      expect(LockoutPolicy.lockoutFor(0), isNull);
    });

    test('1 attempt → null', () {
      expect(LockoutPolicy.lockoutFor(1), isNull);
    });

    test('2 attempts → null', () {
      expect(LockoutPolicy.lockoutFor(2), isNull);
    });

    test('3 attempts → 1 minute (block 1)', () {
      expect(LockoutPolicy.lockoutFor(3), const Duration(minutes: 1));
    });

    test('4 attempts → null', () {
      expect(LockoutPolicy.lockoutFor(4), isNull);
    });

    test('5 attempts → null', () {
      expect(LockoutPolicy.lockoutFor(5), isNull);
    });

    test('6 attempts → 5 minutes (block 2)', () {
      expect(LockoutPolicy.lockoutFor(6), const Duration(minutes: 5));
    });

    test('9 attempts → 25 minutes (block 3)', () {
      expect(LockoutPolicy.lockoutFor(9), const Duration(minutes: 25));
    });

    test('12 attempts → 125 minutes (block 4)', () {
      expect(LockoutPolicy.lockoutFor(12), const Duration(minutes: 125));
    });

    test('15 attempts → 625 minutes (block 5)', () {
      expect(LockoutPolicy.lockoutFor(15), const Duration(minutes: 625));
    });
  });
}
