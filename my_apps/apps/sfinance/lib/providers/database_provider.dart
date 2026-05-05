import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';

/// Singleton [AppDatabase] opened once at startup.
///
/// Globally scoped — accessed by all DAOs and services throughout the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
