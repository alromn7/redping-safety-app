import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/services/platform_service.dart';

/// Test suite for Always-On functionality
/// Verifies battery optimization, boot receiver, and platform services
void main() {
  group('Platform Service Tests', () {
    test('PlatformService should initialize without errors', () {
      // Should not throw
      expect(
        () => PlatformService.isBatteryOptimizationDisabled(),
        returnsNormally,
      );
    });

    test('getDeviceManufacturer should return string', () async {
      final manufacturer = await PlatformService.getDeviceManufacturer();
      expect(manufacturer, isA<String>());
      expect(manufacturer.isNotEmpty, true);
    });

    test('canRunInBackground should return boolean', () async {
      final canRun = await PlatformService.canRunInBackground();
      expect(canRun, isA<bool>());
    });
  });

  group('Battery Optimization Tests', () {
    test('isBatteryOptimizationDisabled should return boolean', () async {
      final isDisabled = await PlatformService.isBatteryOptimizationDisabled();
      expect(isDisabled, isA<bool>());
    });

    test('requestBatteryOptimizationExemption should not throw', () {
      expect(
        () => PlatformService.requestBatteryOptimizationExemption(),
        returnsNormally,
      );
    });

    test('openBatterySettings should not throw', () {
      expect(() => PlatformService.openBatterySettings(), returnsNormally);
    });
  });
}
