// ignore_for_file: unused_field, unused_local_variable, unused_element
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'ai_emergency_verification_service.dart';
import 'package:redping_14v/utils/logger.dart';

/// Enhanced emergency detection with AI verification and false positive mitigation
class EnhancedEmergencyDetectionService {
  static final EnhancedEmergencyDetectionService _instance =
      EnhancedEmergencyDetectionService._internal();
  factory EnhancedEmergencyDetectionService() => _instance;
  EnhancedEmergencyDetectionService._internal();

  bool _isInitialized = false;
  bool _isMonitoring = false;

  // AI verification service
  final AIEmergencyVerificationService _aiVerification =
      AIEmergencyVerificationService();

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;

  // Detection parameters
  static const double _crashDecelThreshold = 8.0; // m/s²
  static const double _crashJerkThreshold = 15.0; // m/s³
  static const double _crashImpactThreshold = 20.0; // m/s²
  static const double _fallFreefallThreshold = 0.5; // m/s²
  static const double _fallImpactThreshold = 12.0; // m/s²
  static const double _stationarySpeedThreshold = 2.0; // m/s
  static const Duration _detectionWindow = Duration(seconds: 3);
  static const Duration _motionResumeWindow = Duration(seconds: 120);

  // Detection state
  DateTime? _lastEmergencyDetection;
  DateTime? _lastMotionTime;
  double _lastSpeed = 0.0;
  bool _isStationary = false;
  bool _hasMotionResumed = false;

  // Sensor data buffers
  final List<double> _recentAccelerations = [];
  final List<double> _recentJerk = [];
  final List<double> _recentSpeeds = [];
  final List<Position> _recentPositions = [];

  // Callbacks
  Function(String, Map<String, dynamic>)? _onEmergencyDetected;
  Function(String)? _onError;
  Function()? _onVerificationStarted;
  Function()? _onVerificationCancelled;

