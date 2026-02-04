// Bluetooth scanner service removed in Phase 1 APK optimization
// This is a stub to satisfy imports

import 'package:flutter/foundation.dart';

class BluetoothScannerService {
  BluetoothScannerService() {
    debugPrint('BluetoothScannerService: Feature disabled in Phase 1');
  }

  Future<void> initialize() async {
    debugPrint('Bluetooth scanning disabled');
  }

  Future<dynamic> convertToGadgetDevice(dynamic device, {String? type}) async {
    return null;
  }
}
