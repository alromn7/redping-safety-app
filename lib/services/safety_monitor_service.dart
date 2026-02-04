import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/sos_session.dart';
import '../core/constants/app_constants.dart';
import 'location_service.dart';
import 'notification_service.dart';

/// Monitors speed and altitude to surface proactive sticky notifications
/// indicating that RedPing's auto crash/fall detection is actively engaged.
class SafetyMonitorService {
  static final SafetyMonitorService _instance = SafetyMonitorService._internal();
  factory SafetyMonitorService() => _instance;
  SafetyMonitorService._internal();

  // Dependencies
  LocationService? _locationService;
  NotificationService? _notificationService;

  // Streaming
  Function(LocationInfo)? _locationListener;

  // State
  bool _isInitialized = false;
  bool _isMonitoring = false;
  bool _speedCriticalActive = false;
  bool _altitudeCriticalActive = false;

  // Altitude window for relative gain calculation
  final Queue<_AltitudePoint> _altitudeWindow = Queue<_AltitudePoint>();

  // Notification IDs (fixed, so we can cancel/update deterministically)
  static const int _notifIdCrashActive = 20001;
  static const int _notifIdFallActive = 20002;

  // Callback for UI updates
  void Function(bool speedActive, bool altitudeActive)? _onStatusChanged;

  Future<void> initialize({
    LocationService? locationService,
    NotificationService? notificationService,
  }) async {
    if (_isInitialized) return;

    _locationService = locationService ?? _locationService ?? LocationService();
    _notificationService =
        notificationService ?? _notificationService ?? NotificationService();

    // Ensure location permission before starting
    try {
      await _locationService!.initialize();
    } catch (_) {
      // Best-effort; we'll still try to start stream, Geolocator will gate
    }

    _isInitialized = true;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    try {
      final ls = LocationService();
      await ls.initialize();
      _locationListener = (LocationInfo li) => _handleLocation(li);
      ls.addLocationListener(_locationListener!);
      await ls.startTracking();
      _isMonitoring = true;
      debugPrint('SafetyMonitor: Monitoring started');
    } catch (e) {
      debugPrint('SafetyMonitor: Failed to start monitoring - $e');
    }
  }

  void stopMonitoring() {
    if (_locationListener != null) {
      try {
        LocationService().removeLocationListener(_locationListener!);
      } catch (_) {}
      _locationListener = null;
    }
    _isMonitoring = false;
    _altitudeWindow.clear();
    debugPrint('SafetyMonitor: Monitoring stopped');
  }
 
  void _handleLocation(LocationInfo info) {
    // Speed logic (m/s)
    final double speed = (info.speed != null && info.speed!.isFinite && info.speed! >= 0)
        ? info.speed!
        : 0.0;
    final double crit = AppConstants.criticalSpeedMps;
    final double hyster = AppConstants.criticalSpeedHysteresisMps;

    if (!_speedCriticalActive && speed >= crit) {
      _speedCriticalActive = true;
      _showCrashActiveSticky();
      _emit();
    } else if (_speedCriticalActive && speed <= (crit - hyster)) {
      _speedCriticalActive = false;
      _cancelCrashActiveSticky();
      _emit();
    }

    // Altitude logic (relative gain in a rolling window)
    final now = DateTime.now();
    final double altitude = (info.altitude != null && info.altitude!.isFinite)
      ? info.altitude!
      : 0.0;
    _altitudeWindow.addLast(_AltitudePoint(t: now, alt: altitude));

    // Evict old samples
    final cutoff =
        now.subtract(Duration(seconds: AppConstants.criticalAltitudeWindowSeconds));
    while (_altitudeWindow.isNotEmpty && _altitudeWindow.first.t.isBefore(cutoff)) {
      _altitudeWindow.removeFirst();
    }

    if (_altitudeWindow.isNotEmpty) {
      double minAlt = _altitudeWindow.first.alt;
      for (final pt in _altitudeWindow) {
        if (pt.alt < minAlt) minAlt = pt.alt;
      }
      final double gain = altitude - minAlt;
      final double gainCrit = AppConstants.criticalAltitudeGainMeters;
      // Simple hysteresis: deactivate when we drop 5m below threshold
      final double gainOff = gainCrit - 5.0;

      if (!_altitudeCriticalActive && gain >= gainCrit) {
        _altitudeCriticalActive = true;
        _showFallActiveSticky();
        _emit();
      } else if (_altitudeCriticalActive && gain <= gainOff) {
        _altitudeCriticalActive = false;
        _cancelFallActiveSticky();
        _emit();
      }
    }
  }

  Future<void> _showCrashActiveSticky() async {
    await _notificationService?.showNotification(
      title: 'redping auto crash detection active',
      body: 'High speed detected. Monitoring engaged for safety.',
      importance: NotificationImportance.high,
      persistent: true,
      notificationId: _notifIdCrashActive,
    );
  }

  Future<void> _cancelCrashActiveSticky() async {
    await _notificationService?.cancelNotification(_notifIdCrashActive);
  }

  Future<void> _showFallActiveSticky() async {
    await _notificationService?.showNotification(
      title: 'redping auto fall detection active',
      body: 'Critical altitude change detected. Monitoring engaged.',
      importance: NotificationImportance.high,
      persistent: true,
      notificationId: _notifIdFallActive,
    );
  }

  Future<void> _cancelFallActiveSticky() async {
    await _notificationService?.cancelNotification(_notifIdFallActive);
  }

  void setStatusChangedCallback(
      void Function(bool speedActive, bool altitudeActive) callback) {
    _onStatusChanged = callback;
  }

  void _emit() {
    _onStatusChanged?.call(_speedCriticalActive, _altitudeCriticalActive);
  }

  Map<String, dynamic> getStatus() => {
        'isInitialized': _isInitialized,
        'isMonitoring': _isMonitoring,
        'speedCriticalActive': _speedCriticalActive,
        'altitudeCriticalActive': _altitudeCriticalActive,
        'altitudeWindowSize': _altitudeWindow.length,
      };

  bool get speedCriticalActive => _speedCriticalActive;
  bool get altitudeCriticalActive => _altitudeCriticalActive;
  bool get isMonitoring => _isMonitoring;
  bool get isInitialized => _isInitialized;

  void dispose() {
    stopMonitoring();
    _onStatusChanged = null;
  }
}

class _AltitudePoint {
  final DateTime t;
  final double alt;
  _AltitudePoint({required this.t, required this.alt});
}

