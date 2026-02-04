import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/models/detection_context.dart';
import 'package:redping_14v/services/incident_escalation_coordinator.dart';
import 'package:redping_14v/models/sos_session.dart';

void main() {
  group('IncidentEscalationCoordinator additional flows', () {
    final coordinator = IncidentEscalationCoordinator.instance;

    setUp(() {
      coordinator.reset();
      coordinator.setFallbackWindowForTest(const Duration(milliseconds: 80));
    });

    tearDown(() {
      coordinator.reset();
      coordinator.startSOSOverride = null;
    });

    test(
      'uncertain triggers fallback with reason Fallback_Uncertain',
      () async {
        final calls = <Map<String, dynamic>>[];
        coordinator.startSOSOverride =
            ({
              required SOSType type,
              required bool bringToSOSPage,
              String? escalationReasonCode,
            }) async {
              calls.add({'type': type, 'reason': escalationReasonCode});
            };

        final ctx = DetectionContext(
          type: DetectionType.fall,
          reason: DetectionReason.freeFallImpact,
          timestamp: DateTime.now(),
          magnitude: 35.0,
        );
        coordinator.detectionWindowStarted(ctx);

        coordinator.scheduleFallback(
          context: ctx,
          reasonCode: 'Fallback_Uncertain',
        );

        await Future.delayed(const Duration(milliseconds: 140));

        expect(coordinator.state, CoordinatorState.sosCountdown);
        expect(calls.length, 1);
        expect(calls.first['type'], SOSType.fallDetection);
        expect(calls.first['reason'], 'Fallback_Uncertain');
      },
    );

    test('fallback cancelled on falseAlarm before expiry', () async {
      final calls = <Map<String, dynamic>>[];
      coordinator.startSOSOverride =
          ({
            required SOSType type,
            required bool bringToSOSPage,
            String? escalationReasonCode,
          }) async {
            calls.add({'type': type, 'reason': escalationReasonCode});
          };

      final ctx = DetectionContext(
        type: DetectionType.crash,
        reason: DetectionReason.sharpDeceleration,
        timestamp: DateTime.now(),
        magnitude: 150.0,
      );
      coordinator.detectionWindowStarted(ctx);

      coordinator.scheduleFallback(
        context: ctx,
        reasonCode: 'Fallback_Uncertain',
      );

      // Cancel quickly and mark as false alarm
      coordinator.markFalseAlarm();

      // Wait beyond original fallback window to ensure no SOS
      await Future.delayed(const Duration(milliseconds: 150));

      expect(coordinator.state, CoordinatorState.falseAlarm);
      expect(calls, isEmpty);
    });

    test('notifyCountdownStarted synchronizes state', () async {
      expect(coordinator.state, CoordinatorState.idle);
      coordinator.notifyCountdownStarted(
        type: SOSType.manual,
        reasonCode: 'Manual_Test',
      );
      expect(coordinator.state, CoordinatorState.sosCountdown);
    });
  });
}
