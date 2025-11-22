import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'location_service.dart';
import 'sar_identity_service.dart';
import 'user_profile_service.dart';
import 'notification_service.dart';
import 'emergency_messaging_service.dart';
import 'mock_firestore_service.dart';

/// Mock SOS ping service for local testing
class SOSPingServiceMock {
  static final SOSPingServiceMock _instance = SOSPingServiceMock._internal();
  factory SOSPingServiceMock() => _instance;
  SOSPingServiceMock._internal();

  final LocationService _locationService = LocationService();
  final SARIdentityService _sarIdentityService = SARIdentityService();
  final UserProfileService _userProfileService = UserProfileService();
  final NotificationService _notificationService = NotificationService();
  final EmergencyMessagingService _messagingService =
      EmergencyMessagingService();
  final MockFirestoreService _mockFirestore = MockFirestoreService();

  final List<Map<String, dynamic>> _activePings = [];
  final List<Map<String, dynamic>> _assignedPings = [];

  bool _isInitialized = false;
  Timer? _pingUpdateTimer;
  Timer? _locationUpdateTimer;

  // Callbacks
  Function(List<Map<String, dynamic>>)? _onActivePingsUpdated;

  /// Initialize the SOS ping service
  Future<void> initialize({String? sarMemberId}) async {
    if (_isInitialized) return;

    try {
      await _locationService.initialize();
      await _sarIdentityService.initialize();
      await _userProfileService.initialize();
      await _notificationService.initialize();
      await _messagingService.initialize();
      await _mockFirestore.initialize();

      // Start listening for new pings
      _startPingListener();

      // Start periodic updates
      _startPeriodicUpdates();

      _isInitialized = true;
      debugPrint('SOSPingServiceMock: Initialized successfully');
    } catch (e) {
      debugPrint('SOSPingServiceMock: Initialization failed - $e');
      rethrow;
    }
  }

  /// Start listening for new pings
  void _startPingListener() {
    _mockFirestore.collection('sos_pings').snapshots().listen((data) {
      try {
        // For mock service, we'll just log the data
        debugPrint('SOSPingServiceMock: Received ping data - $data');
        _updateActivePings();
      } catch (e) {
        debugPrint('SOSPingServiceMock: Error processing ping data - $e');
      }
    });
  }

  /// Start regional listener for cross-emulator communication
  Future<void> startRegionalListener({String? regionId}) async {
    try {
      debugPrint(
        'SOSPingServiceMock: Starting regional listener for region: ${regionId ?? 'default'}',
      );

      // Listen to regional pings collection
      _mockFirestore.collection('regional_pings').snapshots().listen((data) {
        try {
          debugPrint('SOSPingServiceMock: Received regional ping data - $data');
          _updateActivePings();
        } catch (e) {
          debugPrint('SOSPingServiceMock: Error processing regional ping - $e');
        }
      });
    } catch (e) {
      debugPrint('SOSPingServiceMock: Failed to start regional listener - $e');
    }
  }

  /// Create a test ping (for REDP!NG help requests)
  Future<void> createTestPing({
    bool isREDPINGHelp = false,
    String? helpCategory,
  }) async {
    try {
      final location = await _locationService.getCurrentLocation();
      final userProfile = _userProfileService.currentProfile;

      final pingId = isREDPINGHelp
          ? 'help_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}'
          : 'ping_${DateTime.now().millisecondsSinceEpoch}';

      // Create a simple ping data map for mock service
      final pingData = {
        'id': pingId,
        'userId':
            userProfile?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        'userName': userProfile?.name ?? 'Unknown User',
        'location': {
          'latitude': location?.latitude ?? 0.0,
          'longitude': location?.longitude ?? 0.0,
          'altitude': location?.altitude ?? 0.0,
          'accuracy': location?.accuracy ?? 0.0,
          'timestamp':
              location?.timestamp.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isREDPINGHelp': isREDPINGHelp,
        'helpCategory': helpCategory,
        'priority': isREDPINGHelp ? 'high' : 'medium',
        'status': 'pending',
        'description': isREDPINGHelp
            ? 'REDP!NG help request for $helpCategory'
            : 'SOS ping from ${userProfile?.name ?? 'Unknown User'}',
      };

      // Add to mock Firestore
      await _mockFirestore.collection('sos_pings').add(pingData);

      // Also add to regional pings for cross-emulator communication
      await _mockFirestore.collection('regional_pings').add(pingData);

      debugPrint(
        'SOSPingServiceMock: ${isREDPINGHelp ? 'REDP!NG help' : 'SOS'} ping created - $pingId',
      );

      // Show notification
      if (isREDPINGHelp) {
        await _notificationService.showNotification(
          title: 'REDP!NG Help Request Sent',
          body:
              'Your $helpCategory help request has been sent to nearby SAR teams',
          importance: NotificationImportance.high,
        );
      }
    } catch (e) {
      debugPrint('SOSPingServiceMock: Error creating test ping - $e');
      rethrow;
    }
  }

  /// Update active pings list
  void _updateActivePings() {
    // This would normally fetch from Firestore, but for mock we'll use local data
    _onActivePingsUpdated?.call(_activePings);
  }

  /// Start periodic updates
  void _startPeriodicUpdates() {
    _pingUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateActivePings();
    });

    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateSARMemberLocation();
    });
  }

  /// Update SAR member location
  Future<void> _updateSARMemberLocation() async {
    try {
      // Update location (mock implementation)
      await _locationService.getCurrentLocation();
    } catch (e) {
      debugPrint(
        'SOSPingServiceMock: Failed to update SAR member location - $e',
      );
    }
  }

  /// Get active pings
  List<Map<String, dynamic>> getActivePings() => List.from(_activePings);

  /// Get assigned pings
  List<Map<String, dynamic>> getAssignedPings() => List.from(_assignedPings);

  /// Set callbacks
  void setOnActivePingsUpdated(Function(List<Map<String, dynamic>>) callback) {
    _onActivePingsUpdated = callback;
  }

  /// Send message to SAR (mock implementation)
  Future<void> sendMessageToSAR({
    required String pingId,
    required String message,
    String? sarMemberId,
  }) async {
    try {
      debugPrint('SOSPingServiceMock: Sending message to SAR - $message');
      // Mock implementation - just log the message
      await _notificationService.showNotification(
        title: 'Message Sent to SAR',
        body: 'Your message has been sent to SAR teams',
        importance: NotificationImportance.high,
      );
    } catch (e) {
      debugPrint('SOSPingServiceMock: Error sending message to SAR - $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _pingUpdateTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _mockFirestore.dispose();
  }
}
