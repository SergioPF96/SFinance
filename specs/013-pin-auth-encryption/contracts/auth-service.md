# Contract: AuthService and Supporting Services

**Feature**: 013-pin-auth-encryption
**Package**: `shared_services` — `lib/src/auth/`

This document defines the public Dart interface of the four services that
implement the PIN authentication and encryption flow. These contracts are
the input to the test-first cycle (Constitution Principle IV) and the
boundary between `shared_services` and the app.

## File layout

```
my_apps/packages/shared_services/lib/src/auth/
├── auth_service.dart                # Top-level orchestrator
├── auth_state.dart                  # Sealed AuthState class
├── auth_envelope.dart               # Envelope value type
├── lockout_state.dart               # LockoutState value type
├── lockout_policy.dart              # Pure exponential-backoff math
├── key_derivation_service.dart      # PBKDF2-SHA256
├── encryption_service.dart          # AES-256-GCM
└── secure_storage_service.dart      # flutter_secure_storage wrapper
```

All services are pure Dart and constructor-injectable. None of them depend
on Flutter widgets or Riverpod (Riverpod providers wrap them in the app
layer).

---

## 1. KeyDerivationService

```dart
abstract interface class KeyDerivationService {
  /// Derives a 256-bit key from [pin] and [salt] using PBKDF2-SHA256
  /// with [iterations] iterations.
  ///
  /// CALLERS MUST run this through `compute()` — it takes ~1–2 s.
  /// Throws [ArgumentError] if iterations < 500_000.
  Future<Uint8List> deriveKey({
    required String pin,
    required Uint8List salt,
    required int iterations,
  });
}
```

**Implementation**: `Pbkdf2KeyDerivationService` using
`cryptography ^2.9.0`.

**Test contract**:
- Same `(pin, salt, iterations)` triple → same 32-byte output (determinism).
- Different salt with same pin/iterations → different output.
- Iterations < 500_000 throws `ArgumentError`.

---

## 2. EncryptionService

```dart
class EncryptionResult {
  final Uint8List cipherText;   // 32 bytes for the master key
  final Uint8List nonce;        // 12 bytes
  final Uint8List tag;          // 16 bytes
}

abstract interface class EncryptionService {
  /// Wraps [masterKey] (32 bytes) with [wrappingKey] (32 bytes) using
  /// AES-256-GCM. Generates a fresh 12-byte random nonce.
  Future<EncryptionResult> encryptMasterKey({
    required Uint8List masterKey,
    required Uint8List wrappingKey,
  });

  /// Unwraps a previously wrapped master key. Throws [WrongKeyException]
  /// if the GCM tag does not verify (wrong PIN).
  Future<Uint8List> decryptMasterKey({
    required Uint8List cipherText,
    required Uint8List nonce,
    required Uint8List tag,
    required Uint8List wrappingKey,
  });
}

class WrongKeyException implements Exception {
  const WrongKeyException();
}
```

**Implementation**: `AesGcmEncryptionService` using `cryptography ^2.9.0`.

**Test contract**:
- `encrypt → decrypt` round-trip yields the original master key bytes.
- Decrypt with a wrapping key derived from a different PIN throws
  `WrongKeyException` (GCM tag mismatch).
- Decrypt with a tampered cipher text byte throws `WrongKeyException`.
- `encryptMasterKey` produces a fresh nonce on every call (no
  determinism).

---

## 3. SecureStorageService

```dart
abstract interface class SecureStorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);

  /// Returns true if the platform's secure storage is available
  /// and writable. Used at startup to surface FR-018 errors early.
  Future<bool> isAvailable();
}
```

**Implementation**: `FlutterSecureStorageService` wrapping
`flutter_secure_storage ^9.0.0`.

**Test contract**:
- Tests use `InMemorySecureStorageService` (a `Map<String, String>`-backed
  fake). The real implementation is integration-tested only.
- `delete` of a missing key is a no-op (does not throw).
- `read` of a missing key returns `null`.

---

## 4. LockoutPolicy (pure function)

```dart
class LockoutPolicy {
  static const int blockSize = 3;

  /// Returns the lockout duration to apply when [failedAttempts] reaches
  /// a multiple of 3. Returns `null` if [failedAttempts] is not on a
  /// block boundary. Block N → 5^(N-1) minutes.
  static Duration? lockoutFor(int failedAttempts);
}
```

**Test contract** (every assertion exact):
- `lockoutFor(0)` → `null`
- `lockoutFor(1)` → `null`
- `lockoutFor(2)` → `null`
- `lockoutFor(3)` → `Duration(minutes: 1)`
- `lockoutFor(4)` → `null`
- `lockoutFor(5)` → `null`
- `lockoutFor(6)` → `Duration(minutes: 5)`
- `lockoutFor(9)` → `Duration(minutes: 25)`
- `lockoutFor(12)` → `Duration(minutes: 125)`
- `lockoutFor(15)` → `Duration(minutes: 625)`

