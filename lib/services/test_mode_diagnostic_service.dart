import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Comprehensive diagnostic data collection and export service for Test Mode v2.0
class TestModeDiagnosticService {
  static final TestModeDiagnosticService _instance =
      TestModeDiagnosticService._internal();
  factory TestModeDiagnosticService() => _instance;
  TestModeDiagnosticService._internal();

  // Diagnostic state
  bool _isRecording = false;
  DateTime? _sessionStartTime;
  String? _currentSessionId;

  // Event buffer (circular buffer, max 1000 events)
  final List<DiagnosticEvent> _events = [];
  static const int maxEvents = 1000;

  // Real-time sensor trace (sampled at 10Hz during active detection)
  final List<SensorSample> _sensorTrace = [];
  static const int maxSensorSamples = 3000; // 5 minutes at 10Hz

  // Session summary metrics
  int _detectionCount = 0;
  int _truePositives = 0;
  int _falseAlarms = 0;
  int _smsSent = 0;
  Duration? _avgResponseTime;

  // Stream controllers for real-time updates
  final _eventStreamController = StreamController<DiagnosticEvent>.broadcast();
  final _sensorStreamController = StreamController<SensorSample>.broadcast();
  final _stateStreamController = StreamController<DetectionState>.broadcast();

  // Getters
  bool get isRecording => _isRecording;
  String? get currentSessionId => _currentSessionId;
  Stream<DiagnosticEvent> get eventStream => _eventStreamController.stream;
  Stream<SensorSample> get sensorStream => _sensorStreamController.stream;
  Stream<DetectionState> get stateStream => _stateStreamController.stream;
  List<DiagnosticEvent> get events => List.unmodifiable(_events);
  List<SensorSample> get sensorTrace => List.unmodifiable(_sensorTrace);

  /// Snapshot of the current session for UI overlays
  Map<String, dynamic>? get currentSession {
    if (!_isRecording || _sessionStartTime == null) return null;
    return {
      'sessionStart': _sessionStartTime!.toIso8601String(),
      'events': _events.map((e) => e.toJson()).toList(),
      'sensorTrace': _sensorTrace
          .map(
            (s) => {
              'timestamp': s.timestamp.toIso8601String(),
              'accelerometer': s.accelerometer,
              'magnitude': s.magnitude,
            },
          )
          .toList(),
    };
  }

  /// Start new diagnostic session
  void startSession() {
    if (_isRecording) {
      debugPrint('[TestDiagnostic] Session already recording');
      return;
    }

    _isRecording = true;
    _sessionStartTime = DateTime.now();
    _currentSessionId = 'test_${_sessionStartTime!.millisecondsSinceEpoch}';

    _events.clear();
    _sensorTrace.clear();
    _detectionCount = 0;
    _truePositives = 0;
    _falseAlarms = 0;
    _smsSent = 0;

    _logEvent(
      type: 'session_start',
      phase: 'init',
      data: {
        'sessionId': _currentSessionId,
        'timestamp': _sessionStartTime!.toIso8601String(),
      },
    );

    debugPrint('[TestDiagnostic] Session started: $_currentSessionId');
  }

  /// Stop current diagnostic session
  void stopSession() {
    if (!_isRecording) return;

    _logEvent(
      type: 'session_end',
      phase: 'complete',
      data: {
        'duration': DateTime.now()
            .difference(_sessionStartTime!)
            .inMilliseconds,
        'eventCount': _events.length,
        'sensorSamples': _sensorTrace.length,
      },
    );

    _isRecording = false;
    debugPrint('[TestDiagnostic] Session stopped: $_currentSessionId');
  }

  /// Log diagnostic event
  void _logEvent({
    required String type,
    required String phase,
    required Map<String, dynamic> data,
  }) {
    if (!_isRecording) return;

    final event = DiagnosticEvent(
      timestamp: DateTime.now(),
      eventType: type,
      phase: phase,
      data: data,
      elapsedSinceSession: DateTime.now().difference(_sessionStartTime!),
    );

    // Add to circular buffer
    if (_events.length >= maxEvents) {
      _events.removeAt(0);
    }
    _events.add(event);

    // Broadcast to stream
    _eventStreamController.add(event);
  }

