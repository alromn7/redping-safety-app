import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'location_service.dart';
import 'firebase_service.dart';
import 'sar_service.dart';
import 'location_sharing_service.dart';
import 'feature_access_service.dart';
import '../models/sos_session.dart';

/// Service for automatic emergency detection and response
class EmergencyDetectionService {
  static final EmergencyDetectionService _instance =
      EmergencyDetectionService._internal();
  factory EmergencyDetectionService() => _instance;
  EmergencyDetectionService._internal();

  bool _isInitialized = false;
  bool _isMonitoring = false;
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Emergency detection thresholds
  static const double _crashThreshold = 15.0; // m/s²
  static const double _fallThreshold = 8.0; // m/s²
  static const double _panicThreshold = 12.0; // m/s²
  static const Duration _cooldownPeriod = Duration(minutes: 5);

  DateTime? _lastEmergencyDetection;
  final List<double> _recentAccelerations = [];
  final List<double> _recentGyroscope = [];

  // Callbacks
  Function(String, Map<String, dynamic>)? _onEmergencyDetected;
  Function(String)? _onError;

  /// Initialize the emergency detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('EmergencyDetectionService: Initializing...');

    try {
      _isInitialized = true;
      debugPrint('EmergencyDetectionService: Initialized successfully');
    } catch (e) {
      debugPrint('EmergencyDetectionService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Start monitoring for emergency situations
  static void startMonitoring() {
    final service = EmergencyDetectionService();
    service._startEmergencyMonitoring();
  }

  /// Start emergency monitoring
  void _startEmergencyMonitoring() {
    if (_isMonitoring) return;

    // 🔒 SUBSCRIPTION GATE: ACFD requires Essential+ or above
    if (!_featureAccessService.hasFeatureAccess('acfd')) {
      debugPrint(
        '⚠️ EmergencyDetectionService: ACFD not available - Free tier (manual SOS only)',
      );
      debugPrint('   Upgrade to Essential+ for Auto Crash/Fall Detection');
      return;
    }

    debugPrint('EmergencyDetectionService: Starting emergency monitoring...');

    try {
      _isMonitoring = true;

      // Monitor accelerometer for crash/fall detection
      _accelerometerSubscription = accelerometerEventStream().listen(
        _handleAccelerometerData,
        onError: (error) {
          debugPrint('EmergencyDetectionService: Accelerometer error - $error');
          _onError?.call('ACCELEROMETER_ERROR');
        },
      );

      // Monitor gyroscope for panic detection
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        _handleGyroscopeData,
        onError: (error) {
          debugPrint('EmergencyDetectionService: Gyroscope error - $error');
          _onError?.call('GYROSCOPE_ERROR');
        },
      );

      debugPrint('EmergencyDetectionService: Emergency monitoring started');
    } catch (e) {
      debugPrint('EmergencyDetectionService: Failed to start monitoring - $e');
      _onError?.call('MONITORING_START_FAILED');
    }
  }

  /// Stop emergency monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    debugPrint('EmergencyDetectionService: Stopping emergency monitoring...');

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isMonitoring = false;

    debugPrint('EmergencyDetectionService: Emergency monitoring stopped');
  }

