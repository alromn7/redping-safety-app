import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_session.dart';
import '../core/logging/app_logger.dart';
import 'emergency_contacts_service.dart';
import 'notification_service.dart';
import '../repositories/sos_repository.dart';
import 'foreground_service_manager.dart';

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

  /// Attempt to deliver queued SOS sessions.
  Future<void> processQueue() async {
    if (_queue.isEmpty) return;
    final now = DateTime.now();
    final copy = List<_QueuedSOS>.from(_queue);

    for (final q in copy) {
      try {
        final session = SOSSession.fromJson(jsonDecode(q.sessionJson));
        // 1) Persist session to Firestore
        await _repo.createOrUpdateFromSession(session);
        // 2) Try sending contact alerts (best-effort; simulated transports)
        await _contactsService.sendEmergencyAlerts(session);
        // 3) Remove on success
        _queue.removeWhere((x) => x.id == q.id);
        await _save();
        AppLogger.i('Delivered offline SOS (${q.id})', tag: 'OfflineSOSQueue');
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
