import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/messaging/message_packet.dart';
import '../../models/messaging/conversation_state.dart';
import '../../models/messaging/transport_type.dart';
import 'crypto_service.dart';
import 'dtn_storage_service.dart';

/// Core messaging engine for queue management, deduplication, and state sync
class MessageEngine {
  static final MessageEngine _instance = MessageEngine._internal();
  factory MessageEngine() => _instance;
  MessageEngine._internal();

  final _crypto = CryptoService();
  final _storage = DTNStorageService();
  final _uuid = const Uuid();

    // Stream controllers (recreated on dispose for testability)
    StreamController<List<MessagePacket>> _outboxController =
      StreamController<List<MessagePacket>>.broadcast();
    StreamController<MessagePacket> _receivedController =
      StreamController<MessagePacket>.broadcast();
    StreamController<MessageStatus> _statusController =
      StreamController<MessageStatus>.broadcast();

  // In-memory cache for processed message IDs (for quick lookup)
  final Set<String> _processedMessageIds = {};

  // Pending messages awaiting delivery
  final Map<String, MessagePacket> _pendingMessages = {};

  bool _initialized = false;
  String? _currentDeviceId;
  String? _currentUserId;

  /// Initialize the message engine
  Future<void> initialize({
    required String deviceId,
    required String userId,
  }) async {
    if (_initialized) return;

    try {
      _currentDeviceId = deviceId;
      _currentUserId = userId;

      // Initialize dependencies
      await _crypto.initialize(deviceId);
      await _storage.initialize();

      // Load processed IDs into memory
      await _loadProcessedIds();

      _initialized = true;
      debugPrint('✅ MessageEngine initialized for device $deviceId');
    } catch (e) {
      debugPrint('❌ Failed to initialize MessageEngine: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MESSAGE SENDING
  // ============================================================================

  /// Send a message (creates packet, encrypts, queues for delivery)
  Future<MessagePacket> sendMessage({
    required String conversationId,
    required String content,
    required MessageType type,
    MessagePriority priority = MessagePriority.normal,
    TransportHint transportHint = TransportHint.auto,
    List<String> recipients = const [],
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      // Get or create conversation key
      String conversationKey =
          await _crypto.getConversationKey(conversationId) ??
          await _createConversationKey(conversationId);

      // Encrypt payload
      final encryptedPayload = await _crypto.encryptMessage(
        content,
        conversationKey,
      );

      // Create packet
      final packet = MessagePacket(
        messageId: _uuid.v4(),
        conversationId: conversationId,
        senderId: _currentUserId!,
        deviceId: _currentDeviceId!,
        type: type.name,
        encryptedPayload: encryptedPayload,
        signature: '', // Will be signed below
        timestamp: DateTime.now().millisecondsSinceEpoch,
        priority: priority.name,
        preferredTransport: transportHint.name,
        recipients: recipients,
        metadata: metadata ?? {},
        status: MessageStatus.queued.name,
      );

      // Sign the packet
      final signature = await _crypto.signMessage(
        _createSignaturePayload(packet),
        _currentDeviceId!,
      );

      final signedPacket = packet.copyWith(signature: signature);

      // Queue for delivery
      await queueMessage(signedPacket);

      debugPrint('📤 Message queued: ${signedPacket.messageId}');
      return signedPacket;
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      rethrow;
    }
  }

  /// Queue message for delivery (stores in outbox)
  Future<void> queueMessage(MessagePacket packet) async {
    _ensureInitialized();

    try {
      // Add to pending messages
      _pendingMessages[packet.messageId] = packet;

      // Store in persistent outbox
      await _storage.storeOutboxMessage(packet);

      // Notify listeners
      _outboxController.add(await getUnsentMessages());

      debugPrint('📥 Message queued: ${packet.messageId}');
    } catch (e) {
      debugPrint('❌ Failed to queue message: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MESSAGE RECEIVING
  // ============================================================================

  /// Receive and process incoming message
  Future<void> receiveMessage(MessagePacket packet) async {
    _ensureInitialized();

    try {
      // Verify signature first
      final isValid = await _verifyPacketSignature(packet);
      if (!isValid) {
        debugPrint('⚠️ Invalid signature for message: ${packet.messageId}');
        return;
      }

      // Check for duplicates
      if (await isMessageProcessed(packet.messageId)) {
        debugPrint('⚠️ Duplicate message ignored: ${packet.messageId}');
        return;
      }

      // Mark as processed
      await markMessageProcessed(packet.messageId);

      // Decrypt payload
      final conversationKey = await _crypto.getConversationKey(
        packet.conversationId,
      );
      if (conversationKey != null) {
        try {
          final decryptedContent = await _crypto.decryptMessage(
            packet.encryptedPayload,
            conversationKey,
          );
          debugPrint(
            '✅ Message decrypted: ${decryptedContent.substring(0, 20)}...',
          );
        } catch (e) {
          debugPrint('⚠️ Failed to decrypt message: $e');
        }
      }

      // Emit to stream
      _receivedController.add(packet);

      debugPrint('📨 Message received: ${packet.messageId}');
    } catch (e) {
      debugPrint('❌ Failed to receive message: $e');
    }
  }

  // ============================================================================
  // DEDUPLICATION
  // ============================================================================

  /// Check if message has been processed
  Future<bool> isMessageProcessed(String messageId) async {
    // Check in-memory cache first
    if (_processedMessageIds.contains(messageId)) {
      return true;
    }

    // Check persistent storage
    return await _storage.isMessageProcessed(messageId);
  }

  /// Mark message as processed (prevents infinite loops)
  Future<void> markMessageProcessed(String messageId) async {
    _processedMessageIds.add(messageId);
    await _storage.markMessageProcessed(messageId);
  }

  /// Load processed IDs into memory for fast lookup
  Future<void> _loadProcessedIds() async {
    // Note: For now we don't preload all IDs to save memory
    // Storage lookup is fast enough with Hive
    debugPrint('💾 Processed IDs ready for lookup');
  }

  // ============================================================================
  // QUEUE MANAGEMENT
  // ============================================================================

  /// Get all unsent messages from outbox
  Future<List<MessagePacket>> getUnsentMessages() async {
    _ensureInitialized();
    return await _storage.getOutboxMessages();
  }

  /// Mark message as sent and remove from outbox
  Future<void> markMessageSent(
    String messageId, {
    TransportType? transportUsed,
  }) async {
    _ensureInitialized();

    try {
      // Remove from pending
      _pendingMessages.remove(messageId);

      // Remove from storage
      await _storage.removeFromOutbox(messageId);

      // Update status
      _statusController.add(MessageStatus.delivered);

      // Notify listeners
      _outboxController.add(await getUnsentMessages());

      debugPrint(
        '✅ Message sent: $messageId via ${transportUsed?.name ?? "unknown"}',
      );
    } catch (e) {
      debugPrint('❌ Failed to mark message sent: $e');
    }
  }

  /// Retry failed message
  Future<void> retryMessage(String messageId) async {
    final packet = _pendingMessages[messageId];
    if (packet != null) {
      await queueMessage(packet);
      debugPrint('🔄 Retrying message: $messageId');
    }
  }

  /// Get outbox count
  Future<int> getOutboxCount() async {
    return await _storage.getOutboxCount();
  }

  // ============================================================================
  // CONVERSATION STATE
  // ============================================================================

  /// Sync conversation state (reconcile with remote)
  Future<void> syncConversationState(String conversationId) async {
    _ensureInitialized();

    try {
      var state = await _storage.getConversationState(conversationId);

      // Create new state if doesn't exist
      if (state == null) {
        state = ConversationState(
          conversationId: conversationId,
          participants: [],
          lastSyncTimestamp: DateTime.now().millisecondsSinceEpoch,
        );
        await _storage.storeConversationState(state);
      }

      // Check if key rotation is needed
      if (state.needsKeyRotation) {
        await _rotateConversationKey(conversationId);
      }

      debugPrint('🔄 Conversation state synced: $conversationId');
    } catch (e) {
      debugPrint('❌ Failed to sync conversation state: $e');
    }
  }

  /// Get conversation state
  Future<ConversationState?> getConversationState(String conversationId) async {
    return await _storage.getConversationState(conversationId);
  }

  /// Update conversation state
  Future<void> updateConversationState(ConversationState state) async {
    await _storage.storeConversationState(state);
  }

  // ============================================================================
  // RECONCILIATION
  // ============================================================================

  /// Reconcile messages after reconnection
  Future<void> reconcileMessages(List<MessagePacket> remoteMessages) async {
    _ensureInitialized();

    int newMessages = 0;
    int duplicates = 0;

    for (var packet in remoteMessages) {
      if (!await isMessageProcessed(packet.messageId)) {
        await receiveMessage(packet);
        newMessages++;
      } else {
        duplicates++;
      }
    }

    debugPrint(
      '🔄 Reconciliation complete: $newMessages new, $duplicates duplicates',
    );
  }

  /// Sync on reconnect (upload outbox, download missed messages)
  Future<void> syncOnReconnect() async {
    _ensureInitialized();

    try {
      debugPrint('🔄 Starting sync after reconnection...');

      // Get all unsent messages
      final unsentMessages = await getUnsentMessages();
      debugPrint('📤 Found ${unsentMessages.length} unsent messages');

      // Note: Actual upload will be handled by transport layer
      // This just reports status

      debugPrint('✅ Sync ready - ${unsentMessages.length} messages to send');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    }
  }

  // ============================================================================
  // STREAMS
  // ============================================================================

  /// Stream of outbox changes
  Stream<List<MessagePacket>> get outboxStream => _outboxController.stream;

  /// Stream of received messages
  Stream<MessagePacket> get receivedStream => _receivedController.stream;

  /// Stream of message status changes
  Stream<MessageStatus> get statusStream => _statusController.stream;

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Create conversation key
  Future<String> _createConversationKey(String conversationId) async {
    final key = await _crypto.generateConversationKey();
    await _crypto.storeConversationKey(conversationId, key);
    debugPrint('🔑 Created conversation key for $conversationId');
    return key;
  }

  /// Rotate conversation key
  Future<void> _rotateConversationKey(String conversationId) async {
    final newKey = await _crypto.generateConversationKey();
    await _crypto.storeConversationKey(conversationId, newKey);

    final state = await _storage.getConversationState(conversationId);
    if (state != null) {
      final rotatedState = state.rotateKey(newKey);
      await _storage.storeConversationState(rotatedState);
    }

    debugPrint('🔄 Rotated conversation key for $conversationId');
  }

  /// Create signature payload
  String _createSignaturePayload(MessagePacket packet) {
    return '${packet.messageId}:${packet.conversationId}:${packet.senderId}:${packet.timestamp}';
  }

  /// Verify packet signature
  Future<bool> _verifyPacketSignature(MessagePacket packet) async {
    // For now, always return true - proper verification requires sender's public key
    // TODO: Implement proper signature verification with key exchange
    return true;
  }

  /// Ensure engine is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'MessageEngine not initialized. Call initialize() first.',
      );
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final storageStats = await _storage.getStatistics();
    return {
      ...storageStats,
      'pendingMessages': _pendingMessages.length,
      'processedIdsInMemory': _processedMessageIds.length,
      'currentDeviceId': _currentDeviceId,
      'currentUserId': _currentUserId,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _outboxController.close();
    await _receivedController.close();
    await _statusController.close();

    // Reset state so this singleton can be re-initialized (useful in tests)
    _outboxController = StreamController<List<MessagePacket>>.broadcast();
    _receivedController = StreamController<MessagePacket>.broadcast();
    _statusController = StreamController<MessageStatus>.broadcast();
    _processedMessageIds.clear();
    _pendingMessages.clear();
    _initialized = false;
    debugPrint('👋 MessageEngine disposed');
  }
}
