import 'dart:typed_data';

sealed class AuthState {
  const AuthState();
}

final class AuthStateBootstrapping extends AuthState {
  const AuthStateBootstrapping();
}

final class AuthStateNeedsSetup extends AuthState {
  const AuthStateNeedsSetup();
}

final class AuthStateNeedsAuth extends AuthState {
  const AuthStateNeedsAuth({this.error});
  final WrongPinException? error;
}

final class AuthStateVerifying extends AuthState {
  const AuthStateVerifying();
}

final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated(this.masterKey);
  final Uint8List masterKey;
}

final class AuthStateLockedOut extends AuthState {
  const AuthStateLockedOut(this.expiresAt);
  final DateTime expiresAt;
}

final class AuthStateFatalError extends AuthState {
  const AuthStateFatalError(this.reason);
  final String reason;
}

class WrongPinException implements Exception {
  const WrongPinException({required this.failedAttempts, this.newLockout});
  final int failedAttempts;
  final Duration? newLockout;
}

class LockedOutException implements Exception {
  const LockedOutException(this.expiresAt);
  final DateTime expiresAt;
}
