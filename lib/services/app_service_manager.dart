import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../models/sos_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sos_service.dart';
import 'platform_service.dart';
import 'sensor_service.dart';
import 'location_service.dart';
import 'emergency_contacts_service.dart';
import 'user_profile_service.dart';
import 'notification_service.dart';
import 'sar_service.dart';
import 'hazard_alert_service.dart';
import 'chat_service.dart';
import 'satellite_service.dart';
import 'sar_identity_service.dart';
import 'volunteer_rescue_service.dart';
import 'sar_organization_service.dart';
import 'rescue_response_service.dart';
import 'help_assistant_service.dart';
// phone_ai_service removed - AI emergency calls disabled
import 'phone_ai_integration_service.dart';
import 'ai_assistant_service.dart';
import 'activity_service.dart';
import 'privacy_security_service.dart';
import 'auth_service.dart';
import 'subscription_service.dart';
import 'feature_access_service.dart';
import 'battery_optimization_service.dart';
import 'performance_monitoring_service.dart';
import 'memory_optimization_service.dart';
import 'emergency_mode_service.dart';
import 'emergency_messaging_service.dart';
import 'sar_messaging_service.dart';
import 'sos_ping_service.dart';
import 'messaging_integration_service.dart';
// ignore_for_file: unused_field
import 'native_map_service.dart';
import 'gadget_integration_service.dart';
import 'google_cloud_api_service.dart';
// import 'websocket_communication_service.dart';
import 'performance_optimization_service.dart';
import 'firebase_service.dart';
import 'redping_mode_service.dart';
import 'location_sharing_service.dart';
import 'emergency_detection_service.dart';
import 'safety_monitor_service.dart';
import 'offline_sos_queue_service.dart';
import 'legal_documents_service.dart';
import '../models/sar_identity.dart';
import 'platform_sms_sender_service.dart';
import '../security/secure_storage_service.dart';
import '../security/storage_crypto.dart';
import '../config/env.dart';

/// Central service manager that coordinates all app services
class AppServiceManager {
  /// Lightweight startup verification to avoid heavy work and log spam
  /// Only checks critical permissions/services quickly.
  Future<void> verifyAllServicesAtStartup() async {
    try {
      // Initialize secure storage and ensure encryption key exists early
      await SecureStorageService.instance.initialize();
      await StorageCrypto.ensureMasterKey();
      // Minimal, fast checks only (no wake/hibernate or full tests)
      await _notificationService.initialize();
      await _locationService.initialize();

      // Optionally: pre-warm SOS minimal state (without listeners)
      // Do NOT call triggerFullSystemTest here to avoid heavy startup cost
    } catch (e) {
      debugPrint('verifyAllServicesAtStartup: non-fatal issue: $e');
    }
  }

  static final AppServiceManager _instance = AppServiceManager._internal();
  factory AppServiceManager() => _instance;
  AppServiceManager._internal();

