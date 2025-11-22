import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../models/sos_session.dart' as sos;
import 'location_service.dart';
import 'notification_service.dart';
import 'user_profile_service.dart';
import 'sar_identity_service.dart';
import '../models/sar_identity.dart';
import '../core/logging/app_logger.dart';

/// Service for managing chat, messaging, and community communication
class ChatService {
  /// Generate a clean SOS chat message for emergency alerts
  String _generateSOSChatMessageClean(
    sos.SOSSession session,
    String userMessage,
  ) {
    final location = session.location;
    final buffer = StringBuffer();
    buffer.writeln('🚨 EMERGENCY ALERT');
    buffer.writeln('User: ${session.userId}');
    buffer.writeln('Location: ${location.latitude}, ${location.longitude}');
    buffer.writeln('Accuracy: ${location.accuracy} m');
    if (userMessage.isNotEmpty) {
      buffer.writeln('Message: $userMessage');
    }
    buffer.writeln('Reference: ${session.id}');
    return buffer.toString();
  }

  // Private fields
  List<ChatRoom> _chatRooms = [];
  Map<String, List<ChatMessage>> _chatMessages = {};
  List<ChatUser> _nearbyUsers = [];
  ChatUser? _currentUser;

  // Connection state
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isEnabled = true;

  // Timers
  Timer? _heartbeatTimer;
  Timer? _nearbyUsersTimer;
  Timer? _messageCleanupTimer;

  // Callbacks
  Function(ChatMessage)? _onMessageReceived;
  Function(ChatRoom)? _onChatRoomUpdated;
  Function(List<ChatUser>)? _onNearbyUsersUpdated;
  Function(bool)? _onConnectionStatusChanged;

  Future<void> discoverNearbyUsers() async {
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) return;

      final mockNearbyUsers = await _generateMockNearbyUsers(currentLocation);

      _nearbyUsers = mockNearbyUsers;
      _onNearbyUsersUpdated?.call(_nearbyUsers);