This is the pure mathematical function tested in isolation; `AuthService`
delegates to it.

---

## 5. AuthService

The orchestrator. The app interacts with this and nothing else.

```dart
class AuthService {
  AuthService({
    required SecureStorageService storage,
    required KeyDerivationService keyDerivation,
    required EncryptionService encryption,
    Random? random,
    DateTime Function() clock = _systemClock,
  });

  /// Inspect storage to determine the initial AuthState. Called once at
  /// startup. Returns one of: needsSetup, needsAuth, lockedOut, fatalError.
  Future<AuthState> bootstrap();

  /// First-launch flow: generate master key + salt, wrap with PIN-derived
  /// key, persist envelope, return master key.
  ///
  /// Pre-condition: bootstrap() returned needsSetup.
  /// Throws [StateError] if an envelope already exists.
  Future<Uint8List> setupPin(String pin);

  /// Subsequent-launch flow: derive wrapping key from PIN, attempt to
  /// decrypt master key. Updates lockout counters on the way.
  ///
  /// Pre-condition: bootstrap() returned needsAuth (NOT lockedOut).
  /// Throws [LockedOutException] if a lockout is active when called.
  /// Returns the master key on success; throws [WrongPinException] on
  /// wrong PIN (after incrementing the failure counter).
  Future<Uint8List> verifyPin(String pin);

  /// Returns current lockout state without performing any work.
  Future<LockoutState> currentLockout();
}

class WrongPinException implements Exception {
  final int failedAttempts;
  final Duration? newLockout;   // non-null if this failure triggered a lockout
}

class LockedOutException implements Exception {
  final DateTime expiresAt;
}
```

**Test contract** (key scenarios):

1. *Fresh install*: `bootstrap()` → `needsSetup`. After `setupPin('1234')`:
   - Envelope persisted with all 6 fields.
   - Returned key is 32 bytes.
   - `bootstrap()` on the same storage → `needsAuth`.
2. *Correct PIN*: `setupPin('1234')` then `verifyPin('1234')` returns the
   same 32 bytes.
3. *Wrong PIN*: `verifyPin('9999')` throws `WrongPinException` with
   `failedAttempts=1`, `newLockout=null`.
4. *Lockout trigger*: 3 consecutive wrong PINs → 3rd throws
   `WrongPinException` with `failedAttempts=3`,
   `newLockout=Duration(minutes:1)`.
5. *Locked out*: 4th attempt during lockout → `LockedOutException` (no
   PBKDF2 work performed).
6. *Counter reset*: 2 wrong PINs, then correct PIN → `failedAttempts` in
   storage = 0.
7. *Lockout persists*: trigger lockout, instantiate a fresh `AuthService`
   with the same storage, call `bootstrap()` → `lockedOut`.
8. *Block escalation*: trigger lockouts in sequence. After 6 total
   failures → 5-min lockout. After 9 → 25-min. (Use injected fake clock
   to fast-forward.)
9. *Corrupt envelope*: storage has only `salt` but no `encryptedMasterKey`
   → `bootstrap()` returns `fatalError`.
10. *No secure storage*: `storage.isAvailable()` returns false →
    `bootstrap()` returns `fatalError`.

---

## 6. AppDatabase (modified existing contract)

```dart
class AppDatabase extends _$AppDatabase {
  /// Opens the database with [masterKey] (32 bytes) as the SQLCipher
  /// passphrase. Does NOT generate a key — caller is responsible for
  /// passing the recovered master key from AuthService.
  AppDatabase(Uint8List masterKey) : super(_openConnection(masterKey));

  /// Test constructor — accepts a pre-built executor (in-memory etc.).
  AppDatabase.forTesting(super.executor);

  // schemaVersion and migration unchanged.
}
```

**Breaking change note**: Existing default constructor `AppDatabase()`
(no parameters) is removed. All call sites must be updated to pass the
master key. Documented in the plan's Complexity Tracking table.

---

## 7. Riverpod provider contract (in `apps/sfinance/lib/providers/`)

```dart
final authServiceProvider = Provider<AuthService>((ref) { ... });

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final masterKeyProvider = Provider<Uint8List>((ref) {
  // Throws if read while authProvider is not in `authenticated` state.
  // This is a deliberate fail-fast: any DAO that reads it before auth is a bug.
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final key = ref.watch(masterKeyProvider);
  final db = AppDatabase(key);
  ref.onDispose(db.close);
  return db;
});
```

`AuthNotifier` is the only place mutating `AuthState`. UI calls
`ref.read(authProvider.notifier).submitPin(pin)`; the notifier in turn
invokes `AuthService.verifyPin` and emits state transitions
(`needsAuth → verifying → authenticated|needsAuth(error)|lockedOut`).
