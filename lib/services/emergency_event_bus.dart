import 'dart:async';
import '../core/logging/app_logger.dart';
import '../models/sos_session.dart';

/// Emergency Event Types
enum EmergencyEventType {
  // SOS Events
  sosActivated,
  sosCancelled,
  sosResolved,
  sosStatusChanged,

  // WebRTC Events
  webrtcCallStarted,
  webrtcCallConnected,
  webrtcCallFailed,
  webrtcCallEnded,
  webrtcTokenGenerated,
  webrtcTokenFailed,

  // SMS Events
  smsInitialSent,
  smsFollowUpSent,
  smsEscalationSent,
  smsAcknowledgedSent,
  smsResolvedSent,
  smsSendFailed,
  smsBulkComplete,

  // AI Events
  aiMonitoringStarted,
  aiMonitoringStopped,
  aiVerificationAttempt,
  aiUserResponsive,
  aiUserUnresponsive,
  aiEmergencyCallInitiated,
  aiDecisionMade,

  // SAR Events
  sarTeamAssigned,
  sarTeamEnRoute,
  sarTeamArrived,
  sarResponseTimeout,

  // Location Events
  locationUpdated,
  locationAccuracyChanged,

  // Contact Events
  emergencyContactAlerted,
  emergencyContactResponded,

  // System Events
  serviceError,
  networkStatusChanged,
  batteryLevelCritical,
}

/// Emergency Event
class EmergencyEvent {
  final EmergencyEventType type;
  final String sessionId;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? message;
  final dynamic error;

  EmergencyEvent({
    required this.type,
    required this.sessionId,
    required this.timestamp,
    this.data = const {},
    this.message,
    this.error,
  });

  @override
  String toString() {
    return 'EmergencyEvent{type: $type, sessionId: $sessionId, time: $timestamp, message: $message}';
  }

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'sessionId': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'message': message,
    'error': error?.toString(),
  };
}

/// Emergency Event Bus
/// Central coordination system for all emergency services
class EmergencyEventBus {
  static final EmergencyEventBus _instance = EmergencyEventBus._internal();
  factory EmergencyEventBus() => _instance;
  EmergencyEventBus._internal();

  // Event streams by type
  final Map<EmergencyEventType, StreamController<EmergencyEvent>> _controllers =
      {};

  // Global event stream (all events)
  final StreamController<EmergencyEvent> _globalController =
      StreamController<EmergencyEvent>.broadcast();

  // Event history for debugging
  final List<EmergencyEvent> _eventHistory = [];
  static const int _maxHistorySize = 100;

  // Session-specific tracking
  final Map<String, List<EmergencyEvent>> _sessionEvents = {};

  /// Get stream for specific event type
  Stream<EmergencyEvent> on(EmergencyEventType type) {
    if (!_controllers.containsKey(type)) {
      _controllers[type] = StreamController<EmergencyEvent>.broadcast();
    }
    return _controllers[type]!.stream;
  }

  /// Get global event stream (all events)
  Stream<EmergencyEvent> get stream => _globalController.stream;

  /// Fire an emergency event
  void fire(EmergencyEvent event) {
    AppLogger.i(
      '🔔 Event: ${event.type} | Session: ${event.sessionId} | ${event.message ?? ""}',
      tag: 'EventBus',
    );

    // Add to history
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }

    // Add to session tracking
    if (!_sessionEvents.containsKey(event.sessionId)) {
      _sessionEvents[event.sessionId] = [];
    }
    _sessionEvents[event.sessionId]!.add(event);

    // Fire to global stream
    _globalController.add(event);

