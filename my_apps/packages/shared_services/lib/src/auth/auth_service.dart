import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auth_envelope.dart';
import 'auth_state.dart';
import 'encryption_service.dart';
import 'key_derivation_service.dart';
import 'lockout_policy.dart';
import 'lockout_state.dart';
import 'secure_storage_service.dart';

const _kEnvelopeKey = 'auth.envelope';
const _kLockoutKey = 'auth.lockout';

class AuthService {
  AuthService({
    required SecureStorageService storage,
    required KeyDerivationService keyDerivation,
    required EncryptionService encryption,
    required Future<bool> Function() preExistingDbExists,
    Future<String> Function()? dbFilePath,
    Random? random,
    DateTime Function()? clock,
  })  : _storage = storage,
        _kds = keyDerivation,
        _enc = encryption,
        _preExistingDbExists = preExistingDbExists,
        _dbFilePath = dbFilePath ?? _defaultDbFilePath,
        _random = random ?? Random.secure(),
        _clock = clock ?? (() => DateTime.now().toUtc());

  final SecureStorageService _storage;
  final KeyDerivationService _kds;
  final EncryptionService _enc;
  final Future<bool> Function() _preExistingDbExists;
  final Future<String> Function() _dbFilePath;
  final Random _random;
  final DateTime Function() _clock;

  static Future<String> _defaultDbFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'sfinance.sqlite');
  }

  /// Inspects storage to determine the initial auth state.
  Future<AuthState> bootstrap() async {
    if (!await _storage.isAvailable()) {
      return const AuthStateFatalError(
          'Secure storage is unavailable on this device.');
    }

    final envelopeRaw = await _storage.read(_kEnvelopeKey);

    if (envelopeRaw == null) {
      if (await _preExistingDbExists()) {
        final path = await _dbFilePath();
        return AuthStateFatalError(
          'A pre-existing unencrypted database was found at:\n$path\n\n'
          'Delete this file manually and relaunch the app.',
        );
      }
      return const AuthStateNeedsSetup();
    }

    try {
      AuthEnvelope.fromJson(envelopeRaw); // validates format
    } on FormatException catch (e) {
      return AuthStateFatalError('Authentication data is corrupted: $e');
    }

    final lockout = await _readLockout();
    if (lockout.isLockedOut(_clock())) {
      return AuthStateLockedOut(lockout.expiresAt!);
    }

    return const AuthStateNeedsAuth();
  }

  /// First-launch flow: generate master key + salt, wrap with PIN-derived key,
  /// persist envelope, return master key.
  Future<Uint8List> setupPin(String pin) async {
    final existing = await _storage.read(_kEnvelopeKey);
    if (existing != null) {
      throw StateError('setupPin called but an envelope already exists');
    }

    final masterKey = _randomBytes(32);
    final salt = _randomBytes(16);
    final wrappingKey = await _kds.deriveKey(pin: pin, salt: salt);
    final result = await _enc.encryptMasterKey(
      masterKey: masterKey,
      wrappingKey: wrappingKey,
    );

    final envelope = AuthEnvelope(
      salt: salt,
      encryptedMasterKey: result.cipherText,
      gcmNonce: result.nonce,
      gcmTag: result.tag,
    );
    await _storage.write(_kEnvelopeKey, envelope.toJson());
    await _storage.write(_kLockoutKey, LockoutState.clean.toJson());
    return masterKey;
  }

  /// Subsequent-launch flow: verify PIN and return master key.
  Future<Uint8List> verifyPin(String pin) async {
    final lockout = await _readLockout();
    if (lockout.isLockedOut(_clock())) {
      throw LockedOutException(lockout.expiresAt!);
    }

    final envelopeRaw = await _storage.read(_kEnvelopeKey);
    if (envelopeRaw == null) {
      throw StateError('No envelope present — call bootstrap first');
    }
    final envelope = AuthEnvelope.fromJson(envelopeRaw);
    final wrappingKey = await _kds.deriveKey(pin: pin, salt: envelope.salt);

    try {
      final masterKey = await _enc.decryptMasterKey(
        cipherText: envelope.encryptedMasterKey,
        nonce: envelope.gcmNonce,
        tag: envelope.gcmTag,
        wrappingKey: wrappingKey,
      );
      await _storage.write(_kLockoutKey, LockoutState.clean.toJson());
      return masterKey;
    } on WrongKeyException {
      final newFailures = lockout.failedAttempts + 1;
      final lockoutDuration = LockoutPolicy.lockoutFor(newFailures);
      final newState = LockoutState(
        failedAttempts: newFailures,
        expiresAt:
            lockoutDuration == null ? null : _clock().add(lockoutDuration),
      );
      await _storage.write(_kLockoutKey, newState.toJson());
      throw WrongPinException(
        failedAttempts: newFailures,
        newLockout: lockoutDuration,
      );
    }
  }

  /// Returns current lockout state without performing any auth work.
  Future<LockoutState> currentLockout() => _readLockout();

  Future<LockoutState> _readLockout() async {
    final raw = await _storage.read(_kLockoutKey);
    if (raw == null) return LockoutState.clean;
    try {
      return LockoutState.fromJson(raw);
    } on FormatException {
      return LockoutState.clean;
    }
  }

  Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));
}
