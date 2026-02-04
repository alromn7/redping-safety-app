import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_message.dart';
import '../models/messaging/message_packet.dart' as msg;
import '../models/sar_identity.dart';
import 'emergency_messaging_service.dart';
import 'sar_identity_service.dart';
import 'messaging_initializer.dart';

/// Service for SAR members to communicate directly with SOS users
class SARMessagingService {
  static final SARMessagingService _instance = SARMessagingService._internal();
  factory SARMessagingService() => _instance;
  SARMessagingService._internal();

  final EmergencyMessagingService _emergencyMessagingService =
      EmergencyMessagingService();
  final MessagingInitializer _messaging = MessagingInitializer();

  // SAR member identification
  String? _sarMemberId;
  String? _sarMemberName;
  SARMemberType? _sarMemberType;

  // Active conversations with SOS users
  final Map<String, List<EmergencyMessage>> _conversations = {};
  final StreamController<Map<String, List<EmergencyMessage>>>
  _conversationsController = StreamController.broadcast();

  // Message streams
  final StreamController<EmergencyMessage> _messageReceivedController =
      StreamController.broadcast();
  final StreamController<EmergencyMessage> _messageSentController =
      StreamController.broadcast();

  // Track processed messages to prevent infinite loops
  final Set<String> _processedMessageIds = {};

  bool _isInitialized = false;
  Timer? _syncTimer;

  // Getters
  Stream<Map<String, List<EmergencyMessage>>> get conversationsStream =>
      _conversationsController.stream;
  Stream<EmergencyMessage> get messageReceivedStream =>
      _messageReceivedController.stream;
  Stream<EmergencyMessage> get messageSentStream =>
      _messageSentController.stream;
  Map<String, List<EmergencyMessage>> get conversations =>
      Map.unmodifiable(_conversations);
  bool get isInitialized => _isInitialized;
  String? get sarMemberId => _sarMemberId;
  String? get sarMemberName => _sarMemberName;

  /// Initialize SAR messaging service with default values for testing
  Future<void> initializeForTesting() async {
    try {
      // Get SAR identity if available
      final sarIdentityService = SARIdentityService();
      await sarIdentityService.initialize();

      if (sarIdentityService.isCurrentUserVerified &&
          sarIdentityService.currentUserIdentity != null) {
        final identity = sarIdentityService.currentUserIdentity!;
        await initialize(
          sarMemberId: identity.id,
          sarMemberName: identity.personalInfo.fullName,
          sarMemberType: identity.memberType,
        );
      } else {
        // Use default values for testing
        await initialize(
          sarMemberId:
              'sar_test_member_${DateTime.now().millisecondsSinceEpoch}',
          sarMemberName: 'SAR Test Member',
          sarMemberType: SARMemberType.professional,
        );
      }
    } catch (e) {
      debugPrint('SARMessagingService: Error in testing initialization - $e');
      // Fallback to default values
      await initialize(
        sarMemberId: 'sar_test_member_${DateTime.now().millisecondsSinceEpoch}',
        sarMemberName: 'SAR Test Member',
        sarMemberType: SARMemberType.professional,
      );
    }
  }

  /// Initialize SAR messaging service
  Future<void> initialize({
    required String sarMemberId,
    required String sarMemberName,
    required SARMemberType sarMemberType,
  }) async {
    if (_isInitialized) return;

    try {
      _sarMemberId = sarMemberId;
      _sarMemberName = sarMemberName;
      _sarMemberType = sarMemberType;

      // Initialize emergency messaging service
      await _emergencyMessagingService.initialize();

      // Initialize new messaging system
      await _messaging.initialize();

      // Set up message listeners with proper deduplication (INFINITE LOOP FIX)
      _messaging.engine.receivedStream.listen((packet) {
        _handleReceivedPacket(packet);
      });

      // Load existing conversations
      await _loadConversations();

      // Setup demo messages
      _setupDemoMessages();

      // Start periodic sync
      _startPeriodicSync();

      _isInitialized = true;
      debugPrint(
        'SARMessagingService: Initialized for SAR member $_sarMemberName',
      );
    } catch (e) {
      debugPrint('SARMessagingService: Initialization error - $e');
      throw Exception('Failed to initialize SAR messaging service: $e');
    }
  }

