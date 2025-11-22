import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'firebase_service.dart';
import 'sar_service.dart';
import 'location_sharing_service.dart';
import '../models/sos_session.dart';

/// ChatGPT-powered AI verification service for emergency detection
class ChatGPTAIVerificationService {
  static final ChatGPTAIVerificationService _instance =
      ChatGPTAIVerificationService._internal();
  factory ChatGPTAIVerificationService() => _instance;
  ChatGPTAIVerificationService._internal();

  bool _isInitialized = false;
  bool _isMonitoring = false;

  // ChatGPT API configuration
  String _apiKey = '';
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model =
      'gpt-4o-mini'; // Cost-effective model for real-time analysis

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;

  // Detection parameters
  static const double _crashImpactThreshold = 20.0; // m/s²
  static const double _fallFreefallThreshold = 0.5; // m/s²
  static const double _fallImpactThreshold = 12.0; // m/s²
  static const double _stationarySpeedThreshold = 2.0; // m/s

  // Detection state
  DateTime? _lastMotionTime;
  double _lastSpeed = 0.0;
  bool _isStationary = false;
  bool _hasMotionResumed = false;

  // Sensor data buffers for AI analysis
  final List<Map<String, dynamic>> _sensorDataBuffer = [];
  final List<Map<String, dynamic>> _contextDataBuffer = [];

  // AI analysis state
  bool _isAIAnalyzing = false;
  String _lastAIAnalysis = '';
  Map<String, dynamic> _lastAIPrediction = {};

  // Callbacks
  Function(String, Map<String, dynamic>)? _onEmergencyDetected;
  Function(String)? _onError;
  Function(String)? _onAIAnalysisComplete;

  /// Initialize the ChatGPT AI verification service
  Future<void> initialize({required String apiKey}) async {
    if (_isInitialized) return;

    debugPrint(
      'ChatGPTAIVerificationService: Initializing ChatGPT AI verification...',
    );

    try {
      _apiKey = apiKey;
      _isInitialized = true;
      debugPrint(
        'ChatGPTAIVerificationService: ChatGPT AI verification initialized successfully',
      );
    } catch (e) {
      debugPrint('ChatGPTAIVerificationService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Start AI-powered emergency monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    debugPrint(
      'ChatGPTAIVerificationService: Starting AI-powered monitoring...',
    );

    try {
      _isMonitoring = true;

      // Monitor accelerometer for crash/fall detection
      _accelerometerSubscription = accelerometerEventStream().listen(
        _handleAccelerometerData,
        onError: (error) {
          debugPrint(
            'ChatGPTAIVerificationService: Accelerometer error - $error',
          );
          _onError?.call('ACCELEROMETER_ERROR');
        },
      );

      // Monitor gyroscope for additional context
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        _handleGyroscopeData,
        onError: (error) {
          debugPrint('ChatGPTAIVerificationService: Gyroscope error - $error');
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
              debugPrint('ChatGPTAIVerificationService: GPS error - $error');
              _onError?.call('GPS_ERROR');
            },
          );

      debugPrint('ChatGPTAIVerificationService: AI-powered monitoring started');
    } catch (e) {
      debugPrint(
        'ChatGPTAIVerificationService: Failed to start monitoring - $e',
      );
      _onError?.call('MONITORING_START_FAILED');
    }
  }

  /// Stop AI monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    debugPrint('ChatGPTAIVerificationService: Stopping AI monitoring...');

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _positionSubscription = null;

    _isMonitoring = false;

