import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_services/shared_services.dart';
import '../services/recurring_generation_service.dart';

// T020: authServiceProvider + AuthNotifier
// T031: submitPin (US2)
// T037: clearLockout (US3)

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    storage: FlutterSecureStorageService(),
    keyDerivation: Pbkdf2KeyDerivationService(),
    encryption: AesGcmEncryptionService(),
    preExistingDbExists: () async {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, 'sfinance.sqlite')).exists();
    },
  );
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthStateBootstrapping();

  Future<void> bootstrap() async {
    state = await ref.read(authServiceProvider).bootstrap();
  }

  Future<void> completeSetup(String pin) async {
    state = const AuthStateVerifying();
    final key = await ref.read(authServiceProvider).setupPin(pin);
    await _runRecurringGeneration(key);
    state = AuthStateAuthenticated(key);
  }

  Future<void> submitPin(String pin) async {
    state = const AuthStateVerifying();
    try {
      final key = await ref.read(authServiceProvider).verifyPin(pin);
      await _runRecurringGeneration(key);
      state = AuthStateAuthenticated(key);
    } on WrongPinException catch (e) {
      state = AuthStateNeedsAuth(error: e);
    } on LockedOutException catch (e) {
      state = AuthStateLockedOut(e.expiresAt);
    }
  }

  void clearLockout() => state = const AuthStateNeedsAuth();

  Future<void> _runRecurringGeneration(Uint8List key) async {
    final db = AppDatabase(key);
    try {
      await RecurringGenerationService.run(db);
    } finally {
      await db.close();
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
