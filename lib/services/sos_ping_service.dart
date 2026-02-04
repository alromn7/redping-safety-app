// ignore_for_file: unused_element
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/google_cloud_config.dart';
import '../models/sos_ping.dart';
import '../models/sos_session.dart' hide MessageType;
import '../models/emergency_message.dart'
    show EmergencyMessage, MessageType, MessagePriority, MessageStatus;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'location_service.dart';
import 'sar_identity_service.dart';
import 'user_profile_service.dart';
import 'notification_service.dart';
import 'emergency_messaging_service.dart';
import '../core/logging/app_logger.dart';

/// Service for managing SOS pings visible to SAR members
class SOSPingService {
  static final SOSPingService _instance = SOSPingService._internal();
  factory SOSPingService() => _instance;
  SOSPingService._internal();

  final LocationService _locationService = LocationService();
  final SARIdentityService _sarIdentityService = SARIdentityService();
  final UserProfileService _userProfileService = UserProfileService();
  final NotificationService _notificationService = NotificationService();
  final EmergencyMessagingService _messagingService =
      EmergencyMessagingService();

  List<SOSPing> _activePings = [];
  List<SOSPing> _assignedPings = [];
  String? _currentSARMemberId;
  LocationInfo? _sarMemberLocation;

  bool _isInitialized = false;
  Timer? _pingUpdateTimer;
  Timer? _locationUpdateTimer;

  // Callbacks
  Function(List<SOSPing>)? _onActivePingsUpdated;
  Function(List<SOSPing>)? _onAssignedPingsUpdated;
  Function(SOSPing)? _onNewPingReceived;
  Function(SOSPing, SARResponse)? _onResponseUpdated;

  /// Initialize the SOS ping service
  Future<void> initialize({String? sarMemberId}) async {
    if (_isInitialized) return;

    try {
      // Run all service initializations in parallel
      await Future.wait([
        _locationService.initialize(),
        _sarIdentityService.initialize(),
        // _userProfileService.initialize(), // Temporarily disabled
        _notificationService.initialize(),
        _messagingService.initialize(),
      ]);

      // Set current SAR member
      _currentSARMemberId = sarMemberId;
      if (_currentSARMemberId == null) {
        // Try to infer from registered members
        try {
          final members = _sarIdentityService.registeredMembers;
          _currentSARMemberId = members.isNotEmpty
              ? members.first.userId
              : null;
        } catch (_) {}
      }

      if (_currentSARMemberId == null) {
        AppLogger.w(
          'No SAR member ID available, operating in demo mode',
          tag: 'SOSPingService',
        );
        // Use a demo SAR member ID for testing purposes
        _currentSARMemberId = 'demo_sar_member_001';
      }

      // Load saved data (demo ping generation disabled - using real pings only)
      await _loadSavedPings();

      // Clear old dummy pings from storage
      await _clearOldDummyPings();

      // Note: Demo pings removed. Real pings are created via:
      // - createPingFromSession() for SOS emergency
      // - createHelpPing() for REDP!NG help requests
      // - Manual testing via createTestPing() when needed

      // Start periodic updates (not awaited)
      _startPingUpdates();
      _startLocationUpdates();

      // Start Firestore regional listener for cross-emulator communication
      await startRegionalListener();

      _isInitialized = true;
      AppLogger.i(
        'Initialized for SAR member $_currentSARMemberId',
        tag: 'SOSPingService',
      );
    } catch (e) {
      AppLogger.e('Initialization error', tag: 'SOSPingService', error: e);
      throw Exception('Failed to initialize SOS ping service: $e');
    }
  }

  /// Get all active SOS pings in the area
  List<SOSPing> getActivePings({
    double? maxDistance,
    List<String>? priorities,
    List<String>? riskLevels,
  }) {
    var filteredPings = _activePings
        .where((ping) => ping.status == SOSPingStatus.active)
        .toList();

    // Show all pings in regional coverage (including self-created for testing)
    // This allows SAR teams to see all emergencies in their coverage area
    final currentUserProfile = _userProfileService.currentProfile;
    AppLogger.d(
      'Regional coverage - showing all pings. Current user: ${currentUserProfile?.id ?? 'unknown'}, Available pings: ${filteredPings.length}',
      tag: 'SOSPingService',
    );
    AppLogger.d(
      'Pings in coverage - ${filteredPings.map((p) => '${p.id}:${p.userId}:${p.userName}').join(', ')}',
      tag: 'SOSPingService',
    );

    // Filter by distance
    if (maxDistance != null && _sarMemberLocation != null) {
      filteredPings = filteredPings.where((ping) {
        final distance = _calculateDistance(_sarMemberLocation!, ping.location);
        return distance <= maxDistance;
      }).toList();
    }

    // Filter by priority
    if (priorities != null && priorities.isNotEmpty) {
      filteredPings = filteredPings
          .where((ping) => priorities.contains(ping.priority.name))
          .toList();
    }

    // Filter by risk level
    if (riskLevels != null && riskLevels.isNotEmpty) {
      filteredPings = filteredPings
          .where((ping) => riskLevels.contains(ping.riskLevel.name))
          .toList();
    }

    // Sort by priority and time
    filteredPings.sort((a, b) {
      // Critical first
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;

      // Then by time (oldest first)
      return a.timestamp.compareTo(b.timestamp);
    });

    return filteredPings;
  }

  /// Get pings assigned to current SAR member
  List<SOSPing> getAssignedPings() {
    if (_currentSARMemberId == null) return [];

    return _assignedPings
        .where((ping) => ping.isAssignedTo(_currentSARMemberId!))
        .toList();
  }

