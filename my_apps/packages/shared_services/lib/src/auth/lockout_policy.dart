import 'dart:math';

class LockoutPolicy {
  static const int blockSize = 3;

  /// Returns the lockout duration for [failedAttempts] if it lands on a block
  /// boundary (multiple of 3). Returns null otherwise.
  ///
  /// Block N → 5^(N-1) minutes.
  static Duration? lockoutFor(int failedAttempts) {
    if (failedAttempts <= 0 || failedAttempts % blockSize != 0) return null;
    final block = failedAttempts ~/ blockSize;
    final minutes = pow(5, block - 1).toInt();
    return Duration(minutes: minutes);
  }
}
