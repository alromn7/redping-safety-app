import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/models/detection_context.dart';
import 'package:redping_14v/services/incident_escalation_coordinator.dart';
import 'package:redping_14v/models/sos_session.dart';

void main() {
  group('IncidentEscalationCoordinator fallback flow', () {
    final coordinator = IncidentEscalationCoordinator.instance;

    setUp(() {
      coordinator.reset();
      // Use a short fallback window for tests
      coordinator.setFallbackWindowForTest(const Duration(milliseconds: 50));
    });

    tearDown(() {
      coordinator.reset();
    });

    test('detection start sets detectionWindow state', () async {
      expect(coordinator.state, CoordinatorState.idle);

      final ctx = DetectionContext(
        type: DetectionType.crash,
        reason: DetectionReason.sharpDeceleration,
        timestamp: DateTime.now(),
        magnitude: 200.0,
      );

      coordinator.detectionWindowStarted(ctx);

      expect(coordinator.state, CoordinatorState.detectionWindow);
    });

    test(
      'noResponse triggers fallback and starts SOS with reason code',
      () async {
        final calls = <Map<String, dynamic>>[];

        // Intercept SOS start to capture arguments without touching real services
        coordinator.startSOSOverride =
            ({
              required SOSType type,
              required bool bringToSOSPage,
              String? escalationReasonCode,
            }) async {
              calls.add({
                'type': type,
                'bringToSOSPage': bringToSOSPage,
                'reason': escalationReasonCode,
              });
            };

        // Seed a detection context (used to map SOSType)
        final ctx = DetectionContext(
          type: DetectionType.crash,
          reason: DetectionReason.sharpDeceleration,
          timestamp: DateTime.now(),
          magnitude: 190.0,
        );
        coordinator.detectionWindowStarted(ctx);

        // Schedule fallback (heuristic no-response escalation)
        coordinator.scheduleFallback(
          context: ctx,
          reasonCode: 'Fallback_NoResponse',
        );

        // Wait > fallback window
        await Future.delayed(const Duration(milliseconds: 120));

        // Coordinator should have moved to sosCountdown
        expect(coordinator.state, CoordinatorState.sosCountdown);

        // Exactly one call should have been made to start SOS
        expect(calls.length, 1);
        final call = calls.first;
        expect(call['type'], SOSType.crashDetection);
        expect(call['bringToSOSPage'], true);
        expect(call['reason'], 'Fallback_NoResponse');
      },
    );
  });
}
