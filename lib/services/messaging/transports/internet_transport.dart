import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../models/messaging/message_packet.dart';
import '../../../models/messaging/transport_type.dart';
import 'transport_interface.dart';

/// Internet transport implementation using Firebase Firestore
/// Integrates with existing Firestore collections for backward compatibility
class InternetTransport implements ITransport {
  final FirebaseFirestore? _firestoreOverride;
  final Connectivity _connectivity;
  FirebaseFirestore? _firestore;

  // Stream controllers
  final _receivedPacketsController =
      StreamController<MessagePacket>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();

  // Metrics
  TransportMetrics _metrics = const TransportMetrics();

  // Firestore listeners
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _isInitialized = false;
  bool _isOnline = false;
  String? _currentUserId;

  InternetTransport({FirebaseFirestore? firestore, Connectivity? connectivity})
    : _firestoreOverride = firestore,
      _connectivity = connectivity ?? Connectivity();

  @override
  TransportType get type => TransportType.internet;

  @override
  int get priority => 10; // Highest priority transport

  @override
  int get estimatedLatency => 500; // 500ms average

  @override
  bool get supportsEmergencyPriority => true;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Lazily obtain Firestore; in unit tests Firebase may not be initialized.
      try {
        _firestore = _firestoreOverride ?? FirebaseFirestore.instance;
      } catch (e) {
        // In unit tests/desktop runs without Firebase, keep transport unavailable.
        _firestore = null;
        debugPrint('⚠️ InternetTransport: Firestore unavailable: $e');
      }

      // Check initial connectivity
      try {
        final result = await _connectivity.checkConnectivity();
        _isOnline = !result.contains(ConnectivityResult.none);
      } catch (e) {
        _isOnline = false;
        debugPrint('⚠️ InternetTransport: Connectivity unavailable: $e');
      }

