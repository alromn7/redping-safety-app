import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'message_engine.dart';
import 'transport_manager.dart';
import 'dtn_storage_service.dart';

/// Handles synchronization when connectivity is restored
/// Automatically processes outbox and reconciles message state
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _engine = MessageEngine();
  final _transportManager = TransportManager();
  final _storage = DTNStorageService();
  final _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _syncTimer;

  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncAttempts = 0;

  // Stream controller for sync events
  StreamController<SyncEvent> _syncEventsController =
      StreamController<SyncEvent>.broadcast();

  /// Initialize sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Listen to connectivity changes.
      // In unit tests, connectivity_plus may not have a platform implementation.
      try {
        _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
          final isOnline = !results.contains(ConnectivityResult.none);
          if (isOnline) {
            _onConnectivityRestored();
          }
        });
      } catch (e) {
        debugPrint('⚠️ SyncService: Connectivity unavailable: $e');
      }

      // Periodic sync check (every 30 seconds)
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _periodicSync();
      });

      _isInitialized = true;
      debugPrint('✅ SyncService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize SyncService: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CONNECTIVITY RESTORATION
  // ============================================================================

  /// Handle connectivity restored event
  Future<void> _onConnectivityRestored() async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress, skipping...');
      return;
    }

    debugPrint('🔄 Connectivity restored, starting sync...');
    _syncEventsController.add(
      SyncEvent(type: SyncEventType.started, timestamp: DateTime.now()),
    );

    await syncOnReconnect();
  }

  /// Periodic sync check (even when online)
  Future<void> _periodicSync() async {
    if (_isSyncing) return;

    // Check if there are messages in outbox
    final outboxCount = await _storage.getOutboxCount();
    if (outboxCount > 0) {
      debugPrint('🔄 Periodic sync: $outboxCount messages in outbox');
      await syncOnReconnect();
    }
  }

  // ============================================================================
  // MAIN SYNC LOGIC
  // ============================================================================

  /// Sync messages on reconnection
  Future<SyncResult> syncOnReconnect() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        messagesSent: 0,
        messagesReceived: 0,
        error: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _syncAttempts++;

    final startTime = DateTime.now();
    int messagesSent = 0;
    int messagesReceived = 0;
    String? error;

    try {
      debugPrint('🔄 Starting sync (attempt #$_syncAttempts)...');

      // Step 1: Process outbox (send queued messages)
      messagesSent = await _processOutbox();

      // Step 2: Reconcile conversation states
      await _reconcileConversationStates();

      // Step 3: Update last sync timestamp
      _lastSyncTime = DateTime.now();

      final duration = DateTime.now().difference(startTime);
      debugPrint(
        '✅ Sync complete: $messagesSent sent, $messagesReceived received (${duration.inMilliseconds}ms)',
      );

      _syncEventsController.add(
        SyncEvent(
          type: SyncEventType.completed,
          timestamp: DateTime.now(),
          messagesSent: messagesSent,
          messagesReceived: messagesReceived,
          duration: duration,
        ),
      );

      return SyncResult(
        success: true,
        messagesSent: messagesSent,
        messagesReceived: messagesReceived,
        duration: duration,
      );
    } catch (e) {
      error = e.toString();
      debugPrint('❌ Sync failed: $e');

      _syncEventsController.add(
        SyncEvent(
          type: SyncEventType.failed,
          timestamp: DateTime.now(),
          error: error,
        ),
      );

      return SyncResult(
        success: false,
        messagesSent: messagesSent,
        messagesReceived: messagesReceived,
        error: error,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Process outbox - send all queued messages
  Future<int> _processOutbox() async {
    try {
      final sentCount = await _transportManager.processOutbox();
      debugPrint('📤 Outbox processed: $sentCount messages sent');
      return sentCount;
    } catch (e) {
      debugPrint('❌ Failed to process outbox: $e');
      return 0;
    }
  }

  /// Reconcile conversation states
  Future<void> _reconcileConversationStates() async {
    try {
      final conversations = await _storage.getAllConversationStates();

      for (var state in conversations) {
        await _engine.syncConversationState(state.conversationId);
      }

      debugPrint('🔄 Reconciled ${conversations.length} conversation states');
    } catch (e) {
      debugPrint('❌ Failed to reconcile conversation states: $e');
    }
  }

  // ============================================================================
  // MANUAL SYNC
  // ============================================================================

  /// Manually trigger sync
  Future<SyncResult> manualSync() async {
    debugPrint('🔄 Manual sync triggered');
    _syncEventsController.add(
      SyncEvent(type: SyncEventType.manualTrigger, timestamp: DateTime.now()),
    );
    return await syncOnReconnect();
  }

  /// Force sync even if already syncing
  Future<SyncResult> forceSync() async {
    _isSyncing = false; // Reset sync flag
    return await syncOnReconnect();
  }

  // ============================================================================
  // STATUS & MONITORING
  // ============================================================================

  /// Get sync status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncAttempts': _syncAttempts,
    };
  }

  /// Stream of sync events
  Stream<SyncEvent> get syncEventsStream => _syncEventsController.stream;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _syncTimer?.cancel();
    _syncTimer = null;

    try {
      await _syncEventsController.close();
    } catch (_) {
      // Ignore close errors in tests.
    }
    _syncEventsController = StreamController<SyncEvent>.broadcast();
    _isInitialized = false;
    debugPrint('👋 SyncService disposed');
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Sync event types
enum SyncEventType { started, completed, failed, manualTrigger }

/// Sync event for monitoring
class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final int? messagesSent;
  final int? messagesReceived;
  final Duration? duration;
  final String? error;

  SyncEvent({
    required this.type,
    required this.timestamp,
    this.messagesSent,
    this.messagesReceived,
    this.duration,
    this.error,
  });

  @override
  String toString() {
    return 'SyncEvent(type: $type, sent: $messagesSent, received: $messagesReceived, duration: ${duration?.inMilliseconds}ms, error: $error)';
  }
}

/// Sync result
class SyncResult {
  final bool success;
  final int messagesSent;
  final int messagesReceived;
  final Duration? duration;
  final String? error;

  SyncResult({
    required this.success,
    required this.messagesSent,
    required this.messagesReceived,
    this.duration,
    this.error,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, sent: $messagesSent, received: $messagesReceived, duration: ${duration?.inMilliseconds}ms, error: $error)';
  }
}