  // Services
  final SOSService _sosService = SOSService();
  final SensorService _sensorService = SensorService();
  final LocationService _locationService = LocationService();
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  final UserProfileService _profileService = UserProfileService();
  final NotificationService _notificationService = NotificationService();
  final SARService _sarService = SARService();
  final HazardAlertService _hazardService = HazardAlertService();
  final ChatService _chatService = ChatService();
  final SatelliteService _satelliteService = SatelliteService();
  final SARIdentityService _sarIdentityService = SARIdentityService();
  final VolunteerRescueService _volunteerService = VolunteerRescueService();
  final SAROrganizationService _organizationService = SAROrganizationService();
  final RescueResponseService _rescueResponseService = RescueResponseService();
  final HelpAssistantService _helpAssistantService = HelpAssistantService();
  // PhoneAIService removed - AI emergency calls disabled
  PhoneAIIntegrationService? _phoneAIIntegrationService;
  final AIAssistantService _aiAssistantService = AIAssistantService();
  final ActivityService _activityService = ActivityService();
  final PrivacySecurityService _privacySecurityService =
      PrivacySecurityService();
  final AuthService _authService = AuthService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;
  final BatteryOptimizationService _batteryOptimizationService =
      BatteryOptimizationService();
  final PerformanceMonitoringService _performanceMonitoringService =
      PerformanceMonitoringService();
  final MemoryOptimizationService _memoryOptimizationService =
      MemoryOptimizationService();
  final EmergencyModeService _emergencyModeService = EmergencyModeService();
  final EmergencyMessagingService _emergencyMessagingService =
      EmergencyMessagingService();
  final SARMessagingService _sarMessagingService = SARMessagingService();
  final SOSPingService _sosPingService = SOSPingService();
  final MessagingIntegrationService _messagingIntegrationService =
      MessagingIntegrationService();
  final NativeMapService _nativeMapService = NativeMapService();
  final GadgetIntegrationService _gadgetIntegrationService =
      GadgetIntegrationService.instance;
  final GoogleCloudApiService _googleCloudApiService = GoogleCloudApiService();
  // final WebSocketCommunicationService _websocketService =
  //     WebSocketCommunicationService();
  final PerformanceOptimizationService _performanceOptimizationService =
      PerformanceOptimizationService();
  final FirebaseService _firebaseService = FirebaseService();
  final LocationSharingService _locationSharingService =
      LocationSharingService();
  final EmergencyDetectionService _emergencyDetectionService =
      EmergencyDetectionService();
  final SafetyMonitorService _safetyMonitorService = SafetyMonitorService();
  final OfflineSOSQueueService _offlineSOSQueueService =
      OfflineSOSQueueService();
  final LegalDocumentsService _legalDocumentsService = LegalDocumentsService();

  bool _isInitialized = false;
  bool _isAppInForeground = true;

  // AI Safety Assistant state (user preference + auto activation)
  bool _aiSafetyAssistantUserEnabled = false; // persisted, default OFF
  bool _aiSafetyAssistantAutoActive = false; // runtime auto state
  DateTime? _lastMovementTime;
  Timer? _aiSafetyAutoTimer;
  static const double _aiSafetyAutoOnSpeedMps = 16.67; // 60 km/h
  static const double _idleSpeedMps = 0.5; // ~stationary threshold
  static const Duration _aiSafetyIdleTimeout = Duration(minutes: 5);
  Timer? _aiSafetyTempTimer;

  // Global app state callbacks
  Function(SOSSession)? _onSOSActivated;
  Function(SOSSession)? _onSOSDeactivated;
  Function(String, String)? _onCriticalAlert;
  Function()? _onServicesReady;
  Function()? _onSettingsChanged;

