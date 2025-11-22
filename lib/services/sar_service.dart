import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redping_14v/utils/iterable_extensions.dart';
import '../models/sar_session.dart';
import '../models/sos_session.dart';
import 'location_service.dart';
import 'emergency_contacts_service.dart';
import 'notification_service.dart';

/// Service for managing SAR (Search and Rescue) operations
class SARService {
  void wake() {
    // TODO: Implement wake logic if needed
    debugPrint('SARService: wake called');
  }

  void hibernate() {
    // TODO: Implement hibernate logic if needed
    debugPrint('SARService: hibernate called');
  }

  static final SARService _instance = SARService._internal();
  factory SARService() => _instance;
  SARService._internal();

  final LocationService _locationService = LocationService();
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  final NotificationService _notificationService = NotificationService();

  SARSession? _currentSession;
  Timer? _locationUpdateTimer;
  Timer? _statusUpdateTimer;
  // _crossEmulatorCheckTimer REMOVED - no longer needed in production
  final List<SARTeam> _availableTeams = [];
  List<SARSession> _sessionHistory = [];
  // Removed unused in-memory caches to reduce memory and warnings

  bool _isInitialized = false;
  bool _isActive = false;

  // Removed unused stream controllers (production relies on Firebase streams)

  // Callbacks
  Function(SARSession)? _onSessionStarted;
  Function(SARSession)? _onSessionUpdated;
  Function(SARSession)? _onSessionEnded;
  Function(SARUpdate)? _onUpdateReceived;

