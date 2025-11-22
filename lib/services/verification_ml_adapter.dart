/// ML Adapter interface for RedPing AI Verification
/// Phase 0 scaffold: provides contract for future on-device model integration.
/// Keeps heuristic pipeline intact; model augments confidence only.
library;

class VerificationFeatures {
  final double peakMagnitude; // physics-adjusted
  final int sustainedHighImpactCount; // last N readings above crash threshold
  final double deceleration; // m/s² over short window
  final double jerk; // m/s³ peak
  final double impactDurationSeconds; // time above threshold
  final double preImpactAvgSpeed; // m/s
  final double postImpactAvgMagnitude; // residual motion
  final bool motionResumed; // driving continued
  final bool freeFallPattern; // fall dynamics
  final bool throwPattern; // free-fall + impact chain
  final bool stationaryPreImpact; // phone stationary before crash
  final double nightHourFactor; // 0 or 1 (night time)
  final bool lowPowerMode; // device low power state
  final bool airplaneMode; // flight turbulence context
  final bool boatMode; // marine vibration context
  final double falseAlarmRate7d; // historical ratio
  final int genuineIncidents7d; // count

  VerificationFeatures({
    required this.peakMagnitude,
    required this.sustainedHighImpactCount,
    required this.deceleration,
    required this.jerk,
    required this.impactDurationSeconds,
    required this.preImpactAvgSpeed,
    required this.postImpactAvgMagnitude,
    required this.motionResumed,
    required this.freeFallPattern,
    required this.throwPattern,
    required this.stationaryPreImpact,
    required this.nightHourFactor,
    required this.lowPowerMode,
    required this.airplaneMode,
    required this.boatMode,
    required this.falseAlarmRate7d,
    required this.genuineIncidents7d,
  });
}

abstract class VerificationMLAdapter {
  /// Returns true when model assets are loaded & ready.
  bool get isModelLoaded;

  /// Predict probability incident is genuine (0..1). Should be fast (<10ms).
  double predictIncidentProbability(VerificationFeatures features);

  /// Optional calibration hook for per-user adjustments.
  double applyCalibration(double probability) => probability;
}

/// Stub implementation used in Phase 0 (returns neutral baseline).
class StubVerificationMLAdapter implements VerificationMLAdapter {
  @override
  bool get isModelLoaded => false; // Always false; heuristic only

  @override
  double predictIncidentProbability(VerificationFeatures features) {
    // Neutral probability; encourages heuristic dominance.
    return 0.5;
  }

  @override
  double applyCalibration(double probability) => probability; // Explicit to satisfy interface contract
}
