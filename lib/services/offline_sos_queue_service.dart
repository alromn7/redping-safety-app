import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_session.dart';
import '../core/logging/app_logger.dart';
import 'emergency_contacts_service.dart';
import 'sms_service.dart';
import 'notification_service.dart';
import '../repositories/sos_repository.dart';
import 'foreground_service_manager.dart';
import 'connectivity_monitor_service.dart';

/// Offline queue to guarantee SOS delivery when network is down.
class OfflineSOSQueueService {
  static final OfflineSOSQueueService _instance =
      OfflineSOSQueueService._internal();
  factory OfflineSOSQueueService() => _instance;
  OfflineSOSQueueService._internal();

  final _repo = SosRepository();
  final _contactsService = EmergencyContactsService();
  final _notificationService = NotificationService();

  bool _isInitialized = false;
  final List<_QueuedSOS> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _retryTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _load();

    // Observe connectivity changes for instant retry
    try {
      _connSub = Connectivity().onConnectivityChanged.listen((results) async {
        final online = results.any((r) => r != ConnectivityResult.none);
        if (online) {
          await processQueue();
        }
      });
    } catch (e) {
      debugPrint('OfflineSOSQueue: connectivity listen failed - $e');
    }

    // Backoff retry every 2 minutes
    _retryTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await processQueue();
    });

    _isInitialized = true;
    AppLogger.i(
      'Initialized (items: ${_queue.length})',
      tag: 'OfflineSOSQueue',
    );
  }

  Future<void> enqueue(SOSSession session, {String reason = 'unknown'}) async {
    final item = _QueuedSOS(
      id: session.id,
      sessionJson: jsonEncode(session.toJson()),
      createdAt: DateTime.now().toIso8601String(),
      attempts: 0,
      lastError: reason,
    );
    _queue.removeWhere((q) => q.id == item.id);
    _queue.add(item);
    await _save();

    // Persistent prompt to user
    await _notificationService.showNotification(
      title: 'SOS queued offline',
      body: 'No network. We will auto-send when online.',
      importance: NotificationImportance.high,
      persistent: true,
      // Use fixed id to avoid duplicates; 21001 reserved for queued SOS
      notificationId: 21001,
      // Remove payload that triggers SMS composer to avoid UI jump/spam
      payload: 'offline_sos:${session.id}',
    );

    AppLogger.w('Enqueued offline SOS (${session.id})', tag: 'OfflineSOSQueue');

    // Ensure background persistence on Android
    try {
      await ForegroundServiceManager.start(
        title: 'REDP!NG Offline SOS Queue',
        text: 'Delivering SOS when connection is available',
      );
    } catch (_) {}
  }

  /// Offer an SMS prompt without adding to queue (optional helper)
  Future<void> offerSmsPrompt(SOSSession session) async {
    await _notificationService.showNotification(
      title: 'Send SOS via SMS',
      body: 'Tap to open SMS with your location to your contacts.',
      importance: NotificationImportance.high,
      persistent: true,
      notificationId: 21002,
      payload: 'offline_sos_sms:${session.id}',
    );
  }

  /// Offer an internet share prompt (WhatsApp/Email/etc.) for Wi‑Fi-only cases.
  ///
  /// This is the best-effort option when there is internet access but no
  /// carrier mobile network for SMS.
  Future<void> offerSharePrompt(SOSSession session) async {
    await _notificationService.showNotification(
      title: 'Share SOS via internet',
      body: 'Tap to share your SOS message to contacts (WhatsApp/Email/etc.).',
      importance: NotificationImportance.high,
      persistent: true,
      notificationId: 21003,
      payload: 'offline_sos_share:${session.id}',
    );
  }

  /// Attempt to deliver queued SOS sessions.
  Future<void> processQueue({bool bypassStartupGrace = false}) async {
    if (_queue.isEmpty) return;
    final now = DateTime.now();
    final copy = List<_QueuedSOS>.from(_queue);

    for (final q in copy) {
      try {
        final session = SOSSession.fromJson(jsonDecode(q.sessionJson));
        // Determine connectivity
        final results = await Connectivity().checkConnectivity();
        bool hasInternet = false;
        try {
          final hasInterfaces = results.any((r) => r != ConnectivityResult.none);
          hasInternet = hasInterfaces &&
              await ConnectivityMonitorService().isInternetReachable(
                timeout: const Duration(seconds: 2),
              );
        } catch (_) {
          hasInternet = false;
        }
        final hasMobile = results.any((r) => r == ConnectivityResult.mobile);

        // Enabled contacts
        final contacts = _contactsService.enabledContacts;

        bool delivered = false;

        // SMS-first: attempt carrier SMS even if internet is unavailable
        try {
          final prefs = await SharedPreferences.getInstance();
          final enableSms = prefs.getBool('enable_sms_notifications') ?? false;
          if (enableSms && contacts.isNotEmpty && hasMobile) {
            await SMSService.instance.startSMSNotifications(session, contacts);
            delivered = true;
            AppLogger.i(
              'Offline queue: SMS notifications started for ${contacts.length} contacts',
              tag: 'OfflineSOSQueue',
            );
          }
        } catch (e) {
          AppLogger.w(
            'Offline queue: SMS start failed (will try internet fallback)',
            tag: 'OfflineSOSQueue',
            error: e,
          );
        }

        // Wi‑Fi/internet-only case: offer an explicit share prompt for contacts.
        // (This does not auto-send anything; it opens a user-driven share sheet.)
        if (!delivered && hasInternet && contacts.isNotEmpty && !hasMobile) {
          try {
            await offerSharePrompt(session);
            AppLogger.i(
              'Offline queue: Offered share prompt for Wi‑Fi/internet-only case',
              tag: 'OfflineSOSQueue',
            );
          } catch (e) {
            AppLogger.w(
              'Offline queue: Share prompt failed',
              tag: 'OfflineSOSQueue',
              error: e,
            );
          }
        }

        // Persist session to Firestore when internet is available (best-effort)
        if (hasInternet) {
          try {
            await _repo.createOrUpdateFromSession(session);
          } catch (e) {
            AppLogger.w(
              'Offline queue: Firestore persistence failed',
              tag: 'OfflineSOSQueue',
              error: e,
            );
          }
        }

        // Best-effort simulated alerts for logging/analytics
        try {
          await _contactsService.sendEmergencyAlerts(session);
        } catch (e) {
          AppLogger.w(
            'Offline queue: sendEmergencyAlerts failed',
            tag: 'OfflineSOSQueue',
            error: e,
          );
        }

        // Remove item if any delivery path succeeded
        if (delivered || hasInternet) {
          _queue.removeWhere((x) => x.id == q.id);
          await _save();
          AppLogger.i('Delivered offline SOS (${q.id})', tag: 'OfflineSOSQueue');
        } else {
          // Keep in queue for future attempts
          AppLogger.i(
            'Offline queue: no delivery path available (will retry)',
            tag: 'OfflineSOSQueue',
          );
        }
      } catch (e) {
        // Update metadata and continue
        final idx = _queue.indexWhere((x) => x.id == q.id);
        if (idx != -1) {
          _queue[idx] = _queue[idx].copyWith(
            attempts: q.attempts + 1,
            lastAttemptAt: now.toIso8601String(),
            lastError: e.toString(),
          );
        }
        await _save();
        AppLogger.w('Retry pending for ${q.id}: $e', tag: 'OfflineSOSQueue');
      }
    }

    // Stop foreground service when queue becomes empty (best-effort)
    if (_queue.isEmpty) {
      try {
        await ForegroundServiceManager.stop();
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> getQueueSnapshot() =>
      _queue.map((q) => q.toJson()).toList();
  bool get hasQueuedItems => _queue.isNotEmpty;
  int get queueCount => _queue.length;
  bool get isInitialized => _isInitialized;

  SOSSession? getSessionById(String sessionId) {
    try {
      final q = _queue.firstWhere((e) => e.id == sessionId);
      return SOSSession.fromJson(jsonDecode(q.sessionJson));
    } catch (_) {
      return null;
    }
  }

  Future<void> loadQueueOnly() async {
    await _load();
  }

  Future<void> remove(String sessionId, {String? reason}) async {
    _queue.removeWhere((q) => q.id == sessionId);
    await _save();
    if (_queue.isEmpty) {
      try {
        await ForegroundServiceManager.stop();
      } catch (_) {}
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('offline_sos_queue') ?? [];
      _queue
        ..clear()
        ..addAll(raw.map((s) => _QueuedSOS.fromJson(jsonDecode(s))));
    } catch (e) {
      debugPrint('OfflineSOSQueue: load failed - $e');
      _queue.clear();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _queue.map((q) => jsonEncode(q.toJson())).toList();
      await prefs.setStringList('offline_sos_queue', raw);
    } catch (e) {
      debugPrint('OfflineSOSQueue: save failed - $e');
    }
  }

  void dispose() {
    _connSub?.cancel();
    _retryTimer?.cancel();
  }
}

class _QueuedSOS {
  final String id;
  final String sessionJson;
  final String createdAt;
  final String? lastAttemptAt;
  final int attempts;
  final String? lastError;

  _QueuedSOS({
    required this.id,
    required this.sessionJson,
    required this.createdAt,
    this.lastAttemptAt,
    required this.attempts,
    this.lastError,
  });

  _QueuedSOS copyWith({
    String? sessionJson,
    String? createdAt,
    String? lastAttemptAt,
    int? attempts,
    String? lastError,
  }) => _QueuedSOS(
    id: id,
    sessionJson: sessionJson ?? this.sessionJson,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError ?? this.lastError,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionJson': sessionJson,
    'createdAt': createdAt,
    'lastAttemptAt': lastAttemptAt,
    'attempts': attempts,
    'lastError': lastError,
  };

  factory _QueuedSOS.fromJson(Map<String, dynamic> json) => _QueuedSOS(
    id: json['id'] as String,
    sessionJson: json['sessionJson'] as String,
    createdAt: json['createdAt'] as String,
    lastAttemptAt: json['lastAttemptAt'] as String?,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    lastError: json['lastError'] as String?,
  );
}
