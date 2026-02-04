import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:redping_14v/security/secure_storage_service.dart';

/// Shared test initialization utilities.
///
/// - Uses in-memory secure storage to avoid platform channels.
/// - Initializes Hive in a temp folder (no path_provider needed).
class TestEnvironment {
  static Directory? _hiveDir;

  static Future<void> setUp() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SecureStorageService.instance.enableInMemoryMock();

    _hiveDir = await Directory.systemTemp.createTemp('redping_hive_test_');
    Hive.init(_hiveDir!.path);
  }

  static Future<void> tearDown() async {
    try {
      await Hive.close();
    } catch (_) {
      // Ignore close errors in tests.
    }

    final dir = _hiveDir;
    _hiveDir = null;
    if (dir != null) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {
        // Ignore cleanup errors in tests.
      }
    }
  }
}