      // Listen to connectivity changes
      try {
        _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
          final wasOnline = _isOnline;
          _isOnline = !results.contains(ConnectivityResult.none);

          if (_isOnline && !wasOnline) {
            debugPrint('🌐 Internet transport: Online');
          } else if (!_isOnline && wasOnline) {
            debugPrint('📵 Internet transport: Offline');
          }

          _updateStatus();
        });
      } catch (e) {
        // No-op; transport will remain offline in tests.
        debugPrint('⚠️ InternetTransport: Connectivity stream unavailable: $e');
      }

      _isInitialized = true;
      debugPrint('✅ InternetTransport initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize InternetTransport: $e');
      rethrow;
    }
  }

  /// Set current user ID to filter incoming messages
  void setUserId(String userId) {
    _currentUserId = userId;
    _startListeningToMessages();
  }

  // ============================================================================
  // MESSAGE SENDING
  // ============================================================================

  @override
  Future<void> sendPacket(MessagePacket packet) async {
    if (!_isOnline) {
      throw Exception('Internet transport is offline');
    }

    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Internet transport unavailable (Firestore not initialized)');
    }

    final startTime = DateTime.now();

    try {
      // Store in Firestore 'messages' collection
      await firestore.collection('messages').doc(packet.messageId).set({
        'messageId': packet.messageId,
        'conversationId': packet.conversationId,
        'senderId': packet.senderId,
        'deviceId': packet.deviceId,
        'type': packet.type,
        'encryptedPayload': packet.encryptedPayload,
        'signature': packet.signature,
        'timestamp': packet.timestamp,
        'priority': packet.priority,
        'preferredTransport': packet.preferredTransport,
        'ttl': packet.ttl,
        'hopCount': packet.hopCount,
        'metadata': packet.metadata,
        'recipients': packet.recipients,
        'status': MessageStatus.sentInternet.name,
        'transportUsed': TransportType.internet.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update metrics
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      _metrics = _metrics.copyWith(
        messagesSent: _metrics.messagesSent + 1,
        averageLatency: (_metrics.averageLatency + latency) / 2,
        lastUsed: DateTime.now(),
        bytesTransferred:
            _metrics.bytesTransferred + packet.encryptedPayload.length,
      );

      debugPrint(
        '📤 Sent message via Internet: ${packet.messageId} (${latency}ms)',
      );
      _updateStatus();
    } catch (e) {
      _metrics = _metrics.copyWith(messagesFailed: _metrics.messagesFailed + 1);
      debugPrint('❌ Failed to send message via Internet: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MESSAGE RECEIVING
  // ============================================================================

  /// Start listening to messages from Firestore
  void _startListeningToMessages() {
    if (_currentUserId == null || _messagesSubscription != null) return;

    final firestore = _firestore;
    if (firestore == null) {
      return;
    }

    try {
      _messagesSubscription = firestore
          .collection('messages')
          .where('recipients', arrayContains: _currentUserId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  try {
                    final data = change.doc.data();
                    if (data != null) {
                      final packet = MessagePacket.fromJson(data);

                      // Don't receive our own messages
                      if (packet.senderId != _currentUserId) {
                        _receivedPacketsController.add(packet);

                        _metrics = _metrics.copyWith(
                          messagesReceived: _metrics.messagesReceived + 1,
                          lastUsed: DateTime.now(),
                        );

                        debugPrint(
                          '📨 Received message via Internet: ${packet.messageId}',
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('⚠️ Failed to parse received message: $e');
                  }
                }
              }
              _updateStatus();
            },
            onError: (error) {
              debugPrint('❌ Error listening to messages: $error');
            },
          );

      debugPrint('👂 Listening to messages for user: $_currentUserId');
    } catch (e) {
      debugPrint('❌ Failed to start listening to messages: $e');
    }
  }

  @override
  Stream<MessagePacket> get receivedPackets =>
      _receivedPacketsController.stream;

  // ============================================================================
  // STATUS & AVAILABILITY
  // ============================================================================

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) return false;
    return _isOnline;
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    return {
      'type': type.name,
      'available': _isOnline,
      'initialized': _isInitialized,
      'priority': priority,
      'latency': estimatedLatency,
      'metrics': {
        'messagesSent': _metrics.messagesSent,
        'messagesReceived': _metrics.messagesReceived,
        'messagesFailed': _metrics.messagesFailed,
        'averageLatency': _metrics.averageLatency,
        'lastUsed': _metrics.lastUsed?.toIso8601String(),
        'bytesTransferred': _metrics.bytesTransferred,
      },
    };
  }

  /// Update status stream
  void _updateStatus() {
    _statusController.add({
      'type': type.name,
      'available': _isOnline,
      'metrics': _metrics,
    });
  }

  /// Stream of transport status updates
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  Future<void> dispose() async {
    await _messagesSubscription?.cancel();
    await _connectivitySub?.cancel();
    await _receivedPacketsController.close();
    await _statusController.close();
    _isInitialized = false;
    debugPrint('👋 InternetTransport disposed');
  }

  // ============================================================================
  // LEGACY SUPPORT (For existing services)
  // ============================================================================

  /// Send to SOS sessions collection (legacy compatibility)
  Future<void> sendToSOSSession({
    required String sessionId,
    required Map<String, dynamic> messageData,
  }) async {
    if (!_isOnline) {
      throw Exception('Internet transport is offline');
    }

    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Internet transport unavailable (Firestore not initialized)');
    }

    try {
      await firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .collection('chat_messages')
          .add({...messageData, 'timestamp': FieldValue.serverTimestamp()});

      debugPrint('📤 Sent message to SOS session: $sessionId');
    } catch (e) {
      debugPrint('❌ Failed to send to SOS session: $e');
      rethrow;
    }
  }

  /// Listen to SOS session messages (legacy compatibility)
  Stream<List<Map<String, dynamic>>> listenToSOSSession(String sessionId) {
    final firestore = _firestore;
    if (firestore == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }

    return firestore
        .collection('sos_sessions')
        .doc(sessionId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }
}
