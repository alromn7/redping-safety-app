import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/communication_log.dart';
import '../core/logging/app_logger.dart';

/// Service for tracking SAR team communications (calls, SMS, etc.)
/// Aligned with website's communication logging functionality
class CommunicationTrackingService {
  static final CommunicationTrackingService _instance =
      CommunicationTrackingService._internal();
  factory CommunicationTrackingService() => _instance;
  CommunicationTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log a phone call communication
  Future<bool> logCall({
    required String recipientPhone,
    required String recipientName,
    String? sosId,
    String? helpRequestId,
    String? recipientId,
    required String senderId,
    required String senderName,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Create communication log
      final log = CommunicationLog.call(
        recipientPhone: recipientPhone,
        recipientName: recipientName,
        sosId: sosId,
        helpRequestId: helpRequestId,
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        metadata: additionalMetadata,
      );

      // Determine collection and document ID
      final collection = sosId != null ? 'sos_sessions' : 'help_requests';
      final documentId = sosId ?? helpRequestId;

      if (documentId == null) {
        AppLogger.e(
          'Cannot log call: No sosId or helpRequestId provided',
          tag: 'CommunicationTrackingService',
        );
        return false;
      }

      // Update Firestore
      await _updateFirestoreWithLog(
        collection: collection,
        documentId: documentId,
        log: log,
      );

      AppLogger.i(
        'Call logged successfully: ${log.id} to $recipientName',
        tag: 'CommunicationTrackingService',
      );

      return true;
    } catch (e) {
      AppLogger.e(
        'Failed to log call',
        tag: 'CommunicationTrackingService',
        error: e,
      );
      return false;
    }
  }

  /// Log an SMS communication
  Future<bool> logSMS({
    required String recipientPhone,
    required String recipientName,
    String? sosId,
    String? helpRequestId,
    String? recipientId,
    required String senderId,
    required String senderName,
    String? messageContent,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Create communication log
      final log = CommunicationLog.sms(
        recipientPhone: recipientPhone,
        recipientName: recipientName,
        sosId: sosId,
        helpRequestId: helpRequestId,
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        messageContent: messageContent,
        metadata: additionalMetadata,
      );

      // Determine collection and document ID
      final collection = sosId != null ? 'sos_sessions' : 'help_requests';
      final documentId = sosId ?? helpRequestId;

      if (documentId == null) {
        AppLogger.e(
          'Cannot log SMS: No sosId or helpRequestId provided',
          tag: 'CommunicationTrackingService',
        );
        return false;
      }

      // Update Firestore
      await _updateFirestoreWithLog(
        collection: collection,
        documentId: documentId,
        log: log,
      );

      AppLogger.i(
        'SMS logged successfully: ${log.id} to $recipientName',
        tag: 'CommunicationTrackingService',
      );

      return true;
    } catch (e) {
      AppLogger.e(
        'Failed to log SMS',
        tag: 'CommunicationTrackingService',
        error: e,
      );
      return false;
    }
  }

  /// Update Firestore with communication log
  Future<void> _updateFirestoreWithLog({
    required String collection,
    required String documentId,
    required CommunicationLog log,
  }) async {
    final docRef = _firestore.collection(collection).doc(documentId);
    final logData = log.toJson();

    await docRef.update({
      // Add to communicationHistory array
      'communicationHistory': FieldValue.arrayUnion([logData]),
      // Also add to messages array for compatibility with existing SOSSession model
      'messages': FieldValue.arrayUnion([logData]),
      // Update last communication
      'lastCommunication': logData,
      'lastMessageTimestamp': log.timestamp.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.d(
      'Firestore updated: $collection/$documentId with log ${log.id}',
      tag: 'CommunicationTrackingService',
    );
  }

  /// Get communication history for a session
  Future<List<CommunicationLog>> getCommunicationHistory({
    String? sosId,
    String? helpRequestId,
  }) async {
    try {
      final collection = sosId != null ? 'sos_sessions' : 'help_requests';
      final documentId = sosId ?? helpRequestId;

      if (documentId == null) {
        AppLogger.w(
          'Cannot get history: No sosId or helpRequestId provided',
          tag: 'CommunicationTrackingService',
        );
        return [];
      }

      final docSnapshot = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (!docSnapshot.exists) {
        AppLogger.w(
          'Document not found: $collection/$documentId',
          tag: 'CommunicationTrackingService',
        );
        return [];
      }

      final data = docSnapshot.data();
      final historyData = data?['communicationHistory'] as List<dynamic>?;

      if (historyData == null || historyData.isEmpty) {
        return [];
      }

      return historyData
          .map(
            (item) => CommunicationLog.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      AppLogger.e(
        'Failed to get communication history',
        tag: 'CommunicationTrackingService',
        error: e,
      );
      return [];
    }
  }

  /// Get last communication for a session
  Future<CommunicationLog?> getLastCommunication({
    String? sosId,
    String? helpRequestId,
  }) async {
    try {
      final collection = sosId != null ? 'sos_sessions' : 'help_requests';
      final documentId = sosId ?? helpRequestId;

      if (documentId == null) {
        return null;
      }

      final docSnapshot = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data();
      final lastCommData = data?['lastCommunication'] as Map<String, dynamic>?;

      if (lastCommData == null) {
        return null;
      }

      return CommunicationLog.fromJson(lastCommData);
    } catch (e) {
      AppLogger.e(
        'Failed to get last communication',
        tag: 'CommunicationTrackingService',
        error: e,
      );
      return null;
    }
  }

  /// Count communications for a session
  Future<int> getCommunicationCount({
    String? sosId,
    String? helpRequestId,
  }) async {
    final history = await getCommunicationHistory(
      sosId: sosId,
      helpRequestId: helpRequestId,
    );
    return history.length;
  }

  /// Check if user has been contacted
  Future<bool> hasBeenContacted({String? sosId, String? helpRequestId}) async {
    final count = await getCommunicationCount(
      sosId: sosId,
      helpRequestId: helpRequestId,
    );
    return count > 0;
  }
}
