import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/src/auth/lockout_state.dart';

void main() {
  group('LockoutState JSON round-trip', () {
    test('round-trip with non-null expiresAt', () {
      final expiry = DateTime.utc(2026, 5, 10, 12, 0, 0);
      final state = LockoutState(failedAttempts: 3, expiresAt: expiry);
      final restored = LockoutState.fromJson(state.toJson());
      expect(restored.failedAttempts, 3);
      expect(restored.expiresAt, expiry);
    });

    test('round-trip with null expiresAt', () {
      const state = LockoutState(failedAttempts: 1, expiresAt: null);
      final restored = LockoutState.fromJson(state.toJson());
      expect(restored.failedAttempts, 1);
      expect(restored.expiresAt, isNull);
    });

    test('clean constant round-trips cleanly', () {
      final restored = LockoutState.fromJson(LockoutState.clean.toJson());
      expect(restored.failedAttempts, 0);
      expect(restored.expiresAt, isNull);
    });

    test('missing failedAttempts field throws FormatException', () {
      expect(
        () => LockoutState.fromJson('{"expiresAt":null}'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LockoutState.isLockedOut', () {
    test('returns false when expiresAt is null', () {
      const state = LockoutState(failedAttempts: 2, expiresAt: null);
      final now = DateTime.utc(2026, 5, 5, 10, 0, 0);
      expect(state.isLockedOut(now), isFalse);
    });

    test('returns true when now is before expiresAt', () {
      final expiry = DateTime.utc(2026, 5, 5, 10, 5, 0);
      final state = LockoutState(failedAttempts: 3, expiresAt: expiry);
      final now = DateTime.utc(2026, 5, 5, 10, 0, 0);
      expect(state.isLockedOut(now), isTrue);
    });

    test('returns false when now equals expiresAt', () {
      final expiry = DateTime.utc(2026, 5, 5, 10, 0, 0);
      final state = LockoutState(failedAttempts: 3, expiresAt: expiry);
      expect(state.isLockedOut(expiry), isFalse);
    });

    test('returns false when now is after expiresAt', () {
      final expiry = DateTime.utc(2026, 5, 5, 9, 0, 0);
      final state = LockoutState(failedAttempts: 3, expiresAt: expiry);
      final now = DateTime.utc(2026, 5, 5, 10, 0, 0);
      expect(state.isLockedOut(now), isFalse);
    });
  });

  group('LockoutState.currentBlock', () {
    test('0 attempts → block 0', () {
      expect(LockoutState.clean.currentBlock, 0);
    });

    test('1 attempt → block 0', () {
      expect(
        const LockoutState(failedAttempts: 1, expiresAt: null).currentBlock,
        0,
      );
    });

    test('3 attempts → block 1', () {
      expect(
        const LockoutState(failedAttempts: 3, expiresAt: null).currentBlock,
        1,
      );
    });

    test('6 attempts → block 2', () {
      expect(
        const LockoutState(failedAttempts: 6, expiresAt: null).currentBlock,
        2,
      );
    });
  });
}
