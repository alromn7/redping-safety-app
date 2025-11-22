// ignore_for_file: unused_field, unused_local_variable, unused_element
import 'dart:async';
import 'dart:math';
// Removed unused Flutter imports after introducing Logger
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
// import 'package:speech_to_text/speech_to_text.dart'; // Removed due to Android compatibility issues
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:redping_14v/utils/logger.dart';
import 'location_service.dart';
import 'firebase_service.dart';
import 'sar_service.dart';
import 'location_sharing_service.dart';
import '../models/sos_session.dart';

/// AI-powered emergency verification service with multiple layers of false positive mitigation
class AIEmergencyVerificationService {
  static final AIEmergencyVerificationService _instance =
      AIEmergencyVerificationService._internal();
  factory AIEmergencyVerificationService() => _instance;
  AIEmergencyVerificationService._internal();

  bool _isInitialized = false;
  bool _isMonitoring = false;
  bool _isVerificationActive = false;

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;

  // AI verification components
  // SpeechToText? _speechToText; // Removed due to Android compatibility issues
  FlutterTts? _flutterTts;
  Timer? _verificationTimer;
  Timer? _motionResumeTimer;
  Timer? _countdownTimer;

  // Detection thresholds and parameters
  // Removed unused field: _crashDecelThreshold
  static const double _crashJerkThreshold = 15.0; // m/s³ - High jerk
  static const double _crashImpactThreshold = 20.0; // m/s² - Impact spike
  static const double _fallFreefallThreshold =
      0.5; // m/s² - Free-fall detection
  static const double _fallImpactThreshold = 12.0; // m/s² - Fall impact
  static const double _stationarySpeedThreshold =
      2.0; // m/s - Stationary vehicle
  static const Duration _detectionWindow = Duration(seconds: 3);
  static const Duration _verificationWindow = Duration(seconds: 30);
  static const Duration _motionResumeWindow = Duration(seconds: 120);
  static const Duration _inactivityWindow = Duration(seconds: 60);

  // Detection state
  DateTime? _lastMotionTime;
  double _lastSpeed = 0.0;
  bool _isStationary = false;
  bool _hasMotionResumed = false;
  bool _hasUserResponded = false;

  // Sensor data buffers
  final List<double> _recentAccelerations = [];
  final List<double> _recentJerk = [];

  // Verification state
  int _countdownSeconds = 30;
  bool _isListeningForSpeech = false;
  final List<String> _positiveResponses = [
    'I\'m OK',
    'I\'m fine',
    'I\'m good',
    'cancel',
    'stop',
    'no',
  ];

  // Callbacks
  Function(String, Map<String, dynamic>)? _onEmergencyDetected;
  Function(String)? _onError;
  Function()? _onVerificationStarted;
  Function()? _onVerificationCancelled;

