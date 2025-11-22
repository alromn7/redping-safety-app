import 'dart:math' as math;
import 'verification_ml_adapter.dart';

/// Lightweight feature snapshot builder (Phase 0)
///
/// This builder consumes short time windows of sensor magnitudes
/// (already converted to real-world m/s^2 by SensorService) around
/// a detection event and derives VerificationFeatures for ML inference.
class FeatureSnapshotBuilder {
  // Tunable thresholds (kept conservative; align with heuristic constants)
  static const double crashImpactThreshold = 80.0; // m/s^2 (example)
  static const double freeFallThreshold = 3.0; // m/s^2 approx < 0.3g
  static const double stationaryVarianceThreshold = 1.5; // m/s^2^2

  /// Time series sample for magnitude with optional speed (m/s)
  const FeatureSnapshotBuilder();
}

class TimeSample {
  final DateTime t;
  final double magnitude; // m/s^2
  final double? speed; // m/s (optional)
  const TimeSample({required this.t, required this.magnitude, this.speed});
}

class SnapshotInputs {
  final List<TimeSample> preImpact; // e.g., 3–5s
  final List<TimeSample> impactWindow; // around the peak
  final List<TimeSample> postImpact; // 1–3s

  // Context flags
  final bool lowPowerMode;
  final bool airplaneMode;
  final bool boatMode;

  // Historical
  final double falseAlarmRate7d; // 0..1
  final int genuineIncidents7d;

  const SnapshotInputs({
    required this.preImpact,
    required this.impactWindow,
    required this.postImpact,
    this.lowPowerMode = false,
    this.airplaneMode = false,
    this.boatMode = false,
    this.falseAlarmRate7d = 0.0,
    this.genuineIncidents7d = 0,
  });
}

class FeatureSnapshotBuilderResult {
  final VerificationFeatures features;
  final Map<String, double> debug; // expose intermediate metrics for tests
  const FeatureSnapshotBuilderResult(this.features, this.debug);
}

extension on List<TimeSample> {
  double _avgMag() =>
      isEmpty ? 0.0 : fold<double>(0.0, (acc, s) => acc + s.magnitude) / length;
  double _varMag() {
    if (isEmpty) return 0.0;
    final mu = _avgMag();
    return fold<double>(
          0.0,
          (acc, s) => acc + (s.magnitude - mu) * (s.magnitude - mu),
        ) /
        length;
  }

  double _avgSpeed() {
    final speeds = where((s) => s.speed != null).map((s) => s.speed!).toList();
    if (speeds.isEmpty) return 0.0;
    return speeds.reduce((a, b) => a + b) / speeds.length;
  }
}

class FeatureSnapshotBuilderImpl {
  /// Build features from snapshot inputs.
  static FeatureSnapshotBuilderResult build(
    SnapshotInputs inputs,
    DateTime now,
  ) {
    final impact = inputs.impactWindow;
    final pre = inputs.preImpact;
    final post = inputs.postImpact;

    final peak = impact.isEmpty
        ? 0.0
        : impact.map((s) => s.magnitude).reduce(math.max);

    // Sustained high-impact count above crash threshold
    final sustainedCount = impact
        .where(
          (s) => s.magnitude >= FeatureSnapshotBuilder.crashImpactThreshold,
        )
        .length;

    // Approx deceleration over short window: diff of average before/after
    final preAvg = pre._avgMag();
    final postAvg = post._avgMag();
    final decel = (preAvg - postAvg).clamp(0.0, double.infinity);

    // Jerk: max finite difference of magnitude per second
    double jerkMax = 0.0;
    for (var i = 1; i < impact.length; i++) {
      final dt =
          impact[i].t.difference(impact[i - 1].t).inMilliseconds / 1000.0;
      if (dt <= 0) continue;
      final dv = (impact[i].magnitude - impact[i - 1].magnitude).abs();
      jerkMax = math.max(jerkMax, dv / dt);
    }

    // Impact duration above threshold
    double durationSec = 0.0;
    for (var i = 1; i < impact.length; i++) {
      final above =
          impact[i - 1].magnitude >=
              FeatureSnapshotBuilder.crashImpactThreshold ||
          impact[i].magnitude >= FeatureSnapshotBuilder.crashImpactThreshold;
      if (above) {
        durationSec +=
            impact[i].t.difference(impact[i - 1].t).inMilliseconds / 1000.0;
      }
    }

    final preSpeed = pre._avgSpeed();
    final postAvgMag = post._avgMag();

    // Motion resumed if post-impact average significantly higher than stationary
    final motionResumed = postAvgMag > 2.5; // heuristic small motion threshold

    // Free-fall ratio in pre-impact
    final freeFallRatio = pre.isEmpty
        ? 0.0
        : pre
                  .where(
                    (s) =>
                        s.magnitude < FeatureSnapshotBuilder.freeFallThreshold,
                  )
                  .length /
              pre.length;
    final freeFallPattern = freeFallRatio > 0.2; // any meaningful interval

    // Throw pattern: noticeable free-fall followed by high impact
    final throwPattern =
        freeFallPattern && peak >= FeatureSnapshotBuilder.crashImpactThreshold;

    // Stationary pre-impact: low variance
    final stationaryPre =
        pre._varMag() <= FeatureSnapshotBuilder.stationaryVarianceThreshold;

    final hour = now.hour;
    final night = (hour >= 22 || hour < 6) ? 1.0 : 0.0;

    final vf = VerificationFeatures(
      peakMagnitude: peak,
      sustainedHighImpactCount: sustainedCount,
      deceleration: decel,
      jerk: jerkMax,
      impactDurationSeconds: durationSec,
      preImpactAvgSpeed: preSpeed,
      postImpactAvgMagnitude: postAvgMag,
      motionResumed: motionResumed,
      freeFallPattern: freeFallPattern,
      throwPattern: throwPattern,
      stationaryPreImpact: stationaryPre,
      nightHourFactor: night,
      lowPowerMode: inputs.lowPowerMode,
      airplaneMode: inputs.airplaneMode,
      boatMode: inputs.boatMode,
      falseAlarmRate7d: inputs.falseAlarmRate7d,
      genuineIncidents7d: inputs.genuineIncidents7d,
    );

    return FeatureSnapshotBuilderResult(vf, {
      'peak': peak,
      'sustainedCount': sustainedCount.toDouble(),
      'decel': decel,
      'jerk': jerkMax,
      'impactDurationSec': durationSec,
      'preAvgSpeed': preSpeed,
      'postAvgMag': postAvgMag,
      'freeFallRatio': freeFallRatio,
      'nightHour': night,
    });
  }
}
