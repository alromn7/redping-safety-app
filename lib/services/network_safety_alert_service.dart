import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/starlink_carrier_utils.dart';
import 'connectivity_monitor_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'platform_service.dart';

enum NetworkSafetyAlertType {
  noNetwork,
  noMobileNetwork,
  overseasTravel,
  nonStarlinkCarrier,
}

class NetworkSafetyAlert {
  final NetworkSafetyAlertType type;
  final String title;
  final String message;
  final DateTime timestamp;

  const NetworkSafetyAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

class NetworkSafetyAlertService {
  static final NetworkSafetyAlertService _instance =
      NetworkSafetyAlertService._internal();
  factory NetworkSafetyAlertService() => _instance;
  NetworkSafetyAlertService._internal();

  final StreamController<NetworkSafetyAlert> _alertsController =
      StreamController<NetworkSafetyAlert>.broadcast();

  Stream<NetworkSafetyAlert> get alertsStream => _alertsController.stream;

  bool _initialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicCarrierTimer;
  Timer? _periodicCountryTimer;

  LocationService? _locationService;
  NotificationService? _notificationService;
  SharedPreferences? _prefs;

  bool _everHadMobile = false;
  String? _homeCountryIso;
  String? _lastCountryIso;
  String? _lastCarrier;
  bool? _lastCarrierStarlink;

  static const _prefsHomeCountryKey = 'network_alert_home_country_iso';

  Future<void> initialize({
    required LocationService locationService,
    required NotificationService notificationService,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _locationService = locationService;
    _notificationService = notificationService;
    _prefs = await SharedPreferences.getInstance();

    _homeCountryIso = _prefs!.getString(_prefsHomeCountryKey);

    await ConnectivityMonitorService().initialize();

    _connectivitySub = ConnectivityMonitorService().connectivityStream.listen(
      _handleConnectivity,
    );

    // Seed mobile state if we already know it.
    final initial = ConnectivityMonitorService().lastConnectivityResults;
    if (initial != null) {
      _everHadMobile = initial.contains(ConnectivityResult.mobile);
    }

    // Trigger initial checks (best-effort)
    unawaited(_checkCarrierAndMaybeAlert());
    unawaited(_checkCountryAndMaybeAlert());

    // Periodic checks (travel + carrier changes)
    _periodicCarrierTimer?.cancel();
    _periodicCarrierTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _checkCarrierAndMaybeAlert(),
    );

    _periodicCountryTimer?.cancel();
    _periodicCountryTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _checkCountryAndMaybeAlert(),
    );

