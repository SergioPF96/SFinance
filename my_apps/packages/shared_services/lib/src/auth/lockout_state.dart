import 'dart:convert';

class LockoutState {
  const LockoutState({required this.failedAttempts, required this.expiresAt});

  final int failedAttempts;
  final DateTime? expiresAt;

  static const LockoutState clean =
      LockoutState(failedAttempts: 0, expiresAt: null);

  /// Returns true iff a lockout is currently active (now is before expiresAt).
  bool isLockedOut(DateTime now) =>
      expiresAt != null && now.isBefore(expiresAt!);

  /// The current block number: floor(failedAttempts / 3).
  int get currentBlock => failedAttempts ~/ 3;

  String toJson() => jsonEncode({
        'failedAttempts': failedAttempts,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
      });

  factory LockoutState.fromJson(String source) {
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(source) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('LockoutState: invalid JSON — $e');
    }
    if (!map.containsKey('failedAttempts')) {
      throw const FormatException(
          'LockoutState: missing required field "failedAttempts"');
    }
    final failedAttempts = map['failedAttempts'] as int;
    final expiresAtRaw = map['expiresAt'];
    final expiresAt = expiresAtRaw == null
        ? null
        : DateTime.parse(expiresAtRaw as String).toUtc();
    return LockoutState(failedAttempts: failedAttempts, expiresAt: expiresAt);
  }
}