  /// Log sensor data sample
  void logSensorSample({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double magnitude,
    required double jerk,
  }) {
    if (!_isRecording) return;

    final sample = SensorSample(
      timestamp: DateTime.now(),
      accelerometer: [accelX, accelY, accelZ],
      gyroscope: [gyroX, gyroY, gyroZ],
      magnitude: magnitude,
      jerk: jerk,
      elapsedSinceSession: DateTime.now().difference(_sessionStartTime!),
    );

    if (_sensorTrace.length >= maxSensorSamples) {
      _sensorTrace.removeAt(0);
    }
    _sensorTrace.add(sample);

    _sensorStreamController.add(sample);
  }

  /// Log detection triggered
  void logDetection({
    required String type, // crash, fall, shake, manual
    required String reason,
    required double thresholdUsed,
    required double actualValue,
    required bool testMode,
    Map<String, dynamic>? additionalData,
  }) {
    _detectionCount++;

    _logEvent(
      type: 'detection',
      phase: 'triggered',
      data: {
        'detectionType': type,
        'reason': reason,
        'thresholdUsed': thresholdUsed,
        'actualValue': actualValue,
        'testMode': testMode,
        'comparison':
            '${actualValue.toStringAsFixed(2)} vs ${thresholdUsed.toStringAsFixed(2)}',
        ...?additionalData,
      },
    );
  }

  /// Log verification phase
  void logVerification({
    required String phase, // voice, motion, inactivity
    required String status, // started, completed, skipped
    Duration? duration,
    double? confidence,
    Map<String, dynamic>? additionalData,
  }) {
    _logEvent(
      type: 'verification',
      phase: phase,
      data: {
        'status': status,
        'duration': duration?.inMilliseconds,
        'confidence': confidence,
        ...?additionalData,
      },
    );
  }

  /// Log state transition
  void logStateTransition({
    required String fromState,
    required String toState,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) {
    _logEvent(
      type: 'state_transition',
      phase: 'transition',
      data: {
        'from': fromState,
        'to': toState,
        'reason': reason,
        ...?additionalData,
      },
    );

    _stateStreamController.add(
      DetectionState(state: toState, timestamp: DateTime.now(), reason: reason),
    );
  }

  /// Log SMS sent
  void logSMS({
    required String recipient,
    required String messageType,
    required bool testMode,
    bool success = true,
  }) {
    if (success) _smsSent++;

    _logEvent(
      type: 'sms',
      phase: 'sent',
      data: {
        'recipient': testMode ? 'TEST_CONTACT' : 'REAL_CONTACT',
        'messageType': messageType,
        'testMode': testMode,
        'success': success,
      },
    );
  }

  /// Log user interaction
  void logUserInteraction({
    required String interactionType, // cancel, voice_response, button_tap
    required String context,
    Map<String, dynamic>? additionalData,
  }) {
    _logEvent(
      type: 'user_interaction',
      phase: 'interaction',
      data: {'type': interactionType, 'context': context, ...?additionalData},
    );
  }

  /// Log outcome
  void logOutcome({
    required String outcome, // activated, cancelled, false_alarm, no_response
    required String reason,
    bool isTruePositive = false,
    bool isFalseAlarm = false,
  }) {
    if (isTruePositive) _truePositives++;
    if (isFalseAlarm) _falseAlarms++;

    _logEvent(
      type: 'outcome',
      phase: 'final',
      data: {
        'outcome': outcome,
        'reason': reason,
        'truePositive': isTruePositive,
        'falseAlarm': isFalseAlarm,
      },
    );
  }

  /// Export session as JSON
  Future<String> exportSessionAsJson() async {
    if (_currentSessionId == null) {
      throw Exception('No active session to export');
    }

    final export = {
      'sessionId': _currentSessionId,
      'version': '2.0',
      'exportTime': DateTime.now().toIso8601String(),
      'sessionInfo': {
        'startTime': _sessionStartTime!.toIso8601String(),
        'duration': DateTime.now()
            .difference(_sessionStartTime!)
            .inMilliseconds,
        'testModeEnabled': true,
      },
      'deviceInfo': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        // Add more device info as needed
      },
      'configuration': {
        'testModeThresholds': {'crashG': 8.0, 'fallMeters': 0.3, 'shakeG': 6.0},
        'productionThresholds': {'crashG': 35.0, 'fallMeters': 1.0},
      },
      'summary': {
        'totalDetections': _detectionCount,
        'truePositives': _truePositives,
        'falseAlarms': _falseAlarms,
        'smsSent': _smsSent,
        'eventCount': _events.length,
        'sensorSamples': _sensorTrace.length,
      },
      'events': _events.map((e) => e.toJson()).toList(),
      'sensorTrace': _sensorTrace.map((s) => s.toJson()).toList(),
    };

    return JsonEncoder.withIndent('  ').convert(export);
  }

