import 'package:hive/hive.dart';
import 'storage_crypto.dart';

/// Utilities to open and migrate encrypted Hive boxes.
class EncryptedHive {
  /// Opens an encrypted box with the current AES-256 key.
  static Future<Box<T>> openBox<T>(String name) async {
    final cipher = await StorageCrypto.hiveCipher();
    return Hive.openBox<T>(name, encryptionCipher: cipher);
  }

  /// Migrates an existing plain-text box into an encrypted one.
  /// If the plain box doesn't exist, simply opens encrypted box.
  static Future<Box<T>> migratePlainToEncrypted<T>(String name) async {
    final exists = await Hive.boxExists(name);
    if (!exists) {
      return openBox<T>(name);
    }

    final isOpen = Hive.isBoxOpen(name);
    Box<T>? plain;
    if (isOpen) {
      plain = Hive.box<T>(name);
    } else {
      plain = await Hive.openBox<T>(name);
    }

    final data = Map<dynamic, T>.from(plain.toMap());
    await plain.close();
    await Hive.deleteBoxFromDisk(name);

    final enc = await openBox<T>(name);
    await enc.putAll(data);
    await enc.flush();
    return enc;
  }
}