  // Public getters for services
  SOSService get sosService => _sosService;
  SensorService get sensorService => _sensorService;
  LocationService get locationService => _locationService;
  EmergencyContactsService get contactsService => _contactsService;
  UserProfileService get profileService => _profileService;
  UserProfileService get userProfileService =>
      _profileService; // Alias for compatibility
  NotificationService get notificationService => _notificationService;
  SARService get sarService => _sarService;
  HazardAlertService get hazardService => _hazardService;
  ChatService get chatService => _chatService;
  SatelliteService get satelliteService => _satelliteService;
  SARIdentityService get sarIdentityService => _sarIdentityService;
  VolunteerRescueService get volunteerService => _volunteerService;
  SAROrganizationService get organizationService => _organizationService;
  RescueResponseService get rescueResponseService => _rescueResponseService;
  HelpAssistantService get helpAssistantService => _helpAssistantService;
  // PhoneAIService removed - AI emergency calls disabled
  // AI Integration Service removed - emergency calls handled via SMS only
  PhoneAIIntegrationService get phoneAIIntegrationService =>
      _phoneAIIntegrationService ??= PhoneAIIntegrationService();
  AIAssistantService get aiAssistantService => _aiAssistantService;
  ActivityService get activityService => _activityService;
  PrivacySecurityService get privacySecurityService => _privacySecurityService;
  AuthService get authService => _authService;
  SubscriptionService get subscriptionService => _subscriptionService;
  FeatureAccessService get featureAccessService => _featureAccessService;
  BatteryOptimizationService get batteryOptimizationService =>
      _batteryOptimizationService;
  PerformanceMonitoringService get performanceMonitoringService =>
      _performanceMonitoringService;
  MemoryOptimizationService get memoryOptimizationService =>
      _memoryOptimizationService;
  EmergencyModeService get emergencyModeService => _emergencyModeService;
  EmergencyMessagingService get emergencyMessagingService =>
      _emergencyMessagingService;
  SARMessagingService get sarMessagingService => _sarMessagingService;
  SOSPingService get sosPingService => _sosPingService;
  MessagingIntegrationService get messagingIntegrationService =>
      _messagingIntegrationService;
  NativeMapService get nativeMapService => _nativeMapService;
  GadgetIntegrationService get gadgetIntegrationService =>
      _gadgetIntegrationService;
  GoogleCloudApiService get googleCloudApiService => _googleCloudApiService;
  // WebSocketCommunicationService get websocketService => _websocketService;
  PerformanceOptimizationService get performanceOptimizationService =>
      _performanceOptimizationService;
  FirebaseService get firebaseService => _firebaseService;
  LocationSharingService get locationSharingService => _locationSharingService;
  EmergencyDetectionService get emergencyDetectionService =>
      _emergencyDetectionService;
  SafetyMonitorService get safetyMonitorService => _safetyMonitorService;
  OfflineSOSQueueService get offlineSOSQueueService => _offlineSOSQueueService;
  LegalDocumentsService get legalDocumentsService => _legalDocumentsService;

  // Public getters for state
  bool get isInitialized => _isInitialized;
  bool get isAppInForeground => _isAppInForeground;

