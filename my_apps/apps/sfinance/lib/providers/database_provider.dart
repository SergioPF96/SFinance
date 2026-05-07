import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'master_key_provider.dart';

// T022: watch masterKeyProvider so the DB only opens after authentication.
// RecurringGenerationService is run by AuthNotifier after PIN verification.
final databaseProvider = Provider<AppDatabase>((ref) {
  final key = ref.watch(masterKeyProvider);
  final db = AppDatabase(key);
  ref.onDispose(db.close);
  return db;
});
