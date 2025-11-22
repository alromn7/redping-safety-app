import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../models/emergency_message.dart';
import '../core/logging/app_logger.dart';
import '../models/emergency_contact.dart';
import 'auth_service.dart';
import 'connectivity_monitor_service.dart';
import 'app_service_manager.dart';

/// Service for managing emergency messaging with online/offline capability
class EmergencyMessagingService {
  static final EmergencyMessagingService _instance =
      EmergencyMessagingService._internal();
  factory EmergencyMessagingService() => _instance;
  EmergencyMessagingService._internal();

  // State
  bool _isInitialized = false;
  List<EmergencyMessage> _messages = [];
  List<EmergencyMessage> _offlineQueue = [];
  bool _isOnline = true;
  // User-requested flag for emergency messaging
  final bool _userRequestedEmergencyMessaging = false;

  // Stream controllers
  final StreamController<List<EmergencyMessage>> _messagesController =
      StreamController<List<EmergencyMessage>>.broadcast();
  final StreamController<List<EmergencyMessage>> _offlineQueueController =
      StreamController<List<EmergencyMessage>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  // Timers
  Timer? _syncTimer;
  Timer? _statusCheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Callbacks
  Function(EmergencyMessage)? _onMessageSent;
  Function(String)? _onConnectionStatusChanged;

  /// Initialize the emergency messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load existing messages
      await _loadMessages();
      await _loadOfflineQueue();

      // Add some sample SAR messages for testing if no messages exist
      if (_messages.isEmpty) {
        await _addSampleSARMessages();
      }

      // Start connection monitoring (connectivity_plus)
      await _primeConnectivityStatus();
      _startConnectionMonitoring();

      // Start periodic sync
      _startPeriodicSync();

      // Monitor offline/online status
      ConnectivityMonitorService().offlineStream.listen((isOffline) {
        final sosActive = AppServiceManager().sosService.isSOSActive;
        if (isOffline && (sosActive || _userRequestedEmergencyMessaging)) {
          // Only send emergency messages when offline AND SOS is active or user requests
          _startEmergencyMessageLoop();
        } else {
          // Stop emergency message loop otherwise
          _stopEmergencyMessageLoop();
        }
      });
      // Removed unused local overrides for emergency messaging request; using field _userRequestedEmergencyMessaging

