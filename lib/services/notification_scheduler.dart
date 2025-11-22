import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/sos_session.dart';
import 'package:intl/intl.dart';
import 'sos_analytics_service.dart';
import 'adaptive_sound_service.dart';

/// Push Notification Scheduler for emergency escalation
/// Implements smart notification timing based on SOS status
class NotificationScheduler {
  static final NotificationScheduler instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => instance;
  NotificationScheduler._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification tracking
  final Map<String, Timer?> _activeTimers = {};
  final Map<String, int> _notificationCounts = {};
  final Map<String, DateTime> _lastNotificationTimes = {};
  final Map<String, String> _currentPhases =
      {}; // Track which phase each session is in

  // Notification Schedule Configuration
  static const Duration _activePhaseInterval = Duration(minutes: 2);
  static const Duration _acknowledgedPhaseInterval = Duration(minutes: 10);
  static const int _activePhaseMaxCount =
      10; // Max 10 notifications (20 min) - triggers auto-escalation
  static const int _acknowledgedPhaseMaxCount =
      6; // Max 6 notifications (60 min)

  bool _isInitialized = false;

  /// Initialize notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize adaptive sound service
      await AdaptiveSoundService.instance.initialize();
      debugPrint('✅ Adaptive sound service initialized');

      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Push notification permissions granted');
      } else {
        debugPrint('⚠️ Push notification permissions denied');
      }

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      _isInitialized = true;
      debugPrint('✅ Notification Scheduler initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Notification Scheduler: $e');
    }
  }

  /// Start push notifications for an SOS session
  Future<void> startNotifications(SOSSession session) async {
    await initialize();

    // Initialize tracking
    _notificationCounts[session.id] = 0;
    _lastNotificationTimes[session.id] = DateTime.now();
    _currentPhases[session.id] = 'active';

    // Send immediate notification
    await _sendActivePhaseNotification(session, 0);

    // Schedule active phase notifications (every 2 minutes)
    _scheduleActivePhase(session.id);
  }

  /// Schedule active phase notifications (every 2 minutes)
  void _scheduleActivePhase(String sessionId) {
    _activeTimers[sessionId]?.cancel();

    _activeTimers[sessionId] = Timer.periodic(_activePhaseInterval, (
      timer,
    ) async {
      final count = _notificationCounts[sessionId] ?? 0;

      if (count >= _activePhaseMaxCount) {
        debugPrint('⚠️ Active phase max count reached, auto-escalating...');
        await _autoEscalateToAuthorities(sessionId);
        timer.cancel();
        return;
      }

      // Fetch current session
      final session = await _fetchSession(sessionId);
      if (session == null) {
        timer.cancel();
        return;
      }

      // Check if status changed
      if (_shouldSwitchToAcknowledgedPhase(session.status)) {
        timer.cancel();
        await switchToAcknowledgedPhase(sessionId);
        return;
      } else if (_shouldStopNotifications(session.status)) {
        timer.cancel();
        await stopNotifications(sessionId);
        return;
      }

      // Send next active notification
      await _sendActivePhaseNotification(session, count + 1);
      _notificationCounts[sessionId] = count + 1;
      _lastNotificationTimes[sessionId] = DateTime.now();
    });
  }

  /// Switch to acknowledged phase (every 10 minutes)
  Future<void> switchToAcknowledgedPhase(String sessionId) async {
    _activeTimers[sessionId]?.cancel();
    _notificationCounts[sessionId] = 0; // Reset counter
    _currentPhases[sessionId] = 'acknowledged';

    debugPrint('📍 Switching to acknowledged phase for session $sessionId');

    // Fetch session
    final session = await _fetchSession(sessionId);
    if (session == null) return;

    // Send immediate acknowledged notification
    await _sendAcknowledgedPhaseNotification(session, 0);

    // Schedule acknowledged phase notifications
    _activeTimers[sessionId] = Timer.periodic(_acknowledgedPhaseInterval, (
      timer,
    ) async {
      final count = _notificationCounts[sessionId] ?? 0;

      if (count >= _acknowledgedPhaseMaxCount) {
        timer.cancel();
        return;
      }

      // Fetch current session
      final updatedSession = await _fetchSession(sessionId);
      if (updatedSession == null) {
        timer.cancel();
        return;
      }

      // Check if resolved
      if (_shouldStopNotifications(updatedSession.status)) {
        timer.cancel();
        await stopNotifications(sessionId);
        return;
      }

      // Send next acknowledged notification
      await _sendAcknowledgedPhaseNotification(updatedSession, count + 1);
      _notificationCounts[sessionId] = count + 1;
      _lastNotificationTimes[sessionId] = DateTime.now();
    });
  }

  /// Stop all notifications for a session
  Future<void> stopNotifications(
    String sessionId, {
    bool sendFinalNotification = true,
  }) async {
    _activeTimers[sessionId]?.cancel();
    _activeTimers.remove(sessionId);

    if (sendFinalNotification) {
      final session = await _fetchSession(sessionId);
      if (session != null) {
        await _sendResolvedNotification(session);
      }
    }

    _notificationCounts.remove(sessionId);
    _lastNotificationTimes.remove(sessionId);
    _currentPhases.remove(sessionId);

    debugPrint('✅ Stopped notifications for session $sessionId');
  }

  /// Send active phase notification (🚨 URGENT)
  Future<void> _sendActivePhaseNotification(
    SOSSession session,
    int notificationNumber,
  ) async {
    final userName = session.metadata['userName'] as String? ?? 'RedPing User';
    final accidentType = _getAccidentTypeString(session.type);
    final timestamp = DateFormat('h:mm a').format(DateTime.now());

    // Play adaptive sound based on alert number
    final alertNumber = notificationNumber + 1;
    await AdaptiveSoundService.instance.playNotificationSound(
      sessionId: session.id,
      alertNumber: alertNumber,
      status: session.status,
      emergencyType: session.type,
    );

    // Get adaptive sound filename for notification
    final soundFilename = AdaptiveSoundService.instance.getSoundFilename(
      alertNumber: alertNumber,
      status: session.status,
      emergencyType: session.type,
    );

    // Local notification
    final androidDetails = AndroidNotificationDetails(
      'sos_active',
      'SOS Active Alerts',
      channelDescription: 'Critical emergency alerts for active SOS sessions',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound(soundFilename),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$soundFilename.aiff',
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'SOS_ACTIVE',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      session.id.hashCode,
      '🚨 SOS ACTIVE - $userName',
      '$accidentType detected at $timestamp. Responders needed! [Alert $alertNumber]',
      details,
      payload: session.id,
    );

    // Log notification
    await _logNotification(session.id, 'active_phase', notificationNumber + 1);

    debugPrint(
      '🚨 Sent active phase notification #${notificationNumber + 1} for ${session.id}',
    );
  }

  /// Send acknowledged phase notification (📍 UPDATE)
  Future<void> _sendAcknowledgedPhaseNotification(
    SOSSession session,
    int notificationNumber,
  ) async {
    final userName = session.metadata['userName'] as String? ?? 'RedPing User';
    final sarName =
        session.metadata['assignedSARName'] as String? ?? 'SAR Team';
    final timestamp = DateFormat('h:mm a').format(DateTime.now());

    const androidDetails = AndroidNotificationDetails(
      'sos_acknowledged',
      'SOS Update Alerts',
      channelDescription: 'Update alerts for acknowledged SOS sessions',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      session.id.hashCode + 1000,
      '📍 SOS UPDATE - $userName',
      '$sarName is responding. Status: En route. [$timestamp] [Update ${notificationNumber + 1}]',
      details,
      payload: session.id,
    );

    await _logNotification(
      session.id,
      'acknowledged_phase',
      notificationNumber + 1,
    );

    debugPrint(
      '📍 Sent acknowledged phase notification #${notificationNumber + 1} for ${session.id}',
    );
  }

  /// Send resolved notification (✅ RESOLVED)
  Future<void> _sendResolvedNotification(SOSSession session) async {
    final userName = session.metadata['userName'] as String? ?? 'RedPing User';
    final timestamp = DateFormat('h:mm a').format(DateTime.now());
    final duration = DateTime.now().difference(session.startTime).inMinutes;

    const androidDetails = AndroidNotificationDetails(
      'sos_resolved',
      'SOS Resolved',
      channelDescription: 'Final notifications for resolved SOS sessions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound('success_chime'),
      playSound: true,
      category: AndroidNotificationCategory.status,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'success_chime.aiff',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final statusText = session.status == SOSStatus.cancelled
        ? 'cancelled by user'
        : 'resolved successfully';

    await _localNotifications.show(
      session.id.hashCode + 2000,
      '✅ SOS RESOLVED - $userName',
      'Emergency $statusText at $timestamp. Duration: $duration min. All responders stood down.',
      details,
      payload: session.id,
    );

    await _logNotification(session.id, 'resolved', 1);

    debugPrint('✅ Sent resolved notification for ${session.id}');
  }

  /// Auto-escalate to authorities after 20 minutes of no acknowledgment
  Future<void> _autoEscalateToAuthorities(String sessionId) async {
    debugPrint('🚨 AUTO-ESCALATING session $sessionId to authorities');

    try {
      // Update Firestore
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'autoEscalated': true,
        'escalatedAt': FieldValue.serverTimestamp(),
        'escalationReason': 'No SAR acknowledgment after 20 minutes',
      });

      // Send critical escalation notification
      final androidDetails = AndroidNotificationDetails(
        'sos_escalation',
        'SOS Escalation',
        channelDescription: 'Critical escalation alerts',
        importance: Importance.max,
        priority: Priority.max,
        sound: const RawResourceAndroidNotificationSound('emergency_siren'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        color: const Color.fromARGB(255, 255, 0, 0),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'emergency_siren.aiff',
        interruptionLevel: InterruptionLevel.critical,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        sessionId.hashCode + 3000,
        '🚨 CRITICAL - AUTO-ESCALATION',
        'No response after 20 minutes. Contact emergency services immediately! Call 911/000.',
        details,
        payload: sessionId,
      );

      await _logNotification(sessionId, 'auto_escalation', 1);

      // Log auto-escalation to analytics
      try {
        final notificationCount = _notificationCounts[sessionId] ?? 0;
        final sessionDoc = await _firestore
            .collection('sos_sessions')
            .doc(sessionId)
            .get();
        if (sessionDoc.exists) {
          final startTime =
              (sessionDoc.data()?['startTime'] as Timestamp?)?.toDate() ??
              DateTime.now();
          final timeSinceActivation = DateTime.now().difference(startTime);

          await SOSAnalyticsService.instance.logAutoEscalation(
            sessionId: sessionId,
            notificationCount: notificationCount,
            timeSinceActivation: timeSinceActivation,
          );
        }
      } catch (e) {
        debugPrint('Analytics logging failed (non-fatal): $e');
      }

      // TODO: Trigger additional escalation actions
      // - Send critical SMS to emergency contacts
      // - Alert nearby SAR teams with higher priority
      // - Notify system administrators
    } catch (e) {
      debugPrint('❌ Error auto-escalating session $sessionId: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    final sessionId = response.payload;
    if (sessionId != null) {
      debugPrint('📱 Notification tapped for session: $sessionId');
      // TODO: Navigate to SOS session details
    }
  }

  /// Fetch SOS session from Firestore
  Future<SOSSession?> _fetchSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return SOSSession.fromJson({...data, 'id': sessionId});
    } catch (e) {
      debugPrint('❌ Error fetching session $sessionId: $e');
      return null;
    }
  }

  /// Check if should switch to acknowledged phase
  bool _shouldSwitchToAcknowledgedPhase(SOSStatus status) {
    return status == SOSStatus.acknowledged ||
        status == SOSStatus.assigned ||
        status == SOSStatus.enRoute ||
        status == SOSStatus.onScene ||
        status == SOSStatus.inProgress;
  }

  /// Check if should stop notifications
  bool _shouldStopNotifications(SOSStatus status) {
    return status == SOSStatus.resolved ||
        status == SOSStatus.cancelled ||
        status == SOSStatus.falseAlarm;
  }

  /// Get accident type string
  String _getAccidentTypeString(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual SOS';
      case SOSType.crashDetection:
        return 'Crash';
      case SOSType.fallDetection:
        return 'Fall';
      case SOSType.panicButton:
        return 'Panic';
      case SOSType.voiceCommand:
        return 'Voice SOS';
      case SOSType.externalTrigger:
        return 'External Alert';
    }
  }

  /// Log notification to Firestore
  Future<void> _logNotification(
    String sessionId,
    String notificationType,
    int sequenceNumber,
  ) async {
    try {
      await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .collection('notification_logs')
          .add({
            'type': notificationType,
            'sequenceNumber': sequenceNumber,
            'timestamp': FieldValue.serverTimestamp(),
            'sentAt': DateTime.now().toIso8601String(),
            'phase': _currentPhases[sessionId] ?? 'unknown',
          });

      // Update session notification count
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'notificationCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error logging notification: $e');
    }
  }

  /// Get notification statistics for a session
  Future<Map<String, dynamic>> getNotificationStats(String sessionId) async {
    try {
      final logs = await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .collection('notification_logs')
          .orderBy('timestamp')
          .get();

      final activeCount = logs.docs
          .where((d) => d.data()['type'] == 'active_phase')
          .length;
      final acknowledgedCount = logs.docs
          .where((d) => d.data()['type'] == 'acknowledged_phase')
          .length;
      final totalCount = logs.docs.length;

      return {
        'totalNotifications': totalCount,
        'activePhaseCount': activeCount,
        'acknowledgedPhaseCount': acknowledgedCount,
        'currentPhase': _currentPhases[sessionId],
        'lastNotificationTime': _lastNotificationTimes[sessionId]
            ?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting notification stats: $e');
      return {};
    }
  }

  /// Dispose all timers
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer?.cancel();
    }
    _activeTimers.clear();
    _notificationCounts.clear();
    _lastNotificationTimes.clear();
    _currentPhases.clear();
  }
}
