import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
import 'connectivity_monitor_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'notification_service.dart';

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
  final UserProfileService _userProfileService = UserProfileService();
  final SatelliteService _satelliteService = SatelliteService();
  final RescueResponseService _rescueResponseService = RescueResponseService();
  final SOSPingService _sosPingService = SOSPingService();
  final SosRepository _sosRepository = SosRepository();
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();
  final NotificationService _notificationService = NotificationService();

  SOSSession? _currentSession;
  Timer? _countdownTimer;
  Timer? _voiceVerificationTimer;
  static const String _localActiveSessionIdPrefsKey =
      'local_active_sos_session_id';

  static const String _localActiveSessionJsonPrefsKey =
      'local_active_sos_session_json';
  static const String _localActiveSessionSavedAtPrefsKey =
      'local_active_sos_session_saved_at';

  String? _lastSarUpdateNotificationKey;

  Future<void> _notifySenderOfSarUpdateIfNeeded({
    required String sessionId,
    required SOSStatus newStatus,
    required String rawStatus,
    String? responderId,
    String? responderName,
    String? responderOrgName,
    String? responderTeamName,
    String? acknowledgedByName,
    String? acknowledgedByOrg,
    String? assignedByName,
    String? assignedByOrg,
  }) async {
    // Only notify for meaningful SAR-driven updates.
    final normalized = rawStatus.toLowerCase();
    const notifiable = {
      'acknowledged',
      'assigned',
      'responder_assigned',
      'en_route',
      'enroute',
      'on_scene',
      'in_progress',
    };

    if (!notifiable.contains(normalized)) return;

    // Deduplicate: Firestore can emit multiple snapshots.
    final key =
        '$sessionId|$normalized|${responderId ?? ''}|${responderName ?? ''}|${responderOrgName ?? ''}|${responderTeamName ?? ''}|${acknowledgedByName ?? ''}|${acknowledgedByOrg ?? ''}|${assignedByName ?? ''}|${assignedByOrg ?? ''}';
    if (_lastSarUpdateNotificationKey == key) return;
    _lastSarUpdateNotificationKey = key;

    try {
      if (!_notificationService.isInitialized) {
        await _notificationService.initialize();
      }

      String phase;
      String details;

      String formatActor({String? name, String? org, String? team}) {
        final parts = <String>[];
        if (name != null && name.trim().isNotEmpty) parts.add(name.trim());
        if (team != null && team.trim().isNotEmpty) parts.add(team.trim());
        if (org != null && org.trim().isNotEmpty) parts.add(org.trim());
        return parts.join(' • ');
      }

      switch (newStatus) {
        case SOSStatus.acknowledged:
          phase = 'Acknowledged';
          final actor = formatActor(
            name: acknowledgedByName ?? responderName,
            org: acknowledgedByOrg,
          );
          details = actor.isNotEmpty
              ? '$actor acknowledged your SOS.'
              : 'SAR acknowledged your SOS.';
          break;
        case SOSStatus.assigned:
          phase = 'Assigned';
          final actor = formatActor(
            name: responderName,
            team: responderTeamName,
            org: responderOrgName,
          );
          final assigner = formatActor(
            name: assignedByName,
            org: assignedByOrg,
          );
          details = actor.isNotEmpty
              ? '$actor has been assigned.'
              : 'A SAR responder has been assigned.';
          if (assigner.isNotEmpty) {
            details = '$details Assigned by $assigner.';
          }
          break;
        case SOSStatus.enRoute:
          phase = 'En Route';
          final actor = formatActor(
            name: responderName,
            team: responderTeamName,
            org: responderOrgName,
          );
          details = actor.isNotEmpty
              ? '$actor is en route to you.'
              : 'SAR is en route to your location.';
          break;
        case SOSStatus.onScene:
          phase = 'On Scene';
          final actor = formatActor(
            name: responderName,
            team: responderTeamName,
            org: responderOrgName,
          );
          details = actor.isNotEmpty
              ? '$actor has arrived on scene.'
              : 'SAR has arrived on scene.';
          break;
        case SOSStatus.inProgress:
          phase = 'In Progress';
          details = 'Rescue operation is in progress.';
          break;
        default:
          phase = 'Rescue Update';
          details = 'Status updated: $rawStatus';
      }

      await _notificationService.showRescueStatusUpdate(phase, details);
    } catch (e) {
      // Never let notification failures interfere with SOS.
      debugPrint('SOSService: Failed to notify SAR update (continuing) - $e');
    }
  }

  Future<void> _setLocalActiveSessionId(String? sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (sessionId == null || sessionId.trim().isEmpty) {
        await prefs.remove(_localActiveSessionIdPrefsKey);
        await prefs.remove(_localActiveSessionJsonPrefsKey);
        await prefs.remove(_localActiveSessionSavedAtPrefsKey);
      } else {
        await prefs.setString(_localActiveSessionIdPrefsKey, sessionId);
      }
    } catch (_) {
      // best-effort only
    }
  }

  Future<void> _persistLocalActiveSession(SOSSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localActiveSessionIdPrefsKey, session.id);
      await prefs.setString(
        _localActiveSessionJsonPrefsKey,
        jsonEncode(session.toJson()),
      );
      await prefs.setString(
        _localActiveSessionSavedAtPrefsKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // best-effort only
    }
  }

  Future<SOSSession?> _tryRestoreLocalActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString(_localActiveSessionIdPrefsKey);
      if (sessionId == null || sessionId.trim().isEmpty) return null;

      // Prefer queued copy if present (offline activations).
      try {
        await OfflineSOSQueueService().initialize();
      } catch (_) {}

      final queued = OfflineSOSQueueService().getSessionById(sessionId);
      if (queued != null) return queued;

      final raw = prefs.getString(_localActiveSessionJsonPrefsKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final restored = SOSSession.fromJson(decoded);
        if (restored.id.trim().isEmpty) return null;
        if (restored.id != sessionId) return null;
        return restored;
      }
    } catch (_) {
      // best-effort only
    }
    return null;
  }

  Future<void> _adoptRestoredSession(SOSSession session) async {
    _currentSession = session;

    // Keep local marker + JSON in sync so the user doesn't “lose” their SOS
    // across app restarts or temporary auth/network issues.
    await _persistLocalActiveSession(session);

    // Start Firestore listener for real-time updates.
    _startFirestoreListener(session.id);

    // If session is active (not just countdown), restart location tracking.
    if (session.status != SOSStatus.countdown) {
      await _locationService.startTracking();

      // Reattach location writer to persist breadcrumb pings
      if (!_locationWriterAttached) {
        _locationService.setLocationUpdateCallback((loc) async {
          // Guard: ensure session is still active
          final current = _currentSession;
          if (current == null || current.status != SOSStatus.active) return;
          try {
            await _sosRepository.addLocationPing(current.id, loc);
            await _sosRepository.updateLatestLocation(current.id, loc);
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

    // Restart rescue response tracking if needed.
    if (session.status == SOSStatus.active ||
        session.status == SOSStatus.acknowledged ||
        session.status == SOSStatus.assigned ||
        session.status == SOSStatus.enRoute ||
        session.status == SOSStatus.onScene ||
        session.status == SOSStatus.inProgress) {
      try {
        await _rescueResponseService.startTrackingSession(session);
      } catch (e) {
        debugPrint('SOSService: Failed to restart rescue tracking: $e');
      }
    }

    _onSessionStarted?.call(session);
    _onSessionUpdated?.call(session);
  }

  /// Quick restore path used to keep the UI stable even when full service
  /// initialization (Firebase/Auth/Firestore) is still in progress.
  ///
  /// This prevents users from accidentally starting a second SOS while the app
  /// is still restoring the first one (common after offline app relaunch).
  Future<void> quickRestoreFromLocalIfNeeded() async {
    try {
      final existing = _currentSession;
      if (existing != null && !_isTerminalStatus(existing.status)) {
        return;
      }

      final local = await _tryRestoreLocalActiveSession();
      if (local == null) return;

      // If fully initialized, adopt to attach listeners/tracking.
      if (_isInitialized) {
        try {
          await _adoptRestoredSession(local);
          return;
        } catch (_) {
          // Fall back to minimal adopt below.
        }
      }

      // Minimal adopt: keep state visible + prevent duplicate activation.
      _currentSession = local;
      unawaited(_persistLocalActiveSession(local));
      _onSessionStarted?.call(local);
      _onSessionUpdated?.call(local);
    } catch (_) {
      // best-effort only
    }
  }

  StreamSubscription<DocumentSnapshot>? _firestoreListener;
  bool _locationWriterAttached = false;

  bool _isInitialized = false;

  Future<bool> _canResolveHost(
    String host, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final addrs = await InternetAddress.lookup(host).timeout(timeout);
      return addrs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canConnectToHost(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canReachFirestore({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final sw = Stopwatch()..start();
    try {
      // First resolve to IPs with a hard timeout.
      final addrs = await InternetAddress.lookup(
        'firestore.googleapis.com',
      ).timeout(timeout);
      if (addrs.isEmpty) return false;

      // Then attempt TCP connect to one of the resolved IPs.
      // Using InternetAddress here avoids a second DNS lookup inside Socket.connect.
      for (final addr in addrs.take(2)) {
        final remaining =
            timeout - Duration(milliseconds: sw.elapsedMilliseconds);
        if (remaining <= Duration.zero) break;
        try {
          final socket = await Socket.connect(addr, 443, timeout: remaining);
          socket.destroy();
          return true;
        } catch (_) {
          // try next addr
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _computeEffectivelyOffline({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      return await (() async {
        final results = await Connectivity().checkConnectivity();
        final hasInterfaces = results.any((r) => r != ConnectivityResult.none);
        if (!hasInterfaces) return true;

        final reachable = await ConnectivityMonitorService()
            .isInternetReachable(timeout: timeout);
        if (!reachable) return true;

        // If Firestore backend can't be reached, treat as offline for SOS delivery.
        final firestoreReachable = await _canReachFirestore(timeout: timeout);
        return !firestoreReachable;
      })().timeout(timeout, onTimeout: () => true);
    } catch (_) {
      return true;
    }
  }

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
        // Auth can take time to restore on cold start; don't drop active SOS.
        final local = await _tryRestoreLocalActiveSession();
        if (local != null) {
          debugPrint(
            'SOSService: Restored active session from local storage: ${local.id} (status: ${local.status})',
          );
          AppLogger.i(
            'Restore source=local (auth not ready) sessionId=${local.id} status=${local.status}',
            tag: 'SOSService',
          );
          await _adoptRestoredSession(local);

          // If we're offline, ensure the offline queue still has this session
          // so it can publish as soon as the network returns.
          try {
            final offline = await _computeEffectivelyOffline(
              timeout: const Duration(seconds: 2),
            );
            if (offline) {
              await OfflineSOSQueueService().enqueue(
                local,
                reason: 'restore_local_offline',
              );
            }
          } catch (_) {}
        } else {
          debugPrint(
            'SOSService: No authenticated user and no local active session; skipping session restore',
          );
          AppLogger.i(
            'Restore skipped: no auth + no local marker',
            tag: 'SOSService',
          );
        }
        return;
      }

      debugPrint('SOSService: Checking for active session to restore...');
      final activeSession = await _sosRepository.getActiveSession(authUser.id);

      if (activeSession == null) {
        // Firestore may be offline/unreachable. Fall back to local restore.
        final local = await _tryRestoreLocalActiveSession();
        if (local != null) {
          debugPrint(
            'SOSService: Firestore restore unavailable; restored from local storage: ${local.id} (status: ${local.status})',
          );
          AppLogger.i(
            'Restore source=local (firestore unavailable) sessionId=${local.id} status=${local.status}',
            tag: 'SOSService',
          );
          await _adoptRestoredSession(local);
        } else {
          debugPrint('SOSService: No active session to restore');
          AppLogger.i(
            'Restore source=none (no active session in firestore/local)',
            tag: 'SOSService',
          );
        }
        return;
      }

      debugPrint(
        'SOSService: ✅ Restored active session: ${activeSession.id} (status: ${activeSession.status})',
      );
      AppLogger.i(
        'Restore source=firestore sessionId=${activeSession.id} status=${activeSession.status}',
        tag: 'SOSService',
      );

      await _adoptRestoredSession(activeSession);

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
    // Guard: if the app is still restoring an ongoing SOS from local storage,
    // avoid creating a duplicate session.
    await quickRestoreFromLocalIfNeeded();

    // Check if there's already an active session (countdown or active)
    if (_currentSession != null &&
        !_isTerminalStatus(_currentSession!.status)) {
      AppLogger.w(
        'Session already active. Returning existing session (no restart).',
        tag: 'SOSService',
      );
      return _currentSession!;
    }

    // Safety-net: if the local marker is missing but Firestore already has an
    // active session doc for this user, adopt it instead of creating a second
    // active session.
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        final effectivelyOffline = await _computeEffectivelyOffline(
          timeout: const Duration(seconds: 2),
        );
        if (!effectivelyOffline) {
          final existing = await _sosRepository
              .findMostRecentActiveSessionByUser(authUser.id)
              .timeout(const Duration(seconds: 2));
          if (existing != null && !_isTerminalStatus(existing.status)) {
            debugPrint(
              'SOSService: Safety-net adopted existing active session from Firestore: ${existing.id} (status: ${existing.status})',
            );
            await _adoptRestoredSession(existing);
            return _currentSession!;
          }
        }
      }
    } catch (_) {
      // best-effort only
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
    LocationInfo? location;
    try {
      final future = _locationService.getCurrentLocation(
        highAccuracy: true,
        forceFresh: true,
      );

      // Integration/dev testing: don't hang the entire SOS flow waiting for a
      // permission prompt or a GPS fix.
      if (!kReleaseMode && AppConstants.testingModeEnabled) {
        location = await future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
      } else {
        location = await future;
      }
    } catch (_) {
      location = null;
    }

    location ??= LocationInfo(
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

    // Mark this as the locally-active session so offline queue flushing
    // won't publish ghost pings when no SOS is actually active.
    // Best-effort only.
    await _setLocalActiveSessionId(_currentSession!.id);
    unawaited(_persistLocalActiveSession(_currentSession!));

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
  /// The 5-second button hold serves as the countdown, so we skip the service countdown
  Future<SOSSession> activateSOSImmediately({
    SOSType type = SOSType.manual,
    String? userMessage,
    ImpactInfo? impactInfo,
    bool bringToSOSPage = true,
    String? escalationReasonCode,
  }) async {
    debugPrint('SOSService: activateSOSImmediately() called (type=$type)');

    // Guard: if the app is still restoring an ongoing SOS from local storage,
    // avoid creating a duplicate session.
    await quickRestoreFromLocalIfNeeded();

    // Check if there's already an active session
    if (_currentSession != null &&
        !_isTerminalStatus(_currentSession!.status)) {
      debugPrint(
        'SOSService: Session already active; id=${_currentSession!.id}, status=${_currentSession!.status}',
      );

      // If we're effectively offline (or Firestore is unreachable), make sure
      // the active session is still queued for delivery.
      try {
        final effectivelyOffline = await _computeEffectivelyOffline(
          timeout: const Duration(seconds: 2),
        );
        if (effectivelyOffline) {
          await OfflineSOSQueueService().enqueue(
            _currentSession!,
            reason: 'active_session_existing_offline',
          );
          debugPrint(
            'SOSService: Existing active session enqueued for offline delivery',
          );
        }
      } catch (e) {
        debugPrint(
          'SOSService: Existing active session enqueue attempt failed: $e',
        );
      }

      AppLogger.w(
        'Session already active. Returning existing session.',
        tag: 'SOSService',
      );
      return _currentSession!;
    }

    // Safety-net: if the local marker is missing but Firestore already has an
    // active session doc for this user, adopt it instead of creating a second
    // active session.
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        final effectivelyOffline = await _computeEffectivelyOffline(
          timeout: const Duration(seconds: 2),
        );
        if (!effectivelyOffline) {
          final existing = await _sosRepository
              .findMostRecentActiveSessionByUser(authUser.id)
              .timeout(const Duration(seconds: 2));
          if (existing != null && !_isTerminalStatus(existing.status)) {
            debugPrint(
              'SOSService: Safety-net adopted existing active session from Firestore: ${existing.id} (status: ${existing.status})',
            );
            await _adoptRestoredSession(existing);
            return _currentSession!;
          }
        }
      }
    } catch (_) {
      // best-effort only
    }
    // Get current location.
    // IMPORTANT: In airplane mode/offline, forcing a fresh GPS fix can take a
    // long time and makes the UI look like SOS activation "failed".
    // Use cached/last-known location offline; tracking will refine it later.
    debugPrint('SOSService: activateSOSImmediately() computing offline…');
    final effectivelyOffline = await _computeEffectivelyOffline(
      timeout: const Duration(seconds: 2),
    );
    debugPrint(
      'SOSService: activateSOSImmediately() effectivelyOffline=$effectivelyOffline',
    );

    // Attempt to clear any stale activeSessionId pointer (online-only).
    // If Firestore/DNS is down, this can block. Never let it prevent SOS activation.
    // NOTE: We intentionally do NOT clear the activeSessionId pointer to null.
    // Clearing can create a brief window where backend rules/automation may
    // interpret the session as stale and mark it resolved, causing SAR UI
    // to show it briefly and then drop it.

    LocationInfo? location;
    try {
      debugPrint('SOSService: activateSOSImmediately() fetching location…');
      location = await _locationService.getCurrentLocation(
        highAccuracy: true,
        forceFresh: !effectivelyOffline,
      );
    } catch (_) {
      location = null;
    }
    debugPrint(
      'SOSService: activateSOSImmediately() location=${location != null}',
    );
    location ??= LocationInfo(
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
      impactInfo: impactInfo,
      userMessage: userMessage,
      isTestMode: false,
      metadata: {
        ...metadata,
        if (escalationReasonCode != null && escalationReasonCode.isNotEmpty)
          'escalationReason': escalationReasonCode,
      },
    );

    // Online-only: set pointer to this new session id ASAP to avoid any
    // backend automation resolving it as "not the active" session.
    if (!effectivelyOffline) {
      try {
        if (authUser.id.isNotEmpty) {
          await _sosRepository
              .setActiveSessionPointer(authUser.id, _currentSession!.id)
              .timeout(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint(
          'SOSService: Failed to set active session pointer early: $e',
        );
      }
    }

    _lastSessionStart = DateTime.now();

    // Mark this as the locally-active session for offline queue gating.
    await _setLocalActiveSessionId(_currentSession!.id);
    unawaited(_persistLocalActiveSession(_currentSession!));

    // Provide haptic feedback
    HapticFeedback.heavyImpact();

    AppLogger.i(
      'Immediate SOS created - ${_currentSession!.id}',
      tag: 'SOSService',
    );

    // Notify UI immediately so offline activation shows without waiting
    _onSessionStarted?.call(_currentSession!);

    if (bringToSOSPage) {
      try {
        AppRouter.router.go(AppRouter.main);
      } catch (_) {}
    }

    // Activate SOS (no countdown); performs networking/offline enqueue
    try {
      await _activateSOS();
    } catch (e) {
      // Never treat activation as failed once the session is created; any
      // downstream network/tracking errors should degrade to "queued".
      AppLogger.w(
        'SOS activation follow-up failed (non-fatal)',
        tag: 'SOSService',
        error: e,
      );
    }

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

    // Clear offline queue + local active session marker.
    try {
      OfflineSOSQueueService().remove(cancelledSession.id, reason: 'cancelled');
    } catch (_) {}
    _setLocalActiveSessionId(null);

    _currentSession = null;

    // Light haptic feedback
    HapticFeedback.lightImpact();

    AppLogger.i('SOS cancelled - ${cancelledSession.id}', tag: 'SOSService');
    _onSessionEnded?.call(cancelledSession);

    // Auto-monitoring removed - SMS notifications handle emergency contact alerts
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

  /// Immediately activate an in-progress countdown.
  ///
  /// Used for hands-free scenarios (e.g. yelling for help / groaning in pain)
  /// to escalate faster than the full countdown window.
  Future<bool> activateCountdownNow({
    required String reason,
    String? transcription,
  }) async {
    if (_currentSession == null) return false;
    if (_currentSession!.status != SOSStatus.countdown) return false;

    try {
      _countdownTimer?.cancel();
    } catch (_) {}

    try {
      final extra = (transcription == null || transcription.trim().isEmpty)
          ? ''
          : ' | heard: ${transcription.trim()}';
      addMessage(
        'Countdown accelerated: $reason$extra',
        MessageType.systemMessage,
      );
    } catch (_) {}

    await _activateSOS();
    return true;
  }

  /// Activate SOS (after countdown or immediately)
  Future<void> _activateSOS() async {
    if (_currentSession == null) return;

    debugPrint('SOSService: _activateSOS() start (id=${_currentSession!.id})');

    _countdownTimer?.cancel();

    // Mark the session ACTIVE immediately when the countdown completes.
    // Downstream initialization (sensors/location/network persistence) should
    // not block the user's emergency state.
    if (_currentSession!.status != SOSStatus.active) {
      _currentSession = _currentSession!.copyWith(status: SOSStatus.active);
      try {
        _onSessionUpdated?.call(_currentSession!);
      } catch (_) {}
    }

    // Determine connectivity upfront, treating Wi‑Fi without internet as offline.
    // Also treat "Firestore unreachable" as offline so we enqueue reliably.
    debugPrint('SOSService: _activateSOS() computing offline…');
    final isOffline = await _computeEffectivelyOffline(
      timeout: const Duration(seconds: 2),
    );
    debugPrint('SOSService: _activateSOS() isOffline=$isOffline');

    // IMPORTANT: Do not clear the pointer to null here.
    // Instead, ensure it points at the new session id as early as possible.
    if (!isOffline) {
      try {
        final authUser = AuthService.instance.currentUser;
        if (authUser.id.isNotEmpty) {
          await _sosRepository.setActiveSessionPointer(
            authUser.id,
            _currentSession!.id,
          );
          debugPrint(
            'SOSService: Active session pointer set before persist (sessionId=${_currentSession!.id})',
          );
        }
      } catch (e) {
        debugPrint(
          'SOSService: Failed to set active session pointer pre-persist - $e',
        );
      }
    }

    // Ensure sensors are running, then switch to ACTIVE MODE for SOS.
    // Driving Mode may have already started monitoring; if not, start here.
    try {
      if (!_sensorService.isMonitoring) {
        await _sensorService.startMonitoring(
          locationService: _locationService,
          lowPowerMode: false,
        );
      }
      await _sensorService.setActiveMode();
      debugPrint('SOSService: Sensors switched to ACTIVE MODE');
    } catch (e) {
      debugPrint('SOSService: Failed to start/switch sensor mode - $e');
    }

    // Activate satellite service for SOS
    _satelliteService.activateForSOS();

    // Get location.
    // When offline, do not block activation waiting for a fresh GPS fix.
    try {
      final currentLocation = await _locationService.getCurrentLocation(
        highAccuracy: true,
        forceFresh: !isOffline,
      );
      if (currentLocation != null) {
        _currentSession = _currentSession!.copyWith(location: currentLocation);
      }
    } catch (e) {
      // Never let location failures abort SOS activation.
      AppLogger.w(
        'Failed to refresh current location (non-fatal)',
        tag: 'SOSService',
        error: e,
      );
    }

    // Start location tracking for real-time updates
    try {
      await _locationService.startTracking();
    } catch (e) {
      AppLogger.w(
        'Failed to start location tracking (non-fatal)',
        tag: 'SOSService',
        error: e,
      );
    }

    // Attach location writer to persist breadcrumb pings and keep header fresh
    if (!_locationWriterAttached) {
      _locationService.setLocationUpdateCallback((loc) async {
        // Guard: ensure session is still active
        final session = _currentSession;
        if (session == null || session.status != SOSStatus.active) return;

        // Skip Firestore writes when offline (or Wi‑Fi without internet)
        try {
          final results = await Connectivity().checkConnectivity();
          final hasInterfaces = results.any(
            (r) => r != ConnectivityResult.none,
          );
          if (!hasInterfaces) return;
          final reachable = await ConnectivityMonitorService()
              .isInternetReachable(timeout: const Duration(seconds: 2));
          if (!reachable) return;
        } catch (_) {
          return;
        }

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

    // Persist session to Firestore when online; otherwise, offline-first enqueue
    if (!isOffline) {
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
          // Keep local marker in sync so queue gating doesn't mis-classify
          // a valid active SOS as stale.
          await _setLocalActiveSessionId(sessionId);
          unawaited(_persistLocalActiveSession(_currentSession!));

          // Pointer must match the adopted id.
          try {
            final authUser = AuthService.instance.currentUser;
            if (authUser.id.isNotEmpty) {
              await _sosRepository.setActiveSessionPointer(
                authUser.id,
                _currentSession!.id,
              );
            }
          } catch (_) {}
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

        // Pointer is set pre-persist (and again after server id adoption).

        // Start listening for status updates from SAR coordinators
        _startFirestoreListener(_currentSession!.id);

        // Publish SAR dashboard ping when online.
        // This is idempotent per sessionId inside SOSPingService.
        try {
          await _sosPingService.createPingFromSession(_currentSession!);
          debugPrint(
            'SOSService: Published SOS ping to SAR dashboard for session ${_currentSession!.id}',
          );
        } catch (e) {
          AppLogger.w(
            'Failed to publish SOS ping to SAR dashboard (non-fatal)',
            tag: 'SOSService',
            error: e,
          );
        }

        AppLogger.i(
          'SOS session persisted to Firestore and listener started',
          tag: 'SOSService',
        );
      } catch (e) {
        AppLogger.w(
          'Failed to persist sos_session',
          tag: 'SOSService',
          error: e,
        );
        // Queue for offline delivery and continue app flow
        try {
          await OfflineSOSQueueService().enqueue(
            _currentSession!,
            reason: 'persist_failed',
          );
        } catch (_) {}
      }
    } else {
      // Offline: enqueue immediately and offer SMS prompt
      try {
        // Start listening even while offline. The doc may not exist yet, but
        // once the offline queue flushes, SAR updates will flow through.
        _startFirestoreListener(_currentSession!.id);

        await OfflineSOSQueueService().enqueue(
          _currentSession!,
          reason: 'offline',
        );
        AppLogger.i('Offline mode: SOS enqueued', tag: 'SOSService');
        debugPrint('SOSService: Offline enqueue done');
      } catch (e) {
        AppLogger.w('Offline enqueue failed', tag: 'SOSService', error: e);
        debugPrint('SOSService: Offline enqueue FAILED: $e');
      }

      try {
        await OfflineSOSQueueService().offerSmsPrompt(_currentSession!);
        AppLogger.i('Offline mode: SMS prompt offered', tag: 'SOSService');
      } catch (e) {
        AppLogger.w(
          'Offline mode: failed to offer SMS prompt (non-fatal)',
          tag: 'SOSService',
          error: e,
        );
      }
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

    // SMS-first alerts with Wi‑Fi/internet share fallback
    try {
      final contacts = _contactsService.enabledContacts;
      if (contacts.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final enableSms =
            (prefs.getBool('always_allow_emergency_sms') ?? false) ||
            (prefs.getBool('enable_sms_notifications') ?? false);
        final results = await Connectivity().checkConnectivity();
        final hasMobile = results.any((r) => r == ConnectivityResult.mobile);
        bool hasInternet = false;
        try {
          final hasInterfaces = results.any(
            (r) => r != ConnectivityResult.none,
          );
          hasInternet =
              hasInterfaces &&
              await ConnectivityMonitorService().isInternetReachable(
                timeout: const Duration(seconds: 2),
              );
        } catch (_) {
          hasInternet = false;
        }

        bool smsStarted = false;

        // Attempt carrier SMS first when enabled and mobile is available
        if (enableSms && hasMobile) {
          try {
            await SMSService.instance.startSMSNotifications(
              _currentSession!,
              contacts,
            );
            smsStarted = true;
            AppLogger.i(
              'SMS notifications started for ${contacts.length} emergency contacts',
              tag: 'SOSService',
            );
          } catch (e) {
            AppLogger.w(
              'Failed to start SMS notifications (will fallback to internet)',
              tag: 'SOSService',
              error: e,
            );
          }
        }

        // Wi‑Fi/internet-only fallback: offer a user-driven Share prompt.
        // This works locally and overseas as long as the internet works.
        if (!smsStarted && hasInternet && !hasMobile) {
          try {
            await OfflineSOSQueueService().offerSharePrompt(_currentSession!);
            AppLogger.i(
              'Wi‑Fi/internet-only: offered Share prompt for SOS message',
              tag: 'SOSService',
            );
          } catch (e) {
            AppLogger.w(
              'Failed to offer Share prompt',
              tag: 'SOSService',
              error: e,
            );
          }
        }

        // If neither SMS nor internet is available, offer manual SMS prompt
        if (!smsStarted && !hasInternet) {
          try {
            await OfflineSOSQueueService().offerSmsPrompt(_currentSession!);
            AppLogger.i(
              'No internet/mobile: offered SMS prompt',
              tag: 'SOSService',
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      AppLogger.w(
        'Alert delivery (SMS/Internet) flow error',
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

    // Send emergency SOS via satellite if available
    await _sendSatelliteEmergencyAlert();

    // Voice verification must not start after SOS is ACTIVE.
    // Countdown/verification UX happens pre-activation (during countdown) so
    // users can cancel/confirm. Post-activation prompts can cause accidental
    // cancellation (e.g., TTS echo or late callback scheduling).

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
    try {
      await _rescueResponseService.startTrackingSession(_currentSession!);
    } catch (e) {
      AppLogger.w(
        'Failed to start rescue response tracking (non-fatal)',
        tag: 'SOSService',
        error: e,
      );
    }

    // Create SOS ping for SAR coordination (online-only).
    // When offline, let OfflineSOSQueueService publish once internet returns.
    if (!isOffline) {
      try {
        await _sosPingService.createPingFromSession(_currentSession!);
        AppLogger.i('SOS ping created for SAR coordination', tag: 'SOSService');
      } catch (e) {
        AppLogger.w('Failed to create SOS ping', tag: 'SOSService', error: e);
        // Continue without SOS ping
      }
    } else {
      debugPrint('SOSService: Offline - skipping SAR ping creation for now');
    }

    // Auto-call monitoring removed - SMS notifications handle emergency alerts
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
      'SOSService: Crash detected (avg=${impactInfo.accelerationMagnitude.toStringAsFixed(2)} m/s², max=${impactInfo.maxAcceleration.toStringAsFixed(2)} m/s²), starting auto SOS',
    );

    // High-speed crash bypass: reserved for genuinely extreme impacts.
    // In test mode, shake-based triggers should show the countdown UX so the
    // user can cancel/verify; do not bypass the countdown in test mode.
    if (!AppConstants.testingModeEnabled) {
      final bypassThreshold = AppConstants.highSpeedCrashBypassThreshold;
      if (impactInfo.maxAcceleration >= bypassThreshold) {
        debugPrint(
          'SOSService: High-speed impact (max=${impactInfo.maxAcceleration.toStringAsFixed(1)} m/s²) >= ${bypassThreshold.toStringAsFixed(1)} m/s²; bypassing countdown.',
        );
        try {
          await activateSOSImmediately(
            type: SOSType.crashDetection,
            userMessage: _generateCrashMessage(impactInfo),
            impactInfo: impactInfo,
            bringToSOSPage: true,
            escalationReasonCode: 'high_speed_crash_bypass_countdown',
          );
        } catch (e) {
          debugPrint('SOSService: High-speed bypass activation failed: $e');
        }
        return;
      }
    }

    // Get location best-effort, but do not block the countdown UI.
    // ACFD countdown must appear immediately so the user can cancel/verify.
    LocationInfo location =
        _locationService.currentLocationInfo ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );
    try {
      final fresh = await _locationService
          .getCurrentLocation(highAccuracy: true, forceFresh: false)
          .timeout(const Duration(seconds: 2));
      if (fresh != null) location = fresh;
    } catch (_) {
      // keep cached/default
    }

    // Get current user ID
    final currentUser = _userProfileService.currentProfile;
    final userId = currentUser?.id ?? 'anonymous_user';

    // Generate crash description based on impact data
    final crashMessage = _generateCrashMessage(impactInfo);

    // Create session with impact info and generated message
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

    // Get location best-effort, but do not block the countdown UI.
    LocationInfo location =
        _locationService.currentLocationInfo ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );
    try {
      final fresh = await _locationService
          .getCurrentLocation(highAccuracy: true, forceFresh: false)
          .timeout(const Duration(seconds: 2));
      if (fresh != null) location = fresh;
    } catch (_) {
      // keep cached/default
    }

    // Get current user ID
    final currentUser = _userProfileService.currentProfile;
    final userId = currentUser?.id ?? 'anonymous_user';

    // Generate fall description based on impact data
    final fallMessage = _generateFallMessage(impactInfo);

    // Create session with impact info and generated message
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

  /// Generate a crash description based on impact data
  String _generateCrashMessage(ImpactInfo impactInfo) {
    final magnitude = impactInfo.accelerationMagnitude;
    final severity = impactInfo.severity;

    // Heuristic logic to determine crash severity and type
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

  /// Generate a fall description based on impact data
  String _generateFallMessage(ImpactInfo impactInfo) {
    final magnitude = impactInfo.accelerationMagnitude;
    final severity = impactInfo.severity;
    final verificationReason = impactInfo.verificationReason;

    // Heuristic logic to determine fall severity and context
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
      // Never cancel an already-active SOS from voice verification.
      // Only allow cancellation while still in countdown.
      if (_currentSession?.status == SOSStatus.countdown) {
        cancelSOS();
      } else {
        debugPrint(
          'SOSService: Voice verification cancelled/denied but SOS already active; ignoring cancellation',
        );
        _onSessionUpdated?.call(_currentSession!);
      }
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

    // Clear offline queue + local active session marker early.
    try {
      await OfflineSOSQueueService()
          .remove(resolvedSession.id, reason: 'resolved')
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    await _setLocalActiveSessionId(null);

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
      await _sosPingService
          .resolvePingBySessionId(sessionId)
          .timeout(const Duration(seconds: 4));
      debugPrint(
        'SOSService: Marked SOS ping as resolved for session $sessionId',
      );
    } catch (e) {
      debugPrint('SOSService: Failed to resolve SOS ping: $e');
    }

    // Update persistence
    try {
      // Use full session upsert to avoid NOT_FOUND when the initial create
      // failed (e.g., transient offline) but we are now online.
      final extra = isDeveloper
          ? {'resolvedByDeveloper': true, 'developerEmail': authUser.email}
          : null;
      final sessionToPersist = extra == null
          ? resolvedSession
          : resolvedSession.copyWith(
              metadata: {...resolvedSession.metadata, ...extra},
            );
      await _sosRepository
          .createOrUpdateFromSession(sessionToPersist)
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    // Clear active session pointer so future sessions don't get auto-resolved
    try {
      if (authUser.id.isNotEmpty) {
        await _sosRepository
            .clearActiveSessionPointer(authUser.id)
            .timeout(const Duration(seconds: 4));
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

    // Clear offline queue + local active session marker.
    try {
      await OfflineSOSQueueService()
          .remove(falseAlarmSession.id, reason: 'false_alarm')
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    _setLocalActiveSessionId(null);

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

      // Reset per-session notification dedupe
      _lastSarUpdateNotificationKey = null;

      // Listen to sos_sessions collection for status updates
      _firestoreListener = FirebaseFirestore.instance
          .collection('sos_sessions')
          .doc(sessionId)
          .snapshots()
          .listen(
            (DocumentSnapshot snapshot) {
              if (!snapshot.exists) return;

              // If the in-memory session has ended (or no longer matches), ignore.
              final activeSession = _currentSession;
              if (activeSession == null || activeSession.id != sessionId) {
                return;
              }

              try {
                final data = snapshot.data() as Map<String, dynamic>?;
                if (data == null) return;

                final docMetadata = data['metadata'] is Map<String, dynamic>
                    ? (data['metadata'] as Map<String, dynamic>)
                    : (data['metadata'] is Map
                          ? Map<String, dynamic>.from(data['metadata'] as Map)
                          : <String, dynamic>{});

                String? readString(dynamic v) {
                  if (v == null) return null;
                  final s = v.toString();
                  return s.trim().isEmpty ? null : s;
                }

                final responderId = readString(
                  docMetadata['responderId'] ?? data['responderId'],
                );
                final responderName = readString(
                  docMetadata['responderName'] ??
                      data['responderName'] ??
                      (data['responder'] is Map<String, dynamic>
                          ? ((data['responder']['name'] ??
                                    data['responder']['displayName'])
                                as String?)
                          : null),
                );
                final responderOrgName = readString(
                  docMetadata['responderOrgName'],
                );
                final responderTeamName = readString(
                  docMetadata['responderTeamName'],
                );
                final acknowledgedByName = readString(
                  docMetadata['acknowledgedByName'],
                );
                final acknowledgedByOrg = readString(
                  docMetadata['acknowledgedByOrg'],
                );
                final assignedByName = readString(
                  docMetadata['assignedByName'],
                );
                final assignedByOrg = readString(docMetadata['assignedByOrg']);

                final priorStatus = _currentSession?.status;
                final priorResponderId =
                    _currentSession?.metadata['responderId'] as String?;
                final priorResponderName =
                    _currentSession?.metadata['responderName'] as String?;
                final priorResponderOrgName =
                    _currentSession?.metadata['responderOrgName'] as String?;
                final priorResponderTeamName =
                    _currentSession?.metadata['responderTeamName'] as String?;
                final priorAcknowledgedByName =
                    _currentSession?.metadata['acknowledgedByName'] as String?;
                final priorAcknowledgedByOrg =
                    _currentSession?.metadata['acknowledgedByOrg'] as String?;
                final priorAssignedByName =
                    _currentSession?.metadata['assignedByName'] as String?;
                final priorAssignedByOrg =
                    _currentSession?.metadata['assignedByOrg'] as String?;

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
                    final mergedMeta = Map<String, dynamic>.from(
                      _currentSession!.metadata,
                    )..['rawStatus'] = firestoreStatus;
                    if (responderId != null) {
                      mergedMeta['responderId'] = responderId;
                    }
                    if (responderName != null) {
                      mergedMeta['responderName'] = responderName;
                    }
                    if (responderOrgName != null) {
                      mergedMeta['responderOrgName'] = responderOrgName;
                    }
                    if (responderTeamName != null) {
                      mergedMeta['responderTeamName'] = responderTeamName;
                    }
                    if (acknowledgedByName != null) {
                      mergedMeta['acknowledgedByName'] = acknowledgedByName;
                    }
                    if (acknowledgedByOrg != null) {
                      mergedMeta['acknowledgedByOrg'] = acknowledgedByOrg;
                    }
                    if (assignedByName != null) {
                      mergedMeta['assignedByName'] = assignedByName;
                    }
                    if (assignedByOrg != null) {
                      mergedMeta['assignedByOrg'] = assignedByOrg;
                    }

                    _currentSession = _currentSession!.copyWith(
                      status: newStatus,
                      metadata: mergedMeta,
                    );

                    unawaited(_persistLocalActiveSession(_currentSession!));

                    AppLogger.i(
                      'SOS status updated from Firestore: $firestoreStatus -> $newStatus',
                      tag: 'SOSService',
                    );

                    // Notify UI of status change
                    _onSessionUpdated?.call(_currentSession!);

                    // Provide haptic feedback for status change
                    HapticFeedback.mediumImpact();

                    // Notify sender of SAR action updates (best-effort)
                    unawaited(
                      _notifySenderOfSarUpdateIfNeeded(
                        sessionId: sessionId,
                        newStatus: newStatus,
                        rawStatus: firestoreStatus,
                        responderId: responderId,
                        responderName: responderName,
                        responderOrgName: responderOrgName,
                        responderTeamName: responderTeamName,
                        acknowledgedByName: acknowledgedByName,
                        acknowledgedByOrg: acknowledgedByOrg,
                        assignedByName: assignedByName,
                        assignedByOrg: assignedByOrg,
                      ),
                    );

                    // If SAR ended the session remotely, perform local cleanup so
                    // SOS UI resets and background tracking stops.
                    if (_isTerminalStatus(newStatus) &&
                        (priorStatus == null ||
                            !_isTerminalStatus(priorStatus))) {
                      unawaited(
                        _handleRemoteSessionEnded(
                          sessionId: sessionId,
                          terminalStatus: newStatus,
                          rawStatus: firestoreStatus,
                        ),
                      );
                    }
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
                        unawaited(_persistLocalActiveSession(_currentSession!));
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
                final hasResponderIdentity =
                    (responderId != null && responderId.isNotEmpty) ||
                    (responderName != null && responderName.isNotEmpty) ||
                    (responderOrgName != null && responderOrgName.isNotEmpty) ||
                    (responderTeamName != null && responderTeamName.isNotEmpty);

                if (hasResponderIdentity) {
                  AppLogger.i(
                    'SAR responder assigned: ${responderId ?? '-'}${responderName != null ? ' ($responderName)' : ''}',
                    tag: 'SOSService',
                  );
                  // Store responder info in session metadata so UI can display it
                  if (_currentSession != null) {
                    final currentMeta = Map<String, dynamic>.from(
                      _currentSession!.metadata,
                    );
                    bool changed = false;

                    if (responderId != null &&
                        currentMeta['responderId'] != responderId) {
                      currentMeta['responderId'] = responderId;
                      changed = true;
                    }
                    if (responderName != null &&
                        currentMeta['responderName'] != responderName) {
                      currentMeta['responderName'] = responderName;
                      changed = true;
                    }
                    if (responderOrgName != null &&
                        currentMeta['responderOrgName'] != responderOrgName) {
                      currentMeta['responderOrgName'] = responderOrgName;
                      changed = true;
                    }
                    if (responderTeamName != null &&
                        currentMeta['responderTeamName'] != responderTeamName) {
                      currentMeta['responderTeamName'] = responderTeamName;
                      changed = true;
                    }
                    if (acknowledgedByName != null &&
                        currentMeta['acknowledgedByName'] !=
                            acknowledgedByName) {
                      currentMeta['acknowledgedByName'] = acknowledgedByName;
                      changed = true;
                    }
                    if (acknowledgedByOrg != null &&
                        currentMeta['acknowledgedByOrg'] != acknowledgedByOrg) {
                      currentMeta['acknowledgedByOrg'] = acknowledgedByOrg;
                      changed = true;
                    }
                    if (assignedByName != null &&
                        currentMeta['assignedByName'] != assignedByName) {
                      currentMeta['assignedByName'] = assignedByName;
                      changed = true;
                    }
                    if (assignedByOrg != null &&
                        currentMeta['assignedByOrg'] != assignedByOrg) {
                      currentMeta['assignedByOrg'] = assignedByOrg;
                      changed = true;
                    }

                    if (changed || hasResponseUpdate) {
                      _currentSession = _currentSession!.copyWith(
                        metadata: currentMeta,
                      );
                      unawaited(_persistLocalActiveSession(_currentSession!));
                      _onSessionUpdated?.call(_currentSession!);

                      // Assignment can arrive without a status transition.
                      final identityChanged =
                          (priorResponderId != responderId) ||
                          (priorResponderName != responderName) ||
                          (priorResponderOrgName != responderOrgName) ||
                          (priorResponderTeamName != responderTeamName) ||
                          (priorAcknowledgedByName != acknowledgedByName) ||
                          (priorAcknowledgedByOrg != acknowledgedByOrg) ||
                          (priorAssignedByName != assignedByName) ||
                          (priorAssignedByOrg != assignedByOrg);

                      if (identityChanged) {
                        // Provide subtle feedback for responder identity changes.
                        HapticFeedback.selectionClick();

                        final effectiveStatus =
                            _currentSession?.metadata['rawStatus'] as String?;
                        if (effectiveStatus != null) {
                          unawaited(
                            _notifySenderOfSarUpdateIfNeeded(
                              sessionId: sessionId,
                              newStatus: _currentSession!.status,
                              rawStatus: effectiveStatus,
                              responderId: responderId,
                              responderName: responderName,
                              responderOrgName: responderOrgName,
                              responderTeamName: responderTeamName,
                              acknowledgedByName: acknowledgedByName,
                              acknowledgedByOrg: acknowledgedByOrg,
                              assignedByName: assignedByName,
                              assignedByOrg: assignedByOrg,
                            ),
                          );
                        }
                      }
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

  bool _isTerminalStatus(SOSStatus status) {
    return status == SOSStatus.resolved ||
        status == SOSStatus.cancelled ||
        status == SOSStatus.falseAlarm;
  }

  Future<void> _handleRemoteSessionEnded({
    required String sessionId,
    required SOSStatus terminalStatus,
    required String rawStatus,
  }) async {
    final session = _currentSession;
    if (session == null || session.id != sessionId) return;

    // Prevent re-entrancy and stop listening immediately.
    _countdownTimer?.cancel();
    _voiceVerificationTimer?.cancel();
    _stopFirestoreListener();

    // Switch sensors back to LOW POWER MODE when SOS ends
    unawaited(
      _sensorService
          .setLowPowerMode()
          .then((_) {
            debugPrint(
              'SOSService: Sensors switched back to LOW POWER MODE (remote end)',
            );
          })
          .catchError((e) {
            debugPrint('SOSService: Failed to switch sensor mode - $e');
          }),
    );

    // Deactivate satellite service
    try {
      _satelliteService.deactivateFromSOS();
    } catch (_) {}

    // Detach location writer to stop persisting pings
    if (_locationWriterAttached) {
      try {
        // Replace with no-op to avoid nullability changes in LocationService
        _locationService.setLocationUpdateCallback((_) {});
      } catch (_) {}
      _locationWriterAttached = false;
    }
    try {
      _locationService.stopTracking();
    } catch (_) {}

    final endedSession = session.copyWith(
      status: terminalStatus,
      endTime: DateTime.now(),
      metadata: {
        ...session.metadata,
        'rawStatus': rawStatus,
        'endedBy': 'remote',
      },
    );

    // Clear offline queue + local active session marker.
    try {
      await OfflineSOSQueueService()
          .remove(endedSession.id, reason: rawStatus)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await _setLocalActiveSessionId(null);
    } catch (_) {}

    // Stop tracking rescue responses
    try {
      _rescueResponseService.stopTrackingSession(endedSession.id);
    } catch (_) {}

    // Stop SMS notifications and send a final SMS
    try {
      await SMSService.instance.stopSMSNotifications(
        sessionId,
        sendFinalSMS: true,
      );
    } catch (_) {}

    // Stop push notification scheduler and send final notification
    try {
      await NotificationScheduler.instance.stopNotifications(
        sessionId,
        sendFinalNotification: true,
      );
    } catch (_) {}

    // Clear active session pointer so future sessions don't get auto-resolved
    try {
      final authUser = AuthService.instance.currentUser;
      if (authUser.id.isNotEmpty) {
        await _sosRepository
            .clearActiveSessionPointer(authUser.id)
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    _currentSession = null;
    _onSessionEnded?.call(endedSession);

    // Stop background foreground service
    try {
      ForegroundServiceManager.stop();
    } catch (_) {}
  }

  /// Dispose of the service
  /// Handle session updates from rescue response service
  void _handleSessionUpdated(SOSSession updatedSession) {
    if (_currentSession?.id == updatedSession.id) {
      _currentSession = updatedSession;
      unawaited(_persistLocalActiveSession(updatedSession));
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
      // User interaction tracked via SOS status updates
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
    // Auto-call service removed
  }
}
