import '../core/constants/app_constants.dart';

class ActivityStatus {
  final String mode;
  final String summary;
  const ActivityStatus({required this.mode, required this.summary});
}

/// Classifies activity based on speed (km/h) and altitude (meters).
/// - Flying if speed >= 250 km/h
/// - Flying if altitude >= 2500 m (altitude-only fallback)
/// - High-Speed 100-249 km/h
/// - Driving 25-99 km/h
/// - Running/Cycling 8-24 km/h
/// - Walking 2-7 km/h
/// - Idle < 2 km/h or missing speed
class ActivityClassifier {
  static ActivityStatus classify(double? speedKmh, double? altitudeM) {
    final double s = (speedKmh ?? 0.0);
    final double a = (altitudeM ?? 0.0);

    String mode;
    String summary = '';

    // Primary flying by speed
    if (s >= AppConstants.flightSpeedKmhThreshold) {
      mode = 'Flying ${s.toStringAsFixed(0)} km/h';
      summary = 'Airplane mode detected';
      return ActivityStatus(mode: mode, summary: summary);
    }

    // Altitude-only fallback for flight (e.g., GPS speed unavailable in-flight)
    if (a >= AppConstants.flightAltitudeFallbackMeters) {
      mode = 'Flying (alt) ${a.toStringAsFixed(0)} m';
      summary = 'Airplane mode detected';
      return ActivityStatus(mode: mode, summary: summary);
    }

    if (s < 2) {
      mode = 'Idle';
      return ActivityStatus(mode: mode, summary: summary);
    } else if (s >= 2 && s < 8) {
      mode = 'Walking ${s.toStringAsFixed(0)} km/h';
      summary = 'Walking detected';
    } else if (s >= 8 && s < 25) {
      mode = 'Running/Cycling ${s.toStringAsFixed(0)} km/h';
      summary = 'Fast movement detected';
    } else if (s >= 25 && s < 100) {
      mode = 'Driving ${s.toStringAsFixed(0)} km/h';
      summary = 'Vehicle movement';
    } else if (s >= 100 && s < 250) {
      mode = 'High-Speed ${s.toStringAsFixed(0)} km/h';
      summary = 'Fast vehicle or boat detected';
    } else {
      // Should not reach here due to early returns
      mode = 'Idle';
    }

    return ActivityStatus(mode: mode, summary: summary);
  }
}
