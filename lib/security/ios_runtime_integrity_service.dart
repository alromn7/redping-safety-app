import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Provides iOS runtime integrity checks using the native SecurityPlugin.
class IosRuntimeIntegrityService {
  IosRuntimeIntegrityService._();
  static final IosRuntimeIntegrityService instance =
      IosRuntimeIntegrityService._();

  static const MethodChannel _channel = MethodChannel('redping.security');

  /// Returns true if the device appears jailbroken; false otherwise or when unsupported.
  Future<bool> isJailbroken() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<dynamic>('checkRootStatus');
      if (result is bool) return result;
    } catch (_) {}
    return false;
  }

  /// Throws if device is not allowed for sensitive operations.
  /// Currently blocks jailbroken devices when on iOS.
  Future<void> assertDeviceAllowed() async {
    if (!Platform.isIOS) return;
    final jailbroken = await isJailbroken();
    if (jailbroken) {
      throw Exception('IOS_JAILBROKEN_BLOCKED');
    }
  }
}
