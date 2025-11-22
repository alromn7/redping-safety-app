// ignore_for_file: dead_code, unused_element
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_reading.dart';
import '../models/verification_result.dart';
import 'location_service.dart';
import 'verification_ml_adapter.dart';
import '../config/env.dart';
import '../config/testing_mode.dart';
import '../core/constants/app_constants.dart';
import 'verification_physics_utils.dart';
// Removed dependency on SensorService test mode; AI runs with production logic

/// Advanced AI verification service for crash and fall detection
/// Implements sophisticated algorithms to reduce false alarms
class AIVerificationService {
  static const Duration _verificationWindow = Duration(seconds: 30);
  static const Duration _motionResumeWindow = Duration(seconds: 90);
  static const Duration _fallInactivityWindow = Duration(seconds: 15);

  // Crash detection thresholds
  static const double _crashDecelThreshold = 25.0; // m/s²
  static const double _crashJerkThreshold = 80.0; // m/s³
  static const double _impactSpikeThreshold = 30.0; // m/s²
  static const double _stationarySpeedThreshold = 2.0; // m/s

  // Fall detection thresholds
  static const double _freeFallThreshold = 2.0; // m/s²
  static const double _fallImpactThreshold = 20.0; // m/s²

  final LocationService _locationService;
  // Note: NotificationService will be used for AI verification alerts in future updates

  // Emergency mode integration
  bool _isEmergencyMode = false;

  // Detection state
  bool _isVerifying = false;
  bool _isMonitoring = true;
  Timer? _verificationTimer;
  Timer? _motionResumeTimer;

  // Performance optimization
  DateTime? _lastRepetitiveLogTime;
  int _repetitiveLogCount = 0;
  static const Duration _logThrottleDuration = Duration(seconds: 10);
  static const int _maxRepetitiveLogs = 3;
  // Additional cooldown for common noisy log
  DateTime? _lastEmulatorPatternLog;

  // Sensor data buffers
  final List<SensorReading> _accelerometerBuffer = [];
  final List<SensorReading> _gyroscopeBuffer = [];
  final List<double> _speedBuffer = [];
  final List<DateTime> _interactionBuffer = [];

  // Detection context
  DetectionContext? _currentContext;
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  // Optional ML adapter (Phase 0 stub) to augment confidence scoring
  VerificationMLAdapter? _mlAdapter;
  // External feed mode: when true, host service provides sensor events.
  bool _externalFeedEnabled = false;
  Timer? _locationTimer;

  // Callbacks
  Function(VerificationResult)? _onVerificationComplete;
  Function(DetectionEvent)? _onDetectionEvent;
  // External gate to decide if verification is allowed to start
  bool Function(DetectionContext context)? _verificationGate;

  AIVerificationService({required LocationService locationService})
    : _locationService = locationService;

  /// Initialize the AI verification service
  Future<void> initialize() async {
    try {
      if (_externalFeedEnabled) {
        // In external feed mode, do not subscribe to sensors here.
        // Still start location timer for speed/context features.
        _startLocationTimer();
      } else {
        await _startSensorMonitoring();
      }
      debugPrint('AIVerificationService: Initialized successfully');
    } catch (e) {
      debugPrint('AIVerificationService: Error initializing - $e');
    }
  }