  /// Export session as CSV
  Future<String> exportSessionAsCsv() async {
    if (_currentSessionId == null) {
      throw Exception('No active session to export');
    }

    final buffer = StringBuffer();

    // Header
    buffer.writeln('Timestamp,Elapsed(ms),Type,Phase,Data');

    // Events
    for (final event in _events) {
      buffer.writeln(
        '${event.timestamp.toIso8601String()},'
        '${event.elapsedSinceSession.inMilliseconds},'
        '${event.eventType},'
        '${event.phase},'
        '"${jsonEncode(event.data)}"',
      );
    }

    return buffer.toString();
  }

  /// Save and share export
  Future<void> shareExport({bool asJson = true}) async {
    try {
      final content = asJson
          ? await exportSessionAsJson()
          : await exportSessionAsCsv();

      final extension = asJson ? 'json' : 'csv';
      final filename = 'redping_test_${_currentSessionId}.$extension';

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(content);

      // Share
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'RedPing Test Session: $_currentSessionId');

      debugPrint('[TestDiagnostic] Export shared: $filename');
    } catch (e) {
      debugPrint('[TestDiagnostic] Export failed: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _eventStreamController.close();
    _sensorStreamController.close();
    _stateStreamController.close();
  }
}

/// Diagnostic event model
class DiagnosticEvent {
  final DateTime timestamp;
  final String eventType;
  final String phase;
  final Map<String, dynamic> data;
  final Duration elapsedSinceSession;

  DiagnosticEvent({
    required this.timestamp,
    required this.eventType,
    required this.phase,
    required this.data,
    required this.elapsedSinceSession,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'elapsed_ms': elapsedSinceSession.inMilliseconds,
    'type': eventType,
    'phase': phase,
    'data': data,
  };
}

/// Sensor sample model
class SensorSample {
  final DateTime timestamp;
  final List<double> accelerometer; // [x, y, z]
  final List<double> gyroscope; // [x, y, z]
  final double magnitude;
  final double jerk;
  final Duration elapsedSinceSession;

  SensorSample({
    required this.timestamp,
    required this.accelerometer,
    required this.gyroscope,
    required this.magnitude,
    required this.jerk,
    required this.elapsedSinceSession,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'elapsed_ms': elapsedSinceSession.inMilliseconds,
    'accel_x': accelerometer[0],
    'accel_y': accelerometer[1],
    'accel_z': accelerometer[2],
    'gyro_x': gyroscope[0],
    'gyro_y': gyroscope[1],
    'gyro_z': gyroscope[2],
    'magnitude': magnitude,
    'jerk': jerk,
  };
}

/// Detection state model
class DetectionState {
  final String state;
  final DateTime timestamp;
  final String reason;

  DetectionState({
    required this.state,
    required this.timestamp,
    required this.reason,
  });
}
