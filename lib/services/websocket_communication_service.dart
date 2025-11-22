import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/google_cloud_config.dart';

/// WebSocket service for real-time communication with REDP!NG website
class WebSocketCommunicationService {
  static final WebSocketCommunicationService _instance =
      WebSocketCommunicationService._internal();
  factory WebSocketCommunicationService() => _instance;
  WebSocketCommunicationService._internal();

  bool _isInitialized = false;
  WebSocketChannel? _sosAlertsChannel;
  WebSocketChannel? _sarCoordinationChannel;

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Connection status
  bool _isSosAlertsConnected = false;
  bool _isSarCoordinationConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? _onSosAlertReceived;
  Function(Map<String, dynamic>)? _onSarMessageReceived;
  Function(String, dynamic)? _onError;

  /// Initialize WebSocket connections
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('WebSocketCommunicationService: Initializing...');

    // Connect to SOS alerts WebSocket
    await _connectSosAlerts();

    // Connect to SAR coordination WebSocket
    await _connectSarCoordination();

    _isInitialized = true;
    debugPrint('WebSocketCommunicationService: Initialized successfully');
  }

  /// Connect to SOS alerts WebSocket
  Future<void> _connectSosAlerts() async {
    try {
      final url = GoogleCloudConfig.getWebSocketUrl('/ws/sos-alerts');
      _sosAlertsChannel = WebSocketChannel.connect(Uri.parse(url));

      // Listen for messages
      _sosAlertsChannel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _onSosAlertReceived?.call(message);
          } catch (e) {
            debugPrint(
              'WebSocketCommunicationService: Failed to parse SOS alert - $e',
            );
          }
        },
        onError: (error) {
          _isSosAlertsConnected = false;
          _onError?.call('SOS_ALERTS_WEBSOCKET_ERROR', error);
          _scheduleReconnect();
        },
        onDone: () {
          _isSosAlertsConnected = false;
          _scheduleReconnect();
        },
      );

      _isSosAlertsConnected = true;
      debugPrint(
        'WebSocketCommunicationService: SOS alerts WebSocket connected',
      );
    } catch (e) {
      _isSosAlertsConnected = false;
      debugPrint(
        'WebSocketCommunicationService: Failed to connect SOS alerts WebSocket - $e',
      );
    }
  }

  /// Connect to SAR coordination WebSocket
  Future<void> _connectSarCoordination() async {
    try {
      final url = GoogleCloudConfig.getWebSocketUrl('/ws/sar-coordination');
      _sarCoordinationChannel = WebSocketChannel.connect(Uri.parse(url));

      // Listen for messages
      _sarCoordinationChannel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _onSarMessageReceived?.call(message);
          } catch (e) {
            debugPrint(
              'WebSocketCommunicationService: Failed to parse SAR message - $e',
            );
          }
        },
        onError: (error) {
          _isSarCoordinationConnected = false;
          _onError?.call('SAR_COORDINATION_WEBSOCKET_ERROR', error);
          _scheduleReconnect();
        },
        onDone: () {
          _isSarCoordinationConnected = false;
          _scheduleReconnect();
        },
      );

      _isSarCoordinationConnected = true;
      debugPrint(
        'WebSocketCommunicationService: SAR coordination WebSocket connected',
      );
    } catch (e) {
      _isSarCoordinationConnected = false;
      debugPrint(
        'WebSocketCommunicationService: Failed to connect SAR coordination WebSocket - $e',
      );
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), () {
      if (!_isSosAlertsConnected) {
        _connectSosAlerts();
      }
      if (!_isSarCoordinationConnected) {
        _connectSarCoordination();
      }
    });
  }

  /// Send SOS alert via WebSocket
  Future<void> sendSosAlert(Map<String, dynamic> alert) async {
    if (!_isSosAlertsConnected || _sosAlertsChannel == null) {
      debugPrint(
        'WebSocketCommunicationService: SOS alerts WebSocket not connected',
      );
      return;
    }

    try {
      _sosAlertsChannel!.sink.add(
        jsonEncode({
          'type': 'sos_alert',
          'data': alert,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint(
        'WebSocketCommunicationService: Failed to send SOS alert - $e',
      );
    }
  }

  /// Send SAR coordination message
  Future<void> sendSarMessage(Map<String, dynamic> message) async {
    if (!_isSarCoordinationConnected || _sarCoordinationChannel == null) {
      debugPrint(
        'WebSocketCommunicationService: SAR coordination WebSocket not connected',
      );
      return;
    }

    try {
      _sarCoordinationChannel!.sink.add(
        jsonEncode({
          'type': 'sar_message',
          'data': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint(
        'WebSocketCommunicationService: Failed to send SAR message - $e',
      );
    }
  }

  /// Send location update
  Future<void> sendLocationUpdate(
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    if (!_isSosAlertsConnected || _sosAlertsChannel == null) {
      return;
    }

    try {
      _sosAlertsChannel!.sink.add(
        jsonEncode({
          'type': 'location_update',
          'data': {
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );
    } catch (e) {
      debugPrint(
        'WebSocketCommunicationService: Failed to send location update - $e',
      );
    }
  }

  /// Set SOS alert callback
  void setSosAlertCallback(Function(Map<String, dynamic>) callback) {
    _onSosAlertReceived = callback;
  }

  /// Set SAR message callback
  void setSarMessageCallback(Function(Map<String, dynamic>) callback) {
    _onSarMessageReceived = callback;
  }

  /// Set error callback
  void setErrorCallback(Function(String, dynamic) callback) {
    _onError = callback;
  }

  /// Get connection status
  bool get isSosAlertsConnected => _isSosAlertsConnected;
  bool get isSarCoordinationConnected => _isSarCoordinationConnected;
  bool get isAnyConnected =>
      _isSosAlertsConnected || _isSarCoordinationConnected;

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isSosAlertsConnected': _isSosAlertsConnected,
      'isSarCoordinationConnected': _isSarCoordinationConnected,
      'isAnyConnected': isAnyConnected,
    };
  }

  /// Dispose of resources
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _sosAlertsChannel?.sink.close(status.goingAway);
    _sarCoordinationChannel?.sink.close(status.goingAway);
    _isInitialized = false;
    _isSosAlertsConnected = false;
    _isSarCoordinationConnected = false;
  }
}