  /// Respond to a SOS ping
  Future<SARResponse> respondToPing({
    required String pingId,
    required SARResponseType responseType,
    String? message,
    int? estimatedArrivalTime,
    List<String>? availableEquipment,
    List<String>? teamMembers,
    String? vehicleType,
  }) async {
    if (_currentSARMemberId == null) {
      throw Exception('No SAR member ID available');
    }

    final ping = _activePings.firstWhere(
      (p) => p.id == pingId,
      orElse: () => throw Exception('SOS ping not found'),
    );

    final sarIdentity = _sarIdentityService.getSARMemberByUserId(
      _currentSARMemberId!,
    );
    final sarMemberName = sarIdentity?.personalInfo.firstName ?? 'SAR Member';

    final response = SARResponse(
      id: _generateResponseId(),
      sarMemberId: _currentSARMemberId!,
      sarMemberName: sarMemberName,
      responseType: responseType,
      responseTime: DateTime.now(),
      message: message,
      estimatedArrivalTime: estimatedArrivalTime,
      currentLocation: _sarMemberLocation,
      availableEquipment: availableEquipment ?? [],
      teamMembers: teamMembers ?? [],
      vehicleType: vehicleType,
      status: SARResponseStatus.pending,
    );

    // Update ping with response
    final updatedPing = ping.copyWith(
      sarResponses: [...ping.sarResponses, response],
      assignedSARMembers: responseType == SARResponseType.available
          ? [...ping.assignedSARMembers, _currentSARMemberId!]
          : ping.assignedSARMembers,
      status: responseType == SARResponseType.available
          ? SOSPingStatus.assigned
          : ping.status,
    );

    // Update in lists
    final activeIndex = _activePings.indexWhere((p) => p.id == pingId);
    if (activeIndex != -1) {
      _activePings[activeIndex] = updatedPing;
    }

    if (responseType == SARResponseType.available) {
      _assignedPings.add(updatedPing);
    }

    // Save and notify
    await _savePings();
    _onResponseUpdated?.call(updatedPing, response);
    _onActivePingsUpdated?.call(_activePings);
    _onAssignedPingsUpdated?.call(_assignedPings);

    // Send notification to user
    await _notifyUser(updatedPing, response);

    AppLogger.i('Response sent for ping $pingId', tag: 'SOSPingService');
    return response;
  }

  /// Update response status (e.g., en route, on scene)
  Future<void> updateResponseStatus({
    required String pingId,
    required SARResponseStatus status,
    String? message,
  }) async {
    if (_currentSARMemberId == null) return;

    final pingIndex = _assignedPings.indexWhere((p) => p.id == pingId);
    if (pingIndex == -1) return;

    final ping = _assignedPings[pingIndex];
    final responseIndex = ping.sarResponses.indexWhere(
      (r) => r.sarMemberId == _currentSARMemberId!,
    );

    if (responseIndex == -1) return;

    final updatedResponse = ping.sarResponses[responseIndex].copyWith(
      status: status,
      message: message,
    );

    final updatedResponses = List<SARResponse>.from(ping.sarResponses);
    updatedResponses[responseIndex] = updatedResponse;

    final updatedPing = ping.copyWith(
      sarResponses: updatedResponses,
      status: status == SARResponseStatus.onScene
          ? SOSPingStatus.inProgress
          : ping.status,
    );

    _assignedPings[pingIndex] = updatedPing;
    await _savePings();

    _onAssignedPingsUpdated?.call(_assignedPings);
    AppLogger.i(
      'Response status updated for ping $pingId',
      tag: 'SOSPingService',
    );
  }

  /// Mark rescue as completed
  Future<void> completeRescue({
    required String pingId,
    String? completionNotes,
  }) async {
    if (_currentSARMemberId == null) return;

    final pingIndex = _assignedPings.indexWhere((p) => p.id == pingId);
    if (pingIndex == -1) return;

    final ping = _assignedPings[pingIndex];
    final updatedPing = ping.copyWith(
      status: SOSPingStatus.resolved,
      metadata: {
        ...ping.metadata,
        'completedBy': _currentSARMemberId!,
        'completionTime': DateTime.now().toIso8601String(),
        'completionNotes': completionNotes ?? '',
      },
    );

    _assignedPings[pingIndex] = updatedPing;

    // Remove from active pings
    _activePings.removeWhere((p) => p.id == pingId);

    await _savePings();
    _onAssignedPingsUpdated?.call(_assignedPings);
    _onActivePingsUpdated?.call(_activePings);

    AppLogger.i('Rescue completed for ping $pingId', tag: 'SOSPingService');
  }

  /// Mark ping as resolved by session ID (called when user resolves SOS)
  Future<void> resolvePingBySessionId(String sessionId) async {
    debugPrint(
      'SOSPingService: Marking ping as resolved for session $sessionId',
    );

    // Find the ping with matching session ID
    final pingIndex = _activePings.indexWhere((p) => p.sessionId == sessionId);
    if (pingIndex == -1) {
      debugPrint('SOSPingService: No active ping found for session $sessionId');
      return;
    }

    final ping = _activePings[pingIndex];
    final updatedPing = ping.copyWith(
      status: SOSPingStatus.resolved,
      metadata: {
        ...ping.metadata,
        'resolvedBy': 'user',
        'resolutionTime': DateTime.now().toIso8601String(),
        'resolutionMethod': '5-second button press',
      },
    );

    // Remove from active pings
    _activePings.removeAt(pingIndex);

    // Update Firestore if allowed
    if (GoogleCloudConfig.allowClientSOSPingWrites) {
      try {
        await _publishPingToFirestore(updatedPing);
        AppLogger.d(
          'Ping ${ping.id} marked as resolved in Firestore',
          tag: 'SOSPingService',
        );
      } catch (e) {
        AppLogger.w(
          'Failed to update ping in Firestore',
          tag: 'SOSPingService',
          error: e,
        );
      }
    }

    await _savePings();
    _onActivePingsUpdated?.call(_activePings);

    AppLogger.i(
      'Ping ${ping.id} marked as resolved for session $sessionId',
      tag: 'SOSPingService',
    );
  }

