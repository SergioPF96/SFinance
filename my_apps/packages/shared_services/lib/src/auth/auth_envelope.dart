import 'dart:convert';
import 'dart:typed_data';

class AuthEnvelope {
  const AuthEnvelope({
    required this.salt,
    required this.encryptedMasterKey,
    required this.gcmNonce,
    required this.gcmTag,
  });

  final Uint8List salt;             // 16 bytes — hex encoded
  final Uint8List encryptedMasterKey; // 32 bytes — base64 encoded
  final Uint8List gcmNonce;         // 12 bytes — base64 encoded
  final Uint8List gcmTag;           // 16 bytes — base64 encoded

  String toJson() => jsonEncode({
        'salt': _toHex(salt),
        'encryptedMasterKey': base64Encode(encryptedMasterKey),
        'gcmNonce': base64Encode(gcmNonce),
        'gcmTag': base64Encode(gcmTag),
      });

  factory AuthEnvelope.fromJson(String source) {
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(source) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('AuthEnvelope: invalid JSON — $e');
    }

    _requireKey(map, 'salt');
    _requireKey(map, 'encryptedMasterKey');
    _requireKey(map, 'gcmNonce');
    _requireKey(map, 'gcmTag');

    final salt = _fromHex(map['salt'] as String, expectedBytes: 16, field: 'salt');
    final emk = _fromB64(map['encryptedMasterKey'] as String,
        expectedBytes: 32, field: 'encryptedMasterKey');
    final nonce =
        _fromB64(map['gcmNonce'] as String, expectedBytes: 12, field: 'gcmNonce');
    final tag =
        _fromB64(map['gcmTag'] as String, expectedBytes: 16, field: 'gcmTag');

    return AuthEnvelope(
      salt: salt,
      encryptedMasterKey: emk,
      gcmNonce: nonce,
      gcmTag: tag,
    );
  }
}

void _requireKey(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) {
    throw FormatException('AuthEnvelope: missing required field "$key"');
  }
}

String _toHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List _fromHex(String hex, {required int expectedBytes, required String field}) {
  if (hex.length != expectedBytes * 2) {
    throw FormatException(
        'AuthEnvelope: field "$field" has wrong length (expected ${expectedBytes * 2} hex chars, got ${hex.length})');
  }
  try {
    return Uint8List.fromList(
      List.generate(expectedBytes, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  } catch (e) {
    throw FormatException('AuthEnvelope: field "$field" contains invalid hex — $e');
  }
}

Uint8List _fromB64(String b64, {required int expectedBytes, required String field}) {
  final Uint8List bytes;
  try {
    bytes = base64Decode(b64);
  } catch (e) {
    throw FormatException('AuthEnvelope: field "$field" contains invalid base64 — $e');
  }
  if (bytes.length != expectedBytes) {
    throw FormatException(
        'AuthEnvelope: field "$field" has wrong byte length (expected $expectedBytes, got ${bytes.length})');
  }
  return bytes;
}
