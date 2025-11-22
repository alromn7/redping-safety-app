import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_session.dart';
import '../models/verification_result.dart';
import '../core/logging/app_logger.dart';

/// SOS Analytics Service for tracking emergency response metrics
///
/// Tracks:
/// - SOS activation events
/// - SAR team response times
/// - Resolution outcomes
/// - SMS and notification counts
/// - Session duration analytics
class SOSAnalyticsService {
  static final SOSAnalyticsService instance = SOSAnalyticsService._internal();
  factory SOSAnalyticsService() => instance;
  SOSAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _coordinatorLoggingEnabled = false; // default off for unit tests

  void enableCoordinatorLogging(bool enabled) {
    _coordinatorLoggingEnabled = enabled;
  }

  /// Log verification outcome with latency (coordinator event)
  Future<void> logVerificationOutcomeEvent({
    required DetectionType type,
    required VerificationOutcome outcome,
    required double confidence,
    required Duration latency,
  }) async {
    try {
      if (!_coordinatorLoggingEnabled) {
        debugPrint(
          'Analytics[coordinator]: verification outcome ${outcome.name} conf=${confidence.toStringAsFixed(2)} latency=${latency.inMilliseconds}ms',
        );
        return;
      }
      await _firestore
          .collection('analytics')
          .doc('coordinator_events')
          .collection('verification')
          .add({
            'detectionType': type.name,
            'outcome': outcome.name,
            'confidence': confidence,
            'latencyMs': latency.inMilliseconds,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.w(
        'Failed to log verification outcome',
        tag: 'SOSAnalytics',
        error: e,
      );
    }
  }

  /// Log fallback trigger (coordinator event)
  Future<void> logFallbackTriggered({
    required DetectionType type,
    required String reasonCode,
    required Duration delay,
  }) async {
    try {
      if (!_coordinatorLoggingEnabled) {
        debugPrint(
          'Analytics[coordinator]: fallback $reasonCode after ${delay.inSeconds}s',
        );
        return;
      }
      await _firestore
          .collection('analytics')
          .doc('coordinator_events')
          .collection('fallbacks')
          .add({
            'detectionType': type.name,
            'reasonCode': reasonCode,
            'delaySeconds': delay.inSeconds,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.w('Failed to log fallback', tag: 'SOSAnalytics', error: e);
    }
  }

  /// Log SOS activation event
  ///
  /// Records when a user activates an SOS session
  /// Tracks: type, location, timestamp, user details
  Future<void> logSOSActivation(SOSSession session) async {
    try {
      await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('activations')
          .add({
            'sessionId': session.id,
            'userId': session.userId,
            'type': session.type.toString().split('.').last,
            'timestamp': FieldValue.serverTimestamp(),
            'location': {
              'lat': session.location.latitude,
              'lon': session.location.longitude,
              'accuracy': session.location.accuracy,
              'address': session.location.address ?? 'Unknown',
            },
            'metadata': {
              'isTestMode': session.isTestMode,
              'userMessage': session.userMessage,
            },
          });

      AppLogger.i(
        'Analytics: SOS activation logged - ${session.id}',
        tag: 'SOSAnalytics',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to log SOS activation',
        tag: 'SOSAnalytics',
        error: e,
      );
    }
  }

  /// Log SAR team response event
  ///
  /// Records when a SAR team member acknowledges/responds to SOS
  /// Tracks: response time, SAR user, session details
  Future<void> logSARResponse({
    required String sessionId,
    required String sarUserId,
    required String sarUserName,
    required Duration responseTime,
    required String
    responseType, // 'acknowledged', 'assigned', 'enroute', 'onscene'
  }) async {
    try {
      await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('responses')
          .add({
            'sessionId': sessionId,
            'sarUserId': sarUserId,
            'sarUserName': sarUserName,
            'responseType': responseType,
            'responseTimeSeconds': responseTime.inSeconds,
            'responseTimeMinutes': responseTime.inMinutes,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update session with response time
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'analytics.firstResponseTime': responseTime.inSeconds,
        'analytics.firstResponseType': responseType,
        'analytics.firstResponderId': sarUserId,
      });

      AppLogger.i(
        'Analytics: SAR response logged - $responseType in ${responseTime.inSeconds}s',
        tag: 'SOSAnalytics',
      );
    } catch (e) {
      AppLogger.w('Failed to log SAR response', tag: 'SOSAnalytics', error: e);
    }
  }

  /// Log SOS resolution event
  ///
  /// Records when an SOS session is resolved
  /// Tracks: outcome, duration, SMS/notification counts, resolution details
  Future<void> logSOSResolution({
    required String sessionId,
    required String
    outcome, // 'safe', 'injured', 'false_alarm', 'unable_to_locate', 'cancelled'
    required DateTime startTime,
    String? resolutionNotes,
    String? resolvedBy,
    int? smsCount,
    int? notificationCount,
  }) async {
    try {
      final duration = DateTime.now().difference(startTime);

      await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('resolutions')
          .add({
            'sessionId': sessionId,
            'outcome': outcome,
            'durationSeconds': duration.inSeconds,
            'durationMinutes': duration.inMinutes,
            'smsCount': smsCount ?? 0,
            'notificationCount': notificationCount ?? 0,
            'resolvedBy': resolvedBy,
            'resolutionNotes': resolutionNotes,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update session analytics summary
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'analytics.totalDurationSeconds': duration.inSeconds,
        'analytics.totalDurationMinutes': duration.inMinutes,
        'analytics.smsCount': smsCount ?? 0,
        'analytics.notificationCount': notificationCount ?? 0,
        'analytics.outcome': outcome,
        'analytics.completedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.i(
        'Analytics: SOS resolution logged - $outcome after ${duration.inMinutes} minutes',
        tag: 'SOSAnalytics',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to log SOS resolution',
        tag: 'SOSAnalytics',
        error: e,
      );
    }
  }

  /// Get session analytics summary
  ///
  /// Retrieves comprehensive analytics for a specific session
  Future<Map<String, dynamic>> getSessionAnalytics(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        return {'error': 'Session not found'};
      }

      final data = sessionDoc.data()!;
      final analytics = data['analytics'] as Map<String, dynamic>? ?? {};

      return {
        'sessionId': sessionId,
        'status': data['status'],
        'type': data['type'],
        'startTime': data['startTime'],
        'endTime': data['endTime'],
        'duration': analytics['totalDurationMinutes'] ?? 0,
        'smsCount': analytics['smsCount'] ?? 0,
        'notificationCount': analytics['notificationCount'] ?? 0,
        'outcome': analytics['outcome'] ?? 'unknown',
        'firstResponseTime': analytics['firstResponseTime'],
        'firstResponseType': analytics['firstResponseType'],
      };
    } catch (e) {
      AppLogger.w(
        'Failed to get session analytics',
        tag: 'SOSAnalytics',
        error: e,
      );
      return {'error': e.toString()};
    }
  }

  /// Get aggregate statistics for a date range
  ///
  /// Retrieves summary statistics across multiple sessions
  Future<Map<String, dynamic>> getAggregateStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all activations in date range
      final activationsSnapshot = await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('activations')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      // Get all resolutions in date range
      final resolutionsSnapshot = await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('resolutions')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      // Get all responses in date range
      final responsesSnapshot = await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('responses')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      // Calculate statistics
      final totalActivations = activationsSnapshot.docs.length;
      final totalResolutions = resolutionsSnapshot.docs.length;
      final totalResponses = responsesSnapshot.docs.length;

      // Outcome breakdown
      final outcomes = <String, int>{};
      for (final doc in resolutionsSnapshot.docs) {
        final outcome = doc.data()['outcome'] as String;
        outcomes[outcome] = (outcomes[outcome] ?? 0) + 1;
      }

      // Average response time
      final responseTimes = responsesSnapshot.docs
          .map((doc) => doc.data()['responseTimeSeconds'] as int? ?? 0)
          .toList();
      final avgResponseTime = responseTimes.isEmpty
          ? 0
          : responseTimes.reduce((a, b) => a + b) / responseTimes.length;

      // Average resolution time
      final resolutionTimes = resolutionsSnapshot.docs
          .map((doc) => doc.data()['durationMinutes'] as int? ?? 0)
          .toList();
      final avgResolutionTime = resolutionTimes.isEmpty
          ? 0
          : resolutionTimes.reduce((a, b) => a + b) / resolutionTimes.length;

      return {
        'totalActivations': totalActivations,
        'totalResolutions': totalResolutions,
        'totalResponses': totalResponses,
        'outcomeBreakdown': outcomes,
        'averageResponseTimeSeconds': avgResponseTime.round(),
        'averageResolutionTimeMinutes': avgResolutionTime.round(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
    } catch (e) {
      AppLogger.w(
        'Failed to get aggregate statistics',
        tag: 'SOSAnalytics',
        error: e,
      );
      return {'error': e.toString()};
    }
  }

  /// Log status change event
  ///
  /// Records when session status changes (for detailed tracking)
  Future<void> logStatusChange({
    required String sessionId,
    required String fromStatus,
    required String toStatus,
    String? changedBy,
  }) async {
    try {
      await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('status_changes')
          .add({
            'sessionId': sessionId,
            'fromStatus': fromStatus,
            'toStatus': toStatus,
            'changedBy': changedBy,
            'timestamp': FieldValue.serverTimestamp(),
          });

      debugPrint('Analytics: Status change logged - $fromStatus → $toStatus');
    } catch (e) {
      debugPrint('Failed to log status change: $e');
    }
  }

  /// Log escalation event
  ///
  /// Records when auto-escalation occurs (20 min no response)
  Future<void> logAutoEscalation({
    required String sessionId,
    required int notificationCount,
    required Duration timeSinceActivation,
  }) async {
    try {
      await _firestore
          .collection('analytics')
          .doc('sos_events')
          .collection('escalations')
          .add({
            'sessionId': sessionId,
            'notificationCount': notificationCount,
            'timeSinceActivationMinutes': timeSinceActivation.inMinutes,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update session with escalation flag
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'analytics.wasEscalated': true,
        'analytics.escalatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.w(
        'Analytics: Auto-escalation logged after ${timeSinceActivation.inMinutes} minutes',
        tag: 'SOSAnalytics',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to log auto-escalation',
        tag: 'SOSAnalytics',
        error: e,
      );
    }
  }
}
