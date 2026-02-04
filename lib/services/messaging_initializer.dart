import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/messaging/message_packet.dart';
import 'messaging/crypto_service.dart';
import 'messaging/message_engine.dart';
import 'messaging/dtn_storage_service.dart';
import 'messaging/transport_manager.dart';
import 'messaging/sync_service.dart';

/// Helper service to initialize messaging v2 system
/// Use this to set up encryption, storage, message engine, and transports
class MessagingInitializer {
  static final MessagingInitializer _instance =
      MessagingInitializer._internal();
  factory MessagingInitializer() => _instance;
  MessagingInitializer._internal();

  final _crypto = CryptoService();
  final _engine = MessageEngine();
  final _storage = DTNStorageService();
  final _transportManager = TransportManager();
  final _syncService = SyncService();
  final _deviceInfo = DeviceInfoPlugin();

  bool _initialized = false;
  bool _disposing = false;

  StreamSubscription<MessagePacket>? _receivedSub;
  StreamSubscription<List<MessagePacket>>? _outboxSub;

  /// Initialize messaging v2 system (Phase 2: with transports)
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ Messaging system already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing Messaging v2 System (Phase 2)...');

      // Get device ID
      final deviceId = await _getDeviceId();
      debugPrint('📱 Device ID: $deviceId');

      // Get user ID
      final userId = await _getUserId();
      debugPrint('👤 User ID: $userId');

      // Initialize components
      await _storage.initialize();
      await _crypto.initialize(deviceId);
      await _engine.initialize(deviceId: deviceId, userId: userId);

      // Phase 2: Initialize transport manager
      await _transportManager.initialize(userId: userId);

      // Phase 2: Initialize sync service
      await _syncService.initialize();

      // Phase 2: Listen to received messages from transports
      _receivedSub = _transportManager.receivedMessagesStream.listen((packet) {
        if (_disposing) return;
        _engine.receiveMessage(packet);
      });

      // Phase 2: Send messages through transport manager
      _outboxSub = _engine.outboxStream.listen((messages) async {
        if (_disposing) return;

        // Auto-send messages when they're queued.
        // Important: these packets are already persisted in the DTN outbox by
        // MessageEngine.queueMessage, so do not re-store them on failure.
        for (var packet in messages) {
          if (_disposing) return;
          try {
            final sent = await _transportManager.trySendPacket(packet);
            if (_disposing) return;
            if (sent) {
              await _engine.markMessageSent(packet.messageId);
            }
          } catch (e) {
            debugPrint('⚠️ Failed to send queued message: $e');
          }
        }
      });

      _initialized = true;
      debugPrint('✅ Messaging v2 System (Phase 2) initialized successfully');

      // Print statistics
      final stats = await getStatistics();
      debugPrint('📊 Statistics: $stats');
    } catch (e) {
      debugPrint('❌ Failed to initialize messaging system: $e');
      rethrow;
    }
  }

  /// Send a test message
  Future<MessagePacket> sendTestMessage({
    String? content,
    String? conversationId,
  }) async {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }

    final testContent = content ?? 'Test message from RedPing Messaging v2';
    final testConversationId =
        conversationId ??
        'test_conversation_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('📤 Sending test message...');
    final packet = await _engine.sendMessage(
      conversationId: testConversationId,
      content: testContent,
      type: MessageType.text,
      priority: MessagePriority.normal,
    );

    debugPrint('✅ Test message sent: ${packet.messageId}');
    return packet;
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return info.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ??
            'ios_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        return 'device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get device ID: $e');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get user ID
  Future<String> _getUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.uid;
      }
      return 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('⚠️ Failed to get user ID: $e');
      return 'fallback_user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get messaging engine (for advanced usage)
  MessageEngine get engine {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }
    return _engine;
  }

  /// Get crypto service (for advanced usage)
  CryptoService get crypto {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }
    return _crypto;
  }

  /// Get storage service (for advanced usage)
  DTNStorageService get storage {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }
    return _storage;
  }

  /// Get transport manager (Phase 2)
  TransportManager get transportManager {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }
    return _transportManager;
  }

  /// Get sync service (Phase 2)
  SyncService get syncService {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }
    return _syncService;
  }

  /// Check if system is initialized
  bool get isInitialized => _initialized;

  /// Get comprehensive system statistics (Phase 2)
  Future<Map<String, dynamic>> getStatistics() async {
    if (!_initialized) {
      return {'initialized': false};
    }

    return {
      'engine': await _engine.getStatistics(),
      'transport': await _transportManager.getStatistics(),
      'sync': _syncService.getStatus(),
    };
  }

  /// Manually trigger sync (Phase 2)
  Future<void> manualSync() async {
    if (!_initialized) {
      throw Exception('Call initialize() first');
    }
    await _syncService.manualSync();
  }

  /// Dispose resources
  Future<void> dispose() async {
    _disposing = true;

    try {
      await _outboxSub?.cancel();
    } catch (_) {}
    _outboxSub = null;

    try {
      await _receivedSub?.cancel();
    } catch (_) {}
    _receivedSub = null;

    // Dispose in an order that prevents background work from touching Hive after
    // it's closed.
    await _syncService.dispose();
    await _transportManager.dispose();
    await _engine.dispose();
    await _storage.close();

    _initialized = false;
    _disposing = false;
    debugPrint('👋 Messaging system disposed');
  }
}
