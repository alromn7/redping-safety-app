import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../core/constants/app_constants.dart';
import '../models/sos_session.dart';
import '../models/detection_context.dart';
import 'incident_escalation_coordinator.dart';
import 'connectivity_monitor_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'app_service_manager.dart';
import 'test_mode_diagnostic_service.dart';
import '../models/redping_mode.dart' show PowerMode, SensorConfig;

/// Service for handling device sensors and crash/fall detection
class SensorService {
  void wake() {
    // TODO: Implement wake logic if needed
    debugPrint('SensorService: wake called');
  }

  void hibernate() {
    // TODO: Implement hibernate logic if needed
    debugPrint('SensorService: hibernate called');
  }

  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // RedPing Mode overrides
  double? _crashThresholdOverride;
  double? _fallThresholdOverride;
  int? _samplingPeriodOverrideMs;
  PowerMode? _powerModeOverride;

  static const double _testModeCrashThreshold = 78.4; // 8G in m/s²
  static const double _testModeFallThreshold =
      48.0; // ~0.3m drop impact in m/s²

  double _defaultCrashThreshold() {
    return AppConstants.testingModeEnabled ? _testModeCrashThreshold : 180.0;
  }

  double _defaultFallThreshold() {
    return AppConstants.testingModeEnabled ? _testModeFallThreshold : 150.0;
  }

  double _effectiveCrashThreshold() {
    return _crashThresholdOverride ?? _crashThreshold;
  }

  double _effectiveFallThreshold() {
    return _fallThresholdOverride ?? _fallThreshold;
  }

  void _resetThresholdsToDefaults() {
    _crashThreshold = _defaultCrashThreshold();
    _fallThreshold = _defaultFallThreshold();
    _severeImpactThreshold = AppConstants.testingModeEnabled ? 147.0 : 250.0;
    _reapplyThresholdOverridesIfAny();
  }

  void _reapplyThresholdOverridesIfAny() {
    if (_crashThresholdOverride != null) {
      _crashThreshold = _crashThresholdOverride!;
    }
    if (_fallThresholdOverride != null) {
      _fallThreshold = _fallThresholdOverride!;
    }
  }

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _calibrationAccelerometerSubscription;
  Timer? _calibrationTimeoutTimer;

  DateTime? _lastAppOpenCalibrationAttempt;
  static const Duration _appOpenCalibrationThrottle = Duration(seconds: 30);

  final List<SensorReading> _accelerometerBuffer = [];
  final List<SensorReading> _gyroscopeBuffer = [];

  // User-requested flag for sensor upload
  final bool _userRequestedSensorUpload = false;

  bool _isMonitoring = false;
  bool _crashDetectionEnabled =
      true; // ENABLED: Real phone testing with realistic thresholds
  bool _fallDetectionEnabled =
      true; // ENABLED: Real phone testing with realistic thresholds
  bool _isLowPowerMode = true; // Start in low power mode by default

  DateTime? _lastCrashDetection;
  DateTime? _lastFallDetection;
  static const Duration _detectionCooldown = Duration(seconds: 30);

  // Detection thresholds - Based on real-world physics (REALISTIC VALUES)
  // TEST MODE v2.0: Dynamic thresholds adjust based on AppConstants.testingModeEnabled
  // Production: 180 m/s² crash, 150 m/s² fall (60+ km/h crashes, 1.5m+ falls)
  // Test Mode: 78.4 m/s² (8G) crash, 29.4 m/s² (0.3m fall) - Simple shake triggers
  //
  // BLUEPRINT REQUIREMENTS:
  // - Only trigger on >1 meter drops (controlled falls don't count)
  // - Only trigger on >60 km/h crashes (gentle bumps don't count)
  // - Only trigger when BOTH impact AND deceleration detected (sudden stop)
  // - Auto-cancel if motion continues (driving vibrations/bumps)
  //
  // PHYSICS CALCULATIONS:
  // 1 meter fall = √(2×9.8×1) = 4.43 m/s, impact over 0.05s = ~88 m/s²
  // 1.5 meter fall = √(2×9.8×1.5) = 5.42 m/s, impact over 0.05s = ~150 m/s²
  // 0.3m fall (test) = √(2×9.8×0.3) = 2.42 m/s, impact over 0.05s = ~48 m/s²
  // 60 km/h crash = 16.67 m/s sudden stop over 0.1s = ~167 m/s²
  // 80 km/h crash = 22.22 m/s sudden stop over 0.1s = ~222 m/s²
  // 8G shake (test) = 8 × 9.8 = 78.4 m/s²
  //
  // NORMAL PHONE HANDLING (should NOT trigger):
  // - Gentle bump/tap: 10-30 m/s²
  // - Setting down on table: 20-50 m/s²
  // - Throwing on bench: 50-100 m/s²  ← USER ISSUE: False alerts from vigorous handling
  // - Pocket movement: 5-15 m/s²
  // - Walking/running: 10-25 m/s²
  // - Driving vibrations: 15-80 m/s² (brief spikes, no sustained pattern + motion continues)
  // - Pothole/speed bump: 50-120 m/s² (brief impact + motion continues)
  double _crashThreshold =
      180.0; // m/s² - Crashes at 60+ km/h (BLUEPRINT MINIMUM) or TEST: 78.4 m/s² (8G)
  double _fallThreshold =
      150.0; // m/s² - 1.5+ meter falls or TEST: 48 m/s² (0.3m falls)
  double _severeImpactThreshold =
      250.0; // m/s² - 80+ km/h, immediate escalation or TEST: 147 m/s² (15G)
  // Extreme impact classification (captures and escalates instead of rejecting)
  static const double _extremeImpactThreshold =
      300.0; // m/s² - Human survivability limit (~30G). Capture, corroborate, escalate
  final double _phoneDropThreshold =
      120.0; // m/s² - Filter normal phone handling (INCREASED from 100 to filter bench throws)

  // Shake detection pattern for test mode

  // VIOLENT PHONE HANDLING DETECTION (narrow band just below crash)
  // Detects aggressive handling: phone thrown, smashed, or violently handled
  // Narrowed for lab: only trigger extremely high impacts just below crash threshold
  // This keeps silent alerts enabled but avoids triggers from typical lab throws (<= ~175 m/s²)
  final double _violentHandlingThreshold =
      179.5; // m/s² - Narrow band to minimize lab triggers
  final double _violentHandlingMaxThreshold =
      180.0; // m/s² - Below crash threshold (crash handling starts at >= 180)
  final bool _violentHandlingDetectionEnabled = true; // Enable by default

  // Crash detection state - Monitor for motion resume (driving continues)
  DateTime? _potentialCrashTime;
  bool _isPotentialCrashInProgress = false;
  static const Duration _crashVerificationWindow = Duration(
    seconds: 3,
  ); // 3 second window to verify crash
  final List<SensorReading> _postImpactReadings =
      []; // Track movement after impact

  // Fall detection state - Cancel detection when user picks up phone
  DateTime? _fallDetectedTime;
  bool _isFallInProgress = false;
  static const Duration _fallCancellationWindow = Duration(
    seconds: 5,
  ); // 5 second window to cancel

  // Violent phone handling state - Track aggressive handling incidents
  DateTime? _lastViolentHandlingDetection;
  static const Duration _violentHandlingCooldown = Duration(
    minutes: 5,
  ); // 5 min cooldown between alerts
  int _violentHandlingCount = 0; // Count incidents in session
  DateTime? _sessionStartTime;

  // Callbacks
  Function(ImpactInfo)? _onCrashDetected;
  Function(ImpactInfo)? _onFallDetected;
  Function(SensorReading)? _onSensorUpdate;
  Function(ImpactInfo)?
  _onViolentHandlingDetected; // Silent alert to emergency contacts

  // Update throttling - Dynamic based on power mode (blueprint optimized)
  DateTime? _lastUIUpdate;
  DateTime? _lastCrashCheck;

  // Low power mode throttling (background monitoring)
  static const Duration _uiUpdateThrottleLowPower = Duration(
    minutes: 2,
  ); // Drastically reduced
  static const Duration _crashCheckThrottleLowPower = Duration(
    minutes: 5,
  ); // Only severe impacts

  // Active mode throttling (during SOS)
  static const Duration _uiUpdateThrottleActive = Duration(milliseconds: 500);
  static const Duration _crashCheckThrottleActive = Duration(seconds: 1);

  Duration get _currentUIThrottle =>
      _isLowPowerMode ? _uiUpdateThrottleLowPower : _uiUpdateThrottleActive;

  Duration get _currentCrashThrottle =>
      _isLowPowerMode ? _crashCheckThrottleLowPower : _crashCheckThrottleActive;

  // Smart battery saving with motion detection (from ultra battery optimization)
  int _sensorDataBufferSize = 0;
  static const int _maxBufferSize = 50; // Reduced for battery optimization
  int _processingInterval = 1000; // Process every Nth millisecond

  // Motion tracking for smart battery optimization
  double _baselineMagnitude = 9.8; // Earth's gravity
  int _significantMotionCount = 0;
  int _lowGravityCount = 0;
  DateTime? _lastSignificantMotion;

  // Logging optimization - only log state changes
  String _lastLoggedMotionState = "";
  String _lastLoggedStationaryStatus = "";
  int _lastLoggedBatteryLevel = 0;
  double _lastLoggedMagnitude = 0.0;

  // SENSOR CALIBRATION SYSTEM - Convert raw sensor data to real-world movement
  // Problem: Phone sensors are too sensitive - detect every tiny vibration
  // Solution: Start with default real-world patterns, then learn user's specific patterns

  // DEFAULT REAL-WORLD MOVEMENT PATTERNS (Standard Physics-Based Values)
  // Used as baseline until system learns user's specific patterns
  final Map<String, double> _defaultMovementPatterns = {
    'stationary': 9.8, // Phone at rest (gravity only)
    'walking': 12.0, // Normal walking
    'running': 18.0, // Running/jogging
    'sitting_down': 25.0, // Sitting down on chair
    'table_placement': 30.0, // Placing phone on table
    'bench_throw': 80.0, // Throwing phone on bench (vigorous handling)
    'pocket_movement': 15.0, // Phone in pocket while moving
    'car_idle': 11.0, // In car, engine running
    'car_driving': 20.0, // Normal driving (smooth road)
    'car_rough_road': 45.0, // Driving on rough road
    'pothole': 85.0, // Hitting pothole at normal speed
    'speed_bump': 75.0, // Going over speed bump
    'gentle_tap': 40.0, // Gentle tap on phone
    'drop_50cm': 60.0, // Drop from 50cm (pocket height)
    'fall_1m': 100.0, // Fall from 1 meter (below new threshold)
    'fall_1.5m': 150.0, // Fall from 1.5 meters (NEW DETECTION THRESHOLD)
    'crash_60kmh': 180.0, // Car crash at 60 km/h (DETECTION THRESHOLD)
    'crash_80kmh': 250.0, // Car crash at 80 km/h (SEVERE)
  };

  // LEARNED MOVEMENT PATTERNS (Adapts to User's Phone)
  // Starts as copy of defaults, adjusts after learning cycles
  Map<String, double> _learnedMovementPatterns = {};

  // Calibration data (measured when phone is stationary)
  double _calibratedGravity = 9.8; // Will be calibrated on first run
  double _sensorNoiseFactor = 1.0; // Phone-specific noise amplification factor
  bool _isCalibrated = false;

  // Calibration samples for baseline measurement
  final List<double> _calibrationSamples = [];
  static const int _calibrationSampleCount = 100; // 10 seconds at 10Hz
  bool _isCalibrating = false;

  // AUTO-CALIBRATION SETTINGS
  final bool _autoCalibrationEnabled = true; // Enable automatic calibration
  DateTime? _lastCalibrationTime;
  static const Duration _calibrationInterval = Duration(
    days: 7,
  ); // Re-calibrate weekly
  bool _hasRunInitialCalibration =
      false; // Track if we've run startup calibration

  // CONTINUOUS LEARNING SYSTEM - Analyzes user's daily movement patterns
  final List<double> _dailyMovementSamples =
      []; // Collect samples throughout the day
  static const int _dailyLearningBufferSize = 1000; // Keep last 1000 samples
  Timer? _learningTimer; // Periodic learning analysis (runs daily)

  // Learning statistics
  int _movementSamplesCollected = 0;
  int _learningCyclesCompleted = 0;
  DateTime? _lastLearningUpdate;
  static const int _samplesPerLearningCycle =
      1000; // 1000 samples before adjustment

  // Movement pattern buffers for learning (categorized by activity)
  // Reserved for future enhancement: Activity-specific pattern analysis
  // ignore: unused_field
  final Map<String, List<double>> _movementSampleBuffers = {
    'walking': [], // 10-20 m/s² sustained
    'driving': [], // 15-50 m/s² variable
    'stationary': [], // 8-12 m/s² (just gravity)
    'high_impact': [], // >100 m/s² events
  };

  // Movement pattern statistics (learned over time)
  double _averageDailyMovement = 12.0; // Average acceleration during normal use
  // ignore: unused_field
  double _typicalWalkingAcceleration =
      15.0; // Typical walking pattern (reserved for advanced filtering)
  double _typicalDrivingVibration = 20.0; // Typical driving vibration baseline
  int _totalSamplesLearned = 0; // Track how much data we've learned from

  // Conversion formula coefficients (phone sensor → real-world movement)
  // Formula: realWorldAccel = (rawSensor - baseline) * scalingFactor / noiseFactor
  //
  // Example: Phone reports 15 m/s² for gentle tap
  // Real-world: gentle tap is ~20 m/s²
  // Scaling: (15 - 9.8) * 1.0 / 1.2 = 4.3 m/s² (filtered noise)
  //
  // Example: Phone reports 200 m/s² for crash
  // Real-world: 60 km/h crash is ~180 m/s²
  // Scaling: (200 - 9.8) * 0.95 / 1.0 = 180.5 m/s² (accurate)
  double _accelerationScalingFactor =
      1.0; // Adjusts sensitivity (default: 1.0 = no scaling)

  // Device-specific profiles (different phones have different sensor characteristics)
  final Map<String, Map<String, double>> _deviceProfiles = {
    'default': {
      'scalingFactor': 1.0,
      'noiseFactor': 1.0,
      'baselineGravity': 9.8,
    },
    // Add profiles for specific devices as we gather data
    'samsung': {
      'scalingFactor': 0.95, // Samsung sensors tend to over-report
      'noiseFactor': 1.2, // Higher noise in vibrations
      'baselineGravity': 9.8,
    },
    'google_pixel': {
      'scalingFactor': 1.05, // Pixel sensors slightly under-report
      'noiseFactor': 0.9, // Lower noise, cleaner readings
      'baselineGravity': 9.8,
    },
    'iphone': {
      'scalingFactor': 1.0, // Apple sensors well-calibrated
      'noiseFactor': 0.85, // Excellent noise filtering
      'baselineGravity': 9.8,
    },
  };

  // Smart battery optimization - Track sensor reading counter
  int _sensorReadingCounter = 0; // Battery-aware adaptive sampling
  final Battery _battery = Battery();
  int _currentBatteryLevel = 100;
  bool _isCharging = false;
  Timer? _batteryCheckTimer;
  // Power mode switching hysteresis
  DateTime? _lastPowerModeSwitch;
  static const Duration _minModeHold = Duration(seconds: 30);
  // Compact status logging
  String _lastStatusSummary = '';
  DateTime? _lastStatusLogTime;
  static const Duration _statusLogThrottle = Duration(seconds: 30);

  // Smart context awareness
  bool _isLikelySleeping = false;
  bool _isInSafeLocation = false;

  // MOTION-BASED ACTIVATION SYSTEM - Only monitor when moving
  bool _isActivelyMoving = false;
  double? _lastKnownSpeed; // km/h from GPS
  double? _lastKnownAltitude; // meters
  DateTime? _lastMovementDetected;
  Timer? _movementTimeoutTimer;
  static const Duration _movementTimeout = Duration(
    minutes: 5,
  ); // Stop monitoring after 5 min of no movement
  static const double _minimumSpeedThreshold = 5.0; // km/h - walking speed
  static const double _altitudeChangeThreshold =
      10.0; // meters - significant elevation change
  double _deviceTemperature = 25.0; // Celsius

