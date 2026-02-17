/// App-wide constants for RedPing Safety Ecosystem
class AppConstants {
  // App Info
  static const String appName = 'RedPing';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your Safety Companion';

  // Colors (Safety-focused theme)
  static const int primaryColorValue = 0xFFE53935; // Emergency Red
  static const int secondaryColorValue = 0xFF43A047; // Safe Green
  static const int accentColorValue = 0xFFFF9800; // Warning Orange
  static const int backgroundColorValue = 0xFF121212; // Dark theme
  static const int surfaceColorValue = 0xFF1E1E1E;

  // SOS Configuration
  static const int sosCountdownSeconds = 10;
  static const int acfdOfficialCountdownSeconds = 30;
  static const int heartbeatAnimationDurationMs = 1000;
  static const int emergencyVibrationPattern = 500;
  static const double highSpeedCrashBypassThreshold = 70.0;

  // Location & Tracking
  static const double locationAccuracyThreshold = 10.0; // meters
  static const int locationUpdateIntervalMs = 5000; // 5 seconds
  static const int breadcrumbTrailMaxPoints = 1000;

  // Vehicle Speed & Altitude Monitoring (for proactive detection state)
  // Geolocator speed is in m/s; 27.78 m/s ~= 100 km/h
  static const double criticalSpeedMps = 27.78;
  // Hysteresis to avoid flickering when hovering around the threshold
  static const double criticalSpeedHysteresisMps = 2.0;
  // Altitude monitoring uses relative gain over a short window
  static const double criticalAltitudeGainMeters = 15.0;
  static const int criticalAltitudeWindowSeconds = 30;

  // Flight detection thresholds
  static const double flightSpeedKmhThreshold = 250.0; // km/h
  static const double flightAltitudeFallbackMeters = 2500.0; // meters

  // Crash Detection Thresholds (Production)
  static const double crashAccelerationThreshold = 25.0; // m/s²
  static const double fallDetectionThreshold = 15.0; // m/s²
  static const double severeImpactThresholdG =
      250.0; // 250 m/s² for severe impact
  static const double jerkThreshold = 200.0; // 200 m/s³ rate of change
  static const double decelerationThreshold = 20.0; // 20 m/s² deceleration

  // Test Mode Thresholds (v2.0 - Production Flow Testing)
  // These lowered thresholds allow simple phone shaking to trigger full ACFD flow
  static const double testModeCrashThresholdG = 8.0; // 8G (vigorous shake)
  static const double testModeFallHeightMeters =
      0.3; // 0.3m (gentle drop ~1 foot)
  static const double testModeSevereImpactThresholdG = 15.0; // 15 m/s²
  static const double testModeJerkThreshold = 50.0; // 50 m/s³
  static const double testModeDecelerationThreshold = 5.0; // 5 m/s²
  static const double testModeShakeThreshold = 6.0; // 6G moderate shake
  static const int testModeShakeWindowMs = 1000; // 1 second window
  static const int testModeMinShakeCount = 3; // 3+ shakes to trigger

  /// Sensor Configuration
  static const int sensorSamplingRateMs =
      500; // 2Hz - Low power mode for background monitoring
  static const int sensorSamplingRateActiveMs =
      100; // 10Hz - Active mode during SOS
  static const int crashDetectionWindowMs = 2000; // 2 seconds

  // Test Mode v2.0 Configuration
  // Testing mode enables lowered sensitivity thresholds + comprehensive diagnostics
  // while running full production pipeline (NO bypasses or suppressions)
  static bool testingModeEnabled = false;

  // SMS Test Mode - use test contacts instead of real emergency contacts
  static bool useSmsTestMode = false;
  static List<String> testModeEmergencyContacts = [
    '+1234567890', // Test device 1
    '+0987654321', // Test device 2
  ];