    // Also piggy-back on location updates to detect travel sooner.
    _locationService!.addLocationListener((_) {
      unawaited(_checkCountryAndMaybeAlert());
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicCarrierTimer?.cancel();
    _periodicCountryTimer?.cancel();
    // Do not close controller; service is a singleton shared across app.
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final hasAnyBearer = results.any((r) => r != ConnectivityResult.none);
    final hasMobile = results.contains(ConnectivityResult.mobile);

    if (hasMobile) {
      _everHadMobile = true;
    }

    // 1) No network at all
    if (!hasAnyBearer) {
      unawaited(
        _emitAlertThrottled(
          type: NetworkSafetyAlertType.noNetwork,
          minInterval: const Duration(minutes: 30),
          title: 'No Network Detected',
          message:
              'No Wi‑Fi or mobile network detected. SOS messaging and hazard updates may be delayed. Move to coverage or enable mobile data/roaming if safe.',
          notificationId: 91001,
        ),
      );
      return;
    }

    // 2) No mobile network (Wi‑Fi only) — only warn if we have ever seen mobile
    // on this device/session. This avoids spamming tablets/Wi‑Fi-only devices.
    if (_everHadMobile && !hasMobile) {
      unawaited(
        _emitAlertThrottled(
          type: NetworkSafetyAlertType.noMobileNetwork,
          minInterval: const Duration(hours: 6),
          title: 'Mobile Network Unavailable',
          message:
              'Wi‑Fi is connected but mobile network is not detected. If you rely on carrier SMS for SOS, check airplane mode, SIM status, and roaming settings.',
          notificationId: 91002,
        ),
      );
    }

    // Connectivity changes are a good time to re-check carrier and travel status.
    unawaited(_checkCarrierAndMaybeAlert());
    unawaited(_checkCountryAndMaybeAlert());
  }

  Future<void> _checkCarrierAndMaybeAlert() async {
    try {
      final carrier = await PlatformService.getCarrierName();
      final normalized = carrier.trim();
      if (normalized.isEmpty || normalized.toLowerCase() == 'unknown') return;

      final starlinkCapable = StarlinkCarrierUtils.isStarlinkPartnerCarrier(
        normalized,
      );

      // Skip if carrier is Starlink-capable
      if (starlinkCapable) {
        _lastCarrier = normalized;
        _lastCarrierStarlink = true;
        return;
      }

      // Avoid re-alerting on the same carrier value within a session.
      if (_lastCarrier == normalized && _lastCarrierStarlink == false) return;
      _lastCarrier = normalized;
      _lastCarrierStarlink = false;

      await _emitAlertThrottled(
        type: NetworkSafetyAlertType.nonStarlinkCarrier,
        minInterval: const Duration(days: 7),
        title: 'Non‑Starlink Carrier Coverage',
        message:
            'Your current carrier ($normalized) is not detected as Starlink‑partner capable. Satellite/Starlink-assisted coverage may be unavailable; ensure SMS fallback and offline SOS queue are enabled.',
        notificationId: 91003,
      );
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> _checkCountryAndMaybeAlert() async {
    try {
      final locationService = _locationService;
      if (locationService == null) return;

      final iso = await locationService.getCurrentIsoCountryCodeBestEffort();
      if (iso == null || iso.trim().isEmpty) return;

      final currentIso = iso.toUpperCase();
      // Avoid repeated work/alerts when we remain in the same country.
      if (_lastCountryIso == currentIso) return;
      _lastCountryIso = currentIso;

      // If we don't have a home country yet, seed it.
      _homeCountryIso ??= _prefs?.getString(_prefsHomeCountryKey);
      if (_homeCountryIso == null || _homeCountryIso!.trim().isEmpty) {
        _homeCountryIso = currentIso;
        await _prefs?.setString(_prefsHomeCountryKey, currentIso);
        return;
      }

      final homeIso = _homeCountryIso!.toUpperCase();
      if (currentIso == homeIso) return;

      await _emitAlertThrottled(
        type: NetworkSafetyAlertType.overseasTravel,
        minInterval: const Duration(days: 1),
        title: 'Overseas Travel Detected',
        message:
            'You appear to be outside your home country ($homeIso → $currentIso). Emergency numbers and coverage can differ overseas. Verify roaming, emergency contacts, and satellite readiness.',
        notificationId: 91004,
      );
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> _emitAlertThrottled({
    required NetworkSafetyAlertType type,
    required Duration minInterval,
    required String title,
    required String message,
    required int notificationId,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;

    final key = 'network_alert_last_${type.name}';
    final lastMillis = prefs.getInt(key);
    final now = DateTime.now();

    if (lastMillis != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      if (now.difference(last) < minInterval) {
        return;
      }
    }

    await prefs.setInt(key, now.millisecondsSinceEpoch);

    final alert = NetworkSafetyAlert(
      type: type,
      title: title,
      message: message,
      timestamp: now,
    );

    _alertsController.add(alert);

    // Always try to notify as well (works even if app is backgrounded).
    try {
      await _notificationService?.showNotification(
        title: title,
        body: message,
        importance: NotificationImportance.high,
        notificationId: notificationId,
      );
    } catch (_) {
      // Non-fatal
    }
  }
}
