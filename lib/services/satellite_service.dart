import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sos_session.dart';
import '../models/user_profile.dart';
import 'user_profile_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'connectivity_monitor_service.dart';

/// Service for satellite communication integration
class SatelliteService {
  // Track hibernation state
  bool _isHibernating = false;
  static final SatelliteService _instance = SatelliteService._internal();
  factory SatelliteService() => _instance;
  SatelliteService._internal();

  final UserProfileService _userProfileService = UserProfileService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  // Platform channels for native satellite integration
  static const MethodChannel _satelliteChannel = MethodChannel(
    'redping/satellite',
  );
  static const EventChannel _satelliteStatusChannel = EventChannel(
    'redping/satellite_status',
  );

  // Satellite state
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _hasPermission = false;
  bool _isAvailable = false;
  bool _isConnected = false;
  bool _sosActive = false; // Track if SOS is currently active
  SatelliteConnectionType _connectionType = SatelliteConnectionType.none;
  double _signalStrength = 0.0;

  // Message queue for satellite transmission
  final List<SatelliteMessage> _messageQueue = [];
  Timer? _connectionMonitor;
  Timer? _messageProcessor;

  // Callbacks
  Function(bool)? _onConnectionChanged;
  Function(SatelliteMessage)? _onMessageSent;
  Function(SatelliteMessage)? _onMessageReceived;
  Function(double)? _onSignalStrengthChanged;

  /// Initialize satellite service
  Future<void> initialize({bool sosActive = false}) async {
    if (_isInitialized) return;

    try {
      // Initialize connectivity monitor
      await ConnectivityMonitorService().initialize();
      ConnectivityMonitorService().offlineStream.listen((isOffline) {
        if (isOffline && sosActive) {
          // Only start monitoring and processing when offline AND SOS is active
          _startConnectionMonitoring();
          _startMessageProcessing();
          _isHibernating = false;
        } else {
          // Stop satellite operations when online or SOS not active
          _connectionMonitor?.cancel();
          _messageProcessor?.cancel();
          _isHibernating = true;
        }
      });

      // Check device satellite capability
      await _checkSatelliteCapability(sosActive: sosActive);

      // Request permissions
      await _requestSatellitePermissions();

      // Load saved settings
      await _loadSettings();

      // Set up platform channel listeners
      _setupPlatformChannels();

      _isInitialized = true;
      AppLogger.i('Initialized successfully', tag: 'SatelliteService');
    } catch (e) {
      AppLogger.w('Initialization error', tag: 'SatelliteService', error: e);
      // Don't throw - satellite is optional feature
    }
  }

  /// Hibernate satellite service (pause all updates and timers)
  void hibernate() {
    _connectionMonitor?.cancel();
    _messageProcessor?.cancel();
    _isHibernating = true;
    _sosActive = false;
    AppLogger.i(
      'SatelliteService hibernated: all timers and updates paused',
      tag: 'SatelliteService',
    );
  }

  /// Wake satellite service (resume if needed)
  void wake({bool sosActive = false, bool isOffline = false}) {
    _sosActive = sosActive;
    if (sosActive && isOffline) {
      _startConnectionMonitoring();
      _startMessageProcessing();
      _isHibernating = false;
      AppLogger.i(
        'SatelliteService woken: timers resumed',
        tag: 'SatelliteService',
      );
    }
  }

  /// Activate satellite service for SOS
  void activateForSOS() {
    _sosActive = true;
    AppLogger.i(
      'SatelliteService: Activated for SOS emergency',
      tag: 'SatelliteService',
    );
  }

  /// Deactivate satellite service when SOS ends
  void deactivateFromSOS() {
    _sosActive = false;
    AppLogger.i(
      'SatelliteService: Deactivated - SOS ended',
      tag: 'SatelliteService',
    );
  }

  /// Check if device supports satellite communication

