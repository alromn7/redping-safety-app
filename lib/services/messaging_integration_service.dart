import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emergency_message.dart';
import 'emergency_messaging_service.dart';
import 'sar_messaging_service.dart';
import 'sos_ping_service.dart';

/// Service that integrates all messaging systems for seamless communication
/// between REDP!NG help, SOS, and SAR members
class MessagingIntegrationService {
  static final MessagingIntegrationService _instance =
      MessagingIntegrationService._internal();
  factory MessagingIntegrationService() => _instance;
  MessagingIntegrationService._internal();

  final EmergencyMessagingService _emergencyMessagingService =
      EmergencyMessagingService();
  final SARMessagingService _sarMessagingService = SARMessagingService();
  final SOSPingService _sosPingService = SOSPingService();

  bool _isInitialized = false;
  final StreamController<EmergencyMessage> _messageStreamController =
      StreamController.broadcast();

  // Streams
  Stream<EmergencyMessage> get messageStream => _messageStreamController.stream;

  /// Initialize the messaging integration service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize all messaging services
      await _emergencyMessagingService.initialize();
      await _sarMessagingService.initializeForTesting();
      await _sosPingService.initialize();

      // Set up message routing between services
      _setupMessageRouting();

      _isInitialized = true;
      debugPrint('MessagingIntegrationService: Initialized successfully');
    } catch (e) {
      debugPrint('MessagingIntegrationService: Initialization error - $e');
      throw Exception('Failed to initialize messaging integration service: $e');
    }
  }

  /// Set up message routing between all messaging services
  /// INFINITE LOOP FIX: MessageEngine now handles all routing with global deduplication
  void _setupMessageRouting() {
    // Route messages from both services to unified stream
    // The underlying MessageEngine ensures no infinite loops via deduplication

    _emergencyMessagingService.messagesStream.listen((messages) {
      for (final message in messages) {
        _messageStreamController.add(message);
      }
    });

    _sarMessagingService.messageReceivedStream.listen((message) {
      _messageStreamController.add(message);
    });

    _sarMessagingService.messageSentStream.listen((message) {
      _messageStreamController.add(message);
    });

    debugPrint(
      'MessagingIntegrationService: Message routing enabled with deduplication',
    );
  }

  /// Send message from REDP!NG help user to SAR
  Future<void> sendREDPINGHelpMessage({
    required String pingId,
    required String content,
    MessagePriority priority = MessagePriority.medium,
  }) async {
    if (!_isInitialized) {
      throw Exception('Messaging integration service not initialized');
    }

    try {
      // Get the ping to find assigned SAR members
      final ping = _sosPingService.getActivePings().firstWhere(
        (p) => p.id == pingId,
        orElse: () => throw Exception('Ping not found'),
      );

      // Create message
      final message = EmergencyMessage(
        id: _generateMessageId(),
        senderId: ping.userId,
        senderName: ping.userName ?? 'SOS User',
        content: content,
        recipients: ping.assignedSARMembers,
        timestamp: DateTime.now(),
        priority: priority,
        type: MessageType.userResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {
          'pingId': pingId,
          'messageSource': 'redping_help',
          'helpCategory': ping.metadata['helpCategory'],
        },
      );

      // Send via emergency messaging service
      await _emergencyMessagingService.receiveMessageFromSAR(
        senderId: ping.userId,
        senderName: ping.userName ?? 'SOS User',
        content: content,
        priority: priority,
        type: MessageType.userResponse,
        metadata: message.metadata,
      );

      // Route to SAR messaging service
      await _sarMessagingService.receiveMessageFromSOSUser(
        sosUserId: ping.userId,
        sosUserName: ping.userName ?? 'SOS User',
        content: content,
        priority: priority,
        metadata: message.metadata,
      );

      _messageStreamController.add(message);
      debugPrint('MessagingIntegrationService: REDP!NG help message sent');
    } catch (e) {
      debugPrint(
        'MessagingIntegrationService: Error sending REDP!NG help message - $e',
      );
      throw Exception('Failed to send REDP!NG help message: $e');
    }
  }

  /// Send message from SAR to REDP!NG help user
  Future<void> sendSARResponseToREDPINGHelp({
    required String pingId,
    required String content,
    MessagePriority priority = MessagePriority.high,
  }) async {
    if (!_isInitialized) {
      throw Exception('Messaging integration service not initialized');
    }

    try {
      // Get the ping
      final ping = _sosPingService.getActivePings().firstWhere(
        (p) => p.id == pingId,
        orElse: () => throw Exception('Ping not found'),
      );

      // Send via SAR messaging service
      await _sarMessagingService.sendMessageToSOSUser(
        sosUserId: ping.userId,
        sosUserName: ping.userName ?? 'SOS User',
        content: content,
        priority: priority,
        metadata: {
          'pingId': pingId,
          'messageSource': 'sar_response',
          'helpCategory': ping.metadata['helpCategory'],
        },
      );

      // Route to emergency messaging service
      await _emergencyMessagingService.receiveMessageFromSAR(
        senderId: _sarMessagingService.sarMemberId ?? 'sar_member',
        senderName: _sarMessagingService.sarMemberName ?? 'SAR Team',
        content: content,
        priority: priority,
        type: MessageType.sarResponse,
        metadata: {
          'pingId': pingId,
          'messageSource': 'sar_response',
          'helpCategory': ping.metadata['helpCategory'],
        },
      );

      debugPrint(
        'MessagingIntegrationService: SAR response sent to REDP!NG help user',
      );
    } catch (e) {
      debugPrint(
        'MessagingIntegrationService: Error sending SAR response - $e',
      );
      throw Exception('Failed to send SAR response: $e');
    }
  }

  /// Send message from SOS user to SAR
  Future<void> sendSOSMessageToSAR({
    required String pingId,
    required String content,
    MessagePriority priority = MessagePriority.critical,
  }) async {
    if (!_isInitialized) {
      throw Exception('Messaging integration service not initialized');
    }

    try {
      // Use the SOS ping service to send message
      await _sosPingService.sendMessageToSAR(
        pingId: pingId,
        content: content,
        type: MessageType.emergency,
      );

      debugPrint('MessagingIntegrationService: SOS message sent to SAR');
    } catch (e) {
      debugPrint('MessagingIntegrationService: Error sending SOS message - $e');
      throw Exception('Failed to send SOS message: $e');
    }
  }

  /// Send message from SAR to SOS user
  Future<void> sendSARResponseToSOS({
    required String pingId,
    required String content,
    MessagePriority priority = MessagePriority.high,
  }) async {
    if (!_isInitialized) {
      throw Exception('Messaging integration service not initialized');
    }

    try {
      // Use the SOS ping service to send message
      await _sosPingService.sendMessageToCivilian(
        pingId: pingId,
        content: content,
        type: MessageType.sarResponse,
      );

      debugPrint('MessagingIntegrationService: SAR response sent to SOS user');
    } catch (e) {
      debugPrint(
        'MessagingIntegrationService: Error sending SAR response to SOS - $e',
      );
      throw Exception('Failed to send SAR response to SOS: $e');
    }
  }

  /// Get all messages for a specific ping
  List<EmergencyMessage> getMessagesForPing(String pingId) {
    return _sosPingService.getMessagesForPing(pingId);
  }

  /// Get conversation between user and SAR for a specific ping
  List<EmergencyMessage> getConversationForPing(String pingId) {
    final messages = getMessagesForPing(pingId);
    // Sort by timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// Mark messages as read for a specific ping
  Future<void> markMessagesAsRead(String pingId, String userId) async {
    await _sosPingService.markMessagesAsRead(pingId, userId);
  }

  /// Get unread message count for a specific ping
  int getUnreadMessageCount(String pingId, String userId) {
    final messages = getMessagesForPing(pingId);
    return messages
        .where(
          (msg) =>
              !msg.isRead &&
              (msg.senderId != userId || msg.recipients.contains(userId)),
        )
        .length;
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Get current state
  bool get isInitialized => _isInitialized;

  /// Create a REDP!NG help ping and send initial message to SAR
  Future<String> createREDPINGHelpRequest({
    required String helpCategory,
    String? userMessage,
  }) async {
    if (!_isInitialized) {
      throw Exception('Messaging integration service not initialized');
    }

    try {
      // Create the help ping using SOSPingService
      final ping = await _sosPingService.createHelpPing(
        category: helpCategory,
        userMessage: userMessage,
      );

      // Send initial help message to SAR via messaging integration
      await sendREDPINGHelpMessage(
        pingId: ping.id,
        content: userMessage ?? 'REDP!NG Help request for $helpCategory',
        priority: _mapPriorityFromSOSPriority(ping.priority),
      );

      debugPrint(
        'MessagingIntegrationService: REDP!NG help request created - ${ping.id}',
      );
      return ping.id;
    } catch (e) {
      debugPrint(
        'MessagingIntegrationService: Error creating REDP!NG help request - $e',
      );
      rethrow;
    }
  }

  /// Map SOSPriority to MessagePriority
  MessagePriority _mapPriorityFromSOSPriority(dynamic sosPriority) {
    // Handle both enum and string cases
    final priorityString = sosPriority.toString().split('.').last.toLowerCase();
    switch (priorityString) {
      case 'low':
        return MessagePriority.low;
      case 'medium':
        return MessagePriority.medium;
      case 'high':
        return MessagePriority.high;
      case 'critical':
        return MessagePriority.critical;
      default:
        return MessagePriority.medium;
    }
  }

  void dispose() {
    _messageStreamController.close();
    _isInitialized = false;
  }
}