  // Public methods for app status and health
  Map<String, dynamic> getAppStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAppInForeground': _isAppInForeground,
      'services': {
        'sosService': _sosService.isInitialized,
        'sensorService': _sensorService.isMonitoring,
        'locationService': _locationService.hasPermission,
        'contactsService': _contactsService.isInitialized,
        'profileService': _profileService.isInitialized,
        'notificationService': _notificationService.isInitialized,
        'sarService': _sarService.isInitialized,
        'satelliteService': _satelliteService.isInitialized,
        // 'phoneAIService': removed
        'activityService': _activityService.isInitialized,
        'emergencyMessagingService': _emergencyMessagingService.isInitialized,
        'sarMessagingService': _sarMessagingService.isInitialized,
        'sosPingService': _sosPingService.isInitialized,
        'messagingIntegrationService':
            _messagingIntegrationService.isInitialized,
        'gadgetIntegrationService': _gadgetIntegrationService.isInitialized,
      },
    };
  }

  double getEmergencyReadinessScore() {
    int score = 0;
    int totalChecks = 0;

    // Check profile completeness
    totalChecks++;
    if (_profileService.isInitialized &&
        _profileService.currentProfile != null) {
      final profile = _profileService.currentProfile!;
      if (profile.emergencyContacts.isNotEmpty) score++;
    }

    // Check emergency contacts
    totalChecks++;
    if (_contactsService.isInitialized &&
        _contactsService.enabledContacts.isNotEmpty) {
      score++;
    }

    // Check location permissions
    totalChecks++;
    if (_locationService.hasPermission) {
      score++;
    }

    // Check notification permissions
    totalChecks++;
    if (_notificationService.isEnabled) {
      score++;
    }

    // Check sensor services
    totalChecks++;
    if (_sensorService.isMonitoring && _sensorService.crashDetectionEnabled) {
      score++;
    }

    // Check SOS service
    totalChecks++;
    if (_sosService.isInitialized) {
      score++;
    }

    return totalChecks > 0 ? (score * 100.0 / totalChecks) : 0.0;
  }

  Future<void> triggerFullSystemTest() async {
    try {
      debugPrint('AppServiceManager: Starting full system test...');

      // Test all services
      await _sosService.initialize();
      // Disable sensor monitoring to reduce CPU load when not in SOS mode
      // await _sensorService.startMonitoring();
      await _locationService.initialize();
      await _contactsService.initialize();
      await _profileService.initialize();
      await _notificationService.initialize();
      await _sarService.initialize();
      await _satelliteService.initialize();
      // await _phoneAIService.initialize(serviceManager: this); // removed
      await _activityService.initialize();
      await _emergencyMessagingService.initialize();
      await _sarMessagingService.initialize(
        sarMemberId: 'default',
        sarMemberName: 'Default User',
        sarMemberType: SARMemberType.volunteer,
      );
      await _sosPingService.initialize();
      await _messagingIntegrationService.initialize();
      await _gadgetIntegrationService.initialize();

      debugPrint('AppServiceManager: Full system test completed successfully');
    } catch (e) {
      debugPrint('AppServiceManager: Full system test failed - $e');
    }
  }

  // Additional methods that are being called throughout the codebase
  void setSettingsChangedCallback(Function() callback) {
    _onSettingsChanged = callback;
  }

  void setServicesReadyCallback(Function() callback) {
    _onServicesReady = callback;
  }

  void setSOSActivatedCallback(Function(SOSSession) callback) {
    _onSOSActivated = callback;
  }

  void setSOSDeactivatedCallback(Function(SOSSession) callback) {
    _onSOSDeactivated = callback;
  }

  void setCriticalAlertCallback(Function(String, String) callback) {
    _onCriticalAlert = callback;
  }

  void dispose() {
    _sosService.dispose();
    _sensorService.dispose();
    _locationService.dispose();
    _contactsService.dispose();
    _profileService.dispose();
    _notificationService.dispose();
    _sarService.dispose();
    _hazardService.dispose();
    _chatService.dispose();
    _satelliteService.dispose();
    // _sarIdentityService.dispose(); // No dispose method
    // _volunteerService.dispose(); // No dispose method
    // _organizationService.dispose(); // No dispose method
    _rescueResponseService.dispose();
    _helpAssistantService.dispose();
    // _phoneAIService.dispose(); // removed
    // AI Integration Service removed
    _activityService.dispose();
    _privacySecurityService.dispose();
    // _legalDocumentsService.dispose(); // No dispose method
    _authService.dispose();
    _subscriptionService.dispose();
    // _featureAccessService.dispose(); // No dispose method
    _batteryOptimizationService.dispose();
    _performanceMonitoringService.dispose();
    _memoryOptimizationService.dispose();
    _emergencyModeService.dispose();
    _emergencyMessagingService.dispose();
    _sarMessagingService.dispose();
    _sosPingService.dispose();
    _messagingIntegrationService.dispose();
    _gadgetIntegrationService.dispose();
    _googleCloudApiService.dispose();
    // _websocketService.dispose();
    _performanceOptimizationService.dispose();
    _firebaseService.dispose();
    _locationSharingService.dispose();
    _emergencyDetectionService.dispose();
    _safetyMonitorService.dispose();
    _offlineSOSQueueService.dispose();
    // _nativeMapService.dispose(); // No dispose method
  }

  /// Initialize all app services in the correct order
  Future<void> initializeAllServices() async {
    if (_isInitialized) return;

    try {
      debugPrint('AppServiceManager: Starting service initialization...');

      // ULTRA BATTERY OPTIMIZATION - Rule 3: Request battery exemption (MANDATORY)
      // This must happen early to ensure 24/7 operation
      try {
        final isExempt = await PlatformService.isBatteryOptimizationDisabled();
        if (!isExempt) {
          debugPrint(
            'AppServiceManager: Requesting battery optimization exemption...',
          );
          await PlatformService.requestBatteryOptimizationExemption();
        } else {
          debugPrint(
            'AppServiceManager: Battery optimization already disabled ✅',
          );
        }
      } catch (e) {
        debugPrint(
          'AppServiceManager: Battery exemption check failed (continuing) - $e',
        );
      }

      // Initialize only essential services first
      await _profileService.initialize();

      // Initialize subscription service (needed for access controls)
      await _subscriptionService.initialize();

      // Initialize feature access service AFTER subscription service
      _featureAccessService.initialize();

      // Initialize usage tracking service
      await _initializeUsageTrackingService();

      // Initialize Google Cloud API service
      await _googleCloudApiService.initialize();
      // Automated protected ping (optional, gated by feature flag) to validate
      // HMAC + nonce + Integrity chain early. Retries for transient failures.
      if (Env.flag<bool>('autoProtectedPingOnStartup', false)) {
        Future.microtask(() async {
          const int maxAttempts = 3;
          int attempt = 0;
          while (attempt < maxAttempts) {
            attempt++;
            final ok = await _googleCloudApiService.protectedPing();
            if (ok) {
              debugPrint(
                'AppServiceManager: Startup protected ping OK (attempt $attempt)',
              );
              break;
            }
            // Break on deterministic failures (missing integrity token) to avoid wasting attempts
            // We detect via last log string pattern; simplest: skip if Play Integrity required and attempt 1 failed.
            // For now keep simple retry unless maxAttempts reached.
            await Future.delayed(Duration(seconds: attempt * 2));
          }
          if (attempt == maxAttempts) {
            debugPrint(
              'AppServiceManager: Startup protected ping failed after $maxAttempts attempts',
            );
          }
        });
      }

      // AI Emergency Call Service removed - SMS notifications handle emergency alerts

      // Initialize WebSocket communication
      // await _websocketService.initialize();

      // Initialize performance optimization
      await _performanceOptimizationService.initialize();

      // Initialize Firebase service
      await _firebaseService.initialize();

      // Initialize location sharing service
      await _locationSharingService.initialize();

      // Initialize emergency detection service
      await _emergencyDetectionService.initialize();

      // Initialize RedPing Mode service
      await RedPingModeService().initialize();

      // Initialize proactive safety monitor (speed/altitude → sticky notifs)
      await _safetyMonitorService.initialize(
        locationService: _locationService,
        notificationService: _notificationService,
      );

      // Initialize notifications (may work without Firebase)
      try {
        await _notificationService.initialize();
        // Handle taps on local notifications (e.g., SMS fallback prompts)
        _notificationService.setNotificationTappedCallback((payload) async {
          try {
            if (payload.startsWith('offline_sos_sms:')) {
              final sessionId = payload.split(':').last;
              final queued = _offlineSOSQueueService.getSessionById(sessionId);
              final session =
                  queued ??
                  _sosService.currentSession ??
                  _buildMinimalSessionForSMS();
              await _contactsService.openSMSComposerForEnabledContacts(session);
            }
          } catch (e) {
            debugPrint(
              'AppServiceManager: Notification tap handling failed - $e',
            );
          }
        });
      } catch (e) {
        debugPrint(
          'AppServiceManager: Notification service failed to initialize - $e',
        );
        // Continue without notifications
      }

      // Initialize location service (essential for SOS)
      await _locationService.initialize();

      // Start safety monitor after location permission is ready
      try {
        await _safetyMonitorService.startMonitoring();
      } catch (_) {}

      // Load and apply AI Safety Assistant preferences + start auto controller
      try {
        final prefs = await SharedPreferences.getInstance();
        _aiSafetyAssistantUserEnabled =
            prefs.getBool('ai_safety_assistant_enabled') ??
            false; // default OFF
        _setupAISafetyAssistantAutomation();
      } catch (e) {
        debugPrint('AppServiceManager: AI Safety Assistant prefs error - $e');
      }

      // Initialize offline SOS queue (ensures queued delivery when back online)
      try {
        await _offlineSOSQueueService.initialize();
      } catch (e) {
        debugPrint('AppServiceManager: Offline SOS queue failed to init - $e');
      }

      // Initialize emergency services (essential for REDP!NG)
      await _contactsService.initialize();
      await _sosService.initialize();

      // If user opted-in, proactively request Android SMS permission at startup
      // to ensure automatic emergency SMS can send without interruption.
      // This is a no-op on non-Android platforms or if already granted.
      try {
        await _preflightSmsPermissionIfEnabled();
      } catch (e) {
        debugPrint('AppServiceManager: SMS preflight skipped - $e');
      }

      // Initialize phone AI integration (voice commands, TTS) with DI to avoid cycles
      try {
        await phoneAIIntegrationService.initialize(serviceManager: this);
      } catch (e) {
        debugPrint(
          'AppServiceManager: PhoneAIIntegrationService init skipped - $e',
        );
      }

      // Initialize native map service
      try {
        await _nativeMapService.initialize();
      } catch (e) {
        debugPrint(
          'AppServiceManager: Native map service failed to initialize - $e',
        );
        // Continue without native map service
      }

      // Initialize other services in background to prevent hanging
      _initializeBackgroundServices();

      _isInitialized = true;
      debugPrint(
        'AppServiceManager: Essential services initialized successfully',
      );

      // Call services ready callback
      _onServicesReady?.call();
    } catch (e) {
      debugPrint('AppServiceManager: Service initialization failed - $e');
      // Mark as initialized anyway to prevent retry loops
      _isInitialized = true;
    }
  }

  SOSSession _buildMinimalSessionForSMS() {
    final loc =
        _locationService.currentLocationInfo ??
        LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime(1970, 1, 1),
        );
    final userId = _profileService.currentProfile?.id ?? 'anonymous_user';
    return SOSSession(
      id: 'sms_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: SOSType.manual,
      status: SOSStatus.active,
      startTime: DateTime.now(),
      location: loc,
      isTestMode: false,
    );
  }

  /// Initialize usage tracking service
  Future<void> _initializeUsageTrackingService() async {
    try {
      // Usage tracking will be initialized separately in app service manager
      debugPrint(
        'AppServiceManager: Usage tracking will be initialized by app service manager',
      );
    } catch (e) {
      debugPrint('AppServiceManager: Usage tracking initialization error - $e');
    }
  }

  /// If the user enabled "Always allow emergency SMS", proactively request
  /// SEND_SMS permission on Android during startup. This avoids first-use
  /// prompts during an emergency.
  Future<void> _preflightSmsPermissionIfEnabled() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('always_allow_emergency_sms') ?? false;
      if (!enabled) return;

      final sms = PlatformSMSSenderService();
      final has = await sms.hasSMSPermission();
      if (!has) {
        await sms.requestSMSPermission();
      }
    } catch (e) {
      // Non-fatal; continue without proactive permission
      debugPrint('AppServiceManager: SMS permission preflight error - $e');
    }
  }

  /// Initialize non-essential services in background with performance optimization
  void _initializeBackgroundServices() {
    // Run in background to prevent app startup hanging
    Future.microtask(() async {
      try {
        // Initialize services in batches to prevent main thread blocking
        await _initializeServiceBatch1();
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Allow UI to breathe

        await _initializeServiceBatch2();
        await Future.delayed(const Duration(milliseconds: 100));

        await _initializeServiceBatch3();
        await Future.delayed(const Duration(milliseconds: 100));

        await _initializeServiceBatch4();

        debugPrint('AppServiceManager: Background services initialized');
      } catch (e) {
        debugPrint(
          'AppServiceManager: Background service initialization failed - $e',
        );
      }
    });
  }

  /// Initialize first batch of services (most critical)
  Future<void> _initializeServiceBatch1() async {
    await _sensorService.startMonitoring(
      locationService: _locationService,
      notificationService: _notificationService,
      lowPowerMode: true,
    );

    // Apply user-configured detection settings (sensitivity & toggles)
    try {
      final prefs = await SharedPreferences.getInstance();
      final crashEnabled = prefs.getBool('crash_detection_enabled');
      final fallEnabled = prefs.getBool('fall_detection_enabled');
      final crashSens = prefs.getDouble('crash_sensitivity');
      final fallSens = prefs.getDouble('fall_sensitivity');

      if (crashEnabled != null) {
        _sensorService.crashDetectionEnabled = crashEnabled;
      }
      if (fallEnabled != null) {
        _sensorService.fallDetectionEnabled = fallEnabled;
      }

      if (crashSens != null) {
        _sensorService.crashThreshold =
            180.0 + (1.0 - crashSens.clamp(0.0, 1.0)) * 40.0; // 180–220
      }
      if (fallSens != null) {
        _sensorService.fallThreshold =
            140.0 + (1.0 - fallSens.clamp(0.0, 1.0)) * 60.0; // 140–200
      }
    } catch (_) {}

    // Set up violent phone handling detection callback
    _sensorService.setViolentHandlingDetectedCallback(_handleViolentHandling);

    await _sarService.initialize();
    await _hazardService.initialize();
  }

  /// Handle violent phone handling detection - Silent alert to emergency contacts
  /// No user notification, just discreet alert to family/emergency contacts
  void _handleViolentHandling(ImpactInfo impactInfo) async {
    try {
      debugPrint('AppServiceManager: Violent phone handling detected');
      debugPrint(
        '   Impact: ${impactInfo.accelerationMagnitude.toStringAsFixed(1)} m/s²',
      );
      debugPrint('   Severity: ${impactInfo.severity.name}');
      debugPrint('   🔕 Preparing silent alert to emergency contacts...');

      // Get emergency contacts
      final contacts = _contactsService.enabledContacts;
      if (contacts.isEmpty) {
        debugPrint('   ⚠️ No emergency contacts configured - alert not sent');
        return;
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      final locationText = location != null
          ? 'https://maps.google.com/?q=${location.latitude},${location.longitude}'
          : 'Location unavailable';

      // Create discreet message
      final timestamp = DateTime.now().toString().substring(0, 16);
      final message =
          'REDPING Safety Alert ($timestamp): Potential distress detected. '
          'Location: $locationText';

      // Log the alert (SMS sending will be implemented through emergency contacts service)
      debugPrint('   📱 Alert message: $message');
      debugPrint('   👥 Recipients: ${contacts.length} contact(s)');

      for (final contact in contacts) {
        debugPrint('      - ${contact.name} (${contact.phoneNumber})');
      }

      // Store the incident for later review
      await _notificationService.showNotification(
        title: 'Safety Monitoring Active',
        body: 'Unusual phone activity detected',
      );

      debugPrint('   ✅ Violent handling incident logged');
    } catch (e) {
      debugPrint(
        'AppServiceManager: Failed to handle violent handling alert: $e',
      );
    }
  }

  /// Initialize second batch of services (communication)
  Future<void> _initializeServiceBatch2() async {
    await _chatService.initialize();
    await _satelliteService.initialize();
    await _sarIdentityService.initialize();
  }

  /// Initialize third batch of services (support)
  Future<void> _initializeServiceBatch3() async {
    await _volunteerService.initialize();
    await _organizationService.initialize();
    await _rescueResponseService.initialize();
    await _helpAssistantService.initialize();
    // await _phoneAIService.initialize(serviceManager: this); // removed
  }

  /// Initialize fourth batch of services (optimization)
  Future<void> _initializeServiceBatch4() async {
    await _activityService.initialize();
    await _privacySecurityService.initialize();
    await _batteryOptimizationService.initialize();
    await _performanceMonitoringService.initialize();
    await _memoryOptimizationService.initialize();
    await _emergencyModeService.initialize();
    await _emergencyMessagingService.initialize();
    await _sarMessagingService.initialize(
      sarMemberId: 'default',
      sarMemberName: 'Default User',
      sarMemberType: SARMemberType.volunteer,
    );
    await _sosPingService.initialize();
    await _messagingIntegrationService.initialize();
    await _gadgetIntegrationService.initialize();

    // Initialize AI Assistant Service with dependencies
    await _aiAssistantService.initialize(
      serviceManager: this,
      notificationService: _notificationService,
      userProfileService: _profileService,
      locationService: _locationService,
    );
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        debugPrint('AppServiceManager: App resumed');
        break;
      case AppLifecycleState.paused:
        _isAppInForeground = false;
        debugPrint('AppServiceManager: App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('AppServiceManager: App detached');
        break;
      case AppLifecycleState.inactive:
        debugPrint('AppServiceManager: App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('AppServiceManager: App hidden');
        break;
    }
  }

  // ================= AI SAFETY ASSISTANT (Toggle + Auto) =================
  /// Returns whether AI Safety Assistant should be actively monitoring now
  /// Combines user preference and auto-on rule (speed > 60 km/h)
  bool get isAISafetyAssistantActive =>
      _aiSafetyAssistantUserEnabled || _aiSafetyAssistantAutoActive;

  /// Returns the stored user preference (manual toggle)
  bool get isAISafetyAssistantUserEnabled => _aiSafetyAssistantUserEnabled;

  /// Update the user preference and persist; applies immediately
  Future<void> setAISafetyAssistantUserEnabled(bool enabled) async {
    _aiSafetyAssistantUserEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_safety_assistant_enabled', enabled);
    } catch (_) {}
    _applyAISafetyAssistantState();
    _onSettingsChanged?.call();
  }

  void _setupAISafetyAssistantAutomation() {
    // Seed last movement time to now to avoid premature idle-off
    _lastMovementTime ??= DateTime.now();

    // Periodic controller: check current speed + idle timeout every 10s
    _aiSafetyAutoTimer?.cancel();
    _aiSafetyAutoTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      try {
        final speed =
            _locationService.currentLocationInfo?.speed ??
            _locationService.currentPosition?.speed ??
            0.0; // m/s

        // Track movement for idle detection
        if (speed >= _idleSpeedMps) {
          _lastMovementTime = DateTime.now();
        }

        // Auto ON when speed >= 60 km/h
        final shouldAutoOn = speed >= _aiSafetyAutoOnSpeedMps;

        // Auto OFF when idle for >= 5 minutes
        final now = DateTime.now();
        final isIdleTooLong =
            _lastMovementTime != null &&
            now
                    .difference(_lastMovementTime!)
                    .compareTo(_aiSafetyIdleTimeout) >=
                0;

        bool newAutoActive = _aiSafetyAssistantAutoActive;
        if (shouldAutoOn) {
          newAutoActive = true;
        } else if (isIdleTooLong) {
          newAutoActive = false;
        }

        if (newAutoActive != _aiSafetyAssistantAutoActive) {
          _aiSafetyAssistantAutoActive = newAutoActive;
          _applyAISafetyAssistantState();
        }
      } catch (e) {
        // Non-fatal; keep previous state
        debugPrint('AI Safety Auto Controller error: $e');
      }
    });

    // Apply initial state at startup
    _applyAISafetyAssistantState();
  }

  void _applyAISafetyAssistantState() {
    final active = isAISafetyAssistantActive;
    try {
      // Gate AI verification background monitoring (ACFD will still trigger verification when needed)
      _sensorService.aiVerificationService?.setMonitoring(active);
    } catch (e) {
      debugPrint('AppServiceManager: Failed to apply AI safety state - $e');
    }
  }

  /// Force-activate AI Safety Assistant for a limited time (e.g., during ACFD window)
  void temporarilyActivateAISafetyAssistant(Duration duration) {
    _aiSafetyAssistantAutoActive = true;
    _applyAISafetyAssistantState();
    _aiSafetyTempTimer?.cancel();
    _aiSafetyTempTimer = Timer(duration, () {
      // Let the periodic controller decide, but remove the temporary force if speed/idle rules don't keep it on
      _aiSafetyAssistantAutoActive = false;
      _applyAISafetyAssistantState();
    });
  }
}