  /// Create SOS ping from SOS session (REAL EMERGENCY - NO TEST DISCLAIMER)
  Future<SOSPing> createPingFromSession(SOSSession session) async {
    debugPrint(
      'SOSPingService: Creating REAL SOS ping from session ${session.id} for user ${session.userId}',
    );

    final userProfile = _userProfileService.currentProfile;
    debugPrint(
      'SOSPingService: Current user profile: ${userProfile?.id}, Session user: ${session.userId}',
    );

    final ping = SOSPing(
      id: _generatePingId(),
      sessionId: session.id,
      userId: session.userId,
      userName: userProfile?.name ?? 'Unknown User',
      userPhone: userProfile?.phoneNumber ?? 'Unknown Phone',
      type: session.type,
      priority: _assessPriority(session),
      timestamp: session.startTime,
      location: session.location,
      userMessage:
          session.userMessage ??
          'Emergency SOS activated', // REAL emergency - no test disclaimer
      medicalConditions: userProfile?.medicalConditions ?? [],
      allergies: userProfile?.allergies ?? [],
      bloodType: userProfile?.bloodType,
      estimatedAge: userProfile?.dateOfBirth != null
          ? DateTime.now().difference(userProfile!.dateOfBirth!).inDays ~/ 365
          : userProfile?.age,
      gender: userProfile?.gender,
      impactInfo: session.impactInfo,
      status: SOSPingStatus.active,
      accessibilityLevel: _assessAccessibility(session.location),
      requiredEquipment: _determineRequiredEquipment(session),
      estimatedRescueTime: _estimateRescueTime(session),
      riskLevel: _assessRiskLevel(session),
    );

    _activePings.add(ping);
    debugPrint(
      '🚨 REAL EMERGENCY: Added SOS ping to active list. Total active pings: ${_activePings.length}',
    );

    await _savePings();
    AppLogger.d('Saved real emergency ping to storage', tag: 'SOSPingService');

    // Publish to Firestore for cross-emulator communication
    if (GoogleCloudConfig.allowClientSOSPingWrites) {
      try {
        await _publishPingToFirestore(ping);
        AppLogger.d(
          'Real SOS ping published to Firestore regional_pings',
          tag: 'SOSPingService',
        );
      } catch (e) {
        AppLogger.w(
          'Firestore publish failed (will retry)',
          tag: 'SOSPingService',
          error: e,
        );
      }
    } else {
      AppLogger.d(
        'Client write to sos_pings disabled by config',
        tag: 'SOSPingService',
      );
    }

    _onNewPingReceived?.call(ping);
    _onActivePingsUpdated?.call(_activePings);
    AppLogger.d('Real emergency callbacks triggered', tag: 'SOSPingService');

    debugPrint(
      '🚨 REAL EMERGENCY PING CREATED: Session ${session.id}, Ping ${ping.id}, User: ${ping.userName}',
    );
    return ping;
  }

  /// Add testing disclaimer to user message
  String _addTestingDisclaimer(String? originalMessage) {
    const testingDisclaimer = '[TESTING ONLY - No action required]';

    if (originalMessage == null || originalMessage.isEmpty) {
      return '$testingDisclaimer Emergency SOS activated for testing purposes.';
    }

    return '$testingDisclaimer $originalMessage';
  }

  /// Generate demo SOS pings for testing (DISABLED - using real pings only)
  Future<void> _generateDemoPings() async {
    // DISABLED: No longer auto-generating demo pings
    // Real pings are created via createPingFromSession() and createHelpPing()
    debugPrint(
      'SOSPingService: Demo ping generation disabled - waiting for real pings',
    );
    return;

    // Old demo generation code kept for reference:
    /* if (_activePings.isNotEmpty) return;

    final now = DateTime.now();
    final demoLocation = LocationInfo(
      latitude: 37.4219999,
      longitude: -122.0840575,
      accuracy: 10.0,
      timestamp: now,
      address: 'Stanford University, CA',
    );

    final demoPings = [
      SOSPing(
        id: 'ping_001',
        sessionId: 'session_001',
        userId: 'user_001',
        userName: 'Alice Johnson',
        userPhone: '+1-555-0101',
        type: SOSType.fallDetection,
        priority: SOSPriority.high,
        timestamp: now.subtract(const Duration(minutes: 5)),
        location: demoLocation.copyWith(
          latitude: demoLocation.latitude + 0.001,
          address: 'Hiking Trail, Stanford Hills',
        ),
        userMessage: _addTestingDisclaimer('Fell while hiking, ankle injury'),
        medicalConditions: ['Diabetes'],
        allergies: ['Penicillin'],
        bloodType: 'O+',
        estimatedAge: 34,
        status: SOSPingStatus.active,
        accessibilityLevel: AccessibilityLevel.moderate,
        requiredEquipment: ['First Aid Kit', 'Stretcher'],
        estimatedRescueTime: 25,
        riskLevel: RiskLevel.medium,
        terrainType: 'Mountainous',
        weatherConditions: 'Clear, 72°F',
      ),
      SOSPing(
        id: 'ping_002',
        sessionId: 'session_002',
        userId: 'user_002',
        userName: 'Bob Smith',
        userPhone: '+1-555-0102',
        type: SOSType.manual,
        priority: SOSPriority.critical,
        timestamp: now.subtract(const Duration(minutes: 2)),
        location: demoLocation.copyWith(
          latitude: demoLocation.latitude - 0.002,
          longitude: demoLocation.longitude + 0.001,
          address: 'Lake Lagunita, Stanford',
        ),
        userMessage: _addTestingDisclaimer('Chest pain, difficulty breathing'),
        medicalConditions: ['Heart Disease', 'Hypertension'],
        allergies: [],
        bloodType: 'A-',
        estimatedAge: 58,
        status: SOSPingStatus.active,
        accessibilityLevel: AccessibilityLevel.easy,
        requiredEquipment: ['AED', 'Oxygen', 'Ambulance'],
        estimatedRescueTime: 15,
        riskLevel: RiskLevel.critical,
        terrainType: 'Flat',
        weatherConditions: 'Clear, 72°F',
      ),
      SOSPing(
        id: 'ping_003',
        sessionId: 'session_003',
        userId: 'user_003',
        userName: 'Carol Davis',
        userPhone: '+1-555-0103',
        type: SOSType.crashDetection,
        priority: SOSPriority.high,
        timestamp: now.subtract(const Duration(minutes: 12)),
        location: demoLocation.copyWith(
          latitude: demoLocation.latitude + 0.003,
          longitude: demoLocation.longitude - 0.002,
          address: 'Campus Drive, Stanford',
        ),
        userMessage: _addTestingDisclaimer(
          'Bike accident, possible concussion',
        ),
        medicalConditions: [],
        allergies: ['Aspirin'],
        bloodType: 'B+',
        estimatedAge: 28,
        status: SOSPingStatus.active,
        accessibilityLevel: AccessibilityLevel.easy,
        requiredEquipment: ['First Aid Kit', 'Neck Brace'],
        estimatedRescueTime: 20,
        riskLevel: RiskLevel.medium,
        terrainType: 'Urban',
        weatherConditions: 'Clear, 72°F',
      ),
    ];

    _activePings.addAll(demoPings);
    await _savePings();
    _onActivePingsUpdated?.call(_activePings);

    debugPrint('SOSPingService: Demo pings generated');
    */
  }

