import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/messaging/message_packet.dart';
import '../../models/messaging/transport_type.dart';
import 'transports/transport_interface.dart';
import 'transports/internet_transport.dart';
import 'dtn_storage_service.dart';

/// Manages multiple transports and handles message routing with fallback
class TransportManager {
  static final TransportManager _instance = TransportManager._internal();
  factory TransportManager() => _instance;
  TransportManager._internal();

  final Map<TransportType, ITransport> _transports = {};
  final _storage = DTNStorageService();

  // Stream controllers
  StreamController<TransportStatus> _statusController =
      StreamController<TransportStatus>.broadcast();

  TransportStatus _currentStatus = const TransportStatus();
  bool _initialized = false;

  /// Initialize transport manager with available transports
  Future<void> initialize({String? userId}) async {
    if (_initialized) return;

    try {
      debugPrint('🚀 Initializing TransportManager...');

      // Initialize storage
      await _storage.initialize();

      // Initialize Internet transport (Phase 2)
      try {
        final internetTransport = InternetTransport();
        await internetTransport.initialize();
        if (userId != null) {
          internetTransport.setUserId(userId);
        }
        _transports[TransportType.internet] = internetTransport;
      } catch (e) {
        // In unit tests (or environments without Firebase/plugins), InternetTransport
        // may be unavailable. Keep TransportManager usable for offline queuing.
        debugPrint('⚠️ Internet transport unavailable: $e');
      }

      // Phase 3+: Add Bluetooth mesh, WiFi Direct, Satellite
      // _transports[TransportType.bluetooth] = BluetoothMeshTransport();
      // _transports[TransportType.wifiDirect] = WiFiDirectTransport();
      // _transports[TransportType.satellite] = SatelliteTransport();

      // Start monitoring transport availability
      _startMonitoring();

      _initialized = true;
      debugPrint(
        '✅ TransportManager initialized with ${_transports.length} transports',
      );
    } catch (e) {
      debugPrint('❌ Failed to initialize TransportManager: $e');
      rethrow;
    }
  }

  // ============================================================================
  // TRANSPORT SELECTION
  // ============================================================================

  /// Select best available transport based on priority and message type
  Future<ITransport?> selectBestTransport(MessagePacket packet) async {
    // For emergency messages, try to use fastest available transport
    if (packet.priority == MessagePriority.emergency.name) {
      return await _selectEmergencyTransport();
    }

    // For normal messages, use transport preference order
    final preferenceOrder = _getTransportPreferenceOrder(packet);

    for (var type in preferenceOrder) {
      final transport = _transports[type];
      if (transport != null && await transport.isAvailable()) {
        return transport;
      }
    }

    // No transport available - message will go to outbox
    return null;
  }

  /// Get transport preference order based on message packet hints
  List<TransportType> _getTransportPreferenceOrder(MessagePacket packet) {
    switch (packet.preferredTransport) {
      case 'preferInternet':
        return [
          TransportType.internet,
          TransportType.wifiDirect,
          TransportType.bluetooth,
        ];
      case 'preferMesh':
        return [
          TransportType.bluetooth,
          TransportType.wifiDirect,
          TransportType.internet,
        ];
      case 'forceOffline':
        return []; // Force offline queue
      case 'auto':
      default:
        return [
          TransportType.internet,
          TransportType.wifiDirect,
          TransportType.bluetooth,
          TransportType.satellite,
        ];
    }
  }

  /// Select transport for emergency messages (try all simultaneously)
  Future<ITransport?> _selectEmergencyTransport() async {
    // For now, just use internet if available
    // Phase 3+: Try multiple transports in parallel
    final internet = _transports[TransportType.internet];
    if (internet != null && await internet.isAvailable()) {
      return internet;
    }
    return null;
  }

  // ============================================================================
  // MESSAGE SENDING WITH FALLBACK
  // ============================================================================

  /// Send packet with automatic fallback
  Future<bool> sendPacketWithFallback(MessagePacket packet) async {
    if (!_initialized) {
      throw Exception('TransportManager not initialized');
    }

    final sent = await trySendPacket(packet);
    if (sent) return true;

    // No transport available (or send failed) - store in outbox.
    debugPrint('📥 No transport available, storing in outbox: ${packet.messageId}');
    await _storage.storeOutboxMessage(packet);
    await _updateStatus();
    return false;
  }

  /// Attempt to send a packet without writing to the outbox.
  ///
  /// This is useful when the packet is already queued in persistent storage
  /// (e.g. MessageEngine outbox), so we avoid redundant Hive writes.
  Future<bool> trySendPacket(MessagePacket packet) async {
    if (!_initialized) {
      throw Exception('TransportManager not initialized');
    }

    // Try to select best transport
    final transport = await selectBestTransport(packet);
    if (transport == null) {
      return false;
    }

    // Try to send via selected transport
    try {
      await transport.sendPacket(packet);
      debugPrint('✅ Sent via ${transport.type.name}: ${packet.messageId}');
      return true;
    } catch (e) {
      debugPrint('⚠️ Failed to send via ${transport.type.name}: $e');

      // Try fallback transports
      final success = await _tryFallbackTransports(packet, transport.type);
      return success;
    }
  }

  /// Try fallback transports if primary fails
  Future<bool> _tryFallbackTransports(
    MessagePacket packet,
    TransportType failedType,
  ) async {
    final fallbackOrder = _getTransportPreferenceOrder(
      packet,
    ).where((type) => type != failedType).toList();

    for (var type in fallbackOrder) {
      final transport = _transports[type];
      if (transport != null && await transport.isAvailable()) {
        try {
          await transport.sendPacket(packet);
          debugPrint('✅ Sent via fallback ${type.name}: ${packet.messageId}');
          return true;
        } catch (e) {
          debugPrint('⚠️ Fallback ${type.name} also failed: $e');
          continue;
        }
      }
    }

    return false;
  }

