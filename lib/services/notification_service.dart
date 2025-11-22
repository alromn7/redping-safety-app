import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/sos_session.dart';
import 'user_profile_service.dart';

/// Service for handling local and push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final UserProfileService _userProfileService = UserProfileService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _firebaseMessaging;

  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;
  bool _isEnabled = true; // User can disable notifications
  String? _fcmToken;

  // Callbacks
  Function(String)? _onNotificationTapped;
  Function(RemoteMessage)? _onPushMessageReceived;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved notification preference
      await _loadNotificationPreference();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging (optional)
      await _initializeFirebaseMessaging();

      _isInitialized = true;
      AppLogger.i('Initialized successfully', tag: 'NotificationService');
    } catch (e) {
      AppLogger.e('Initialization error', tag: 'NotificationService', error: e);
      throw Exception('Failed to initialize notification service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTapped?.call(response.payload ?? '');
      },
    );

    // Request permissions
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      AppLogger.w(
        'Android notifications permission request failed (continuing without it)',
        tag: 'NotificationService',
        error: e,
      );
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.i(
          'Push notification permission granted',
          tag: 'NotificationService',
        );
      } else {
        AppLogger.w(
          'Push notification permission denied',
          tag: 'NotificationService',
        );
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging!.getToken();
      AppLogger.d('FCM Token - $_fcmToken', tag: 'NotificationService');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _onPushMessageReceived?.call(message);
      });

      // Subscribe to emergency topics
      await _subscribeToTopics();

      _isFirebaseAvailable = true;
      AppLogger.i('Firebase messaging initialized', tag: 'NotificationService');
    } catch (e) {
      AppLogger.w(
        'Firebase messaging not available',
        tag: 'NotificationService',
        error: e,
      );
      _isFirebaseAvailable = false;
      // Continue without Firebase - only local notifications will work
    }
  }

  /// Subscribe to Firebase topics
  Future<void> _subscribeToTopics() async {
    if (_firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.subscribeToTopic(
        AppConstants.emergencyAlertsTopic,
      );
      await _firebaseMessaging!.subscribeToTopic(
        AppConstants.hazardAlertsTopic,
      );
      await _firebaseMessaging!.subscribeToTopic(
        AppConstants.communityUpdatesTopic,
      );

      debugPrint('NotificationService: Subscribed to topics');
    } catch (e) {
      debugPrint('NotificationService: Error subscribing to topics - $e');
    }
  }

  /// Handle foreground push messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'NotificationService: Foreground message received - ${message.messageId}',
    );

    // Show local notification for foreground messages
    showNotification(
      title: message.notification?.title ?? 'REDP!NG Alert',
      body: message.notification?.body ?? 'You have a new alert',
      payload: message.data.toString(),
      importance: _getImportanceFromMessage(message),
    );

    _onPushMessageReceived?.call(message);
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationImportance importance =
        NotificationImportance.defaultImportance,
    bool persistent = false,
    int? notificationId,
  }) async {
    // Check if notifications are enabled
    if (!_isEnabled) {
      debugPrint('NotificationService: Notifications disabled by user');
      return;
    }
    final androidDetails = AndroidNotificationDetails(
      'redping_alerts',
      'REDP!NG Safety Alerts',
      channelDescription: 'Emergency and safety notifications',
      importance: _mapImportance(importance),
      priority: Priority.high,
      ongoing: persistent,
      autoCancel: !persistent,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      color: const Color(0xFFE53935), // AppTheme.primaryRed
      ledColor: const Color(0xFFE53935),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final int id =
        notificationId ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(id, title, body, details, payload: payload);

    debugPrint('NotificationService: Local notification shown - $title');
  }

  /// Show SOS emergency notification with user identification
  Future<void> showSOSNotification(SOSSession session) async {
    final userProfile = _userProfileService.currentProfile;

    final title = session.isAutoTriggered
        ? '🚨 AUTOMATIC SOS ACTIVATED'
        : '🚨 SOS ACTIVATED';

    // Enhanced body with user identification
    final bodyBuffer = StringBuffer();

    if (userProfile?.name.isNotEmpty == true) {
      bodyBuffer.writeln('Person: ${userProfile!.name}');
    }

    bodyBuffer.write(
      session.isAutoTriggered
          ? '${session.type.name.toUpperCase()} detected. '
          : 'Manual activation. ',
    );

    bodyBuffer.write('Emergency contacts notified.');

    if (session.location.address != null) {
      bodyBuffer.write(' Location: ${session.location.address}');
    }

    await showNotification(
      title: title,
      body: bodyBuffer.toString(),
      payload: 'sos_session:${session.id}',
      importance: NotificationImportance.max,
      persistent: true,
    );
  }

  /// Show rescue team acknowledgment notification
  Future<void> showRescueTeamAcknowledgment(
    String teamName,
    String? eta,
  ) async {
    if (!_isEnabled) return;

    final title = '🚑 Rescue Team Dispatched';
    final body = eta != null
        ? '$teamName is responding. ETA: $eta'
        : '$teamName has been dispatched to your location';

    await showNotification(
      title: title,
      body: body,
      importance: NotificationImportance.high,
    );
  }

  /// Show emergency contact response notification
  Future<void> showEmergencyContactResponse(
    String contactName,
    String message,
  ) async {
    if (!_isEnabled) return;

    await showNotification(
      title: '👤 $contactName Responded',
      body: message,
      importance: NotificationImportance.defaultImportance,
    );
  }

  /// Show rescue status update notification
  Future<void> showRescueStatusUpdate(String phase, String? details) async {
    if (!_isEnabled) return;

    await showNotification(
      title: '🆘 Rescue Update',
      body: details ?? phase,
      importance: NotificationImportance.high,
    );
  }

  /// Show enhanced emergency notification with user details
  Future<void> showEmergencyNotificationWithUserDetails({
    required SOSSession session,
    required String
    recipientType, // 'emergency_contact', 'sar_team', 'community'
  }) async {
    final userProfile = _userProfileService.currentProfile;

    // Build notification title
    final title = '🚨 EMERGENCY: ${userProfile?.name ?? 'Unknown Person'}';

    // Build detailed notification body
    final bodyBuffer = StringBuffer();

    // Person identification
    if (userProfile != null) {
      bodyBuffer.writeln('👤 ${userProfile.name}');
      if (userProfile.phoneNumber?.isNotEmpty == true) {
        bodyBuffer.writeln('📞 ${userProfile.phoneNumber}');
      }
      if (userProfile.dateOfBirth != null) {
        final age =
            DateTime.now().difference(userProfile.dateOfBirth!).inDays ~/ 365;
        bodyBuffer.writeln('🎂 Age: $age');
      }

      // Critical medical info
      if (userProfile.bloodType?.isNotEmpty == true) {
        bodyBuffer.writeln('🩸 Blood: ${userProfile.bloodType}');
      }
      if (userProfile.allergies.isNotEmpty) {
        bodyBuffer.writeln('⚠️ Allergies: ${userProfile.allergies.join(', ')}');
      }
    }

    // Emergency details
    bodyBuffer.writeln('🚨 ${_getSOSTypeDisplayName(session.type)}');
    bodyBuffer.writeln(
      '📍 ${session.location.address ?? 'GPS: ${session.location.latitude.toStringAsFixed(4)}, ${session.location.longitude.toStringAsFixed(4)}'}',
    );

    if (session.userMessage?.isNotEmpty == true) {
      bodyBuffer.writeln('💬 "${session.userMessage}"');
    }

    await showNotification(
      title: title,
      body: bodyBuffer.toString(),
      payload: 'emergency_details:${session.id}',
      importance: NotificationImportance.max,
      persistent: true,
    );
  }

  /// Get display name for SOS type
  String _getSOSTypeDisplayName(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual SOS';
      case SOSType.crashDetection:
        return 'Crash Detected';
      case SOSType.fallDetection:
        return 'Fall Detected';
      case SOSType.panicButton:
        return 'Panic Alert';
      case SOSType.voiceCommand:
        return 'Voice Emergency';
      default:
        return 'Emergency Alert';
    }
  }

  /// Show crash/fall detection alert
  Future<void> showDetectionAlert({
    required String type,
    required String message,
    String? sessionId,
  }) async {
    await showNotification(
      title: '⚠️ ${type.toUpperCase()} DETECTED',
      body: message,
      payload: sessionId != null ? 'detection:$sessionId' : null,
      importance: NotificationImportance.high,
    );
  }

  /// Show location alert
  Future<void> showLocationAlert(String message) async {
    await showNotification(
      title: '📍 Location Alert',
      body: message,
      importance: NotificationImportance.defaultImportance,
    );
  }

  /// Show system status notification
  Future<void> showStatusNotification(String message) async {
    await showNotification(
      title: 'REDP!NG Status',
      body: message,
      importance: NotificationImportance.low,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('NotificationService: All notifications cancelled');
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    debugPrint('NotificationService: Notification $id cancelled');
  }

  /// Get notification importance from Firebase message
  NotificationImportance _getImportanceFromMessage(RemoteMessage message) {
    final priority = message.data['priority']?.toString().toLowerCase();
    switch (priority) {
      case 'high':
      case 'emergency':
        return NotificationImportance.max;
      case 'medium':
        return NotificationImportance.high;
      case 'low':
        return NotificationImportance.low;
      default:
        return NotificationImportance.defaultImportance;
    }
  }

  /// Map notification importance to Android importance
  Importance _mapImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.max:
        return Importance.max;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  bool get isEnabled => _isEnabled;
  String? get fcmToken => _fcmToken;

  // Setters
  set isEnabled(bool enabled) {
    _isEnabled = enabled;
    _saveNotificationPreference();
    debugPrint(
      'NotificationService: Notifications ${enabled ? "enabled" : "disabled"}',
    );
  }

  /// Load notification preference from storage
  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('notifications_enabled') ?? true;
      debugPrint(
        'NotificationService: Loaded preference - enabled: $_isEnabled',
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to load preference - $e');
      _isEnabled = true; // Default to enabled
    }
  }

  /// Save notification preference to storage
  Future<void> _saveNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _isEnabled);
      debugPrint(
        'NotificationService: Saved preference - enabled: $_isEnabled',
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to save preference - $e');
    }
  }

  // Event handlers
  void setNotificationTappedCallback(Function(String) callback) {
    _onNotificationTapped = callback;
  }

  void setPushMessageReceivedCallback(Function(RemoteMessage) callback) {
    _onPushMessageReceived = callback;
  }

  /// Dispose of the service
  void dispose() {
    // Firebase messaging doesn't need explicit disposal
  }
}

/// Notification importance levels
enum NotificationImportance { low, defaultImportance, high, max }