  /// Setup demo messages without infinite loops
  void _setupDemoMessages() {
    // Add a few demo conversations for testing
    debugPrint('SARMessagingService: Setting up demo messages (static)');
    // Demo messages will be added through other methods as needed
  }

  /// Send direct message to SOS user
  Future<void> sendMessageToSOSUser({
    required String sosUserId,
    required String sosUserName,
    required String content,
    MessagePriority priority = MessagePriority.medium,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      throw Exception('SAR messaging service not initialized');
    }

    try {
      // Create message
      final message = EmergencyMessage(
        id: _generateMessageId(),
        senderId: _sarMemberId!,
        senderName: _sarMemberName!,
        content: content,
        recipients: [sosUserId],
        timestamp: DateTime.now(),
        priority: priority,
        type: MessageType.sarResponse,
        status: MessageStatus.pending,
        isRead: false,
        metadata: {
          'sarMemberType': _sarMemberType?.name,
          'sarMemberId': _sarMemberId,
          'messageType': 'sar_direct_message',
          ...?metadata,
        },
      );

      // Send via new MessageEngine (with deduplication)
      debugPrint(
        'SARMessagingService: Sending message via new messaging system',
      );

      final conversationId =
          'sar_to_sos_${sosUserId}_${DateTime.now().millisecondsSinceEpoch}';

      await _messaging.engine.sendMessage(
        conversationId: conversationId,
        content: message.content,
        type: msg.MessageType.text,
        priority: _convertPriority(message.priority),
        recipients: [sosUserId],
        metadata: {
          'senderName': _sarMemberName!,
          'sarMemberId': _sarMemberId,
          'sarMemberType': _sarMemberType?.name,
          ...message.metadata,
        },
      );

      debugPrint(
        'SARMessagingService: Message successfully sent via new system',
      );

      // Add to local conversation
      _addToConversation(sosUserId, message);

      // Notify listeners
      _messageSentController.add(message);

      debugPrint('SARMessagingService: Message sent to $sosUserName');
    } catch (e) {
      debugPrint('SARMessagingService: Error sending message - $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send status update to SOS user
  Future<void> sendStatusUpdate({
    required String sosUserId,
    required String sosUserName,
    required String status,
    String? additionalInfo,
  }) async {
    final content =
        'SAR Status Update: $status${additionalInfo != null ? '\n\n$additionalInfo' : ''}';

    await sendMessageToSOSUser(
      sosUserId: sosUserId,
      sosUserName: sosUserName,
      content: content,
      priority: MessagePriority.high,
      metadata: {
        'updateType': 'status',
        'status': status,
        'additionalInfo': additionalInfo,
      },
    );
  }

  /// Send location update to SOS user
  Future<void> sendLocationUpdate({
    required String sosUserId,
    required String sosUserName,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    final content =
        'SAR Team Location Update:\n'
        'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}\n'
        '${description ?? 'SAR team is en route to your location.'}';

    await sendMessageToSOSUser(
      sosUserId: sosUserId,
      sosUserName: sosUserName,
      content: content,
      priority: MessagePriority.high,
      metadata: {
        'updateType': 'location',
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      },
    );
  }

  /// Send ETA update to SOS user
  Future<void> sendETAUpdate({
    required String sosUserId,
    required String sosUserName,
    required Duration eta,
    String? additionalInfo,
  }) async {
    final etaMinutes = eta.inMinutes;
    final content =
        'SAR Team ETA Update:\n'
        'Estimated arrival: ${etaMinutes > 60 ? '${etaMinutes ~/ 60}h ${etaMinutes % 60}m' : '${etaMinutes}m'}\n'
        '${additionalInfo ?? 'Please remain at your current location if safe to do so.'}';

    await sendMessageToSOSUser(
      sosUserId: sosUserId,
      sosUserName: sosUserName,
      content: content,
      priority: MessagePriority.medium,
      metadata: {
        'updateType': 'eta',
        'etaMinutes': etaMinutes,
        'additionalInfo': additionalInfo,
      },
    );
  }

  /// Send medical advice to SOS user
  Future<void> sendMedicalAdvice({
    required String sosUserId,
    required String sosUserName,
    required String advice,
    MessagePriority priority = MessagePriority.high,
  }) async {
    final content = 'Medical Advice from SAR Team:\n\n$advice';

    await sendMessageToSOSUser(
      sosUserId: sosUserId,
      sosUserName: sosUserName,
      content: content,
      priority: priority,
      metadata: {'updateType': 'medical_advice', 'advice': advice},
    );
  }

  /// Send rescue instructions to SOS user
  Future<void> sendRescueInstructions({
    required String sosUserId,
    required String sosUserName,
    required String instructions,
  }) async {
    final content = 'Rescue Instructions:\n\n$instructions';

    await sendMessageToSOSUser(
      sosUserId: sosUserId,
      sosUserName: sosUserName,
      content: content,
      priority: MessagePriority.critical,
      metadata: {
        'updateType': 'rescue_instructions',
        'instructions': instructions,
      },
    );
  }

  /// Get conversation with specific SOS user
  List<EmergencyMessage> getConversation(String sosUserId) {
    return _conversations[sosUserId] ?? [];
  }

  /// Get unread message count for specific conversation
  int getUnreadCount(String sosUserId) {
    final messages = _conversations[sosUserId] ?? [];
    return messages
        .where((msg) => !msg.isRead && msg.senderId != _sarMemberId)
        .length;
  }

  /// Mark messages as read
  Future<void> markAsRead(String sosUserId, List<String> messageIds) async {
    final messages = _conversations[sosUserId];
    if (messages == null) return;

    for (final message in messages) {
      if (messageIds.contains(message.id) && !message.isRead) {
        final updatedMessage = message.copyWith(isRead: true);
        final index = messages.indexOf(message);
        messages[index] = updatedMessage;
      }
    }

    _conversationsController.add(Map.unmodifiable(_conversations));
    await _saveConversations();
  }

  /// Add message to conversation
  void _addToConversation(String userId, EmergencyMessage message) {
    if (!_conversations.containsKey(userId)) {
      _conversations[userId] = [];
    }

    _conversations[userId]!.add(message);

    // Sort by timestamp
    _conversations[userId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _conversationsController.add(Map.unmodifiable(_conversations));
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncMessages();
      // Clean up old processed message IDs to prevent memory leaks
      _cleanupProcessedMessages();
    });
  }

  /// Clean up old processed message IDs to prevent memory growth
  void _cleanupProcessedMessages() {
    // Keep only the most recent 1000 message IDs to prevent memory leaks
    if (_processedMessageIds.length > 1000) {
      // Convert to list, sort, and keep only the last 500
      final messageIdsList = _processedMessageIds.toList()
        ..sort(); // Sort to get consistent ordering
      _processedMessageIds.clear();
      _processedMessageIds.addAll(
        messageIdsList.skip(messageIdsList.length - 500),
      );
      debugPrint(
        'SARMessagingService: Cleaned up processed message IDs, now ${_processedMessageIds.length} items',
      );
    }
  }

  /// Sync messages with emergency messaging service
  Future<void> _syncMessages() async {
    try {
      // TODO: Implement message sync
      // await _emergencyMessagingService.syncMessages();
    } catch (e) {
      debugPrint('SARMessagingService: Sync error - $e');
    }
  }

  /// Load conversations from storage
  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = prefs.getString(
        'sar_conversations_$_sarMemberId',
      );

      if (conversationsJson != null) {
        // TODO: Implement proper JSON deserialization
        // For now, conversations will be loaded from emergency messaging service
      }
    } catch (e) {
      debugPrint('SARMessagingService: Error loading conversations - $e');
    }
  }

  /// Save conversations to storage
  Future<void> _saveConversations() async {
    try {
      // TODO: Implement proper JSON serialization
      // For now, conversations are managed in memory
    } catch (e) {
      debugPrint('SARMessagingService: Error saving conversations - $e');
    }
  }

  /// Generate unique message ID
  /// Receive a message from a SOS user (reply to SAR message)
  Future<void> receiveMessageFromSOSUser({
    required String sosUserId,
    required String sosUserName,
    required String content,
    required MessagePriority priority,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      debugPrint('SARMessagingService: Not initialized');
      return;
    }

    try {
      // Create the received message
      final receivedMessage = EmergencyMessage(
        id: 'sos_reply_${DateTime.now().millisecondsSinceEpoch}',
        senderId: sosUserId,
        senderName: sosUserName,
        content: content,
        recipients: [_sarMemberId ?? 'sar_member'],
        timestamp: DateTime.now(),
        priority: priority,
        type: MessageType.userResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {
          'sarMemberId': _sarMemberId,
          'sarMemberName': _sarMemberName,
          'isReply': true,
          ...?metadata,
        },
      );

      // Add to conversation
      _addToConversation(sosUserId, receivedMessage);

      // Notify listeners
      _messageReceivedController.add(receivedMessage);

      debugPrint('SARMessagingService: Message received from $sosUserName');
    } catch (e) {
      debugPrint('SARMessagingService: Error receiving message: $e');
    }
  }

  String _generateMessageId() {
    return 'sar_msg_${DateTime.now().millisecondsSinceEpoch}_$_sarMemberId';
  }

  // TEMPORARILY DISABLED to prevent infinite loops
  /*
  void _handleIncomingUserMessage(EmergencyMessage message) {
    try {
      debugPrint('SARMessagingService: Handling incoming user message');
      debugPrint('SARMessagingService: Message ID: ${message.id}');
      debugPrint('SARMessagingService: Sender ID: ${message.senderId}');
      debugPrint('SARMessagingService: Sender Name: ${message.senderName}');
      debugPrint('SARMessagingService: Content: ${message.content}');
      debugPrint('SARMessagingService: Type: ${message.type}');

      // Add to conversation
      final sosUserId = message.senderId;
      _addToConversation(sosUserId, message);

      // Notify listeners
      _messageReceivedController.add(message);

      debugPrint('SARMessagingService: Message received from user $sosUserId');
    } catch (e) {
      debugPrint(
        'SARMessagingService: Error handling incoming user message: $e',
      );
    }
  }
  */

  /// Handle received message packet from new messaging system
  Future<void> _handleReceivedPacket(msg.MessagePacket packet) async {
    try {
      // Skip messages from this SAR member (avoid self-messages)
      if (packet.senderId == _sarMemberId) {
        debugPrint('SARMessagingService: Skipping own message');
        return;
      }

      // Get conversation key to decrypt
      final conversationKey = await _messaging.crypto.getConversationKey(
        packet.conversationId,
      );
      if (conversationKey == null) {
        debugPrint(
          'SARMessagingService: No conversation key for ${packet.conversationId}',
        );
        return;
      }

      // Decrypt the content
      final content = await _messaging.crypto.decryptMessage(
        packet.encryptedPayload,
        conversationKey,
      );

      // Get sender name from metadata
      final senderName = packet.metadata['senderName'] as String? ?? 'SOS User';

      // Convert to EmergencyMessage for compatibility
      final message = EmergencyMessage(
        id: packet.messageId,
        senderId: packet.senderId,
        senderName: senderName,
        content: content,
        recipients: [_sarMemberId!],
        timestamp: DateTime.fromMillisecondsSinceEpoch(packet.timestamp),
        priority: _convertPriorityFromString(packet.priority),
        type: _convertTypeFromString(packet.type),
        status: MessageStatus.sent,
        isRead: false,
        metadata: packet.metadata,
      );

      // Add to conversation
      _addToConversation(packet.senderId, message);

      // Notify listeners
      _messageReceivedController.add(message);

      debugPrint(
        'SARMessagingService: Message received via new system - ${message.id}',
      );
    } catch (e) {
      debugPrint('SARMessagingService: Error handling received packet - $e');
    }
  }

  /// Convert legacy MessagePriority to new MessagePriority
  msg.MessagePriority _convertPriority(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.low:
      case MessagePriority.medium:
        return msg.MessagePriority.normal;
      case MessagePriority.high:
        return msg.MessagePriority.high;
      case MessagePriority.critical:
        return msg.MessagePriority.emergency;
    }
  }

  /// Convert priority string to legacy MessagePriority
  MessagePriority _convertPriorityFromString(String priority) {
    switch (priority) {
      case 'emergency':
        return MessagePriority.critical;
      case 'high':
        return MessagePriority.high;
      case 'normal':
        return MessagePriority.medium;
      default:
        return MessagePriority.medium;
    }
  }

  /// Convert type string to legacy MessageType
  MessageType _convertTypeFromString(String type) {
    switch (type) {
      case 'text':
        return MessageType.general;
      case 'sos':
        return MessageType.emergency;
      case 'location':
        return MessageType.status;
      case 'system':
        return MessageType.response;
      default:
        return MessageType.userResponse;
    }
  }

  /// Dispose service
  void dispose() {
    _syncTimer?.cancel();
    _conversationsController.close();
    _messageReceivedController.close();
    _messageSentController.close();
    _isInitialized = false;
  }
}