  /// Initialize the SAR service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies with timeout to prevent hanging
      await Future.wait([
        _locationService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('SARService: LocationService initialization timeout');
            // LocationService.initialize returns bool; indicate failure on timeout
            return false;
          },
        ),
        _contactsService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('SARService: ContactsService initialization timeout');
            return;
          },
        ),
        _notificationService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
              'SARService: NotificationService initialization timeout',
            );
            return;
          },
        ),
      ]);

      // Load session history with timeout
      await _loadSessionHistory().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('SARService: Load session history timeout - using empty');
          _sessionHistory = [];
          return;
        },
      );

      // Production mode - all data from Firestore/Firebase
      debugPrint('SARService: Production mode - all data from Firestore');

      _isInitialized = true;
      AppLogger.i('Initialized successfully', tag: 'SARService');
    } catch (e) {
      AppLogger.e('Initialization error', tag: 'SARService', error: e);
      // Don't throw - allow app to continue with partial initialization
      debugPrint('SARService: Partial initialization - continuing anyway');
      _isInitialized = true;
    }
  }

  /// Handle incoming SOS alert (called by SOS service or test)
  Future<void> handleIncomingSOSAlert({
    required String sosSessionId,
    required String userId,
    required String userName,
    required LocationInfo location,
    required SOSType sosType,
    String? message,
    List<String> emergencyContacts = const [],
    Map<String, dynamic>? userDetails,
    Map<String, dynamic>? incidentDetails,
    Map<String, dynamic>? weatherConditions,
    String? mapScreenshotPath,
  }) async {
    // Store alert in SharedPreferences for cross-emulator communication
    await _storeCrossEmulatorAlert(
      sosSessionId,
      userId,
      userName,
      location,
      sosType,
      message,
      emergencyContacts,
      userDetails,
      incidentDetails,
      weatherConditions,
      mapScreenshotPath,
    );
    try {
      // Create comprehensive SOS alert message
      final incidentType = incidentDetails?['type'] ?? 'Unknown';
      final impactDetails =
          incidentDetails?['impact'] ?? 'No details available';
      final weatherInfo =
          weatherConditions?['conditions'] ?? 'Weather data unavailable';

      final sosUpdate = SARUpdate(
        id: _generateUpdateId(),
        userId: 'sos_system',
        timestamp: DateTime.now(),
        message:
            '🚨 SOS ALERT: $incidentType incident - $userName needs immediate assistance at ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
        type: SARUpdateType.sosAlert,
        location: location,
        data: {
          'sosSessionId': sosSessionId,
          'sosType': sosType.name,
          'userId': userId,
          'userName': userName,
          'emergencyContacts': emergencyContacts,
          'message': message ?? '',
          'userDetails': userDetails ?? {},
          'incidentDetails': incidentDetails ?? {},
          'weatherConditions': weatherConditions ?? {},
          'mapScreenshotPath': mapScreenshotPath,
          'impactDetails': impactDetails,
          'incidentType': incidentType,
          'weatherInfo': weatherInfo,
          'urgencyLevel': _determineUrgencyLevel(incidentType, impactDetails),
        },
      );

      // Add to current session if active, otherwise create a new one
      if (_currentSession != null && _currentSession!.isActive) {
        _currentSession = _currentSession!.copyWith(
          updates: [..._currentSession!.updates, sosUpdate],
        );
      } else {
        // Create emergency SAR session for SOS response
        _currentSession = SARSession(
          id: _generateSessionId(),
          userId: 'sar_coordinator',
          type: SARType.medicalEmergency, // Default for SOS alerts
          status: SARStatus.initiated,
          startTime: DateTime.now(),
          lastKnownLocation: location,
          locationHistory: [location],
          priority: SARPriority.high, // SOS alerts are high priority
          description: 'Emergency response to SOS alert from $userName',
          equipmentList: [],
          estimatedPersons: 1,
          weatherInfo: SARWeatherInfo(
            temperature: 20.0,
            conditions: 'Unknown',
            windSpeed: 0.0,
            windDirection: 'Unknown',
            visibility: 10.0,
            precipitation: 0.0,
            timestamp: DateTime.now(),
          ),
          terrainInfo: SARTerrainInfo(
            elevation: 0.0,
            terrainType: 'Unknown',
            difficulty: 'Unknown',
            hazards: [],
            searchRadius: 1000.0,
            accessMethod: 'Unknown',
          ),
          rescueTeamIds: [],
          updates: [sosUpdate],
        );
      }

      // Show notification
      await _notificationService.showNotification(
        title: '🚨 SOS Alert - $incidentType',
        body: '$userName needs immediate assistance - $impactDetails',
        payload: 'sos_alert:$sosSessionId:$userId',
      );

      // Trigger callbacks
      _onUpdateReceived?.call(sosUpdate);
      if (_currentSession != null) {
        _onSessionStarted?.call(_currentSession!);
      }

      AppLogger.i(
        'Handled incoming SOS alert from $userName',
        tag: 'SARService',
      );
    } catch (e) {
      AppLogger.e('Error handling SOS alert', tag: 'SARService', error: e);
      throw Exception('Failed to handle SOS alert: $e');
    }
  }

  /// Determine urgency level based on incident type and impact
  String _determineUrgencyLevel(String incidentType, String impactDetails) {
    final criticalIncidents = [
      'fire',
      'explosion',
      'medical_emergency',
      'trapped',
    ];
    final highUrgencyIncidents = ['fall', 'accident', 'storm', 'flood'];

    if (criticalIncidents.any(
      (type) => incidentType.toLowerCase().contains(type),
    )) {
      return 'CRITICAL';
    } else if (highUrgencyIncidents.any(
      (type) => incidentType.toLowerCase().contains(type),
    )) {
      return 'HIGH';
    } else if (impactDetails.toLowerCase().contains('severe') ||
        impactDetails.toLowerCase().contains('critical') ||
        impactDetails.toLowerCase().contains('unconscious')) {
      return 'HIGH';
    } else {
      return 'MEDIUM';
    }
  }

  /// Start a new SAR session
  Future<SARSession> startSARSession({
    required SARType type,
    required SARPriority priority,
    String? description,
    int? estimatedPersons,
    List<String>? equipmentList,
    bool isTestMode = false,
  }) async {
    if (_currentSession != null && _currentSession!.isActive) {
      throw Exception('SAR session already active');
    }

    // Get current location
    final location =
        await _locationService.getCurrentLocation() ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );

    // Get weather information (mock data for demo)
    final weatherInfo = await _getWeatherInfo(location);
    final terrainInfo = await _getTerrainInfo(location);

    // Create new SAR session
    _currentSession = SARSession(
      id: _generateSessionId(),
      userId: 'current_user',
      type: type,
      status: SARStatus.initiated,
      startTime: DateTime.now(),
      lastKnownLocation: location,
      locationHistory: [location],
      priority: priority,
      description: description,
      equipmentList: equipmentList ?? [],
      estimatedPersons: estimatedPersons,
      weatherInfo: weatherInfo,
      terrainInfo: terrainInfo,
      isTestMode: isTestMode,
    );

    // Start location tracking
    await _startLocationTracking();

    // Dispatch SAR teams based on priority
    await _dispatchSARTeams();

    // Send notifications
    await _sendSARNotifications();

    // Start status updates
    _startStatusUpdates();

    _isActive = true;

    // Provide haptic feedback
    HapticFeedback.heavyImpact();

    debugPrint('SARService: Started SAR session - ${_currentSession!.id}');
    _onSessionStarted?.call(_currentSession!);

    return _currentSession!;
  }

  /// Update SAR session status
  Future<void> updateSARStatus(SARStatus status, {String? message}) async {
    if (_currentSession == null) return;

    final update = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message: message ?? 'Status updated to ${status.name}',
      location: _currentSession!.lastKnownLocation,
      type: SARUpdateType.statusUpdate,
    );

    _currentSession = _currentSession!.copyWith(
      status: status,
      updates: [..._currentSession!.updates, update],
    );

    if (status == SARStatus.rescued || status == SARStatus.cancelled) {
      await _endSARSession();
    } else {
      _onSessionUpdated?.call(_currentSession!);
      _onUpdateReceived?.call(update);
    }

    debugPrint('SARService: Status updated to $status');
  }

  /// Add location update to current SAR session
  Future<void> addLocationUpdate(LocationInfo location) async {
    if (_currentSession == null) return;

    final update = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message: 'Location updated',
      location: location,
      type: SARUpdateType.locationUpdate,
    );

    _currentSession = _currentSession!.copyWith(
      lastKnownLocation: location,
      locationHistory: [..._currentSession!.locationHistory, location],
      updates: [..._currentSession!.updates, update],
    );

    _onSessionUpdated?.call(_currentSession!);
    _onUpdateReceived?.call(update);
  }

  /// Request additional SAR resources
  Future<void> requestSARResources({
    required String resourceType,
    required String description,
    SARPriority priority = SARPriority.medium,
  }) async {
    if (_currentSession == null) return;

    final update = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message: 'Requesting $resourceType: $description',
      location: _currentSession!.lastKnownLocation,
      type: SARUpdateType.resourceRequest,
      data: {'resourceType': resourceType, 'priority': priority.name},
    );

    _currentSession = _currentSession!.copyWith(
      updates: [..._currentSession!.updates, update],
    );

    // Notify available teams
    await _notificationService.showNotification(
      title: 'SAR Resource Request',
      body: '$resourceType requested: $description',
      importance: NotificationImportance.high,
    );

    _onSessionUpdated?.call(_currentSession!);
    _onUpdateReceived?.call(update);

    debugPrint('SARService: Resource requested - $resourceType');
  }

  /// Send distress beacon with current location
  Future<void> sendDistressBeacon({String? message}) async {
    if (_currentSession == null) return;

    final location =
        await _locationService.getCurrentLocation() ??
        _currentSession!.lastKnownLocation;

    final update = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message: message ?? 'Distress beacon activated',
      location: location,
      type: SARUpdateType.statusUpdate,
      data: {'beacon': true, 'urgent': true},
    );

    _currentSession = _currentSession!.copyWith(
      priority: SARPriority.urgent,
      updates: [..._currentSession!.updates, update],
    );

    // Send urgent notifications
    await _sendUrgentDistressNotification(location, message);

    // Provide strong haptic feedback
    HapticFeedback.heavyImpact();

    _onSessionUpdated?.call(_currentSession!);
    _onUpdateReceived?.call(update);

    debugPrint('SARService: Distress beacon sent');
  }

  /// End current SAR session
  Future<void> _endSARSession() async {
    if (_currentSession == null) return;

    _locationUpdateTimer?.cancel();
    _statusUpdateTimer?.cancel();

    final endedSession = _currentSession!.copyWith(endTime: DateTime.now());

    // Save to history
    _sessionHistory.add(endedSession);
    await _saveSessionHistory();

    // Stop location tracking
    _locationService.stopTracking();

    // Send completion notification
    await _notificationService.showNotification(
      title: 'SAR Session Completed',
      body: 'Session ${endedSession.id} has ended',
      importance: NotificationImportance.defaultImportance,
    );

    _currentSession = null;
    _isActive = false;

    debugPrint('SARService: SAR session ended - ${endedSession.id}');
    _onSessionEnded?.call(endedSession);
  }

  /// Cancel current SAR session
  Future<void> cancelSARSession({String? reason}) async {
    if (_currentSession == null) return;

    final update = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message: reason ?? 'SAR session cancelled',
      type: SARUpdateType.statusUpdate,
    );

    _currentSession = _currentSession!.copyWith(
      status: SARStatus.cancelled,
      updates: [..._currentSession!.updates, update],
    );

    await _endSARSession();
    debugPrint('SARService: SAR session cancelled - $reason');
  }

  /// Complete SAR session with detailed report
  Future<void> completeSARSession({
    required SAROutcome outcome,
    required String summary,
    String? detailedReport,
    List<String>? personsFound,
    List<String>? personsNotFound,
    List<String>? resourcesUsed,
    int? survivorsCount,
    int? casualtiesCount,
    String? hospitalDestination,
    required SARDifficulty difficulty,
    required double successRating,
    List<String>? lessonsLearned,
  }) async {
    if (_currentSession == null) return;

    final completion = SARCompletion(
      completionTime: DateTime.now(),
      outcome: outcome,
      summary: summary,
      detailedReport: detailedReport,
      personsFound: personsFound ?? [],
      personsNotFound: personsNotFound ?? [],
      resourcesUsed: resourcesUsed ?? [],
      totalDuration: _currentSession!.duration,
      teamPerformance: _generateTeamPerformanceReport(),
      lessonsLearned: lessonsLearned ?? [],
      survivorsCount: survivorsCount,
      casualtiesCount: casualtiesCount,
      hospitalDestination: hospitalDestination,
      difficulty: difficulty,
      successRating: successRating,
      completedBy: 'current_user',
    );

    final completionUpdate = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message: 'Mission completed: ${outcome.name}',
      type: SARUpdateType.rescueComplete,
      data: {
        'outcome': outcome.name,
        'successRating': successRating,
        'survivors': survivorsCount,
        'casualties': casualtiesCount,
      },
    );

    _currentSession = _currentSession!.copyWith(
      status:
          outcome == SAROutcome.successfulRescue ||
              outcome == SAROutcome.personsFoundSafe
          ? SARStatus.rescued
          : SARStatus.cancelled,
      completion: completion,
      updates: [..._currentSession!.updates, completionUpdate],
    );

    await _endSARSession();
    await _sendCompletionNotifications(completion);

    debugPrint('SARService: SAR session completed - ${outcome.name}');
  }

  /// Add media file to current SAR session
  Future<void> addSARMedia({
    required SARMediaType type,
    required String filePath,
    String? description,
    List<String>? tags,
    bool isEvidence = false,
  }) async {
    if (_currentSession == null) return;

    final location = await _locationService.getCurrentLocation();

    final media = SARMedia(
      id: _generateMediaId(),
      type: type,
      filePath: filePath,
      description: description,
      location: location,
      timestamp: DateTime.now(),
      uploadedBy: 'current_user',
      tags: tags ?? [],
      isEvidence: isEvidence,
    );

    final mediaUpdate = SARUpdate(
      id: _generateUpdateId(),
      timestamp: DateTime.now(),
      userId: 'current_user',
      message:
          'Media uploaded: ${type.name}${description != null ? " - $description" : ""}',
      location: location,
      type: SARUpdateType.statusUpdate,
      data: {
        'mediaType': type.name,
        'mediaId': media.id,
        'isEvidence': isEvidence,
      },
    );

    _currentSession = _currentSession!.copyWith(
      mediaFiles: [..._currentSession!.mediaFiles, media],
      updates: [..._currentSession!.updates, mediaUpdate],
    );

    _onSessionUpdated?.call(_currentSession!);
    _onUpdateReceived?.call(mediaUpdate);

    debugPrint('SARService: Media added - ${type.name}');
  }

  /// Generate team performance report
  Map<String, String> _generateTeamPerformanceReport() {
    final performance = <String, String>{};

    for (final teamId in _currentSession?.rescueTeamIds ?? []) {
      final team = _availableTeams.where((t) => t.id == teamId).firstOrNull;
      if (team != null) {
        // Mock performance evaluation
        final responseTime = '${5 + Random().nextInt(15)} minutes';
        final effectiveness = [
          'Excellent',
          'Good',
          'Satisfactory',
          'Needs Improvement',
        ][Random().nextInt(4)];
        performance[team.name] =
            'Response: $responseTime, Performance: $effectiveness';
      }
    }

    return performance;
  }

  /// Send completion notifications
  Future<void> _sendCompletionNotifications(SARCompletion completion) async {
    final outcomeText = _getOutcomeDisplayText(completion.outcome);

    await _notificationService.showNotification(
      title: 'SAR Mission Complete',
      body:
          '$outcomeText - Success Rating: ${(completion.successRating * 100).round()}%',
      importance: NotificationImportance.high,
    );

    // Send to emergency contacts
    final completionSOSSession = SOSSession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      type: SOSType.manual,
      status: SOSStatus.resolved,
      startTime: _currentSession!.startTime,
      endTime: completion.completionTime,
      location: _currentSession!.lastKnownLocation,
      userMessage: 'SAR Mission Complete: $outcomeText',
      isTestMode: _currentSession!.isTestMode,
    );

    await _contactsService.sendEmergencyAlerts(completionSOSSession);
  }

  String _getOutcomeDisplayText(SAROutcome outcome) {
    switch (outcome) {
      case SAROutcome.successfulRescue:
        return 'Successful Rescue';
      case SAROutcome.personsFoundSafe:
        return 'Persons Found Safe';
      case SAROutcome.personsFoundInjured:
        return 'Persons Found Injured';
      case SAROutcome.personsFoundDeceased:
        return 'Persons Found Deceased';
      case SAROutcome.personsNotFound:
        return 'Persons Not Found';
      case SAROutcome.falseAlarm:
        return 'False Alarm';
      case SAROutcome.operationSuspended:
        return 'Operation Suspended';
      case SAROutcome.operationCancelled:
        return 'Operation Cancelled';
      case SAROutcome.transferredToAuthorities:
        return 'Transferred to Authorities';
    }
  }

  /// Start location tracking for SAR session
  Future<void> _startLocationTracking() async {
    // Use connectivity-aware location updates as per blueprint
    LocationService().setUserRequestedLocationUpdates(true);

    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 1), // Update every minute during SAR
      (timer) async {
        final location = await LocationService().getCurrentLocation();
        if (location != null) {
          await addLocationUpdate(location);
        }
      },
    );
  }

  /// Start periodic status updates
  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(
      const Duration(minutes: 5), // Status update every 5 minutes
      (timer) {
        _handlePeriodicStatusUpdate();
      },
    );
  }

  Future<void> _handlePeriodicStatusUpdate() async {
    if (_currentSession != null && _currentSession!.isActive) {
      final update = SARUpdate(
        id: _generateUpdateId(),
        timestamp: DateTime.now(),
        userId: 'system',
        message: 'Periodic status update - Still active',
        location: _currentSession!.lastKnownLocation,
        type: SARUpdateType.statusUpdate,
      );

      _currentSession = _currentSession!.copyWith(
        updates: [..._currentSession!.updates, update],
      );

      _onSessionUpdated?.call(_currentSession!);
    }
  }

  /// Dispatch SAR teams based on session priority and type
  Future<void> _dispatchSARTeams() async {
    if (_currentSession == null) return;

    final teamsToDispatch = _selectAppropriateTeams(_currentSession!);

    for (final team in teamsToDispatch) {
      final update = SARUpdate(
        id: _generateUpdateId(),
        timestamp: DateTime.now(),
        userId: 'dispatch',
        message: '${team.name} dispatched to scene',
        type: SARUpdateType.teamDispatch,
        data: {'teamId': team.id, 'teamType': team.type.name},
      );

      _currentSession = _currentSession!.copyWith(
        rescueTeamIds: [..._currentSession!.rescueTeamIds, team.id],
        updates: [..._currentSession!.updates, update],
      );
    }

    _onSessionUpdated?.call(_currentSession!);
    debugPrint('SARService: ${teamsToDispatch.length} teams dispatched');
  }

  /// Select appropriate SAR teams based on session requirements
  List<SARTeam> _selectAppropriateTeams(SARSession session) {
    final selectedTeams = <SARTeam>[];

    // Always dispatch ground team for initial response
    final groundTeam = _availableTeams
        .where(
          (t) =>
              t.type == SARTeamType.groundTeam &&
              t.status == SARTeamStatus.available,
        )
        .firstOrNull;
    if (groundTeam != null) selectedTeams.add(groundTeam);

    // Add specialized teams based on SAR type
    switch (session.type) {
      case SARType.medicalEmergency:
        final medicalTeam = _availableTeams
            .where(
              (t) =>
                  t.type == SARTeamType.medicalTeam &&
                  t.status == SARTeamStatus.available,
            )
            .firstOrNull;
        if (medicalTeam != null) selectedTeams.add(medicalTeam);
        break;
      case SARType.waterRescue:
        final waterTeam = _availableTeams
            .where(
              (t) =>
                  t.type == SARTeamType.waterRescue &&
                  t.status == SARTeamStatus.available,
            )
            .firstOrNull;
        if (waterTeam != null) selectedTeams.add(waterTeam);
        break;
      case SARType.mountainRescue:
      case SARType.wildernessRescue:
        final k9Team = _availableTeams
            .where(
              (t) =>
                  t.type == SARTeamType.k9Unit &&
                  t.status == SARTeamStatus.available,
            )
            .firstOrNull;
        if (k9Team != null) selectedTeams.add(k9Team);
        break;
      default:
        break;
    }

    // Add air support for high priority cases
    if (session.priority == SARPriority.urgent ||
        session.priority == SARPriority.critical) {
      final airSupport = _availableTeams
          .where(
            (t) =>
                t.type == SARTeamType.airSupport &&
                t.status == SARTeamStatus.available,
          )
          .firstOrNull;
      if (airSupport != null) selectedTeams.add(airSupport);
    }

    return selectedTeams;
  }

  /// Send SAR notifications to emergency contacts and authorities
  Future<void> _sendSARNotifications() async {
    if (_currentSession == null) return;

    final session = _currentSession!;
    final location = session.lastKnownLocation;

    // Create a mock SOS session for emergency contacts compatibility
    final mockSOSSession = SOSSession(
      id: session.id,
      userId: session.userId,
      type: SOSType.manual,
      status: SOSStatus.active,
      startTime: session.startTime,
      location: location,
      userMessage: 'SAR operation initiated: ${session.type.name}',
      isTestMode: session.isTestMode,
    );

    // Send to emergency contacts
    await _contactsService.sendEmergencyAlerts(mockSOSSession);

    // Send system notification
    await _notificationService.showNotification(
      title: 'SAR Operation Started',
      body: '${session.type.name} - Priority: ${session.priority.name}',
      importance: NotificationImportance.high,
      persistent: true,
    );
  }

  /// Send urgent distress notification
  Future<void> _sendUrgentDistressNotification(
    LocationInfo location,
    String? message,
  ) async {
    // Create urgent mock SOS session for distress beacon
    final urgentSOSSession = SOSSession(
      id: _currentSession?.id ?? _generateSessionId(),
      userId: _currentSession?.userId ?? 'current_user',
      type: SOSType.manual,
      status: SOSStatus.active,
      startTime: DateTime.now(),
      location: location,
      userMessage:
          'URGENT DISTRESS BEACON: ${message ?? "Help needed immediately"}',
      isTestMode: false,
    );

    // Send to emergency contacts with urgent priority
    await _contactsService.sendEmergencyAlerts(urgentSOSSession);

    // Send critical system notification
    await _notificationService.showNotification(
      title: '🚨 DISTRESS BEACON ACTIVE',
      body: message ?? 'Emergency assistance required immediately',
      importance: NotificationImportance.max,
      persistent: true,
    );
  }

  /// Get weather information for location (mock implementation)
  Future<SARWeatherInfo> _getWeatherInfo(LocationInfo location) async {
    // In production, this would call a weather API
    return SARWeatherInfo(
      temperature: 15.0 + Random().nextDouble() * 20, // 15-35°C
      windSpeed: Random().nextDouble() * 30, // 0-30 km/h
      windDirection: [
        'N',
        'NE',
        'E',
        'SE',
        'S',
        'SW',
        'W',
        'NW',
      ][Random().nextInt(8)],
      visibility: 5.0 + Random().nextDouble() * 15, // 5-20 km
      conditions: [
        'Clear',
        'Cloudy',
        'Overcast',
        'Light Rain',
        'Fog',
      ][Random().nextInt(5)],
      precipitation: Random().nextDouble() * 5, // 0-5mm
      timestamp: DateTime.now(),
    );
  }

  /// Get terrain information for location (mock implementation)
  Future<SARTerrainInfo> _getTerrainInfo(LocationInfo location) async {
    // In production, this would analyze topographic data
    final terrainTypes = [
      'Forest',
      'Mountain',
      'Desert',
      'Urban',
      'Water',
      'Plains',
    ];
    final difficulties = ['Easy', 'Moderate', 'Difficult', 'Extreme'];
    final hazards = [
      'Steep slopes',
      'Dense vegetation',
      'Water hazards',
      'Wildlife',
      'Weather exposure',
    ];

    return SARTerrainInfo(
      terrainType: terrainTypes[Random().nextInt(terrainTypes.length)],
      elevation: Random().nextDouble() * 3000, // 0-3000m
      difficulty: difficulties[Random().nextInt(difficulties.length)],
      hazards: hazards.take(Random().nextInt(3) + 1).toList(),
      searchRadius: 1.0 + Random().nextDouble() * 9, // 1-10 km
      accessMethod: [
        'Foot',
        'Vehicle',
        'Helicopter',
        'Boat',
      ][Random().nextInt(4)],
    );
  }

  // Mock SAR teams method REMOVED - production uses Firestore data only

  /// Load SAR session history from storage
  Future<void> _loadSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('sar_session_history') ?? [];

      _sessionHistory = historyJson
          .map(
            (json) => SARSession.fromJson(Map<String, dynamic>.from({})),
          ) // Simplified for demo
          .toList();
    } catch (e) {
      debugPrint('SARService: Failed to load session history - $e');
      _sessionHistory = [];
    }
  }

  /// Save SAR session history to storage
  Future<void> _saveSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _sessionHistory
          .map((session) => session.toJson().toString())
          .toList();
      await prefs.setStringList('sar_session_history', historyJson);
    } catch (e) {
      debugPrint('SARService: Failed to save session history - $e');
    }
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'SAR_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// Generate unique update ID
  String _generateUpdateId() {
    return 'UPD_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999).toString().padLeft(3, '0')}';
  }

  /// Generate unique media ID
  String _generateMediaId() {
    return 'MED_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999).toString().padLeft(3, '0')}';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isActive => _isActive;
  SARSession? get currentSession => _currentSession;

  /// Lightweight status snapshot for diagnostics and tests
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isActive': _isActive,
      'hasSession': _currentSession != null,
      'currentSessionId': _currentSession?.id,
      'currentStatus': _currentSession?.status.name,
      'locationUpdates': _currentSession?.locationHistory.length ?? 0,
      'updatesCount': _currentSession?.updates.length ?? 0,
    };
  }

  List<SARTeam> get availableTeams => List.from(_availableTeams);
  List<SARSession> get sessionHistory => List.from(_sessionHistory);

  // Event handlers
  void setSessionStartedCallback(Function(SARSession) callback) {
    _onSessionStarted = callback;
  }

  void setSessionUpdatedCallback(Function(SARSession) callback) {
    _onSessionUpdated = callback;
  }

  void setSessionEndedCallback(Function(SARSession) callback) {
    _onSessionEnded = callback;
  }

  void setUpdateReceivedCallback(Function(SARUpdate) callback) {
    _onUpdateReceived = callback;
  }

  /// Store SOS alert for cross-emulator communication using shared storage
  Future<void> _storeCrossEmulatorAlert(
    String sosSessionId,
    String userId,
    String userName,
    LocationInfo location,
    SOSType sosType,
    String? message,
    List<String> emergencyContacts,
    Map<String, dynamic>? userDetails,
    Map<String, dynamic>? incidentDetails,
    Map<String, dynamic>? weatherConditions,
    String? mapScreenshotPath,
  ) async {
    try {
      // Use SharedPreferences with a unique key for cross-emulator communication
      final prefs = await SharedPreferences.getInstance();

      final alertData = {
        'sosSessionId': sosSessionId,
        'userId': userId,
        'userName': userName,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
          'altitude': location.altitude,
          'speed': location.speed,
          'timestamp': location.timestamp.toIso8601String(),
        },
        'sosType': sosType.name,
        'message': message,
        'emergencyContacts': emergencyContacts,
        'userDetails': userDetails,
        'incidentDetails': incidentDetails,
        'weatherConditions': weatherConditions,
        'mapScreenshotPath': mapScreenshotPath,
        'timestamp': DateTime.now().toIso8601String(),
        'processed': false, // Flag to prevent duplicate processing
      };

      // Store with a unique key that both emulators can access
      final alertKey = 'cross_emulator_sos_alert_$sosSessionId';
      await prefs.setString(alertKey, jsonEncode(alertData));

      debugPrint(
        'SARService: Stored cross-emulator SOS alert for $sosSessionId from $userName',
      );
      debugPrint(
        'SARService: Location: ${location.latitude}, ${location.longitude}',
      );
      debugPrint(
        'SARService: Incident: ${incidentDetails?['type']} - ${incidentDetails?['impact']}',
      );
    } catch (e) {
      debugPrint('SARService: Error storing cross-emulator alert - $e');
    }
  }

  // Cross-emulator and simulation methods REMOVED - production uses Firebase only
  // _processIncomingSOSAlert method REMOVED - no longer needed

  /// Dispose of the service
  void dispose() {
    _locationUpdateTimer?.cancel();
    _statusUpdateTimer?.cancel();
    // _crossEmulatorCheckTimer removed - no longer needed
    _locationService.dispose();
  }
}