    debugPrint('ChatGPTAIVerificationService: AI monitoring stopped');
  }

  /// Handle accelerometer data for crash/fall detection
  void _handleAccelerometerData(AccelerometerEvent event) {
    try {
      // Calculate acceleration magnitude
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Add to sensor data buffer
      _sensorDataBuffer.add({
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'accelerometer',
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'magnitude': magnitude,
        'source': 'device_sensor',
      });

      // Keep buffer size manageable
      if (_sensorDataBuffer.length > 100) {
        _sensorDataBuffer.removeAt(0);
      }

      // Check for immediate crash indicators
      _checkForImmediateCrashIndicators(magnitude);

      // Check for fall indicators
      _checkForFallIndicators(magnitude);
    } catch (e) {
      debugPrint(
        'ChatGPTAIVerificationService: Accelerometer processing error - $e',
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

      // Add to sensor data buffer
      _sensorDataBuffer.add({
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'gyroscope',
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'magnitude': magnitude,
        'source': 'device_sensor',
      });
    } catch (e) {
      debugPrint(
        'ChatGPTAIVerificationService: Gyroscope processing error - $e',
      );
    }
  }

  /// Handle GPS position data for speed and movement analysis
  void _handlePositionData(Position position) {
    try {
      _lastSpeed = position.speed;
      _isStationary = position.speed < _stationarySpeedThreshold;
      _lastMotionTime = DateTime.now();

      // Add to context data buffer
      _contextDataBuffer.add({
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'gps',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'source': 'device_sensor',
      });

      // Keep buffer size manageable
      if (_contextDataBuffer.length > 50) {
        _contextDataBuffer.removeAt(0);
      }

      // Check if motion has resumed after a potential crash
      if (_hasMotionResumed == false &&
          position.speed > _stationarySpeedThreshold) {
        _hasMotionResumed = true;
        debugPrint(
          'ChatGPTAIVerificationService: Motion resumed - ${position.speed} m/s',
        );
      }
    } catch (e) {
      debugPrint('ChatGPTAIVerificationService: GPS processing error - $e');
    }
  }

  /// Check for immediate crash indicators (before AI analysis)
  void _checkForImmediateCrashIndicators(double magnitude) {
    try {
      // Only check for immediate threats that require instant response
      if (magnitude > _crashImpactThreshold * 1.5) {
        // 30 m/s² - severe impact
        debugPrint(
          'ChatGPTAIVerificationService: 🚨 SEVERE IMPACT DETECTED - $magnitude m/s²',
        );
        _triggerImmediateEmergency('SEVERE_IMPACT', {
          'type': 'severe_impact',
          'magnitude': magnitude,
          'threshold': _crashImpactThreshold * 1.5,
          'timestamp': DateTime.now().toIso8601String(),
          'ai_analysis': 'bypassed_due_to_severity',
        });
        return;
      }

      // For other indicators, use AI analysis
      if (magnitude > _crashImpactThreshold) {
        _triggerAIAnalysis('POTENTIAL_CRASH', {
          'type': 'potential_crash',
          'magnitude': magnitude,
          'threshold': _crashImpactThreshold,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('ChatGPTAIVerificationService: Crash detection error - $e');
    }
  }

  /// Check for fall indicators
  void _checkForFallIndicators(double magnitude) {
    try {
      // Free-fall detection (acceleration close to 0)
      if (magnitude < _fallFreefallThreshold && _sensorDataBuffer.length >= 5) {
        final recentAccelerations = _sensorDataBuffer
            .where((data) => data['type'] == 'accelerometer')
            .take(5)
            .map((data) => data['magnitude'] as double)
            .toList();

        if (recentAccelerations.length >= 5) {
          final avgAcceleration =
              recentAccelerations.reduce((a, b) => a + b) /
              recentAccelerations.length;
          if (avgAcceleration < _fallFreefallThreshold) {
            _triggerAIAnalysis('POTENTIAL_FALL', {
              'type': 'potential_fall',
              'average_acceleration': avgAcceleration,
              'threshold': _fallFreefallThreshold,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      // Fall impact detection
      if (magnitude > _fallImpactThreshold) {
        _triggerAIAnalysis('POTENTIAL_FALL_IMPACT', {
          'type': 'potential_fall_impact',
          'magnitude': magnitude,
          'threshold': _fallImpactThreshold,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('ChatGPTAIVerificationService: Fall detection error - $e');
    }
  }

  /// Trigger AI analysis for potential emergency
  void _triggerAIAnalysis(
    String detectionType,
    Map<String, dynamic> data,
  ) async {
    if (_isAIAnalyzing) return;

    debugPrint(
      'ChatGPTAIVerificationService: 🤖 Triggering AI analysis for $detectionType',
    );

    try {
      _isAIAnalyzing = true;

      // Prepare data for AI analysis
      final analysisData = _prepareDataForAIAnalysis(detectionType, data);

      // Send to ChatGPT for analysis
      final aiResponse = await _analyzeWithChatGPT(analysisData);

      // Process AI response
      await _processAIResponse(aiResponse, detectionType, data);
    } catch (e) {
      debugPrint('ChatGPTAIVerificationService: AI analysis failed - $e');
      _onError?.call('AI_ANALYSIS_FAILED');
    } finally {
      _isAIAnalyzing = false;
    }
  }

  /// Prepare data for AI analysis
  Map<String, dynamic> _prepareDataForAIAnalysis(
    String detectionType,
    Map<String, dynamic> data,
  ) {
    // Get recent sensor data (last 10 seconds)
    final recentSensorData = _sensorDataBuffer
        .where(
          (item) =>
              DateTime.now()
                  .difference(DateTime.parse(item['timestamp']))
                  .inSeconds <=
              10,
        )
        .toList();

    // Get recent context data
    final recentContextData = _contextDataBuffer
        .where(
          (item) =>
              DateTime.now()
                  .difference(DateTime.parse(item['timestamp']))
                  .inSeconds <=
              10,
        )
        .toList();

    return {
      'detection_type': detectionType,
      'detection_data': data,
      'sensor_data': recentSensorData,
      'context_data': recentContextData,
      'analysis_timestamp': DateTime.now().toIso8601String(),
      'device_state': {
        'is_stationary': _isStationary,
        'last_speed': _lastSpeed,
        'has_motion_resumed': _hasMotionResumed,
        'last_motion_time': _lastMotionTime?.toIso8601String(),
      },
    };
  }

  /// Analyze data with ChatGPT
  Future<Map<String, dynamic>> _analyzeWithChatGPT(
    Map<String, dynamic> analysisData,
  ) async {
    try {
      final prompt = _buildChatGPTPrompt(analysisData);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an AI emergency detection specialist. Analyze sensor data to determine if a real emergency occurred. Consider patterns, context, and false positive indicators.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1, // Low temperature for consistent analysis
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiAnalysis = responseData['choices'][0]['message']['content'];

        debugPrint('ChatGPTAIVerificationService: AI analysis received');
        return {
          'success': true,
          'analysis': aiAnalysis,
          'raw_response': responseData,
        };
      } else {
        debugPrint(
          'ChatGPTAIVerificationService: ChatGPT API error - ${response.statusCode}',
        );
        return {'success': false, 'error': 'API_ERROR_${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('ChatGPTAIVerificationService: ChatGPT analysis failed - $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Build ChatGPT prompt for analysis
  String _buildChatGPTPrompt(Map<String, dynamic> analysisData) {
    final sensorData = analysisData['sensor_data'] as List;
    final contextData = analysisData['context_data'] as List;
    final detectionType = analysisData['detection_type'] as String;
    final detectionData =
        analysisData['detection_data'] as Map<String, dynamic>;

    return '''
Analyze this emergency detection data and determine if this is a REAL emergency or a false positive.

DETECTION TYPE: $detectionType
DETECTION DATA: ${jsonEncode(detectionData)}

RECENT SENSOR DATA (last 10 seconds):
${jsonEncode(sensorData.take(20).toList())}

RECENT CONTEXT DATA (GPS, speed, etc.):
${jsonEncode(contextData.take(10).toList())}

DEVICE STATE:
- Stationary: ${analysisData['device_state']['is_stationary']}
- Last Speed: ${analysisData['device_state']['last_speed']} m/s
- Motion Resumed: ${analysisData['device_state']['has_motion_resumed']}

ANALYSIS CRITERIA:
1. Look for patterns that indicate real emergencies vs false positives
2. Consider if this could be phone drop, hard braking, normal movement
3. Check for sustained vs momentary events
4. Consider GPS context (speed, location changes)
5. Look for multiple sensor confirmations

RESPOND WITH JSON:
{
  "is_emergency": true/false,
  "confidence": 0.0-1.0,
  "reasoning": "brief explanation",
  "false_positive_indicators": ["list of indicators"],
  "emergency_indicators": ["list of indicators"],
  "recommendation": "proceed_with_sos" or "suppress_alert" or "request_verification"
}
''';
  }

  /// Process AI response and take appropriate action
  Future<void> _processAIResponse(
    Map<String, dynamic> aiResponse,
    String detectionType,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!aiResponse['success']) {
        debugPrint(
          'ChatGPTAIVerificationService: AI analysis failed, using fallback logic',
        );
        _useFallbackLogic(detectionType, data);
        return;
      }

      final analysis = aiResponse['analysis'] as String;
      _lastAIAnalysis = analysis;

      // Parse AI response
      final aiDecision = _parseAIResponse(analysis);
      _lastAIPrediction = aiDecision;

      debugPrint(
        'ChatGPTAIVerificationService: AI Decision - ${aiDecision['is_emergency']} (confidence: ${aiDecision['confidence']})',
      );
      debugPrint(
        'ChatGPTAIVerificationService: AI Reasoning - ${aiDecision['reasoning']}',
      );

      // Take action based on AI decision
      if (aiDecision['is_emergency'] == true &&
          aiDecision['confidence'] > 0.7) {
        _triggerEmergencyResponse(detectionType, data, aiDecision);
      } else if (aiDecision['recommendation'] == 'request_verification') {
        _requestUserVerification(detectionType, data, aiDecision);
      } else {
        debugPrint(
          'ChatGPTAIVerificationService: AI determined false positive - suppressing alert',
        );
        _suppressAlert(detectionType, data, aiDecision);
      }

      _onAIAnalysisComplete?.call(analysis);
    } catch (e) {
      debugPrint(
        'ChatGPTAIVerificationService: AI response processing failed - $e',
      );
      _useFallbackLogic(detectionType, data);
    }
  }

  /// Parse AI response JSON
  Map<String, dynamic> _parseAIResponse(String analysis) {
    try {
      // Extract JSON from analysis text
      final jsonStart = analysis.indexOf('{');
      final jsonEnd = analysis.lastIndexOf('}') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonText = analysis.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonText);
      }

      // Fallback parsing
      return {
        'is_emergency': false,
        'confidence': 0.5,
        'reasoning': 'Could not parse AI response',
        'recommendation': 'suppress_alert',
      };
    } catch (e) {
      debugPrint(
        'ChatGPTAIVerificationService: AI response parsing failed - $e',
      );
      return {
        'is_emergency': false,
        'confidence': 0.0,
        'reasoning': 'Parsing error',
        'recommendation': 'suppress_alert',
      };
    }
  }

  /// Use fallback logic when AI analysis fails
  void _useFallbackLogic(String detectionType, Map<String, dynamic> data) {
    debugPrint(
      'ChatGPTAIVerificationService: Using fallback logic for $detectionType',
    );

    // Simple threshold-based logic
    final magnitude = data['magnitude'] as double? ?? 0.0;

    if (magnitude > _crashImpactThreshold * 1.2) {
      // 24 m/s²
      _triggerEmergencyResponse(detectionType, data, {
        'is_emergency': true,
        'confidence': 0.8,
        'reasoning': 'Fallback logic - high impact detected',
        'recommendation': 'proceed_with_sos',
      });
    } else {
      _suppressAlert(detectionType, data, {
        'is_emergency': false,
        'confidence': 0.6,
        'reasoning': 'Fallback logic - insufficient evidence',
        'recommendation': 'suppress_alert',
      });
    }
  }

  /// Trigger emergency response
  void _triggerEmergencyResponse(
    String detectionType,
    Map<String, dynamic> data,
    Map<String, dynamic> aiDecision,
  ) async {
    debugPrint(
      'ChatGPTAIVerificationService: 🚨 EMERGENCY CONFIRMED BY AI - $detectionType',
    );

    try {
      // Get current location
      final location = await LocationService.getCurrentLocationStatic();

      // Create SOS session
      final sosSession = SOSSession(
        id: 'ai_verified_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        type: SOSType.manual,
        status: SOSStatus.active,
        startTime: DateTime.now(),
        location: LocationInfo(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: DateTime.now(),
        ),
        userMessage:
            'AI-verified emergency: $detectionType (confidence: ${aiDecision['confidence']})',
      );

      // Send to Firebase
      final firebaseService = FirebaseService();
      await firebaseService.sendSosAlert(sosSession);

      // Send to SAR service
      final sarService = SARService();
      await sarService.addLocationUpdate(sosSession.location);

      // Open map app
      await LocationService.openMapApp(location.latitude, location.longitude);

      // Share with emergency contacts
      await LocationSharingService.shareLocationWithContacts();

      // Notify callback
      _onEmergencyDetected?.call(detectionType, {
        ...data,
        'ai_decision': aiDecision,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
      });

      debugPrint('ChatGPTAIVerificationService: Emergency response completed');
    } catch (e) {
      debugPrint(
        'ChatGPTAIVerificationService: Emergency response failed - $e',
      );
      _onError?.call('EMERGENCY_RESPONSE_FAILED');
    }
  }

  /// Request user verification
  void _requestUserVerification(
    String detectionType,
    Map<String, dynamic> data,
    Map<String, dynamic> aiDecision,
  ) {
    debugPrint(
      'ChatGPTAIVerificationService: Requesting user verification for $detectionType',
    );

    // This would trigger the UI verification overlay
    // For now, we'll log the request
    debugPrint(
      'ChatGPTAIVerificationService: AI requests user verification - ${aiDecision['reasoning']}',
    );
  }

  /// Suppress alert (false positive)
  void _suppressAlert(
    String detectionType,
    Map<String, dynamic> data,
    Map<String, dynamic> aiDecision,
  ) {
    debugPrint(
      'ChatGPTAIVerificationService: Alert suppressed - ${aiDecision['reasoning']}',
    );

    // Log the suppression for analytics
    debugPrint(
      'ChatGPTAIVerificationService: False positive indicators: ${aiDecision['false_positive_indicators']}',
    );
  }

  /// Trigger immediate emergency (bypass AI for severe cases)
  void _triggerImmediateEmergency(
    String detectionType,
    Map<String, dynamic> data,
  ) async {
    debugPrint(
      'ChatGPTAIVerificationService: 🚨 IMMEDIATE EMERGENCY - $detectionType',
    );

    // Same as _triggerEmergencyResponse but with immediate flag
    _triggerEmergencyResponse(detectionType, data, {
      'is_emergency': true,
      'confidence': 1.0,
      'reasoning': 'Immediate emergency - severity bypassed AI analysis',
      'recommendation': 'proceed_with_sos',
    });
  }

  /// Set callbacks
  void setOnEmergencyDetected(Function(String, Map<String, dynamic>) callback) {
    _onEmergencyDetected = callback;
  }

  void setOnError(Function(String) callback) {
    _onError = callback;
  }

  void setOnAIAnalysisComplete(Function(String) callback) {
    _onAIAnalysisComplete = callback;
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isMonitoring': _isMonitoring,
      'isAIAnalyzing': _isAIAnalyzing,
      'lastAIAnalysis': _lastAIAnalysis,
      'lastAIPrediction': _lastAIPrediction,
      'sensorDataBufferSize': _sensorDataBuffer.length,
      'contextDataBufferSize': _contextDataBuffer.length,
      'lastSpeed': _lastSpeed,
      'isStationary': _isStationary,
      'hasMotionResumed': _hasMotionResumed,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _sensorDataBuffer.clear();
    _contextDataBuffer.clear();
    _isInitialized = false;
  }
}
