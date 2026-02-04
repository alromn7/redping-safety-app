import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logging/app_logger.dart';
import '../models/sos_session.dart';
import 'sar_service.dart';

/// Service that listens for fall detection events from RedPing Doctor Plus
/// and automatically creates SAR sessions for emergency response
class SARFallDetectionListener {
  static final SARFallDetectionListener _instance =
      SARFallDetectionListener._internal();
  factory SARFallDetectionListener() => _instance;
  SARFallDetectionListener._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SARService _sarService = SARService();

  StreamSubscription<QuerySnapshot>? _fallDetectionSubscription;
  bool _isListening = false;
  final Set<String> _processedSessions = {};

  /// Start listening for fall detection SOS sessions
  Future<void> startListening() async {
    if (_isListening) {
      AppLogger.w(
        'Already listening for fall detection events',
        tag: 'SARFallDetectionListener',
      );
      return;
    }

    try {
      // Subscribe to sos_sessions collection filtered for fall detection events
      _fallDetectionSubscription = _firestore
          .collection('sos_sessions')
          .where('source', isEqualTo: 'redping_doctor_plus')
          .where('sosType', isEqualTo: 'fall_detection')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to recent events
          .snapshots()
          .listen(
            _handleFallDetectionEvents,
            onError: _handleError,
            cancelOnError: false,
          );

      _isListening = true;
      AppLogger.i(
        'Started listening for fall detection events',
        tag: 'SARFallDetectionListener',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to start listening for fall detection events',
        tag: 'SARFallDetectionListener',
        error: e,
      );
      rethrow;
    }
  }

  /// Handle incoming fall detection events
  void _handleFallDetectionEvents(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        _processFallDetectionEvent(change.doc);
      }
    }
  }

  /// Process a single fall detection event
  Future<void> _processFallDetectionEvent(DocumentSnapshot doc) async {
    try {
      final sessionId = doc.id;

      // Skip if already processed
      if (_processedSessions.contains(sessionId)) {
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        AppLogger.w(
          'Fall detection event has no data: $sessionId',
          tag: 'SARFallDetectionListener',
        );
        return;
      }

      // Mark as processed immediately to avoid duplicates
      _processedSessions.add(sessionId);

      // Extract required fields
      final userId = data['userId'] as String?;
      final userName = data['userName'] as String?;
      final locationData = data['location'] as Map<String, dynamic>?;
      final fallDetails = data['fallDetails'] as Map<String, dynamic>? ?? {};
      final medicalContext =
          data['medicalContext'] as Map<String, dynamic>? ?? {};
      final emergencyContactIds =
          (data['emergencyContactIds'] as List<dynamic>?)?.cast<String>() ?? [];

      // Validate required fields
      if (userId == null || userName == null || locationData == null) {
        AppLogger.w(
          'Fall detection event missing required fields: $sessionId',
          tag: 'SARFallDetectionListener',
        );
        return;
      }

      // Parse location
      final location = LocationInfo(
        latitude: (locationData['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (locationData['longitude'] as num?)?.toDouble() ?? 0.0,
        accuracy: (locationData['accuracy'] as num?)?.toDouble() ?? 0.0,
        altitude: (locationData['altitude'] as num?)?.toDouble(),
        speed: (locationData['speed'] as num?)?.toDouble(),
        heading: (locationData['heading'] as num?)?.toDouble(),
        timestamp: locationData['timestamp'] != null
            ? (locationData['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      );

      // Call SARService to handle the fall detection alert
      await _sarService.handleFallDetectionAlert(
        sosSessionId: sessionId,
        userId: userId,
        userName: userName,
        location: location,
        fallDetails: fallDetails,
        medicalContext: medicalContext,
        emergencyContactIds: emergencyContactIds,
      );

      AppLogger.i(
        'Processed fall detection event for $userName (session: $sessionId)',
        tag: 'SARFallDetectionListener',
      );
    } catch (e) {
      AppLogger.e(
        'Error processing fall detection event: ${doc.id}',
        tag: 'SARFallDetectionListener',
        error: e,
      );
    }
  }

  /// Handle stream errors
  void _handleError(Object error, StackTrace stackTrace) {
    AppLogger.e(
      'Error in fall detection listener stream',
      tag: 'SARFallDetectionListener',
      error: error,
    );

    // Attempt to restart listening after error
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isListening) {
        AppLogger.i(
          'Attempting to restart fall detection listener',
          tag: 'SARFallDetectionListener',
        );
        startListening();
      }
    });
  }

  /// Stop listening for fall detection events
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    await _fallDetectionSubscription?.cancel();
    _fallDetectionSubscription = null;
    _isListening = false;
    _processedSessions.clear();

    AppLogger.i(
      'Stopped listening for fall detection events',
      tag: 'SARFallDetectionListener',
    );
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get count of processed sessions
  int get processedCount => _processedSessions.length;

  /// Clear processed sessions cache (useful for testing)
  void clearProcessedCache() {
    _processedSessions.clear();
    AppLogger.i(
      'Cleared processed sessions cache',
      tag: 'SARFallDetectionListener',
    );
  }
}
