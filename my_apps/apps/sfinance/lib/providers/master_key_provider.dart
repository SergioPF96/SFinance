import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'auth_provider.dart';

// T021: fail-fast guard — throws if accessed before authentication.
final masterKeyProvider = Provider<Uint8List>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthStateAuthenticated) return authState.masterKey;
  throw StateError('masterKey accessed before authentication');
});