  // Legacy Lab Flags (v1.0 - kept for backward compatibility, not used in v2.0)
  static bool labSuppressAllSOSDialogs = false;
  static bool labSuppressVerificationDialog = false;
  static bool labSuppressCountdownDialog = false;
  static bool labSuppressActivatedDialog = false;

  /// Activate testing mode v2.0 at runtime
  /// Effects:
  ///  - Enables lowered sensitivity thresholds (8G crash, 0.3m fall, 6G shake)
  ///  - Starts diagnostic data collection and real-time overlay
  ///  - Runs full production pipeline (NO bypasses)
  ///  - Optionally uses test SMS contacts instead of real ones
  static void activateTestingMode({bool enableSmsTestMode = false}) {
    testingModeEnabled = true;
    useSmsTestMode = enableSmsTestMode;

    // Import and start diagnostic service
    // This will be called from the UI toggle
    print(
      '[TestMode] v2.0 activated - Production flow with lowered thresholds',
    );
    print('[TestMode] SMS test mode: $enableSmsTestMode');
  }

  /// Deactivate testing mode (restore production thresholds)
  static void deactivateTestingMode() {
    testingModeEnabled = false;
    useSmsTestMode = false;

    // Stop diagnostic service
    print('[TestMode] Deactivated - Production thresholds restored');
  }

  /// Get appropriate threshold based on test mode state
  static double getCrashThreshold() {
    return testingModeEnabled
        ? testModeCrashThresholdG
        : crashAccelerationThreshold;
  }

  static double getFallThreshold() {
    return testingModeEnabled
        ? testModeFallHeightMeters
        : fallDetectionThreshold;
  }

  static double getJerkThreshold() {
    return testingModeEnabled ? testModeJerkThreshold : jerkThreshold;
  }

  static double getDecelerationThreshold() {
    return testingModeEnabled
        ? testModeDecelerationThreshold
        : decelerationThreshold;
  }

  // Communication
  static const int meshNetworkDiscoveryTimeoutMs = 30000; // 30 seconds
  static const int messageRetryAttempts = 3;
  static const int offlineMessageQueueLimit = 100;

  // Battery & Performance
  static const double lowBatteryThreshold = 0.15; // 15%
  static const double criticalBatteryThreshold = 0.05; // 5%
  static const int backgroundLocationIntervalMs = 60000; // 1 minute

  // Database
  static const String dbName = 'redping_database';
  static const int dbVersion = 1;

  // Storage Keys
  static const String userProfileKey = 'user_profile';
  static const String emergencyContactsKey = 'emergency_contacts';
  static const String settingsKey = 'app_settings';
  static const String lastKnownLocationKey = 'last_known_location';

  // API Keys - Google Maps removed, using native maps

  // API Endpoints (placeholder - would be actual endpoints in production)
  static const String baseApiUrl = 'https://api.redping.com/v1';
  static const String sosEndpoint = '/sos';
  static const String hazardFeedEndpoint = '/hazards';
  static const String communityEndpoint = '/community';

  // Push Notification Topics
  static const String emergencyAlertsTopic = 'emergency_alerts';
  static const String hazardAlertsTopic = 'hazard_alerts';
  static const String communityUpdatesTopic = 'community_updates';

  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_BACKGROUND_LOCATION',
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.VIBRATE',
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.WAKE_LOCK',
    'android.permission.FOREGROUND_SERVICE',
  ];

  // Feature Flags
  static const bool enableCrashDetection = true;
  static const bool enableFallDetection = true;
  static const bool enableMeshNetworking = true;
  static const bool enableVoiceCommands = true;
  static const bool enableHazardAlerts = true;
  static const bool enableCommunityFeatures = true;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double sosButtonSize = 200.0;
  static const double mapZoomLevel = 15.0;

  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 400;
  static const int longAnimationMs = 800;
  static const int sosHeartbeatMs = 1000;

  // Text Styles
  static const double headingFontSize = 24.0;
  static const double subheadingFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
}