  /// Start periodic ping updates
  void _startPingUpdates() {
    _pingUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updatePingDistances();
      _checkExpiredPings();
    });
  }

  /// Start location updates
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) async {
      try {
        _sarMemberLocation = await _locationService.getCurrentLocation();
        _updatePingDistances();
      } catch (e) {
        debugPrint('SOSPingService: Error updating location - $e');
      }
    });
  }

  /// Update distances for all pings
  void _updatePingDistances() {
    if (_sarMemberLocation == null) return;

    for (int i = 0; i < _activePings.length; i++) {
      final distance = _calculateDistance(
        _sarMemberLocation!,
        _activePings[i].location,
      );
      _activePings[i] = _activePings[i].copyWith(distanceFromSAR: distance);
    }

    _onActivePingsUpdated?.call(_activePings);
  }

  /// Check for expired pings
  void _checkExpiredPings() {
    final now = DateTime.now();
    bool hasExpired = false;

    for (int i = 0; i < _activePings.length; i++) {
      final ping = _activePings[i];
      final elapsed = now.difference(ping.timestamp);

      // Mark as expired after 2 hours for non-critical, 4 hours for critical
      final expirationTime = ping.priority == SOSPriority.critical
          ? const Duration(hours: 4)
          : const Duration(hours: 2);

      if (elapsed > expirationTime && ping.status == SOSPingStatus.active) {
        _activePings[i] = ping.copyWith(status: SOSPingStatus.expired);
        hasExpired = true;
      }
    }

    if (hasExpired) {
      _onActivePingsUpdated?.call(_activePings);
    }
  }

  /// Calculate distance between two locations (in kilometers)
  double _calculateDistance(LocationInfo from, LocationInfo to) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1Rad = from.latitude * pi / 180;
    final lat2Rad = to.latitude * pi / 180;
    final deltaLatRad = (to.latitude - from.latitude) * pi / 180;
    final deltaLonRad = (to.longitude - from.longitude) * pi / 180;

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Assess priority based on SOS session
  SOSPriority _assessPriority(SOSSession session) {
    if (session.impactInfo?.severity == ImpactSeverity.critical) {
      return SOSPriority.critical;
    }

    if (session.type == SOSType.crashDetection ||
        session.type == SOSType.fallDetection) {
      return SOSPriority.high;
    }

    return SOSPriority.medium;
  }

  /// Assess accessibility level
  AccessibilityLevel _assessAccessibility(LocationInfo location) {
    // This would use terrain analysis, road access, etc.
    // For demo, return moderate
    return AccessibilityLevel.moderate;
  }

  /// Determine required equipment
  List<String> _determineRequiredEquipment(SOSSession session) {
    final equipment = <String>['First Aid Kit'];

    if (session.type == SOSType.crashDetection) {
      equipment.addAll(['Neck Brace', 'Stretcher']);
    }

    if (session.type == SOSType.fallDetection) {
      equipment.add('Stretcher');
    }

    return equipment;
  }

  /// Estimate rescue time
  int _estimateRescueTime(SOSSession session) {
    // Base time + complexity factors
    int baseTime = 20; // minutes

    if (session.impactInfo?.severity == ImpactSeverity.critical) {
      baseTime = 15;
    }

    return baseTime;
  }

  /// Assess risk level
  RiskLevel _assessRiskLevel(SOSSession session) {
    if (session.impactInfo?.severity == ImpactSeverity.critical) {
      return RiskLevel.critical;
    }

    if (session.type == SOSType.crashDetection) {
      return RiskLevel.high;
    }

    return RiskLevel.medium;
  }

  /// Notify user about SAR response
  Future<void> _notifyUser(SOSPing ping, SARResponse response) async {
    try {
      await _notificationService.showNotification(
        title: '🚁 SAR Response',
        body: '${response.sarMemberName} is responding to your emergency',
        importance: NotificationImportance.high,
      );
    } catch (e) {
      debugPrint('SOSPingService: Error sending user notification - $e');
    }
  }

  /// Save pings to storage
  Future<void> _savePings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final activePingsJson = _activePings.map((p) => p.toJson()).toList();
      final assignedPingsJson = _assignedPings.map((p) => p.toJson()).toList();

      await prefs.setString('active_pings', jsonEncode(activePingsJson));
      await prefs.setString('assigned_pings', jsonEncode(assignedPingsJson));
    } catch (e) {
      debugPrint('SOSPingService: Error saving pings - $e');
    }
  }

  /// Load saved pings
  Future<void> _loadSavedPings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final activePingsJson = prefs.getString('active_pings');
      final assignedPingsJson = prefs.getString('assigned_pings');

      if (activePingsJson != null) {
        final List<dynamic> activeList = jsonDecode(activePingsJson);
        _activePings = activeList
            .map((json) => SOSPing.fromJson(json))
            .toList();
        debugPrint(
          'SOSPingService: Loaded ${_activePings.length} active pings from storage',
        );
      }

      if (assignedPingsJson != null) {
        final List<dynamic> assignedList = jsonDecode(assignedPingsJson);
        _assignedPings = assignedList
            .map((json) => SOSPing.fromJson(json))
            .toList();
        debugPrint(
          'SOSPingService: Loaded ${_assignedPings.length} assigned pings from storage',
        );
      }
    } catch (e) {
      debugPrint('SOSPingService: Error loading saved pings - $e');
    }
  }

  /// Clear old dummy pings from previous sessions
  Future<void> _clearOldDummyPings() async {
    try {
      // Remove pings with dummy IDs (ping_001, ping_002, ping_003)
      final dummyIds = ['ping_001', 'ping_002', 'ping_003'];

      // Also remove any pings with test disclaimers
      final beforeCount = _activePings.length;
      _activePings.removeWhere(
        (ping) =>
            dummyIds.contains(ping.id) ||
            (ping.userMessage?.contains(
                  '[TESTING ONLY - No action required]',
                ) ??
                false),
      );
      final removedCount = beforeCount - _activePings.length;

      if (removedCount > 0) {
        await _savePings();
        _onActivePingsUpdated?.call(_activePings);
        debugPrint(
          'SOSPingService: Cleared $removedCount old dummy pings from storage',
        );
      } else {
        debugPrint('SOSPingService: No old dummy pings found - storage clean');
      }
    } catch (e) {
      debugPrint('SOSPingService: Error clearing dummy pings - $e');
    }
  }

  /// PUBLIC: Clear all stored pings (useful for fresh start)
  Future<void> clearAllStoredPings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_pings');
      await prefs.remove('assigned_pings');

      _activePings.clear();
      _assignedPings.clear();

      _onActivePingsUpdated?.call(_activePings);
      _onAssignedPingsUpdated?.call(_assignedPings);

      debugPrint('SOSPingService: ✅ All stored pings cleared - fresh start');
    } catch (e) {
      debugPrint('SOSPingService: Error clearing all pings - $e');
    }
  }

  /// Generate unique ping ID
  String _generatePingId() {
    return 'ping_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// Generate unique response ID
  String _generateResponseId() {
    return 'response_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Event callbacks
  void setActivePingsUpdatedCallback(Function(List<SOSPing>) callback) {
    _onActivePingsUpdated = callback;
  }

  void setAssignedPingsUpdatedCallback(Function(List<SOSPing>) callback) {
    _onAssignedPingsUpdated = callback;
  }

  void setNewPingReceivedCallback(Function(SOSPing) callback) {
    _onNewPingReceived = callback;
  }

  void setResponseUpdatedCallback(Function(SOSPing, SARResponse) callback) {
    _onResponseUpdated = callback;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentSARMemberId => _currentSARMemberId;
  LocationInfo? get sarMemberLocation => _sarMemberLocation;

  int get activeCount =>
      _activePings.where((p) => p.status == SOSPingStatus.active).length;

  int get assignedCount => _assignedPings
      .where((p) => p.isAssignedTo(_currentSARMemberId ?? ''))
      .length;

  /// Create a dedicated REDP!NG help ping (non-test)
  /// Also publishes to Firestore for regional coverage
  Future<SOSPing> createHelpPing({
    required String category,
    String? userMessage,
  }) async {
    final now = DateTime.now();

    // Ensure we have a location, fall back gracefully with timeout
    LocationInfo? loc;
    try {
      loc = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('SOSPingService: Location timeout, using fallback');
          return null;
        },
      );
    } catch (e) {
      debugPrint('SOSPingService: Location error, using fallback - $e');
    }

    var location =
        loc ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: now,
          address: 'Unknown',
        );

    // Best-effort reverse geocoding to provide address for website display
    try {
      if (location.latitude != 0.0 || location.longitude != 0.0) {
        final placemarks = await geocoding
            .placemarkFromCoordinates(location.latitude, location.longitude)
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
          final addr = parts.join(', ');
          location = location.copyWith(address: addr);
        }
      }
    } catch (_) {}

    final profile = _userProfileService.currentProfile;
    final userId = profile?.id ?? 'redping_user_${now.millisecondsSinceEpoch}';
    final userName = profile?.name ?? 'REDP!NG User';
    final userPhone = profile?.phoneNumber ?? 'Not provided';

    // Map category to priority/risk
    SOSPriority priority;
    RiskLevel risk;
    switch (category) {
      case 'domestic_violence':
        priority = SOSPriority.critical;
        risk = RiskLevel.critical;
        break;
      case 'home_breakin':
        priority = SOSPriority.critical;
        risk = RiskLevel.high;
        break;
      case 'fall_accident':
        priority = SOSPriority.high;
        risk = RiskLevel.medium;
        break;
      case 'car_breakdown':
        priority = SOSPriority.medium;
        risk = RiskLevel.low;
        break;
      case 'theft':
        priority = SOSPriority.low;
        risk = RiskLevel.low;
        break;
      case 'lost_pets':
        priority = SOSPriority.low;
        risk = RiskLevel.low;
        break;
      default:
        priority = SOSPriority.low;
        risk = RiskLevel.low;
        break;
    }

    final defaultMessage = () {
      switch (category) {
        case 'domestic_violence':
          return 'REDP!NG Help: Immediate safety concern at home';
        case 'home_breakin':
          return 'REDP!NG Help: Suspected/confirmed break-in';
        case 'fall_accident':
          return 'REDP!NG Help: Fall injury reported';
        case 'car_breakdown':
          return 'REDP!NG Help: Vehicle disabled';
        case 'theft':
          return 'REDP!NG Help: Theft reported';
        case 'lost_pets':
          return 'REDP!NG Help: Lost pet assistance';
        default:
          return 'REDP!NG Help request';
      }
    }();

    final ping = SOSPing(
      id: 'help_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}',
      sessionId: 'help_session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      type: SOSType.manual,
      priority: priority,
      timestamp: now,
      location: location,
      userMessage:
          userMessage ??
          defaultMessage, // REAL REDP!NG help request - no test disclaimer
      medicalConditions: profile?.medicalConditions ?? [],
      allergies: profile?.allergies ?? [],
      bloodType: profile?.bloodType,
      estimatedAge: profile?.dateOfBirth != null
          ? DateTime.now().difference(profile!.dateOfBirth!).inDays ~/ 365
          : null,
      status: SOSPingStatus.active,
      accessibilityLevel: AccessibilityLevel.moderate,
      requiredEquipment: const ['Basic First Aid'],
      estimatedRescueTime: 25,
      riskLevel: risk,
      metadata: {'requestType': 'redping_help', 'helpCategory': category},
    );

    _activePings.add(ping);
    await _savePings();

    // Publish to Firestore for cross-emulator communication
    try {
      // Align with website: create a help_requests document for real-time dashboard
      try {
        final helpDoc = <String, dynamic>{
          'userId': userId,
          'userName': userName,
          'categoryId': category,
          'description': ping.userMessage,
          'priority': _priorityToString(priority),
          'status': 'active',
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'accuracy': location.accuracy,
            'timestamp': FieldValue.serverTimestamp(),
            'address': location.address,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await FirebaseFirestore.instance
            .collection('help_requests')
            .doc(ping.id)
            .set(helpDoc, SetOptions(merge: true));
      } catch (e) {
        debugPrint('SOSPingService: Failed to write help_requests: $e');
      }

      await _publishPingToFirestore(ping);
      debugPrint(
        'SOSPingService: REDP!NG help ping published to Firestore sos_pings',
      );
    } catch (e) {
      debugPrint('SOSPingService: Firestore publish failed (will retry): $e');
    }

    _onNewPingReceived?.call(ping);
    _onActivePingsUpdated?.call(_activePings);

    debugPrint(
      'SOSPingService: REAL REDP!NG help ping created and broadcast - ${ping.id}',
    );
    return ping;
  }

  String _priorityToString(SOSPriority p) {
    switch (p) {
      case SOSPriority.critical:
        return 'critical';
      case SOSPriority.high:
        return 'high';
      case SOSPriority.medium:
        return 'medium';
      case SOSPriority.low:
        return 'low';
    }
  }

  /// Start Firestore regional listener (subscribe to regional coverage)
  Future<void> startRegionalListener({String regionId = 'default'}) async {
    try {
      // Don't call initialize() here - it creates infinite loop when called from initialize()
      if (!_isInitialized) {
        debugPrint(
          'SOSPingService: Cannot start listener - service not initialized',
        );
        return;
      }

      FirebaseFirestore.instance
          .collection('sos_pings')
          .where('regionId', isEqualTo: regionId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen((snapshot) {
            bool changed = false;
            for (final doc in snapshot.docs) {
              try {
                final data = doc.data();
                final ping = SOSPing.fromJson(data);
                final index = _activePings.indexWhere((p) => p.id == ping.id);
                if (index >= 0) {
                  _activePings[index] = ping;
                } else {
                  _activePings.add(ping);
                }
                changed = true;
              } catch (e) {
                debugPrint(
                  'SOSPingService: Failed to parse Firestore ping: $e',
                );
              }
            }
            if (changed) {
              _onActivePingsUpdated?.call(_activePings);
              // Notify about new pings for cross-emulator communication
              for (final doc in snapshot.docs) {
                try {
                  final data = doc.data();
                  final ping = SOSPing.fromJson(data);
                  final existingIndex = _activePings.indexWhere(
                    (p) => p.id == ping.id,
                  );
                  if (existingIndex == -1) {
                    // This is a new ping from another emulator
                    _onNewPingReceived?.call(ping);
                  }
                } catch (e) {
                  debugPrint('SOSPingService: Failed to notify new ping: $e');
                }
              }
            }
          });
      debugPrint('SOSPingService: Regional Firestore listener started');
    } catch (e) {
      debugPrint('SOSPingService: Failed to start Firestore listener: $e');
    }
  }

  Future<void> _publishPingToFirestore(
    SOSPing ping, {
    String regionId = 'default',
  }) async {
    final doc = FirebaseFirestore.instance.collection('sos_pings').doc(ping.id);
    try {
      final json = ping.toJson();
      json['regionId'] = regionId;

      // Validate and clean JSON data to prevent Firestore errors
      _cleanFirestoreData(json);

      await doc.set(json, SetOptions(merge: true));
      debugPrint('Firestore write OK for pingId=${ping.id}');
    } catch (e, st) {
      debugPrint('Firestore write FAILED for pingId=${ping.id}: $e\n$st');
      // Continue without Firestore to prevent app crashes
    }
  }

  /// Clean Firestore data to prevent serialization errors
  void _cleanFirestoreData(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is double) {
        if (value.isNaN || value.isInfinite) {
          debugPrint(
            'SOSPingService: Cleaning invalid double value for key $key: $value',
          );
          data[key] = 0.0; // Replace with safe default
        }
      } else if (value is Map<String, dynamic>) {
        _cleanFirestoreData(value); // Recursively clean nested maps
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _cleanFirestoreData(value[i]);
          } else if (value[i] is double) {
            final doubleVal = value[i] as double;
            if (doubleVal.isNaN || doubleVal.isInfinite) {
              debugPrint(
                'SOSPingService: Cleaning invalid double value in list at index $i: $doubleVal',
              );
              value[i] = 0.0;
            }
          }
        }
      }
    });
  }

  /// MANUAL TEST ONLY: Create a test ping for development/testing
  /// This is NOT called automatically - only when explicitly testing
  Future<void> createTestPing({
    bool isREDPINGHelp = false,
    String? helpCategory,
  }) async {
    final now = DateTime.now();
    final testLocation = LocationInfo(
      latitude: 37.4219999,
      longitude: -122.0840575,
      accuracy: 10.0,
      timestamp: now,
      address: 'Test Location',
    );

    // Create scenarios based on type
    late List<Map<String, dynamic>> scenarios;

    if (isREDPINGHelp && helpCategory != null) {
      // REDP!NG Help scenarios
      scenarios = _getREDPINGHelpScenarios(helpCategory);
    } else {
      // Emergency scenarios
      scenarios = [
        {
          'name': 'Sarah Martinez',
          'phone': '+1-555-0142',
          'message': 'Hiking accident - twisted ankle, cannot walk',
          'conditions': ['Diabetes'],
          'allergies': ['Bee stings'],
          'age': 28,
          'risk': RiskLevel.medium,
          'terrain': 'Mountain Trail',
          'weather': 'Overcast, 15°C',
          'priority': SOSPriority.high,
        },
        {
          'name': 'Mike Johnson',
          'phone': '+1-555-0198',
          'message': 'Car accident - vehicle off road, minor injuries',
          'conditions': ['Hypertension'],
          'allergies': ['Penicillin'],
          'age': 45,
          'risk': RiskLevel.high,
          'terrain': 'Highway',
          'weather': 'Rain, 12°C',
          'priority': SOSPriority.high,
        },
        {
          'name': 'Emma Chen',
          'phone': '+1-555-0176',
          'message': 'Lost while camping - low on supplies',
          'conditions': [],
          'allergies': ['Peanuts'],
          'age': 32,
          'risk': RiskLevel.low,
          'terrain': 'Forest',
          'weather': 'Clear, 18°C',
          'priority': SOSPriority.medium,
        },
      ];
    }

    final random = Random();
    final scenario = scenarios[random.nextInt(scenarios.length)];

    final pingPrefix = isREDPINGHelp ? 'redping_help' : 'regional_emergency';

    // Use actual user data for REDP!NG requests, random data for test emergencies
    String userId, userName, userPhone;
    if (isREDPINGHelp) {
      // Prefer actual profile when available
      final profile = _userProfileService.currentProfile;
      if (profile != null) {
        userId = profile.id;
        userName = profile.name;
        userPhone = profile.phoneNumber ?? 'Not provided';
      } else {
        // Fallback to mock map profile
        try {
          final mock = await _getUserProfile();
          if (mock is Map<String, dynamic>) {
            userId =
                (mock['id'] as String?) ??
                'redping_user_${DateTime.now().millisecondsSinceEpoch}';
            userName = (mock['name'] as String?) ?? 'REDP!NG User';
            userPhone = (mock['phone'] as String?) ?? 'Not provided';
          } else {
            userId = 'redping_user_${DateTime.now().millisecondsSinceEpoch}';
            userName = 'REDP!NG User';
            userPhone = 'Not provided';
          }
        } catch (e) {
          userId = 'redping_user_${DateTime.now().millisecondsSinceEpoch}';
          userName = 'REDP!NG User';
          userPhone = 'Not provided';
        }
      }
    } else {
      userId = 'user_${random.nextInt(9999).toString().padLeft(4, '0')}';
      userName = scenario['name'] as String;
      userPhone = scenario['phone'] as String;
    }

    final String testNote = 'TEST PING ONLY - NO ACTION REQUIRED';
    final testPing = SOSPing(
      id: '${pingPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      type: SOSType.manual,
      priority: scenario['priority'] as SOSPriority,
      timestamp: now,
      location: testLocation,
      userMessage: '${scenario['message']}\n\n$testNote',
      medicalConditions: (scenario['conditions'] as List<dynamic>)
          .cast<String>(),
      allergies: (scenario['allergies'] as List<dynamic>).cast<String>(),
      bloodType: 'O+',
      estimatedAge: scenario['age'] as int,
      status: SOSPingStatus.active,
      accessibilityLevel: AccessibilityLevel.moderate,
      requiredEquipment: ['Medical Kit', 'GPS Device'],
      estimatedRescueTime: 25,
      riskLevel: scenario['risk'] as RiskLevel,
      terrainType: scenario['terrain'] as String,
      weatherConditions: scenario['weather'] as String,
      metadata: {
        'testNote': testNote,
        if (isREDPINGHelp) 'requestType': 'redping_help',
        if (isREDPINGHelp && helpCategory != null) 'helpCategory': helpCategory,
      },
    );

    _activePings.add(testPing);
    await _savePings();

    _onNewPingReceived?.call(testPing);
    _onActivePingsUpdated?.call(_activePings);

    final pingType = isREDPINGHelp
        ? 'REDP!NG help request'
        : 'Regional emergency';
    debugPrint(
      'SOSPingService: $pingType created - ${testPing.userName} (${testPing.id}). '
      'Message: ${testPing.userMessage}. Available to all SAR teams in coverage area.',
    );
  }

  /// Send message from SAR member to civilian
  Future<EmergencyMessage> sendMessageToCivilian({
    required String pingId,
    required String content,
    MessageType type = MessageType.sarResponse,
  }) async {
    if (_currentSARMemberId == null) {
      throw Exception('No SAR member ID available');
    }

    final ping = _findPingById(pingId);
    if (ping == null) {
      throw Exception('SOS ping not found');
    }

    final sarIdentity = _sarIdentityService.getSARMemberByUserId(
      _currentSARMemberId!,
    );
    final sarMemberName = sarIdentity?.personalInfo.firstName ?? 'SAR Member';

    final message = EmergencyMessage(
      id: _generateMessageId(),
      senderId: _currentSARMemberId!,
      senderName: sarMemberName,
      content: content,
      recipients: [ping.userId],
      timestamp: DateTime.now(),
      priority: MessagePriority.high,
      type: type,
      status: MessageStatus.sent,
      isRead: false,
      metadata: {
        'pingId': pingId,
        'sarMemberId': _currentSARMemberId!,
        'messageSource': 'sar_to_civilian',
      },
    );

    // Add message to ping
    final updatedPing = ping.copyWith(messages: [...ping.messages, message]);

    _updatePingInLists(updatedPing);
    await _savePings();

    // Send via emergency messaging service to civilian
    try {
      await _messagingService.receiveMessageFromSAR(
        senderId: _currentSARMemberId!,
        senderName: sarMemberName,
        content: content,
        priority: MessagePriority.high,
        type: type,
        metadata: {
          'pingId': pingId,
          'sarMemberId': _currentSARMemberId!,
          'messageSource': 'sar_to_civilian',
        },
      );
      debugPrint(
        'SOSPingService: Message sent via emergency messaging service',
      );
    } catch (e) {
      debugPrint(
        'SOSPingService: Error sending via emergency messaging service - $e',
      );
    }

    // Notify civilian
    await _notificationService.showNotification(
      title: '🚁 SAR Team Message',
      body: '$sarMemberName: $content',
      importance: NotificationImportance.high,
    );

    debugPrint('SOSPingService: Message sent from SAR to civilian - $pingId');
    return message;
  }

  /// Send message from civilian to SAR member
  Future<EmergencyMessage> sendMessageToSAR({
    required String pingId,
    required String content,
    MessageType type = MessageType.emergency,
  }) async {
    final ping = _findPingById(pingId);
    if (ping == null) {
      throw Exception('SOS ping not found');
    }

    final userProfile = _userProfileService.currentProfile;
    final userName = userProfile?.name ?? 'SOS User';

    final message = EmergencyMessage(
      id: _generateMessageId(),
      senderId: ping.userId,
      senderName: userName,
      content: content,
      recipients: ping.assignedSARMembers,
      timestamp: DateTime.now(),
      priority: MessagePriority.critical,
      type: type,
      status: MessageStatus.sent,
      isRead: false,
      metadata: {'pingId': pingId, 'messageSource': 'civilian_to_sar'},
    );

    // Add message to ping
    final updatedPing = ping.copyWith(messages: [...ping.messages, message]);

    _updatePingInLists(updatedPing);
    await _savePings();

    // Send via emergency messaging service to SAR members
    try {
      await _messagingService.receiveMessageFromSAR(
        senderId: ping.userId,
        senderName: userName,
        content: content,
        priority: MessagePriority.critical,
        type: type,
        metadata: {'pingId': pingId, 'messageSource': 'civilian_to_sar'},
      );
      debugPrint(
        'SOSPingService: Message sent via emergency messaging service',
      );
    } catch (e) {
      debugPrint(
        'SOSPingService: Error sending via emergency messaging service - $e',
      );
    }

    // Notify SAR members
    for (final _ in ping.assignedSARMembers) {
      await _notificationService.showNotification(
        title: '🆘 SOS User Message',
        body: '$userName: $content',
        importance: NotificationImportance.high,
      );
    }

    debugPrint('SOSPingService: Message sent from civilian to SAR - $pingId');
    return message;
  }

  /// Get messages for a specific ping
  List<EmergencyMessage> getMessagesForPing(String pingId) {
    final ping = _findPingById(pingId);
    return ping?.messages ?? [];
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String pingId, String userId) async {
    final ping = _findPingById(pingId);
    if (ping == null) return;

    final updatedMessages = ping.messages.map((message) {
      if (!message.isRead &&
          (message.senderId != userId || message.recipients.contains(userId))) {
        return message.copyWith(isRead: true);
      }
      return message;
    }).toList();

    final updatedPing = ping.copyWith(messages: updatedMessages);
    _updatePingInLists(updatedPing);
    await _savePings();
  }

  /// Helper method to find ping by ID
  SOSPing? _findPingById(String pingId) {
    try {
      return _activePings.firstWhere((p) => p.id == pingId);
    } catch (e) {
      try {
        return _assignedPings.firstWhere((p) => p.id == pingId);
      } catch (e) {
        return null;
      }
    }
  }

  /// Helper method to update ping in all lists
  void _updatePingInLists(SOSPing updatedPing) {
    final activeIndex = _activePings.indexWhere((p) => p.id == updatedPing.id);
    if (activeIndex != -1) {
      _activePings[activeIndex] = updatedPing;
    }

    final assignedIndex = _assignedPings.indexWhere(
      (p) => p.id == updatedPing.id,
    );
    if (assignedIndex != -1) {
      _assignedPings[assignedIndex] = updatedPing;
    }

    // Notify callbacks
    _onActivePingsUpdated?.call(_activePings);
    _onAssignedPingsUpdated?.call(_assignedPings);
  }

  /// Get REDP!NG help scenarios based on category
  List<Map<String, dynamic>> _getREDPINGHelpScenarios(String category) {
    final baseScenarios = {
      // Original generic categories
      'navigation': [
        {
          'name': 'Alex Thompson',
          'phone': '+1-555-0234',
          'message':
              'REDP!NG Help: Lost on hiking trail, need navigation assistance',
          'conditions': [],
          'allergies': [],
          'age': 29,
          'risk': RiskLevel.low,
          'terrain': 'Mountain Trail',
          'weather': 'Clear, 16°C',
          'priority': SOSPriority.low,
        },
      ],
      'medical': [
        {
          'name': 'Jordan Lee',
          'phone': '+1-555-0345',
          'message': 'REDP!NG Help: Minor cut on hand, need first aid guidance',
          'conditions': [],
          'allergies': ['Latex'],
          'age': 34,
          'risk': RiskLevel.low,
          'terrain': 'Camping Area',
          'weather': 'Sunny, 22°C',
          'priority': SOSPriority.medium,
        },
      ],
      'equipment': [
        {
          'name': 'Sam Wilson',
          'phone': '+1-555-0456',
          'message':
              'REDP!NG Help: GPS device malfunction, need technical support',
          'conditions': [],
          'allergies': [],
          'age': 41,
          'risk': RiskLevel.low,
          'terrain': 'Forest Path',
          'weather': 'Cloudy, 14°C',
          'priority': SOSPriority.low,
        },
      ],
      'weather': [
        {
          'name': 'Taylor Davis',
          'phone': '+1-555-0567',
          'message':
              'REDP!NG Help: Need current weather conditions for route planning',
          'conditions': [],
          'allergies': [],
          'age': 26,
          'risk': RiskLevel.low,
          'terrain': 'Base Camp',
          'weather': 'Variable, 18°C',
          'priority': SOSPriority.low,
        },
      ],

      // Categories used by the SOS page UI
      'car_breakdown': [
        {
          'name': 'Chris Walker',
          'phone': '+1-555-0789',
          'message': 'REDP!NG Help: Vehicle disabled, need roadside assistance',
          'conditions': [],
          'allergies': [],
          'age': 36,
          'risk': RiskLevel.low,
          'terrain': 'Roadway / Shoulder',
          'weather': 'Light rain, 12°C',
          'priority': SOSPriority.medium,
        },
        {
          'name': 'Dana Kim',
          'phone': '+1-555-0477',
          'message': 'REDP!NG Help: Flat tire, no jack available',
          'conditions': [],
          'allergies': [],
          'age': 27,
          'risk': RiskLevel.low,
          'terrain': 'Highway',
          'weather': 'Clear, 18°C',
          'priority': SOSPriority.low,
        },
      ],
      'domestic_violence': [
        {
          'name': 'Anonymous',
          'phone': 'Not provided',
          'message': 'REDP!NG Help: Immediate safety threat at home',
          'conditions': [],
          'allergies': [],
          'age': 0,
          'risk': RiskLevel.critical,
          'terrain': 'Home / Apartment',
          'weather': 'N/A',
          'priority': SOSPriority.critical,
        },
      ],
      'fall_accident': [
        {
          'name': 'Taylor Morgan',
          'phone': '+1-555-0987',
          'message': 'REDP!NG Help: Fall injury, severe ankle pain',
          'conditions': [],
          'allergies': [],
          'age': 42,
          'risk': RiskLevel.medium,
          'terrain': 'Stairs / Trail',
          'weather': 'Overcast, 15°C',
          'priority': SOSPriority.high,
        },
      ],
      'home_breakin': [
        {
          'name': 'Anonymous',
          'phone': 'Not provided',
          'message': 'REDP!NG Help: Suspected break-in, hiding and unsafe',
          'conditions': [],
          'allergies': [],
          'age': 0,
          'risk': RiskLevel.high,
          'terrain': 'Residential',
          'weather': 'N/A',
          'priority': SOSPriority.critical,
        },
      ],
      'theft': [
        {
          'name': 'Jamie Rivera',
          'phone': '+1-555-0332',
          'message': 'REDP!NG Help: Phone stolen, requesting guidance',
          'conditions': [],
          'allergies': [],
          'age': 24,
          'risk': RiskLevel.low,
          'terrain': 'Urban',
          'weather': 'Clear, 20°C',
          'priority': SOSPriority.low,
        },
      ],
      'lost_pets': [
        {
          'name': 'Morgan Blake',
          'phone': '+1-555-0661',
          'message': 'REDP!NG Help: Missing dog near park, last seen 30m ago',
          'conditions': [],
          'allergies': [],
          'age': 33,
          'risk': RiskLevel.low,
          'terrain': 'Park / Trail',
          'weather': 'Breezy, 17°C',
          'priority': SOSPriority.low,
        },
      ],

      'general': [
        {
          'name': 'Casey Brown',
          'phone': '+1-555-0678',
          'message':
              'REDP!NG Help: General assistance needed, unsure of best route',
          'conditions': [],
          'allergies': [],
          'age': 31,
          'risk': RiskLevel.low,
          'terrain': 'Trail Junction',
          'weather': 'Partly cloudy, 19°C',
          'priority': SOSPriority.low,
        },
      ],
    };

    return baseScenarios[category] ?? baseScenarios['general']!;
  }

  /// Get current user profile
  Future<dynamic> _getUserProfile() async {
    try {
      // Use the real UserProfileService - no mock data
      final userProfile = _userProfileService.currentProfile;

      if (userProfile != null) {
        return {
          'id': userProfile.id,
          'name': userProfile.name,
          'phone': userProfile.phoneNumber,
        };
      }

      // No profile available - return null (no mock fallback)
      debugPrint(
        'SOSPingService: No user profile found - user must set up profile',
      );
      return null;
    } catch (e) {
      debugPrint('SOSPingService: Error getting user profile: $e');
      return null;
    }
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// Dispose of the service
  void dispose() {
    _pingUpdateTimer?.cancel();
    _locationUpdateTimer?.cancel();
  }
}