  /// Start sensor monitoring for detection
  Future<void> _startSensorMonitoring() async {
    _accelSubscription = userAccelerometerEventStream().listen(
      _processAccelerometerDataOptimized,
    );
    _gyroSubscription = gyroscopeEventStream().listen(_processGyroscopeData);
    _startLocationTimer();
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      _isEmergencyMode
          ? const Duration(seconds: 10)
          : const Duration(seconds: 30),
      (timer) {
        if (!_isMonitoring) {
          timer.cancel();
          return;
        }
        _updateLocationDataOptimized();
      },
    );
  }

  /// Legacy processing method removed (replaced by optimized pipeline)
  /// Note: The optimized handlers are wired in initialize/start and used at runtime.

  /// Determine if sensor data should be processed based on motion and height changes
  bool _shouldProcessSensorData(SensorReading reading, double magnitude) {
    // Check if phone is in significant motion (vehicle movement)
    if (_isInSignificantMotion(magnitude)) {
      return true;
    }

    // Check for height changes (fall detection)
    if (_isHeightChanging()) {
      return true;
    }

    // Check for sudden acceleration changes (crash detection)
    if (_isSuddenAccelerationChange(magnitude)) {
      return true;
    }

    // Otherwise, skip processing to save battery
    return false;
  }

  /// Check if phone is in significant motion (like in a moving vehicle)
  bool _isInSignificantMotion(double magnitude) {
    if (_accelerometerBuffer.length < 10) return false;

    // Calculate average magnitude over last 10 readings
    final recentReadings = _accelerometerBuffer
        .skip(_accelerometerBuffer.length - 10)
        .toList();
    final avgMagnitude =
        recentReadings
            .map((r) => sqrt(r.x * r.x + r.y * r.y + r.z * r.z))
            .reduce((a, b) => a + b) /
        recentReadings.length;

    // Significant motion if average is above normal gravity + movement
    return avgMagnitude > 12.0; // Above normal gravity (9.8) + movement
  }

  /// Check if phone is experiencing height changes
  bool _isHeightChanging() {
    if (_accelerometerBuffer.length < 20) return false;

    final recentReadings = _accelerometerBuffer
        .skip(_accelerometerBuffer.length - 20)
        .toList();

    // Check for free fall pattern (height change)
    int lowGravityCount = 0;
    for (final reading in recentReadings) {
      final magnitude = sqrt(
        reading.x * reading.x + reading.y * reading.y + reading.z * reading.z,
      );
      if (magnitude < 8.0) {
        // Significantly below normal gravity
        lowGravityCount++;
      }
    }

    // Height change if more than 30% of readings show low gravity
    return lowGravityCount > 6;
  }

  /// Check for sudden acceleration changes (potential crash)
  bool _isSuddenAccelerationChange(double currentMagnitude) {
    if (_accelerometerBuffer.length < 5) return false;

    final recentReadings = _accelerometerBuffer
        .skip(_accelerometerBuffer.length - 5)
        .toList();
    final previousMagnitude = sqrt(
      recentReadings.first.x * recentReadings.first.x +
          recentReadings.first.y * recentReadings.first.y +
          recentReadings.first.z * recentReadings.first.z,
    );

    // Sudden change if magnitude increased by more than 50%
    final changePercent =
        (currentMagnitude - previousMagnitude) / previousMagnitude;
    return changePercent > 0.5 && currentMagnitude > 15.0;
  }

  /// Process gyroscope data
  void _processGyroscopeData(GyroscopeEvent event) {
    if (!_isMonitoring || _isVerifying) return;

    // Validate gyroscope data
    if (!_isValidSensorReading(event.x, event.y, event.z)) {
      return;
    }

    final reading = SensorReading(
      timestamp: DateTime.now(),
      x: event.x,
      y: event.y,
      z: event.z,
    );

    _gyroscopeBuffer.add(reading);
    if (_gyroscopeBuffer.length > 100) {
      _gyroscopeBuffer.removeAt(0);
    }
  }

  /// Enable or disable external feed mode. Must be set BEFORE initialize().
  void enableExternalFeed(bool enabled) {
    _externalFeedEnabled = enabled;
    debugPrint(
      'AIVerificationService: External feed ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Accept accelerometer events from host service in external feed mode.
  void processExternalAccelerometer(AccelerometerEvent event) {
    if (!_externalFeedEnabled) return;
    final userEvent = UserAccelerometerEvent(
      event.x,
      event.y,
      event.z,
      DateTime.now(),
    );
    _processAccelerometerDataOptimized(userEvent);
  }

  /// Accept gyroscope events from host service in external feed mode.
  void processExternalGyroscope(GyroscopeEvent event) {
    if (!_externalFeedEnabled) return;
    _processGyroscopeData(event);
  }

  /// Update location and speed data
  // Legacy location updater removed (replaced by optimized updater)

  /// Check for crash conditions using multiple heuristics
  void _checkCrashConditions(SensorReading reading, double magnitude) {
    if (_accelerometerBuffer.length < 10) return;

    // Check if AI verification is enabled by user
    // Note: We'll add user preference checking in a future update

    // In debug mode, be more restrictive to prevent false alarms during development
    if (kDebugMode && magnitude > 30.0) {
      debugPrint(
        'AIVerificationService: Ignoring high magnitude in debug mode: $magnitude m/s²',
      );
      return;
    }

    // Additional filtering for development/emulator environments
    // Check for consistent extreme readings that indicate sensor malfunction
    final recentReadings = _accelerometerBuffer
        .skip(_accelerometerBuffer.length - 10)
        .toList();

    // If most recent readings are identical (emulator pattern), ignore
    final identicalReadings = recentReadings
        .where((r) => (r.calculatedMagnitude - magnitude).abs() < 0.1)
        .length;
    if (identicalReadings > 7) {
      // Log at most once per minute to avoid spam
      final now = DateTime.now();
      if (_lastEmulatorPatternLog == null ||
          now.difference(_lastEmulatorPatternLog!) >
              const Duration(minutes: 1)) {
        _lastEmulatorPatternLog = now;
        debugPrint(
          'AIVerificationService: Ignoring repetitive sensor pattern (emulator)',
        );
      }
      return;
    }

    // Calculate deceleration over short window
    final deceleration =
        VerificationPhysicsUtils.decelerationFrom<SensorReading>(
          recentReadings,
          (r) => sqrt(r.x * r.x + r.y * r.y + r.z * r.z),
          (r) => r.timestamp,
        );

    // Calculate jerk (rate of acceleration change)
    final jerk = VerificationPhysicsUtils.jerkFrom<SensorReading>(
      recentReadings,
      (r) => sqrt(r.x * r.x + r.y * r.y + r.z * r.z),
      (r) => r.timestamp,
    );

    // Check for impact spike (but not if magnitude is suspiciously high)
    final hasImpactSpike =
        magnitude > _impactSpikeThreshold && magnitude < 40.0;

    // Check if vehicle was stationary
    final currentSpeed = _speedBuffer.isNotEmpty ? _speedBuffer.last : 0.0;
    final wasStationary = currentSpeed < _stationarySpeedThreshold;

    // Crash detection logic with additional validation
    bool crashDetected = false;
    DetectionReason reason = DetectionReason.none;

    // No AI-level detection cooldown; SensorService blueprint handles gating

    if (deceleration > _crashDecelThreshold && deceleration < 100.0) {
      crashDetected = true;
      reason = DetectionReason.sharpDeceleration;
    } else if (jerk > _crashJerkThreshold && jerk < 200.0) {
      crashDetected = true;
      reason = DetectionReason.highJerk;
    } else if (hasImpactSpike && !wasStationary) {
      crashDetected = true;
      reason = DetectionReason.impactSpike;
    } else if (hasImpactSpike && wasStationary) {
      crashDetected = true;
      reason = DetectionReason.stationaryImpact;
    }

    if (crashDetected) {
      // Do not set cooldown here; only set when verification actually starts
      _triggerCrashVerification(reason, magnitude, deceleration, jerk);
    }
  }

  /// Check for fall conditions
  void _checkFallConditions(SensorReading reading, double magnitude) {
    if (_accelerometerBuffer.length < 20) return;

    // Do not apply extra debug-mode gating here; rely on blueprint gate

    // Check for free fall pattern
    final freeFallDetected =
        VerificationPhysicsUtils.freeFallFrom<SensorReading>(
          _accelerometerBuffer,
          (r) => sqrt(r.x * r.x + r.y * r.y + r.z * r.z),
          threshold: _freeFallThreshold,
          window: 20,
          ratio: 0.6,
        );

    if (freeFallDetected) {
      // Check for impact after free fall
      final impactDetected = magnitude > _fallImpactThreshold;

      if (impactDetected) {
        _triggerFallVerification(magnitude);
      }
    }
  }

  /// Detect free fall pattern in sensor data
  bool _detectFreeFall() {
    if (_accelerometerBuffer.length < 20) return false;

    final recentReadings = _accelerometerBuffer
        .skip(_accelerometerBuffer.length - 20)
        .toList();
    int lowGravityCount = 0;

    for (final reading in recentReadings) {
      final magnitude = sqrt(
        reading.x * reading.x + reading.y * reading.y + reading.z * reading.z,
      );
      if (magnitude < _freeFallThreshold) {
        lowGravityCount++;
      }
    }

    // Free fall if majority of recent readings show low gravity
    return lowGravityCount > 12; // 60% of readings
  }

  /// Calculate deceleration from recent readings
  double _calculateDeceleration(List<SensorReading> readings) {
    if (readings.length < 2) return 0.0;

    final first = readings.first;
    final last = readings.last;

    final firstMag = sqrt(
      first.x * first.x + first.y * first.y + first.z * first.z,
    );
    final lastMag = sqrt(last.x * last.x + last.y * last.y + last.z * last.z);

    final timeDiff =
        last.timestamp.difference(first.timestamp).inMilliseconds / 1000.0;

    return timeDiff > 0 ? (lastMag - firstMag).abs() / timeDiff : 0.0;
  }

  /// Calculate jerk (rate of acceleration change)
  double _calculateJerk(List<SensorReading> readings) {
    if (readings.length < 3) return 0.0;

    final accelerations = readings
        .map((r) => sqrt(r.x * r.x + r.y * r.y + r.z * r.z))
        .toList();

    double maxJerk = 0.0;

    for (int i = 2; i < accelerations.length; i++) {
      final timeDiff1 =
          readings[i].timestamp
              .difference(readings[i - 1].timestamp)
              .inMilliseconds /
          1000.0;
      final timeDiff2 =
          readings[i - 1].timestamp
              .difference(readings[i - 2].timestamp)
              .inMilliseconds /
          1000.0;

      if (timeDiff1 > 0 && timeDiff2 > 0) {
        final accel1 = (accelerations[i] - accelerations[i - 1]) / timeDiff1;
        final accel2 =
            (accelerations[i - 1] - accelerations[i - 2]) / timeDiff2;
        final jerk = (accel1 - accel2).abs() / timeDiff1;

        if (jerk > maxJerk) {
          maxJerk = jerk;
        }
      }
    }

    return maxJerk;
  }

  /// Trigger crash verification protocol
  Future<void> _triggerCrashVerification(
    DetectionReason reason,
    double magnitude,
    double deceleration,
    double jerk,
  ) async {
    if (_isVerifying) return;

    final context = DetectionContext(
      type: DetectionType.crash,
      reason: reason,
      timestamp: DateTime.now(),
      magnitude: magnitude,
      deceleration: deceleration,
      jerk: jerk,
      location: await _locationService.getCurrentLocation(),
    );
    _currentContext = context;

    debugPrint('AIVerificationService: Crash detected - ${reason.name}');
    _onDetectionEvent?.call(
      DetectionEvent(
        type: DetectionType.crash,
        reason: reason,
        context: context,
      ),
    );

    // External gate: allow host to decide if verification should start
    if (_verificationGate != null && !_verificationGate!(context)) {
      debugPrint(
        'AIVerificationService: Verification start denied by external gate (crash)',
      );
      _currentContext = null;
      return;
    }

    // Proceed with verification
    _isVerifying = true;
    await _startVerificationProtocol();
  }

  /// Trigger fall verification protocol
  Future<void> _triggerFallVerification(double magnitude) async {
    if (_isVerifying) return;

    final context = DetectionContext(
      type: DetectionType.fall,
      reason: DetectionReason.freeFallImpact,
      timestamp: DateTime.now(),
      magnitude: magnitude,
      location: await _locationService.getCurrentLocation(),
    );
    _currentContext = context;

    debugPrint('AIVerificationService: Fall detected');
    _onDetectionEvent?.call(
      DetectionEvent(
        type: DetectionType.fall,
        reason: DetectionReason.freeFallImpact,
        context: context,
      ),
    );

    // External gate: allow host to decide if verification should start
    if (_verificationGate != null && !_verificationGate!(context)) {
      debugPrint(
        'AIVerificationService: Verification start denied by external gate (fall)',
      );
      _currentContext = null;
      return;
    }

    // Proceed with verification
    _isVerifying = true;
    await _startVerificationProtocol();
  }

  /// Start the AI verification protocol
  Future<void> _startVerificationProtocol() async {
    if (_currentContext == null) return;

    // Start verification with standard production logging
    // Optional testing bypass (compile-time feature flag)
    final testingBypass =
        Env.flag<bool>('aiVerificationTestingMode', false) ||
        TestingMode.aiBypassEnabled ||
        AppConstants.testingModeEnabled;
    if (testingBypass) {
      // Skip all auto-analysis - force manual verification only
      debugPrint(
        'AIVerificationService: [TESTING] Forcing manual verification - skipping auto-analysis',
      );

      // Wait for voice verification timeout without auto-completing
      await Future.delayed(_verificationWindow);

      // If we reach here, user didn't respond
      _completeVerification(
        VerificationResult(
          outcome: VerificationOutcome.noResponse,
          confidence: 0.5,
          reason: '[TESTING] No user response within verification window',
          context: _currentContext!,
        ),
      );
      return;
    }

    // Phase 1: Voice verification
    final voiceResult = await _performVoiceVerification();

    if (voiceResult == VerificationOutcome.userConfirmedOK) {
      _completeVerification(
        VerificationResult(
          outcome: VerificationOutcome.userConfirmedOK,
          confidence: 1.0,
          reason: 'User confirmed they are OK via voice',
          context: _currentContext!,
        ),
      );
      return;
    }

    // Phase 2: Motion analysis (for crash detection)
    if (_currentContext!.type == DetectionType.crash) {
      // Motion analysis (production)
      final motionResult = await _performMotionAnalysis();

      if (motionResult == VerificationOutcome.falseAlarmDetected) {
        _completeVerification(
          VerificationResult(
            outcome: VerificationOutcome.falseAlarmDetected,
            confidence: 0.9,
            reason: 'Motion resumed - likely braking or phone drop',
            context: _currentContext!,
          ),
        );
        return;
      }
    }

    // Phase 3: Inactivity analysis (for fall detection)
    if (_currentContext!.type == DetectionType.fall) {
      // Inactivity analysis (production)
      final inactivityResult = await _performInactivityAnalysis();

      if (inactivityResult == VerificationOutcome.falseAlarmDetected) {
        _completeVerification(
          VerificationResult(
            outcome: VerificationOutcome.falseAlarmDetected,
            confidence: 0.8,
            reason: 'Activity resumed - likely false fall detection',
            context: _currentContext!,
          ),
        );
        return;
      }
    }

    // Phase 4: AI confidence assessment (production)
    final aiResult = await _performAIAssessment();

    _completeVerification(aiResult);
  }

  /// Perform voice verification with TTS prompt
  Future<VerificationOutcome> _performVoiceVerification() async {
    try {
      // Generate contextual prompt
      final prompt = _generateVerificationPrompt();

      debugPrint(
        'AIVerificationService: Starting voice verification - "$prompt"',
      );

      // TTS disabled; log prompt for verification
      debugPrint('AIVerificationService (prompt): $prompt');

      // Wait for user response with timeout
      // Standard production timeout window
      final timeout = _verificationWindow;

      final completer = Completer<VerificationOutcome>();

      _verificationTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(VerificationOutcome.noResponse);
        }
      });

      // Listen for user interactions (tap, speech, movement)
      _startInteractionMonitoring(completer);

      return await completer.future;
    } catch (e) {
      debugPrint('AIVerificationService: Voice verification error - $e');
      return VerificationOutcome.noResponse;
    }
  }

  /// Generate contextual verification prompt
  String _generateVerificationPrompt() {
    if (_currentContext == null) return 'Are you OK?';

    switch (_currentContext!.type) {
      case DetectionType.crash:
        switch (_currentContext!.reason) {
          case DetectionReason.sharpDeceleration:
            return 'Sudden stop detected. Are you OK? Say "I\'m OK" or tap your screen if you\'re safe.';
          case DetectionReason.highJerk:
            return 'Rapid movement change detected. Are you OK? Say "I\'m OK" or tap your screen if you\'re safe.';
          case DetectionReason.impactSpike:
            return 'Impact detected. Are you OK? Say "I\'m OK" or tap your screen if you\'re safe.';
          case DetectionReason.stationaryImpact:
            return 'Impact while stationary detected. Are you OK? Say "I\'m OK" or tap your screen if you\'re safe.';
          default:
            return 'Crash detected. Are you OK? Say "I\'m OK" or tap your screen if you\'re safe.';
        }
      case DetectionType.fall:
        return 'Fall detected. Are you OK? Say "I\'m OK" or tap your screen if you need help.';
    }
  }

  /// Start monitoring for user interactions
  void _startInteractionMonitoring(Completer<VerificationOutcome> completer) {
    // Monitor for device movement (user picking up phone)
    final interactionSubscription = userAccelerometerEventStream().listen((
      event,
    ) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Detect deliberate movement patterns
      if (magnitude > 15.0 && !completer.isCompleted) {
        _interactionBuffer.add(DateTime.now());

        // If multiple interactions in short time, user is responsive
        if (_interactionBuffer.length >= 3) {
          final timeSpan = _interactionBuffer.last.difference(
            _interactionBuffer.first,
          );
          if (timeSpan.inSeconds < 5) {
            completer.complete(VerificationOutcome.userConfirmedOK);
          }
        }
      }
    });

    // Clean up subscription when verification completes
    completer.future.then((_) {
      interactionSubscription.cancel();
      _verificationTimer?.cancel();
    });
  }

  /// Perform motion analysis to detect false alarms
  Future<VerificationOutcome> _performMotionAnalysis() async {
    debugPrint('AIVerificationService: Starting motion analysis...');

    final completer = Completer<VerificationOutcome>();

    _motionResumeTimer = Timer(_motionResumeWindow, () {
      if (!completer.isCompleted) {
        completer.complete(VerificationOutcome.genuineIncident);
      }
    });

    // Monitor for motion resume
    final motionSubscription = userAccelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Check for normal movement patterns
      if (_isNormalMovement(magnitude)) {
        if (!completer.isCompleted) {
          completer.complete(VerificationOutcome.falseAlarmDetected);
        }
      }
    });

    // Monitor for speed increase (vehicle acceleration)
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (completer.isCompleted) {
        timer.cancel();
        return;
      }

      try {
        final location = await _locationService.getCurrentLocation();
        final currentSpeed = location?.speed ?? 0.0;

        // If speed increases significantly, likely false alarm
        if (currentSpeed > _stationarySpeedThreshold * 2) {
          if (!completer.isCompleted) {
            completer.complete(VerificationOutcome.falseAlarmDetected);
          }
          timer.cancel();
        }
      } catch (e) {
        debugPrint('AIVerificationService: Error checking speed - $e');
      }
    });

    final result = await completer.future;
    motionSubscription.cancel();
    _motionResumeTimer?.cancel();

    return result;
  }

  /// Perform inactivity analysis for fall detection
  Future<VerificationOutcome> _performInactivityAnalysis() async {
    debugPrint('AIVerificationService: Starting inactivity analysis...');

    final completer = Completer<VerificationOutcome>();

    Timer(_fallInactivityWindow, () {
      if (!completer.isCompleted) {
        completer.complete(VerificationOutcome.genuineIncident);
      }
    });

    // Monitor for activity resume
    final activitySubscription = userAccelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Check for deliberate movement
      if (_isDeliberateMovement(magnitude)) {
        if (!completer.isCompleted) {
          completer.complete(VerificationOutcome.falseAlarmDetected);
        }
      }
    });

    final result = await completer.future;
    activitySubscription.cancel();

    return result;
  }

  /// Perform AI assessment of detection confidence
  Future<VerificationResult> _performAIAssessment() async {
    if (_currentContext == null) {
      return VerificationResult(
        outcome: VerificationOutcome.genuineIncident,
        confidence: 0.5,
        reason: 'No context available',
        context: _currentContext!,
      );
    }

    double confidence = 0.5;
    String reason = 'AI assessment';

    // Analyze detection context
    final contextScore = _analyzeDetectionContext();
    final environmentScore = _analyzeEnvironmentalFactors();
    final historicalScore = _analyzeHistoricalPatterns();

    confidence = (contextScore + environmentScore + historicalScore) / 3.0;

    // If ML adapter available, blend ML probability with heuristic confidence
    if (_mlAdapter != null && _mlAdapter!.isModelLoaded) {
      try {
        final features = _buildVerificationFeatures();
        final mlProb = _mlAdapter!.applyCalibration(
          _mlAdapter!.predictIncidentProbability(features),
        );
        // Blend: heuristic retains stronger weight for safety overrides
        confidence = (0.6 * confidence + 0.4 * mlProb).clamp(0.0, 1.0);
        reason += ' (ML blended: ${(mlProb * 100).toStringAsFixed(1)}%)';
      } catch (e) {
        debugPrint('AIVerificationService: ML adapter error - $e');
      }
    }

    // Determine outcome based on confidence
    VerificationOutcome outcome;
    if (confidence > 0.8) {
      outcome = VerificationOutcome.genuineIncident;
      reason = 'High confidence genuine incident';
    } else if (confidence < 0.3) {
      outcome = VerificationOutcome.falseAlarmDetected;
      reason = 'Low confidence - likely false alarm';
    } else {
      outcome = VerificationOutcome.uncertainIncident;
      reason = 'Moderate confidence - requires manual verification';
    }

    return VerificationResult(
      outcome: outcome,
      confidence: confidence,
      reason: reason,
      context: _currentContext!,
    );
  }

  /// Analyze detection context for confidence scoring
  double _analyzeDetectionContext() {
    if (_currentContext == null) return 0.5;

    double score = 0.5;

    // Higher magnitude = higher confidence
    if (_currentContext!.magnitude > 40.0) score += 0.2;
    if (_currentContext!.magnitude > 60.0) score += 0.2;

    // Multiple detection reasons = higher confidence
    if (_currentContext!.deceleration != null &&
        _currentContext!.deceleration! > _crashDecelThreshold) {
      score += 0.1;
    }
    if (_currentContext!.jerk != null &&
        _currentContext!.jerk! > _crashJerkThreshold) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Analyze environmental factors
  double _analyzeEnvironmentalFactors() {
    double score = 0.5;

    // Speed context
    if (_speedBuffer.isNotEmpty) {
      final avgSpeed =
          _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;

      // Higher speed = higher crash likelihood
      if (avgSpeed > 10.0) score += 0.1; // 36 km/h
      if (avgSpeed > 20.0) score += 0.2; // 72 km/h

      // Very low speed = lower crash likelihood
      if (avgSpeed < 1.0) score -= 0.2;
    }

    // Time of day context
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 6) {
      score += 0.1; // Higher risk during night hours
    }

    return score.clamp(0.0, 1.0);
  }

  /// Analyze historical patterns
  double _analyzeHistoricalPatterns() {
    // For now, return baseline score
    // Future: Implement machine learning based on user patterns
    return 0.5;
  }

  /// Check if movement pattern indicates normal activity
  bool _isNormalMovement(double magnitude) {
    // Normal movement: 5-15 m/s² sustained over time
    return magnitude > 5.0 && magnitude < 15.0;
  }

  /// Check if movement pattern indicates deliberate activity
  bool _isDeliberateMovement(double magnitude) {
    // Deliberate movement: controlled patterns above normal gravity
    return magnitude > 12.0 && magnitude < 25.0;
  }

  /// Install ML adapter (optional). Does not alter severe-impact overrides.
  void setMLAdapter(VerificationMLAdapter adapter) {
    _mlAdapter = adapter;
    debugPrint('AIVerificationService: ML adapter installed');
  }

  /// Build feature vector for ML blending using existing buffers & context.
  VerificationFeatures _buildVerificationFeatures() {
    // Peak magnitude: current context magnitude
    final peakMag = _currentContext?.magnitude ?? 0.0;
    // Sustained high-impact count (heuristic: > impactSpikeThreshold in recent 20 readings)
    int sustainedCount = 0;
    if (_accelerometerBuffer.isNotEmpty) {
      final recent = _accelerometerBuffer.length > 20
          ? _accelerometerBuffer.sublist(_accelerometerBuffer.length - 20)
          : _accelerometerBuffer;
      for (final r in recent) {
        final mag = sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
        if (mag > _impactSpikeThreshold) sustainedCount++;
      }
    }
    // Deceleration & jerk from context (already computed)
    final decel = _currentContext?.deceleration ?? 0.0;
    final jerk = _currentContext?.jerk ?? 0.0;
    // Impact duration (approximate: time span of last readings above impact threshold)
    double impactDuration = 0.0;
    DateTime? start;
    DateTime? end;
    for (final r in _accelerometerBuffer) {
      final mag = sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
      if (mag > _impactSpikeThreshold) {
        start ??= r.timestamp;
        end = r.timestamp;
      }
    }
    if (start != null && end != null) {
      impactDuration = end.difference(start).inMilliseconds / 1000.0;
    }
    // Pre-impact avg speed: last 5 speed entries prior to verification start
    double preImpactAvgSpeed = 0.0;
    if (_speedBuffer.isNotEmpty) {
      final sample = _speedBuffer.length > 5
          ? _speedBuffer.sublist(_speedBuffer.length - 5)
          : _speedBuffer;
      preImpactAvgSpeed = sample.reduce((a, b) => a + b) / sample.length;
    }
    // Post-impact avg magnitude: last 10 accel readings after context timestamp
    double postImpactAvgMag = 0.0;
    if (_currentContext != null) {
      final post = _accelerometerBuffer
          .where((r) => r.timestamp.isAfter(_currentContext!.timestamp))
          .toList();
      if (post.isNotEmpty) {
        final tail = post.length > 10 ? post.sublist(post.length - 10) : post;
        postImpactAvgMag =
            tail
                .map((r) => sqrt(r.x * r.x + r.y * r.y + r.z * r.z))
                .reduce((a, b) => a + b) /
            tail.length;
      }
    }
    // Motion resumed heuristic (normal movement pattern in buffer)
    final motionResumed = _accelerometerBuffer.any((r) {
      final mag = sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
      return _isNormalMovement(mag);
    });
    // Free-fall pattern reuse
    final freeFallPattern = _detectFreeFall();
    // Throw pattern approximation (free-fall + multiple impacts)
    final throwPattern = freeFallPattern && sustainedCount >= 2;
    // Stationary pre-impact (avg speed low)
    final stationaryPreImpact = preImpactAvgSpeed < _stationarySpeedThreshold;
    // Night hour factor
    final hour = DateTime.now().hour;
    final nightHourFactor = (hour >= 22 || hour <= 6) ? 1.0 : 0.0;
    // Placeholder modes (extend with actual integration later)
    final lowPowerMode = false; // TODO: integrate device power manager
    final airplaneMode = false; // TODO: integrate airplane mode status
    final boatMode = false; // TODO: integrate boat mode status
    // Historical placeholders (Phase 0)
    final falseAlarmRate7d = 0.0;
    final genuineIncidents7d = 0;

    return VerificationFeatures(
      peakMagnitude: peakMag,
      sustainedHighImpactCount: sustainedCount,
      deceleration: decel,
      jerk: jerk,
      impactDurationSeconds: impactDuration,
      preImpactAvgSpeed: preImpactAvgSpeed,
      postImpactAvgMagnitude: postImpactAvgMag,
      motionResumed: motionResumed,
      freeFallPattern: freeFallPattern,
      throwPattern: throwPattern,
      stationaryPreImpact: stationaryPreImpact,
      nightHourFactor: nightHourFactor,
      lowPowerMode: lowPowerMode,
      airplaneMode: airplaneMode,
      boatMode: boatMode,
      falseAlarmRate7d: falseAlarmRate7d,
      genuineIncidents7d: genuineIncidents7d,
    );
  }

  /// Complete verification process
  void _completeVerification(VerificationResult result) {
    debugPrint(
      'AIVerificationService: Verification complete - ${result.outcome.name} (${(result.confidence * 100).toStringAsFixed(1)}%)',
    );

    _isVerifying = false;
    _verificationTimer?.cancel();
    _motionResumeTimer?.cancel();
    _currentContext = null;
    _interactionBuffer.clear();

    _onVerificationComplete?.call(result);
  }

  /// Record user interaction (for external triggers)
  void recordUserInteraction(InteractionType type) {
    if (!_isVerifying) return;

    debugPrint(
      'AIVerificationService: User interaction recorded - ${type.name}',
    );

    if (type == InteractionType.cancelTap ||
        type == InteractionType.okResponse) {
      _completeVerification(
        VerificationResult(
          outcome: VerificationOutcome.userConfirmedOK,
          confidence: 1.0,
          reason: 'User manually confirmed OK',
          context: _currentContext!,
        ),
      );
    }
  }

  /// Set verification completion callback
  void setVerificationCallback(Function(VerificationResult) callback) {
    _onVerificationComplete = callback;
  }

  /// Set detection event callback
  void setDetectionCallback(Function(DetectionEvent) callback) {
    _onDetectionEvent = callback;
  }

  /// Enable/disable monitoring
  void setMonitoring(bool enabled) {
    _isMonitoring = enabled;
    debugPrint(
      'AIVerificationService: Monitoring ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Set external verification gate that decides if AI may start verification
  void setVerificationGate(bool Function(DetectionContext context) gate) {
    _verificationGate = gate;
    debugPrint('AIVerificationService: External verification gate installed');
  }

  /// Get current verification status
  bool get isVerifying => _isVerifying;

  /// Get current detection context
  DetectionContext? get currentContext => _currentContext;

  /// Validate sensor reading to prevent extreme values
  bool _isValidSensorReading(double x, double y, double z) {
    // Check for NaN or infinite values
    if (!x.isFinite || !y.isFinite || !z.isFinite) {
      return false;
    }

    // Check for extremely large values that could indicate sensor malfunction
    const double maxReasonableValue = 100.0; // m/s² (more restrictive for AI)
    if (x.abs() > maxReasonableValue ||
        y.abs() > maxReasonableValue ||
        z.abs() > maxReasonableValue) {
      return false;
    }

    return true;
  }

  /// Throttled logging to prevent spam
  void _throttledLog(String message) {
    final now = DateTime.now();

    if (_lastRepetitiveLogTime == null ||
        now.difference(_lastRepetitiveLogTime!) > _logThrottleDuration) {
      _lastRepetitiveLogTime = now;
      _repetitiveLogCount = 1;
      debugPrint(message);
    } else if (_repetitiveLogCount < _maxRepetitiveLogs) {
      _repetitiveLogCount++;
      debugPrint(message);
    }
    // After max logs, silently ignore until throttle period resets
  }

  /// Ultra-optimized sensor processing - only when motion detected
  void _processAccelerometerDataOptimized(UserAccelerometerEvent event) {
    if (!_isMonitoring || _isVerifying) return;

    // Validate sensor data to prevent extreme values
    if (!_isValidSensorReading(event.x, event.y, event.z)) {
      return;
    }

    final reading = SensorReading(
      timestamp: DateTime.now(),
      x: event.x,
      y: event.y,
      z: event.z,
    );

    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Filter out extreme readings that could cause false positives
    if (magnitude > 50.0) {
      _throttledLog(
        'AIVerificationService: Ignoring extreme sensor reading: ${magnitude.toStringAsFixed(1)} m/s²',
      );
      return;
    }

    _accelerometerBuffer.add(reading);
    if (_accelerometerBuffer.length > 50) {
      // Reduced buffer size
      _accelerometerBuffer.removeAt(0);
    }

    // Only process every 10th reading AND only when motion detected
    if (_accelerometerBuffer.length % 10 == 0 &&
        _shouldProcessSensorData(reading, magnitude)) {
      // Check for crash conditions
      _checkCrashConditions(reading, magnitude);

      // Check for fall conditions
      _checkFallConditions(reading, magnitude);
    }
  }

  /// Battery-optimized location updates
  Future<void> _updateLocationDataOptimized() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        final speed = location.speed ?? 0.0;
        _speedBuffer.add(speed);
        if (_speedBuffer.length > 30) {
          // Reduced from 60 to 30
          _speedBuffer.removeAt(0);
        }
      }
    } catch (e) {
      _throttledLog('AIVerificationService: Error updating location - $e');
    }
  }

  /// Set emergency mode
  void setEmergencyMode(bool isEmergency) {
    _isEmergencyMode = isEmergency;
    debugPrint(
      'AIVerificationService: Emergency mode ${isEmergency ? 'activated' : 'deactivated'}',
    );
  }

  /// Get emergency mode status
  bool get isEmergencyMode => _isEmergencyMode;

  /// Get emergency-optimized processing interval
  Duration getEmergencyProcessingInterval() {
    if (_isEmergencyMode) {
      return const Duration(minutes: 2); // Every 2 minutes during emergency
    }
    return const Duration(
      seconds: 30,
    ); // Every 30 seconds during normal operation
  }

  /// Dispose of resources
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _verificationTimer?.cancel();
    _motionResumeTimer?.cancel();
    _locationTimer?.cancel();
  }
}
