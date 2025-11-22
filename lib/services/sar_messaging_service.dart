import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_message.dart';
import '../models/sar_identity.dart';
import 'emergency_messaging_service.dart';
import 'sar_identity_service.dart';

/// Service for SAR members to communicate directly with SOS users
class SARMessagingService {
  static final SARMessagingService _instance = SARMessagingService._internal();
  factory SARMessagingService() => _instance;
  SARMessagingService._internal();

  final EmergencyMessagingService _emergencyMessagingService =
      EmergencyMessagingService();

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

      // Load existing conversations
      await _loadConversations();

      // Set up message listeners - TEMPORARILY DISABLED to prevent crashes
      // TODO: Fix the infinite message loop issue properly
      /*
      _emergencyMessagingService.messagesStream.listen((messages) {
        debugPrint(
          'SARMessagingService: Received ${messages.length} messages from emergency messaging service',
        );

        // Process messages from emergency messaging service
        for (final message in messages) {
          // Skip already processed messages to prevent infinite loops
          if (_processedMessageIds.contains(message.id)) {
            continue;
          }
          
          debugPrint(
            'SARMessagingService: Processing message from ${message.senderId} (type: ${message.type})',
          );

          // Accept messages from users that are not from this SAR member
          if (message.senderId != _sarMemberId &&
              (message.type == MessageType.userResponse ||
                  message.type == MessageType.emergency ||
                  message.type == MessageType.response)) {
            debugPrint(
              'SARMessagingService: Message qualifies for SAR processing',
            );
            _processedMessageIds.add(message.id); // Mark as processed
            _handleIncomingUserMessage(message);
          } else {
            debugPrint(
              'SARMessagingService: Message filtered out - senderId: ${message.senderId}, sarMemberId: $_sarMemberId, type: ${message.type}',
            );
            _processedMessageIds.add(message.id); // Mark as processed even if filtered
          }
        }
      });
      */

      // Simple demo message setup instead
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

      // Send via emergency messaging service
      debugPrint(
        'SARMessagingService: Sending message to emergency messaging service',
      );
      await _emergencyMessagingService.receiveMessageFromSAR(
        senderId: _sarMemberId!,
        senderName: _sarMemberName!,
        content: message.content,
        priority: message.priority,
        type: message.type,
        metadata: message.metadata,
      );

      debugPrint(
        'SARMessagingService: Message successfully sent to emergency messaging service',
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

  /// Dispose service
  void dispose() {
    _syncTimer?.cancel();
    _conversationsController.close();
    _messageReceivedController.close();
    _messageSentController.close();
    _isInitialized = false;
  }
}
