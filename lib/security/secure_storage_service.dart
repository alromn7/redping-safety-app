import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around platform secure storage with sane defaults
class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();
  SecureStorageService._internal();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  late final FlutterSecureStorage _storage;
  bool _initialized = false;
  bool _useMock = false;
  final Map<String, String> _mockStore = <String, String>{};

  Future<void> initialize() async {
    if (_initialized) return;
    if (_useMock) {
      _initialized = true;
      return;
    }
    _storage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    _initialized = true;
  }

  Future<void> write({required String key, required String value}) async {
    await _ensure();
    if (_useMock) {
      _mockStore[key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    await _ensure();
    if (_useMock) {
      return _mockStore[key];
    }
    return _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _ensure();
    if (_useMock) {
      _mockStore.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  Future<bool> containsKey(String key) async {
    await _ensure();
    if (_useMock) {
      return _mockStore.containsKey(key);
    }
    return await _storage.containsKey(key: key);
  }

  Future<Map<String, String>> readAll() async {
    await _ensure();
    if (_useMock) {
      return Map<String, String>.from(_mockStore);
    }
    return _storage.readAll();
  }

  Future<void> deleteAll() async {
    await _ensure();
    if (_useMock) {
      _mockStore.clear();
      return;
    }
    await _storage.deleteAll();
  }

  Future<void> _ensure() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Enable in-memory mock store for tests where platform channels are unavailable
  void enableInMemoryMock() {
    _useMock = true;
    _initialized = false; // re-init in mock mode on next use
  }
}