  /// Initialize the enhanced detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.i(
      'EnhancedEmergencyDetectionService',
      'Initializing enhanced detection...',
    );

    try {
      // Initialize AI verification service
      await _aiVerification.initialize();

      // Set up AI verification callbacks
      _aiVerification.setOnEmergencyDetected((type, data) {
        _onEmergencyDetected?.call(type, data);
      });

      _aiVerification.setOnError((error) {
        _onError?.call(error);
      });

      _aiVerification.setOnVerificationStarted(() {
        _onVerificationStarted?.call();
      });

      _aiVerification.setOnVerificationCancelled(() {
        _onVerificationCancelled?.call();
      });

      _isInitialized = true;
      Logger.i(
        'EnhancedEmergencyDetectionService',
        'Enhanced detection initialized successfully',
      );
    } catch (e) {
      Logger.e(
        'EnhancedEmergencyDetectionService',
        'Initialization failed - $e',
      );
      rethrow;
    }
  }

  /// Start enhanced emergency monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    // In release builds, disable this low-threshold enhanced monitor entirely to avoid false positives
    if (kReleaseMode) {
      Logger.w(
        'EnhancedEmergencyDetectionService',
        'Start suppressed in release build (uses low thresholds; SensorService handles production detection).',
      );
      return;
    }

    Logger.i(
      'EnhancedEmergencyDetectionService',
      'Starting enhanced monitoring...',
    );

    try {
      _isMonitoring = true;

      // Start AI verification monitoring
      _aiVerification.startMonitoring();

      // Monitor accelerometer for crash/fall detection
      _accelerometerSubscription = accelerometerEventStream().listen(
        _handleAccelerometerData,
        onError: (error) {
          Logger.e(
            'EnhancedEmergencyDetectionService',
            'Accelerometer error - $error',
          );
          _onError?.call('ACCELEROMETER_ERROR');
        },
      );

      // Monitor gyroscope for additional context
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        _handleGyroscopeData,
        onError: (error) {
          Logger.e(
            'EnhancedEmergencyDetectionService',
            'Gyroscope error - $error',
          );
          _onError?.call('GYROSCOPE_ERROR');
        },
      );

      // Monitor GPS for speed and movement
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 1,
            ),
          ).listen(
            _handlePositionData,
            onError: (error) {
              Logger.e(
                'EnhancedEmergencyDetectionService',
                'GPS error - $error',
              );
              _onError?.call('GPS_ERROR');
            },
          );

      Logger.i(
        'EnhancedEmergencyDetectionService',
        'Enhanced monitoring started',
      );
    } catch (e) {
      Logger.e(
        'EnhancedEmergencyDetectionService',
        'Failed to start monitoring - $e',
      );
      _onError?.call('MONITORING_START_FAILED');
    }
  }

  /// Stop enhanced monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    Logger.i(
      'EnhancedEmergencyDetectionService',
      'Stopping enhanced monitoring...',
    );

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _positionSubscription = null;

    _aiVerification.stopMonitoring();
    _isMonitoring = false;

    Logger.i(
      'EnhancedEmergencyDetectionService',
      'Enhanced monitoring stopped',
    );
  }

  /// Handle accelerometer data for crash/fall detection
  void _handleAccelerometerData(AccelerometerEvent event) {
    try {
      // Calculate acceleration magnitude
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Add to recent accelerations
      _recentAccelerations.add(magnitude);
      if (_recentAccelerations.length > 30) {
        _recentAccelerations.removeAt(0);
      }

      // Calculate jerk (rate of change of acceleration)
      if (_recentAccelerations.length >= 2) {
        final jerk =
            (magnitude - _recentAccelerations[_recentAccelerations.length - 2])
                .abs();
        _recentJerk.add(jerk);
        if (_recentJerk.length > 10) {
          _recentJerk.removeAt(0);
        }
      }

      // Check for crash indicators
      _checkForCrashIndicators(magnitude);

      // Check for fall indicators
      _checkForFallIndicators(magnitude);
    } catch (e) {
      Logger.w(
        'EnhancedEmergencyDetectionService',
        'Accelerometer processing error - $e',
        throttle: const Duration(seconds: 5),
      );
    }
  }

  /// Handle gyroscope data for additional context
  void _handleGyroscopeData(GyroscopeEvent event) {
    try {
      // Calculate rotation magnitude
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Use gyroscope data for additional context in crash detection
      // High rotation during impact might indicate vehicle rollover
    } catch (e) {
      Logger.w(
        'EnhancedEmergencyDetectionService',
        'Gyroscope processing error - $e',
        throttle: const Duration(seconds: 5),
      );
    }
  }

  /// Handle GPS position data for speed and movement analysis
  void _handlePositionData(Position position) {
    try {
      _recentPositions.add(position);
      if (_recentPositions.length > 10) {
        _recentPositions.removeAt(0);
      }

      _lastSpeed = position.speed;
      _isStationary = position.speed < _stationarySpeedThreshold;
      _lastMotionTime = DateTime.now();

      // Check if motion has resumed after a potential crash
      if (_hasMotionResumed == false &&
          position.speed > _stationarySpeedThreshold) {
        _hasMotionResumed = true;
        Logger.d(
          'EnhancedEmergencyDetectionService',
          'Motion resumed - ${position.speed} m/s',
          throttle: const Duration(seconds: 10),
        );
      }
    } catch (e) {
      Logger.w(
        'EnhancedEmergencyDetectionService',
        'GPS processing error - $e',
        throttle: const Duration(seconds: 5),
      );
    }
  }

  /// Check for crash indicators using multiple heuristics
  void _checkForCrashIndicators(double magnitude) {
    try {
      // 1. Sharp deceleration detection
      if (_recentSpeeds.length >= 3) {
        final speedChange =
            _recentSpeeds.last - _recentSpeeds[_recentSpeeds.length - 3];
        if (speedChange < -_crashDecelThreshold) {
          Logger.d(
            'EnhancedEmergencyDetectionService',
            'Sharp deceleration detected: $speedChange m/s',
            throttle: const Duration(seconds: 5),
          );
          _triggerCrashVerification('SHARP_DECELERATION', {
            'type': 'sharp_deceleration',
            'speed_change': speedChange,
            'threshold': _crashDecelThreshold,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }
      }

      // 2. High jerk detection
      if (_recentJerk.length >= 3) {
        final avgJerk =
            _recentJerk.reduce((a, b) => a + b) / _recentJerk.length;
        if (avgJerk > _crashJerkThreshold) {
          Logger.d(
            'EnhancedEmergencyDetectionService',
            'High jerk detected: $avgJerk m/s³',
            throttle: const Duration(seconds: 5),
          );
          _triggerCrashVerification('HIGH_JERK', {
            'type': 'high_jerk',
            'average_jerk': avgJerk,
            'threshold': _crashJerkThreshold,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }
      }

      // 3. Impact spike detection
      if (magnitude > _crashImpactThreshold) {
        Logger.d(
          'EnhancedEmergencyDetectionService',
          'Impact spike detected: $magnitude m/s²',
          throttle: const Duration(seconds: 5),
        );
        _triggerCrashVerification('IMPACT_SPIKE', {
          'type': 'impact_spike',
          'magnitude': magnitude,
          'threshold': _crashImpactThreshold,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      // 4. Stationary impact detection (vehicle stopped, then impact)
      if (_isStationary && magnitude > _crashImpactThreshold) {
        Logger.d(
          'EnhancedEmergencyDetectionService',
          'Stationary impact detected: $magnitude m/s²',
          throttle: const Duration(seconds: 5),
        );
        _triggerCrashVerification('STATIONARY_IMPACT', {
          'type': 'stationary_impact',
          'magnitude': magnitude,
          'speed': _lastSpeed,
          'threshold': _crashImpactThreshold,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }
    } catch (e) {
      Logger.w(
        'EnhancedEmergencyDetectionService',
        'Crash detection error - $e',
        throttle: const Duration(seconds: 5),
      );
    }
  }

  /// Check for fall indicators
  void _checkForFallIndicators(double magnitude) {
    try {
      // Free-fall detection (acceleration close to 0)
      if (magnitude < _fallFreefallThreshold &&
          _recentAccelerations.length >= 5) {
        final avgAcceleration =
            _recentAccelerations.reduce((a, b) => a + b) /
            _recentAccelerations.length;
        if (avgAcceleration < _fallFreefallThreshold) {
          Logger.d(
            'EnhancedEmergencyDetectionService',
            'Free-fall detected: $avgAcceleration m/s²',
            throttle: const Duration(seconds: 5),
          );
          _triggerFallVerification('FREE_FALL', {
            'type': 'free_fall',
            'average_acceleration': avgAcceleration,
            'threshold': _fallFreefallThreshold,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }
      }

      // Fall impact detection
      if (magnitude > _fallImpactThreshold) {
        Logger.d(
          'EnhancedEmergencyDetectionService',
          'Fall impact detected: $magnitude m/s²',
          throttle: const Duration(seconds: 5),
        );
        _triggerFallVerification('FALL_IMPACT', {
          'type': 'fall_impact',
          'magnitude': magnitude,
          'threshold': _fallImpactThreshold,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }
    } catch (e) {
      Logger.w(
        'EnhancedEmergencyDetectionService',
        'Fall detection error - $e',
        throttle: const Duration(seconds: 5),
      );
    }
  }

  /// Trigger crash verification with AI
  void _triggerCrashVerification(
    String detectionType,
    Map<String, dynamic> data,
  ) {
    if (_aiVerification.getStatus()['isVerificationActive'] == true) return;

    debugPrint(
      'EnhancedEmergencyDetectionService: 🚗 CRASH DETECTED - $detectionType',
    );
    // AI verification is handled by the AIVerificationService monitoring sensor data
    // Trigger callback for higher-level handling
    _onEmergencyDetected?.call(detectionType, data);
  }

  /// Trigger fall verification with AI
  void _triggerFallVerification(
    String detectionType,
    Map<String, dynamic> data,
  ) {
    if (_aiVerification.getStatus()['isVerificationActive'] == true) return;

    debugPrint(
      'EnhancedEmergencyDetectionService: 🏃 FALL DETECTED - $detectionType',
    );
    // AI verification is handled by the AIVerificationService monitoring sensor data
    // Trigger callback for higher-level handling
    _onEmergencyDetected?.call(detectionType, data);
  }

  /// Set callbacks
  void setOnEmergencyDetected(Function(String, Map<String, dynamic>) callback) {
    _onEmergencyDetected = callback;
  }

  void setOnError(Function(String) callback) {
    _onError = callback;
  }

  void setOnVerificationStarted(Function() callback) {
    _onVerificationStarted = callback;
  }

  void setOnVerificationCancelled(Function() callback) {
    _onVerificationCancelled = callback;
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isMonitoring': _isMonitoring,
      'aiVerificationStatus': _aiVerification.getStatus(),
      'lastSpeed': _lastSpeed,
      'isStationary': _isStationary,
      'hasMotionResumed': _hasMotionResumed,
      'recentAccelerations': _recentAccelerations.length,
      'recentJerk': _recentJerk.length,
      'recentPositions': _recentPositions.length,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _aiVerification.dispose();
    _isInitialized = false;
  }
}
