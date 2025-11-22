import 'dart:math';
import '../models/sos_session.dart';

/// Shared physics helpers for verification/detection to reduce duplication.
class VerificationPhysicsUtils {
  /// Calculate deceleration from a list of SensorReading entries.
  static double deceleration(List<SensorReading> readings) {
    if (readings.length < 2) return 0.0;
    final first = readings.first;
    final last = readings.last;

    final firstMag = _mag(first);
    final lastMag = _mag(last);

    final timeDiff =
        last.timestamp.difference(first.timestamp).inMilliseconds / 1000.0;

    return timeDiff > 0 ? (lastMag - firstMag).abs() / timeDiff : 0.0;
  }

  /// Calculate jerk (rate of change of acceleration) across readings.
  static double jerk(List<SensorReading> readings) {
    if (readings.length < 3) return 0.0;

    final accels = readings.map(_mag).toList();
    double maxJerk = 0.0;

    for (int i = 2; i < accels.length; i++) {
      final dt1 =
          readings[i].timestamp
              .difference(readings[i - 1].timestamp)
              .inMilliseconds /
          1000.0;
      final dt2 =
          readings[i - 1].timestamp
              .difference(readings[i - 2].timestamp)
              .inMilliseconds /
          1000.0;
      if (dt1 <= 0 || dt2 <= 0) continue;

      final a1 = (accels[i] - accels[i - 1]) / dt1;
      final a2 = (accels[i - 1] - accels[i - 2]) / dt2;
      final j = (a1 - a2).abs() / dt1;
      if (j > maxJerk) maxJerk = j;
    }

    return maxJerk;
  }

  /// Detect free-fall using ratio of low-gravity readings in a window.
  static bool freeFall(
    List<SensorReading> readings, {
    double threshold = 2.0,
    int window = 20,
    double ratio = 0.6,
  }) {
    if (readings.length < window) return false;
    final recent = readings.sublist(readings.length - window);
    int low = 0;
    for (final r in recent) {
      if (_mag(r) < threshold) low++;
    }
    return low > (window * ratio);
  }

  static double _mag(SensorReading r) =>
      sqrt(r.x * r.x + r.y * r.y + r.z * r.z);

  // Generic variants to support other SensorReading models
  static double decelerationFrom<T>(
    List<T> items,
    double Function(T) mag,
    DateTime Function(T) ts,
  ) {
    if (items.length < 2) return 0.0;
    final first = items.first;
    final last = items.last;
    final firstMag = mag(first);
    final lastMag = mag(last);
    final timeDiff = ts(last).difference(ts(first)).inMilliseconds / 1000.0;
    return timeDiff > 0 ? (lastMag - firstMag).abs() / timeDiff : 0.0;
  }

  static double jerkFrom<T>(
    List<T> items,
    double Function(T) mag,
    DateTime Function(T) ts,
  ) {
    if (items.length < 3) return 0.0;
    final accels = items.map(mag).toList();
    double maxJerk = 0.0;
    for (int i = 2; i < accels.length; i++) {
      final dt1 =
          ts(items[i]).difference(ts(items[i - 1])).inMilliseconds / 1000.0;
      final dt2 =
          ts(items[i - 1]).difference(ts(items[i - 2])).inMilliseconds / 1000.0;
      if (dt1 <= 0 || dt2 <= 0) continue;
      final a1 = (accels[i] - accels[i - 1]) / dt1;
      final a2 = (accels[i - 1] - accels[i - 2]) / dt2;
      final j = (a1 - a2).abs() / dt1;
      if (j > maxJerk) maxJerk = j;
    }
    return maxJerk;
  }

  static bool freeFallFrom<T>(
    List<T> items,
    double Function(T) mag, {
    double threshold = 2.0,
    int window = 20,
    double ratio = 0.6,
  }) {
    if (items.length < window) return false;
    final recent = items.sublist(items.length - window);
    int low = 0;
    for (final it in recent) {
      if (mag(it) < threshold) low++;
    }
    return low > (window * ratio);
  }
}