  // ============================================================================
  // OUTBOX PROCESSING
  // ============================================================================

  /// Process outbox - try to send queued messages
  Future<int> processOutbox() async {
    if (!_initialized) return 0;

    final outboxMessages = await _storage.getOutboxMessages();
    if (outboxMessages.isEmpty) return 0;

    debugPrint('📤 Processing outbox: ${outboxMessages.length} messages');

    int sentCount = 0;
    for (var packet in outboxMessages) {
      // Skip expired messages
      if (packet.isExpired) {
        await _storage.removeFromOutbox(packet.messageId);
        debugPrint('🗑️ Removed expired message: ${packet.messageId}');
        continue;
      }

      // Try to send (do not re-store if offline)
      final sent = await trySendPacket(packet);
      if (sent) {
        await _storage.removeFromOutbox(packet.messageId);
        sentCount++;
      }
    }

    debugPrint(
      '✅ Processed outbox: $sentCount sent, ${outboxMessages.length - sentCount} remaining',
    );
    await _updateStatus();
    return sentCount;
  }

  /// Get outbox message count
  Future<int> getOutboxCount() async {
    final count = await _storage.getOutboxCount();

    // Keep status consistent even if storage is mutated externally (e.g. tests
    // calling DTNStorageService().deleteAllData()).
    final hasOutbox = count > 0;
    if (_currentStatus.hasOutboxMessages != hasOutbox) {
      _currentStatus = _currentStatus.copyWith(hasOutboxMessages: hasOutbox);
      _statusController.add(_currentStatus);
    }

    return count;
  }

  // ============================================================================
  // TRANSPORT MONITORING
  // ============================================================================

  /// Start monitoring transport availability
  void _startMonitoring() {
    // Monitor internet transport
    final internet = _transports[TransportType.internet] as InternetTransport?;
    if (internet != null) {
      internet.statusStream.listen((status) {
        _updateTransportStatus(
          TransportType.internet,
          status['available'] as bool,
        );
      });
    }

    // Initial status update
    _updateStatus();
  }

  /// Update status for specific transport
  void _updateTransportStatus(TransportType type, bool available) {
    switch (type) {
      case TransportType.internet:
        _currentStatus = _currentStatus.copyWith(internet: available);
        break;
      case TransportType.bluetooth:
        _currentStatus = _currentStatus.copyWith(bluetooth: available);
        break;
      case TransportType.wifiDirect:
        _currentStatus = _currentStatus.copyWith(wifiDirect: available);
        break;
      case TransportType.satellite:
        _currentStatus = _currentStatus.copyWith(satellite: available);
        break;
      case TransportType.localStore:
        break;
    }

    _statusController.add(_currentStatus);
  }

  /// Update overall status
  Future<void> _updateStatus() async {
    final outboxCount = await getOutboxCount();
    final hasOutbox = outboxCount > 0;

    // Get active transport
    TransportType? activeTransport;
    for (var entry in _transports.entries) {
      if (await entry.value.isAvailable()) {
        activeTransport = entry.key;
        break;
      }
    }

    _currentStatus = _currentStatus.copyWith(
      hasOutboxMessages: hasOutbox,
      activeTransport: activeTransport,
    );

    _statusController.add(_currentStatus);
  }

  /// Stream of transport status updates
  Stream<TransportStatus> get statusStream => _statusController.stream;

  /// Get current transport status
  TransportStatus get currentStatus => _currentStatus;

  // ============================================================================
  // TRANSPORT ACCESS
  // ============================================================================

  /// Get specific transport
  ITransport? getTransport(TransportType type) {
    return _transports[type];
  }

  /// Get all transports
  Map<TransportType, ITransport> getAllTransports() {
    return Map.unmodifiable(_transports);
  }

  /// Check if transport is available
  Future<bool> isTransportAvailable(TransportType type) async {
    final transport = _transports[type];
    if (transport == null) return false;
    return await transport.isAvailable();
  }

  // ============================================================================
  // RECEIVED MESSAGES
  // ============================================================================

  /// Stream of all received messages from all transports
  Stream<MessagePacket> get receivedMessagesStream async* {
    for (var transport in _transports.values) {
      yield* transport.receivedPackets;
    }
  }

  // ============================================================================
  // STATISTICS
  // ============================================================================

  /// Get comprehensive statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final stats = <String, dynamic>{
      'initialized': _initialized,
      'transports': {},
      'currentStatus': {
        'internet': _currentStatus.internet,
        'bluetooth': _currentStatus.bluetooth,
        'wifiDirect': _currentStatus.wifiDirect,
        'satellite': _currentStatus.satellite,
        'hasOutboxMessages': _currentStatus.hasOutboxMessages,
        'activeTransport': _currentStatus.activeTransport?.name,
      },
      'outboxCount': await getOutboxCount(),
    };

    // Get stats from each transport
    for (var entry in _transports.entries) {
      stats['transports'][entry.key.name] = await entry.value.getStatus();
    }

    return stats;
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose all transports and resources
  Future<void> dispose() async {
    for (var transport in _transports.values) {
      await transport.dispose();
    }
    _transports.clear();
    await _statusController.close();
    _statusController = StreamController<TransportStatus>.broadcast();
    _initialized = false;
    debugPrint('👋 TransportManager disposed');
  }

  /// Check if initialized
  bool get isInitialized => _initialized;
}
