import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/src/auth/auth_service.dart';
import 'package:shared_services/src/auth/auth_state.dart';
import 'package:shared_services/src/auth/key_derivation_service.dart';
import 'package:shared_services/src/auth/encryption_service.dart';
import 'package:shared_services/src/auth/lockout_state.dart';
import 'fakes/in_memory_secure_storage.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AuthService _makeService({
  InMemorySecureStorageService? storage,
  bool storageAvailable = true,
  bool preExistingDb = false,
  String fakeDbPath = '/fake/sfinance.sqlite',
  DateTime Function()? clock,
}) {
  final s = storage ?? InMemorySecureStorageService(available: storageAvailable);
  return AuthService(
    storage: s,
    keyDerivation: Pbkdf2KeyDerivationService(),
    encryption: AesGcmEncryptionService(),
    preExistingDbExists: () async => preExistingDb,
    dbFilePath: () async => fakeDbPath,
    clock: clock ?? () => DateTime.now().toUtc(),
  );
}

// ---------------------------------------------------------------------------
// Scenario 1: fresh install bootstrap → needsSetup; setupPin persists
//             envelope and returns 32-byte key; second bootstrap → needsAuth
// ---------------------------------------------------------------------------
void main() {
  group('Scenario 1 — fresh install', () {
    test('bootstrap() on empty storage returns needsSetup', () async {
      final svc = _makeService();
      final state = await svc.bootstrap();
      expect(state, isA<AuthStateNeedsSetup>());
    });

    test('setupPin stores 4-field envelope and returns 32-byte key', () async {
      final storage = InMemorySecureStorageService();
      final svc = _makeService(storage: storage);
      await svc.bootstrap();
      final key = await svc.setupPin('1234');
      expect(key.length, 32);

      final raw = await storage.read('auth.envelope');
      expect(raw, isNotNull);
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map.containsKey('salt'), isTrue);
      expect(map.containsKey('encryptedMasterKey'), isTrue);
      expect(map.containsKey('gcmNonce'), isTrue);
      expect(map.containsKey('gcmTag'), isTrue);
    });

    test('second bootstrap() on same storage returns needsAuth', () async {
      final storage = InMemorySecureStorageService();
      final svc = _makeService(storage: storage);
      await svc.bootstrap();
      await svc.setupPin('1234');

      final svc2 = _makeService(storage: storage);
      final state = await svc2.bootstrap();
      expect(state, isA<AuthStateNeedsAuth>());
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 2: correct PIN returns same key
  // -------------------------------------------------------------------------
  group('Scenario 2 — correct PIN', () {
    test('verifyPin with correct PIN returns the same key as setupPin',
        () async {
      final storage = InMemorySecureStorageService();
      final svc = _makeService(storage: storage);
      await svc.bootstrap();
      final setupKey = await svc.setupPin('1234');

      final svc2 = _makeService(storage: storage);
      await svc2.bootstrap();
      final verifyKey = await svc2.verifyPin('1234');
      expect(verifyKey, equals(setupKey));
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 3: wrong PIN (no lockout yet)
  // -------------------------------------------------------------------------
  group('Scenario 3 — wrong PIN', () {
    test('verifyPin with wrong PIN throws WrongPinException(failedAttempts=1)',
        () async {
      final storage = InMemorySecureStorageService();
      final svc = _makeService(storage: storage);
      await svc.bootstrap();
      await svc.setupPin('1234');

      final svc2 = _makeService(storage: storage);
      await svc2.bootstrap();
      expect(
        () => svc2.verifyPin('9999'),
        throwsA(
          isA<WrongPinException>()
              .having((e) => e.failedAttempts, 'failedAttempts', 1)
              .having((e) => e.newLockout, 'newLockout', isNull),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 6: 2 wrong PINs then correct → failedAttempts resets to 0
  // -------------------------------------------------------------------------
  group('Scenario 6 — counter reset on success', () {
    test('correct PIN after 2 failures resets failedAttempts to 0', () async {
      final storage = InMemorySecureStorageService();
      final svc = _makeService(storage: storage);
      await svc.bootstrap();
      await svc.setupPin('1234');

      final svc2 = _makeService(storage: storage);
      await svc2.bootstrap();
      await expectLater(() => svc2.verifyPin('0000'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc2.verifyPin('0001'), throwsA(isA<WrongPinException>()));
      await svc2.verifyPin('1234');

      final lockoutRaw = await storage.read('auth.lockout');
      if (lockoutRaw != null) {
        final ls = LockoutState.fromJson(lockoutRaw);
        expect(ls.failedAttempts, 0);
      }
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 4: lockout trigger after 3 consecutive wrong PINs
  // -------------------------------------------------------------------------
  group('Scenario 4 — lockout trigger', () {
    test('3rd wrong PIN triggers 1-minute lockout', () async {
      final storage = InMemorySecureStorageService();
      final svc = _makeService(storage: storage);
      await svc.bootstrap();
      await svc.setupPin('1234');

      final svc2 = _makeService(storage: storage);
      await svc2.bootstrap();
      await expectLater(() => svc2.verifyPin('0000'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc2.verifyPin('0001'), throwsA(isA<WrongPinException>()));
      WrongPinException? ex;
      try {
        await svc2.verifyPin('0002');
      } on WrongPinException catch (e) {
        ex = e;
      }
      expect(ex, isNotNull);
      expect(ex!.failedAttempts, 3);
      expect(ex.newLockout, const Duration(minutes: 1));
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 5: locked-out attempt is rejected without PBKDF2 work
  // -------------------------------------------------------------------------
  group('Scenario 5 — locked-out rejection', () {
    test('verifyPin during active lockout throws LockedOutException', () async {
      final storage = InMemorySecureStorageService();
      DateTime now = DateTime.utc(2026, 5, 5, 10, 0, 0);
      final svc = _makeService(storage: storage, clock: () => now);
      await svc.bootstrap();
      await svc.setupPin('1234');

      await expectLater(() => svc.verifyPin('0000'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc.verifyPin('0001'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc.verifyPin('0002'), throwsA(isA<WrongPinException>()));

      // Still within lockout window
      now = DateTime.utc(2026, 5, 5, 10, 0, 30);
      expect(
        () => svc.verifyPin('1234'),
        throwsA(isA<LockedOutException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 7: lockout persists across restart
  // -------------------------------------------------------------------------
  group('Scenario 7 — lockout persists across restart', () {
    test('fresh AuthService on same storage sees lockout state', () async {
      final storage = InMemorySecureStorageService();
      DateTime now = DateTime.utc(2026, 5, 5, 10, 0, 0);
      final svc = _makeService(storage: storage, clock: () => now);
      await svc.bootstrap();
      await svc.setupPin('1234');
      await expectLater(() => svc.verifyPin('0000'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc.verifyPin('0001'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc.verifyPin('0002'), throwsA(isA<WrongPinException>()));

      // Simulate app restart — same clock (still inside lockout)
      final svc2 = _makeService(storage: storage, clock: () => now);
      final state = await svc2.bootstrap();
      expect(state, isA<AuthStateLockedOut>());
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 8: block escalation (6 failures → 5 min, 9 → 25 min)
  // -------------------------------------------------------------------------
  group('Scenario 8 — block escalation', () {
    test('block 2: 6 total wrong PINs → 5-minute lockout', () async {
      final storage = InMemorySecureStorageService();
      DateTime now = DateTime.utc(2026, 5, 5, 10, 0, 0);
      final svc = _makeService(storage: storage, clock: () => now);
      await svc.bootstrap();
      await svc.setupPin('1234');

      // First 3 failures → 1-minute lockout
      for (int i = 0; i < 3; i++) {
        await expectLater(() => svc.verifyPin('0000'), throwsA(isA<WrongPinException>()));
      }

      // Advance past lockout
      now = DateTime.utc(2026, 5, 5, 10, 2, 0);

      // Next 3 failures → 5-minute lockout
      await expectLater(() => svc.verifyPin('0001'), throwsA(isA<WrongPinException>()));
      await expectLater(() => svc.verifyPin('0002'), throwsA(isA<WrongPinException>()));
      WrongPinException? ex;
      try {
        await svc.verifyPin('0003');
      } on WrongPinException catch (e) {
        ex = e;
      }
      expect(ex!.failedAttempts, 6);
      expect(ex.newLockout, const Duration(minutes: 5));
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 9: corrupt envelope → fatalError
  // -------------------------------------------------------------------------
  group('Scenario 9 — corrupt envelope', () {
    test('malformed envelope JSON → bootstrap returns fatalError', () async {
      final storage = InMemorySecureStorageService();
      await storage.write('auth.envelope', '{bad json}');
      final svc = _makeService(storage: storage);
      final state = await svc.bootstrap();
      expect(state, isA<AuthStateFatalError>());
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 10: pre-existing unencrypted DB → fatalError with path
  // -------------------------------------------------------------------------
  group('Scenario 10 — pre-existing unencrypted DB', () {
    test('bootstrap returns fatalError containing the DB file path', () async {
      final svc = _makeService(preExistingDb: true);
      final state = await svc.bootstrap();
      expect(state, isA<AuthStateFatalError>());
      final err = state as AuthStateFatalError;
      expect(err.reason, contains('sfinance.sqlite'));
    });
  });

  // -------------------------------------------------------------------------
  // Scenario 11: secure storage unavailable → fatalError
  // -------------------------------------------------------------------------
  group('Scenario 11 — no secure storage', () {
    test('bootstrap returns fatalError when storage is unavailable', () async {
      final svc = _makeService(storageAvailable: false);
      final state = await svc.bootstrap();
      expect(state, isA<AuthStateFatalError>());
    });
  });
}