  Future<void> _checkSatelliteCapability({bool sosActive = false}) async {
    try {
      if (Platform.isIOS) {
        // Check for iPhone 14+ with satellite capability
        await _satelliteChannel.invokeMethod('checkSatelliteCapability');
      }

      // Mark satellite features available when capability check does not throw
      _isAvailable = true;

      // Only start connection monitoring and message processing if:
      // - No network AND SOS activated
      final results = await Connectivity().checkConnectivity();
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline && sosActive) {
        _startConnectionMonitoring();
        _startMessageProcessing();
      }
      // Otherwise, stay in standby mode to save battery

      // Do not set _isInitialized here, only in initialize()
    } catch (e) {
      AppLogger.w(
        'Error checking satellite capability',
        tag: 'SatelliteService',
        error: e,
      );
      _isAvailable = false;
    }
  }

  /// Request satellite communication permissions
  Future<void> _requestSatellitePermissions() async {
    if (!_isAvailable) return;

    try {
      // Request location permission (required for satellite)
      final locationPermission = await Permission.location.request();

      // Request emergency services permission (iOS)
      if (Platform.isIOS) {
        final emergencyPermission = await _requestiOSEmergencyPermission();
        _hasPermission = locationPermission.isGranted && emergencyPermission;
      } else {
        _hasPermission = locationPermission.isGranted;
      }

      debugPrint('SatelliteService: Permissions granted: $_hasPermission');
    } catch (e) {
      debugPrint('SatelliteService: Error requesting permissions - $e');
      _hasPermission = false;
    }
  }

  /// Send emergency SOS via satellite
  Future<bool> sendEmergencySOS({
    required SOSSession session,
    String? customMessage,
  }) async {
    if (!_canUseSatellite()) {
      throw Exception('Satellite communication not available');
    }

    try {
      final userProfile = _userProfileService.currentProfile;

      // Create compressed emergency message
      final message = SatelliteMessage(
        id: _generateMessageId(),
        type: SatelliteMessageType.emergency,
        priority: SatelliteMessagePriority.critical,
        content: _createEmergencyMessage(session, userProfile, customMessage),
        location: session.location,
        timestamp: DateTime.now(),
        sessionId: session.id,
      );

      // Queue message for transmission
      _messageQueue.insert(0, message); // High priority at front

      // Attempt immediate transmission
      final success = await _transmitMessage(message);

      if (success) {
        await _notificationService.showNotification(
          title: '🛰️ Emergency SOS Sent via Satellite',
          body:
              'Your emergency alert has been transmitted via satellite communication.',
          importance: NotificationImportance.high,
          persistent: true,
        );
      } else {
        await _notificationService.showNotification(
          title: '🛰️ Satellite SOS Queued',
          body:
              'Emergency message queued for satellite transmission when signal available.',
          importance: NotificationImportance.high,
        );
      }

      debugPrint(
        'SatelliteService: Emergency SOS sent via satellite - Success: $success',
      );
      return success;
    } catch (e) {
      debugPrint('SatelliteService: Error sending satellite SOS - $e');
      return false;
    }
  }

  /// Send location update via satellite
  Future<bool> sendLocationUpdate(LocationInfo location) async {
    if (!_canUseSatellite()) return false;

    try {
      final userProfile = _userProfileService.currentProfile;

      final message = SatelliteMessage(
        id: _generateMessageId(),
        type: SatelliteMessageType.location,
        priority: SatelliteMessagePriority.normal,
        content: _createLocationMessage(location, userProfile),
        location: location,
        timestamp: DateTime.now(),
      );

      _messageQueue.add(message);
      return await _transmitMessage(message);
    } catch (e) {
      debugPrint('SatelliteService: Error sending location update - $e');
      return false;
    }
  }

  /// Send custom message via satellite
  Future<bool> sendCustomMessage({
    required String message,
    SatelliteMessagePriority priority = SatelliteMessagePriority.normal,
  }) async {
    if (!_canUseSatellite()) return false;

    try {
      final location = await _locationService.getCurrentLocation();
      final userProfile = _userProfileService.currentProfile;

      final satelliteMessage = SatelliteMessage(
        id: _generateMessageId(),
        type: SatelliteMessageType.text,
        priority: priority,
        content: _createCustomMessage(message, userProfile),
        location: location,
        timestamp: DateTime.now(),
      );

      _messageQueue.add(satelliteMessage);
      return await _transmitMessage(satelliteMessage);
    } catch (e) {
      debugPrint('SatelliteService: Error sending custom message - $e');
      return false;
    }
  }

  /// Create emergency message for satellite transmission
  String _createEmergencyMessage(
    SOSSession session,
    UserProfile? userProfile,
    String? customMessage,
  ) {
    final buffer = StringBuffer();

    // Header (keep short for satellite)
    buffer.write('🚨 EMERGENCY SOS 🚨\n');

    // Person identification (critical)
    if (userProfile?.name.isNotEmpty == true) {
      buffer.write('Person: ${userProfile!.name}\n');
    }
    if (userProfile?.phoneNumber?.isNotEmpty == true) {
      buffer.write('Phone: ${userProfile!.phoneNumber}\n');
    }

    // Emergency details
    buffer.write('Type: ${_getShortSOSType(session.type)}\n');
    buffer.write('Time: ${_formatSatelliteTime(session.startTime)}\n');

    // Critical medical info (space-efficient)
    if (userProfile != null) {
      if (userProfile.bloodType?.isNotEmpty == true) {
        buffer.write('Blood: ${userProfile.bloodType}\n');
      }
      if (userProfile.allergies.isNotEmpty) {
        buffer.write(
          '⚠️ Allergies: ${userProfile.allergies.take(2).join(', ')}\n',
        );
      }
    }

    // Location (precise GPS)
    final loc = session.location;
    buffer.write(
      'GPS: ${loc.latitude.toStringAsFixed(6)},${loc.longitude.toStringAsFixed(6)}\n',
    );
    buffer.write('Accuracy: ±${loc.accuracy.toStringAsFixed(0)}m\n');

    // Custom message
    if (customMessage?.isNotEmpty == true) {
      buffer.write('Msg: $customMessage\n');
    }

    // Session reference
    buffer.write('ID: ${session.id}');

    return buffer.toString();
  }

  /// Create location message for satellite
  String _createLocationMessage(
    LocationInfo location,
    UserProfile? userProfile,
  ) {
    final buffer = StringBuffer();

    buffer.write('📍 LOCATION UPDATE\n');
    if (userProfile?.name.isNotEmpty == true) {
      buffer.write('${userProfile!.name}\n');
    }
    buffer.write(
      'GPS: ${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}\n',
    );
    buffer.write('Time: ${_formatSatelliteTime(location.timestamp)}\n');
    buffer.write('Accuracy: ±${location.accuracy.toStringAsFixed(0)}m');

    return buffer.toString();
  }

  /// Create custom message for satellite
  String _createCustomMessage(String message, UserProfile? userProfile) {
    final buffer = StringBuffer();

    if (userProfile?.name.isNotEmpty == true) {
      buffer.write('${userProfile!.name}: ');
    }
    buffer.write(message);

    return buffer.toString();
  }

  /// Transmit message via satellite
  Future<bool> _transmitMessage(SatelliteMessage message) async {
    if (!_isConnected) {
      debugPrint('SatelliteService: No satellite connection - message queued');
      return false;
    }

    try {
      if (Platform.isIOS) {
        return await _transmitViaiOS(message);
      } else if (Platform.isAndroid) {
        return await _transmitViaAndroid(message);
      }
      return false;
    } catch (e) {
      debugPrint('SatelliteService: Error transmitting message - $e');
      return false;
    }
  }

  /// Transmit via iOS satellite emergency features
  Future<bool> _transmitViaiOS(SatelliteMessage message) async {
    try {
      final result = await _satelliteChannel.invokeMethod(
        'sendEmergencyMessage',
        {
          'message': message.content,
          'priority': message.priority.index,
          'location': {
            'latitude': message.location?.latitude,
            'longitude': message.location?.longitude,
            'accuracy': message.location?.accuracy,
          },
          'timestamp': message.timestamp.millisecondsSinceEpoch,
        },
      );

      final success = result['success'] ?? false;
      if (success) {
        _onMessageSent?.call(message);
        _removeFromQueue(message.id);
      }

      return success;
    } catch (e) {
      debugPrint('SatelliteService: iOS transmission error - $e');
      return false;
    }
  }

  /// Transmit via Android satellite features (future implementation)
  Future<bool> _transmitViaAndroid(SatelliteMessage message) async {
    try {
      // Android satellite communication implementation
      // This would integrate with future Android satellite APIs

      final result = await _satelliteChannel
          .invokeMethod('sendSatelliteMessage', {
            'message': message.content,
            'type': message.type.name,
            'priority': message.priority.name,
            'location': message.location?.toJson(),
            'timestamp': message.timestamp.millisecondsSinceEpoch,
          });

      final success = result['success'] ?? false;
      if (success) {
        _onMessageSent?.call(message);
        _removeFromQueue(message.id);
      }

      return success;
    } catch (e) {
      debugPrint('SatelliteService: Android transmission error - $e');
      return false;
    }
  }

  /// Check Android satellite support

  /// Request iOS emergency permission
  Future<bool> _requestiOSEmergencyPermission() async {
    try {
      final result = await _satelliteChannel.invokeMethod(
        'requestEmergencyPermission',
      );
      return result['granted'] ?? false;
    } catch (e) {
      debugPrint('SatelliteService: iOS emergency permission error - $e');
      return false;
    }
  }

  /// Setup platform channel listeners
  void _setupPlatformChannels() {
    // Listen to satellite status changes
    _satelliteStatusChannel.receiveBroadcastStream().listen(
      (event) {
        _handleSatelliteStatusUpdate(event);
      },
      onError: (error) {
        debugPrint('SatelliteService: Status channel error - $error');
      },
    );

    // Set up method call handler for incoming messages
    _satelliteChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle satellite status updates from platform
  void _handleSatelliteStatusUpdate(dynamic event) {
    try {
      final data = Map<String, dynamic>.from(event);

      final wasConnected = _isConnected;
      _isConnected = data['isConnected'] ?? false;
      _signalStrength = (data['signalStrength'] ?? 0.0).toDouble();
      _connectionType = _parseConnectionType(data['connectionType']);

      // Notify listeners of connection changes
      if (wasConnected != _isConnected) {
        _onConnectionChanged?.call(_isConnected);

        if (_isConnected) {
          _notificationService.showNotification(
            title: '🛰️ Satellite Connected',
            body: 'Emergency satellite communication is now available.',
            importance: NotificationImportance.defaultImportance,
          );

          // Process queued messages
          _processQueuedMessages();
        } else {
          _notificationService.showNotification(
            title: '🛰️ Satellite Disconnected',
            body:
                'Satellite communication unavailable. Messages will be queued.',
            importance: NotificationImportance.defaultImportance,
          );
        }
      }

      _onSignalStrengthChanged?.call(_signalStrength);
      // Suppress status update logs to avoid terminal spam
      // (Satellite service only activates when actually needed - offline + SOS)
      // Status updates come from native channel and can't be stopped,
      // so we just don't log them unless actively using satellite
      if (_isConnected && _sosActive) {
        // Only log when actually connected to satellite during SOS
        debugPrint(
          'SatelliteService: Status update - Connected: $_isConnected, Signal: $_signalStrength',
        );
      }
    } catch (e) {
      debugPrint('SatelliteService: Error handling status update - $e');
    }
  }

  /// Handle method calls from platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMessageReceived':
        _handleIncomingMessage(call.arguments);
        break;
      case 'onTransmissionComplete':
        _handleTransmissionComplete(call.arguments);
        break;
      case 'onSatelliteError':
        _handleSatelliteError(call.arguments);
        break;
      default:
        debugPrint('SatelliteService: Unknown method call - ${call.method}');
    }
  }

  /// Handle incoming satellite message
  void _handleIncomingMessage(dynamic data) {
    try {
      final messageData = Map<String, dynamic>.from(data);
      final message = SatelliteMessage.fromJson(messageData);

      _onMessageReceived?.call(message);

      // Show notification for received message
      _notificationService.showNotification(
        title: '🛰️ Satellite Message Received',
        body: message.content,
        importance: message.priority == SatelliteMessagePriority.critical
            ? NotificationImportance.max
            : NotificationImportance.high,
      );

      debugPrint(
        'SatelliteService: Message received via satellite - ${message.id}',
      );
    } catch (e) {
      debugPrint('SatelliteService: Error handling incoming message - $e');
    }
  }

  /// Handle transmission completion
  void _handleTransmissionComplete(dynamic data) {
    try {
      final messageId = data['messageId'] as String;
      final success = data['success'] as bool;

      if (success) {
        _removeFromQueue(messageId);
        debugPrint(
          'SatelliteService: Message transmitted successfully - $messageId',
        );
      } else {
        debugPrint(
          'SatelliteService: Message transmission failed - $messageId',
        );
      }
    } catch (e) {
      debugPrint('SatelliteService: Error handling transmission complete - $e');
    }
  }

  /// Handle satellite errors
  void _handleSatelliteError(dynamic data) {
    try {
      final error = data['error'] as String;

      debugPrint('SatelliteService: Satellite error - $error');

      _notificationService.showNotification(
        title: '🛰️ Satellite Communication Error',
        body: error,
        importance: NotificationImportance.high,
      );
    } catch (e) {
      debugPrint('SatelliteService: Error handling satellite error - $e');
    }
  }

  /// Start monitoring satellite connection (only when needed)
  void _startConnectionMonitoring() {
    // Cancel existing timer
    _connectionMonitor?.cancel();

    // Only start if enabled and has permission
    if (!_isEnabled || !_hasPermission || _isHibernating) {
      debugPrint(
        'SatelliteService: Connection monitoring not started (enabled: $_isEnabled, permission: $_hasPermission, hibernating: $_isHibernating)',
      );
      return;
    }

    debugPrint('SatelliteService: Starting connection monitoring');
    _connectionMonitor = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      if (_isEnabled && _hasPermission && !_isHibernating) {
        await _checkSatelliteConnection();
      }
    });
  }

  /// Start processing message queue (only when needed)
  void _startMessageProcessing() {
    // Cancel existing timer
    _messageProcessor?.cancel();

    // Only start if connected and has messages
    if (!_isConnected || _isHibernating) {
      debugPrint(
        'SatelliteService: Message processing not started (connected: $_isConnected, hibernating: $_isHibernating)',
      );
      return;
    }

    debugPrint('SatelliteService: Starting message processing');
    _messageProcessor = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) async {
      if (_isConnected && _messageQueue.isNotEmpty && !_isHibernating) {
        await _processQueuedMessages();
      }
    });
  }

  /// Check current satellite connection status
  Future<void> _checkSatelliteConnection() async {
    try {
      final result = await _satelliteChannel.invokeMethod('checkConnection');
      final wasConnected = _isConnected;

      _isConnected = result['isConnected'] ?? false;
      _signalStrength = (result['signalStrength'] ?? 0.0).toDouble();

      if (wasConnected != _isConnected) {
        _onConnectionChanged?.call(_isConnected);
      }

      _onSignalStrengthChanged?.call(_signalStrength);
    } catch (e) {
      debugPrint('SatelliteService: Error checking connection - $e');
      _isConnected = false;
    }
  }

  /// Process queued messages
  Future<void> _processQueuedMessages() async {
    if (_messageQueue.isEmpty || !_isConnected) return;

    try {
      // Process high priority messages first
      _messageQueue.sort(
        (a, b) => b.priority.index.compareTo(a.priority.index),
      );

      final messagesToProcess = _messageQueue
          .take(3)
          .toList(); // Limit to 3 per batch

      for (final message in messagesToProcess) {
        final success = await _transmitMessage(message);
        if (success) {
          _removeFromQueue(message.id);
        }

        // Add delay between satellite transmissions
        await Future.delayed(const Duration(seconds: 5));
      }

      debugPrint(
        'SatelliteService: Processed ${messagesToProcess.length} queued messages',
      );
    } catch (e) {
      debugPrint('SatelliteService: Error processing queued messages - $e');
    }
  }

  /// Remove message from queue
  void _removeFromQueue(String messageId) {
    _messageQueue.removeWhere((msg) => msg.id == messageId);
    _saveMessageQueue();
  }

  /// Load saved settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('satellite_enabled') ?? false;

      // Load message queue
      final queueJson = prefs.getString('satellite_message_queue') ?? '[]';
      final queueList = jsonDecode(queueJson) as List;
      _messageQueue
        ..clear()
        ..addAll(queueList.map((json) => SatelliteMessage.fromJson(json)));

      debugPrint(
        'SatelliteService: Loaded ${_messageQueue.length} queued messages',
      );
    } catch (e) {
      debugPrint('SatelliteService: Error loading settings - $e');
    }
  }

  /// Save message queue
  Future<void> _saveMessageQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(
        _messageQueue.map((msg) => msg.toJson()).toList(),
      );
      await prefs.setString('satellite_message_queue', queueJson);
    } catch (e) {
      debugPrint('SatelliteService: Error saving message queue - $e');
    }
  }

  /// Save settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('satellite_enabled', _isEnabled);
    } catch (e) {
      debugPrint('SatelliteService: Error saving settings - $e');
    }
  }

  /// Helper methods
  bool _canUseSatellite() {
    return _isInitialized && _isAvailable && _hasPermission && _isEnabled;
  }

  SatelliteConnectionType _parseConnectionType(dynamic type) {
    if (type == null) return SatelliteConnectionType.none;

    switch (type.toString().toLowerCase()) {
      case 'emergency':
        return SatelliteConnectionType.emergency;
      case 'messaging':
        return SatelliteConnectionType.messaging;
      case 'data':
        return SatelliteConnectionType.data;
      default:
        return SatelliteConnectionType.none;
    }
  }

  String _getShortSOSType(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual';
      case SOSType.crashDetection:
        return 'Crash';
      case SOSType.fallDetection:
        return 'Fall';
      case SOSType.panicButton:
        return 'Panic';
      case SOSType.voiceCommand:
        return 'Voice';
      default:
        return 'Emergency';
    }
  }

  String _formatSatelliteTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} ${local.day}/${local.month}';
  }

  String _generateMessageId() {
    return 'SAT_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get isEnabled => _isEnabled;
  bool get hasPermission => _hasPermission;
  bool get isConnected => _isConnected;
  double get signalStrength => _signalStrength;
  SatelliteConnectionType get connectionType => _connectionType;
  int get queuedMessageCount => _messageQueue.length;
  bool get canSendEmergency =>
      _canUseSatellite() && _connectionType != SatelliteConnectionType.none;

  // Setters
  set isEnabled(bool enabled) {
    _isEnabled = enabled;
    _saveSettings();

    if (!enabled) {
      // Clear message queue when disabled
      _messageQueue.clear();
      _saveMessageQueue();
    }
  }

  // Event handlers

  void setConnectionChangedCallback(Function(bool) callback) {
    _onConnectionChanged = callback;
  }

  void setMessageSentCallback(Function(SatelliteMessage) callback) {
    _onMessageSent = callback;
  }

  void setMessageReceivedCallback(Function(SatelliteMessage) callback) {
    _onMessageReceived = callback;
  }

  void setSignalStrengthChangedCallback(Function(double) callback) {
    _onSignalStrengthChanged = callback;
  }

  /// Dispose of the service
  void dispose() {
    _connectionMonitor?.cancel();
    _messageProcessor?.cancel();
  }
}

