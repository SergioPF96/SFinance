import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class EncryptionResult {
  const EncryptionResult({
    required this.cipherText,
    required this.nonce,
    required this.tag,
  });
  final Uint8List cipherText;
  final Uint8List nonce;
  final Uint8List tag;
}

class WrongKeyException implements Exception {
  const WrongKeyException();
}

abstract interface class EncryptionService {
  Future<EncryptionResult> encryptMasterKey({
    required Uint8List masterKey,
    required Uint8List wrappingKey,
  });

  Future<Uint8List> decryptMasterKey({
    required Uint8List cipherText,
    required Uint8List nonce,
    required Uint8List tag,
    required Uint8List wrappingKey,
  });
}

class AesGcmEncryptionService implements EncryptionService {
  static final _aesGcm = AesGcm.with256bits();

  @override
  Future<EncryptionResult> encryptMasterKey({
    required Uint8List masterKey,
    required Uint8List wrappingKey,
  }) async {
    final secretKey = SecretKeyData(wrappingKey);
    final box = await _aesGcm.encrypt(masterKey, secretKey: secretKey);
    return EncryptionResult(
      cipherText: Uint8List.fromList(box.cipherText),
      nonce: Uint8List.fromList(box.nonce),
      tag: Uint8List.fromList(box.mac.bytes),
    );
  }

  @override
  Future<Uint8List> decryptMasterKey({
    required Uint8List cipherText,
    required Uint8List nonce,
    required Uint8List tag,
    required Uint8List wrappingKey,
  }) async {
    final secretKey = SecretKeyData(wrappingKey);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(tag));
    try {
      final clearText = await _aesGcm.decrypt(box, secretKey: secretKey);
      return Uint8List.fromList(clearText);
    } catch (_) {
      throw const WrongKeyException();
    }
  }
}