  // AIRPLANE DETECTION SYSTEM - Recognize flight patterns
  bool _isInAirplaneMode = false;
  bool _isPotentialFlight = false;
  double? _flightStartAltitude;
  DateTime? _flightDetectionTime;
  final List<double> _altitudeHistory = []; // Track altitude changes over time
  final List<double> _speedHistory = []; // Track speed changes
  static const int _altitudeHistorySize =
      20; // Keep last 20 readings (10 minutes at 30s intervals)

  // Airplane pattern thresholds
  static const double _cruisingAltitudeMin = 3000.0; // meters (~10,000 feet)
  static const double _cruisingAltitudeMax = 13000.0; // meters (~43,000 feet)
  static const double _climbRateThreshold =
      300.0; // meters/minute - typical airplane climb
  static const double _cruisingSpeedMin =
      400.0; // km/h - minimum cruising speed

  // BOAT DETECTION SYSTEM - Recognize marine vessel patterns
  bool _isOnBoat = false;
  bool _isPotentialBoat = false;
  DateTime? _boatDetectionTime;
  final List<double> _accelerationVarianceHistory =
      []; // Track motion variance (waves)
  static const int _boatPatternSampleSize = 30; // 30 seconds of data

  // Boat pattern thresholds
  static const double _boatSpeedMin = 5.0; // km/h - minimum boat movement
  static const double _boatSpeedMax =
      100.0; // km/h - typical boat speed range (5-100 km/h)
  static const double _boatAltitudeMax =
      100.0; // meters - boats stay at sea level (±100m GPS accuracy)
  static const double _wavyMotionVarianceMin =
      2.0; // m/s² - rhythmic wave pattern variance
  static const double _wavyMotionVarianceMax =
      15.0; // m/s² - not too extreme (would be crash)
  static const Duration _boatVerificationWindow = Duration(
    minutes: 3,
  ); // Verify sustained pattern

  // Stationary state detection (prevents false positives when sitting/resting)
  bool _isUserLikelyStationary = false;
  int _stationaryReadingsCount = 0;
  static const int _stationaryReadingsRequired = 300; // 5 minutes at 1Hz

  // Historical pattern learning
  final Map<String, List<bool>> _historicalMotionPatterns = {};
  Timer? _patternUpdateTimer;

  // ========== PUBLIC CALIBRATION API ==========

  /// Check if sensor is calibrated
  bool get isCalibrated => _isCalibrated;

  /// Check if calibration is in progress
  bool get isCalibrating => _isCalibrating;

  /// Get current calibration status
  Map<String, dynamic> get calibrationStatus => {
    'isCalibrated': _isCalibrated,
    'isCalibrating': _isCalibrating,
    'calibratedGravity': _calibratedGravity,
    'noiseFactor': _sensorNoiseFactor,
    'scalingFactor': _accelerationScalingFactor,
    'sensorQuality': _isCalibrated ? _getSensorQuality() : 'Not calibrated',
    'samplesCollected': _calibrationSamples.length,
    'samplesRequired': _calibrationSampleCount,
    // Learning system status
    'learningEnabled': _autoCalibrationEnabled,
    'learningCycles': _learningCyclesCompleted,
    'totalSamplesLearned': _totalSamplesLearned,
    'lastLearningUpdate': _lastLearningUpdate?.toIso8601String(),
    'learnedPatterns': _learnedMovementPatterns,
    'defaultPatterns': _defaultMovementPatterns,
  };

  // ========== END PUBLIC API ==========

  /// Trigger calibration on app open/resume.
  ///
  /// Requirement: calibration should run at most weekly.
  ///
  /// Behavior:
  /// - If never calibrated: runs calibration.
  /// - If calibrated but older than the configured interval: runs calibration.
  /// - Otherwise: no-op.
  ///
  /// Safety: this runs in background and does NOT pause crash detection.
  void triggerCalibrationOnAppOpen() {
    final last = _lastAppOpenCalibrationAttempt;
    if (last != null &&
        DateTime.now().difference(last) < _appOpenCalibrationThrottle) {
      return;
    }
    _lastAppOpenCalibrationAttempt = DateTime.now();

    if (!_autoCalibrationEnabled) {
      return;
    }

    // Fire-and-forget: never block UI or service startup.
    Future.microtask(() async {
      try {
        await startCalibration();
      } catch (e) {
        debugPrint('SensorService: App-open calibration attempt failed: $e');
      }
    });
  }