      debugPrint('ChatService: Found ${_nearbyUsers.length} nearby users');
    } catch (e) {
      debugPrint('ChatService: Error discovering nearby users - $e');
    }
  }

  // Expose notification service for external use
  NotificationService get notificationService => _notificationService;
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final UserProfileService _userProfileService = UserProfileService();

  // Import SAR identity service for user type validation
  late final SARIdentityService _sarIdentityService;

  // WebSocket connection for real-time messaging
  WebSocketChannel? _webSocketChannel;
  StreamSubscription? _webSocketSubscription;

  // (Removed duplicate field declarations)

  /// Initialize chat service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await _locationService.initialize();
      await _notificationService.initialize();

      // Initialize SAR identity service for user type validation
      _sarIdentityService = SARIdentityService();
      await _sarIdentityService.initialize();

      // Load saved data
      await _loadSavedData();
      await _loadCurrentUser();

      // Connect to chat server
      await _connectToServer();

      // Start periodic tasks
      _startHeartbeat();
      _startNearbyUsersDiscovery();
      _startMessageCleanup();

      // Generate demo data
      await _generateDemoData();

      _isInitialized = true;
      debugPrint('ChatService: Initialized successfully');
    } catch (e) {
      debugPrint('ChatService: Initialization error - $e');
      throw Exception('Failed to initialize chat service: $e');
    }
  }

  /// Send a text message
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    MessagePriority priority = MessagePriority.normal,
    List<MessageAttachment>? attachments,
    String? replyToMessageId,
    sos.LocationInfo? location,
  }) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Validate cross messaging policies before sending
    await _validateCrossMessagingPolicy(chatId, type, priority);

    final message = ChatMessage(
      id: _generateMessageId(),
      chatId: chatId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      senderAvatar: _currentUser!.avatar,
      content: content,
      timestamp: DateTime.now(),
      type: type,
      priority: priority,
      attachments: attachments ?? [],
      replyToMessageId: replyToMessageId,
      location: location,
      isEncrypted: _shouldEncryptMessage(priority),
    );

    // Add to local storage
    _addMessageToChat(chatId, message);

    // Send via WebSocket
    await _sendMessageViaWebSocket(message);

    // Send push notification for high priority messages
    if (priority == MessagePriority.urgent ||
        priority == MessagePriority.emergency) {
      await _sendPriorityNotification(message);
    }

    // Update chat room last activity
    await _updateChatRoomActivity(chatId, message);

    _onMessageReceived?.call(message);
    debugPrint('ChatService: Message sent - ${message.id}');

    return message;
  }

  /// Send emergency SOS message with comprehensive user details
  Future<void> sendSOSMessage({
    required sos.SOSSession session,
    required String content,
    sos.LocationInfo? location,
  }) async {
    // Generate comprehensive emergency message with user details
    final detailedMessage = _generateSOSChatMessageClean(session, content);

    // Send to emergency chat room
    final emergencyChatId = await _getOrCreateEmergencyChatRoom();
    await sendMessage(
      chatId: emergencyChatId,
      content: detailedMessage,
      type: MessageType.emergency,
      priority: MessagePriority.emergency,
      location: location ?? session.location,
    );

    // Also send to SAR team if available
    final sarChatId = await _getOrCreateSARChatRoom();
    if (sarChatId != null) {
      await sendMessage(
        chatId: sarChatId,
        content: detailedMessage,
        type: MessageType.sosUpdate,
        priority: MessagePriority.emergency,
        location: location ?? session.location,
      );
    }

    // Send to community emergency channel for additional help
    await _sendCommunityEmergencyAlertClean(session, detailedMessage);
  }

  /// Clean implementation for community emergency alert with sanitized content
  Future<void> _sendCommunityEmergencyAlertClean(
    sos.SOSSession session,
    String message,
  ) async {
    try {
      final communityRoom = _chatRooms.firstWhere(
        (room) =>
            room.type == ChatType.community && room.tags.contains('emergency'),
        orElse: () => ChatRoom(
          id: '',
          name: '',
          type: ChatType.community,
          createdAt: DateTime.now(),
        ),
      );

      final chatId = communityRoom.id.isEmpty
          ? (await createChatRoom(
              name: 'Community Emergency',
              description: 'Community emergency response and assistance',
              type: ChatType.community,
              tags: ['emergency', 'community', 'response'],
            )).id
          : communityRoom.id;

      final alert =
          'COMMUNITY ALERT: Emergency assistance needed in your area.\n\n$message';
      await sendMessage(
        chatId: chatId,
        content: _sanitizeText(alert),
        type: MessageType.emergency,
        priority: MessagePriority.emergency,
        location: session.location,
      );

      AppLogger.i('ChatService: Community emergency alert sent');
    } catch (e) {
      AppLogger.w(
        'ChatService: Failed to send community emergency alert',
        tag: 'ChatService',
        error: e,
      );
    }
  }

  /// Send community emergency alert for additional help

  /// Get display name for SOS type

  /// Format date time for chat messages

  /// Create a new chat room
  Future<ChatRoom> createChatRoom({
    required String name,
    String? description,
    required ChatType type,
    List<String>? participants,
    sos.LocationInfo? location,
    double? radius,
    List<String>? tags,
  }) async {
    // Check if user has permission to create this type of chat room
    final canCreate = await _canCreateChatRoom(type);
    if (!canCreate) {
      throw Exception(
        'Permission denied. You do not have permission to create ${type.name} chat rooms. '
        'Contact a verified SAR member or administrator for assistance.',
      );
    }
    final chatRoom = ChatRoom(
      id: _generateChatId(),
      name: name,
      description: description,
      type: type,
      participants: participants ?? [],
      moderators: _currentUser != null ? [_currentUser!.id] : [],
      createdAt: DateTime.now(),
      location: location,
      radius: radius,
      tags: tags ?? [],
      isEncrypted: type == ChatType.emergency || type == ChatType.sarTeam,
    );

    _chatRooms.add(chatRoom);
    _chatMessages[chatRoom.id] = [];
    await _saveChatRooms();

    // Notify server about new chat room
    await _notifyServerNewChatRoom(chatRoom);

    _onChatRoomUpdated?.call(chatRoom);
    debugPrint('ChatService: Chat room created - ${chatRoom.name}');

    return chatRoom;
  }

  /// Join a chat room
  Future<void> joinChatRoom(String chatId) async {
    if (_currentUser == null) return;

    final roomIndex = _chatRooms.indexWhere((room) => room.id == chatId);
    if (roomIndex == -1) return;

    final room = _chatRooms[roomIndex];
    if (!room.participants.contains(_currentUser!.id)) {
      final updatedRoom = room.copyWith(
        participants: [...room.participants, _currentUser!.id],
      );

      _chatRooms[roomIndex] = updatedRoom;
      await _saveChatRooms();

      // Send join notification
      await sendMessage(
        chatId: chatId,
        content: '${_currentUser!.name} joined the chat',
        type: MessageType.system,
        priority: MessagePriority.low,
      );

      _onChatRoomUpdated?.call(updatedRoom);
    }
  }

  /// Leave a chat room
  Future<void> leaveChatRoom(String chatId) async {
    if (_currentUser == null) return;

    final roomIndex = _chatRooms.indexWhere((room) => room.id == chatId);
    if (roomIndex == -1) return;

    final room = _chatRooms[roomIndex];
    final updatedParticipants = room.participants
        .where((id) => id != _currentUser!.id)
        .toList();

    final updatedRoom = room.copyWith(participants: updatedParticipants);
    _chatRooms[roomIndex] = updatedRoom;
    await _saveChatRooms();

    // Send leave notification
    await sendMessage(
      chatId: chatId,
      content: '${_currentUser!.name} left the chat',
      type: MessageType.system,
      priority: MessagePriority.low,
    );

    _onChatRoomUpdated?.call(updatedRoom);
  }

  /// Get messages for a chat room
  List<ChatMessage> getMessagesForChat(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final messages = _chatMessages[chatId] ?? [];
    final unreadMessages = messages.where(
      (m) => !m.isRead && m.senderId != _currentUser?.id,
    );

    for (final message in unreadMessages) {
      final updatedMessage = message.copyWith(
        isRead: true,
        readByUsers: [
          ...message.readByUsers,
          _currentUser?.id ?? 'current_user',
        ],
      );

      final messageIndex = messages.indexOf(message);
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
      }
    }

    // Update chat room unread count
    final roomIndex = _chatRooms.indexWhere((room) => room.id == chatId);
    if (roomIndex != -1) {
      final room = _chatRooms[roomIndex];
      final updatedRoom = room.copyWith(unreadCount: 0);
      _chatRooms[roomIndex] = updatedRoom;
      _onChatRoomUpdated?.call(updatedRoom);
    }

    await _saveChatMessages();
    await _saveChatRooms();
  }

  /// Connect to chat server via WebSocket
  Future<void> _connectToServer() async {
    try {
      // For demo, we'll simulate connection
      _isConnected = true;
      _onConnectionStatusChanged?.call(_isConnected);

      debugPrint('ChatService: Connected to chat server');

      // Production mode - only real Firebase messages
    } catch (e) {
      debugPrint('ChatService: Failed to connect to server - $e');
      _isConnected = false;
      _onConnectionStatusChanged?.call(_isConnected);
    }
  }

  /// Send message via WebSocket
  Future<void> _sendMessageViaWebSocket(ChatMessage message) async {
    if (!_isConnected) {
      // Queue message for later delivery
      await _queueMessageForDelivery(message);
      return;
    }

    try {
      // For demo, mark as delivered immediately
      final deliveredMessage = message.copyWith(isDelivered: true);
      _updateMessageInChat(message.chatId, message.id, deliveredMessage);

      debugPrint('ChatService: Message sent via WebSocket - ${message.id}');
    } catch (e) {
      debugPrint('ChatService: Failed to send message - $e');
      await _queueMessageForDelivery(message);
    }
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    // Reduce background load: send heartbeat less frequently in dev
    const interval = Duration(minutes: 5);
    _heartbeatTimer = Timer.periodic(interval, (timer) async {
      if (_isConnected) {
        // Send heartbeat
        await _sendHeartbeat();
      } else {
        // Try to reconnect
        await _connectToServer();
      }
    });
  }

  /// Start nearby users discovery
  void _startNearbyUsersDiscovery() {
    _nearbyUsersTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      if (_isEnabled) {
        await discoverNearbyUsers();
      }
    });
  }

  /// Start message cleanup
  void _startMessageCleanup() {
    _messageCleanupTimer = Timer.periodic(const Duration(hours: 1), (
      timer,
    ) async {
      await _cleanupOldMessages();
    });
  }

  /// Generate demo data
  Future<void> _generateDemoData() async {
    if (_chatRooms.isNotEmpty) return;

    // Create demo chat rooms
    final demoRooms = [
      ChatRoom(
        id: 'COMMUNITY_001',
        name: 'Local Community',
        description: 'General community chat for your area',
        type: ChatType.community,
        participants: ['user1', 'user2', 'user3', 'current_user'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
        unreadCount: 3,
        tags: ['community', 'local'],
      ),
      ChatRoom(
        id: 'EMERGENCY_001',
        name: 'Emergency Coordination',
        description: 'Emergency response coordination',
        type: ChatType.emergency,
        participants: ['sar_team_1', 'sar_team_2', 'current_user'],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 1,
        isEncrypted: true,
        tags: ['emergency', 'coordination'],
      ),
      ChatRoom(
        id: 'SAR_TEAM_001',
        name: 'SAR Team Alpha',
        description: 'Search and rescue team coordination',
        type: ChatType.sarTeam,
        participants: ['sar_lead', 'sar_medic', 'sar_tech', 'current_user'],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 2)),
        unreadCount: 0,
        isEncrypted: true,
        tags: ['sar', 'team', 'alpha'],
      ),
    ];

    _chatRooms.addAll(demoRooms);

    // Create demo messages
    await _generateDemoMessages();

    await _saveChatRooms();
    await _saveChatMessages();
  }

  /// Generate demo messages
  Future<void> _generateDemoMessages() async {
    final now = DateTime.now();

    // Community chat messages
    _chatMessages['COMMUNITY_001'] = [
      ChatMessage(
        id: 'MSG_001',
        chatId: 'COMMUNITY_001',
        senderId: 'user1',
        senderName: 'Alex Rodriguez',
        content:
            'Hey everyone! Beautiful weather for hiking today. Anyone else hitting the trails?',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: MessageType.text,
        priority: MessagePriority.normal,
        isDelivered: true,
        isRead: true,
      ),
      ChatMessage(
        id: 'MSG_002',
        chatId: 'COMMUNITY_001',
        senderId: 'user2',
        senderName: 'Maria Santos',
        content:
            'Just finished the Eagle Peak trail. Watch out for loose rocks near the summit!',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        type: MessageType.text,
        priority: MessagePriority.normal,
        isDelivered: true,
        isRead: true,
      ),
      ChatMessage(
        id: 'MSG_003',
        chatId: 'COMMUNITY_001',
        senderId: 'user3',
        senderName: 'David Kim',
        content:
            'Weather alert: Storm clouds building to the west. Might want to head back soon.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: MessageType.text,
        priority: MessagePriority.high,
        isDelivered: true,
        isRead: false,
      ),
    ];

    // Emergency chat messages
    _chatMessages['EMERGENCY_001'] = [
      ChatMessage(
        id: 'MSG_E001',
        chatId: 'EMERGENCY_001',
        senderId: 'sar_team_1',
        senderName: 'SAR Team Leader',
        content:
            'Emergency response activated. Missing hiker reported at Eagle Peak trail.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: MessageType.emergency,
        priority: MessagePriority.emergency,
        isDelivered: true,
        isRead: true,
        isEncrypted: true,
      ),
      ChatMessage(
        id: 'MSG_E002',
        chatId: 'EMERGENCY_001',
        senderId: 'sar_team_2',
        senderName: 'SAR Medic',
        content: 'Medical team standing by. ETA to base camp: 15 minutes.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        type: MessageType.emergency,
        priority: MessagePriority.urgent,
        isDelivered: true,
        isRead: false,
        isEncrypted: true,
      ),
    ];

    // SAR team messages
    _chatMessages['SAR_TEAM_001'] = [
      ChatMessage(
        id: 'MSG_S001',
        chatId: 'SAR_TEAM_001',
        senderId: 'sar_lead',
        senderName: 'Team Leader',
        content:
            'Team Alpha, prepare for deployment. Missing person last seen at coordinates 37.4219, -122.084.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: MessageType.text,
        priority: MessagePriority.urgent,
        isDelivered: true,
        isRead: true,
        isEncrypted: true,
      ),
      ChatMessage(
        id: 'MSG_S002',
        chatId: 'SAR_TEAM_001',
        senderId: 'sar_tech',
        senderName: 'Tech Specialist',
        content:
            'Drone deployed. Thermal imaging active. Scanning grid pattern.',
        timestamp: now.subtract(const Duration(minutes: 2)),
        type: MessageType.text,
        priority: MessagePriority.normal,
        isDelivered: true,
        isRead: false,
        isEncrypted: true,
      ),
    ];
  }

  /// Generate mock nearby users
  Future<List<ChatUser>> _generateMockNearbyUsers(
    sos.LocationInfo userLocation,
  ) async {
    final now = DateTime.now();

    final mockUsers = [
      ChatUser(
        id: 'nearby_1',
        name: 'Sarah Johnson',
        status: UserStatus.available,
        lastSeen: now.subtract(const Duration(minutes: 2)),
        isOnline: true,
        location: sos.LocationInfo(
          latitude: userLocation.latitude + 0.001,
          longitude: userLocation.longitude + 0.001,
          accuracy: 5.0,
          timestamp: now,
          address: 'Nearby Trail',
        ),
      ),
      ChatUser(
        id: 'nearby_2',
        name: 'Mike Chen',
        status: UserStatus.busy,
        lastSeen: now.subtract(const Duration(minutes: 5)),
        isOnline: true,
        isSARTeamMember: true,
        roles: ['sar_medic'],
        location: sos.LocationInfo(
          latitude: userLocation.latitude - 0.002,
          longitude: userLocation.longitude + 0.001,
          accuracy: 8.0,
          timestamp: now,
          address: 'Base Camp',
        ),
      ),
      ChatUser(
        id: 'nearby_3',
        name: 'Emily Davis',
        status: UserStatus.available,
        lastSeen: now.subtract(const Duration(minutes: 1)),
        isOnline: true,
        isEmergencyContact: true,
        location: sos.LocationInfo(
          latitude: userLocation.latitude + 0.003,
          longitude: userLocation.longitude - 0.002,
          accuracy: 12.0,
          timestamp: now,
          address: 'Parking Area',
        ),
      ),
    ];

    return mockUsers;
  }

  // Simulation methods REMOVED - production uses real Firebase messages only

  /// Add message to chat
  void _addMessageToChat(String chatId, ChatMessage message) {
    if (!_chatMessages.containsKey(chatId)) {
      _chatMessages[chatId] = [];
    }

    _chatMessages[chatId]!.add(message);

    // Keep only last 100 messages per chat
    if (_chatMessages[chatId]!.length > 100) {
      _chatMessages[chatId] = _chatMessages[chatId]!
          .skip(_chatMessages[chatId]!.length - 100)
          .toList();
    }
  }

  /// Update message in chat
  void _updateMessageInChat(
    String chatId,
    String messageId,
    ChatMessage updatedMessage,
  ) {
    final messages = _chatMessages[chatId];
    if (messages == null) return;

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      messages[messageIndex] = updatedMessage;
    }
  }

  /// Update chat room activity
  Future<void> _updateChatRoomActivity(
    String chatId,
    ChatMessage message,
  ) async {
    final roomIndex = _chatRooms.indexWhere((room) => room.id == chatId);
    if (roomIndex == -1) return;

    final room = _chatRooms[roomIndex];
    final updatedRoom = room.copyWith(
      lastActivity: message.timestamp,
      lastMessage: message,
      unreadCount: message.senderId != _currentUser?.id
          ? room.unreadCount + 1
          : room.unreadCount,
    );

    _chatRooms[roomIndex] = updatedRoom;
    _onChatRoomUpdated?.call(updatedRoom);
  }

  /// Get or create emergency chat room
  Future<String> _getOrCreateEmergencyChatRoom() async {
    var emergencyRoom = _chatRooms.firstWhere(
      (room) => room.type == ChatType.emergency,
      orElse: () => ChatRoom(
        id: '',
        name: '',
        type: ChatType.emergency,
        createdAt: DateTime.now(),
      ),
    );

    if (emergencyRoom.id.isEmpty) {
      emergencyRoom = await createChatRoom(
        name: 'Emergency Response',
        description: 'Emergency coordination and communication',
        type: ChatType.emergency,
        participants: ['emergency_dispatch', 'current_user'],
        tags: ['emergency', 'sos'],
      );
    }

    return emergencyRoom.id;
  }

  /// Get or create SAR chat room
  Future<String?> _getOrCreateSARChatRoom() async {
    final sarRoom = _chatRooms.firstWhere(
      (room) => room.type == ChatType.sarTeam,
      orElse: () => ChatRoom(
        id: '',
        name: '',
        type: ChatType.sarTeam,
        createdAt: DateTime.now(),
      ),
    );

    return sarRoom.id.isNotEmpty ? sarRoom.id : null;
  }

  /// Send heartbeat
  Future<void> _sendHeartbeat() async {
    try {
      // In production, send heartbeat to server
      AppLogger.d('ChatService: Heartbeat sent');
    } catch (e) {
      AppLogger.w(
        'ChatService: Heartbeat failed',
        tag: 'ChatService',
        error: e,
      );
      _isConnected = false;
      _onConnectionStatusChanged?.call(_isConnected);
    }
  }

  /// Queue message for later delivery
  Future<void> _queueMessageForDelivery(ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedMessages = prefs.getStringList('queued_messages') ?? [];
      queuedMessages.add(jsonEncode(message.toJson()));
      await prefs.setStringList('queued_messages', queuedMessages);

      debugPrint('ChatService: Message queued for delivery - ${message.id}');
    } catch (e) {
      debugPrint('ChatService: Failed to queue message - $e');
    }
  }

  /// Send priority notification
  Future<void> _sendPriorityNotification(ChatMessage message) async {
    final importance = message.priority == MessagePriority.emergency
        ? NotificationImportance.max
        : NotificationImportance.high;

    await _notificationService.showNotification(
      title: '🚨 ${_getPriorityEmoji(message.priority)} Priority Message',
      body: '${message.senderName}: ${message.content}',
      importance: importance,
      persistent: message.priority == MessagePriority.emergency,
    );
  }

  /// Cleanup old messages
  Future<void> _cleanupOldMessages() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    for (final chatId in _chatMessages.keys) {
      final messages = _chatMessages[chatId]!;
      _chatMessages[chatId] = messages
          .where((message) => message.timestamp.isAfter(cutoffDate))
          .toList();
    }

    await _saveChatMessages();
    debugPrint('ChatService: Old messages cleaned up');
  }

  /// Load saved data
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load chat rooms
      final roomsJson = prefs.getStringList('chat_rooms') ?? [];
      _chatRooms = roomsJson
          .map((json) => ChatRoom.fromJson(jsonDecode(json)))
          .toList();

      // Load chat messages
      final messagesJson = prefs.getString('chat_messages') ?? '{}';
      final messagesMap = jsonDecode(messagesJson) as Map<String, dynamic>;

      _chatMessages = messagesMap.map((chatId, messagesList) {
        final messages = (messagesList as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        return MapEntry(chatId, messages);
      });

      // Load preferences
      _isEnabled = prefs.getBool('chat_enabled') ?? true;
    } catch (e) {
      debugPrint('ChatService: Failed to load saved data - $e');
    }
  }

  /// Load current user
  Future<void> _loadCurrentUser() async {
    // Get user ID from user profile service for consistency
    final userProfile = _userProfileService.currentProfile;
    final userId = userProfile?.id ?? 'current_user';
    final userName = userProfile?.name.isNotEmpty == true
        ? userProfile!.name
        : 'You';

    _currentUser = ChatUser(
      id: userId,
      name: userName,
      status: UserStatus.available,
      lastSeen: DateTime.now(),
      isOnline: true,
    );

    debugPrint(
      'ChatService: Current user loaded - ID: $userId, Name: $userName',
    );
  }

  /// Save chat rooms
  Future<void> _saveChatRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = _chatRooms
          .map((room) => jsonEncode(room.toJson()))
          .toList();
      await prefs.setStringList('chat_rooms', roomsJson);
    } catch (e) {
      debugPrint('ChatService: Failed to save chat rooms - $e');
    }
  }

  /// Save chat messages
  Future<void> _saveChatMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesMap = _chatMessages.map((chatId, messages) {
        return MapEntry(chatId, messages.map((m) => m.toJson()).toList());
      });
      await prefs.setString('chat_messages', jsonEncode(messagesMap));
    } catch (e) {
      debugPrint('ChatService: Failed to save chat messages - $e');
    }
  }

  /// Notify server about new chat room
  Future<void> _notifyServerNewChatRoom(ChatRoom room) async {
    // In production, notify server via WebSocket or HTTP
    debugPrint(
      'ChatService: Notified server about new chat room - ${room.name}',
    );
  }

  /// Helper methods
  bool _shouldEncryptMessage(MessagePriority priority) {
    return priority == MessagePriority.emergency ||
        priority == MessagePriority.urgent;
  }

  String _getPriorityEmoji(MessagePriority priority) {
    return switch (priority) {
      MessagePriority.low => 'ℹ️',
      MessagePriority.normal => '💬',
      MessagePriority.high => '⚠️',
      MessagePriority.urgent => '🔥',
      MessagePriority.emergency => '🚨',
    };
  }

  String _generateMessageId() {
    return 'MSG_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  String _generateChatId() {
    return 'CHAT_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isEnabled => _isEnabled;

  List<ChatRoom> get chatRooms => List.from(_chatRooms);
  List<ChatUser> get nearbyUsers => List.from(_nearbyUsers);
  ChatUser? get currentUser => _currentUser;

  int get totalUnreadMessages =>
      _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);

  // Setters
  set isEnabled(bool enabled) {
    _isEnabled = enabled;
    _savePreferences();
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chat_enabled', _isEnabled);
    } catch (e) {
      debugPrint('ChatService: Failed to save preferences - $e');
    }
  }

  // Event handlers
  void setMessageReceivedCallback(Function(ChatMessage) callback) {
    _onMessageReceived = callback;
  }

  void setChatRoomUpdatedCallback(Function(ChatRoom) callback) {
    _onChatRoomUpdated = callback;
  }

  void setNearbyUsersUpdatedCallback(Function(List<ChatUser>) callback) {
    _onNearbyUsersUpdated = callback;
  }

  void setConnectionStatusChangedCallback(Function(bool) callback) {
    _onConnectionStatusChanged = callback;
  }

  /// Validate cross messaging policies before sending messages
  Future<void> _validateCrossMessagingPolicy(
    String chatId,
    MessageType type,
    MessagePriority priority,
  ) async {
    if (_currentUser == null) {
      debugPrint('ChatService: No current user - allowing message as fallback');
      return;
    }

    debugPrint(
      'ChatService: Validating policy for user ${_currentUser!.id}, chatId: $chatId, type: $type, priority: $priority',
    );

    // Get chat room details
    final chatRoom = _chatRooms.firstWhere(
      (room) => room.id == chatId,
      orElse: () => ChatRoom(
        id: '',
        name: '',
        type: ChatType.community,
        createdAt: DateTime.now(),
      ),
    );

    debugPrint(
      'ChatService: Chat room type: ${chatRoom.type}, name: ${chatRoom.name}',
    );

    // Check if current user is verified SAR member
    bool isCurrentUserSAR = false;
    SARIdentity? currentUserSARIdentity;

    try {
      isCurrentUserSAR = _sarIdentityService.isVerifiedSARMember(
        _currentUser!.id,
      );
      currentUserSARIdentity = _sarIdentityService.getSARMemberByUserId(
        _currentUser!.id,
      );
      debugPrint(
        'ChatService: User ${_currentUser!.id} is SAR member: $isCurrentUserSAR',
      );
    } catch (e) {
      debugPrint(
        'ChatService: Error checking SAR status - $e, allowing as fallback',
      );
      return; // Fallback: allow message if SAR service unavailable
    }

    // Emergency communications are always allowed for verified SAR members
    if (isCurrentUserSAR &&
        (type == MessageType.emergency ||
            type == MessageType.sosUpdate ||
            priority == MessagePriority.emergency)) {
      debugPrint('ChatService: Emergency message from SAR member - allowed');
      return; // Allow emergency communications
    }

    // Check chat room type restrictions
    switch (chatRoom.type) {
      case ChatType.direct:
        await _validateDirectMessagePolicy(chatRoom, isCurrentUserSAR);
        break;
      case ChatType.sarTeam:
        await _validateSARTeamMessagePolicy(
          isCurrentUserSAR,
          currentUserSARIdentity,
        );
        break;
      case ChatType.emergency:
        await _validateEmergencyMessagePolicy(isCurrentUserSAR, type, priority);
        break;
      case ChatType.community:
      case ChatType.group:
      case ChatType.locationBased:
      case ChatType.broadcast:
        // Community channels allow general participation but with moderation
        await _validateCommunityMessagePolicy(type, priority);
        break;
    }
  }

  /// Validate direct messaging policy
  Future<void> _validateDirectMessagePolicy(
    ChatRoom chatRoom,
    bool isCurrentUserSAR,
  ) async {
    debugPrint('ChatService: Validating direct message policy');

    // Get other participants (excluding current user)
    final otherParticipants = chatRoom.participants
        .where((id) => id != _currentUser!.id)
        .toList();

    debugPrint('ChatService: Other participants: $otherParticipants');

    for (final participantId in otherParticipants) {
      bool isParticipantSAR = false;
      try {
        isParticipantSAR = _sarIdentityService.isVerifiedSARMember(
          participantId,
        );
      } catch (e) {
        debugPrint(
          'ChatService: Error checking participant SAR status - $e, allowing as fallback',
        );
        continue; // Fallback: allow if unable to check
      }

      debugPrint(
        'ChatService: Current user SAR: $isCurrentUserSAR, Participant $participantId SAR: $isParticipantSAR',
      );

      // Check if this is cross-type messaging (SAR <-> Civilian)
      if (isCurrentUserSAR != isParticipantSAR) {
        debugPrint(
          'ChatService: Cross-type direct messaging detected - blocking',
        );
        // Cross-type direct messaging is restricted
        throw Exception(
          'Direct messaging between SAR members and civilians is restricted to emergency situations only. '
          'Please use community channels or emergency coordination rooms for communication.',
        );
      }
    }

    debugPrint('ChatService: Direct message policy validation passed');
  }

  /// Validate SAR team messaging policy
  Future<void> _validateSARTeamMessagePolicy(
    bool isCurrentUserSAR,
    SARIdentity? sarIdentity,
  ) async {
    if (!isCurrentUserSAR || sarIdentity == null) {
      throw Exception(
        'Access denied. Only verified SAR team members can participate in SAR team communications.',
      );
    }

    if (sarIdentity.verificationStatus != SARVerificationStatus.verified) {
      throw Exception(
        'SAR member verification required. Please complete the verification process before participating in team communications.',
      );
    }
  }

  /// Validate emergency messaging policy
  Future<void> _validateEmergencyMessagePolicy(
    bool isCurrentUserSAR,
    MessageType type,
    MessagePriority priority,
  ) async {
    // Emergency communications are allowed for:
    // 1. Verified SAR members
    // 2. Users in active SOS sessions
    // 3. Emergency personnel

    if (isCurrentUserSAR) {
      return; // SAR members can always participate in emergency communications
    }

    // For civilians, check if they have an active SOS session or emergency situation
    if (type == MessageType.emergency ||
        priority == MessagePriority.emergency) {
      // Allow if user is reporting their own emergency or responding to one they're involved in
      return;
    }

    // For non-emergency messages in emergency channels, require SAR verification
    throw Exception(
      'Only verified SAR members and emergency personnel can initiate non-emergency communications in emergency channels.',
    );
  }

  /// Validate community messaging policy
  Future<void> _validateCommunityMessagePolicy(
    MessageType type,
    MessagePriority priority,
  ) async {
    // Community channels are open but moderated
    // Restrict certain message types to verified users

    if (type == MessageType.sosUpdate || type == MessageType.activation) {
      final isCurrentUserSAR = _sarIdentityService.isVerifiedSARMember(
        _currentUser!.id,
      );
      if (!isCurrentUserSAR) {
        throw Exception(
          'Only verified SAR members can send operational updates in community channels.',
        );
      }
    }

    // Emergency priority messages in community channels require verification
    if (priority == MessagePriority.emergency) {
      final isCurrentUserSAR = _sarIdentityService.isVerifiedSARMember(
        _currentUser!.id,
      );
      if (!isCurrentUserSAR) {
        throw Exception(
          'Emergency priority messages in community channels require SAR member verification. '
          'For personal emergencies, please use the SOS feature.',
        );
      }
    }
  }

  /// Check if user has permission to create specific chat room types
  Future<bool> _canCreateChatRoom(ChatType type) async {
    if (_currentUser == null) return false;

    final isCurrentUserSAR = _sarIdentityService.isVerifiedSARMember(
      _currentUser!.id,
    );

    switch (type) {
      case ChatType.sarTeam:
      case ChatType.emergency:
        return isCurrentUserSAR;
      case ChatType.direct:
      case ChatType.group:
      case ChatType.community:
      case ChatType.locationBased:
      case ChatType.broadcast:
        return true; // Anyone can create these types
    }
  }

  String _sanitizeText(String input) {
    // Remove common garbled sequences and non-ASCII artifacts
    var out = input
        .replaceAll('�?�', '-')
        .replaceAll('�?O', 'Error:')
        .replaceAll('�s��,?', '')
        .replaceAll('dYs"', '')
        .replaceAll('dY"', '')
        .replaceAll("dY'", '')
        .replaceAll('dY`', '')
        .replaceAll('A�', '')
        .replaceAll('m/sA�', 'm/s^2');
    out = out.replaceAll(RegExp(r'[^\x0A\x0D\x20-\x7E]'), '');
    return out.trim();
  }

  /// Dispose of the service
  void dispose() {
    _webSocketSubscription?.cancel();
    _webSocketChannel?.sink.close();
    _heartbeatTimer?.cancel();
    _nearbyUsersTimer?.cancel();
    _messageCleanupTimer?.cancel();
  }
}
