import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../models/sos_session.dart';
import '../models/emergency_contact.dart';
import 'sensor_service.dart';
import '../core/logging/app_logger.dart';
import 'location_service.dart';
import 'emergency_contacts_service.dart';
import 'chat_service.dart';
import 'user_profile_service.dart';
import 'satellite_service.dart';
import 'rescue_response_service.dart';
import 'sos_ping_service.dart';
import '../repositories/sos_repository.dart';
import 'offline_sos_queue_service.dart';
import 'foreground_service_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'sos_callable_client.dart';
import 'battery_optimization_service.dart';
import 'sms_service.dart';
import 'notification_scheduler.dart';
import 'sos_analytics_service.dart';
import 'incident_escalation_coordinator.dart';

// Developer exemption email
const String _developerEmail = 'alromn7@gmail.com';

/// Service for managing SOS sessions and emergency responses
class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  final SensorService _sensorService = SensorService();
  final LocationService _locationService = LocationService();
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  final ChatService _chatService = ChatService();
  final UserProfileService _userProfileService = UserProfileService();
  final SatelliteService _satelliteService = SatelliteService();
  final RescueResponseService _rescueResponseService = RescueResponseService();
  final SOSPingService _sosPingService = SOSPingService();
  final SosRepository _sosRepository = SosRepository();
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();

  SOSSession? _currentSession;
  Timer? _countdownTimer;
  Timer? _voiceVerificationTimer;
  StreamSubscription<DocumentSnapshot>? _firestoreListener;
  bool _locationWriterAttached = false;

  bool _isInitialized = false;

  // Cooldown to prevent rapid re-starts of SOS sessions (reduces dialog spam)
  DateTime? _lastSessionStart;
  static const Duration _sessionStartCooldown = Duration(seconds: 60);

  // Callbacks
  Function(SOSSession)? _onSessionStarted;
  Function(SOSSession)? _onSessionUpdated;
  Function(SOSSession)? _onSessionEnded;
  Function(int)? _onCountdownTick;
  Function()? _onVoiceVerificationRequested;

  /// Initialize the SOS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize location service
      await _locationService.initialize();

      // Initialize sensor service with location tracking
      await _sensorService.startMonitoring(
        locationService: _locationService,
        lowPowerMode: true,
      );

      // Initialize emergency contacts service
      await _contactsService.initialize();

      // Set up sensor callbacks
      _sensorService.setCrashDetectedCallback(_handleCrashDetected);
      _sensorService.setFallDetectedCallback(_handleFallDetected);

      // Initialize rescue response service
      await _rescueResponseService.initialize();

      // Set up rescue response callbacks
      _rescueResponseService.setSessionUpdatedCallback(_handleSessionUpdated);

      // Initialize SOS ping service for SAR coordination
      try {
        await _sosPingService.initialize();
        AppLogger.i('SOS ping service initialized', tag: 'SOSService');
      } catch (e) {
        AppLogger.w(
          'SOS ping service initialization failed',
          tag: 'SOSService',
          error: e,
        );
        // Continue without SOS ping service
      }

      // Restore active session from Firestore if exists
      await _restoreActiveSession();

      _isInitialized = true;
      AppLogger.i('Initialized successfully', tag: 'SOSService');
    } catch (e) {
      AppLogger.e('Initialization error', tag: 'SOSService', error: e);
      throw Exception('Failed to initialize SOS service: $e');
    }
  }

  /// Restore active SOS session from Firestore after app restart
  /// This ensures that if the app is restarted while an SOS is active,
  /// the session state is properly restored
  Future<void> _restoreActiveSession() async {
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isEmpty) {
        debugPrint(
          'SOSService: No authenticated user, skipping session restore',
        );
        return;
      }

      debugPrint('SOSService: Checking for active session to restore...');
      final activeSession = await _sosRepository.getActiveSession(authUser.id);

      if (activeSession == null) {
        debugPrint('SOSService: No active session to restore');
        return;
      }

      debugPrint(
        'SOSService: ✅ Restored active session: ${activeSession.id} (status: ${activeSession.status})',
      );

      // Set the restored session as current
      _currentSession = activeSession;

      // Set up Firestore listener for real-time updates
      _startFirestoreListener(activeSession.id);

      // If session is active (not just countdown), restart location tracking
      if (activeSession.status != SOSStatus.countdown) {
        await _locationService.startTracking();

        // Reattach location writer to persist breadcrumb pings
        if (!_locationWriterAttached) {
          _locationService.setLocationUpdateCallback((loc) async {
            // Guard: ensure session is still active
            final session = _currentSession;
            if (session == null || session.status != SOSStatus.active) return;
            try {
              // Append ping to subcollection
              await _sosRepository.addLocationPing(session.id, loc);
              // Mirror latest into header for UI
              await _sosRepository.updateLatestLocation(session.id, loc);
            } catch (e) {
              AppLogger.w(
                'Failed to persist location update',
                tag: 'SOSService',
                error: e,
              );
            }
          });
          _locationWriterAttached = true;
        }
      }

      // Restart rescue response tracking if needed
      if (activeSession.status == SOSStatus.active ||
          activeSession.status == SOSStatus.acknowledged ||
          activeSession.status == SOSStatus.assigned ||
          activeSession.status == SOSStatus.enRoute ||
          activeSession.status == SOSStatus.onScene ||
          activeSession.status == SOSStatus.inProgress) {
        try {
          await _rescueResponseService.startTrackingSession(activeSession);
        } catch (e) {
          debugPrint('SOSService: Failed to restart rescue tracking: $e');
        }
      }

      // Notify UI that session was restored
      _onSessionStarted?.call(activeSession);
      _onSessionUpdated?.call(activeSession);

      AppLogger.i(
        'Active session restored: ${activeSession.id} (${activeSession.status})',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to restore active session',
        tag: 'SOSService',
        error: e,
      );
      // Don't throw - app should continue even if restore fails
    }
  }

  /// Start SOS countdown manually
  Future<SOSSession> startSOSCountdown({
    SOSType type = SOSType.manual,
    String? userMessage,
    bool bringToSOSPage = true,
    String? escalationReasonCode,
  }) async {
    // Check if there's already an active session (countdown or active)
    if (_currentSession != null &&
        (_currentSession!.status == SOSStatus.countdown ||
            _currentSession!.status == SOSStatus.active)) {
      AppLogger.w(
        'Session already active. Returning existing session (no restart).',
        tag: 'SOSService',
      );
      return _currentSession!;
    }

    // Global cooldown: avoid re-starting sessions too frequently (allow manual override)
    if (type != SOSType.manual) {
      final nowStart = DateTime.now();
      if (_lastSessionStart != null &&
          nowStart.difference(_lastSessionStart!) < _sessionStartCooldown) {
        AppLogger.w('Session start suppressed by cooldown', tag: 'SOSService');
        // If a session exists, return it; otherwise throw a controlled exception
        throw Exception('SOS start suppressed by cooldown');
      }
    }

    // Attempt to clear any stale activeSessionId pointer to avoid server-side
    // duplicate-session auto-resolution when starting a fresh SOS.
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        await _sosRepository.clearActiveSessionPointer(authUser.id);
      }
    } catch (_) {}

    // Get current location
    final location =
        await _locationService.getCurrentLocation(
          highAccuracy: true,
          forceFresh: true,
        ) ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );

    // Get current user ID from AuthService (primary source of truth)
    final authUser = AuthService.instance.currentUser;
    final userId = authUser.id.isNotEmpty ? authUser.id : 'anonymous_user';
    debugPrint(
      'SOSService: Creating SOS for user: $userId (${authUser.email})',
    );

    // Get user profile for medical data and identity
    final userProfile = _userProfileService.currentProfile;
    final metadata = <String, dynamic>{};
    if (userProfile != null) {
      if (userProfile.medicalConditions.isNotEmpty) {
        metadata['medicalConditions'] = userProfile.medicalConditions;
      }
      if (userProfile.allergies.isNotEmpty) {
        metadata['allergies'] = userProfile.allergies;
      }
      if (userProfile.bloodType != null) {
        metadata['bloodType'] = userProfile.bloodType;
      }
      if (userProfile.age != null) {
        metadata['age'] = userProfile.age;
      } else if (userProfile.dateOfBirth != null) {
        final age =
            DateTime.now().difference(userProfile.dateOfBirth!).inDays ~/ 365;
        metadata['age'] = age;
      }
      if (userProfile.gender != null) {
        metadata['gender'] = userProfile.gender;
      }
      if (userProfile.phoneNumber != null &&
          userProfile.phoneNumber!.isNotEmpty) {
        metadata['userPhone'] = userProfile.phoneNumber;
      }
      if (userProfile.name.isNotEmpty) {
        metadata['userName'] = userProfile.name;
      }
      if (userProfile.emergencyContacts.isNotEmpty) {
        metadata['emergencyContacts'] = userProfile.emergencyContacts;
      }
    }

    // Fallback to AuthService for critical identity fields if not in profile
    if (metadata['userName'] == null ||
        (metadata['userName'] as String).isEmpty) {
      if (authUser.displayName.isNotEmpty) {
        metadata['userName'] = authUser.displayName;
        debugPrint(
          'SOSService: Using displayName from AuthService: ${authUser.displayName}',
        );
      } else if (authUser.email.isNotEmpty) {
        // Use email username as last resort
        metadata['userName'] = authUser.email.split('@')[0];
        debugPrint(
          'SOSService: Using email username as fallback: ${metadata['userName']}',
        );
      }
    }

    if (metadata['userPhone'] == null ||
        (metadata['userPhone'] as String).isEmpty) {
      if (authUser.phoneNumber?.isNotEmpty == true) {
        metadata['userPhone'] = authUser.phoneNumber;
        debugPrint(
          'SOSService: Using phoneNumber from AuthService: ${authUser.phoneNumber}',
        );
      }
    }

    // Log final identity values for debugging
    debugPrint(
      'SOSService: SOS Identity - Name: ${metadata['userName']}, Phone: ${metadata['userPhone']}',
    );

    // Add battery level to metadata
    try {
      final batteryLevel = _batteryService.currentBatteryLevel;
      final batteryState = _batteryService.currentBatteryState;
      metadata['batteryLevel'] = batteryLevel;
      metadata['batteryState'] = batteryState
          .toString()
          .split('.')
          .last; // charging, discharging, etc.
      debugPrint(
        'SOSService: Battery level at SOS activation: $batteryLevel% ($batteryState)',
      );
    } catch (e) {
      debugPrint('SOSService: Could not get battery level: $e');
    }

    // Create new session
    _currentSession = SOSSession(
      id: _generateSessionId(),
      userId: userId,
      type: type,
      status: SOSStatus.countdown,
      startTime: DateTime.now(),
      location: location,
      userMessage: userMessage,
      isTestMode: false, // Test mode disabled for production
      metadata: {
        ...metadata,
        if (escalationReasonCode != null && escalationReasonCode.isNotEmpty)
          'escalationReason': escalationReasonCode,
      },
    );

    _lastSessionStart = DateTime.now();

    // Start countdown
    _startCountdown();

    // Notify coordinator that a countdown has started (for timeline/analytics)
    try {
      IncidentEscalationCoordinator.instance.notifyCountdownStarted(
        type: type,
        reasonCode: escalationReasonCode,
      );
    } catch (_) {}

    // Provide haptic feedback
    HapticFeedback.heavyImpact();

    AppLogger.i(
      'Started SOS countdown - ${_currentSession!.id}',
      tag: 'SOSService',
    );
    _onSessionStarted?.call(_currentSession!);

    // Optionally navigate to SOS page so the countdown dialog can be shown
    // Skipped for comprehensive tests to avoid disrupting the test UI
    if (bringToSOSPage) {
      try {
        AppRouter.router.go(AppRouter.main);
      } catch (_) {}
    }

    return _currentSession!;
  }

  /// Activate SOS immediately without countdown (for manual button activation)
  /// The 10-second button hold serves as the countdown, so we skip the service countdown
  Future<SOSSession> activateSOSImmediately({
    SOSType type = SOSType.manual,
    String? userMessage,
  }) async {
    // Check if there's already an active session
    if (_currentSession != null &&
        (_currentSession!.status == SOSStatus.countdown ||
            _currentSession!.status == SOSStatus.active)) {
      AppLogger.w(
        'Session already active. Returning existing session.',
        tag: 'SOSService',
      );
      return _currentSession!;
    }

    // Attempt to clear any stale activeSessionId pointer
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        await _sosRepository.clearActiveSessionPointer(authUser.id);
      }
    } catch (_) {}

    // Get current location
    final location =
        await _locationService.getCurrentLocation(
          highAccuracy: true,
          forceFresh: true,
        ) ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );

    // Get current user ID from AuthService
    final authUser = AuthService.instance.currentUser;
    final userId = authUser.id.isNotEmpty ? authUser.id : 'anonymous_user';
    debugPrint(
      'SOSService: Creating immediate SOS for user: $userId (${authUser.email})',
    );

    // Get user profile for medical data and identity
    final userProfile = _userProfileService.currentProfile;
    final metadata = <String, dynamic>{};
    if (userProfile != null) {
      if (userProfile.medicalConditions.isNotEmpty) {
        metadata['medicalConditions'] = userProfile.medicalConditions;
      }
      if (userProfile.allergies.isNotEmpty) {
        metadata['allergies'] = userProfile.allergies;
      }
      if (userProfile.bloodType != null) {
        metadata['bloodType'] = userProfile.bloodType;
      }
      if (userProfile.age != null) {
        metadata['age'] = userProfile.age;
      } else if (userProfile.dateOfBirth != null) {
        final age =
            DateTime.now().difference(userProfile.dateOfBirth!).inDays ~/ 365;
        metadata['age'] = age;
      }
      if (userProfile.gender != null) {
        metadata['gender'] = userProfile.gender;
      }
      if (userProfile.phoneNumber != null &&
          userProfile.phoneNumber!.isNotEmpty) {
        metadata['userPhone'] = userProfile.phoneNumber;
      }
      if (userProfile.name.isNotEmpty) {
        metadata['userName'] = userProfile.name;
      }
      if (userProfile.emergencyContacts.isNotEmpty) {
        metadata['emergencyContacts'] = userProfile.emergencyContacts;
      }
    }

    // Fallback to AuthService for critical identity fields
    if (metadata['userName'] == null ||
        (metadata['userName'] as String).isEmpty) {
      if (authUser.displayName.isNotEmpty) {
        metadata['userName'] = authUser.displayName;
      } else if (authUser.email.isNotEmpty) {
        metadata['userName'] = authUser.email.split('@')[0];
      }
    }

    if (metadata['userPhone'] == null ||
        (metadata['userPhone'] as String).isEmpty) {
      if (authUser.phoneNumber?.isNotEmpty == true) {
        metadata['userPhone'] = authUser.phoneNumber;
      }
    }

    // Add battery level to metadata
    try {
      final batteryLevel = _batteryService.currentBatteryLevel;
      final batteryState = _batteryService.currentBatteryState;
      metadata['batteryLevel'] = batteryLevel;
      metadata['batteryState'] = batteryState.toString().split('.').last;
      debugPrint(
        'SOSService: Battery level at SOS activation: $batteryLevel% ($batteryState)',
      );
    } catch (e) {
      debugPrint('SOSService: Could not get battery level: $e');
    }

    // Create new session with ACTIVE status (skip countdown)
    _currentSession = SOSSession(
      id: _generateSessionId(),
      userId: userId,
      type: type,
      status: SOSStatus.active,
      startTime: DateTime.now(),
      location: location,
      userMessage: userMessage,
      isTestMode: false,
      metadata: metadata,
    );

    _lastSessionStart = DateTime.now();

    // Provide haptic feedback
    HapticFeedback.heavyImpact();

    AppLogger.i(
      'Immediate SOS activated - ${_currentSession!.id}',
      tag: 'SOSService',
    );

    // Activate SOS immediately (no countdown)
    await _activateSOS();

    _onSessionStarted?.call(_currentSession!);

    return _currentSession!;
  }

  /// Cancel active SOS session
  void cancelSOS() {
    if (_currentSession == null) return;

    _countdownTimer?.cancel();
    _voiceVerificationTimer?.cancel();
    _stopFirestoreListener();

    // Switch sensors back to LOW POWER MODE when SOS ends
    _sensorService
        .setLowPowerMode()
        .then((_) {
          debugPrint('SOSService: Sensors switched back to LOW POWER MODE');
        })
        .catchError((e) {
          debugPrint('SOSService: Failed to switch sensor mode - $e');
        });

    // Deactivate satellite service
    _satelliteService.deactivateFromSOS();

    final cancelledSession = _currentSession!.copyWith(
      status: SOSStatus.cancelled,
      endTime: DateTime.now(),
    );

    _currentSession = null;

    // Light haptic feedback
    HapticFeedback.lightImpact();

    AppLogger.i('SOS cancelled - ${cancelledSession.id}', tag: 'SOSService');
    _onSessionEnded?.call(cancelledSession);

    // AI monitoring removed - SMS notifications handle emergency contact alerts
    try {
      AppLogger.i(
        'SOS cancelled - SMS notifications will send cancellation message',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to handle SOS cancellation',
        tag: 'SOSService',
        error: e,
      );
    }

    // Clear active session pointer so future sessions don't get auto-resolved
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        _sosRepository.clearActiveSessionPointer(authUser.id);
      }
    } catch (_) {}

    // Stop background foreground service if running
    try {
      ForegroundServiceManager.stop();
    } catch (_) {}
  }

  /// Activate SOS (after countdown or immediately)
  Future<void> _activateSOS() async {
    if (_currentSession == null) return;

    _countdownTimer?.cancel();

    // Clear any stale active session pointer to prevent Cloud Function from auto-resolving this session
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        await _sosRepository.clearActiveSessionPointer(authUser.id);
        debugPrint(
          'SOSService: Cleared stale active session pointer before activation',
        );
      }
    } catch (e) {
      debugPrint('SOSService: Failed to clear active session pointer - $e');
    }

    // Switch sensors to ACTIVE MODE for high-frequency monitoring during SOS
    try {
      await _sensorService.setActiveMode();
      debugPrint('SOSService: Sensors switched to ACTIVE MODE');
    } catch (e) {
      debugPrint('SOSService: Failed to switch sensor mode - $e');
    }

    // Activate satellite service for SOS
    _satelliteService.activateForSOS();

    // Update session status
    _currentSession = _currentSession!.copyWith(status: SOSStatus.active);

    // Get fresh location
    final currentLocation = await _locationService.getCurrentLocation(
      highAccuracy: true,
      forceFresh: true,
    );
    if (currentLocation != null) {
      _currentSession = _currentSession!.copyWith(location: currentLocation);
    }

    // Start location tracking for real-time updates
    await _locationService.startTracking();

    // Attach location writer to persist breadcrumb pings and keep header fresh
    if (!_locationWriterAttached) {
      _locationService.setLocationUpdateCallback((loc) async {
        // Guard: ensure session is still active
        final session = _currentSession;
        if (session == null || session.status != SOSStatus.active) return;
        try {
          // Append ping to subcollection
          await _sosRepository.addLocationPing(session.id, loc);
          // Mirror latest into header for UI until Cloud Function is deployed
          await _sosRepository.updateLatestLocation(session.id, loc);
        } catch (e) {
          AppLogger.w(
            'Failed to persist location update',
            tag: 'SOSService',
            error: e,
          );
        }
      });
      _locationWriterAttached = true;
    }

    // Persist session to Firestore: prefer server callable (regional) with fallback
    try {
      // Try server-mediated creation for better latency and server-side enforcement
      try {
        final preferredRegion = await _getPreferredRegionCode();
        final client = SosCallableClient();
        final loc = _currentSession!.location;
        final sessionId = await client.createSession(
          preferredRegion: preferredRegion,
          type: _mapTypeForServer(_currentSession!.type),
          userMessage: _currentSession!.userMessage,
          location: {
            'lat': loc.latitude,
            'lng': loc.longitude,
            'accuracy': loc.accuracy,
            if (loc.address != null && loc.address!.isNotEmpty)
              'address': loc.address,
          },
        );
        // Adopt server-assigned id
        _currentSession = _currentSession!.copyWith(id: sessionId);
      } catch (e) {
        // Fallback: client-side merge write
        AppLogger.w(
          'Callable createSosSession failed; falling back to direct write',
          tag: 'SOSService',
          error: e,
        );
      }

      // Merge app-side fields (contacts, profile, impact, etc.) into header
      await _sosRepository.createOrUpdateFromSession(_currentSession!);

      // Set the active session pointer so Cloud Function knows this is the current session
      try {
        final authUser = AuthService.instance.currentUser;
        if (authUser.id.isNotEmpty) {
          await _sosRepository.setActiveSessionPointer(
            authUser.id,
            _currentSession!.id,
          );
        }
      } catch (e) {
        debugPrint('SOSService: Failed to set active session pointer - $e');
      }

      // Start listening for status updates from SAR coordinators
      _startFirestoreListener(_currentSession!.id);

      AppLogger.i(
        'SOS session persisted to Firestore and listener started',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.w('Failed to persist sos_session', tag: 'SOSService', error: e);
      // Queue for offline delivery and continue app flow
      try {
        await OfflineSOSQueueService().enqueue(
          _currentSession!,
          reason: 'persist_failed',
        );
      } catch (_) {}
    }

    // Send alerts to emergency contacts
    try {
      await _sendEmergencyAlerts();
    } catch (e) {
      debugPrint('SOSService: Emergency alerts failed - $e');
      // Offer SMS fallback prompt so user can send via carrier network
      try {
        await OfflineSOSQueueService().offerSmsPrompt(_currentSession!);
      } catch (_) {}
    }

    // Start SMS notifications to emergency contacts
    try {
      final contacts = _contactsService.enabledContacts;
      if (contacts.isNotEmpty) {
        await SMSService.instance.startSMSNotifications(
          _currentSession!,
          contacts,
        );
        AppLogger.i(
          'SMS notifications started for ${contacts.length} emergency contacts',
          tag: 'SOSService',
        );
      }
    } catch (e) {
      AppLogger.w(
        'Failed to start SMS notifications',
        tag: 'SOSService',
        error: e,
      );
    }

    // Start push notification scheduler
    try {
      await NotificationScheduler.instance.startNotifications(_currentSession!);
      AppLogger.i('Push notification scheduler started', tag: 'SOSService');
    } catch (e) {
      AppLogger.w(
        'Failed to start notification scheduler',
        tag: 'SOSService',
        error: e,
      );
    }

    // Send detailed SOS message to chat channels
    await _sendSOSChatMessage();

    // Send emergency SOS via satellite if available
    await _sendSatelliteEmergencyAlert();

    // Start voice verification if not test mode
    if (!_currentSession!.isTestMode) {
      _startVoiceVerification();
    }

    // Strong haptic feedback
    HapticFeedback.heavyImpact();

    AppLogger.i('SOS activated - ${_currentSession!.id}', tag: 'SOSService');

    // Log SOS activation to analytics
    try {
      await SOSAnalyticsService.instance.logSOSActivation(_currentSession!);
    } catch (e) {
      debugPrint('Analytics logging failed (non-fatal): $e');
    }

    // Start Android foreground service to keep delivery/tracking alive
    try {
      await ForegroundServiceManager.start(
        title: 'REDP!NG SOS Active',
        text: 'Ensuring delivery and location updates',
      );
    } catch (_) {}

    // Start tracking rescue responses
    await _rescueResponseService.startTrackingSession(_currentSession!);

    // Create SOS ping for SAR coordination (may be disabled by config)
    try {
      await _sosPingService.createPingFromSession(_currentSession!);
      AppLogger.i('SOS ping created for SAR coordination', tag: 'SOSService');
    } catch (e) {
      AppLogger.w('Failed to create SOS ping', tag: 'SOSService', error: e);
      // Continue without SOS ping
    }

    // 🤖 AI: Start monitoring for auto emergency services call
    // AI emergency call monitoring removed - SMS notifications handle all emergency alerts
    if (_currentSession!.type == SOSType.crashDetection ||
        _currentSession!.type == SOSType.fallDetection) {
      AppLogger.i(
        'Emergency detected - SMS notifications will alert contacts',
        tag: 'SOSService',
      );
    }

    _onSessionUpdated?.call(_currentSession!);

    // Optionally offer SMS fallback immediately if user prefers
    try {
      final prefs = await SharedPreferences.getInstance();
      final alwaysSms = prefs.getBool('always_sms_fallback') ?? false;
      if (alwaysSms) {
        await OfflineSOSQueueService().offerSmsPrompt(_currentSession!);
      }
    } catch (_) {}
  }

  /// Determine preferred region code for callable selection.
  /// Returns one of: 'AU' | 'EU' | 'AF' | 'AS'. Defaults to 'AU'.
  Future<String> _getPreferredRegionCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pref = prefs.getString('sos_preferred_region');
      if (pref != null && pref.isNotEmpty) {
        final code = pref.toUpperCase();
        if (code == 'AU' || code == 'EU' || code == 'AF' || code == 'AS') {
          return code;
        }
      }
    } catch (_) {}
    return 'AU';
  }

  String _mapTypeForServer(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'manual';
      case SOSType.crashDetection:
        return 'crash';
      case SOSType.fallDetection:
        return 'fall';
      case SOSType.panicButton:
        return 'panic_button';
      case SOSType.voiceCommand:
        return 'voice_command';
      case SOSType.externalTrigger:
        return 'external_trigger';
    }
  }

  /// Start countdown timer
  void _startCountdown() {
    int remainingSeconds = AppConstants.sosCountdownSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      _onCountdownTick?.call(remainingSeconds);

      // Haptic feedback for each second
      HapticFeedback.selectionClick();

      if (remainingSeconds <= 0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  /// Handle crash detection from sensor service
  void _handleCrashDetected(ImpactInfo impactInfo) async {
    // Prevent rapid re-starts from repeated detections
    final nowCrash = DateTime.now();
    if (_lastSessionStart != null &&
        nowCrash.difference(_lastSessionStart!) < _sessionStartCooldown) {
      return;
    }
    // Check if there's already an active session (countdown or active)
    if (_currentSession != null &&
        (_currentSession!.status == SOSStatus.countdown ||
            _currentSession!.status == SOSStatus.active)) {
      return; // Already in session
    }

    debugPrint(
      'SOSService: Crash detected (${impactInfo.accelerationMagnitude.toStringAsFixed(2)} m/s²), starting auto SOS',
    );

    // Get current location
    final location =
        await _locationService.getCurrentLocation(
          highAccuracy: true,
          forceFresh: true,
        ) ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );

    // Get current user ID
    final currentUser = _userProfileService.currentProfile;
    final userId = currentUser?.id ?? 'anonymous_user';

    // Generate AI-powered crash description based on impact data
    final crashMessage = _generateCrashMessage(impactInfo);

    // Create session with impact info and AI-generated message
    _currentSession = SOSSession(
      id: _generateSessionId(),
      userId: userId,
      type: SOSType.crashDetection,
      status: SOSStatus.countdown,
      startTime: DateTime.now(),
      location: location,
      impactInfo: impactInfo,
      userMessage: crashMessage,
      isTestMode: false,
    );
    _lastSessionStart = DateTime.now();

    _startCountdown();
    _onSessionStarted?.call(_currentSession!);

    // Bring the SOS UI to the foreground so the user can see/cancel the countdown
    try {
      AppRouter.router.go(AppRouter.main);
    } catch (_) {}
  }

  /// Handle fall detection from sensor service
  void _handleFallDetected(ImpactInfo impactInfo) async {
    // Prevent rapid re-starts from repeated detections
    final nowFall = DateTime.now();
    if (_lastSessionStart != null &&
        nowFall.difference(_lastSessionStart!) < _sessionStartCooldown) {
      return;
    }
    // Check if there's already an active session (countdown or active)
    if (_currentSession != null &&
        (_currentSession!.status == SOSStatus.countdown ||
            _currentSession!.status == SOSStatus.active)) {
      return; // Already in session
    }

    debugPrint(
      'SOSService: Fall detected (${impactInfo.accelerationMagnitude.toStringAsFixed(2)} m/s²), starting auto SOS',
    );

    // Get current location
    final location =
        await _locationService.getCurrentLocation(
          highAccuracy: true,
          forceFresh: true,
        ) ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );

    // Get current user ID
    final currentUser = _userProfileService.currentProfile;
    final userId = currentUser?.id ?? 'anonymous_user';

    // Generate AI-powered fall description based on impact data
    final fallMessage = _generateFallMessage(impactInfo);

    // Create session with impact info and AI-generated message
    _currentSession = SOSSession(
      id: _generateSessionId(),
      userId: userId,
      type: SOSType.fallDetection,
      status: SOSStatus.countdown,
      startTime: DateTime.now(),
      location: location,
      impactInfo: impactInfo,
      userMessage: fallMessage,
      isTestMode: false,
    );
    _lastSessionStart = DateTime.now();

    _startCountdown();
    _onSessionStarted?.call(_currentSession!);

    // Bring the SOS UI to the foreground so the user can see/cancel the countdown
    try {
      AppRouter.router.go(AppRouter.main);
    } catch (_) {}
  }

  /// Generate AI-powered crash description based on impact data
  String _generateCrashMessage(ImpactInfo impactInfo) {
    final magnitude = impactInfo.accelerationMagnitude;
    final severity = impactInfo.severity;

    // AI logic to determine crash severity and type
    if (severity == ImpactSeverity.critical || magnitude > 40.0) {
      // Severe high-speed crash
      return 'SEVERE CRASH DETECTED: High-speed collision detected (${magnitude.toStringAsFixed(1)}g force). Major impact detected. Possible severe injuries. IMMEDIATE emergency response required. Airbags likely deployed.';
    } else if (severity == ImpactSeverity.high || magnitude > 25.0) {
      // Moderate to severe crash
      return 'CRASH DETECTED: Significant collision (${magnitude.toStringAsFixed(1)}g force). Moderate to severe impact. Airbags may have deployed. Medical attention recommended. Help is on the way.';
    } else if (severity == ImpactSeverity.medium || magnitude > 15.0) {
      // Minor to moderate crash
      return 'CRASH DETECTED: Vehicle collision detected (${magnitude.toStringAsFixed(1)}g force). Impact suggests fender-bender or minor accident. Check for injuries. Emergency services notified.';
    } else {
      // Low-impact detection
      return 'CRASH DETECTED: Low-impact collision or hard braking event (${magnitude.toStringAsFixed(1)}g force). Minor accident detected. Verifying assistance needs.';
    }
  }

  /// Generate AI-powered fall description based on impact data
  String _generateFallMessage(ImpactInfo impactInfo) {
    final magnitude = impactInfo.accelerationMagnitude;
    final severity = impactInfo.severity;
    final verificationReason = impactInfo.verificationReason;

    // AI logic to determine fall severity and context
    if (severity == ImpactSeverity.critical || magnitude > 30.0) {
      // Critical fall - high risk
      String message =
          'CRITICAL FALL DETECTED: Severe impact detected (${magnitude.toStringAsFixed(1)}g force). High-risk injury potential. ';
      if (verificationReason != null) {
        message += '$verificationReason. ';
      }
      message +=
          'IMMEDIATE medical assistance required. User may be unconscious or severely injured.';
      return message;
    } else if (severity == ImpactSeverity.high || magnitude > 20.0) {
      // Severe fall
      String message =
          'SEVERE FALL DETECTED: High-impact fall (${magnitude.toStringAsFixed(1)}g force). ';
      if (verificationReason != null) {
        message += '$verificationReason. ';
      }
      message +=
          'User may have hit head or sustained serious injury. Emergency medical attention recommended.';
      return message;
    } else if (severity == ImpactSeverity.medium || magnitude > 12.0) {
      // Moderate fall
      String message =
          'FALL DETECTED: Moderate impact fall (${magnitude.toStringAsFixed(1)}g force). ';
      if (verificationReason != null) {
        message += '$verificationReason. ';
      }
      message += 'User may need assistance. Possible injury. Help dispatched.';
      return message;
    } else {
      // Minor fall or slip
      return 'FALL DETECTED: Minor fall or slip detected (${magnitude.toStringAsFixed(1)}g impact). User may have tripped or lost balance. Verifying if assistance is needed.';
    }
  }

  /// Send emergency alerts to contacts
  Future<void> _sendEmergencyAlerts() async {
    if (_currentSession == null) return;

    try {
      // Send alerts to all enabled emergency contacts
      final alertLogs = await _contactsService.sendEmergencyAlerts(
        _currentSession!,
      );

      // Extract contact IDs that were successfully contacted
      final contactedIds = alertLogs
          .where((log) => log.status == AlertStatus.sent)
          .map((log) => log.contactId)
          .toSet()
          .toList();

      // Update session with contacted contacts
      _currentSession = _currentSession!.copyWith(
        contactedEmergencyContacts: contactedIds,
      );

      debugPrint('SOSService: Sent alerts to ${contactedIds.length} contacts');
      _onSessionUpdated?.call(_currentSession!);
    } catch (e) {
      debugPrint('SOSService: Error sending emergency alerts - $e');
    }
  }

  /// Send detailed SOS message to chat channels with user identification
  Future<void> _sendSOSChatMessage() async {
    if (_currentSession == null) return;

    try {
      final userProfile = _userProfileService.currentProfile;

      // Generate user-friendly emergency message
      final messageContent = userProfile?.name.isNotEmpty == true
          ? 'Emergency assistance needed for ${userProfile!.name}'
          : 'Emergency assistance needed';

      // Send to chat service with full user details
      await _chatService.sendSOSMessage(
        session: _currentSession!,
        content: messageContent,
        location: _currentSession!.location,
      );

      debugPrint('SOSService: Detailed SOS message sent to chat channels');
    } catch (e) {
      debugPrint('SOSService: Error sending SOS chat message - $e');
    }
  }

  /// Send emergency alert via satellite communication
  Future<void> _sendSatelliteEmergencyAlert() async {
    if (_currentSession == null) return;

    try {
      // Check if satellite communication is available
      if (!_satelliteService.canSendEmergency) {
        debugPrint('SOSService: Satellite communication not available');
        return;
      }

      final userProfile = _userProfileService.currentProfile;

      // Create emergency message for satellite
      final satelliteMessage = userProfile?.name.isNotEmpty == true
          ? 'EMERGENCY: ${userProfile!.name} needs immediate assistance'
          : 'EMERGENCY: Assistance needed immediately';

      // Send via satellite
      final success = await _satelliteService.sendEmergencySOS(
        session: _currentSession!,
        customMessage: satelliteMessage,
      );

      if (success) {
        debugPrint('SOSService: Emergency SOS sent via satellite successfully');
      } else {
        debugPrint(
          'SOSService: Emergency SOS queued for satellite transmission',
        );
      }
    } catch (e) {
      debugPrint('SOSService: Error sending satellite emergency alert - $e');
    }
  }

  /// Start voice verification
  void _startVoiceVerification() {
    if (_currentSession == null) return;

    final voiceVerification = VoiceVerificationInfo(
      requestTime: DateTime.now(),
      result: VoiceVerificationResult.pending,
      attemptCount: 1,
    );

    _currentSession = _currentSession!.copyWith(
      voiceVerification: voiceVerification,
    );

    _onVoiceVerificationRequested?.call();

    // Set timeout for voice verification
    _voiceVerificationTimer = Timer(const Duration(seconds: 30), () {
      _handleVoiceVerificationTimeout();
    });

    _onSessionUpdated?.call(_currentSession!);
  }

  /// Handle voice verification timeout
  void _handleVoiceVerificationTimeout() {
    if (_currentSession?.voiceVerification == null) return;

    final updatedVerification = _currentSession!.voiceVerification!.copyWith(
      responseTime: DateTime.now(),
      result: VoiceVerificationResult.noResponse,
    );

    _currentSession = _currentSession!.copyWith(
      voiceVerification: updatedVerification,
    );

    debugPrint('SOSService: Voice verification timeout');
    _onSessionUpdated?.call(_currentSession!);
  }

  /// Process voice verification result
  void processVoiceVerification(String transcription, bool isConfirmed) {
    if (_currentSession?.voiceVerification == null) return;

    _voiceVerificationTimer?.cancel();

    final result = isConfirmed
        ? VoiceVerificationResult.confirmed
        : VoiceVerificationResult.cancelled;

    final updatedVerification = _currentSession!.voiceVerification!.copyWith(
      responseTime: DateTime.now(),
      result: result,
      transcription: transcription,
      confidenceScore: 0.85, // Mock confidence score
    );

    _currentSession = _currentSession!.copyWith(
      voiceVerification: updatedVerification,
    );

    if (!isConfirmed) {
      // If user denied, cancel the SOS
      cancelSOS();
    } else {
      debugPrint('SOSService: Voice verification confirmed');
      _onSessionUpdated?.call(_currentSession!);
    }
  }

  /// Add message to current session
  void addMessage(String content, MessageType type) {
    if (_currentSession == null) return;

    final message = SOSMessage(
      id: _generateMessageId(),
      content: content,
      timestamp: DateTime.now(),
      type: type,
      isDelivered: true,
    );

    final updatedMessages = List<SOSMessage>.from(_currentSession!.messages)
      ..add(message);

    _currentSession = _currentSession!.copyWith(messages: updatedMessages);
    _onSessionUpdated?.call(_currentSession!);
  }

  /// Resolve SOS session
  Future<void> resolveSession() async {
    if (_currentSession == null) return;

    final sessionId = _currentSession!.id;

    // Check for developer exemption
    final authUser = AuthService.instance.currentUser;
    final isDeveloper = authUser.email == _developerEmail;

    if (isDeveloper) {
      debugPrint(
        '🔓 Developer exemption: Allowing session resolution for ${authUser.email}',
      );
    }

    _countdownTimer?.cancel();
    _voiceVerificationTimer?.cancel();
    _stopFirestoreListener();

    // Detach location writer to stop persisting pings
    if (_locationWriterAttached) {
      try {
        // Replace with no-op to avoid nullability changes in LocationService
        _locationService.setLocationUpdateCallback((_) {});
      } catch (_) {}
      _locationWriterAttached = false;
    }
    _locationService.stopTracking();

    final resolvedSession = _currentSession!.copyWith(
      status: SOSStatus.resolved,
      endTime: DateTime.now(),
    );

    // Stop tracking rescue responses
    _rescueResponseService.stopTrackingSession(resolvedSession.id);

    // Stop SMS notifications and send final resolution SMS
    try {
      await SMSService.instance.stopSMSNotifications(
        sessionId,
        sendFinalSMS: true,
      );
      AppLogger.i(
        'SMS notifications stopped with final resolution SMS',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to stop SMS notifications',
        tag: 'SOSService',
        error: e,
      );
    }

    // Stop push notification scheduler and send final notification
    try {
      await NotificationScheduler.instance.stopNotifications(
        sessionId,
        sendFinalNotification: true,
      );
      AppLogger.i(
        'Push notifications stopped with final resolution notification',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to stop notification scheduler',
        tag: 'SOSService',
        error: e,
      );
    }

    // Mark associated SOS ping as resolved
    try {
      _sosPingService.resolvePingBySessionId(sessionId);
      debugPrint(
        'SOSService: Marked SOS ping as resolved for session $sessionId',
      );
    } catch (e) {
      debugPrint('SOSService: Failed to resolve SOS ping: $e');
    }

    // Update persistence
    try {
      _sosRepository.updateStatus(
        resolvedSession.id,
        status: 'resolved',
        endTime: resolvedSession.endTime,
        extra: isDeveloper
            ? {'resolvedByDeveloper': true, 'developerEmail': authUser.email}
            : null,
      );
    } catch (_) {}

    // Clear active session pointer so future sessions don't get auto-resolved
    try {
      if (authUser.id.isNotEmpty) {
        _sosRepository.clearActiveSessionPointer(authUser.id);
      }
    } catch (_) {}

    // Log resolution to analytics
    try {
      await SOSAnalyticsService.instance.logSOSResolution(
        sessionId: sessionId,
        outcome: 'resolved',
        startTime: resolvedSession.startTime,
        resolvedBy: authUser.id,
      );
    } catch (e) {
      debugPrint('Analytics logging failed (non-fatal): $e');
    }

    _currentSession = null;

    debugPrint(
      'SOSService: SOS session resolved - ${resolvedSession.id}${isDeveloper ? ' (Developer exemption)' : ''}',
    );
    _onSessionEnded?.call(resolvedSession);

    // Stop background foreground service
    try {
      ForegroundServiceManager.stop();
    } catch (_) {}
  }

  /// Mark session as false alarm
  Future<void> markAsFalseAlarm() async {
    if (_currentSession == null) return;

    final sessionId = _currentSession!.id;

    _countdownTimer?.cancel();
    _voiceVerificationTimer?.cancel();
    _stopFirestoreListener();
    _locationService.stopTracking();

    final falseAlarmSession = _currentSession!.copyWith(
      status: SOSStatus.falseAlarm,
      endTime: DateTime.now(),
    );

    // Stop tracking rescue responses
    _rescueResponseService.stopTrackingSession(falseAlarmSession.id);

    // Stop SMS notifications and send cancellation SMS
    try {
      await SMSService.instance.stopSMSNotifications(
        sessionId,
        sendFinalSMS: true,
      );
      AppLogger.i(
        'SMS notifications stopped with cancellation SMS',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to stop SMS notifications',
        tag: 'SOSService',
        error: e,
      );
    }

    // Stop push notification scheduler
    try {
      await NotificationScheduler.instance.stopNotifications(
        sessionId,
        sendFinalNotification: true,
      );
      AppLogger.i('Push notifications stopped', tag: 'SOSService');
    } catch (e) {
      AppLogger.w(
        'Failed to stop notification scheduler',
        tag: 'SOSService',
        error: e,
      );
    }

    // Update persistence
    try {
      _sosRepository.updateStatus(
        falseAlarmSession.id,
        status: 'false_alarm',
        endTime: falseAlarmSession.endTime,
      );
    } catch (_) {}

    // Clear active session pointer so future sessions don't get auto-resolved
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        _sosRepository.clearActiveSessionPointer(authUser.id);
      }
    } catch (_) {}

    // Log false alarm to analytics
    try {
      await SOSAnalyticsService.instance.logSOSResolution(
        sessionId: sessionId,
        outcome: 'false_alarm',
        startTime: falseAlarmSession.startTime,
      );
    } catch (e) {
      debugPrint('Analytics logging failed (non-fatal): $e');
    }

    _currentSession = null;

    debugPrint(
      'SOSService: SOS marked as false alarm - ${falseAlarmSession.id}',
    );
    _onSessionEnded?.call(falseAlarmSession);

    try {
      ForegroundServiceManager.stop();
    } catch (_) {}
  }

  /// Test SOS system
  Future<void> testSOS() async {
    debugPrint('SOSService: Starting SOS test');
    await startSOSCountdown(
      type: SOSType.manual,
      userMessage: 'This is a test of the SOS system',
    );
  }

  /// Generate unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'sos_${timestamp}_$random';
  }

  /// Generate unique message ID
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'msg_${timestamp}_$random';
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'currentSession': _currentSession?.toJson(),
      'sensorStatus': _sensorService.getSensorStatus(),
      'locationStatus': _locationService.getLocationStatus(),
    };
  }

  // Getters
  bool get isInitialized => _isInitialized;
  SOSSession? get currentSession => _currentSession;
  bool get hasActiveSession =>
      _currentSession != null &&
      (_currentSession!.status == SOSStatus.countdown ||
          _currentSession!.status == SOSStatus.active);
  bool get isCountdownActive => _currentSession?.status == SOSStatus.countdown;
  bool get isSOSActive => _currentSession?.status == SOSStatus.active;

  // Event handlers
  void setSessionStartedCallback(Function(SOSSession) callback) {
    _onSessionStarted = callback;
  }

  void setSessionUpdatedCallback(Function(SOSSession) callback) {
    _onSessionUpdated = callback;
  }

  void setSessionEndedCallback(Function(SOSSession) callback) {
    _onSessionEnded = callback;
  }

  void setCountdownTickCallback(Function(int) callback) {
    _onCountdownTick = callback;
  }

  void setVoiceVerificationRequestedCallback(Function() callback) {
    _onVoiceVerificationRequested = callback;
  }

  /// Start Firestore listener for real-time status updates from SAR coordinators
  void _startFirestoreListener(String sessionId) {
    try {
      // Cancel existing listener if any
      _firestoreListener?.cancel();

      // Listen to sos_sessions collection for status updates
      _firestoreListener = FirebaseFirestore.instance
          .collection('sos_sessions')
          .doc(sessionId)
          .snapshots()
          .listen(
            (DocumentSnapshot snapshot) {
              if (!snapshot.exists) return;

              try {
                final data = snapshot.data() as Map<String, dynamic>?;
                if (data == null) return;

                // Check if status has changed
                final firestoreStatus = data['status'] as String?;
                if (firestoreStatus == null) return;

                // Map Firestore status to SOSStatus enum
                SOSStatus? newStatus;
                switch (firestoreStatus.toLowerCase()) {
                  case 'countdown':
                    newStatus = SOSStatus.countdown;
                    break;
                  case 'active':
                    newStatus = SOSStatus.active;
                    break;
                  case 'acknowledged':
                    newStatus = SOSStatus.acknowledged;
                    break;
                  case 'assigned':
                  case 'responder_assigned':
                    newStatus = SOSStatus.assigned;
                    break;
                  case 'en_route':
                    newStatus = SOSStatus.enRoute;
                    break;
                  case 'on_scene':
                    newStatus = SOSStatus.onScene;
                    break;
                  case 'in_progress':
                    newStatus = SOSStatus.inProgress;
                    break;
                  case 'resolved':
                  case 'completed':
                    newStatus = SOSStatus.resolved;
                    break;
                  case 'cancelled':
                    newStatus = SOSStatus.cancelled;
                    break;
                  case 'false_alarm':
                    newStatus = SOSStatus.falseAlarm;
                    break;
                }

                // Update local session with raw status preserved in metadata
                if (newStatus != null) {
                  final shouldUpdate =
                      _currentSession?.status != newStatus ||
                      _currentSession?.metadata['rawStatus'] != firestoreStatus;

                  if (shouldUpdate) {
                    _currentSession = _currentSession!.copyWith(
                      status: newStatus,
                      metadata: {
                        ..._currentSession!.metadata,
                        'rawStatus':
                            firestoreStatus, // Preserve raw status for UI
                      },
                    );

                    AppLogger.i(
                      'SOS status updated from Firestore: $firestoreStatus -> $newStatus',
                      tag: 'SOSService',
                    );

                    // Notify UI of status change
                    _onSessionUpdated?.call(_currentSession!);

                    // Provide haptic feedback for status change
                    HapticFeedback.mediumImpact();
                  }
                }

                // Check for rescue team responses array
                bool hasResponseUpdate = false;
                if (data.containsKey('rescueTeamResponses')) {
                  final responsesData =
                      data['rescueTeamResponses'] as List<dynamic>?;
                  if (responsesData != null && _currentSession != null) {
                    try {
                      final responses = responsesData.map((r) {
                        final responseMap = r as Map<String, dynamic>;
                        return RescueTeamResponse.fromJson(responseMap);
                      }).toList();

                      // Check if responses have changed
                      if (responses.length !=
                              _currentSession!.rescueTeamResponses.length ||
                          responses.isNotEmpty &&
                              _currentSession!.rescueTeamResponses.isEmpty) {
                        _currentSession = _currentSession!.copyWith(
                          rescueTeamResponses: responses,
                        );
                        hasResponseUpdate = true;
                        AppLogger.i(
                          'SAR team responses updated: ${responses.length} responses',
                          tag: 'SOSService',
                        );
                      }
                    } catch (e) {
                      AppLogger.w(
                        'Failed to parse rescue team responses',
                        tag: 'SOSService',
                        error: e,
                      );
                    }
                  }
                }

                // Check for SAR responder assignment
                final responderId = data['responderId'] as String?;
                final responderName =
                    data['responderName'] as String? ??
                    (data['responder'] is Map<String, dynamic>
                        ? ((data['responder']['name'] ??
                                  data['responder']['displayName'])
                              as String?)
                        : null);
                if (responderId != null && responderId.isNotEmpty) {
                  AppLogger.i(
                    'SAR responder assigned: $responderId${responderName != null ? ' ($responderName)' : ''}',
                    tag: 'SOSService',
                  );
                  // Store responder info in session metadata so UI can display it
                  if (_currentSession != null) {
                    final currentMeta = Map<String, dynamic>.from(
                      _currentSession!.metadata,
                    );
                    bool changed = false;
                    if (currentMeta['responderId'] != responderId) {
                      currentMeta['responderId'] = responderId;
                      changed = true;
                    }
                    if (responderName != null &&
                        currentMeta['responderName'] != responderName) {
                      currentMeta['responderName'] = responderName;
                      changed = true;
                    }
                    if (changed || hasResponseUpdate) {
                      _currentSession = _currentSession!.copyWith(
                        metadata: currentMeta,
                      );
                      _onSessionUpdated?.call(_currentSession!);
                    }
                  }
                } else if (hasResponseUpdate && _currentSession != null) {
                  // Trigger update callback even if no responder assignment
                  _onSessionUpdated?.call(_currentSession!);
                }
              } catch (e) {
                AppLogger.w(
                  'Error processing Firestore update',
                  tag: 'SOSService',
                  error: e,
                );
              }
            },
            onError: (error) {
              AppLogger.e(
                'Firestore listener error',
                tag: 'SOSService',
                error: error,
              );
            },
          );

      AppLogger.i(
        'Firestore listener started for session: $sessionId',
        tag: 'SOSService',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to start Firestore listener',
        tag: 'SOSService',
        error: e,
      );
    }
  }

  /// Stop Firestore listener
  void _stopFirestoreListener() {
    _firestoreListener?.cancel();
    _firestoreListener = null;
    AppLogger.i('Firestore listener stopped', tag: 'SOSService');
  }

  /// Dispose of the service
  /// Handle session updates from rescue response service
  void _handleSessionUpdated(SOSSession updatedSession) {
    if (_currentSession?.id == updatedSession.id) {
      _currentSession = updatedSession;
      _onSessionUpdated?.call(updatedSession);
    }
  }

  /// Record user interaction (proves user is responsive)
  Future<void> recordUserInteraction(String sessionId) async {
    try {
      AppLogger.i(
        'User interaction recorded for session $sessionId',
        tag: 'SOSService',
      );
      // AI monitoring removed - user interaction tracked via SOS status updates
    } catch (e) {
      AppLogger.e(
        'Failed to record user interaction',
        tag: 'SOSService',
        error: e,
      );
    }
  }

  void dispose() {
    _countdownTimer?.cancel();
    _voiceVerificationTimer?.cancel();
    _stopFirestoreListener();
    _sensorService.dispose();
    _locationService.dispose();
    _rescueResponseService.dispose();
    // AI emergency call service removed
  }
}
