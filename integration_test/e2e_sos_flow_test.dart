
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:redping_14v/main.dart' as app;
import 'package:redping_14v/core/constants/app_constants.dart';
import 'package:redping_14v/services/app_service_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: SOS flow', () {
    testWidgets('launches app and completes SOS countdown to active', (
      tester,
    ) async {
      // Start the app
      app.main();

      // Allow initial background initialization to progress
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final manager = AppServiceManager();

      // Ensure services are initialized for the test (defensive)
      try {
        await manager.initializeAllServices().timeout(
          const Duration(seconds: 20),
          onTimeout: () {},
        );
      } catch (_) {}

      // If an SOS is already active from previous state, cancel it
      if (manager.sosService.hasActiveSession) {
        manager.sosService.cancelSOS();
        await Future.delayed(const Duration(seconds: 1));
      }

      // Start an SOS countdown
      await manager.sosService.startSOSCountdown(userMessage: 'E2E Test SOS');

      // Wait for countdown to elapse and activation to occur
      await Future<void>.delayed(
        Duration(seconds: AppConstants.sosCountdownSeconds + 3),
      );

      // Verify SOS is active
      expect(
        manager.sosService.isSOSActive,
        isTrue,
        reason: 'SOS should be active after countdown',
      );

      // Resolve the session and verify it is no longer active
      manager.sosService.resolveSession();
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(
        manager.sosService.hasActiveSession,
        isFalse,
        reason: 'SOS session should be resolved',
      );
    });
  });
}
