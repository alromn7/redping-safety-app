// ignore_for_file: dead_code
import 'dart:async';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_session.dart';
import '../core/logging/app_logger.dart';
import 'location_service.dart';
import 'emergency_contact_auto_update_service.dart';
import 'emergency_contacts_service.dart';
import 'phone_ai_integration_service.dart';
import 'user_profile_service.dart';
import 'emergency_event_bus.dart';

/// AI-powered emergency services calling after verification logic
/// Monitors SOS status and SAR dashboard for unattended emergencies
/// NOW INTEGRATED WITH PHONE AI FOR VOICE CALLS
class AIEmergencyCallService {
  static final AIEmergencyCallService _instance =
      AIEmergencyCallService._internal();
  factory AIEmergencyCallService() => _instance;
  AIEmergencyCallService._internal();

  final LocationService _locationService = LocationService();
  final EmergencyContactAutoUpdateService _contactUpdateService =
      EmergencyContactAutoUpdateService();
  final EmergencyContactsService _emergencyContactsService =
      EmergencyContactsService();
  final PhoneAIIntegrationService _phoneAI = PhoneAIIntegrationService();
  final UserProfileService _userProfileService = UserProfileService();
  final EmergencyEventBus _eventBus = EmergencyEventBus();

  Timer? _monitoringTimer;
  Timer? _verificationTimer;
  final Map<String, DateTime> _sessionMonitoring = {};
  final Map<String, int> _verificationAttempts = {};
  final Map<String, bool> _emergencyCallMade = {};
  final Map<String, bool> _sarEscalated =
      {}; // Track if SAR timeout already escalated
  final Map<String, bool> _sarRespondingLogged =
      {}; // Track if SAR responding message already logged

  // ========================================
  // 🚫 EMERGENCY CALL KILL SWITCH
  // ========================================
  // Set to false to COMPLETELY DISABLE all emergency calling functionality
  // This prevents ANY automated phone calls to emergency services or contacts
  // SMS alerts will continue to work normally (SMS-first approach)
  // ignore: constant_identifier_names
  static const bool EMERGENCY_CALL_ENABLED = false;
  // ========================================

  bool _isInitialized = false;
  bool _isMonitoring = false;

  // AI Configuration
  static const Duration _initialVerificationWindow = Duration(
    seconds: 30,
  ); // After crash/fall countdown
  static const Duration _verificationCheckInterval = Duration(
    seconds: 15,
  ); // Check every 15s
  static const Duration _sarResponseTimeout = Duration(
    minutes: 3,
  ); // Wait 3 min for SAR
  static const Duration _totalWaitBeforeCall = Duration(
    minutes: 5,
  ); // Max 5 min before calling
  static const int _maxVerificationAttempts = 3; // Try to verify 3 times
  static const Duration _voiceCheckInterval = Duration(
    seconds: 10,
  ); // Check for voice/movement every 10s

  // Callbacks
  Function(SOSSession, String)? _onEmergencyCallInitiated;
  Function(SOSSession, int)? _onVerificationAttempt;
  Function(SOSSession, String)? _onAIDecision;

  /// Initialize AI Emergency Call Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _locationService.initialize();
      await _contactUpdateService.initialize();

