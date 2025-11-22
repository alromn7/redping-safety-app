import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Service for handling platform-specific functionality
/// Primarily for Android battery optimization exemptions
class PlatformService {
  static const platform = MethodChannel('com.redping.redping/battery');

  /// Request battery optimization exemption (Android only)
  /// Returns true if already exempted or user grants exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't need this
    }

    try {
      final bool isExempt = await platform.invokeMethod(
        'requestBatteryExemption',
      );
      return isExempt;
    } catch (e) {
      print('PlatformService: Error requesting battery exemption - $e');
      return false;
    }
  }

  /// Check if battery optimization is disabled (Android only)
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't need this
    }

    try {
      final bool isDisabled = await platform.invokeMethod(
        'checkBatteryExemption',
      );
      return isDisabled;
    } catch (e) {
      print('PlatformService: Error checking battery exemption - $e');
      return false;
    }
  }

  /// Open battery settings directly
  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;

    try {
      await platform.invokeMethod('openBatterySettings');
    } catch (e) {
      print('PlatformService: Error opening battery settings - $e');
    }
  }

  /// Get device manufacturer for specific guidance
  static Future<String> getDeviceManufacturer() async {
    if (!Platform.isAndroid) return 'Apple';

    try {
      final String manufacturer = await platform.invokeMethod(
        'getManufacturer',
      );
      return manufacturer;
    } catch (e) {
      print('PlatformService: Error getting manufacturer - $e');
      return 'Unknown';
    }
  }

  /// Check if app can run in background unrestricted
  static Future<bool> canRunInBackground() async {
    if (!Platform.isAndroid) {
      return false; // iOS has limitations
    }

    // Check battery exemption + foreground service
    final batteryExempt = await isBatteryOptimizationDisabled();
    return batteryExempt;
  }
}