  /// Initialize the AI verification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.i(
      'AIEmergencyVerificationService',
      'Initializing AI verification...',
    );

    try {
      // Initialize speech recognition
      // _speechToText = SpeechToText(); // Removed due to Android compatibility issues
      // await _speechToText!.initialize();

      // Initialize text-to-speech
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.8);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _isInitialized = true;
      Logger.i(
        'AIEmergencyVerificationService',
        'AI verification initialized successfully',
      );
    } catch (e) {
      Logger.e('AIEmergencyVerificationService', 'Initialization failed - $e');
      rethrow;
    }
  }

  /// Start AI-powered emergency monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    Logger.i(
      'AIEmergencyVerificationService',
      'Starting AI emergency monitoring...',
    );

    try {
      // In release builds, disable AI verification autonomous monitoring to avoid low-threshold triggers
      if (kReleaseMode) {
        Logger.w(
          'AIEmergencyVerificationService',
          'Start suppressed in release build (AI verification runs only under SensorService/production gating).',
        );
        return;
      }
      _isMonitoring = true;

      // Monitor accelerometer for crash/fall detection
      _accelerometerSubscription = accelerometerEventStream().listen(
        _handleAccelerometerData,
        onError: (error) {
          Logger.e(
            'AIEmergencyVerificationService',
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
            'AIEmergencyVerificationService',
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
              Logger.e('AIEmergencyVerificationService', 'GPS error - $error');
              _onError?.call('GPS_ERROR');
            },
          );

      Logger.i('AIEmergencyVerificationService', 'AI monitoring started');
    } catch (e) {
      Logger.e(
        'AIEmergencyVerificationService',
        'Failed to start monitoring - $e',
      );
      _onError?.call('MONITORING_START_FAILED');
    }
  }

  /// Stop AI monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    Logger.i('AIEmergencyVerificationService', 'Stopping AI monitoring...');

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    _verificationTimer?.cancel();
    _motionResumeTimer?.cancel();
    _countdownTimer?.cancel();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _positionSubscription = null;
    _verificationTimer = null;
    _motionResumeTimer = null;
    _countdownTimer = null;

    _isMonitoring = false;
    _isVerificationActive = false;

    Logger.i('AIEmergencyVerificationService', 'AI monitoring stopped');
  }

  /// Handle accelerometer data for crash detection
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
      Logger.e(
        'AIEmergencyVerificationService',
        'Accelerometer processing error - $e',
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
      Logger.e(
        'AIEmergencyVerificationService',
        'Gyroscope processing error - $e',
      );
    }
  }

  /// Handle GPS position data for speed and movement analysis
  void _handlePositionData(Position position) {
    try {
      // Removed unused _recentPositions logic

      _lastSpeed = position.speed;
      _isStationary = position.speed < _stationarySpeedThreshold;
      _lastMotionTime = DateTime.now();

      // Check if motion has resumed after a potential crash
      if (_hasMotionResumed == false &&
          position.speed > _stationarySpeedThreshold) {
        _hasMotionResumed = true;
        Logger.d(
          'AIEmergencyVerificationService',
          'Motion resumed - ${position.speed} m/s',
          throttle: const Duration(seconds: 10),
        );
      }
    } catch (e) {
      Logger.e('AIEmergencyVerificationService', 'GPS processing error - $e');
    }
  }

  /// Check for crash indicators using multiple heuristics
  void _checkForCrashIndicators(double magnitude) {
    try {
      // 1. Sharp deceleration detection
      // Removed unused _recentSpeeds logic for sharp deceleration

      // 2. High jerk detection
      if (_recentJerk.length >= 3) {
        final avgJerk =
            _recentJerk.reduce((a, b) => a + b) / _recentJerk.length;
        if (avgJerk > _crashJerkThreshold) {
          Logger.d(
            'AIEmergencyVerificationService',
            'High jerk detected: $avgJerk m/s³',
            throttle: const Duration(seconds: 5),
          );
          _triggerCrashVerification('HIGH_JERK', {
            'type': 'high_jerk',
            'average_jerk': avgJerk,
            'threshold': _crashJerkThreshold,
          });
          return;
        }
      }

      // 3. Impact spike detection
      if (magnitude > _crashImpactThreshold) {
        Logger.d(
          'AIEmergencyVerificationService',
          'Impact spike detected: $magnitude m/s²',
          throttle: const Duration(seconds: 5),
        );
        _triggerCrashVerification('IMPACT_SPIKE', {
          'type': 'impact_spike',
          'magnitude': magnitude,
          'threshold': _crashImpactThreshold,
        });
        return;
      }

      // 4. Stationary impact detection (vehicle stopped, then impact)
      if (_isStationary && magnitude > _crashImpactThreshold) {
        Logger.d(
          'AIEmergencyVerificationService',
          'Stationary impact detected: $magnitude m/s²',
          throttle: const Duration(seconds: 5),
        );
        _triggerCrashVerification('STATIONARY_IMPACT', {
          'type': 'stationary_impact',
          'magnitude': magnitude,
          'speed': _lastSpeed,
          'threshold': _crashImpactThreshold,
        });
        return;
      }
    } catch (e) {
      Logger.e('AIEmergencyVerificationService', 'Crash detection error - $e');
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
            'AIEmergencyVerificationService',
            'Free-fall detected: $avgAcceleration m/s²',
            throttle: const Duration(seconds: 5),
          );
          _triggerFallVerification('FREE_FALL', {
            'type': 'free_fall',
            'average_acceleration': avgAcceleration,
            'threshold': _fallFreefallThreshold,
          });
          return;
        }
      }

      // Fall impact detection
      if (magnitude > _fallImpactThreshold) {
        Logger.d(
          'AIEmergencyVerificationService',
          'Fall impact detected: $magnitude m/s²',
          throttle: const Duration(seconds: 5),
        );
        _triggerFallVerification('FALL_IMPACT', {
          'type': 'fall_impact',
          'magnitude': magnitude,
          'threshold': _fallImpactThreshold,
        });
        return;
      }
    } catch (e) {
      Logger.e('AIEmergencyVerificationService', 'Fall detection error - $e');
    }
  }

  /// Trigger crash verification with AI
  void _triggerCrashVerification(
    String detectionType,
    Map<String, dynamic> data,
  ) {
    if (_isVerificationActive) return;

    Logger.i(
      'AIEmergencyVerificationService',
      '🚗 CRASH DETECTED - $detectionType',
      throttle: const Duration(seconds: 3),
    );
    _startAIVerification('CRASH', detectionType, data);
  }

  /// Trigger fall verification with AI
  void _triggerFallVerification(
    String detectionType,
    Map<String, dynamic> data,
  ) {
    if (_isVerificationActive) return;

    Logger.i(
      'AIEmergencyVerificationService',
      '🏃 FALL DETECTED - $detectionType',
      throttle: const Duration(seconds: 3),
    );
    _startAIVerification('FALL', detectionType, data);
  }

  /// Start AI verification process
  void _startAIVerification(
    String emergencyType,
    String detectionType,
    Map<String, dynamic> data,
  ) {
    try {
      // Extra safety: never auto-verify/escalate in release
      if (kReleaseMode) {
        Logger.w(
          'AIEmergencyVerificationService',
          'Verification suppressed in release build (production detection handles escalation).',
          throttle: const Duration(seconds: 10),
        );
        return;
      }
      _isVerificationActive = true;
      _countdownSeconds = 30;
      _hasUserResponded = false;
      _hasMotionResumed = false;

      Logger.i(
        'AIEmergencyVerificationService',
        'Starting AI verification for $emergencyType',
      );

      // Start motion resume monitoring
      _motionResumeTimer = Timer(_motionResumeWindow, () {
        if (_hasMotionResumed) {
          Logger.i(
            'AIEmergencyVerificationService',
            'Motion resumed - suppressing SOS',
          );
          _cancelVerification();
          return;
        }
      });

      // Start TTS announcement
      _announceEmergency(emergencyType, detectionType);

      // Start countdown timer
      _startCountdown();

      // Start speech recognition
      _startSpeechRecognition();

      // Notify callback
      _onVerificationStarted?.call();
    } catch (e) {
      Logger.e(
        'AIEmergencyVerificationService',
        'AI verification start failed - $e',
      );
      _onError?.call('VERIFICATION_START_FAILED');
    }
  }

  /// Announce emergency with TTS
  Future<void> _announceEmergency(
    String emergencyType,
    String detectionType,
  ) async {
    try {
      String message;
      if (emergencyType == 'CRASH') {
        message =
            'Detected a possible vehicle crash. Sending emergency alert in 30 seconds unless you respond.';
      } else {
        message =
            'Detected a possible fall. Sending emergency alert in 30 seconds unless you respond.';
      }

      await _flutterTts!.speak(message);
      // Removed unused _currentVerificationMessage assignment
    } catch (e) {
      Logger.w(
        'AIEmergencyVerificationService',
        'TTS announcement failed - $e',
      );
    }
  }

  /// Start countdown with TTS announcements
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _escalateToSOS();
        return;
      }

      // Announce countdown at specific intervals
      if (_countdownSeconds == 30 ||
          _countdownSeconds == 15 ||
          _countdownSeconds == 10 ||
          _countdownSeconds <= 5) {
        _flutterTts!.speak('$_countdownSeconds');
      }

      _countdownSeconds--;
    });
  }

  /// Start speech recognition for user response
  void _startSpeechRecognition() {
    // Speech recognition disabled due to Android compatibility issues
    Logger.d(
      'AIEmergencyVerificationService',
      'Speech recognition disabled',
      throttle: const Duration(seconds: 60),
    );
    /*
    try {
      _isListeningForSpeech = true;
      
      _speechToText!.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords.toLowerCase();
          debugPrint('AIEmergencyVerificationService: Speech recognized: $recognizedText');
          
          // Check for positive responses
          for (final response in _positiveResponses) {
            if (recognizedText.contains(response.toLowerCase())) {
              debugPrint('AIEmergencyVerificationService: Positive response detected: $response');
              _cancelVerification();
              return;
            }
          }
        },
        listenFor: _verificationWindow,
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // Handle sound level changes if needed
        },
      );
      
    } catch (e) {
      debugPrint('AIEmergencyVerificationService: Speech recognition failed - $e');
    }
    */
  }

  /// Cancel verification (user responded positively)
  void _cancelVerification() {
    try {
      Logger.i(
        'AIEmergencyVerificationService',
        'Verification cancelled by user',
      );

      _isVerificationActive = false;
      _hasUserResponded = true;

      // Cancel all timers
      _verificationTimer?.cancel();
      _motionResumeTimer?.cancel();
      _countdownTimer?.cancel();

      // Stop speech recognition
      // _speechToText!.stop(); // Removed due to Android compatibility issues
      _isListeningForSpeech = false;

      // Announce cancellation
      _flutterTts!.speak('Emergency alert cancelled. You are safe.');

      // Notify callback
      _onVerificationCancelled?.call();
    } catch (e) {
      Logger.e(
        'AIEmergencyVerificationService',
        'Verification cancellation failed - $e',
      );
    }
  }

  /// Escalate to SOS (no user response)
  void _escalateToSOS() async {
    try {
      Logger.i(
        'AIEmergencyVerificationService',
        'Escalating to SOS - no user response',
      );

      _isVerificationActive = false;

      // Stop speech recognition
      // _speechToText!.stop(); // Removed due to Android compatibility issues
      _isListeningForSpeech = false;

      // Final announcement
      await _flutterTts!.speak(
        'No response detected. Sending emergency alert now.',
      );

      // Get current location
      final location = await LocationService.getCurrentLocationStatic();

      // Send SOS alert
      await _sendSOSAlert('AUTO_DETECTED', {
        'emergency_type': 'AI_VERIFIED',
        'detection_data': {
          'verification_timeout': true,
          'user_responded': false,
          'motion_resumed': _hasMotionResumed,
        },
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.e('AIEmergencyVerificationService', 'SOS escalation failed - $e');
      _onError?.call('SOS_ESCALATION_FAILED');
    }
  }

  /// Send SOS alert to emergency services
  Future<void> _sendSOSAlert(
    String alertType,
    Map<String, dynamic> data,
  ) async {
    try {
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      // Create SOS session
      final sosSession = SOSSession(
        id: 'ai_verified_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: SOSType.manual,
        status: SOSStatus.active,
        startTime: DateTime.now(),
        location: LocationInfo(
          latitude: data['location']['latitude'],
          longitude: data['location']['longitude'],
          accuracy: data['location']['accuracy'],
          timestamp: DateTime.now(),
        ),
        userMessage: 'AI-verified emergency: $alertType',
      );

      // Send to Firebase
      await firebaseService.sendSosAlert(sosSession);

      // Send to SAR service
      final sarService = SARService();
      await sarService.addLocationUpdate(sosSession.location);

      // Open map app
      await LocationService.openMapApp(
        data['location']['latitude'],
        data['location']['longitude'],
      );

      // Share with emergency contacts
      await LocationSharingService.shareLocationWithContacts();

      // Notify callback
      _onEmergencyDetected?.call(alertType, data);

      Logger.i('AIEmergencyVerificationService', 'SOS alert sent successfully');
    } catch (e) {
      Logger.e('AIEmergencyVerificationService', 'SOS alert failed - $e');
      _onError?.call('SOS_ALERT_FAILED');
    }
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
      'isVerificationActive': _isVerificationActive,
      'countdownSeconds': _countdownSeconds,
      'isListeningForSpeech': _isListeningForSpeech,
      'hasUserResponded': _hasUserResponded,
      'hasMotionResumed': _hasMotionResumed,
      'lastSpeed': _lastSpeed,
      'isStationary': _isStationary,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    // _speechToText = null; // Removed due to Android compatibility issues
    _flutterTts = null;
    _isInitialized = false;
  }
}