    // Fire to type-specific stream
    if (_controllers.containsKey(event.type)) {
      _controllers[event.type]!.add(event);
    }
  }

  /// Quick fire methods for common events

  void fireSosActivated(SOSSession session, {String? message}) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.sosActivated,
        sessionId: session.id,
        timestamp: DateTime.now(),
        message: message ?? 'SOS activated: ${session.type}',
        data: {
          'sosType': session.type.toString(),
          'status': session.status.toString(),
        },
      ),
    );
  }

  void fireWebRTCCallStarted(
    String sessionId,
    String channelName,
    String contactId,
  ) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.webrtcCallStarted,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: 'WebRTC call started to $contactId',
        data: {'channelName': channelName, 'contactId': contactId},
      ),
    );
  }

  void fireWebRTCCallConnected(String sessionId, String channelName) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.webrtcCallConnected,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: 'WebRTC call connected',
        data: {'channelName': channelName},
      ),
    );
  }

  void fireWebRTCCallFailed(String sessionId, dynamic error) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.webrtcCallFailed,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: 'WebRTC call failed',
        error: error,
      ),
    );
  }

  void fireSMSSent(
    String sessionId,
    EmergencyEventType type,
    int recipientCount, {
    String? message,
  }) {
    fire(
      EmergencyEvent(
        type: type,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: message ?? 'SMS sent to $recipientCount recipients',
        data: {'recipientCount': recipientCount},
      ),
    );
  }

  void fireSMSFailed(String sessionId, String phoneNumber, dynamic error) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.smsSendFailed,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: 'SMS failed to $phoneNumber',
        error: error,
        data: {'phoneNumber': phoneNumber},
      ),
    );
  }

  void fireAIMonitoringStarted(String sessionId, String monitoringReason) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.aiMonitoringStarted,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: 'AI monitoring started: $monitoringReason',
        data: {'reason': monitoringReason},
      ),
    );
  }

  void fireAIVerificationAttempt(
    String sessionId,
    int attemptNumber,
    bool responsive,
  ) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.aiVerificationAttempt,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message:
            'AI verification attempt #$attemptNumber: ${responsive ? "Responsive" : "No response"}',
        data: {'attemptNumber': attemptNumber, 'responsive': responsive},
      ),
    );
  }

  void fireAIEmergencyCallInitiated(
    String sessionId,
    String targetNumber,
    String reason,
  ) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.aiEmergencyCallInitiated,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: 'AI initiating emergency call to $targetNumber: $reason',
        data: {'targetNumber': targetNumber, 'reason': reason},
      ),
    );
  }

  void fireServiceError(
    String sessionId,
    String service,
    dynamic error, {
    String? context,
  }) {
    fire(
      EmergencyEvent(
        type: EmergencyEventType.serviceError,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        message: '$service error: ${context ?? ""}',
        error: error,
        data: {'service': service, 'context': context},
      ),
    );
  }

  /// Get all events for a session
  List<EmergencyEvent> getSessionEvents(String sessionId) {
    return _sessionEvents[sessionId] ?? [];
  }

  /// Get recent events (last N)
  List<EmergencyEvent> getRecentEvents([int count = 20]) {
    final start = _eventHistory.length > count
        ? _eventHistory.length - count
        : 0;
    return _eventHistory.sublist(start);
  }

  /// Get event history
  List<EmergencyEvent> get history => List.unmodifiable(_eventHistory);

  /// Clear history for a session (when resolved)
  void clearSessionHistory(String sessionId) {
    _sessionEvents.remove(sessionId);
    AppLogger.i(
      'Event history cleared for session $sessionId',
      tag: 'EventBus',
    );
  }

  /// Clear all history
  void clearAllHistory() {
    _eventHistory.clear();
    _sessionEvents.clear();
    AppLogger.i('All event history cleared', tag: 'EventBus');
  }

  /// Get event statistics
  Map<String, dynamic> getStatistics() {
    final stats = <EmergencyEventType, int>{};
    for (final event in _eventHistory) {
      stats[event.type] = (stats[event.type] ?? 0) + 1;
    }

    return {
      'totalEvents': _eventHistory.length,
      'activeSessions': _sessionEvents.length,
      'eventsByType': stats.map((k, v) => MapEntry(k.toString(), v)),
      'oldestEvent': _eventHistory.isNotEmpty
          ? _eventHistory.first.timestamp.toIso8601String()
          : null,
      'newestEvent': _eventHistory.isNotEmpty
          ? _eventHistory.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Dispose (cleanup)
  void dispose() {
    _globalController.close();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _eventHistory.clear();
    _sessionEvents.clear();
  }
}

/// Emergency Event Listener Helper
/// Makes it easier to listen to multiple event types
class EmergencyEventListener {
  final EmergencyEventBus _eventBus = EmergencyEventBus();
  final List<StreamSubscription<EmergencyEvent>> _subscriptions = [];

  /// Listen to specific event type
  void on(EmergencyEventType type, void Function(EmergencyEvent) handler) {
    final subscription = _eventBus.on(type).listen(handler);
    _subscriptions.add(subscription);
  }

  /// Listen to multiple event types
  void onMany(
    List<EmergencyEventType> types,
    void Function(EmergencyEvent) handler,
  ) {
    for (final type in types) {
      on(type, handler);
    }
  }

  /// Listen to all events
  void onAll(void Function(EmergencyEvent) handler) {
    final subscription = _eventBus.stream.listen(handler);
    _subscriptions.add(subscription);
  }

  /// Listen to events for specific session
  void onSession(String sessionId, void Function(EmergencyEvent) handler) {
    final subscription = _eventBus.stream
        .where((event) => event.sessionId == sessionId)
        .listen(handler);
    _subscriptions.add(subscription);
  }

  /// Cancel all subscriptions
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