      _isInitialized = true;
      AppLogger.i(
        'AI Emergency Call Service initialized',
        tag: 'AIEmergencyCall',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to initialize AI Emergency Call Service',
        tag: 'AIEmergencyCall',
        error: e,
      );
      throw Exception('AI Emergency Call Service initialization failed: $e');
    }
  }

  /// Start monitoring a crash/fall detected SOS session
  Future<void> startMonitoringSession(SOSSession session) async {
    if (!_isInitialized) {
      await initialize();
    }

    // [TESTING MODE] AI monitoring enabled - will call family contacts instead of 911
    AppLogger.i(
      '🤖 AI: Monitoring ENABLED for testing - will call emergency contacts',
      tag: 'AIEmergencyCall',
    );

    // Only monitor crash/fall detection sessions
    if (session.type != SOSType.crashDetection &&
        session.type != SOSType.fallDetection) {
      AppLogger.i(
        'Session ${session.id} is not crash/fall - skipping AI monitoring',
        tag: 'AIEmergencyCall',
      );
      return;
    }

    // Check if already monitoring
    if (_sessionMonitoring.containsKey(session.id)) {
      AppLogger.w(
        'Already monitoring session ${session.id}',
        tag: 'AIEmergencyCall',
      );
      return;
    }

    AppLogger.i(
      '🤖 AI: Starting emergency monitoring for ${session.type} session ${session.id}',
      tag: 'AIEmergencyCall',
    );

    // Record monitoring start
    _sessionMonitoring[session.id] = DateTime.now();
    _verificationAttempts[session.id] = 0;
    _emergencyCallMade[session.id] = false;

    // Fire event: AI monitoring started
    _eventBus.fireAIMonitoringStarted(
      session.id,
      '${session.type} detected - verifying user responsiveness',
    );

    // Log AI decision
    _onAIDecision?.call(
      session,
      'AI monitoring activated: Crash/fall detected. Starting verification protocol.',
    );

    // Start AI verification timer (after initial countdown completes)
    await Future.delayed(_initialVerificationWindow);

    // Begin monitoring loop
    _startMonitoringLoop(session);
  }

  /// Start the AI monitoring loop for a session
  void _startMonitoringLoop(SOSSession session) {
    if (_monitoringTimer != null && _monitoringTimer!.isActive) {
      _monitoringTimer!.cancel();
    }

    // Only start monitoring if session is in active/countdown status
    if (session.status != SOSStatus.active &&
        session.status != SOSStatus.countdown) {
      AppLogger.i(
        '🤖 AI: Not starting monitoring - session status is ${session.status}',
        tag: 'AIEmergencyCall',
      );
      return;
    }

    _monitoringTimer = Timer.periodic(_verificationCheckInterval, (
      timer,
    ) async {
      // Double-check session is still being monitored
      if (!_sessionMonitoring.containsKey(session.id)) {
        timer.cancel();
        _isMonitoring = false;
        return;
      }
      await _checkSessionStatus(session);
    });

    _isMonitoring = true;
    AppLogger.i(
      '🤖 AI: Monitoring loop started for session ${session.id}',
      tag: 'AIEmergencyCall',
    );
  }

  /// Check session status and make AI decisions
  Future<void> _checkSessionStatus(SOSSession session) async {
    try {
      // Safety check: Stop monitoring if session is no longer being monitored
      if (!_sessionMonitoring.containsKey(session.id)) {
        _monitoringTimer?.cancel();
        _isMonitoring = false;
        return;
      }

      // Calculate time since SOS started
      final timeSinceStart = DateTime.now().difference(
        _sessionMonitoring[session.id]!,
      );

      // AI Logic Step 1: Check if user has cancelled or responded
      if (session.status == SOSStatus.cancelled ||
          session.status == SOSStatus.resolved) {
        AppLogger.i(
          '🤖 AI: User responsive - cancelling emergency call protocol',
          tag: 'AIEmergencyCall',
        );
        _onAIDecision?.call(
          session,
          'User verified responsive. Emergency call cancelled.',
        );
        await stopMonitoringSession(session.id);
        return;
      }

      // AI Logic Step 2: Check for SAR/responder activity through session responses
      final hasActiveResponders = session.rescueTeamResponses.any(
        (r) =>
            r.status == ResponseStatus.acknowledged ||
            r.status == ResponseStatus.enRoute ||
            r.status == ResponseStatus.onScene,
      );

      if (hasActiveResponders) {
        final firstResponseTime = session.rescueTeamResponses
            .where(
              (r) =>
                  r.status == ResponseStatus.acknowledged ||
                  r.status == ResponseStatus.enRoute ||
                  r.status == ResponseStatus.onScene,
            )
            .map((r) => r.responseTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        final elapsedSinceResponder = DateTime.now().difference(
          firstResponseTime,
        );

        if (elapsedSinceResponder < _sarResponseTimeout) {
          // Only log once to avoid spam
          if (_sarRespondingLogged[session.id] != true) {
            _sarRespondingLogged[session.id] = true;
            AppLogger.i(
              '🤖 AI: SAR team responding - waiting for arrival',
              tag: 'AIEmergencyCall',
            );
            _onAIDecision?.call(
              session,
              'SAR team en route. Monitoring rescue progress.',
            );
          }
          return;
        } else {
          // Only escalate once per session
          if (_sarEscalated[session.id] != true) {
            _sarEscalated[session.id] = true;
            AppLogger.w(
              '🤖 AI: SAR response timeout exceeded - escalating to emergency services',
              tag: 'AIEmergencyCall',
            );
            _onAIDecision?.call(
              session,
              'SAR response delayed beyond ${_sarResponseTimeout.inMinutes} minutes. Escalating.',
            );
            // Proceed to emergency call logic below
          } else {
            // Already escalated - just return to avoid repeated escalation messages
            return;
          }
        }
      }

      // AI Logic Step 3: Verify user responsiveness
      final userResponsive = await _verifyUserResponsiveness(session);

      // Fire event: Verification attempt
      final attemptNumber = (_verificationAttempts[session.id] ?? 0) + 1;
      _eventBus.fireAIVerificationAttempt(
        session.id,
        attemptNumber,
        userResponsive,
      );

      if (userResponsive) {
        AppLogger.i(
          '🤖 AI: User showed signs of responsiveness',
          tag: 'AIEmergencyCall',
        );

        // Fire event: User responsive
        _eventBus.fire(
          EmergencyEvent(
            type: EmergencyEventType.aiUserResponsive,
            sessionId: session.id,
            timestamp: DateTime.now(),
            message:
                'User movement/interaction detected - monitoring continues',
          ),
        );

        _onAIDecision?.call(
          session,
          'User movement/voice detected. Continuing monitoring.',
        );
        _verificationAttempts[session.id] = 0; // Reset counter
        return;
      }

      // AI Logic Step 4: Increment verification attempts
      _verificationAttempts[session.id] =
          (_verificationAttempts[session.id] ?? 0) + 1;
      final attempts = _verificationAttempts[session.id]!;

      AppLogger.w(
        '🤖 AI: User unresponsive - attempt $attempts/$_maxVerificationAttempts',
        tag: 'AIEmergencyCall',
      );
      _onVerificationAttempt?.call(session, attempts);

      // AI Logic Step 5: Check if we should make emergency call
      final shouldCall = _shouldMakeEmergencyCall(
        session,
        timeSinceStart,
        attempts,
        hasActiveResponders,
      );

      if (shouldCall && !(_emergencyCallMade[session.id] ?? false)) {
        AppLogger.e(
          '🚨 AI DECISION: Making emergency services call - user unresponsive',
          tag: 'AIEmergencyCall',
        );

        // Fire event: User unresponsive - emergency call decision
        _eventBus.fire(
          EmergencyEvent(
            type: EmergencyEventType.aiUserUnresponsive,
            sessionId: session.id,
            timestamp: DateTime.now(),
            message: 'User unresponsive after $attempts verification attempts',
            data: {
              'attempts': attempts,
              'timeElapsed': timeSinceStart.inMinutes,
              'hasActiveResponders': hasActiveResponders,
            },
          ),
        );

        await _makeEmergencyCall(session);
      }
    } catch (e) {
      AppLogger.e(
        'Error checking session status',
        tag: 'AIEmergencyCall',
        error: e,
      );
    }
  }

  /// AI decision logic: Should we call emergency services?
  bool _shouldMakeEmergencyCall(
    SOSSession session,
    Duration timeSinceStart,
    int attempts,
    bool hasResponders,
  ) {
    // Critical condition: Severe crash/fall with no SAR response
    if (session.impactInfo != null &&
        session.impactInfo!.accelerationMagnitude > 35.0) {
      if (timeSinceStart >= Duration(minutes: 2) && !hasResponders) {
        return true; // Critical impact + no help = immediate call
      }
    }

    // Moderate condition: Multiple verification failures
    if (attempts >= _maxVerificationAttempts) {
      if (timeSinceStart >= Duration(minutes: 3)) {
        return true; // User unresponsive for 3+ minutes = call
      }
    }

    // Timeout condition: Too much time has passed
    if (timeSinceStart >= _totalWaitBeforeCall) {
      return true; // 5 minutes elapsed = definitely call
    }

    // SAR response condition: SAR delayed beyond acceptable time
    if (hasResponders && timeSinceStart >= Duration(minutes: 4)) {
      return true; // SAR taking too long = call for backup
    }

    return false;
  }

  /// Verify user responsiveness through multiple signals
  Future<bool> _verifyUserResponsiveness(SOSSession session) async {
    try {
      // Check 1: Voice commands or app interaction
      final prefs = await SharedPreferences.getInstance();
      final lastInteraction = prefs.getInt(
        'last_user_interaction_${session.id}',
      );

      if (lastInteraction != null) {
        final timeSinceInteraction =
            DateTime.now().millisecondsSinceEpoch - lastInteraction;
        if (timeSinceInteraction < _voiceCheckInterval.inMilliseconds) {
          AppLogger.i(
            '🤖 AI: User interaction detected within ${timeSinceInteraction}ms',
            tag: 'AIEmergencyCall',
          );
          return true;
        }
      }

      // Check 2: Location movement (indicates consciousness)
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        final distance = _calculateDistance(
          session.location.latitude,
          session.location.longitude,
          currentLocation.latitude,
          currentLocation.longitude,
        );

        if (distance > 5.0) {
          // Moved more than 5 meters
          AppLogger.i(
            '🤖 AI: User movement detected (${distance.toStringAsFixed(1)}m)',
            tag: 'AIEmergencyCall',
          );
          return true;
        }
      }

      // Check 3: Phone sensors (accelerometer activity)
      // Note: This would require sensor service integration
      // For now, we'll rely on interaction and location

      return false;
    } catch (e) {
      AppLogger.e(
        'Error verifying user responsiveness',
        tag: 'AIEmergencyCall',
        error: e,
      );
      return false; // Assume unresponsive on error (safer)
    }
  }

  /// [TESTING MODE] Make call to family contact instead of 911
  Future<void> _makeEmergencyCall(SOSSession session) async {
    // 🚫 KILL SWITCH: Emergency calling completely disabled
    if (!EMERGENCY_CALL_ENABLED) {
      AppLogger.w(
        '🚫 EMERGENCY CALL DISABLED: AI would have called emergency contacts',
        tag: 'AIEmergencyCall',
      );
      AppLogger.i(
        '📱 SMS alerts are still active and functioning normally',
        tag: 'AIEmergencyCall',
      );

      // Mark as "made" to prevent retry loops
      _emergencyCallMade[session.id] = true;

      // Fire event for logging (call would have been made)
      _eventBus.fireAIEmergencyCallInitiated(
        session.id,
        'DISABLED - No call made',
        'Emergency calling disabled by kill switch',
      );

      return;
    }

    try {
      _emergencyCallMade[session.id] = true;

      // [TESTING MODE] Get family emergency contacts instead of 911
      final familyContacts = await _getFamilyEmergencyContacts(session);
      final primaryNumber = familyContacts['primary']!;
      final secondaryNumber = familyContacts['secondary']!;
      final primaryName = familyContacts['primaryName']!;
      final secondaryName = familyContacts['secondaryName']!;

      // Fire event: AI initiating emergency call
      _eventBus.fireAIEmergencyCallInitiated(
        session.id,
        '[TESTING] $primaryNumber ($primaryName)',
        'User unresponsive after verification protocol',
      );

      AppLogger.e(
        '🚨 [TESTING] AI CALLING FAMILY CONTACT:',
        tag: 'AIEmergencyCall',
      );
      AppLogger.e(
        '  📞 Primary Contact: $primaryNumber - $primaryName',
        tag: 'AIEmergencyCall',
      );
      AppLogger.e(
        '  📞 Backup Contact: $secondaryNumber - $secondaryName',
        tag: 'AIEmergencyCall',
      );

      // Log AI decision
      final impactInfo = session.impactInfo != null
          ? '${session.impactInfo!.accelerationMagnitude.toStringAsFixed(1)}g impact'
          : 'unknown severity';

      // Get SAR status directly from session
      final sarStatus = session.rescueTeamResponses.isEmpty
          ? 'No SAR response'
          : '${session.rescueTeamResponses.length} SAR team(s) - Status: ${session.rescueTeamResponses.first.status.name}';

      final callReason =
          '''
🤖 [TESTING MODE] AI Emergency Call to Family:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📞 CALLING FAMILY CONTACTS:
   1️⃣ Primary: $primaryNumber
      ($primaryName)
   
   2️⃣ Backup: $secondaryNumber
      ($secondaryName)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 INCIDENT DETAILS:
• Type: ${session.type}
• Impact: $impactInfo
• User Status: UNRESPONSIVE after ${_verificationAttempts[session.id]} verification attempts
• Location: ${session.location.latitude}, ${session.location.longitude}
• Time Elapsed: ${DateTime.now().difference(_sessionMonitoring[session.id]!).inMinutes} minutes
• SAR Status: $sarStatus

🤖 AI Decision: Calling family contact - user may need assistance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';

      _onAIDecision?.call(session, callReason);
      _onEmergencyCallInitiated?.call(session, primaryNumber);

      // Store emergency call record
      await _recordEmergencyCall(
        session,
        primaryNumber,
        secondaryNumber,
        callReason,
      );

      // [TESTING MODE] Call primary family contact (wife/spouse)
      await _dialEmergencyNumber(primaryNumber, session, primaryName);

      // Note: If primary fails or busy, secondary contact is available as backup
      // User can manually dial backup contact from call log
    } catch (e) {
      AppLogger.e(
        'Failed to make emergency call',
        tag: 'AIEmergencyCall',
        error: e,
      );
    }
  }

  /// Get appropriate emergency number based on user location
  /// 🤖 AI: Auto-updates from online sources
  /// Number 1: National emergency hotline
  /// Number 2: Local emergency services (closest available)
  Future<Map<String, String>> _getEmergencyNumbers(SOSSession session) async {
    try {
      AppLogger.i(
        '🔍 AI: Auto-updating emergency contact numbers based on location...',
        tag: 'AIEmergencyCall',
      );

      // Auto-update emergency contacts based on current location
      final contacts = await _contactUpdateService.autoUpdateEmergencyContacts(
        session.location,
      );

      final nationalContact = contacts['national'];
      final localContact = contacts['local'];

      // Priority 1: National emergency hotline
      String primaryNumber = nationalContact?.phoneNumber ?? '112';

      // Priority 2: Local emergency services (if available)
      String? secondaryNumber;
      if (localContact != null && localContact.phoneNumber != 'LOCATION_ONLY') {
        secondaryNumber = localContact.phoneNumber;
      }

      AppLogger.i(
        '📞 National Emergency: $primaryNumber (${nationalContact?.name ?? "Default"})',
        tag: 'AIEmergencyCall',
      );
      if (secondaryNumber != null) {
        AppLogger.i(
          '🏥 Local Emergency: $secondaryNumber (${localContact?.name ?? "N/A"})',
          tag: 'AIEmergencyCall',
        );
      } else {
        AppLogger.w(
          '⚠️ No local emergency service found, using national number only',
          tag: 'AIEmergencyCall',
        );
      }

      return {
        'primary': primaryNumber,
        'secondary':
            secondaryNumber ??
            primaryNumber, // Fallback to national if no local
        'primaryName': nationalContact?.name ?? 'Emergency Services',
        'secondaryName':
            localContact?.name ?? nationalContact?.name ?? 'Emergency Services',
      };
    } catch (e) {
      AppLogger.e(
        'Error getting emergency numbers',
        tag: 'AIEmergencyCall',
        error: e,
      );

      // Safe fallback to international emergency number
      return {
        'primary': '112',
        'secondary': '112',
        'primaryName': 'International Emergency Services',
        'secondaryName': 'International Emergency Services',
      };
    }
  }

  /// [TESTING MODE] Get family emergency contacts instead of 911
  Future<Map<String, String>> _getFamilyEmergencyContacts(
    SOSSession session,
  ) async {
    try {
      AppLogger.i(
        '🔍 [TESTING] Getting family emergency contacts...',
        tag: 'AIEmergencyCall',
      );

      // Get all emergency contacts
      final contacts = _emergencyContactsService.contacts;

      if (contacts.isEmpty) {
        AppLogger.w(
          '⚠️ No emergency contacts found, using fallback',
          tag: 'AIEmergencyCall',
        );
        return {
          'primary': '0000000000',
          'secondary': '0000000000',
          'primaryName': 'No Contact Configured',
          'secondaryName': 'No Contact Configured',
        };
      }

      // Sort by priority (lowest number = highest priority)
      final sortedContacts = List.from(contacts)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      // Get primary contact (highest priority, typically wife/spouse)
      final primaryContact = sortedContacts.first;
      final primaryNumber = primaryContact.phoneNumber;
      final primaryName = primaryContact.name;

      // Get secondary contact (second highest priority)
      String secondaryNumber = primaryNumber;
      String secondaryName = primaryName;

      if (sortedContacts.length > 1) {
        final secondaryContact = sortedContacts[1];
        secondaryNumber = secondaryContact.phoneNumber;
        secondaryName = secondaryContact.name;
      }

      AppLogger.i(
        '📞 Primary Contact: $primaryNumber - $primaryName',
        tag: 'AIEmergencyCall',
      );
      AppLogger.i(
        '📞 Backup Contact: $secondaryNumber - $secondaryName',
        tag: 'AIEmergencyCall',
      );

      return {
        'primary': primaryNumber,
        'secondary': secondaryNumber,
        'primaryName': primaryName,
        'secondaryName': secondaryName,
      };
    } catch (e) {
      AppLogger.e(
        'Error getting family emergency contacts',
        tag: 'AIEmergencyCall',
        error: e,
      );

      // Safe fallback
      return {
        'primary': '0000000000',
        'secondary': '0000000000',
        'primaryName': 'Error Getting Contact',
        'secondaryName': 'Error Getting Contact',
      };
    }
  }

  /// [AI VOICE CALL] Dial emergency number using Phone AI Integration
  /// Uses PhoneAIIntegrationService for Google Assistant/Siri voice calls
  Future<void> _dialEmergencyNumber(
    String number,
    SOSSession session,
    String serviceName,
  ) async {
    // 🚫 KILL SWITCH: Emergency calling disabled
    if (!EMERGENCY_CALL_ENABLED) {
      AppLogger.w(
        '🚫 EMERGENCY CALL DISABLED: Would have called $number ($serviceName)',
        tag: 'AIEmergencyCall',
      );
      AppLogger.i(
        '📱 SMS alerts are still active and will notify emergency contacts',
        tag: 'AIEmergencyCall',
      );
      return;
    }

    try {
      // Prepare comprehensive emergency message
      final emergencyMessage = _prepareEmergencyMessage(session, serviceName);

      AppLogger.i(
        '🤖 AI Voice Call: Using Phone AI Integration to call $number ($serviceName)',
        tag: 'AIEmergencyCall',
      );

      // Initialize Phone AI if needed
      if (!_phoneAI.isInitialized) {
        await _phoneAI.initialize();
      }

      // Make AI voice call through Phone AI Integration Service
      await _phoneAI.makeAIVoiceCall(
        contactId:
            number, // Using phone number as contactId for emergency services
        phoneNumber: number,
        contactName: serviceName,
        emergencyMessage: emergencyMessage,
      );

      // Show notification about the call
      await _showEmergencyCallNotification(number, session, serviceName);

      AppLogger.i(
        '✅ AI Voice Call initiated via Phone AI Integration',
        tag: 'AIEmergencyCall',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to make AI voice call',
        tag: 'AIEmergencyCall',
        error: e,
      );

      // Fallback: Try regular phone dialer
      try {
        final uri = Uri(scheme: 'tel', path: number);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          AppLogger.i(
            '📞 Fallback: Regular call initiated',
            tag: 'AIEmergencyCall',
          );
        }
      } catch (e2) {
        AppLogger.e(
          'All call methods failed',
          tag: 'AIEmergencyCall',
          error: e2,
        );
      }
    }
  }

  // Note: Voice call methods moved to PhoneAIIntegrationService
  // for better separation of concerns and reusability

  /// Prepare emergency message for voice call
  String _prepareEmergencyMessage(SOSSession session, String contactName) {
    final eventType = session.type.name;

    // Get user name from profile service
    final userName = _userProfileService.currentProfile?.name ?? 'Unknown User';

    // Get impact info if available
    String impactInfo = '';
    if (session.impactInfo != null) {
      impactInfo =
          '${session.impactInfo!.accelerationMagnitude.toStringAsFixed(1)} G impact detected';
    } else {
      impactInfo = '$eventType incident detected';
    }

    // Get time of incident
    final incidentTime = DateTime.now().toString().substring(11, 19);

    return '''
Hello. Emergency alert from RedPing Safety App.
$impactInfo at $incidentTime.
My client $userName is unresponsive after multiple verification attempts.
Location: ${session.location.latitude.toStringAsFixed(4)}, ${session.location.longitude.toStringAsFixed(4)}.
Please check on them immediately.
To verify this incident, visit www.redpingsafety.com, navigate to SAR dashboard to find SOS details.
This is an automated emergency call.
''';
  }

  /// Show notification about emergency call
  Future<void> _showEmergencyCallNotification(
    String number,
    SOSSession session,
    String serviceName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_emergency_call_${session.id}',
        'AI called $number ($serviceName) at ${DateTime.now().toIso8601String()}',
      );

      AppLogger.i('Emergency call notification stored', tag: 'AIEmergencyCall');
    } catch (e) {
      AppLogger.e(
        'Failed to show notification',
        tag: 'AIEmergencyCall',
        error: e,
      );
    }
  }

  /// Record emergency call in database
  Future<void> _recordEmergencyCall(
    SOSSession session,
    String primaryNumber,
    String secondaryNumber,
    String reason,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final callRecord = {
        'session_id': session.id,
        'primary_number': primaryNumber,
        'secondary_number': secondaryNumber,
        'call_time': DateTime.now().toIso8601String(),
        'reason': reason,
        'ai_decision': true,
        'user_responsive': false,
        'verification_attempts': _verificationAttempts[session.id],
      };

      await prefs.setString(
        'emergency_call_${session.id}',
        callRecord.toString(),
      );
      AppLogger.i(
        'Emergency call recorded in database',
        tag: 'AIEmergencyCall',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to record emergency call',
        tag: 'AIEmergencyCall',
        error: e,
      );
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        (cos((lat2 - lat1) * p) / 2) +
        (cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2);

    return 12742 * asin(sqrt(a)) * 1000; // Distance in meters
  }

  /// Stop monitoring a session
  Future<void> stopMonitoringSession(String sessionId) async {
    if (_sessionMonitoring.containsKey(sessionId)) {
      AppLogger.i(
        '🤖 AI: Stopping monitoring for session $sessionId',
        tag: 'AIEmergencyCall',
      );

      _sessionMonitoring.remove(sessionId);
      _verificationAttempts.remove(sessionId);
      _sarEscalated.remove(sessionId); // Clean up escalation tracking
      _sarRespondingLogged.remove(
        sessionId,
      ); // Clean up SAR responding tracking

      // Don't remove emergency call flag (keep for records)

      if (_sessionMonitoring.isEmpty) {
        _monitoringTimer?.cancel();
        _isMonitoring = false;
      }
    }
  }

  /// Record user interaction (called from UI when user interacts)
  Future<void> recordUserInteraction(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_user_interaction_$sessionId',
        DateTime.now().millisecondsSinceEpoch,
      );

      AppLogger.i(
        'User interaction recorded for session $sessionId',
        tag: 'AIEmergencyCall',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to record user interaction',
        tag: 'AIEmergencyCall',
        error: e,
      );
    }
  }

  /// Set callbacks
  void setOnEmergencyCallInitiated(Function(SOSSession, String) callback) {
    _onEmergencyCallInitiated = callback;
  }

  void setOnVerificationAttempt(Function(SOSSession, int) callback) {
    _onVerificationAttempt = callback;
  }

  void setOnAIDecision(Function(SOSSession, String) callback) {
    _onAIDecision = callback;
  }

  /// Get current monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'activeSessions': _sessionMonitoring.length,
      'sessions': _sessionMonitoring.keys.toList(),
      'emergencyCallsMade': _emergencyCallMade.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
    };
  }

  /// Dispose
  void dispose() {
    _monitoringTimer?.cancel();
    _verificationTimer?.cancel();
    _sessionMonitoring.clear();
    _verificationAttempts.clear();
    _emergencyCallMade.clear();
    _isMonitoring = false;
    _isInitialized = false;

    AppLogger.i('AI Emergency Call Service disposed', tag: 'AIEmergencyCall');
  }

  /// Public: Resolve emergency numbers based on session location or current GPS
  /// Returns keys: 'primary', 'secondary', 'primaryName', 'secondaryName'
  Future<Map<String, String>> resolveEmergencyNumbers({
    SOSSession? session,
    LocationInfo? location,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Prefer explicit inputs
      final loc =
          location ??
          session?.location ??
          await _locationService.getCurrentLocation();
      if (loc == null) {
        // Fallback to safe international number
        return {
          'primary': '112',
          'secondary': '112',
          'primaryName': 'International Emergency Services',
          'secondaryName': 'International Emergency Services',
        };
      }

      final contacts = await _contactUpdateService.autoUpdateEmergencyContacts(
        loc,
      );
      final nationalContact = contacts['national'];
      final localContact = contacts['local'];

      String primaryNumber = nationalContact?.phoneNumber ?? '112';
      String? secondaryNumber;
      if (localContact != null && localContact.phoneNumber != 'LOCATION_ONLY') {
        secondaryNumber = localContact.phoneNumber;
      }

      return {
        'primary': primaryNumber,
        'secondary': secondaryNumber ?? primaryNumber,
        'primaryName': nationalContact?.name ?? 'Emergency Services',
        'secondaryName':
            localContact?.name ?? nationalContact?.name ?? 'Emergency Services',
      };
    } catch (e) {
      AppLogger.w(
        'resolveEmergencyNumbers failed, using fallback',
        tag: 'AIEmergencyCall',
        error: e,
      );
      return {
        'primary': '112',
        'secondary': '112',
        'primaryName': 'International Emergency Services',
        'secondaryName': 'International Emergency Services',
      };
    }
  }

  /// Public: Manually initiate a quick emergency call from the UI
  /// - Uses AI auto-updated emergency numbers based on current session/location
  /// - Dials the primary emergency number and records the call
  /// - Optionally allows overriding the number to dial directly
  /// - BYPASSES KILL SWITCH (this is a manual user action, not automatic AI)
  Future<void> quickCall(SOSSession session, {String? overrideNumber}) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final numbers = await _getEmergencyNumbers(session);
      final primaryNumber = numbers['primary']!;
      final secondaryNumber = numbers['secondary'] ?? primaryNumber;
      final primaryName = numbers['primaryName'] ?? 'Emergency Services';

      final numberToDial = overrideNumber ?? primaryNumber;
      final serviceName = overrideNumber != null
          ? 'Emergency Services'
          : primaryName;

      // Fire callbacks and record the call context
      _onEmergencyCallInitiated?.call(session, numberToDial);

      await _recordEmergencyCall(
        session,
        numberToDial,
        secondaryNumber,
        'Manual quick call from SOS screen',
      );

      // Direct launch for manual calls (bypasses kill switch)
      // Manual user-initiated calls should ALWAYS work regardless of kill switch
      final uri = Uri(scheme: 'tel', path: numberToDial);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.i(
          '📞 Manual quick call to $numberToDial ($serviceName)',
          tag: 'AIEmergencyCall',
        );
      } else {
        throw Exception('Cannot launch phone dialer for $numberToDial');
      }
    } catch (e) {
      AppLogger.e('Quick call failed', tag: 'AIEmergencyCall', error: e);
    }
  }

  /// Public: Manually initiate a quick emergency call without an SOS session
  /// - Resolves numbers from current GPS location
  /// - Dials the primary number directly (no session record)
  Future<void> quickCallWithoutSession() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      final numbers = await resolveEmergencyNumbers();
      final numberToDial = numbers['primary'] ?? '112';

      final uri = Uri(scheme: 'tel', path: numberToDial);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.i(
          '📞 Emergency quick call (no session) to $numberToDial',
          tag: 'AIEmergencyCall',
        );
      } else {
        throw Exception('Cannot launch phone dialer');
      }
    } catch (e) {
      AppLogger.e(
        'Quick call (no session) failed',
        tag: 'AIEmergencyCall',
        error: e,
      );
      // Best-effort fallback attempt
      try {
        final numbers = await resolveEmergencyNumbers();
        final fallbackUri = Uri.parse('tel:${numbers['primary'] ?? '112'}');
        await launchUrl(fallbackUri);
      } catch (_) {}
    }
  }

  /// Public: Manually initiate a quick emergency call to a specific number without an SOS session
  /// - Bypasses number resolution and dials the provided number directly
  /// - Useful for UI flows offering Police/Ambulance/Fire options when no SOS is active
  Future<void> quickCallWithoutSessionToNumber(
    String number, {
    String serviceName = 'Emergency Services',
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.i(
          '📞 Emergency quick call (no session) to $number ($serviceName)',
          tag: 'AIEmergencyCall',
        );
      } else {
        throw Exception('Cannot launch phone dialer');
      }
    } catch (e) {
      AppLogger.e(
        'Quick call (no session) override failed',
        tag: 'AIEmergencyCall',
        error: e,
      );
      // Best-effort fallback attempt to the provided number
      try {
        final fallbackUri = Uri.parse('tel:$number');
        await launchUrl(fallbackUri);
      } catch (_) {}
    }
  }
}
