import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:redping_14v/models/sos_session.dart';
import 'package:redping_14v/services/sensor_service.dart';

SensorReading _readingWithMagnitude(
  double rawMagnitude, {
  required String sensorType,
  DateTime? timestamp,
}) {
  final axis = sqrt(rawMagnitude.clamp(0.0, double.infinity));
  return SensorReading(
    timestamp: timestamp ?? DateTime.now(),
    x: axis,
    y: 0.0,
    z: 0.0,
    sensorType: sensorType,
  );
}

void main() {
  group('SensorService (ACFD) safety tests', () {
    test('debugIsValidSensorReading allows realistic high-G axes', () {
      final service = SensorService();
      service.debugResetForTest();

      expect(service.debugIsValidSensorReading(200.0, 0.0, 0.0), true);
      expect(service.debugIsValidSensorReading(-250.0, 10.0, 10.0), true);
      expect(service.debugIsValidSensorReading(401.0, 0.0, 0.0), false);
      expect(service.debugIsValidSensorReading(double.nan, 0.0, 0.0), false);
      expect(service.debugIsValidSensorReading(double.infinity, 0.0, 0.0), false);
    });

    test('violent handling triggers on throw pattern (free-fall + impact)', () {
      final service = SensorService();
      service.debugResetForTest();

      var triggered = false;
      service.setViolentHandlingDetectedCallback((_) {
        triggered = true;
      });

      // Need at least 10 accelerometer readings in last 2 seconds.
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        service.debugAddAccelerometerReading(
          _readingWithMagnitude(
            15.0,
            sensorType: 'accelerometer',
            timestamp: now.subtract(Duration(milliseconds: 400 - i * 10)),
          ),
        );
      }

      // Free-fall samples (rawMagnitude < 5.0 in current implementation).
      for (var i = 0; i < 3; i++) {
        service.debugAddAccelerometerReading(
          _readingWithMagnitude(
            4.0,
            sensorType: 'accelerometer',
            timestamp: now.subtract(Duration(milliseconds: 200 - i * 10)),
          ),
        );
      }

      // High-impact samples (rawMagnitude in [179.5, 180)).
      for (var i = 0; i < 2; i++) {
        service.debugAddAccelerometerReading(
          _readingWithMagnitude(
            179.6,
            sensorType: 'accelerometer',
            timestamp: now.subtract(Duration(milliseconds: 80 - i * 10)),
          ),
        );
      }

      // Call the checker with a high-impact reading.
      service.debugCheckForViolentHandling(
        _readingWithMagnitude(179.6, sensorType: 'accelerometer'),
      );

      expect(triggered, true);
    });

    test('violent handling does not trigger on impact-only (no throw, no rotation)', () {
      final service = SensorService();
      service.debugResetForTest();

      var triggered = false;
      service.setViolentHandlingDetectedCallback((_) {
        triggered = true;
      });

      final now = DateTime.now();
      for (var i = 0; i < 10; i++) {
        service.debugAddAccelerometerReading(
          _readingWithMagnitude(
            179.6,
            sensorType: 'accelerometer',
            timestamp: now.subtract(Duration(milliseconds: 300 - i * 10)),
          ),
        );
      }

      service.debugCheckForViolentHandling(
        _readingWithMagnitude(179.6, sensorType: 'accelerometer'),
      );

      expect(triggered, false);
    });

    test('violent handling triggers on rotation + high impact (no free-fall)', () {
      final service = SensorService();
      service.debugResetForTest();

      var triggered = false;
      service.setViolentHandlingDetectedCallback((_) {
        triggered = true;
      });

      final now = DateTime.now();
      // 10 accel readings, including a couple of high impacts but no free-fall.
      for (var i = 0; i < 8; i++) {
        service.debugAddAccelerometerReading(
          _readingWithMagnitude(
            20.0,
            sensorType: 'accelerometer',
            timestamp: now.subtract(Duration(milliseconds: 400 - i * 10)),
          ),
        );
      }
      for (var i = 0; i < 2; i++) {
        service.debugAddAccelerometerReading(
          _readingWithMagnitude(
            179.6,
            sensorType: 'accelerometer',
            timestamp: now.subtract(Duration(milliseconds: 120 - i * 10)),
          ),
        );
      }

      // Gyroscope rotation samples (magnitude > 3.0 in current implementation).
      for (var i = 0; i < 5; i++) {
        service.debugAddGyroscopeReading(
          _readingWithMagnitude(
            3.1,
            sensorType: 'gyroscope',
            timestamp: now.subtract(Duration(milliseconds: 150 - i * 10)),
          ),
        );
      }

      service.debugCheckForViolentHandling(
        _readingWithMagnitude(179.6, sensorType: 'accelerometer'),
      );

      expect(triggered, true);
    });
  });
}
