import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/src/auth/encryption_service.dart';

void main() {
  late EncryptionService svc;
  late Uint8List masterKey;
  late Uint8List wrappingKey;

  setUp(() {
    svc = AesGcmEncryptionService();
    masterKey = Uint8List.fromList(List.generate(32, (i) => i));
    wrappingKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));
  });

  group('EncryptionService', () {
    test('encrypt → decrypt round-trip yields original master key', () async {
      final result = await svc.encryptMasterKey(
        masterKey: masterKey,
        wrappingKey: wrappingKey,
      );
      final recovered = await svc.decryptMasterKey(
        cipherText: result.cipherText,
        nonce: result.nonce,
        tag: result.tag,
        wrappingKey: wrappingKey,
      );
      expect(recovered, equals(masterKey));
    });

    test('decrypt with wrong wrapping key throws WrongKeyException', () async {
      final result = await svc.encryptMasterKey(
        masterKey: masterKey,
        wrappingKey: wrappingKey,
      );
      final wrongKey = Uint8List.fromList(List.filled(32, 0xAB));
      expect(
        () => svc.decryptMasterKey(
          cipherText: result.cipherText,
          nonce: result.nonce,
          tag: result.tag,
          wrappingKey: wrongKey,
        ),
        throwsA(isA<WrongKeyException>()),
      );
    });

    test('decrypt with tampered ciphertext throws WrongKeyException', () async {
      final result = await svc.encryptMasterKey(
        masterKey: masterKey,
        wrappingKey: wrappingKey,
      );
      final tampered = Uint8List.fromList(result.cipherText)
        ..[0] ^= 0xFF;
      expect(
        () => svc.decryptMasterKey(
          cipherText: tampered,
          nonce: result.nonce,
          tag: result.tag,
          wrappingKey: wrappingKey,
        ),
        throwsA(isA<WrongKeyException>()),
      );
    });

    test('each encryptMasterKey call produces a distinct nonce', () async {
      final r1 = await svc.encryptMasterKey(
        masterKey: masterKey,
        wrappingKey: wrappingKey,
      );
      final r2 = await svc.encryptMasterKey(
        masterKey: masterKey,
        wrappingKey: wrappingKey,
      );
      expect(r1.nonce, isNot(equals(r2.nonce)));
    });
  });
}
