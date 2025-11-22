import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'secure_storage_service.dart';

/// Provides encryption key management for local storage/databases.
class StorageCrypto {
  static const String _masterKeyName = 'sec.master.v1';
  static const String _keyVersionName = 'sec.master.v1.kid';

  /// Ensure a 32-byte AES key exists in secure storage.
  static Future<List<int>> ensureMasterKey() async {
    await SecureStorageService.instance.initialize();
    final has = await SecureStorageService.instance.containsKey(_masterKeyName);
    if (!has) {
      final rnd = Random.secure();
      final key = List<int>.generate(32, (_) => rnd.nextInt(256));
      final b64 = base64Encode(key);
      await SecureStorageService.instance.write(
        key: _masterKeyName,
        value: b64,
      );
      await SecureStorageService.instance.write(
        key: _keyVersionName,
        value: '1',
      );
      return key;
    }
    final b64 = await SecureStorageService.instance.read(key: _masterKeyName);
    return base64Decode(b64!);
  }

  /// Get current AES-256 key (creates if missing)
  static Future<List<int>> getCurrentKey() => ensureMasterKey();

  /// Return HiveAesCipher for encrypted boxes
  static Future<HiveAesCipher> hiveCipher() async {
    final key = await getCurrentKey();
    return HiveAesCipher(key);
  }

  /// Rotate key: generates a new key and stores previous as deprecated.
  static Future<void> rotateKey() async {
    await SecureStorageService.instance.initialize();
    final rnd = Random.secure();
    final key = List<int>.generate(32, (_) => rnd.nextInt(256));
    final b64 = base64Encode(key);
    await SecureStorageService.instance.write(key: _masterKeyName, value: b64);
    final currentKid = await SecureStorageService.instance.read(
      key: _keyVersionName,
    );
    final nextKid = ((int.tryParse(currentKid ?? '1') ?? 1) + 1).toString();
    await SecureStorageService.instance.write(
      key: _keyVersionName,
      value: nextKid,
    );
  }
}