/// Satellite message model
class SatelliteMessage {
  final String id;
  final SatelliteMessageType type;
  final SatelliteMessagePriority priority;
  final String content;
  final LocationInfo? location;
  final DateTime timestamp;
  final String? sessionId;
  final bool isTransmitted;
  final DateTime? transmittedAt;

  const SatelliteMessage({
    required this.id,
    required this.type,
    required this.priority,
    required this.content,
    this.location,
    required this.timestamp,
    this.sessionId,
    this.isTransmitted = false,
    this.transmittedAt,
  });

  factory SatelliteMessage.fromJson(Map<String, dynamic> json) {
    return SatelliteMessage(
      id: json['id'],
      type: SatelliteMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SatelliteMessageType.text,
      ),
      priority: SatelliteMessagePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => SatelliteMessagePriority.normal,
      ),
      content: json['content'],
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['sessionId'],
      isTransmitted: json['isTransmitted'] ?? false,
      transmittedAt: json['transmittedAt'] != null
          ? DateTime.parse(json['transmittedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'content': content,
      'location': location?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'isTransmitted': isTransmitted,
      'transmittedAt': transmittedAt?.toIso8601String(),
    };
  }

  SatelliteMessage copyWith({bool? isTransmitted, DateTime? transmittedAt}) {
    return SatelliteMessage(
      id: id,
      type: type,
      priority: priority,
      content: content,
      location: location,
      timestamp: timestamp,
      sessionId: sessionId,
      isTransmitted: isTransmitted ?? this.isTransmitted,
      transmittedAt: transmittedAt ?? this.transmittedAt,
    );
  }
}

/// Satellite connection types
enum SatelliteConnectionType {
  none,
  emergency, // Emergency SOS only (iPhone 14+)
  messaging, // Two-way messaging
  data, // Full data communication
}

/// Satellite message types
enum SatelliteMessageType { emergency, location, text, status }

/// Satellite message priorities
enum SatelliteMessagePriority { low, normal, high, critical }
