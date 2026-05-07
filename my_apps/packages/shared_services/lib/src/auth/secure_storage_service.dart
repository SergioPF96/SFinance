import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);

  /// Returns true if the platform's secure storage is available and writable.
  Future<bool> isAvailable();
}

class FlutterSecureStorageService implements SecureStorageService {
  FlutterSecureStorageService()
      : _storage = const FlutterSecureStorage(
          wOptions: WindowsOptions(useBackwardCompatibility: false),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<bool> isAvailable() async {
    const testKey = '_sfinance_storage_health';
    try {
      await _storage.write(key: testKey, value: '1');
      await _storage.delete(key: testKey);
      return true;
    } catch (_) {
      return false;
    }
  }
}
