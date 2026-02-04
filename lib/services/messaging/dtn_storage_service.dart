import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/messaging/message_packet.dart';
import '../../models/messaging/conversation_state.dart';

/// Delay-Tolerant Networking (DTN) storage service
/// Manages offline message queue and conversation state persistence
class DTNStorageService {
  static final DTNStorageService _instance = DTNStorageService._internal();
  factory DTNStorageService() => _instance;
  DTNStorageService._internal();

  // Box names
  static const String _outboxBoxName = 'message_outbox';
  static const String _conversationBoxName = 'conversation_states';
  static const String _processedIdsBoxName = 'processed_message_ids';

  Box<Map>? _outboxBox;
  Box<Map>? _conversationBox;
  Box<int>? _processedIdsBox; // messageId -> timestamp

  bool _initialized = false;

  /// Initialize Hive storage
  /// Note: Hive.initFlutter() is already called in main.dart
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Don't call Hive.initFlutter() again - it's already done in main.dart
      // Calling it twice causes: "Hive is already initialized" exception

      // Just open the boxes
      _outboxBox = await Hive.openBox<Map>(_outboxBoxName);
      _conversationBox = await Hive.openBox<Map>(_conversationBoxName);
      _processedIdsBox = await Hive.openBox<int>(_processedIdsBoxName);

      _initialized = true;
      debugPrint('✅ DTN Storage initialized (boxes opened)');

      // Cleanup old processed IDs (older than 30 days)
      await _cleanupOldProcessedIds();
    } catch (e) {
      debugPrint('❌ Failed to initialize DTN storage: $e');
      debugPrint('   Make sure Hive.initFlutter() was called in main.dart');
      rethrow;
    }
  }

  // ============================================================================
  // OUTBOX MANAGEMENT
  // ============================================================================

  /// Store message in outbox for later delivery
  Future<void> storeOutboxMessage(MessagePacket packet) async {
    await _ensureInitialized();
    try {
      await _outboxBox!.put(packet.messageId, packet.toJson());
      debugPrint('📤 Stored message in outbox: ${packet.messageId}');
    } catch (e) {
      debugPrint('❌ Failed to store outbox message: $e');
      rethrow;
    }
  }

  /// Get all messages from outbox
  Future<List<MessagePacket>> getOutboxMessages() async {
    await _ensureInitialized();
    try {
      final messages = <MessagePacket>[];
      for (var json in _outboxBox!.values) {
        try {
          final packet = MessagePacket.fromJson(
            Map<String, dynamic>.from(json),
          );
          // Skip expired messages
          if (!packet.isExpired) {
            messages.add(packet);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse outbox message: $e');
        }
      }
      return messages;
    } catch (e) {
      debugPrint('❌ Failed to get outbox messages: $e');
      return [];
    }
  }

  /// Remove message from outbox after successful delivery
  Future<void> removeFromOutbox(String messageId) async {
    await _ensureInitialized();
    try {
      await _outboxBox!.delete(messageId);
      debugPrint('✅ Removed message from outbox: $messageId');
    } catch (e) {
      debugPrint('❌ Failed to remove from outbox: $e');
    }
  }

  /// Get count of messages in outbox
  Future<int> getOutboxCount() async {
    await _ensureInitialized();
    return _outboxBox!.length;
  }

  /// Clear all messages from outbox
  Future<void> clearOutbox() async {
    await _ensureInitialized();
    await _outboxBox!.clear();
    debugPrint('🗑️ Cleared outbox');
  }

  // ============================================================================
  // CONVERSATION STATE MANAGEMENT
  // ============================================================================

  /// Store conversation state
  Future<void> storeConversationState(ConversationState state) async {
    await _ensureInitialized();
    try {
      await _conversationBox!.put(state.conversationId, state.toJson());
      debugPrint('💾 Stored conversation state: ${state.conversationId}');
    } catch (e) {
      debugPrint('❌ Failed to store conversation state: $e');
      rethrow;
    }
  }

  /// Get conversation state
  Future<ConversationState?> getConversationState(String conversationId) async {
    await _ensureInitialized();
    try {
      final json = _conversationBox!.get(conversationId);
      if (json == null) return null;
      return ConversationState.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      debugPrint('❌ Failed to get conversation state: $e');
      return null;
    }
  }

  /// Get all conversation states
  Future<List<ConversationState>> getAllConversationStates() async {
    await _ensureInitialized();
    try {
      final states = <ConversationState>[];
      for (var json in _conversationBox!.values) {
        try {
          states.add(
            ConversationState.fromJson(Map<String, dynamic>.from(json)),
          );
        } catch (e) {
          debugPrint('⚠️ Failed to parse conversation state: $e');
        }
      }
      return states;
    } catch (e) {
      debugPrint('❌ Failed to get all conversation states: $e');
      return [];
    }
  }

  /// Delete conversation state
  Future<void> deleteConversationState(String conversationId) async {
    await _ensureInitialized();
    await _conversationBox!.delete(conversationId);
    debugPrint('🗑️ Deleted conversation state: $conversationId');
  }

  // ============================================================================
  // MESSAGE DEDUPLICATION
  // ============================================================================

  /// Mark message as processed
  Future<void> markMessageProcessed(String messageId) async {
    await _ensureInitialized();
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _processedIdsBox!.put(messageId, timestamp);
    } catch (e) {
      debugPrint('❌ Failed to mark message processed: $e');
    }
  }

  /// Check if message has been processed
  Future<bool> isMessageProcessed(String messageId) async {
    await _ensureInitialized();
    return _processedIdsBox!.containsKey(messageId);
  }

  /// Get processed message IDs count
  Future<int> getProcessedIdsCount() async {
    await _ensureInitialized();
    return _processedIdsBox!.length;
  }

  /// Cleanup processed IDs older than 30 days
  Future<void> _cleanupOldProcessedIds() async {
    await _ensureInitialized();
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final keysToDelete = <String>[];
      for (var entry in _processedIdsBox!.toMap().entries) {
        if (entry.value < thirtyDaysAgo) {
          keysToDelete.add(entry.key);
        }
      }

      for (var key in keysToDelete) {
        await _processedIdsBox!.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        debugPrint(
          '🧹 Cleaned up ${keysToDelete.length} old processed message IDs',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup old processed IDs: $e');
    }
  }

  // ============================================================================
  // STATISTICS
  // ============================================================================

  /// Get storage statistics
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureInitialized();

    final outboxCount = await getOutboxCount();
    final conversationCount = _conversationBox!.length;
    final processedIdsCount = await getProcessedIdsCount();

    return {
      'outboxCount': outboxCount,
      'conversationCount': conversationCount,
      'processedIdsCount': processedIdsCount,
      'initialized': _initialized,
    };
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Ensure storage is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Compact storage (cleanup deleted entries)
  Future<void> compact() async {
    await _ensureInitialized();
    await _outboxBox!.compact();
    await _conversationBox!.compact();
    await _processedIdsBox!.compact();
    debugPrint('🗜️ Storage compacted');
  }

  /// Close all boxes
  Future<void> close() async {
    if (!_initialized) return;
    await _outboxBox?.close();
    await _conversationBox?.close();
    await _processedIdsBox?.close();
    _initialized = false;
    debugPrint('📪 DTN Storage closed');
  }

  /// Delete all data (for testing/reset)
  Future<void> deleteAllData() async {
    await _ensureInitialized();
    await clearOutbox();
    await _conversationBox!.clear();
    await _processedIdsBox!.clear();
    debugPrint('🗑️ All DTN data deleted');
  }
}
