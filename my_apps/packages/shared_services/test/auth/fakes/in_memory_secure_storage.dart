import 'package:shared_services/src/auth/secure_storage_service.dart';

class InMemorySecureStorageService implements SecureStorageService {
  InMemorySecureStorageService({bool available = true})
      : _available = available;

  final Map<String, String> _store = {};
  final bool _available;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<bool> isAvailable() async => _available;
}
