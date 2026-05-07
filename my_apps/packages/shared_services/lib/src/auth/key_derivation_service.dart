import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

abstract interface class KeyDerivationService {
  /// PBKDF2-SHA256 iteration count. Constitution Principle V mandates ≥ 500_000.
  static const int iterations = 500000;

  /// Derives a 256-bit key from [pin] and [salt] using PBKDF2-SHA256.
  Future<Uint8List> deriveKey({required String pin, required Uint8List salt});
}

class Pbkdf2KeyDerivationService implements KeyDerivationService {
  @override
  Future<Uint8List> deriveKey({
    required String pin,
    required Uint8List salt,
  }) {
    return compute(_derive, _Pbkdf2Args(pin: pin, salt: salt));
  }
}

class _Pbkdf2Args {
  const _Pbkdf2Args({required this.pin, required this.salt});
  final String pin;
  final Uint8List salt;
}

Future<Uint8List> _derive(_Pbkdf2Args args) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: KeyDerivationService.iterations,
    bits: 256,
  );
  final secretKey = await pbkdf2.deriveKeyFromPassword(
    password: args.pin,
    nonce: args.salt,
  );
  final bytes = await secretKey.extractBytes();
  return Uint8List.fromList(bytes);
}