  /// Handle accelerometer data for crash/fall detection
  void _handleAccelerometerData(AccelerometerEvent event) {
    try {
      // Calculate magnitude of acceleration
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Add to recent accelerations
      _recentAccelerations.add(magnitude);

      // Keep only recent data (last 3 seconds)
      _recentAccelerations.removeWhere(
        (acc) => acc < 0,
      ); // Remove invalid readings

      // Check for crash detection
      if (magnitude > _crashThreshold) {
        _detectEmergency('CRASH', {
          'type': 'crash',
          'magnitude': magnitude,
          'threshold': _crashThreshold,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      // Check for fall detection (sustained high acceleration)
      if (_recentAccelerations.length >= 10) {
        final avgAcceleration =
            _recentAccelerations.reduce((a, b) => a + b) /
            _recentAccelerations.length;
        if (avgAcceleration > _fallThreshold) {
          _detectEmergency('FALL', {
            'type': 'fall',
            'average_magnitude': avgAcceleration,
            'threshold': _fallThreshold,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }
      }
    } catch (e) {
      debugPrint(
        'EmergencyDetectionService: Accelerometer processing error - $e',
      );
    }
  }

  /// Handle gyroscope data for panic detection
  void _handleGyroscopeData(GyroscopeEvent event) {
    try {
      // Calculate magnitude of rotation
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Add to recent gyroscope data
      _recentGyroscope.add(magnitude);

      // Keep only recent data
      if (_recentGyroscope.length > 20) {
        _recentGyroscope.removeAt(0);
      }

      // Check for panic detection (rapid, irregular movement)
      if (magnitude > _panicThreshold && _recentGyroscope.length >= 5) {
        final variance = _calculateVariance(_recentGyroscope);
        if (variance > 5.0) {
          // High variance indicates panic
          _detectEmergency('PANIC', {
            'type': 'panic',
            'magnitude': magnitude,
            'variance': variance,
            'threshold': _panicThreshold,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('EmergencyDetectionService: Gyroscope processing error - $e');
    }
  }

  /// Detect emergency and trigger response
  void _detectEmergency(String emergencyType, Map<String, dynamic> data) {
    try {
      // Check cooldown period
      if (_lastEmergencyDetection != null) {
        final timeSinceLastDetection = DateTime.now().difference(
          _lastEmergencyDetection!,
        );
        if (timeSinceLastDetection < _cooldownPeriod) {
          debugPrint(
            'EmergencyDetectionService: Emergency detection on cooldown',
          );
          return;
        }
      }

      _lastEmergencyDetection = DateTime.now();

      debugPrint(
        'EmergencyDetectionService: 🚨 EMERGENCY DETECTED - $emergencyType',
      );
      debugPrint('EmergencyDetectionService: Emergency data - $data');

      // Trigger emergency response
      _triggerEmergencyResponse(emergencyType, data);

      // Notify callback
      _onEmergencyDetected?.call(emergencyType, data);
    } catch (e) {
      debugPrint('EmergencyDetectionService: Emergency detection error - $e');
      _onError?.call('EMERGENCY_DETECTION_FAILED');
    }
  }

  /// Trigger emergency response
  Future<void> _triggerEmergencyResponse(
    String emergencyType,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint(
        'EmergencyDetectionService: Triggering emergency response for $emergencyType...',
      );

      // 1. Get current location
      final location = await LocationService.getCurrentLocationStatic();
      debugPrint(
        'EmergencyDetectionService: Got location - ${location.latitude}, ${location.longitude}',
      );

      // 2. Send SOS to SAR system
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      // Create SOS session for automatic emergency
      final sosSession = SOSSession(
        id: 'auto_emergency_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type:
            SOSType.manual, // Use manual type since automatic is not available
        status: SOSStatus.active,
        startTime: DateTime.now(),
        location: LocationInfo(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: DateTime.now(),
        ),
        userMessage: 'Automatic emergency detection: $emergencyType',
      );

      // Send to Firebase
      await firebaseService.sendSosAlert(sosSession);
      debugPrint('EmergencyDetectionService: SOS sent to Firebase');

      // Send to SAR service
      final sarService = SARService();
      final locationInfo = LocationInfo(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        timestamp: DateTime.now(),
      );
      await sarService.addLocationUpdate(locationInfo);
      debugPrint('EmergencyDetectionService: Location sent to SAR service');

      // 3. Open phone map
      await LocationService.openMapApp(location.latitude, location.longitude);
      debugPrint('EmergencyDetectionService: Map app opened');

      // 4. Alert emergency contacts
      await LocationSharingService.shareLocationWithContacts();
      debugPrint(
        'EmergencyDetectionService: Location shared with emergency contacts',
      );

      // 5. Send additional emergency data
      await _sendEmergencyData(emergencyType, data, location);

      debugPrint(
        'EmergencyDetectionService: Emergency response completed for $emergencyType',
      );
    } catch (e) {
      debugPrint('EmergencyDetectionService: Emergency response failed - $e');
      _onError?.call('EMERGENCY_RESPONSE_FAILED');
    }
  }

  /// Send additional emergency data to SAR system
  Future<void> _sendEmergencyData(
    String emergencyType,
    Map<String, dynamic> data,
    dynamic location,
  ) async {
    try {
      final firebaseService = FirebaseService();
      final userId = firebaseService.currentUser?.uid ?? 'anonymous';

      // Send emergency data to Firebase
      await firebaseService.updateUserLocation(
        userId,
        location.latitude,
        location.longitude,
        location.accuracy,
      );

      // Additional emergency context
      final emergencyData = {
        'emergency_type': emergencyType,
        'detection_data': data,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'automatic_detection': true,
      };

      debugPrint(
        'EmergencyDetectionService: Emergency data sent - $emergencyData',
      );
    } catch (e) {
      debugPrint(
        'EmergencyDetectionService: Failed to send emergency data - $e',
      );
    }
  }

  /// Calculate variance for panic detection
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        values.length;
    return variance;
  }

  /// Set emergency detection callback
  void setOnEmergencyDetected(Function(String, Map<String, dynamic>) callback) {
    _onEmergencyDetected = callback;
  }

  /// Set error callback
  void setOnError(Function(String) callback) {
    _onError = callback;
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isMonitoring': _isMonitoring,
      'lastEmergencyDetection': _lastEmergencyDetection?.toIso8601String(),
      'recentAccelerations': _recentAccelerations.length,
      'recentGyroscope': _recentGyroscope.length,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _isInitialized = false;
    _recentAccelerations.clear();
    _recentGyroscope.clear();
    _lastEmergencyDetection = null;
  }
}
