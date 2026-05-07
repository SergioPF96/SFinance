import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/src/auth/key_derivation_service.dart';

void main() {
  late KeyDerivationService kds;

  setUp(() {
    kds = Pbkdf2KeyDerivationService();
  });

  group('KeyDerivationService', () {
    test('output length is exactly 32 bytes', () async {
      final salt = Uint8List(16);
      final key = await kds.deriveKey(pin: '1234', salt: salt);
      expect(key.length, 32);
    });

    test('same pin+salt produces the same output (determinism)', () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final key1 = await kds.deriveKey(pin: '1234', salt: salt);
      final key2 = await kds.deriveKey(pin: '1234', salt: salt);
      expect(key1, equals(key2));
    });

    test('different salt with same pin produces different output', () async {
      final salt1 = Uint8List.fromList(List.filled(16, 0));
      final salt2 = Uint8List.fromList(List.filled(16, 1));
      final key1 = await kds.deriveKey(pin: '1234', salt: salt1);
      final key2 = await kds.deriveKey(pin: '1234', salt: salt2);
      expect(key1, isNot(equals(key2)));
    });

    test('different pin with same salt produces different output', () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final key1 = await kds.deriveKey(pin: '1234', salt: salt);
      final key2 = await kds.deriveKey(pin: '9999', salt: salt);
      expect(key1, isNot(equals(key2)));
    });
  });
}
