import 'package:flutter/foundation.dart';
import '../models/sos_session.dart' as sos;
import '../core/logging/app_logger.dart';

/// Minimal ChatService stub for emergency messaging compatibility only
///
/// **COMMUNITY CHAT HAS BEEN REMOVED**
/// Community chat is now available exclusively on the RedPing website.
///
/// This service maintains minimal compatibility with existing code that calls
/// sendSOSMessage() and sendMessage() but no longer provides:
/// - WebSocket connections
/// - Chat rooms
/// - Nearby users
/// - Community messaging
/// - Real-time chat features
///
/// Emergency messaging is handled by:
/// - EmergencyMessagingService (SOS user messages)
/// - SARMessagingService (SAR member communications)
/// - MessagingIntegrationService (routing between services)
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  bool _isInitialized = false;

  /// Initialize chat service (stub - does minimal setup)
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    AppLogger.i(
      'ChatService stub initialized - Community chat removed (use website)',
      tag: 'ChatService',
    );
  }

  /// Send emergency SOS message (stub - logs only)
  ///
  /// Emergency messaging is now handled by EmergencyMessagingService.
  /// This method exists only for backward compatibility.
  Future<void> sendSOSMessage({
    required sos.SOSSession session,
    required String content,
    sos.LocationInfo? location,
  }) async {
    if (kDebugMode) {
      AppLogger.d(
        'ChatService.sendSOSMessage called (stub) - handled by EmergencyMessagingService',
        tag: 'ChatService',
      );
    }
    // Emergency messaging is handled by EmergencyMessagingService
    // This is a compatibility stub only
  }

  /// Send message (stub - logs only)
  ///
  /// Real messaging is handled by EmergencyMessagingService and SARMessagingService.
  /// This method exists only for backward compatibility.
  Future<void> sendMessage({
    required String chatId,
    required String content,
    dynamic type,
    dynamic priority,
    dynamic location,
    List<dynamic>? attachments,
    String? replyToMessageId,
  }) async {
    if (kDebugMode) {
      AppLogger.d(
        'ChatService.sendMessage called (stub) - use EmergencyMessagingService/SARMessagingService',
        tag: 'ChatService',
      );
    }
    // Real messaging handled by EmergencyMessagingService and SARMessagingService
    // This is a compatibility stub only
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if connected (always returns false for stub)
  bool get isConnected => false;

  /// Dispose service (stub)
  void dispose() {
    _isInitialized = false;
  }
}