  /// Start monitoring sensors for crash and fall detection
  Future<void> startMonitoring({
    LocationService? locationService,
    NotificationService? notificationService,
    bool lowPowerMode = true, // Default to low power mode
  }) async {
    if (_isMonitoring) return;

    // Initialize learned patterns from defaults on first start
    if (_learnedMovementPatterns.isEmpty) {
      _learnedMovementPatterns = Map.from(_defaultMovementPatterns);
      debugPrint(
        '📊 Initialized learned patterns from defaults (${_defaultMovementPatterns.length} patterns)',
      );
    }

    _isLowPowerMode = lowPowerMode;

    // Get initial battery level
    try {
      _currentBatteryLevel = await _battery.batteryLevel;
      debugPrint('SensorService: Battery level: $_currentBatteryLevel%');
    } catch (e) {
      _currentBatteryLevel = 100; // Assume full if can't read
    }

    // Start battery monitoring (check every 5 minutes)
    _batteryCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        final newLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        final wasCharging = _isCharging;

        _isCharging =
            batteryState == BatteryState.charging ||
            batteryState == BatteryState.full;

        // ENHANCEMENT 1: Update sleep state
        _updateSleepState();

        if (newLevel != _currentBatteryLevel || wasCharging != _isCharging) {
          _currentBatteryLevel = newLevel;
          if (kDebugMode) {
            print(
              'SensorService: Battery level updated: $_currentBatteryLevel% (Charging: $_isCharging, Sleeping: $_isLikelySleeping)',
            );
          }

          // Adjust sampling rate if needed
          if (_isMonitoring && _isLowPowerMode) {
            await _adjustSamplingForBattery();
          }
        }
      } catch (e) {
        // Ignore battery read errors
      }
    });

    final samplingRate = _getSamplingRateForBattery();

    // App-open calibration (runs in background, does not block startup).
    // Runs only if calibration is missing/outdated (weekly).
    if (_autoCalibrationEnabled && !_hasRunInitialCalibration) {
      _hasRunInitialCalibration = true;
      Future.delayed(const Duration(seconds: 2), triggerCalibrationOnAppOpen);
    }

    // Apply device-specific sensor profile if not yet calibrated
    if (!_isCalibrated) {
      try {
        // Try to detect device model - this is platform-specific
        // For now, use a placeholder. In production, you'd use device_info_plus package
        _applyDeviceProfile('default');
      } catch (e) {
        debugPrint('SensorService: Could not apply device profile: $e');
      }
    }

    // START CONTINUOUS LEARNING: Analyze movement patterns every hour
    _startContinuousLearning();

    debugPrint(
      'SensorService: Starting monitoring in ${lowPowerMode ? "LOW POWER" : "ACTIVE"} mode (${samplingRate}ms sampling, battery: $_currentBatteryLevel%)',
    );

    try {
      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: Duration(milliseconds: samplingRate),
      ).listen(_handleAccelerometerEvent);

      // Start gyroscope monitoring (optional; some devices do not have one).
      try {
        _gyroscopeSubscription = gyroscopeEventStream(
          samplingPeriod: Duration(milliseconds: samplingRate),
        ).listen(_handleGyroscopeEvent);
      } on PlatformException catch (e) {
        // Example: PlatformException(NO_SENSOR, Sensor not found, ...)
        debugPrint('SensorService: Gyroscope unavailable - $e');
        _gyroscopeSubscription = null;
      } catch (e) {
        debugPrint('SensorService: Gyroscope stream failed - $e');
        _gyroscopeSubscription = null;
      }

      // Optional: Start location tracking for movement/speed heuristics.
      if (locationService != null) {
        try {
          await locationService.startTracking();
          debugPrint(
            'SensorService: Location tracking started for movement detection',
          );
        } catch (e) {
          debugPrint('SensorService: Could not start location tracking - $e');
          // Continue without location tracking - will use accelerometer only
        }
      }

      // Monitor connectivity changes
      ConnectivityMonitorService().offlineStream.listen((isOffline) {
        final sosActive = AppServiceManager().sosService.isSOSActive;
        if (isOffline && (sosActive || _userRequestedSensorUpload)) {
          // Only upload sensor data when offline AND SOS is active or user requests
          _startSensorUpload();
        } else {
          // Stop sensor upload otherwise
          _stopSensorUpload();
        }
      });

      // ENHANCEMENT 3: Check safe location periodically (every 5 minutes)
      Timer.periodic(const Duration(minutes: 5), (timer) {
        _checkSafeLocation();
      });

      // ENHANCEMENT 4: Update motion patterns hourly
      _patternUpdateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        _updateMotionPattern();
      });

      // ENHANCEMENT 5: Monitor device temperature (every 10 minutes)
      Timer.periodic(const Duration(minutes: 10), (timer) {
        _updateDeviceTemperature();
      });

      _isMonitoring = true;
      debugPrint('SensorService: Started monitoring sensors');
    } catch (e) {
      debugPrint('SensorService: Error starting monitoring - $e');
      throw Exception('Failed to start sensor monitoring: $e');
    }
  }

  /// Stop monitoring sensors
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _calibrationTimeoutTimer?.cancel();
    _calibrationTimeoutTimer = null;
    _calibrationAccelerometerSubscription?.cancel();
    _calibrationAccelerometerSubscription = null;
    _batteryCheckTimer?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _batteryCheckTimer = null;
    _isMonitoring = false;
    _clearBuffers();
    debugPrint('SensorService: Stopped monitoring sensors');
  }

  /// Get adaptive sampling rate based on battery level (ultra battery optimization)
  int _getSamplingRateForBattery() {
    // ENHANCEMENT 1: Sleep mode - ultra-low power (11pm - 7am)
    if (_isLikelySleeping) {
      return 10000; // 0.1 Hz - only check for major impacts during sleep
    }

    // RedPing Mode: power/interval overrides (applied after sleep shortcut)
    if (_powerModeOverride == PowerMode.high) {
      final forced = AppConstants.sensorSamplingRateActiveMs;
      if (_samplingPeriodOverrideMs != null) {
        return _samplingPeriodOverrideMs!.clamp(50, 10000);
      }
      return forced;
    }

    if (!_isLowPowerMode) {
      // Active mode (SOS): Always high frequency
      if (_samplingPeriodOverrideMs != null) {
        return _samplingPeriodOverrideMs!.clamp(50, 10000);
      }
      return AppConstants.sensorSamplingRateActiveMs; // 100ms = 10Hz
    }

    // ENHANCEMENT 2: Charging mode - higher frequency when plugged in
    if (_isCharging && _currentBatteryLevel > 80) {
      return 200; // 5 Hz - better monitoring with no battery penalty
    }

    // ENHANCEMENT 3: Safe location (home WiFi) - reduce frequency
    if (_isInSafeLocation && !_isInSignificantMotion()) {
      if (_currentBatteryLevel >= 50) {
        return 1000; // 1 Hz (vs 2 Hz)
      } else if (_currentBatteryLevel >= 25) {
        return 2000; // 0.5 Hz (vs 1 Hz)
      } else {
        return 5000; // 0.2 Hz (same as critical)
      }
    }

    // Standard low power mode: Adaptive based on battery
    int rate;
    if (_currentBatteryLevel >= 50) {
      rate = 500; // 2 Hz - Good battery
    } else if (_currentBatteryLevel >= 25) {
      rate = 1000; // 1 Hz - Medium battery
    } else if (_currentBatteryLevel >= 15) {
      rate = 2000; // 0.5 Hz - Low battery
    } else {
      rate = 5000; // 0.2 Hz - Critical battery
    }

    // RedPing Mode: monitoring interval override is treated as a minimum period
    // for low-power monitoring.
    if (_samplingPeriodOverrideMs != null) {
      rate = max(rate, _samplingPeriodOverrideMs!);
    }

    // RedPing Mode: enforce low power preference
    if (_powerModeOverride == PowerMode.low) {
      rate = max(rate, 1000);
    }

    return rate;
  }

  /// Adjust sampling rate based on current battery level
  Future<void> _adjustSamplingForBattery() async {
    if (!_isMonitoring || !_isLowPowerMode) return;

    debugPrint(
      'SensorService: Adjusting sampling rate for battery level: $_currentBatteryLevel%',
    );

    // Restart monitoring with new sampling rate
    stopMonitoring();
    await Future.delayed(const Duration(milliseconds: 100));
    await startMonitoring(lowPowerMode: true);
  }

  /// Switch to active mode (high frequency sampling during SOS)
  Future<void> setActiveMode() async {
    if (!_isMonitoring) return;
    if (!_isLowPowerMode) return; // Already in active mode

    debugPrint('SensorService: Switching to ACTIVE mode for SOS');
    _isLowPowerMode = false;

    // Restart monitoring with active sampling rate
    stopMonitoring();
    await startMonitoring(lowPowerMode: false);
  }

  /// Switch to low power mode (reduced sampling for background monitoring)
  Future<void> setLowPowerMode() async {
    if (!_isMonitoring) return;
    if (_isLowPowerMode) return; // Already in low power mode

    debugPrint('SensorService: Switching to LOW POWER mode');
    _isLowPowerMode = true;

    // Restart monitoring with low power sampling rate
    stopMonitoring();
    await startMonitoring(lowPowerMode: true);
  }

  // ========== SENSOR CALIBRATION METHODS ==========

  /// Start automatic calibration - measures baseline when phone is stationary
  /// Call this when app starts or when user is in a safe, stationary location
  Future<void> startCalibration({bool force = false}) async {
    if (_isCalibrating) {
      debugPrint('SensorService: Calibration already in progress');
      return;
    }

    if (!force && !_shouldRunCalibration()) {
      return;
    }

    // Cancel any previous calibration attempt.
    await _calibrationAccelerometerSubscription?.cancel();
    _calibrationTimeoutTimer?.cancel();

    _isCalibrating = true;
    _calibrationSamples.clear();

    debugPrint(
      'SensorService: Starting sensor calibration - Keep phone still for 10 seconds...',
    );

    // Important: do NOT rely on the monitoring sampling rate (can be 1Hz+ in low power).
    // Use a dedicated short-lived calibration stream at ~10Hz.
    const calibrationSampling = Duration(milliseconds: 100);
    const stationaryMin = 7.5;
    const stationaryMax = 12.5;

    final completer = Completer<void>();

    _calibrationTimeoutTimer = Timer(const Duration(seconds: 15), () async {
      await _calibrationAccelerometerSubscription?.cancel();
      _calibrationAccelerometerSubscription = null;
      if (_calibrationSamples.length >= _calibrationSampleCount) {
        _completeCalibration();
      } else {
        debugPrint(
          'SensorService: Calibration failed - not enough stationary samples (${_calibrationSamples.length}/$_calibrationSampleCount)',
        );
        _isCalibrating = false;
        _calibrationSamples.clear();
      }
      if (!completer.isCompleted) completer.complete();
    });

    _calibrationAccelerometerSubscription =
        accelerometerEventStream(samplingPeriod: calibrationSampling).listen(
          (event) async {
            if (!_isCalibrating) return;
            if (!_isValidSensorReading(event.x, event.y, event.z)) {
              return;
            }

            final magnitude = sqrt(
              (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
            );

            // Only accept samples that look stationary (gravity-only).
            if (magnitude < stationaryMin || magnitude > stationaryMax) {
              return;
            }

            if (_calibrationSamples.length < _calibrationSampleCount) {
              _calibrationSamples.add(magnitude);
              if (_calibrationSamples.length == 1 ||
                  _calibrationSamples.length == 50 ||
                  _calibrationSamples.length >= 95) {
                debugPrint(
                  'SensorService: Calibration progress: ${_calibrationSamples.length}/$_calibrationSampleCount samples',
                );
              }
            }

            if (_calibrationSamples.length >= _calibrationSampleCount) {
              await _calibrationAccelerometerSubscription?.cancel();
              _calibrationAccelerometerSubscription = null;
              _calibrationTimeoutTimer?.cancel();
              _calibrationTimeoutTimer = null;
              _completeCalibration();
              if (!completer.isCompleted) completer.complete();
            }
          },
          onError: (e) async {
            debugPrint('SensorService: Calibration stream error: $e');
            await _calibrationAccelerometerSubscription?.cancel();
            _calibrationAccelerometerSubscription = null;
            _calibrationTimeoutTimer?.cancel();
            _calibrationTimeoutTimer = null;
            _isCalibrating = false;
            _calibrationSamples.clear();
            if (!completer.isCompleted) completer.complete();
          },
        );

    await completer.future;
  }

  /// Complete calibration and calculate baseline + noise factor
  void _completeCalibration() {
    if (_calibrationSamples.isEmpty) return;

    // Calculate average magnitude (should be close to 9.8 m/s² for stationary phone)
    final sum = _calibrationSamples.reduce((a, b) => a + b);
    _calibratedGravity = sum / _calibrationSamples.length;

    // Calculate standard deviation (noise factor)
    final variance =
        _calibrationSamples
            .map((s) => pow(s - _calibratedGravity, 2))
            .reduce((a, b) => a + b) /
        _calibrationSamples.length;
    final stdDev = sqrt(variance);

    // Reject clearly non-stationary calibration windows (prevents corrupting calibration)
    if (_calibratedGravity < 8.0 || _calibratedGravity > 12.0 || stdDev > 1.5) {
      debugPrint(
        'SensorService: Calibration rejected (not stationary). avg=${_calibratedGravity.toStringAsFixed(2)} std=${stdDev.toStringAsFixed(2)}',
      );
      _isCalibrating = false;
      _calibrationSamples.clear();
      return;
    }

    // Noise factor: how much the sensor fluctuates when stationary
    // Higher value = noisier sensor = need more filtering
    _sensorNoiseFactor = 1.0 + (stdDev / _calibratedGravity);

    // Adjust scaling factor based on how far baseline is from ideal 9.8 m/s²
    // If phone reports 10.2 m/s² at rest, scaling should be 9.8/10.2 = 0.96
    _accelerationScalingFactor = 9.8 / _calibratedGravity;

    _isCalibrated = true;
    _isCalibrating = false;
    _lastCalibrationTime =
        DateTime.now(); // Record when calibration was completed
    _baselineMagnitude = _calibratedGravity; // Update baseline

    debugPrint('SensorService: ✅ Calibration complete!');
    debugPrint(
      '  - Calibrated gravity: ${_calibratedGravity.toStringAsFixed(2)} m/s²',
    );
    debugPrint('  - Noise factor: ${_sensorNoiseFactor.toStringAsFixed(3)}');
    debugPrint(
      '  - Scaling factor: ${_accelerationScalingFactor.toStringAsFixed(3)}',
    );
    debugPrint('  - Sensor quality: ${_getSensorQuality()}');

    _calibrationSamples.clear();
  }

  /// Get sensor quality rating based on noise factor
  String _getSensorQuality() {
    if (_sensorNoiseFactor < 1.05) return 'Excellent (Low noise)';
    if (_sensorNoiseFactor < 1.15) return 'Good (Moderate noise)';
    if (_sensorNoiseFactor < 1.30) return 'Fair (High noise)';
    return 'Poor (Very noisy - may cause false alarms)';
  }

  /// Convert raw sensor reading to real-world acceleration
  /// This is the CRITICAL FORMULA that makes crash detection work accurately
  ///
  /// Formula: realWorldAccel = (rawSensor - calibratedBaseline) * scalingFactor / noiseFactor
  ///
  /// Example 1: Gentle tap on phone
  ///   - Raw sensor: 15 m/s²
  ///   - Baseline: 10.2 m/s² (phone at rest)
  ///   - Scaling: 0.96
  ///   - Noise: 1.15
  ///   - Result: (15 - 10.2) * 0.96 / 1.15 = 4.0 m/s² (filtered correctly as gentle tap)
  ///
  /// Example 2: 60 km/h crash
  ///   - Raw sensor: 210 m/s²
  ///   - Baseline: 10.2 m/s²
  ///   - Scaling: 0.96
  ///   - Noise: 1.15
  ///   - Result: (210 - 10.2) * 0.96 / 1.15 = 167 m/s² (accurately detected as 60 km/h crash)
  ///
  /// Example 3: Pothole bump while driving
  ///   - Raw sensor: 95 m/s²
  ///   - Baseline: 10.2 m/s²
  ///   - Scaling: 0.96
  ///   - Noise: 1.15
  ///   - Result: (95 - 10.2) * 0.96 / 1.15 = 71 m/s² (correctly filtered, below 180 m/s² crash threshold)
  double _convertToRealWorldAcceleration(double rawMagnitude) {
    if (!_isCalibrated) {
      // If not calibrated, use default conversion (no scaling)
      return rawMagnitude;
    }

    // Apply calibration formula
    final calibrated =
        (rawMagnitude - _calibratedGravity) *
        _accelerationScalingFactor /
        _sensorNoiseFactor;

    // Add back baseline gravity (9.8 m/s²) to get absolute magnitude
    final realWorld = calibrated + 9.8;

    // Ensure non-negative
    return realWorld.clamp(0.0, 1000.0);
  }

  /// Apply device-specific profile if available
  void _applyDeviceProfile(String deviceModel) {
    final modelLower = deviceModel.toLowerCase();
    String profileKey = 'default';

    if (modelLower.contains('samsung') || modelLower.contains('galaxy')) {
      profileKey = 'samsung';
    } else if (modelLower.contains('pixel')) {
      profileKey = 'google_pixel';
    } else if (modelLower.contains('iphone') || modelLower.contains('ios')) {
      profileKey = 'iphone';
    }

    final profile = _deviceProfiles[profileKey]!;
    _accelerationScalingFactor = profile['scalingFactor']!;
    _sensorNoiseFactor = profile['noiseFactor']!;
    _baselineMagnitude = profile['baselineGravity']!;

    debugPrint('SensorService: Applied device profile: $profileKey');
    debugPrint('  - Scaling: ${_accelerationScalingFactor.toStringAsFixed(3)}');
    debugPrint('  - Noise: ${_sensorNoiseFactor.toStringAsFixed(3)}');
  }

  // ========== AUTO-CALIBRATION & CONTINUOUS LEARNING ==========

  /// Check if auto-calibration should run
  bool _shouldRunCalibration() {
    // Run on first launch (never calibrated)
    if (!_isCalibrated) {
      debugPrint('SensorService: First launch - calibration needed');
      return true;
    }

    // Check if calibration is outdated
    if (_isCalibrationOutdated()) {
      debugPrint('SensorService: Calibration outdated - re-calibration needed');
      return true;
    }

    return false;
  }

  /// Check if calibration is outdated (older than 7 days)
  bool _isCalibrationOutdated() {
    if (_lastCalibrationTime == null) return true;

    final daysSinceCalibration = DateTime.now().difference(
      _lastCalibrationTime!,
    );
    return daysSinceCalibration > _calibrationInterval;
  }

  /// Start continuous learning from user's movement patterns
  void _startContinuousLearning() {
    if (_learningTimer != null) {
      _learningTimer!.cancel();
    }

    debugPrint('SensorService: 🧠 Starting continuous learning system');
    debugPrint('  - Will analyze movement patterns every hour');
    debugPrint('  - Learns from $_dailyLearningBufferSize samples');

    // Analyze movement patterns every hour
    _learningTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _analyzeMovementPatterns();
    });

    // Also analyze at end of day (midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = midnight.difference(now);

    Timer(timeUntilMidnight, () {
      _analyzeDailyPatterns();
      // Schedule daily analysis
      Timer.periodic(const Duration(days: 1), (_) {
        _analyzeDailyPatterns();
      });
    });
  }

  /// Collect movement sample for continuous learning
  void _collectLearningData(double magnitude) {
    // Skip if calibrating or if magnitude is unrealistic
    if (_isCalibrating || magnitude > 300.0 || magnitude < 0.1) {
      return;
    }

    // Add to daily samples
    _dailyMovementSamples.add(magnitude);

    // Keep buffer size manageable (FIFO - remove oldest)
    if (_dailyMovementSamples.length > _dailyLearningBufferSize) {
      _dailyMovementSamples.removeAt(0);
    }

    _totalSamplesLearned++;
  }

  /// Analyze movement patterns hourly
  void _analyzeMovementPatterns() {
    if (_dailyMovementSamples.length < 100) {
      debugPrint(
        'SensorService: Not enough data for pattern analysis (${_dailyMovementSamples.length} samples)',
      );
      return;
    }

    // Calculate statistics
    final sum = _dailyMovementSamples.reduce((a, b) => a + b);
    final avg = sum / _dailyMovementSamples.length;

    // Identify typical patterns (walking, driving, stationary)
    final stationarySamples = _dailyMovementSamples
        .where((s) => s >= 8.0 && s < 12.0)
        .toList();
    final walkingSamples = _dailyMovementSamples
        .where((s) => s >= 12.0 && s < 30.0)
        .toList();
    final drivingSamples = _dailyMovementSamples
        .where((s) => s >= 30.0 && s < 100.0)
        .toList();

    // Update learned patterns based on collected data
    if (stationarySamples.isNotEmpty) {
      final avgStationary =
          stationarySamples.reduce((a, b) => a + b) / stationarySamples.length;
      // Gradually update learned pattern (80% old, 20% new)
      _learnedMovementPatterns['stationary'] =
          (_learnedMovementPatterns['stationary']! * 0.8) +
          (avgStationary * 0.2);
    }

    if (walkingSamples.isNotEmpty) {
      final avgWalking =
          walkingSamples.reduce((a, b) => a + b) / walkingSamples.length;
      _typicalWalkingAcceleration = avgWalking;
      // Update learned walking pattern
      _learnedMovementPatterns['walking'] =
          (_learnedMovementPatterns['walking']! * 0.8) + (avgWalking * 0.2);
    }

    if (drivingSamples.isNotEmpty) {
      final avgDriving =
          drivingSamples.reduce((a, b) => a + b) / drivingSamples.length;
      _typicalDrivingVibration = avgDriving;
      // Update learned driving pattern
      _learnedMovementPatterns['car_driving'] =
          (_learnedMovementPatterns['car_driving']! * 0.8) + (avgDriving * 0.2);
    }

    _averageDailyMovement = avg;
    _movementSamplesCollected += _dailyMovementSamples.length;

    // Increment learning cycle counter every 1000 samples
    if (_movementSamplesCollected >= _samplesPerLearningCycle) {
      _learningCyclesCompleted++;
      _lastLearningUpdate = DateTime.now();
      _movementSamplesCollected = 0; // Reset for next cycle

      debugPrint(
        'SensorService: 🎓 Learning cycle $_learningCyclesCompleted completed!',
      );
    }

    debugPrint('SensorService: 📊 Pattern analysis complete');
    debugPrint(
      '  - Average movement: ${_averageDailyMovement.toStringAsFixed(1)} m/s²',
    );
    debugPrint(
      '  - Learned stationary: ${_learnedMovementPatterns['stationary']!.toStringAsFixed(1)} m/s²',
    );
    debugPrint(
      '  - Learned walking: ${_learnedMovementPatterns['walking']!.toStringAsFixed(1)} m/s²',
    );
    debugPrint(
      '  - Learned driving: ${_learnedMovementPatterns['car_driving']!.toStringAsFixed(1)} m/s²',
    );
    debugPrint(
      '  - Total samples: $_totalSamplesLearned (Cycles: $_learningCyclesCompleted)',
    );

    // Auto-adjust thresholds based on learned patterns (subtle adjustments only)
    _adjustThresholdsFromLearning();
  }

  /// Analyze daily patterns at end of day
  void _analyzeDailyPatterns() {
    debugPrint('SensorService: 📅 Daily pattern analysis');
    _analyzeMovementPatterns();

    // Clear daily buffer for next day
    _dailyMovementSamples.clear();

    // Check if re-calibration is needed
    if (_isCalibrationOutdated() && _autoCalibrationEnabled) {
      debugPrint(
        'SensorService: Weekly calibration due - scheduling background calibration',
      );
      // Schedule calibration for next stationary period (detected automatically)
    }
  }

  /// Adjust detection thresholds based on learned movement patterns
  /// This makes the system smarter over time
  void _adjustThresholdsFromLearning() {
    // IMPORTANT: Only make subtle adjustments, never deviate from blueprint requirements
    // Crash threshold MUST stay at 180 m/s² minimum (60 km/h requirement)
    // Fall threshold MUST stay at 100 m/s² minimum (1 meter requirement)

    // Calculate noise factor from typical driving vibrations
    // If user's typical driving shows 25 m/s² vibrations, we know what's "normal"
    if (_typicalDrivingVibration > 20.0 && _typicalDrivingVibration < 80.0) {
      // Update noise factor slightly based on learned driving pattern
      final learnedNoiseFactor = _typicalDrivingVibration / 20.0;

      // Blend with existing noise factor (70% old, 30% new - gradual learning)
      _sensorNoiseFactor =
          (_sensorNoiseFactor * 0.7) + (learnedNoiseFactor * 0.3);

      debugPrint(
        'SensorService: 🎯 Adjusted noise factor to ${_sensorNoiseFactor.toStringAsFixed(3)} based on driving patterns',
      );
    }

    // Update baseline gravity if average stationary reading has shifted
    if (_averageDailyMovement > 8.0 && _averageDailyMovement < 12.0) {
      // Blend baseline (90% old, 10% new - very gradual)
      _calibratedGravity =
          (_calibratedGravity * 0.9) + (_averageDailyMovement * 0.1);

      debugPrint(
        'SensorService: 🎯 Adjusted baseline to ${_calibratedGravity.toStringAsFixed(2)} m/s²',
      );
    }

    // Initialize thresholds based on test mode setting (TEST MODE v2.0)
    // Avoid AppConstants.getCrashThreshold/getFallThreshold here because those
    // values are not expressed in the same units used by SensorService.
    if (_crashThresholdOverride == null) {
      _crashThreshold = _defaultCrashThreshold();
    }
    if (_fallThresholdOverride == null) {
      _fallThreshold = _defaultFallThreshold();
    }
    _severeImpactThreshold = AppConstants.testingModeEnabled
        ? 147.0
        : 250.0; // 15G test vs 80+ km/h production
  }

  // ========== END AUTO-CALIBRATION & LEARNING ==========

  // ========== END CALIBRATION METHODS ==========

  /// Handle accelerometer events - Smart Battery Optimization
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Validate sensor data to prevent extreme values
    if (!_isValidSensorReading(event.x, event.y, event.z)) {
      return; // Silent skip for invalid readings
    }

    final reading = SensorReading(
      timestamp: DateTime.now(),
      x: event.x,
      y: event.y,
      z: event.z,
      sensorType: 'accelerometer',
    );

    final rawMagnitude = reading.magnitude;

    // CONVERT RAW SENSOR DATA TO REAL-WORLD ACCELERATION
    // This is the critical step that makes crash detection accurate
    final magnitude = _isCalibrated
        ? _convertToRealWorldAcceleration(rawMagnitude)
        : rawMagnitude; // Use raw if not calibrated yet

    // CONTINUOUS LEARNING: Collect movement data for pattern analysis
    // This helps the system learn user's typical movement patterns
    _collectLearningData(magnitude);

    // ENHANCED LOGGING: Show sensor readings every 2 seconds for driving test validation
    _sensorReadingCounter++;
    if (_sensorReadingCounter % 4 == 0 && _isCalibrated) {
      final stationaryStatus = _isUserLikelyStationary
          ? "STATIONARY"
          : "ACTIVE";

      // Add motion state indicator for driving detection
      String motionState = "";
      if (magnitude > 16.0) {
        motionState = "🚗 DRIVING";
      } else if (magnitude > 15.0) {
        motionState = "🚶 MOVING";
      } else if (magnitude > 11.5) {
        motionState = "⚠️ IDLE";
      } else {
        motionState = "📍 STILL";
      }

      // Only log if there's a significant change to reduce terminal spam
      final magnitudeChanged =
          (magnitude - _lastLoggedMagnitude).abs() > 2.0; // 2 m/s² threshold
      final stateChanged =
          motionState != _lastLoggedMotionState ||
          stationaryStatus != _lastLoggedStationaryStatus;
      final batteryChanged = _currentBatteryLevel != _lastLoggedBatteryLevel;

      if (stateChanged || batteryChanged || magnitudeChanged) {
        debugPrint(
          'SensorService: 📊 Accel: ${magnitude.toStringAsFixed(1)} m/s² | $motionState | Status: $stationaryStatus | Battery: $_currentBatteryLevel%',
        );

        // Update last logged values
        _lastLoggedMotionState = motionState;
        _lastLoggedStationaryStatus = stationaryStatus;
        _lastLoggedBatteryLevel = _currentBatteryLevel;
        _lastLoggedMagnitude = magnitude;
      }
    }

    // EXTREME IMPACT HANDLING (≥300 m/s²)
    // Instead of rejecting as malfunction, capture and escalate with sustained-pattern corroboration.
    if (magnitude >= _extremeImpactThreshold && _crashDetectionEnabled) {
      _addToBuffer(_accelerometerBuffer, reading);
      // Require sustained pattern to avoid single-sample glitches
      if (_hasSustainedHighImpactPattern()) {
        _handleExtremeImpact(reading);
      } else {
        // Log once a minute to avoid spam, but keep a forensic trail
        final now = DateTime.now();
        if (_lastUIUpdate == null ||
            now.difference(_lastUIUpdate!) > const Duration(minutes: 1)) {
          debugPrint(
            'SensorService: Extreme impact spike ${magnitude.toStringAsFixed(1)} m/s² detected but NOT sustained - logged for forensics',
          );
          _lastUIUpdate = now;
        }
      }
      return; // Extreme path fully handled
    }

    // TIER 1: SEVERE IMPACT - Immediate escalation for extreme crashes (>250 m/s² = 80+ km/h)
    // Only trigger if sustained (not a brief sensor spike)
    if (magnitude > _severeImpactThreshold && _crashDetectionEnabled) {
      _addToBuffer(_accelerometerBuffer, reading);
      // Require sustained pattern before triggering severe impact
      if (_hasSustainedHighImpactPattern()) {
        _handleSevereImpact(reading);
      }
      return;
    }

    // TIER 2: SIGNIFICANT IMPACT - Crash threshold (>180 m/s² = 60+ km/h)
    // TEST MODE v2.0: Uses lowered threshold (8G = 78.4 m/s²) while maintaining identical behavior
    // Require sustained pattern to avoid false positives from sensor spikes
    final currentCrashThreshold = _effectiveCrashThreshold();
    if (magnitude > currentCrashThreshold) {
      _addToBuffer(_accelerometerBuffer, reading);

      // Log sensor sample if in test mode (note: gyro values not available in this handler)
      if (AppConstants.testingModeEnabled) {
        TestModeDiagnosticService().logSensorSample(
          accelX: reading.x,
          accelY: reading.y,
          accelZ: reading.z,
          gyroX: 0.0, // Not available in accelerometer-only handler
          gyroY: 0.0,
          gyroZ: 0.0,
          magnitude: magnitude,
          jerk: 0.0, // Would need historical data to calculate
        );
      }

      if (_crashDetectionEnabled) {
        _checkForCrash(reading);
      }
      return;
    }

    // TIER 2.5: VIOLENT PHONE HANDLING - Aggressive throw/smash (100-180 m/s²)
    // Between normal handling (30-50 m/s²) and crash detection (180+ m/s²)
    // Silent alert to emergency contacts only (no user notification)
    if (magnitude >= _violentHandlingThreshold &&
        magnitude < _violentHandlingMaxThreshold) {
      _addToBuffer(_accelerometerBuffer, reading);
      if (_violentHandlingDetectionEnabled) {
        _checkForViolentHandling(reading);
      }
      // Continue processing (don't return) - check for falls too
    }

    // TIER 3: LOW POWER MODE - Smart selective processing
    if (_isLowPowerMode) {
      // Increment counter for selective processing
      _sensorReadingCounter++;

      // Update motion tracking on every reading (lightweight)
      _updateMotionTracking(magnitude);

      // Smart decision: Should we process this reading?
      final shouldProcess = _shouldProcessSensorData(reading, magnitude);

      if (!shouldProcess) {
        // Skip processing to save battery
        // Only process every Nth reading OR when motion detected
        if (_sensorReadingCounter % _processingInterval != 0) {
          return;
        }
      }

      // If we reach here, this reading is worth processing
      _addToBuffer(_accelerometerBuffer, reading);
      _sensorDataBufferSize++;

      // Trim buffer if too large (memory optimization)
      if (_sensorDataBufferSize > _maxBufferSize) {
        if (_accelerometerBuffer.isNotEmpty) {
          _accelerometerBuffer.removeAt(0);
          _sensorDataBufferSize--;
        }
      }

      // Only update UI occasionally in low power mode
      final now = DateTime.now();
      if (_lastUIUpdate == null ||
          now.difference(_lastUIUpdate!) > _currentUIThrottle) {
        _onSensorUpdate?.call(reading);
        _lastUIUpdate = now;
      }

      return;
    }

    // TIER 4: ACTIVE MODE - Full monitoring (SOS active)
    _addToBuffer(_accelerometerBuffer, reading);
    _sensorDataBufferSize++;

    // Trim buffer if too large
    if (_sensorDataBufferSize > _maxBufferSize) {
      if (_accelerometerBuffer.isNotEmpty) {
        _accelerometerBuffer.removeAt(0);
        _sensorDataBufferSize--;
      }
    }

    // Throttled UI updates in active mode
    final now = DateTime.now();
    if (_lastUIUpdate == null ||
        now.difference(_lastUIUpdate!) > _currentUIThrottle) {
      _onSensorUpdate?.call(reading);
      _lastUIUpdate = now;
    }

    // If a potential crash verification is in progress, continue feeding
    // the verification window with every reading regardless of current magnitude.
    // This allows motion-resume checks and the 3s stop verification to complete.
    if (_isPotentialCrashInProgress && _crashDetectionEnabled) {
      _checkForCrash(reading);
    }

    // Fall detection in active mode
    if (_fallDetectionEnabled) {
      _checkForFall(reading);
    }

    // Evaluate power mode based on recent motion
    _maybeAdjustPowerMode(magnitude: magnitude);
  }

  /// Update motion tracking (lightweight, always runs)
  void _updateMotionTracking(double magnitude) {
    // Track baseline magnitude (gravity + normal movement)
    _baselineMagnitude = (_baselineMagnitude * 0.95) + (magnitude * 0.05);

    // Motion Detection Thresholds (physics-based):
    // Gravity alone = 9.8 m/s²
    // Phone on desk/stationary = 8-11 m/s² (gravity + sensor noise)
    // Car stopped/engine idle = 11-14 m/s² (engine vibrations, desk vibrations)
    // Walking/slow movement = 14-16 m/s²
    // Driving (moving car) = 16-30 m/s² (road vibrations + acceleration)
    // Running = 18-25 m/s²

    // Use 15.0 m/s² threshold to distinguish actual movement from stationary vibrations
    if (magnitude > 15.0) {
      // Clear movement detected (walking, driving, running)
      _significantMotionCount++;
      _lastSignificantMotion = DateTime.now();

      if (_isUserLikelyStationary) {
        // Just transitioned from STATIONARY to ACTIVE
        debugPrint(
          'SensorService: 🚗 Movement detected (${magnitude.toStringAsFixed(1)} m/s²) - resuming crash detection',
        );
      }

      // Reset stationary tracking completely
      _stationaryReadingsCount = 0;
      _isUserLikelyStationary = false;
    } else if (magnitude > 11.5 && magnitude <= 15.0) {
      // Ambiguous range (engine vibration, light movement, desk vibrations)
      // Decay stationary counter very slowly to prevent false triggers
      if (_stationaryReadingsCount > 50) {
        _stationaryReadingsCount = max(0, _stationaryReadingsCount - 1);
      }
      _significantMotionCount = max(0, _significantMotionCount - 1);
    } else {
      // Low motion - likely stationary
      _significantMotionCount = max(0, _significantMotionCount - 1);

      // Track stationary state (low motion for extended period)
      // Only count as stationary if magnitude is very close to gravity (8-11.5 m/s²)
      if (magnitude >= 8.0 && magnitude <= 11.5) {
        // Phone appears stable (just gravity, no significant movement)
        _stationaryReadingsCount++;

        // Check if user has been stationary long enough (5 minutes)
        if (_stationaryReadingsCount >= _stationaryReadingsRequired) {
          if (!_isUserLikelyStationary) {
            _isUserLikelyStationary = true;
            debugPrint(
              'SensorService: 💤 User appears stationary (5+ minutes) - crash detection paused',
            );
          }
        }
      }
    }

    // Detect height changes (free fall pattern)
    if (magnitude < 8.0) {
      _lowGravityCount++;
      // Free fall detected - user likely moving, not stationary
      if (_lowGravityCount > 5) {
        _stationaryReadingsCount = 0;
        _isUserLikelyStationary = false;
      }
    } else {
      _lowGravityCount = max(0, _lowGravityCount - 1);
    }
  }

  /// Smart decision: Should we process this sensor reading? (Battery optimization)
  bool _shouldProcessSensorData(SensorReading reading, double magnitude) {
    // ✅ ALWAYS process if in significant motion (vehicle movement)
    if (_isInSignificantMotion()) {
      return true;
    }

    // ✅ ALWAYS process if detecting height changes (fall detection)
    if (_isHeightChanging()) {
      return true;
    }

    // ✅ ALWAYS process if sudden acceleration change (potential impact)
    if (_isSuddenAccelerationChange(magnitude)) {
      return true;
    }

    // ✅ Process occasionally even when stationary (safety check)
    // Every 10th reading = 5 seconds at 2Hz in low power mode
    if (_sensorReadingCounter % _processingInterval == 0) {
      return true;
    }

    // ❌ Otherwise: Skip processing to save battery (stationary, no motion)
    return false;
  }

  /// Check if device is in significant motion (vehicle movement detected)
  bool _isInSignificantMotion() {
    // Significant motion if:
    // - Multiple consecutive readings > 12.0 m/s²
    // - Or recent motion detected within last 10 seconds
    if (_significantMotionCount >= 3) return true;

    if (_lastSignificantMotion != null) {
      final timeSinceMotion = DateTime.now().difference(
        _lastSignificantMotion!,
      );
      if (timeSinceMotion < const Duration(seconds: 10)) {
        return true;
      }
    }

    return false;
  }

  /// Check if height is changing (free fall pattern for fall detection)
  bool _isHeightChanging() {
    // Height change detected if multiple readings show low gravity
    // (>30% of recent readings below 8.0 m/s²)
    return _lowGravityCount >= 6;
  }

  /// Check for sudden acceleration change (potential impact starting)
  bool _isSuddenAccelerationChange(double magnitude) {
    // Sudden change if magnitude >50% above baseline
    final threshold = _baselineMagnitude * 1.5;
    return magnitude > threshold && magnitude > 12.0;
  }

  /// Handle severe impact that triggers immediate escalation (>250 m/s² = 80+ km/h crash)
  /// CRITICAL: Still requires sustained pattern to avoid sensor glitches
  void _handleSevereImpact(SensorReading reading) {
    final now = DateTime.now();

    // CRITICAL: Convert raw sensor magnitude to real-world acceleration
    final magnitude = _convertToRealWorldAcceleration(reading.magnitude);

    // Check cooldown to prevent multiple rapid detections
    if (_lastCrashDetection != null &&
        now.difference(_lastCrashDetection!) < _detectionCooldown) {
      return;
    }

    // CRITICAL VALIDATION: Even for severe impacts, require sustained pattern
    // This prevents sensor glitches/spikes from triggering false alarms
    // A real 80+ km/h crash will maintain high forces over multiple readings
    if (!_hasSustainedHighImpactPattern()) {
      debugPrint(
        'SensorService: Severe impact spike detected (${magnitude.toStringAsFixed(1)} m/s²) but NOT sustained - sensor glitch, ignoring',
      );
      return;
    }

    // Note: ≥300 m/s² is processed by the Extreme Impact path before reaching here.

    _lastCrashDetection = now;

    // Immediate emergency response for severe sustained impacts
    final impactInfo = _calculateImpactInfo(
      _accelerometerBuffer,
      ImpactSeverity.critical,
      'severe_impact_80kmh_sustained_immediate_escalation',
    );

    debugPrint(
      'SensorService: SEVERE SUSTAINED IMPACT DETECTED! Magnitude: ${magnitude.toStringAsFixed(2)} m/s² - 80+ km/h crash, immediate escalation',
    );
    _onCrashDetected?.call(impactInfo);
  }

  /// Handle extreme impact (≥300 m/s²): capture, corroborate, and escalate
  /// Treated as critical once sustained pattern confirmed
  void _handleExtremeImpact(SensorReading reading) {
    final now = DateTime.now();

    // Convert to real-world acceleration for consistent reporting
    final magnitude = _convertToRealWorldAcceleration(reading.magnitude);

    // Cooldown to avoid duplicate detections
    if (_lastCrashDetection != null &&
        now.difference(_lastCrashDetection!) < _detectionCooldown) {
      return;
    }

    // Sustained pattern already checked at call site; proceed
    _lastCrashDetection = now;

    final impactInfo = _calculateImpactInfo(
      _accelerometerBuffer,
      ImpactSeverity.critical,
      'extreme_impact_30g_plus_immediate_escalation',
    );

    debugPrint(
      'SensorService: EXTREME SUSTAINED IMPACT DETECTED! Magnitude: ${magnitude.toStringAsFixed(2)} m/s² (≥30G) - immediate escalation',
    );

    _onCrashDetected?.call(impactInfo);
  }

  /// Handle gyroscope events - Optimized for low power
  void _handleGyroscopeEvent(GyroscopeEvent event) {
    // Skip gyroscope processing in low power mode (not critical for detection)
    if (_isLowPowerMode) {
      return;
    }

    // Validate gyroscope data
    if (!_isValidSensorReading(event.x, event.y, event.z)) {
      return;
    }

    final reading = SensorReading(
      timestamp: DateTime.now(),
      x: event.x,
      y: event.y,
      z: event.z,
      sensorType: 'gyroscope',
    );

    // CRITICAL: Convert raw sensor magnitude to real-world acceleration
    final magnitude = _convertToRealWorldAcceleration(reading.magnitude);

    // Skip extreme readings entirely
    if (magnitude > 200.0) {
      return;
    }

    _addToBuffer(_gyroscopeBuffer, reading);
  }

  /// Add reading to buffer and maintain size limit
  void _addToBuffer(List<SensorReading> buffer, SensorReading reading) {
    buffer.add(reading);

    // Keep only readings within the detection window
    final cutoffTime = DateTime.now().subtract(
      Duration(milliseconds: AppConstants.crashDetectionWindowMs),
    );

    buffer.removeWhere((r) => r.timestamp.isBefore(cutoffTime));
  }

  /// Check for violent phone handling (aggressive throw/smash)
  /// Detects impacts in 100-180 m/s² range with throw pattern analysis
  /// Sends silent alert to emergency contacts without user notification
  void _checkForViolentHandling(SensorReading reading) {
    // Cooldown check - avoid alert spam
    if (_lastViolentHandlingDetection != null) {
      final timeSinceLastDetection = DateTime.now().difference(
        _lastViolentHandlingDetection!,
      );
      if (timeSinceLastDetection < _violentHandlingCooldown) {
        return; // Still in cooldown period
      }
    }

    // Get recent readings for pattern analysis (same approach as fall detection)
    final recentReadings = _accelerometerBuffer
        .where(
          (r) => r.timestamp.isAfter(
            DateTime.now().subtract(const Duration(seconds: 2)),
          ),
        )
        .toList();

    if (recentReadings.length < 10) {
      return; // Not enough data for pattern analysis
    }

    // PATTERN 1: Check for throw pattern (free-fall + impact)
    // Throwing involves brief weightlessness before impact
    int freeFallCount = 0;
    int highImpactCount = 0;
    double maxImpact = 0.0;

    for (var r in recentReadings) {
      final mag = _convertToRealWorldAcceleration(r.magnitude);

      // Free-fall detection (weightlessness)
      if (mag < 5.0) {
        freeFallCount++;
      }

      // High impact detection (100-180 m/s²)
      if (mag >= _violentHandlingThreshold &&
          mag < _violentHandlingMaxThreshold) {
        highImpactCount++;
        if (mag > maxImpact) maxImpact = mag;
      }
    }

    // Throw pattern: Free-fall followed by impact
    final hasThrowPattern = freeFallCount >= 3 && highImpactCount >= 2;

    // PATTERN 2: Check for rotation during throw (using gyroscope)
    bool hasRotation = false;
    if (_gyroscopeBuffer.length >= 5) {
      final recentGyro = _gyroscopeBuffer
          .skip(max(0, _gyroscopeBuffer.length - 10))
          .toList();
      int rotationCount = 0;

      for (var r in recentGyro) {
        // Detect significant rotation (phone tumbling through air)
        if (r.magnitude > 3.0) {
          // rad/s - significant rotation
          rotationCount++;
        }
      }

      hasRotation = rotationCount >= 3;
    }

    // PATTERN 3: High impact without crash-level force
    final magnitude = _convertToRealWorldAcceleration(reading.magnitude);
    final hasHighImpact =
        magnitude >= _violentHandlingThreshold &&
        magnitude < _violentHandlingMaxThreshold;

    // TRIGGER: Violent handling detected only when the pattern indicates an
    // actual throw/tumble (free-fall and/or rotation), not just a single bump.
    if (hasThrowPattern || (hasHighImpact && hasRotation)) {
      _lastViolentHandlingDetection = DateTime.now();
      _violentHandlingCount++;

      // Initialize session start time on first incident
      _sessionStartTime ??= DateTime.now();

      // Determine severity based on magnitude
      final impactSeverity = magnitude >= 150.0
          ? ImpactSeverity.high
          : magnitude >= 120.0
          ? ImpactSeverity.medium
          : ImpactSeverity.low;

      debugPrint('⚠️ VIOLENT PHONE HANDLING DETECTED');
      debugPrint('   Impact: ${magnitude.toStringAsFixed(1)} m/s²');
      debugPrint('   Max Impact: ${maxImpact.toStringAsFixed(1)} m/s²');
      debugPrint(
        '   Pattern: ${hasThrowPattern
            ? "Throw"
            : hasRotation
            ? "Rotation"
            : "Impact"}',
      );
      debugPrint('   Incident count: $_violentHandlingCount');
      debugPrint('   🔕 Silent alert sent to emergency contacts');

      // Create impact info for callback
      final impactInfo = ImpactInfo(
        accelerationMagnitude: magnitude,
        maxAcceleration: maxImpact > 0 ? maxImpact : magnitude,
        detectionTime: reading.timestamp,
        sensorReadings: recentReadings,
        severity: impactSeverity,
        detectionAlgorithm:
            'Violent Handling Detection (${hasThrowPattern
                ? "Throw Pattern"
                : hasRotation
                ? "Rotation Pattern"
                : "High Impact"})',
        isVerified: true, // Auto-verified based on pattern analysis
        verificationConfidence: hasThrowPattern
            ? 0.9
            : hasRotation
            ? 0.8
            : 0.7,
        verificationReason:
            'Aggressive phone handling detected: Impact ${magnitude.toStringAsFixed(1)} m/s², Count: $_violentHandlingCount',
      );

      // Trigger silent alert callback (no user notification)
      _onViolentHandlingDetected?.call(impactInfo);
    }
  }

  /// Check for crash based on acceleration magnitude - Blueprint strategy
  /// BLUEPRINT REQUIREMENT: Only trigger on 60+ km/h crashes (180+ m/s²) sustained over time
  void _checkForCrash(SensorReading reading) {
    final now = DateTime.now();

    // AIRPLANE MODE: Suppress crash detection during flight (turbulence filtering)
    if (_shouldSuppressCrashDetection()) {
      return;
    }

    // If verification window is active, always process without throttle
    if (_isPotentialCrashInProgress) {
      // Continue gathering post-impact readings
      _postImpactReadings.add(reading);

      // Check if motion resumed (continuous driving = false alarm)
      if (_detectMotionResume()) {
        debugPrint(
          'SensorService: Crash detection CANCELLED - Motion resumed (driving continues, likely pothole/bump)',
        );
        _isPotentialCrashInProgress = false;
        _potentialCrashTime = null;
        _postImpactReadings.clear();
        return;
      }

      // Check if verification window expired → real crash (vehicle stopped)
      if (_potentialCrashTime != null &&
          now.difference(_potentialCrashTime!) > _crashVerificationWindow) {
        debugPrint(
          'SensorService: Crash verification complete - Vehicle stopped after impact (REAL CRASH)',
        );
        _isPotentialCrashInProgress = false;
        _triggerCrashAlert();
        return;
      }

      // Still in verification window
      return;
    }

    // Stationary user handling: allow high-impact external collisions
    // Example: Pedestrian hit by vehicle while phone is stationary
    // TEST MODE v2.0: Uses lowered threshold while maintaining identical behavior
    final currentCrashThreshold = AppConstants.getCrashThreshold();
    if (_isUserLikelyStationary) {
      final magnitude = _convertToRealWorldAcceleration(reading.magnitude);
      if (magnitude >= currentCrashThreshold) {
        // Require sustained pattern to avoid false positives
        if (!_hasSustainedHighImpactPattern()) {
          return;
        }

        // For stationary external impact, skip vehicle deceleration requirement
        if (_lastCrashDetection != null &&
            now.difference(_lastCrashDetection!) < _detectionCooldown) {
          return;
        }

        _lastCrashDetection = now;

        final impactInfo = _calculateImpactInfo(
          _accelerometerBuffer,
          magnitude >= _severeImpactThreshold
              ? ImpactSeverity.critical
              : ImpactSeverity.high,
          'stationary_external_impact_sustained',
        );

        debugPrint(
          'SensorService: 🚶‍♂️💥 Stationary external impact detected (${magnitude.toStringAsFixed(1)} m/s²) - triggering alert',
        );
        _onCrashDetected?.call(impactInfo);

        // Post-impact immobility check (log-only): confirm minimal movement for a few seconds
        _schedulePostImpactImmobilityCheck(windowSeconds: 5);
        return;
      } else {
        // Below crash threshold while stationary: skip to reduce false alarms
        if (_lastCrashCheck == null ||
            now.difference(_lastCrashCheck!) > const Duration(seconds: 30)) {
          debugPrint(
            'SensorService: Crash detection skipped (stationary, below threshold) ${magnitude.toStringAsFixed(1)} m/s²',
          );
          _lastCrashCheck = now;
        }
        return;
      }
    }

    // Throttle crash checks to prevent excessive processing (not during verification)
    if (_lastCrashCheck != null &&
        now.difference(_lastCrashCheck!) < _currentCrashThrottle) {
      return;
    }
    _lastCrashCheck = now;

    // CRITICAL: Convert raw sensor magnitude to real-world acceleration
    final magnitude = _convertToRealWorldAcceleration(reading.magnitude);

    // (Verification handling moved above throttle)

    // Phone drop filter (blueprint: brief impact <100 m/s²)
    if (magnitude < _phoneDropThreshold) {
      return; // Likely phone drop or normal movement
    }

    // CRITICAL: Require sustained HIGH impact pattern (60+ km/h over multiple readings)
    // This prevents false positives from:
    // - Brief sensor spikes/glitches
    // - Gentle bumps (even if sensor reports high value momentarily)
    // - Table placement or pocket movement
    // - Single anomalous readings
    // - Driving vibrations and potholes
    if (!_hasSustainedHighImpactPattern()) {
      return; // Not a sustained crash-level impact - ignoring
    }

    // CRITICAL: Check for deceleration pattern (car stopping)
    // Real crashes show BOTH impact AND deceleration
    // Driving bumps/potholes show impact but NO deceleration (car keeps moving)
    if (!_hasDecelerationPattern()) {
      debugPrint(
        'SensorService: High impact detected but NO deceleration pattern - likely driving bump/pothole, ignoring',
      );
      return;
    }

    if (magnitude > currentCrashThreshold) {
      // Check cooldown period to prevent multiple rapid detections
      if (_lastCrashDetection != null &&
          now.difference(_lastCrashDetection!) < _detectionCooldown) {
        return; // Still in cooldown period
      }

      // Log detection event if in test mode
      if (AppConstants.testingModeEnabled) {
        TestModeDiagnosticService().logDetection(
          type: 'crash',
          reason: 'sustained_impact_with_deceleration',
          thresholdUsed: currentCrashThreshold,
          actualValue: magnitude,
          testMode: true,
          additionalData: {
            'location': '_checkForCrash',
            'has_deceleration': true,
            'has_sustained_pattern': true,
          },
        );
      }

      // Potential crash detected - enter verification window
      _isPotentialCrashInProgress = true;
      _potentialCrashTime = now;
      _postImpactReadings.clear();
      _postImpactReadings.add(reading);

      debugPrint(
        'SensorService: Potential crash detected - Monitoring for 3s to verify vehicle stopped...${AppConstants.testingModeEnabled ? " [TEST MODE]" : ""}',
      );

      // Notify coordinator that a detection window has started (crash)
      try {
        IncidentEscalationCoordinator.instance.detectionWindowStarted(
          DetectionContext(
            type: DetectionType.crash,
            reason: DetectionReason.sharpDeceleration,
            timestamp: now,
            magnitude: magnitude,
            deceleration: null,
            jerk: null,
            location: null,
            additionalData: {
              'phase': 'crash_verification_window',
              'test_mode': AppConstants.testingModeEnabled,
            },
          ),
        );
      } catch (e) {
        debugPrint(
          'SensorService: Failed to notify coordinator (crash start) - $e',
        );
      }
    }
  }

  /// Detect if motion resumed after impact (indicates driving continues, not a crash)
  /// REAL CRASHES: Vehicle stops completely, minimal movement
  /// FALSE ALARMS: Vehicle continues driving after bump/pothole
  bool _detectMotionResume() {
    if (_postImpactReadings.length < 10) {
      return false; // Need enough data (1 second at 10Hz)
    }

    // Get recent readings (last 1 second)
    final recentReadings = _postImpactReadings.length > 10
        ? _postImpactReadings.sublist(_postImpactReadings.length - 10)
        : _postImpactReadings;

    // Count readings showing continuous movement (driving continues)
    // Normal driving shows 10-25 m/s² consistent acceleration patterns
    final continuousMovementReadings = recentReadings.where((r) {
      // Check for consistent driving-level acceleration (not stationary)
      // CRITICAL: Convert raw magnitude to real-world acceleration
      final accel = _convertToRealWorldAcceleration(r.magnitude);
      // Driving continues: 10-30 m/s² sustained movement
      // Vehicle stopped: 8-12 m/s² (just gravity, no movement)
      return accel > 10.0 &&
          accel < 30.0; // Continuous driving range (blueprint)
    }).length;

    // If 70% or more readings show continuous movement = car is still driving
    final movementRatio = continuousMovementReadings / recentReadings.length;

    // Also consider GPS: if latest known speed suggests driving, treat as resumed
    final gpsIndicatesDriving = (_lastKnownSpeed ?? 0.0) > 5.0; // km/h

    if (movementRatio >= 0.7 || gpsIndicatesDriving) {
      debugPrint(
        'SensorService: Motion resume detected - accel ${(movementRatio * 100).toStringAsFixed(0)}% driving, gps ${gpsIndicatesDriving ? 'DRIVING' : 'NO'}',
      );
      return true;
    }

    return false;
  }

  /// Check for deceleration pattern (vehicle stopping)
  /// REAL CRASHES: Show deceleration as vehicle comes to sudden stop
  /// DRIVING BUMPS: Show impact spike but no sustained deceleration
  bool _hasDecelerationPattern() {
    if (_accelerometerBuffer.length < 10) return false;

    // Get recent 1 second of data (10 readings at 10Hz)
    final recentReadings = _accelerometerBuffer.length > 10
        ? _accelerometerBuffer.sublist(_accelerometerBuffer.length - 10)
        : _accelerometerBuffer;

    // Analyze for deceleration pattern:
    // Real crash: High initial impact followed by sustained deceleration
    // The readings should show decreasing forward velocity (negative acceleration)

    // Check if we have sustained higher-than-baseline acceleration
    // indicating vehicle is decelerating (slowing down/stopping)
    int decelerationReadings = 0;

    for (int i = 0; i < recentReadings.length; i++) {
      final current = recentReadings[i];

      // CRITICAL: Convert raw magnitude to real-world acceleration for comparison
      final magnitude = _convertToRealWorldAcceleration(current.magnitude);

      // Deceleration shows as increased acceleration beyond normal gravity
      // indicating forces from vehicle slowing down/stopping
      if (magnitude > _baselineMagnitude + 5.0) {
        decelerationReadings++;
      }
    }

    // Need at least 5 out of 10 readings showing deceleration
    // This filters out brief bumps (1-2 readings) vs real stops (5+ readings)
    bool hasAccelDecel = decelerationReadings >= 5;

    // Also check GPS speed deceleration if available (more robust while driving)
    bool hasGpsDecel = _hasGpsDecelerationPattern();

    final hasDeceleration = hasAccelDecel || hasGpsDecel;

    if (!hasDeceleration) {
      debugPrint(
        'SensorService: No deceleration pattern - accel $decelerationReadings/10, gps ${hasGpsDecel ? 'YES' : 'NO'}',
      );
    }

    return hasDeceleration;
  }

  /// Check for deceleration using GPS speed history when available
  /// Returns true if recent speed samples show a sustained decrease
  bool _hasGpsDecelerationPattern() {
    // Require at least a few speed samples
    if (_speedHistory.length < 4) return false;

    // Consider up to last 10 deltas
    final start = _speedHistory.length > 11 ? _speedHistory.length - 11 : 1;
    int decreasingCount = 0;
    double maxRecentSpeed = 0.0;
    double lastSpeed = _speedHistory[max(0, start - 1)];
    for (int i = start; i < _speedHistory.length; i++) {
      final s = _speedHistory[i];
      if (s < lastSpeed - 2.0) {
        // count as a meaningful decrease (>2 km/h step)
        decreasingCount++;
      }
      if (s > maxRecentSpeed) maxRecentSpeed = s;
      lastSpeed = s;
    }

    // Heuristics:
    // - At least 3 decreasing steps in the recent window, AND
    // - Overall drop of >= 10 km/h from peak to latest
    final overallDrop = maxRecentSpeed - _speedHistory.last;
    return decreasingCount >= 3 && overallDrop >= 10.0;
  }

  /// Trigger crash alert after verification window confirms it's a real crash
  void _triggerCrashAlert() {
    _lastCrashDetection = DateTime.now();
    _postImpactReadings.clear();

    // Calculate impact info from recent readings
    final impactInfo = _calculateImpactInfo(
      _accelerometerBuffer,
      ImpactSeverity.high,
      'crash_detection_verified_vehicle_stopped',
    );

    debugPrint(
      'SensorService: VERIFIED CRASH - Vehicle stopped after impact, triggering emergency alert',
    );
    _onCrashDetected?.call(impactInfo);
  }

  /// Check if sensor pattern indicates sustained HIGH impact (crash-level forces)
  /// BLUEPRINT REQUIREMENT: Must maintain 60+ km/h crash forces over multiple readings
  /// to avoid false positives from brief sensor spikes or gentle bumps
  bool _hasSustainedHighImpactPattern() {
    if (_accelerometerBuffer.length < 5) return false;

    // Check last 5 readings (0.5 seconds at 10Hz sampling)
    final recentReadings = _accelerometerBuffer.length > 5
        ? _accelerometerBuffer.sublist(_accelerometerBuffer.length - 5)
        : _accelerometerBuffer;

    // Count readings that exceed crash threshold (180 m/s² = 60 km/h)
    // CRITICAL: Convert each raw magnitude to real-world acceleration
    final crashLevelReadings = recentReadings
        .where(
          (r) => _convertToRealWorldAcceleration(r.magnitude) > _crashThreshold,
        )
        .length;

    // Sustained crash pattern: at least 3 out of 5 readings exceed 60 km/h threshold (production)
    // or 1 out of 5 in test mode for easier hand shaking
    // This filters out brief sensor spikes while detecting real crashes
    return crashLevelReadings >= 3;
  }

  /// Check for fall based on acceleration patterns
  void _checkForFall(SensorReading reading) {
    if (_accelerometerBuffer.length < 10) return; // Need enough data

    // AIRPLANE MODE: Use special airplane crash detection logic
    if (_isInAirplaneMode) {
      _checkForAirplaneCrash();
      return;
    }

    // If fall is in progress, check for normal movement (phone pickup)
    if (_isFallInProgress) {
      if (_detectNormalMovement(reading)) {
        debugPrint(
          'SensorService: Fall detection CANCELLED - User picked up phone and moving normally',
        );
        _isFallInProgress = false;
        _fallDetectedTime = null;
        return;
      }

      // Check if fall cancellation window expired
      if (_fallDetectedTime != null &&
          DateTime.now().difference(_fallDetectedTime!) >
              _fallCancellationWindow) {
        // Window expired, proceed with fall alert
        debugPrint(
          'SensorService: Fall cancellation window expired - proceeding with alert',
        );
        _isFallInProgress = false;
        _triggerFallAlert();
        return;
      }

      // Still in cancellation window, keep monitoring
      return;
    }

    // BLUEPRINT REQUIREMENT: Detect falls over 1 meter only
    // Physics: h = ½gt², where g = 9.8 m/s², t = free fall duration
    // 1 meter fall = 0.45 seconds free fall time
    final recentReadings = _accelerometerBuffer
        .where(
          (r) => r.timestamp.isAfter(
            DateTime.now().subtract(const Duration(seconds: 2)),
          ),
        )
        .toList();

    if (recentReadings.length < 5) return;

    // STEP 1: Detect free fall pattern and calculate duration
    // Track consecutive free fall readings with timestamps
    DateTime? freeFallStartTime;
    DateTime? freeFallEndTime;
    int consecutiveFreeFall = 0;
    int maxConsecutiveFreeFall = 0;

    for (int i = 0; i < recentReadings.length ~/ 2; i++) {
      // CRITICAL: Convert raw magnitude to real-world acceleration
      final magnitude = _convertToRealWorldAcceleration(
        recentReadings[i].magnitude,
      );

      if (magnitude < 2.0) {
        // Free fall detected (weightlessness)
        if (consecutiveFreeFall == 0) {
          freeFallStartTime = recentReadings[i].timestamp;
        }
        consecutiveFreeFall++;
        freeFallEndTime = recentReadings[i].timestamp;

        if (consecutiveFreeFall > maxConsecutiveFreeFall) {
          maxConsecutiveFreeFall = consecutiveFreeFall;
        }
      } else {
        consecutiveFreeFall = 0;
      }
    }

    // Require sustained free fall (at least 3 consecutive readings)
    final hasFreeFall = maxConsecutiveFreeFall >= 3;

    // STEP 2: Calculate fall height from free fall duration
    double fallHeight = 0.0;
    double freeFallDurationSeconds = 0.0;
    if (hasFreeFall && freeFallStartTime != null && freeFallEndTime != null) {
      // Calculate free fall duration in seconds
      freeFallDurationSeconds =
          freeFallEndTime.difference(freeFallStartTime).inMilliseconds / 1000.0;

      // Physics: h = ½gt² (g = 9.8 m/s²)
      fallHeight =
          0.5 * 9.8 * freeFallDurationSeconds * freeFallDurationSeconds;

      debugPrint(
        'SensorService: Free fall detected - Duration: ${freeFallDurationSeconds.toStringAsFixed(2)}s, Calculated height: ${fallHeight.toStringAsFixed(2)}m',
      );
    }

    // STEP 3: Check for impact (high acceleration - hitting ground)
    // Fall threshold: 100 m/s² = ~1 meter drop impact
    // TEST MODE v2.0: Uses lowered threshold (0.3m fall = 48 m/s²) while maintaining identical behavior
    // CRITICAL: Convert raw magnitudes to real-world acceleration
    final currentFallThreshold = _effectiveFallThreshold();
    final hasImpact = recentReadings
        .skip(recentReadings.length ~/ 2)
        .any(
          (r) =>
              _convertToRealWorldAcceleration(r.magnitude) >
              currentFallThreshold,
        );

    // STEP 4: Only trigger if fall height exceeds minimum (1m production, 0.3m test mode)
    final minFallHeight = AppConstants.testingModeEnabled ? 0.3 : 1.0;
    if (hasFreeFall && hasImpact && fallHeight >= minFallHeight) {
      // Check cooldown period to prevent multiple rapid detections
      final now = DateTime.now();
      if (_lastFallDetection != null &&
          now.difference(_lastFallDetection!) < _detectionCooldown) {
        return; // Still in cooldown period
      }

      // Mark fall as in progress and start cancellation window
      _isFallInProgress = true;
      _fallDetectedTime = now;

      debugPrint(
        'SensorService: Fall detected - Height: ${fallHeight.toStringAsFixed(2)}m (>=${minFallHeight}m threshold)! Monitoring for phone pickup within ${_fallCancellationWindow.inSeconds}s...${AppConstants.testingModeEnabled ? " [TEST MODE]" : ""}',
      );
      debugPrint(
        'SensorService: User can cancel by picking up phone and moving normally',
      );

      // Log detection event if in test mode
      if (AppConstants.testingModeEnabled) {
        final impactMag = recentReadings
            .skip(recentReadings.length ~/ 2)
            .map((r) => _convertToRealWorldAcceleration(r.magnitude))
            .fold<double>(0.0, (prev, m) => m > prev ? m : prev);
        TestModeDiagnosticService().logDetection(
          type: 'fall',
          reason: 'free_fall_with_impact',
          thresholdUsed: currentFallThreshold,
          actualValue: impactMag,
          testMode: true,
          additionalData: {
            'fall_height_m': fallHeight,
            'free_fall_duration_s': freeFallDurationSeconds,
            'min_height_threshold_m': minFallHeight,
          },
        );
      }

      // Notify coordinator that a detection window has started (fall)
      try {
        final impactMagnitude = recentReadings
            .skip(recentReadings.length ~/ 2)
            .map((r) => _convertToRealWorldAcceleration(r.magnitude))
            .fold<double>(0.0, (prev, m) => m > prev ? m : prev);
        IncidentEscalationCoordinator.instance.detectionWindowStarted(
          DetectionContext(
            type: DetectionType.fall,
            reason: DetectionReason.freeFallImpact,
            timestamp: now,
            magnitude: impactMagnitude,
            deceleration: null,
            jerk: null,
            location: null,
            additionalData: {
              'phase': 'fall_cancellation_window',
              'test_mode': AppConstants.testingModeEnabled,
              'fall_height_m': fallHeight,
            },
          ),
        );
      } catch (e) {
        debugPrint(
          'SensorService: Failed to notify coordinator (fall start) - $e',
        );
      }
    } else if (hasFreeFall && hasImpact && fallHeight < 1.0) {
      debugPrint(
        'SensorService: Fall detected but below 1m threshold (${fallHeight.toStringAsFixed(2)}m) - ignoring',
      );
    }
  }

  /// Detect normal movement patterns (user picked up phone after fall)
  bool _detectNormalMovement(SensorReading reading) {
    if (_accelerometerBuffer.length < 10) return false;

    // Get recent readings (last 2 seconds)
    final recentReadings = _accelerometerBuffer
        .where(
          (r) => r.timestamp.isAfter(
            DateTime.now().subtract(const Duration(seconds: 2)),
          ),
        )
        .toList();

    if (recentReadings.length < 5) return false;

    // Check for consistent moderate movement (walking, handling phone)
    // Normal movement: 10-15 m/s² consistent acceleration
    int normalMovementCount = 0;
    for (final r in recentReadings) {
      // CRITICAL: Convert raw magnitude to real-world acceleration
      final magnitude = _convertToRealWorldAcceleration(r.magnitude);
      if (magnitude > 10.0 && magnitude < 20.0) {
        normalMovementCount++;
      }
    }

    // If 60%+ of readings show normal movement, user picked up phone
    final normalMovementRatio = normalMovementCount / recentReadings.length;
    return normalMovementRatio > 0.6;
  }

  /// Trigger fall alert after cancellation window expires
  void _triggerFallAlert() {
    final now = DateTime.now();
    _lastFallDetection = now;

    final impactInfo = _calculateImpactInfo(
      _accelerometerBuffer
          .where(
            (r) =>
                r.timestamp.isAfter(now.subtract(const Duration(seconds: 2))),
          )
          .toList(),
      ImpactSeverity.medium,
      'fall_detection_1meter_threshold',
    );

    debugPrint(
      'SensorService: Fall alert triggered! User did not pick up phone.',
    );
    _onFallDetected?.call(impactInfo);
  }

  /// Calculate impact information from sensor readings
  ImpactInfo _calculateImpactInfo(
    List<SensorReading> readings,
    ImpactSeverity severity,
    String algorithm,
  ) {
    if (readings.isEmpty) {
      return ImpactInfo(
        accelerationMagnitude: 0.0,
        maxAcceleration: 0.0,
        detectionTime: DateTime.now(),
        severity: severity,
        detectionAlgorithm: algorithm,
      );
    }

    // CRITICAL: Convert all magnitudes to real-world acceleration
    final magnitudes = readings
        .map((r) => _convertToRealWorldAcceleration(r.magnitude))
        .toList();
    final maxAcceleration = magnitudes.reduce(max);
    final avgAcceleration =
        magnitudes.reduce((a, b) => a + b) / magnitudes.length;

    return ImpactInfo(
      accelerationMagnitude: avgAcceleration,
      maxAcceleration: maxAcceleration,
      detectionTime: DateTime.now(),
      sensorReadings: readings,
      severity: severity,
      detectionAlgorithm: algorithm,
    );
  }

  /// Clear sensor buffers
  void _clearBuffers() {
    _accelerometerBuffer.clear();
    _gyroscopeBuffer.clear();
  }

  /// Validate sensor reading values to prevent extreme/invalid data
  bool _isValidSensorReading(double x, double y, double z) {
    // Check for NaN or infinite values
    if (!x.isFinite || !y.isFinite || !z.isFinite) {
      return false;
    }

    // Check for extremely large values that could indicate sensor malfunction.
    // Many phones support up to ±16g (≈156.8 m/s²) and some up to ±32g
    // (≈313.6 m/s²). We must allow high-G events or crash/fall detection
    // becomes impossible.
    const double maxReasonableValue = 400.0; // m/s² (~40g)
    if (x.abs() > maxReasonableValue ||
        y.abs() > maxReasonableValue ||
        z.abs() > maxReasonableValue) {
      return false;
    }

    return true;
  }

  void _startSensorUpload() {
    // Implement sensor data upload logic here
    debugPrint('SensorService: Starting sensor data upload...');
  }

  void _stopSensorUpload() {
    // Implement logic to stop sensor data upload here
    debugPrint('SensorService: Stopping sensor data upload...');
  }

  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get isLowPowerMode => _isLowPowerMode;
  bool get crashDetectionEnabled => _crashDetectionEnabled;
  bool get fallDetectionEnabled => _fallDetectionEnabled;
  double get crashThreshold => _crashThreshold;
  double get fallThreshold => _fallThreshold;

  bool get hasRedPingModeOverrides =>
      _crashThresholdOverride != null ||
      _fallThresholdOverride != null ||
      _samplingPeriodOverrideMs != null ||
      _powerModeOverride != null;

  /// Apply RedPing Mode sensor overrides.
  /// Thresholds are in m/s² (SensorService units).
  Future<void> applyRedPingModeConfig(SensorConfig config) async {
    // Threshold overrides
    _crashThresholdOverride = config.crashThreshold;
    _fallThresholdOverride = config.fallThreshold;

    // Apply immediately
    if (AppConstants.testingModeEnabled) {
      _crashThreshold = config.crashThreshold;
      _fallThreshold = config.fallThreshold;
    } else {
      crashThreshold = config.crashThreshold;
      fallThreshold = config.fallThreshold;
    }

    // Detection toggles
    crashDetectionEnabled = config.enableMotionTracking;
    fallDetectionEnabled = config.enableFreefallDetection;

    // Sampling/power overrides
    _samplingPeriodOverrideMs = config.monitoringInterval.inMilliseconds;
    _powerModeOverride = config.powerMode;

    // If already monitoring in low power mode, restart to apply samplingPeriod.
    // Avoid restarting during SOS active mode.
    if (_isMonitoring && _isLowPowerMode) {
      stopMonitoring();
      await Future.delayed(const Duration(milliseconds: 100));
      await startMonitoring(
        lowPowerMode: _powerModeOverride == PowerMode.high ? false : true,
      );
    }
  }

  /// Clear RedPing Mode overrides and restore defaults.
  Future<void> clearRedPingModeConfig() async {
    _crashThresholdOverride = null;
    _fallThresholdOverride = null;
    _samplingPeriodOverrideMs = null;
    _powerModeOverride = null;

    _resetThresholdsToDefaults();

    if (_isMonitoring && _isLowPowerMode) {
      stopMonitoring();
      await Future.delayed(const Duration(milliseconds: 100));
      await startMonitoring(lowPowerMode: true);
    }
  }

  // Setters
  set crashDetectionEnabled(bool enabled) {
    _crashDetectionEnabled = enabled;
    debugPrint(
      'SensorService: Crash detection ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  set fallDetectionEnabled(bool enabled) {
    _fallDetectionEnabled = enabled;
    debugPrint(
      'SensorService: Fall detection ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  set crashThreshold(double threshold) {
    // Enforce blueprint minimum (60+ km/h ≈ 180 m/s²); allow modest increases for less sensitivity
    final min = AppConstants.testingModeEnabled ? 50.0 : 180.0;
    final clamped = threshold.clamp(min, 220.0);
    _crashThreshold = clamped;
    debugPrint(
      'SensorService: Crash threshold set to ${clamped.toStringAsFixed(1)}',
    );
  }

  set fallThreshold(double threshold) {
    // Enforce safe operational range to prevent false alarms and glitches
    final min = AppConstants.testingModeEnabled ? 20.0 : 140.0;
    final clamped = threshold.clamp(min, 220.0);
    _fallThreshold = clamped;
    debugPrint(
      'SensorService: Fall threshold set to ${clamped.toStringAsFixed(1)}',
    );
  }

  // Event handlers
  void setCrashDetectedCallback(Function(ImpactInfo) callback) {
    _onCrashDetected = callback;
  }

  void setFallDetectedCallback(Function(ImpactInfo) callback) {
    _onFallDetected = callback;
  }

  void setSensorUpdateCallback(Function(SensorReading) callback) {
    _onSensorUpdate = callback;
  }

  void setViolentHandlingDetectedCallback(Function(ImpactInfo) callback) {
    _onViolentHandlingDetected = callback;
  }

  /// Get current sensor status
  Map<String, dynamic> getSensorStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'crashDetectionEnabled': _crashDetectionEnabled,
      'fallDetectionEnabled': _fallDetectionEnabled,
      'crashThreshold': _crashThreshold,
      'fallThreshold': _fallThreshold,
      'hasRedPingModeOverrides': hasRedPingModeOverrides,
      'samplingPeriodOverrideMs': _samplingPeriodOverrideMs,
      'powerModeOverride': _powerModeOverride?.toString(),
      'isCalibrated': _isCalibrated,
      'realWorldConversionActive': _isCalibrated,
      'accelerationScalingFactor': _accelerationScalingFactor,
      'sensorNoiseFactor': _sensorNoiseFactor,
      'calibratedGravity': _calibratedGravity,
      'accelerometerBufferSize': _accelerometerBuffer.length,
      'gyroscopeBufferSize': _gyroscopeBuffer.length,
    };
  }

  /// Calibrate sensors (reset thresholds based on current environment)
  /// Enhanced with real-world conversion formula
  Future<void> calibrateSensors() async {
    debugPrint('SensorService: 🔧 Starting enhanced sensor calibration...');
    debugPrint('  📱 Keep phone still on flat surface for 12 seconds');

    // Use new calibration system
    await startCalibration();

    // Also update old system for compatibility
    _clearBuffers();

    // Collect baseline data for additional validation
    final completer = Completer<void>();
    Timer(const Duration(seconds: 5), () {
      // Calculate baseline noise levels
      if (_accelerometerBuffer.isNotEmpty) {
        final magnitudes = _accelerometerBuffer
            .map((r) => r.magnitude)
            .toList();
        final maxMagnitude = magnitudes.reduce(max);

        // Initialize thresholds based on test mode (TEST MODE v2.0)
        _resetThresholdsToDefaults();

        debugPrint(
          'SensorService: ✅ Enhanced calibration complete!${AppConstants.testingModeEnabled ? " [TEST MODE]" : ""}',
        );
        debugPrint(
          '  - Baseline noise: ${maxMagnitude.toStringAsFixed(2)} m/s²',
        );
        debugPrint(
          '  - Crash threshold: $_crashThreshold m/s²${AppConstants.testingModeEnabled ? " (8G shake)" : " (60+ km/h)"}',
        );
        debugPrint(
          '  - Fall threshold: $_fallThreshold m/s²${AppConstants.testingModeEnabled ? " (0.3m fall)" : " (1.5+ meters)"}',
        );
        debugPrint(
          '  - Severe impact threshold: $_severeImpactThreshold m/s²${AppConstants.testingModeEnabled ? " (15G)" : " (80+ km/h)"}',
        );
        debugPrint('  - Calibrated: $_isCalibrated');
        debugPrint('  - Sensor quality: ${_getSensorQuality()}');
      }

      completer.complete();
    });

    return completer.future;
  }

  /// Test crash detection (simulate a crash for testing)
  void simulateCrash() {
    // Simulation disabled for production release
    // Crash simulation disabled for production
  }

  /// Test fall detection (simulate a fall for testing)
  void simulateFall() {
    // Simulation disabled for production release
    // Fall simulation disabled for production
  }

  // ========== ENHANCEMENT HELPER METHODS ==========

  /// ENHANCEMENT 1: Update sleep state (11pm - 7am check)
  void _updateSleepState() {
    final now = DateTime.now();
    final hour = now.hour;

    // Sleep hours: 11pm (23:00) to 7am (07:00)
    final isSleepHours = hour >= 23 || hour < 7;

    // Only consider sleeping if stationary (no significant motion)
    final isStationary = !_isInSignificantMotion();

    _isLikelySleeping = isSleepHours && isStationary;
  }

  /// ENHANCEMENT 3: Check if device is in a safe location (home/office WiFi)
  Future<void> _checkSafeLocation() async {
    try {
      // This requires connectivity_plus package
      // Import: import 'package:connectivity_plus/connectivity_plus.dart';

      // For now, we'll use a simplified approach
      // In production, you'd check specific WiFi SSIDs
      // ConnectivityMonitorService is available but not used here

      // Consider connected state as "safe location"
      // TODO: In production, check against known WiFi SSIDs (home, office)
      _isInSafeLocation = true; // Simplified - assumes any connection is safe
    } catch (e) {
      // If connectivity check fails, assume not in safe location
      _isInSafeLocation = false;
    }
  }

  /// ENHANCEMENT 4: Update historical motion pattern (learn user routine)
  void _updateMotionPattern() {
    final now = DateTime.now();
    final key = '${now.weekday}_${now.hour}'; // e.g., "1_14" for Monday 2pm

    // Initialize pattern list if needed
    if (!_historicalMotionPatterns.containsKey(key)) {
      _historicalMotionPatterns[key] = [];
    }

    // Record if motion was detected in this hour
    final hasMotion = _isInSignificantMotion();
    _historicalMotionPatterns[key]!.add(hasMotion);

    // Keep only last 14 entries (2 weeks of data for this time slot)
    if (_historicalMotionPatterns[key]!.length > 14) {
      _historicalMotionPatterns[key]!.removeAt(0);
    }
  }

  /// ENHANCEMENT 5: Monitor device temperature (reduce processing when hot)
  void _updateDeviceTemperature() async {
    try {
      // Note: Battery temperature requires platform-specific code
      // For now, we'll estimate based on battery state

      // If charging, assume higher temperature
      if (_isCharging) {
        _deviceTemperature = 35.0; // Slightly elevated when charging
      } else {
        _deviceTemperature = 25.0; // Normal temperature
      }

      // Adjust processing interval if device is hot
      if (_deviceTemperature > 40.0) {
        // Reduce processing by increasing interval
        _processingInterval = min(_processingInterval * 2, 10000);
        if (kDebugMode) {
          print(
            'SensorService: Device hot (${_deviceTemperature.toStringAsFixed(1)}°C), reducing processing',
          );
        }
      } else if (_deviceTemperature < 35.0 && _processingInterval > 1000) {
        // Restore normal processing when cool
        _processingInterval = 1000;
      }
    } catch (e) {
      // Ignore temperature check errors
      _deviceTemperature = 25.0;
    }
  }

  // ========== AIRPLANE DETECTION SYSTEM ==========

  /// Update location data and check for airplane patterns
  /// Call this method whenever GPS location updates
  void updateLocationData({
    required double speed, // km/h
    required double altitude, // meters
  }) {
    final now = DateTime.now();

    // Store speed and altitude history
    _speedHistory.add(speed);
    _altitudeHistory.add(altitude);

    // Keep history size limited
    if (_speedHistory.length > _altitudeHistorySize) {
      _speedHistory.removeAt(0);
    }
    if (_altitudeHistory.length > _altitudeHistorySize) {
      _altitudeHistory.removeAt(0);
    }

    // Check if we have enough data for pattern analysis
    if (_altitudeHistory.length < 3) {
      _lastKnownSpeed = speed;
      _lastKnownAltitude = altitude;
      return;
    }

    // Detect airplane flight patterns
    _detectAirplaneFlight(speed, altitude, now);

    // Detect boat patterns
    _detectBoatMovement(speed, altitude, now);

    // Detect movement for sensor activation
    _detectMovement(speed, altitude);

    _lastKnownSpeed = speed;
    _lastKnownAltitude = altitude;

    // Evaluate power mode from updated speed/altitude context
    _maybeAdjustPowerMode();

    // Log status if speed/altitude changes affect summary
    _logCompactStatusIfNeeded();
  }

  /// Detect if user is in an airplane based on altitude and speed patterns
  void _detectAirplaneFlight(
    double currentSpeed,
    double currentAltitude,
    DateTime now,
  ) {
    if (_altitudeHistory.length < 5 || _speedHistory.length < 5) return;

    // Calculate altitude change rate (meters per minute)
    final altitudeChange =
        currentAltitude - _altitudeHistory[_altitudeHistory.length - 5];
    final timeSpanMinutes = 2.5; // 5 readings at 30s intervals = 2.5 minutes
    final climbRate = altitudeChange / timeSpanMinutes;

    // Pattern 1: TAKEOFF DETECTION - Rapid altitude gain + high speed
    if (!_isPotentialFlight && !_isInAirplaneMode) {
      if (climbRate > _climbRateThreshold &&
          currentSpeed > 200.0 &&
          currentAltitude > 100.0) {
        debugPrint(
          '✈️ SensorService: TAKEOFF detected - climb rate: ${climbRate.toStringAsFixed(0)} m/min, speed: ${currentSpeed.toStringAsFixed(0)} km/h',
        );
        _isPotentialFlight = true;
        _flightStartAltitude = currentAltitude;
        _flightDetectionTime = now;
      }
    }

    // Pattern 2: CRUISING ALTITUDE - Sustained high altitude + high speed
    if (_isPotentialFlight || _isInAirplaneMode) {
      final isAtCruisingAltitude =
          currentAltitude >= _cruisingAltitudeMin &&
          currentAltitude <= _cruisingAltitudeMax;
      final isAtCruisingSpeed = currentSpeed >= _cruisingSpeedMin;

      if (isAtCruisingAltitude && isAtCruisingSpeed) {
        // Calculate average altitude stability (low variance = stable flight)
        final recentAltitudes = _altitudeHistory.sublist(
          _altitudeHistory.length - 5,
        );
        final avgAltitude =
            recentAltitudes.reduce((a, b) => a + b) / recentAltitudes.length;
        final variance =
            recentAltitudes
                .map((a) => pow(a - avgAltitude, 2))
                .reduce((a, b) => a + b) /
            recentAltitudes.length;
        final isStable = variance < 10000; // Less than 100m variance

        if (isStable && !_isInAirplaneMode) {
          debugPrint(
            '✈️ SensorService: FLIGHT CONFIRMED - altitude: ${currentAltitude.toStringAsFixed(0)}m, speed: ${currentSpeed.toStringAsFixed(0)} km/h',
          );
          _activateAirplaneMode();
        }
      }
    }

    // Pattern 3: LANDING DETECTION - Rapid descent from cruising altitude
    if (_isInAirplaneMode) {
      if (climbRate < -_climbRateThreshold && currentAltitude < 1000.0) {
        debugPrint(
          '✈️ SensorService: LANDING detected - descent rate: ${climbRate.toStringAsFixed(0)} m/min',
        );
        _deactivateAirplaneMode();
      }
    }

    // Timeout: If potential flight doesn't reach cruising altitude in 10 minutes, cancel
    if (_isPotentialFlight && !_isInAirplaneMode) {
      if (now.difference(_flightDetectionTime!).inMinutes > 10) {
        debugPrint(
          'SensorService: Flight detection timeout - likely false positive',
        );
        _isPotentialFlight = false;
        _flightStartAltitude = null;
        _flightDetectionTime = null;
      }
    }
  }

  /// Activate airplane mode - disable crash detection during flight
  /// Activate airplane mode - adjust detection for flight environment
  void _activateAirplaneMode() {
    _isInAirplaneMode = true;
    _isPotentialFlight = false;

    debugPrint('✈️ SensorService: AIRPLANE MODE ACTIVATED');
    debugPrint('  - Crash detection: DISABLED (turbulence filtering)');
    debugPrint('  - Fall detection: AIRPLANE CRASH MODE (altitude-based)');
    debugPrint('  - Monitoring: Rapid altitude loss + extreme deceleration');
    debugPrint('  - Sensor monitoring: LOW POWER (minimal battery drain)');

    // Switch to ultra-low power mode during flight
    if (_isMonitoring) {
      setLowPowerMode();
    }
  }

  /// Deactivate airplane mode - restore normal crash detection
  void _deactivateAirplaneMode() {
    _isInAirplaneMode = false;
    _flightStartAltitude = null;
    _flightDetectionTime = null;

    debugPrint('✈️ SensorService: AIRPLANE MODE DEACTIVATED');
    debugPrint('  - Crash detection: ENABLED');
    debugPrint('  - Fall detection: ENABLED');
    debugPrint('  - Sensor monitoring: NORMAL');
  }

  /// Check for airplane crash scenario (rapid altitude loss + extreme impact)
  /// This is called instead of normal fall detection when in airplane mode
  void _checkForAirplaneCrash() {
    if (_altitudeHistory.length < 5 || _lastKnownAltitude == null) return;

    // Calculate altitude change rate (meters per second)
    final recentAltitudes = _altitudeHistory.sublist(
      _altitudeHistory.length - 5,
    );
    final altitudeChange = recentAltitudes.last - recentAltitudes.first;
    final timeSpanSeconds =
        2.5 * 60; // 5 readings at 30s intervals = 2.5 minutes
    final descentRate = altitudeChange / timeSpanSeconds; // meters per second

    // AIRPLANE CRASH INDICATORS:
    // 1. RAPID UNCONTROLLED DESCENT: >50 m/s (180 km/h vertical speed)
    //    Normal landing: ~2-5 m/s descent
    //    Emergency: >50 m/s descent indicates loss of control
    final isRapidDescent = descentRate < -50.0; // Negative = descending

    // 2. EXTREME DECELERATION: >500 m/s² impact
    //    Normal turbulence: <100 m/s²
    //    Severe turbulence: 100-300 m/s²
    //    Crash impact: >500 m/s²
    final hasExtremeImpact =
        _accelerometerBuffer.isNotEmpty &&
        _accelerometerBuffer.any((r) {
          final realWorld = _convertToRealWorldAcceleration(r.magnitude);
          return realWorld > 500.0;
        });

    // 3. ALTITUDE DROPPING BELOW SAFE THRESHOLD
    //    If descending rapidly and altitude <500m = imminent ground impact
    final isLowAltitude = _lastKnownAltitude! < 500.0;

    // TRIGGER AIRPLANE CRASH ALERT
    if (isRapidDescent && (hasExtremeImpact || isLowAltitude)) {
      debugPrint('✈️💥 SensorService: AIRPLANE CRASH DETECTED!');
      debugPrint('  - Descent rate: ${descentRate.toStringAsFixed(1)} m/s');
      debugPrint(
        '  - Current altitude: ${_lastKnownAltitude!.toStringAsFixed(0)}m',
      );
      debugPrint('  - Extreme impact: $hasExtremeImpact');

      // Trigger emergency alert
      _triggerAirplaneCrashAlert();
    }

    // ALSO CHECK: Sudden altitude loss (emergency descent)
    // Even without impact, rapid descent from cruising altitude is emergency
    if (isRapidDescent && _lastKnownAltitude! > 2000.0) {
      final descentRateKmh = (descentRate.abs() * 3.6).toStringAsFixed(0);
      debugPrint(
        '✈️⚠️ SensorService: Emergency descent detected - $descentRateKmh km/h vertical speed',
      );
      // Could trigger warning alert (less urgent than crash)
    }
  }

  /// Trigger airplane crash alert
  void _triggerAirplaneCrashAlert() {
    // Same as fall alert but with airplane-specific context
    if (_onFallDetected != null) {
      final info = ImpactInfo(
        accelerationMagnitude: 999.0, // Use max to indicate severity
        maxAcceleration: 999.0,
        detectionTime: DateTime.now(),
        severity: ImpactSeverity.critical,
        detectionAlgorithm: 'Airplane Crash Detection - Rapid Descent',
        sensorReadings: List.from(_accelerometerBuffer.take(100)),
        isVerified: true,
        verificationConfidence: 0.99,
        verificationReason:
            'Airplane crash: rapid altitude loss (${(_lastKnownAltitude ?? 0).toStringAsFixed(0)}m) + extreme deceleration detected',
      );
      _onFallDetected!(info);
    }
  }

  // ========== BOAT DETECTION SYSTEM ==========

  /// Detect if user is on a boat based on rhythmic motion + low altitude + marine speed
  void _detectBoatMovement(
    double currentSpeed,
    double currentAltitude,
    DateTime now,
  ) {
    // Need enough sensor data to analyze wave patterns
    if (_accelerometerBuffer.length < _boatPatternSampleSize) return;

    // Pattern 1: LOW ALTITUDE - Boats stay at sea level
    final isAtSeaLevel = currentAltitude < _boatAltitudeMax;

    // Pattern 2: MARINE SPEED RANGE - Not too fast (not airplane), not too slow (not stationary)
    final isMarineSpeed =
        currentSpeed >= _boatSpeedMin && currentSpeed <= _boatSpeedMax;

    // Pattern 3: RHYTHMIC WAVE MOTION - Analyze acceleration variance
    if (isAtSeaLevel && isMarineSpeed) {
      final motionVariance = _calculateMotionVariance();

      // Boats have distinctive rhythmic motion from waves (2-15 m/s² variance)
      final hasWavyMotion =
          motionVariance >= _wavyMotionVarianceMin &&
          motionVariance <= _wavyMotionVarianceMax;

      if (hasWavyMotion && !_isPotentialBoat && !_isOnBoat) {
        debugPrint(
          '🚤 SensorService: BOAT pattern detected - variance: ${motionVariance.toStringAsFixed(2)} m/s², speed: ${currentSpeed.toStringAsFixed(0)} km/h',
        );
        _isPotentialBoat = true;
        _boatDetectionTime = now;
      }

      // Confirm boat if pattern sustained for verification window
      if (_isPotentialBoat && !_isOnBoat) {
        if (now.difference(_boatDetectionTime!).inMinutes >= 3) {
          debugPrint(
            '🚤 SensorService: BOAT CONFIRMED - sustained wave motion detected',
          );
          _activateBoatMode();
        }
      }

      // Track variance history for pattern analysis
      _accelerationVarianceHistory.add(motionVariance);
      if (_accelerationVarianceHistory.length > 10) {
        _accelerationVarianceHistory.removeAt(0);
      }
    }

    // Pattern 4: EXITED BOAT - Speed stops or altitude increases significantly
    if (_isOnBoat) {
      final hasStoppedMoving = currentSpeed < _boatSpeedMin;
      final hasLeftWater =
          currentAltitude > _boatAltitudeMax + 50.0; // +50m buffer

      if (hasStoppedMoving || hasLeftWater) {
        debugPrint(
          '🚤 SensorService: BOAT EXIT detected - speed: ${currentSpeed.toStringAsFixed(0)} km/h, altitude: ${currentAltitude.toStringAsFixed(0)}m',
        );
        _deactivateBoatMode();
      }
    }

    // Timeout: If potential boat doesn't sustain pattern, cancel
    if (_isPotentialBoat && !_isOnBoat) {
      if (now.difference(_boatDetectionTime!) > _boatVerificationWindow) {
        debugPrint(
          'SensorService: Boat detection timeout - pattern not sustained',
        );
        _isPotentialBoat = false;
        _boatDetectionTime = null;
      }
    }
  }

  /// Calculate motion variance for wave pattern detection
  /// Uses real-world calibrated acceleration values
  double _calculateMotionVariance() {
    if (_accelerometerBuffer.length < 10) return 0.0;

    // Get recent readings (last 30 seconds)
    final recentReadings = _accelerometerBuffer
        .where((r) => DateTime.now().difference(r.timestamp).inSeconds < 30)
        .toList();

    if (recentReadings.isEmpty) return 0.0;

    // Convert to real-world acceleration values using calibration formula
    final realWorldMagnitudes = recentReadings
        .map((r) => _convertToRealWorldAcceleration(r.magnitude))
        .toList();

    // Calculate average magnitude
    final avgMagnitude =
        realWorldMagnitudes.reduce((a, b) => a + b) /
        realWorldMagnitudes.length;

    // Calculate variance (wave pattern indicator)
    // Variance shows how much the acceleration fluctuates around the average
    final variance =
        realWorldMagnitudes
            .map((m) => pow(m - avgMagnitude, 2))
            .reduce((a, b) => a + b) /
        realWorldMagnitudes.length;

    return sqrt(variance);
  }

  /// Activate boat mode - adjust crash detection thresholds
  void _activateBoatMode() {
    _isOnBoat = true;
    _isPotentialBoat = false;

    debugPrint(
      '🚤 SensorService: BOAT MODE ACTIVATED${AppConstants.testingModeEnabled ? " [TEST MODE]" : ""}',
    );
    debugPrint('  - Wave motion filtering: ENABLED');
    debugPrint('  - Crash threshold: INCREASED (ignore wave impacts)');
    debugPrint('  - Fall detection: ADJUSTED (water-specific)');

    // Increase thresholds to ignore wave motion (adjust based on test mode)
    if (AppConstants.testingModeEnabled) {
      // In test mode, boat thresholds are still lowered but higher than base test thresholds
      _crashThreshold = 120.0; // Higher than 8G test threshold (78.4)
      _fallThreshold = 60.0; // Higher than 0.3m test threshold (48)
    } else {
      _crashThreshold =
          250.0; // Production: Higher threshold for boats (waves can be violent)
      _fallThreshold = 120.0; // Production: Adjust for boat movement
    }

    _reapplyThresholdOverridesIfAny();
  }

  /// Deactivate boat mode - restore normal thresholds
  void _deactivateBoatMode() {
    _isOnBoat = false;
    _boatDetectionTime = null;
    _accelerationVarianceHistory.clear();

    debugPrint(
      '🚤 SensorService: BOAT MODE DEACTIVATED${AppConstants.testingModeEnabled ? " [TEST MODE]" : ""}',
    );
    debugPrint('  - Crash detection: NORMAL thresholds restored');
    debugPrint('  - Fall detection: NORMAL thresholds restored');

    // Restore thresholds based on test mode
    _crashThreshold = _defaultCrashThreshold();
    _fallThreshold = _defaultFallThreshold();
    _reapplyThresholdOverridesIfAny();
  }

  /// Get current boat mode status
  Map<String, dynamic> get boatStatus => {
    'isOnBoat': _isOnBoat,
    'isPotentialBoat': _isPotentialBoat,
    'currentSpeed': _lastKnownSpeed,
    'currentAltitude': _lastKnownAltitude,
    'motionVariance': _accelerationVarianceHistory.isNotEmpty
        ? _accelerationVarianceHistory.last
        : 0.0,
    'boatDetectionTime': _boatDetectionTime?.toIso8601String(),
  };

  /// Detect movement based on speed and altitude changes
  void _detectMovement(double currentSpeed, double? currentAltitude) {
    final now = DateTime.now();
    bool isMoving = false;

    // Check speed-based movement
    if (currentSpeed > _minimumSpeedThreshold) {
      isMoving = true;
      debugPrint(
        'SensorService: Movement detected - speed: ${currentSpeed.toStringAsFixed(1)} km/h',
      );
    }

    // Check altitude-based movement (climbing stairs, elevator, hiking)
    if (currentAltitude != null && _lastKnownAltitude != null) {
      final altitudeChange = (currentAltitude - _lastKnownAltitude!).abs();
      if (altitudeChange > _altitudeChangeThreshold) {
        isMoving = true;
        debugPrint(
          'SensorService: Movement detected - altitude change: ${altitudeChange.toStringAsFixed(1)}m',
        );
      }
    }

    // Update movement state
    if (isMoving) {
      _lastMovementDetected = now;

      // Activate sensor monitoring if not already active
      if (!_isActivelyMoving) {
        _isActivelyMoving = true;
        debugPrint(
          'SensorService: 🚀 ACTIVATING sensor monitoring (movement detected)',
        );

        // Start monitoring if not already running
        if (!_isMonitoring && !_isInAirplaneMode) {
          startMonitoring(lowPowerMode: true);
        }
      }

      // Reset movement timeout timer
      _movementTimeoutTimer?.cancel();
      _movementTimeoutTimer = Timer(_movementTimeout, () {
        _onMovementTimeout();
      });
    }
  }

  /// Handle movement timeout - stop monitoring when stationary
  void _onMovementTimeout() {
    if (_lastMovementDetected != null) {
      final timeSinceMovement = DateTime.now().difference(
        _lastMovementDetected!,
      );

      if (timeSinceMovement >= _movementTimeout) {
        debugPrint(
          'SensorService: 😴 Switching to LOW POWER (no movement for ${_movementTimeout.inMinutes} min)',
        );
        _isActivelyMoving = false;
        // Drop to low power instead of stopping monitoring
        if (_isMonitoring && !_isInAirplaneMode) {
          setLowPowerMode();
          _logCompactStatusIfNeeded(force: true);
        }
      }
    }
  }

  /// Check if crash detection should be suppressed (e.g., in airplane)
  bool _shouldSuppressCrashDetection() {
    // Suppress during flight - turbulence can trigger false positives
    if (_isInAirplaneMode) {
      debugPrint(
        'SensorService: ✈️ Crash detection suppressed (airplane mode)',
      );
      return true;
    }

    // Note: Boat mode doesn't suppress detection, just adjusts thresholds
    // Wave impacts are still monitored but with higher threshold

    // Don't suppress in normal conditions
    return false;
  }

  /// Get current airplane mode status
  Map<String, dynamic> get airplaneStatus => {
    'isInAirplaneMode': _isInAirplaneMode,
    'isPotentialFlight': _isPotentialFlight,
    'currentAltitude': _lastKnownAltitude,
    'currentSpeed': _lastKnownSpeed,
    'flightStartAltitude': _flightStartAltitude,
    'flightDetectionTime': _flightDetectionTime?.toIso8601String(),
    'altitudeHistory': _altitudeHistory,
    'isActivelyMoving': _isActivelyMoving,
    'lastMovementDetected': _lastMovementDetected?.toIso8601String(),
  };

  void dispose() {
    stopMonitoring();
    _calibrationTimeoutTimer?.cancel();
    _calibrationAccelerometerSubscription?.cancel();
    _calibrationAccelerometerSubscription = null;
    _batteryCheckTimer?.cancel();
    _patternUpdateTimer?.cancel(); // Cancel pattern learning timer
    _movementTimeoutTimer?.cancel();
  }

  // ===== Power Mode Evaluation =====
  void _maybeAdjustPowerMode({double? magnitude}) {
    // LAB: Freeze in LOW POWER during lab to avoid ACTIVE mode switches
    if (AppConstants.labSuppressAllSOSDialogs) {
      if (!_isLowPowerMode) {
        setLowPowerMode();
      }
      return;
    }
    if (!_isMonitoring) return;

    // Hold mode for a minimum duration to prevent flapping
    final now = DateTime.now();
    if (_lastPowerModeSwitch != null &&
        now.difference(_lastPowerModeSwitch!) < _minModeHold) {
      return;
    }

    // Airplane mode always enforces low power
    if (_isInAirplaneMode) {
      if (!_isLowPowerMode) {
        setLowPowerMode();
        _lastPowerModeSwitch = now;
        _logCompactStatusIfNeeded(force: true);
      }
      return;
    }

    // Determine risk level from context
    final speed = _lastKnownSpeed ?? 0.0;
    final motionStrong = _isInSignificantMotion();
    final accelHigh = (magnitude != null && magnitude > 20.0);

    final bool highRisk =
        speed >= 50.0 ||
        (motionStrong && accelHigh) ||
        _isPotentialCrashInProgress;

    if (highRisk && _isLowPowerMode) {
      setActiveMode();
      _lastPowerModeSwitch = now;
      _logCompactStatusIfNeeded(force: true);
      return;
    }

    final bool safeOrNormal = speed < 15.0 && !accelHigh;
    if (safeOrNormal && !_isLowPowerMode) {
      setLowPowerMode();
      _lastPowerModeSwitch = now;
      _logCompactStatusIfNeeded(force: true);
    }
  }

  // ===== Granular Status =====
  String getRiskLevel() {
    if (_isInAirplaneMode) return 'Low (Airplane)';
    if (_isPotentialCrashInProgress) return 'High';
    final speed = _lastKnownSpeed ?? 0.0;
    // Tuned thresholds: Medium ≥ 40 km/h, High ≥ 70 km/h
    if (speed >= 70.0) return 'High';
    if (speed >= 40.0) return 'Medium';
    if (_isInSignificantMotion()) return 'Medium';
    return 'Low';
  }

  String getCompactStatusSummary() {
    final mode = _isMonitoring
        ? (_isLowPowerMode ? 'Low power' : 'Active')
        : 'Off';
    final context = _isInAirplaneMode
        ? 'Airplane'
        : (_isOnBoat ? 'Boat' : 'Normal');
    final motion = _isUserLikelyStationary
        ? 'Stationary'
        : (_isActivelyMoving
              ? (_lastKnownSpeed != null && _lastKnownSpeed! > 5
                    ? 'Driving ${_lastKnownSpeed!.toStringAsFixed(0)} km/h'
                    : 'Moving')
              : 'Idle');
    final risk = getRiskLevel();
    return 'Mode: $mode • Motion: $motion • Context: $context • Risk: $risk';
  }

  // Public getters for UI granularity
  bool get isActivelyMoving => _isActivelyMoving;
  double? get lastKnownSpeed => _lastKnownSpeed;
  bool get isInAirplaneMode => _isInAirplaneMode;
  bool get isOnBoat => _isOnBoat;
  bool get isUserLikelyStationary => _isUserLikelyStationary;

  // ===== Helpers: post-impact immobility and status logging =====
  void _schedulePostImpactImmobilityCheck({int windowSeconds = 5}) {
    final checkAfter = Duration(seconds: windowSeconds);
    Future.delayed(checkAfter, () {
      try {
        // Assess last 2 seconds of readings for minimal movement
        final recent = _accelerometerBuffer
            .where((r) => DateTime.now().difference(r.timestamp).inSeconds < 2)
            .toList();
        if (recent.isEmpty) return;
        final magnitudes = recent
            .map((r) => _convertToRealWorldAcceleration(r.magnitude))
            .toList();
        final avg = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
        if (avg <= 12.0) {
          debugPrint(
            'SensorService: 🧪 Post-impact immobility confirmed (avg ${avg.toStringAsFixed(1)} m/s² over 2s)',
          );
        } else {
          debugPrint(
            'SensorService: 🧪 Post-impact movement detected (avg ${avg.toStringAsFixed(1)} m/s² over 2s)',
          );
        }
      } catch (_) {}
    });
  }

  void _logCompactStatusIfNeeded({bool force = false}) {
    final summary = getCompactStatusSummary();
    final now = DateTime.now();
    final tooSoon =
        _lastStatusLogTime != null &&
        now.difference(_lastStatusLogTime!) < _statusLogThrottle;
    if (force || summary != _lastStatusSummary || !tooSoon) {
      debugPrint('SensorService: 📋 $summary');
      _lastStatusSummary = summary;
      _lastStatusLogTime = now;
    }
  }

  /// Print comprehensive diagnostics for troubleshooting ACFD issues
  void printDiagnostics() {
    debugPrint('');
    debugPrint('═══════════════════════════════════════');
    debugPrint('   SENSOR SERVICE DIAGNOSTICS');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Status:');
    debugPrint('  Monitoring: ${_isMonitoring ? "✅ ACTIVE" : "❌ STOPPED"}');
    debugPrint(
      '  Crash Detection: ${_crashDetectionEnabled ? "✅ ENABLED" : "❌ DISABLED"}',
    );
    debugPrint(
      '  Fall Detection: ${_fallDetectionEnabled ? "✅ ENABLED" : "❌ DISABLED"}',
    );
    debugPrint('  Low Power Mode: ${_isLowPowerMode ? "🔋 YES" : "⚡ NO"}');
    debugPrint('  Calibrated: ${_isCalibrated ? "✅ YES" : "⚠️ NO"}');
    debugPrint('');
    debugPrint('Thresholds:');
    debugPrint('  Crash: ${_crashThreshold.toStringAsFixed(1)} m/s²');
    debugPrint('  Fall: ${_fallThreshold.toStringAsFixed(1)} m/s²');
    debugPrint('  Severe: ${_severeImpactThreshold.toStringAsFixed(1)} m/s²');
    debugPrint('  Phone Drop: ${_phoneDropThreshold.toStringAsFixed(1)} m/s²');
    debugPrint('');
    debugPrint('Buffer Status:');
    debugPrint('  Accelerometer: ${_accelerometerBuffer.length} readings');
    debugPrint('  Gyroscope: ${_gyroscopeBuffer.length} readings');
    debugPrint('');
    debugPrint('Last Detection:');
    debugPrint('  Crash: ${_lastCrashDetection?.toString() ?? "Never"}');
    debugPrint('  Fall: ${_lastFallDetection?.toString() ?? "Never"}');
    debugPrint('');
    debugPrint('Battery:');
    debugPrint('  Level: $_currentBatteryLevel%');
    debugPrint('  Charging: ${_isCharging ? "Yes" : "No"}');
    debugPrint('  Sleeping: ${_isLikelySleeping ? "Yes" : "No"}');
    debugPrint('');
    debugPrint('Test Mode:');
    debugPrint(
      '  Enabled: ${AppConstants.testingModeEnabled ? "✅ YES" : "❌ NO"}',
    );
    if (AppConstants.testingModeEnabled) {
      debugPrint(
        '  Crash Threshold (test): ${AppConstants.getCrashThreshold().toStringAsFixed(1)} m/s²',
      );
      debugPrint(
        '  Fall Threshold (test): ${AppConstants.getFallThreshold().toStringAsFixed(1)} m/s²',
      );
    }
    debugPrint('═══════════════════════════════════════');
    debugPrint('');
  }
}
