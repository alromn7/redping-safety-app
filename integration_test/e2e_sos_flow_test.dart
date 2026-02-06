
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:redping_14v/main_sos.dart' as app;
import 'package:redping_14v/core/constants/app_constants.dart';
import 'package:redping_14v/config/testing_mode.dart';
import 'package:redping_14v/services/app_service_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: SOS flow', () {
    testWidgets('launches app and completes SOS countdown to active', (
      tester,
    ) async {
      TestingMode.activate(suppressDialogs: true);

      // Start the app
      app.main();

      // Avoid pumpAndSettle() here: the app has background timers/animations
      // that can keep scheduling frames indefinitely during real-device runs.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Lightweight progress markers help diagnose device flakiness.
      // ignore: avoid_print
      print('E2E: app started');

      final manager = AppServiceManager();

      // Ensure services are initialized for the test (defensive)
      try {
        await manager.initializeAllServices().timeout(
          const Duration(seconds: 20),
          onTimeout: () {},
        );
      } catch (_) {}

      // ignore: avoid_print
      print('E2E: services init attempted');

      // If an SOS is already active from previous state, cancel it
      if (manager.sosService.hasActiveSession) {
        manager.sosService.cancelSOS();
        await Future.delayed(const Duration(seconds: 1));
      }

      // ignore: avoid_print
      print('E2E: starting SOS countdown');

      // Start an SOS countdown
      await manager.sosService.startSOSCountdown(
        userMessage: 'E2E Test SOS',
        bringToSOSPage: false,
      );

      // Wait for countdown to elapse and activation to occur
      await tester.pump(
        Duration(seconds: AppConstants.sosCountdownSeconds + 3),
      );

      // ignore: avoid_print
      print('E2E: countdown elapsed; isSOSActive=${manager.sosService.isSOSActive}');

      // Verify SOS is active
      expect(
        manager.sosService.isSOSActive,
        isTrue,
        reason: 'SOS should be active after countdown',
      );

      // Resolve the session and verify it is no longer active
      try {
        await manager.sosService
            .resolveSession()
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        // Best-effort in integration: ensure we don't leave a hanging session.
      }

      // ignore: avoid_print
      print('E2E: resolve requested; waiting for deactivation');

      // Allow async cleanup/persistence to settle.
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline) &&
          manager.sosService.hasActiveSession) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        manager.sosService.hasActiveSession,
        isFalse,
        reason: 'SOS session should be resolved',
      );
    });
  });
}
