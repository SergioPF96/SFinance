import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/src/auth/auth_envelope.dart';

void main() {
  group('AuthEnvelope JSON round-trip', () {
    late AuthEnvelope envelope;

    setUp(() {
      envelope = AuthEnvelope(
        salt: Uint8List.fromList(List.generate(16, (i) => i)),
        encryptedMasterKey: Uint8List.fromList(List.generate(32, (i) => i + 16)),
        gcmNonce: Uint8List.fromList(List.generate(12, (i) => i + 48)),
        gcmTag: Uint8List.fromList(List.generate(16, (i) => i + 60)),
      );
    });

    test('fromJson(toJson()) reproduces identical JSON', () {
      final json = envelope.toJson();
      final restored = AuthEnvelope.fromJson(json);
      expect(restored.toJson(), equals(json));
    });

    test('salt field is preserved', () {
      final restored = AuthEnvelope.fromJson(envelope.toJson());
      expect(restored.salt, equals(envelope.salt));
    });

    test('encryptedMasterKey field is preserved', () {
      final restored = AuthEnvelope.fromJson(envelope.toJson());
      expect(restored.encryptedMasterKey, equals(envelope.encryptedMasterKey));
    });

    test('gcmNonce field is preserved', () {
      final restored = AuthEnvelope.fromJson(envelope.toJson());
      expect(restored.gcmNonce, equals(envelope.gcmNonce));
    });

    test('gcmTag field is preserved', () {
      final restored = AuthEnvelope.fromJson(envelope.toJson());
      expect(restored.gcmTag, equals(envelope.gcmTag));
    });
  });

  group('AuthEnvelope.fromJson error handling', () {
    final goodSalt = _hex(16);
    final goodEmk = _b64(32);
    final goodNonce = _b64(12);
    final goodTag = _b64(16);

    test('missing salt → FormatException', () {
      expect(
        () => AuthEnvelope.fromJson(
            '{"encryptedMasterKey":"$goodEmk","gcmNonce":"$goodNonce","gcmTag":"$goodTag"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing encryptedMasterKey → FormatException', () {
      expect(
        () => AuthEnvelope.fromJson(
            '{"salt":"$goodSalt","gcmNonce":"$goodNonce","gcmTag":"$goodTag"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing gcmNonce → FormatException', () {
      expect(
        () => AuthEnvelope.fromJson(
            '{"salt":"$goodSalt","encryptedMasterKey":"$goodEmk","gcmTag":"$goodTag"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing gcmTag → FormatException', () {
      expect(
        () => AuthEnvelope.fromJson(
            '{"salt":"$goodSalt","encryptedMasterKey":"$goodEmk","gcmNonce":"$goodNonce"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('wrong salt length (not 16 bytes) → FormatException', () {
      expect(
        () => AuthEnvelope.fromJson(
            '{"salt":"aa","encryptedMasterKey":"$goodEmk","gcmNonce":"$goodNonce","gcmTag":"$goodTag"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('malformed JSON → FormatException', () {
      expect(
        () => AuthEnvelope.fromJson('{not valid json'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

String _hex(int byteCount) =>
    Uint8List(byteCount).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

String _b64(int byteCount) => base64Encode(Uint8List(byteCount));