      _isInitialized = true;
      AppLogger.i('Initialized successfully', tag: 'EmergencyMessagingService');
    } catch (e) {
      AppLogger.e(
        'Error initializing',
        tag: 'EmergencyMessagingService',
        error: e,
      );
      throw Exception('Failed to initialize EmergencyMessagingService: $e');
    }
  }

  void _startEmergencyMessageLoop() {
    // This would send emergency messages from the offline queue
    // when the device is offline.
    // Implement the logic to periodically attempt to send
    // messages from the offline queue.
  }

  void _stopEmergencyMessageLoop() {
    // Implement the logic to stop sending emergency messages
    // when the device is back online.
  }

  /// Receive message from SAR
  Future<void> receiveMessageFromSAR({
    required String senderId,
    required String senderName,
    required String content,
    required MessagePriority priority,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = EmergencyMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderName,
        content: content,
        recipients: ['current_user'], // Current user is the recipient
        timestamp: DateTime.now(),
        priority: priority,
        type: type,
        status: MessageStatus.sent,
        isRead: false,
        metadata: metadata ?? {},
      );

      await _saveMessage(message);
      _messages.add(message);
      _messagesController.add(_messages);
      _onMessageSent?.call(message);

      AppLogger.i(
        'Message received from SAR - ${message.id}',
        tag: 'EmergencyMessagingService',
      );
    } catch (e) {
      AppLogger.w(
        'Error receiving message from SAR',
        tag: 'EmergencyMessagingService',
        error: e,
      );
    }
  }

  /// Send emergency message
  Future<bool> sendEmergencyMessage({
    required String content,
    required List<EmergencyContact> recipients,
    MessagePriority priority = MessagePriority.high,
    MessageType type = MessageType.emergency,
  }) async {
    // --- START: NEW Firestore Integration Logic ---
    if (_isOnline) {
      try {
        // 1. Get current location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 2. Reverse-geocode to human-readable address (best-effort)
        String? address;
        try {
          final placemarks = await geocoding
              .placemarkFromCoordinates(position.latitude, position.longitude)
              .timeout(const Duration(seconds: 6));
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String?>[
              p.name,
              p.street,
              p.locality,
              p.administrativeArea,
              p.country,
            ].where((e) => (e ?? '').trim().isNotEmpty).cast<String>().toList();
            address = parts.join(', ');
          }
        } catch (_) {
          // best-effort only
        }

        // 3. Construct the SOS session data
        final authUserId = AuthService.instance.isAuthenticated
            ? AuthService.instance.currentUser.id
            : 'anonymous_user';
        final sosData = <String, dynamic>{
          'userId': authUserId,
          'status': 'active',
          'type': 'medical', // or 'manual', 'crash', 'fall' based on trigger
          'priority': 'high',
          'userMessage': content,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'timestamp': FieldValue.serverTimestamp(),
            if (address != null) 'address': address,
          },
        };

        // 4. Send data to Firestore
        await FirebaseFirestore.instance
            .collection('sos_sessions')
            .add(sosData);

        AppLogger.i(
          'Successfully sent SOS to Firestore.',
          tag: 'EmergencyMessagingService',
        );

        // --- After successful Firestore write, proceed with original local logic ---
      } catch (e) {
        AppLogger.w(
          'FAILED to send SOS to Firestore',
          tag: 'EmergencyMessagingService',
          error: e,
        );
        // If Firestore fails, we fall back to the original offline queuing logic.
        // The original code below will handle it.
      }
    }
    // --- END: NEW Firestore Integration Logic ---

    try {
      final message = EmergencyMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_user', // Would get from user profile
        senderName: 'You',
        content: content,
        recipients: recipients.map((c) => c.id).toList(),
        timestamp: DateTime.now(),
        priority: priority,
        type: type,
        status: _isOnline ? MessageStatus.sent : MessageStatus.pending,
        isRead: false,
      );

      if (_isOnline) {
        // Send immediately
        final success = await _sendToRecipients(message, recipients);
        if (success) {
          final sentMessage = message.copyWith(status: MessageStatus.sent);
          await _saveMessage(sentMessage);
          _messages.add(sentMessage);
          _messagesController.add(_messages);
          _onMessageSent?.call(sentMessage);
        } else {
          final failedMessage = message.copyWith(status: MessageStatus.failed);
          await _addToOfflineQueue(failedMessage);
        }
      } else {
        // Add to offline queue
        final pendingMessage = message.copyWith(status: MessageStatus.pending);
        await _addToOfflineQueue(pendingMessage);
      }

      AppLogger.i(
        'Message sent - ${message.id}',
        tag: 'EmergencyMessagingService',
      );
      return true;
    } catch (e) {
      AppLogger.e(
        'Error sending message',
        tag: 'EmergencyMessagingService',
        error: e,
      );
      return false;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          isRead: true,
        );
        await _saveMessage(_messages[messageIndex]);
        _messagesController.add(_messages);
      }
    } catch (e) {
      debugPrint(
        'EmergencyMessagingService: Error marking message as read - $e',
      );
    }
  }

  /// Get unread message count
  int getUnreadMessageCount() {
    return _messages.where((m) => !m.isRead).length;
  }

  /// Get offline queue count
  int getOfflineQueueCount() {
    return _offlineQueue.length;
  }

  /// Add sample SAR messages for testing
  Future<void> _addSampleSARMessages() async {
    final sampleMessages = [
      EmergencyMessage(
        id: 'sar_sample_1',
        senderId: 'sar_member_1',
        senderName: 'SAR Team',
        content:
            'We are en route to your location. Please stay calm and secure.',
        recipients: ['current_user'],
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        priority: MessagePriority.high,
        type: MessageType.sarResponse,
        status: MessageStatus.sent,
        isRead: false,
        metadata: {'messageType': 'sar_direct_message'},
      ),
      EmergencyMessage(
        id: 'sar_sample_2',
        senderId: 'sar_member_1',
        senderName: 'SAR Team',
        content: 'ETA 15 minutes. Are you able to move or are you injured?',
        recipients: ['current_user'],
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        priority: MessagePriority.medium,
        type: MessageType.sarResponse,
        status: MessageStatus.sent,
        isRead: true,
        metadata: {'messageType': 'sar_direct_message'},
      ),
      EmergencyMessage(
        id: 'sar_sample_3',
        senderId: 'emergency_team',
        senderName: 'Emergency Team',
        content:
            'We have received your SOS signal and are coordinating rescue efforts.',
        recipients: ['current_user'],
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        priority: MessagePriority.high,
        type: MessageType.emergency,
        status: MessageStatus.sent,
        isRead: true,
        metadata: {'messageType': 'emergency_response'},
      ),
    ];

    for (final message in sampleMessages) {
      await _saveMessage(message);
      _messages.add(message);
    }

    _messagesController.add(_messages);
    AppLogger.d(
      'Added ${sampleMessages.length} sample SAR messages',
      tag: 'EmergencyMessagingService',
    );
  }

  /// Check if any emergency contacts are online
  bool areContactsOnline() {
    // This would check actual contact status
    // For now, return true as placeholder
    return true;
  }

  /// Start connection monitoring
  void _startConnectionMonitoring() {
    // Periodic check as a fallback
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectionStatus();
    });

    // Real-time connectivity
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        if (online != _isOnline) {
          _isOnline = online;
          _connectionStatusController.add(_isOnline);
          _onConnectionStatusChanged?.call(_isOnline ? 'Online' : 'Offline');
          if (_isOnline && _offlineQueue.isNotEmpty) {
            _processOfflineQueue();
          }
        }
      });
    } catch (e) {
      debugPrint('EmergencyMessagingService: connectivity listen failed - $e');
    }
  }

  /// Check connection status
  void _checkConnectionStatus() async {
    final wasOnline = _isOnline;
    try {
      final results = await Connectivity().checkConnectivity();
      // Online if any transport is not 'none'
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      _isOnline = wasOnline;
    }

    if (wasOnline != _isOnline) {
      _connectionStatusController.add(_isOnline);
      _onConnectionStatusChanged?.call(_isOnline ? 'Online' : 'Offline');

      // If came back online, try to send queued messages
      if (_isOnline && _offlineQueue.isNotEmpty) {
        _processOfflineQueue();
      }
    }
  }

  Future<void> _primeConnectivityStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      _isOnline = true; // optimistic default
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        _syncMessages();
      }
    });
  }

  /// Sync messages with server
  Future<void> _syncMessages() async {
    try {
      // This would sync with the actual server
      AppLogger.d('Syncing messages', tag: 'EmergencyMessagingService');
    } catch (e) {
      AppLogger.w(
        'Error syncing messages',
        tag: 'EmergencyMessagingService',
        error: e,
      );
    }
  }

  /// Send message to recipients
  Future<bool> _sendToRecipients(
    EmergencyMessage message,
    List<EmergencyContact> recipients,
  ) async {
    try {
      // This would send to actual recipients via push notifications, SMS, etc.
      // For now, simulate sending
      await Future.delayed(const Duration(seconds: 1));

      // Simulate some recipients being offline
      final successRate = 0.8; // 80% success rate
      return DateTime.now().millisecondsSinceEpoch % 100 < (successRate * 100);
    } catch (e) {
      AppLogger.w(
        'Error sending to recipients',
        tag: 'EmergencyMessagingService',
        error: e,
      );
      return false;
    }
  }

  /// Add message to offline queue
  Future<void> _addToOfflineQueue(EmergencyMessage message) async {
    _offlineQueue.add(message);
    await _saveOfflineQueue();
    _offlineQueueController.add(_offlineQueue);
  }

  /// Process offline queue when back online
  Future<void> _processOfflineQueue() async {
    final messagesToSend = List<EmergencyMessage>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final message in messagesToSend) {
      // Get recipients for this message
      final recipients = _getRecipientsForMessage(message);
      final success = await _sendToRecipients(message, recipients);

      if (success) {
        final sentMessage = message.copyWith(status: MessageStatus.sent);
        await _saveMessage(sentMessage);
        _messages.add(sentMessage);
      } else {
        _offlineQueue.add(message);
      }
    }

    await _saveOfflineQueue();
    _offlineQueueController.add(_offlineQueue);
    _messagesController.add(_messages);
  }

  /// Get recipients for message
  List<EmergencyContact> _getRecipientsForMessage(EmergencyMessage message) {
    // This would get actual emergency contacts
    // For now, return empty list
    return [];
  }

  /// Load messages from storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('emergency_messages') ?? [];
      _messages = messagesJson
          .map((json) => EmergencyMessage.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      AppLogger.w(
        'Error loading messages',
        tag: 'EmergencyMessagingService',
        error: e,
      );
      _messages = [];
    }
  }

  /// Save message to storage
  Future<void> _saveMessage(EmergencyMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingMessages = List<String>.from(
        prefs.getStringList('emergency_messages') ?? [],
      );

      // Remove existing message with same ID
      existingMessages.removeWhere((json) {
        try {
          final msg = EmergencyMessage.fromJson(jsonDecode(json));
          return msg.id == message.id;
        } catch (e) {
          return false;
        }
      });

      // Add updated message
      existingMessages.add(jsonEncode(message.toJson()));

      await prefs.setStringList('emergency_messages', existingMessages);
    } catch (e) {
      debugPrint('EmergencyMessagingService: Error saving message - $e');
    }
  }

  /// Load offline queue from storage
  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList('emergency_offline_queue') ?? [];
      _offlineQueue = queueJson
          .map((json) => EmergencyMessage.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('EmergencyMessagingService: Error loading offline queue - $e');
      _offlineQueue = [];
    }
  }

  /// Save offline queue to storage
  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _offlineQueue
          .map((message) => jsonEncode(message.toJson()))
          .toList();
      await prefs.setStringList('emergency_offline_queue', queueJson);
    } catch (e) {
      debugPrint('EmergencyMessagingService: Error saving offline queue - $e');
    }
  }

  /// Set callbacks
  void setMessageSentCallback(Function(EmergencyMessage) callback) {
    _onMessageSent = callback;
  }

  void setConnectionStatusCallback(Function(String) callback) {
    _onConnectionStatusChanged = callback;
  }

  /// Get streams
  Stream<List<EmergencyMessage>> get messagesStream =>
      _messagesController.stream;
  Stream<List<EmergencyMessage>> get offlineQueueStream =>
      _offlineQueueController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Get current state
  List<EmergencyMessage> get messages => List.unmodifiable(_messages);
  List<EmergencyMessage> get offlineQueue => List.unmodifiable(_offlineQueue);
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _statusCheckTimer?.cancel();
    _connectivitySub?.cancel();
    _messagesController.close();
    _offlineQueueController.close();
    _connectionStatusController.close();
  }
}
