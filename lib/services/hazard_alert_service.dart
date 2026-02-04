import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hazard_alert.dart';
import '../models/sos_session.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'weather_service.dart';
import 'connectivity_monitor_service.dart';

/// Service for managing hazard alerts, weather alerts, and emergency broadcasts
class HazardAlertService {
  static final HazardAlertService _instance = HazardAlertService._internal();
  factory HazardAlertService() => _instance;
  HazardAlertService._internal();

  static const String _pendingRemoteHazardAlertsKey =
      'pending_hazard_alert_pushes';

  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  List<HazardAlert> _activeAlerts = [];
  List<CommunityHazardReport> _communityReports = [];
  final List<WeatherAlert> _weatherAlerts = [];
  final List<EmergencyBroadcast> _emergencyBroadcasts = [];

  Timer? _weatherUpdateTimer;
  Timer? _alertExpirationTimer;
  StreamSubscription<BatteryState>? _batterySub;
  BatteryState? _batteryState;
  DateTime? _lastWeatherFetch;
  StreamSubscription<bool>? _offlineSub;
  bool _isOffline = false;
  int _consecutiveApiFailures = 0;
  static const int _maxApiFailures = 3;
  DateTime? _apiBackoffUntil;

  bool _isInitialized = false;
  bool _isEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _communityAlertsEnabled = true;
  bool _emergencyBroadcastsEnabled = true;

  // Callbacks
  Function(HazardAlert)? _onHazardAlert;
  Function(CommunityHazardReport)? _onCommunityReport;
  Function(WeatherAlert)? _onWeatherAlert;
  Function()? _onAlertsUpdated;
  final List<VoidCallback> _alertsUpdatedListeners = [];

  /// Initialize hazard alert service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await _locationService.initialize();
      await _notificationService.initialize();

      // Load saved preferences
      await _loadPreferences();

      // Load saved alerts and reports
      await _loadSavedData();

      // Start periodic weather updates
      _startWeatherUpdates();
      // Initialize connectivity monitoring and react to changes
      try {
        await ConnectivityMonitorService().initialize();
        _isOffline = ConnectivityMonitorService().isOffline;
        _offlineSub?.cancel();
        _offlineSub = ConnectivityMonitorService().offlineStream.listen((o) {
          _isOffline = o;
          _rescheduleWeatherTimer();
        });
      } catch (e) {
        debugPrint('HazardAlertService: Connectivity monitor unavailable - $e');
      }
      // Perform an immediate fetch on startup
      if (_weatherAlertsEnabled) {
        await _fetchWeatherAlerts();
      }

      // Start alert expiration monitoring
      _startExpirationMonitoring();

      // Production mode - all alerts from real APIs only
      debugPrint('HazardAlertService: Production mode - real data only');

      _isInitialized = true;

      // Drain any hazard pushes received while the app was backgrounded/killed.
      await _ingestPendingRemoteHazardAlerts();
      debugPrint('HazardAlertService: Initialized successfully');
    } catch (e) {
      debugPrint('HazardAlertService: Initialization error - $e');
      throw Exception('Failed to initialize hazard alert service: $e');
    }
  }

  Future<void> _ingestPendingRemoteHazardAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending =
          prefs.getStringList(_pendingRemoteHazardAlertsKey) ?? const [];
      if (pending.isEmpty) return;

      await prefs.remove(_pendingRemoteHazardAlertsKey);

      for (final raw in pending) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            await ingestRemoteHazardAlert(
              Map<String, dynamic>.from(decoded),
              showNotification: false,
            );
          }
        } catch (e) {
          debugPrint('HazardAlertService: Failed to parse queued hazard - $e');
        }
      }
    } catch (e) {
      debugPrint(
        'HazardAlertService: Failed to ingest pending remote hazards - $e',
      );
    }
  }

  /// Create a new community hazard report
  Future<CommunityHazardReport> reportCommunityHazard({
    required HazardType type,
    required String title,
    required String description,
    required HazardSeverity severity,
    List<String>? mediaFiles,
    List<String>? tags,
  }) async {
    final location = await _locationService.getCurrentLocation();
    if (location == null) {
      throw Exception('Location required to report hazard');
    }

    final report = CommunityHazardReport(
      id: _generateReportId(),
      reporterId: 'current_user',
      type: type,
      title: title,
      description: description,
      location: location,
      reportedAt: DateTime.now(),
      reportedSeverity: severity,
      mediaFiles: mediaFiles ?? [],
      tags: tags ?? [],
    );

    _communityReports.add(report);
    await _saveCommunityReports();

    // Create corresponding hazard alert
    final hazardAlert = HazardAlert(
      id: _generateAlertId(),
      type: type,
      severity: severity,
      title: title,
      description: description,
      issuedAt: DateTime.now(),
      affectedArea: location,
      radius: _getHazardRadius(type, severity),
      source: HazardSource.communityReport,
      instructions: _getHazardInstructions(type),
      safetyTips: _getHazardSafetyTips(type),
      tags: ['community', 'user-reported', ...?tags],
    );

    _activeAlerts.add(hazardAlert);
    await _saveActiveAlerts();

    // Send notifications
    await _sendHazardNotification(hazardAlert);

    _onCommunityReport?.call(report);
    _onHazardAlert?.call(hazardAlert);
    _onAlertsUpdated?.call();

    debugPrint('HazardAlertService: Community hazard reported - $title');
    return report;
  }

  /// Verify a community hazard report
  Future<void> verifyCommunityReport(String reportId) async {
    final reportIndex = _communityReports.indexWhere((r) => r.id == reportId);
    if (reportIndex == -1) return;

    final report = _communityReports[reportIndex];
    final updatedReport = report.copyWith(
      verificationCount: report.verificationCount + 1,
      verifiedByUsers: [...report.verifiedByUsers, 'current_user'],
      isVerified: report.verificationCount + 1 >= 3,
    );

    _communityReports[reportIndex] = updatedReport;
    await _saveCommunityReports();

    if (updatedReport.isVerified) {
      await _promoteToOfficialAlert(updatedReport);
    }

    _onAlertsUpdated?.call();
    debugPrint('HazardAlertService: Report verified - $reportId');
  }

  /// Promote verified community report to official alert
  Future<void> _promoteToOfficialAlert(CommunityHazardReport report) async {
    final officialAlert = HazardAlert(
      id: _generateAlertId(),
      type: report.type,
      severity: report.reportedSeverity,
      title: '${report.title} (Community Verified)',
      description: report.description,
      issuedAt: DateTime.now(),
      affectedArea: report.location,
      radius: _getHazardRadius(report.type, report.reportedSeverity),
      source: HazardSource.communityReport,
      instructions: _getHazardInstructions(report.type),
      safetyTips: _getHazardSafetyTips(report.type),
      tags: ['verified', 'community', ...report.tags],
    );

    _activeAlerts.add(officialAlert);
    await _saveActiveAlerts();

    await _notificationService.showNotification(
      title: 'Verified Hazard Alert',
      body: '${report.title} has been verified by the community',
      importance: NotificationImportance.high,
    );

    _onHazardAlert?.call(officialAlert);
  }

  /// Dismiss a hazard alert
  Future<void> dismissAlert(String alertId) async {
    final alertIndex = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (alertIndex == -1) return;

    final alert = _activeAlerts[alertIndex];
    final dismissedAlert = alert.copyWith(isActive: false);

    _activeAlerts[alertIndex] = dismissedAlert;
    await _saveActiveAlerts();

    _onAlertsUpdated?.call();
    debugPrint('HazardAlertService: Alert dismissed - $alertId');
  }

  /// Ingest a hazard alert received from a remote channel (e.g., FCM data message).
  ///
  /// This is best-effort: it never throws and will ignore messages when the user
  /// doesn't have access to hazard alerts.
  Future<void> ingestRemoteHazardAlert(
    Map<String, dynamic> data, {
    bool showNotification = false,
  }) async {
    try {
      // Ensure dependencies are ready (notification service may be used below).
      if (!_isInitialized) {
        // initialize() includes location + notification init, preferences, persistence.
        await initialize();
      }

      if (!_isEnabled) return;

      final id = (data['id'] ??
              data['alertId'] ??
              data['hazardId'] ??
              'push_${DateTime.now().millisecondsSinceEpoch}')
          .toString();

      final title = (data['title'] ??
              data['event'] ??
              data['headline'] ??
              data['name'] ??
              'Hazard Alert')
          .toString();

      final description = (data['description'] ??
              data['body'] ??
              data['message'] ??
              data['details'] ??
              '')
          .toString();

      // NOTE: FCM uses a top-level `type` field for message routing (e.g. "hazard_alert").
      // Prefer hazardType/category fields for the actual hazard classification.
      final typeRaw =
          data['hazardType'] ?? data['hazard_type'] ?? data['category'];
      final severityRaw =
          data['severity'] ?? data['level'] ?? data['threat'] ?? data['priority'];

      final hazardType = _parseHazardType(typeRaw);
      final hazardSeverity = _parseHazardSeverity(severityRaw);

      final issuedAt =
          _parseDateTime(data['issuedAt'] ?? data['issued_at'] ?? data['timestamp']) ??
              DateTime.now();
      final expiresAt = _parseDateTime(
        data['expiresAt'] ?? data['expires_at'] ?? data['expires'] ?? data['end'],
      );

      final lat = _parseDouble(data['lat'] ?? data['latitude']);
      final lon = _parseDouble(data['lon'] ?? data['longitude']);
      final LocationInfo? affectedArea = (lat != null && lon != null)
          ? LocationInfo(
              latitude: lat,
              longitude: lon,
              accuracy: 0.0,
              timestamp: issuedAt,
              address: data['address']?.toString(),
            )
          : null;

      final sourceRaw = data['source'] ?? data['issuer'] ?? data['origin'];
      final source = _parseHazardSource(sourceRaw);

      final alert = HazardAlert(
        id: id,
        type: hazardType,
        severity: hazardSeverity,
        title: title,
        description: description,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        affectedArea: affectedArea,
        radius: _parseDouble(data['radiusKm'] ?? data['radius_km'] ?? data['radius']),
        affectedRegions:
            (data['regions'] as List?)?.whereType<String>().toList() ?? const [],
        source: source,
        instructions:
            (data['instructions'] as List?)?.whereType<String>().toList() ??
                _getHazardInstructions(hazardType),
        safetyTips:
            (data['safetyTips'] as List?)?.whereType<String>().toList() ??
                _getHazardSafetyTips(hazardType),
        tags: (data['tags'] as List?)?.whereType<String>().toList() ??
            ['push', 'remote'],
        metadata: data,
      );

      // De-duplicate and keep most recent version.
      final existingIndex = _activeAlerts.indexWhere((a) => a.id == alert.id);
      if (existingIndex >= 0) {
        _activeAlerts[existingIndex] = alert;
      } else {
        _activeAlerts.add(alert);
      }

      await _saveActiveAlerts();

      // Avoid duplicate notifications: NotificationService already surfaces
      // foreground pushes, and system notifications may already exist for
      // background delivery.
      if (showNotification) {
        await _sendHazardNotification(alert);
      }
      _onHazardAlert?.call(alert);
      _notifyAlertsUpdated();
    } catch (e) {
      debugPrint('HazardAlertService: Remote ingest failed - $e');
    }
  }

  HazardType _parseHazardType(Object? raw) {
    final s = (raw ?? '').toString().toLowerCase().trim();
    if (s.isEmpty) return HazardType.weather;

    if (s.contains('earthquake')) return HazardType.earthquake;
    if (s.contains('flood')) return HazardType.flood;
    if (s.contains('fire') || s.contains('wildfire')) return HazardType.fire;
    if (s.contains('tornado')) return HazardType.tornado;
    if (s.contains('hurricane') || s.contains('cyclone')) {
      return HazardType.hurricane;
    }
    if (s.contains('tsunami')) return HazardType.tsunami;
    if (s.contains('landslide')) return HazardType.landslide;
    if (s.contains('avalanche')) return HazardType.avalanche;
    if (s.contains('storm')) return HazardType.severeStorm;
    if (s.contains('heat')) return HazardType.heatWave;
    if (s.contains('cold') || s.contains('freeze')) return HazardType.coldWave;
    if (s.contains('air') || s.contains('smoke') || s.contains('aqi')) {
      return HazardType.airQuality;
    }
    if (s.contains('radiation')) return HazardType.radiation;
    if (s.contains('chemical')) return HazardType.chemicalSpill;
    if (s.contains('gas')) return HazardType.gasLeak;
    if (s.contains('power') || s.contains('outage')) return HazardType.powerOutage;
    if (s.contains('water') && s.contains('contam')) {
      return HazardType.waterContamination;
    }
    if (s.contains('road') || s.contains('closure')) return HazardType.roadClosure;
    if (s.contains('civil')) return HazardType.civilEmergency;
    if (s.contains('amber')) return HazardType.amberAlert;
    if (s.contains('security') || s.contains('threat')) {
      return HazardType.securityThreat;
    }
    if (s.contains('evac')) return HazardType.evacuation;
    if (s.contains('shelter')) return HazardType.shelterInPlace;

    // Best-effort fallback.
    return HazardType.weather;
  }

  HazardSeverity _parseHazardSeverity(Object? raw) {
    final s = (raw ?? '').toString().toLowerCase().trim();
    if (s.isEmpty) return HazardSeverity.moderate;

    if (s.contains('critical') || s.contains('emergency')) {
      return HazardSeverity.critical;
    }
    if (s.contains('extreme') || s.contains('red')) return HazardSeverity.extreme;
    if (s.contains('severe') || s.contains('orange')) return HazardSeverity.severe;
    if (s.contains('moderate') || s.contains('yellow')) {
      return HazardSeverity.moderate;
    }
    if (s.contains('minor') || s.contains('low')) return HazardSeverity.minor;
    if (s.contains('info')) return HazardSeverity.info;

    // Numeric priority, common in some push payloads.
    final n = int.tryParse(s);
    if (n != null) {
      if (n >= 90) return HazardSeverity.critical;
      if (n >= 75) return HazardSeverity.extreme;
      if (n >= 50) return HazardSeverity.severe;
      if (n >= 25) return HazardSeverity.moderate;
      return HazardSeverity.minor;
    }

    return HazardSeverity.moderate;
  }

  HazardSource _parseHazardSource(Object? raw) {
    final s = (raw ?? '').toString().toLowerCase().trim();
    if (s.contains('weather')) return HazardSource.nationalWeatherService;
    if (s.contains('emergency')) return HazardSource.emergencyManagement;
    if (s.contains('authority') || s.contains('local')) {
      return HazardSource.localAuthorities;
    }
    if (s.contains('community')) return HazardSource.communityReport;
    if (s.contains('sensor')) return HazardSource.sensorNetwork;
    if (s.contains('satellite')) return HazardSource.satelliteData;
    if (s.contains('automated') || s.contains('system')) {
      return HazardSource.automatedSystem;
    }
    if (s.contains('user')) return HazardSource.userReport;
    return HazardSource.emergencyManagement;
  }

  double? _parseDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      // Heuristic: seconds vs milliseconds.
      if (raw > 2000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    final s = raw.toString();
    final asInt = int.tryParse(s);
    if (asInt != null) return _parseDateTime(asInt);
    return DateTime.tryParse(s);
  }

  /// Get hazard alerts near user location
  Future<List<HazardAlert>> getNearbyAlerts({double radiusKm = 50.0}) async {
    final userLocation = await _locationService.getCurrentLocation();
    if (userLocation == null) {
      return _activeAlerts.where((a) => a.isActive).toList();
    }

    return _activeAlerts.where((alert) {
      if (!alert.isActive || alert.isExpired) return false;
      if (alert.affectedArea == null) return true; // Global alerts

      // Calculate distance (simplified for demo)
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        alert.affectedArea!.latitude,
        alert.affectedArea!.longitude,
      );

      return distance <= (alert.radius ?? radiusKm);
    }).toList();
  }

  /// Start weather updates with adaptive interval
  void _startWeatherUpdates() {
    _setupBatteryMonitoring();
    _rescheduleWeatherTimer();
  }

  void _rescheduleWeatherTimer() {
    _weatherUpdateTimer?.cancel();
    final interval = _getAdaptiveWeatherInterval();
    _weatherUpdateTimer = Timer.periodic(interval, (timer) async {
      if (_weatherAlertsEnabled) {
        await _fetchWeatherAlerts();
      }
    });
    debugPrint(
      'HazardAlertService: Weather timer set to ${interval.inMinutes} min',
    );
  }

  Duration _getAdaptiveWeatherInterval() {
    // Base interval: 15 minutes
    Duration interval = const Duration(minutes: 15);
    // If charging or full -> more frequent
    if (_batteryState == BatteryState.charging ||
        _batteryState == BatteryState.full) {
      interval = const Duration(minutes: 10);
    }
    // If alerts disabled -> long interval (acts as sleep)
    if (!_isEnabled || !_weatherAlertsEnabled) {
      interval = const Duration(minutes: 60);
    }
    return interval;
  }

  void _setupBatteryMonitoring() {
    try {
      final battery = Battery();
      // Prime state
      battery.batteryState.then((state) {
        _batteryState = state;
        _rescheduleWeatherTimer();
      });
      _batterySub?.cancel();
      _batterySub = battery.onBatteryStateChanged.listen((state) {
        _batteryState = state;
        _rescheduleWeatherTimer();
      });
    } catch (e) {
      debugPrint('HazardAlertService: Battery monitoring unavailable - $e');
    }
  }

  /// Start alert expiration monitoring
  void _startExpirationMonitoring() {
    _alertExpirationTimer = Timer.periodic(
      const Duration(minutes: 5), // Check every 5 minutes
      (timer) async {
        await _removeExpiredAlerts();
      },
    );
  }

  /// Fetch weather alerts with exponential backoff and rate limiting
  Future<void> _fetchWeatherAlerts() async {
    try {
      if (!_isEnabled || !_weatherAlertsEnabled) return;
      if (_isOffline) return; // Skip network calls when offline

      // Check if we're in exponential backoff period
      if (_apiBackoffUntil != null &&
          DateTime.now().isBefore(_apiBackoffUntil!)) {
        debugPrint(
          'HazardAlertService: In backoff period until ${_apiBackoffUntil!.toIso8601String()}',
        );
        return;
      }

      // Respect minimum fetch cadence to avoid rapid polling (5 min minimum)
      if (_lastWeatherFetch != null &&
          DateTime.now().difference(_lastWeatherFetch!) <
              const Duration(minutes: 5)) {
        return;
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) return;

      // Use OpenWeather One Call (2.5) API to fetch alerts
      // We re-use the API key from WeatherService
      final apiKey = WeatherService.apiKey;
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/onecall?lat=${location.latitude}&lon=${location.longitude}&appid=$apiKey&units=metric&exclude=current,minutely,hourly,daily',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        _consecutiveApiFailures++;
        debugPrint(
          'HazardAlertService: OpenWeather alerts error ${response.statusCode} (failure $_consecutiveApiFailures/$_maxApiFailures)',
        );

        // Implement exponential backoff: 2^n minutes (2, 4, 8, 16, ...)
        if (_consecutiveApiFailures >= _maxApiFailures) {
          final backoffMinutes = (1 << _consecutiveApiFailures).clamp(2, 60);
          _apiBackoffUntil = DateTime.now().add(
            Duration(minutes: backoffMinutes),
          );
          debugPrint(
            'HazardAlertService: Too many failures, backing off for $backoffMinutes minutes',
          );
        }
        return;
      }

      // Reset failure counter on successful response
      _consecutiveApiFailures = 0;
      _apiBackoffUntil = null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final alerts = (data['alerts'] as List?) ?? const [];

      // Build new weather alerts list
      final List<WeatherAlert> fetchedWeatherAlerts = [];
      for (final item in alerts) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final String event = (map['event'] ?? 'Weather Alert').toString();
        final int? start = (map['start'] is int) ? map['start'] as int : null;
        final int? end = (map['end'] is int) ? map['end'] as int : null;
        final String description = (map['description'] ?? '').toString();
        final String sender = (map['sender_name'] ?? 'Official Source')
            .toString();
        final List<String> tags =
            (map['tags'] as List?)?.whereType<String>().toList() ?? [];

        // Determine severity heuristically
        final severity = _mapEventToSeverity(event, description, tags);

        final effective = start != null
            ? DateTime.fromMillisecondsSinceEpoch(start * 1000)
            : DateTime.now();
        final expires = end != null
            ? DateTime.fromMillisecondsSinceEpoch(end * 1000)
            : null;

        final alertId =
            'OW_${start ?? DateTime.now().millisecondsSinceEpoch}_'
            '${event.hashCode}';

        final weatherAlert = WeatherAlert(
          id: alertId,
          event: event,
          severity: severity,
          effective: effective,
          expires: expires,
          headline: '$event in Effect',
          description: description.isNotEmpty
              ? description
              : 'An official $event has been issued in your area.',
          instruction: _getWeatherInstruction(event),
          areas: [sender],
          parameters: {'sender': sender, 'tags': tags},
        );

        fetchedWeatherAlerts.add(weatherAlert);

        // Convert to hazard alert and add to active alerts if new
        final hazardAlert = HazardAlert(
          id: weatherAlert.id,
          type: HazardType.weather,
          severity: weatherAlert.severity,
          title: weatherAlert.headline,
          description: weatherAlert.description,
          issuedAt: weatherAlert.effective,
          expiresAt: weatherAlert.expires,
          affectedRegions: weatherAlert.areas,
          source: HazardSource.nationalWeatherService,
          instructions: [weatherAlert.instruction],
          weatherData: weatherAlert.parameters,
          tags: ['weather', 'official'],
        );

        if (!_activeAlerts.any((a) => a.id == hazardAlert.id)) {
          _activeAlerts.add(hazardAlert);
          await _sendHazardNotification(hazardAlert);
          _onWeatherAlert?.call(weatherAlert);
          _onHazardAlert?.call(hazardAlert);
        }
      }

      // Update weather alerts list (replace existing with fresh set)
      _weatherAlerts
        ..clear()
        ..addAll(fetchedWeatherAlerts);

      // Limit total active alerts to prevent memory issues (keep 50 most recent)
      if (_activeAlerts.length > 50) {
        _activeAlerts.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
        _activeAlerts = _activeAlerts.take(50).toList();
        debugPrint('HazardAlertService: Trimmed alerts to 50 most recent');
      }

      await _saveActiveAlerts();
      _lastWeatherFetch = DateTime.now();
      _notifyAlertsUpdated();

      debugPrint(
        'HazardAlertService: Successfully fetched ${fetchedWeatherAlerts.length} weather alerts',
      );
    } on TimeoutException catch (e) {
      _consecutiveApiFailures++;
      debugPrint(
        'HazardAlertService: API timeout - $e (failure $_consecutiveApiFailures/$_maxApiFailures)',
      );
      if (_consecutiveApiFailures >= _maxApiFailures) {
        final backoffMinutes = (1 << _consecutiveApiFailures).clamp(2, 60);
        _apiBackoffUntil = DateTime.now().add(
          Duration(minutes: backoffMinutes),
        );
      }
    } catch (e) {
      _consecutiveApiFailures++;
      debugPrint(
        'HazardAlertService: Error fetching weather alerts - $e (failure $_consecutiveApiFailures/$_maxApiFailures)',
      );
      if (_consecutiveApiFailures >= _maxApiFailures) {
        final backoffMinutes = (1 << _consecutiveApiFailures).clamp(2, 60);
        _apiBackoffUntil = DateTime.now().add(
          Duration(minutes: backoffMinutes),
        );
      }
    }
  }

  /// Map OpenWeather event/description/tags to a HazardSeverity
  HazardSeverity _mapEventToSeverity(
    String event,
    String description,
    List<String> tags,
  ) {
    final e = event.toLowerCase();
    final d = description.toLowerCase();
    final t = tags.map((s) => s.toLowerCase()).toList();

    bool has(String s) => e.contains(s) || d.contains(s) || t.contains(s);

    if (has('tornado') || has('hurricane') || has('cyclone')) {
      return HazardSeverity.extreme;
    }
    if (has('flash flood') || has('flood warning')) {
      return HazardSeverity.severe;
    }
    if (has('warning') || has('severe')) {
      return HazardSeverity.severe;
    }
    if (has('watch')) {
      return HazardSeverity.moderate;
    }
    if (has('advisory')) {
      return HazardSeverity.minor;
    }
    return HazardSeverity.moderate;
  }

  /// Remove expired alerts
  Future<void> _removeExpiredAlerts() async {
    final now = DateTime.now();
    final initialCount = _activeAlerts.length;

    _activeAlerts.removeWhere((alert) => alert.isExpired);
    _weatherAlerts.removeWhere(
      (alert) => alert.expires != null && now.isAfter(alert.expires!),
    );
    _emergencyBroadcasts.removeWhere((broadcast) => broadcast.isExpired);

    if (_activeAlerts.length != initialCount) {
      await _saveActiveAlerts();
      _notifyAlertsUpdated();
      debugPrint(
        'HazardAlertService: Removed ${initialCount - _activeAlerts.length} expired alerts',
      );
    }
  }

  /// Send hazard notification (with rate limiting)
  Future<void> _sendHazardNotification(HazardAlert alert) async {
    if (!_isEnabled) return;

    final severityEmoji = _getSeverityEmoji(alert.severity);
    final typeEmoji = _getTypeEmoji(alert.type);

    // Only send notifications for moderate severity and above to reduce noise
    if (alert.severity == HazardSeverity.info ||
        alert.severity == HazardSeverity.minor) {
      debugPrint(
        'HazardAlertService: Skipping notification for low-severity alert: ${alert.title}',
      );
      return;
    }

    await _notificationService.showNotification(
      title: '$severityEmoji $typeEmoji ${alert.title}',
      body: alert.description,
      importance: _getNotificationImportance(alert.severity),
      persistent:
          alert.severity == HazardSeverity.extreme ||
          alert.severity == HazardSeverity.critical,
    );
  }

  // Mock alerts generation method REMOVED - production uses real API data only

  /// Get hazard radius based on type and severity
  double _getHazardRadius(HazardType type, HazardSeverity severity) {
    final baseRadius = switch (type) {
      HazardType.earthquake => 100.0,
      HazardType.tsunami => 50.0,
      HazardType.tornado => 25.0,
      HazardType.fire => 15.0,
      HazardType.flood => 20.0,
      HazardType.chemicalSpill => 10.0,
      HazardType.gasLeak => 5.0,
      HazardType.roadClosure => 2.0,
      _ => 10.0,
    };

    final severityMultiplier = switch (severity) {
      HazardSeverity.info => 0.5,
      HazardSeverity.minor => 0.7,
      HazardSeverity.moderate => 1.0,
      HazardSeverity.severe => 1.5,
      HazardSeverity.extreme => 2.0,
      HazardSeverity.critical => 3.0,
    };

    return baseRadius * severityMultiplier;
  }

  /// Get hazard instructions
  List<String> _getHazardInstructions(HazardType type) {
    return switch (type) {
      HazardType.weather => [
        'Monitor weather conditions',
        'Stay indoors if severe',
      ],
      HazardType.earthquake => [
        'Drop, Cover, Hold On',
        'Stay away from windows',
      ],
      HazardType.fire => [
        'Evacuate if instructed',
        'Stay low if smoke present',
      ],
      HazardType.flood => [
        'Move to higher ground',
        'Do not drive through water',
      ],
      HazardType.tornado => ['Seek shelter immediately', 'Go to lowest floor'],
      HazardType.chemicalSpill => ['Evacuate area', 'Avoid breathing vapors'],
      HazardType.gasLeak => [
        'Leave area immediately',
        'Do not use electrical devices',
      ],
      HazardType.roadClosure => [
        'Use alternate routes',
        'Allow extra travel time',
      ],
      _ => ['Follow local authority instructions', 'Stay alert'],
    };
  }

  /// Get hazard safety tips
  List<String> _getHazardSafetyTips(HazardType type) {
    return switch (type) {
      HazardType.weather => ['Have emergency kit ready', 'Charge devices'],
      HazardType.earthquake => [
        'Have emergency supplies',
        'Know evacuation routes',
      ],
      HazardType.fire => ['Have escape plan', 'Know meeting point'],
      HazardType.flood => ['Have emergency kit', 'Know evacuation routes'],
      HazardType.tornado => ['Have safe room identified', 'Practice drills'],
      HazardType.chemicalSpill => [
        'Have masks ready',
        'Know evacuation routes',
      ],
      HazardType.gasLeak => [
        'Know gas shutoff location',
        'Have flashlight ready',
      ],
      HazardType.roadClosure => ['Check traffic apps', 'Plan alternate routes'],
      _ => ['Stay informed', 'Have emergency contacts ready'],
    };
  }

  /// Get weather instruction
  String _getWeatherInstruction(String event) {
    return switch (event) {
      'Severe Thunderstorm' =>
        'Seek shelter indoors. Avoid windows and electrical equipment.',
      'Flash Flood' =>
        'Move to higher ground immediately. Do not drive through flooded roads.',
      'High Wind' =>
        'Secure loose objects. Avoid areas with trees and power lines.',
      'Winter Storm' =>
        'Stay indoors. If you must travel, keep emergency supplies in vehicle.',
      _ => 'Follow local emergency management instructions.',
    };
  }

  /// Calculate distance between two points (simplified)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Get severity emoji
  String _getSeverityEmoji(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => 'ℹ️',
      HazardSeverity.minor => '⚠️',
      HazardSeverity.moderate => '🟡',
      HazardSeverity.severe => '🟠',
      HazardSeverity.extreme => '🔴',
      HazardSeverity.critical => '🚨',
    };
  }

  /// Get type emoji
  String _getTypeEmoji(HazardType type) {
    return switch (type) {
      HazardType.weather => '🌩️',
      HazardType.earthquake => '🌍',
      HazardType.fire => '🔥',
      HazardType.flood => '🌊',
      HazardType.tornado => '🌪️',
      HazardType.hurricane => '🌀',
      HazardType.tsunami => '🌊',
      HazardType.landslide => '⛰️',
      HazardType.avalanche => '❄️',
      HazardType.chemicalSpill => '☣️',
      HazardType.gasLeak => '💨',
      HazardType.roadClosure => '🚧',
      HazardType.powerOutage => '⚡',
      HazardType.airQuality => '😷',
      _ => '⚠️',
    };
  }

  /// Get notification importance based on severity
  NotificationImportance _getNotificationImportance(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => NotificationImportance.low,
      HazardSeverity.minor => NotificationImportance.defaultImportance,
      HazardSeverity.moderate => NotificationImportance.defaultImportance,
      HazardSeverity.severe => NotificationImportance.high,
      HazardSeverity.extreme => NotificationImportance.max,
      HazardSeverity.critical => NotificationImportance.max,
    };
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('hazard_alerts_enabled') ?? true;
      _weatherAlertsEnabled = prefs.getBool('weather_alerts_enabled') ?? true;
      _communityAlertsEnabled =
          prefs.getBool('community_alerts_enabled') ?? true;
      _emergencyBroadcastsEnabled =
          prefs.getBool('emergency_broadcasts_enabled') ?? true;
    } catch (e) {
      debugPrint('HazardAlertService: Failed to load preferences - $e');
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hazard_alerts_enabled', _isEnabled);
      await prefs.setBool('weather_alerts_enabled', _weatherAlertsEnabled);
      await prefs.setBool('community_alerts_enabled', _communityAlertsEnabled);
      await prefs.setBool(
        'emergency_broadcasts_enabled',
        _emergencyBroadcastsEnabled,
      );
    } catch (e) {
      debugPrint('HazardAlertService: Failed to save preferences - $e');
    }
  }

  /// Load saved data from storage
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load active alerts
      final alertsJson = prefs.getStringList('active_hazard_alerts') ?? [];
      _activeAlerts = alertsJson
          .map((json) => HazardAlert.fromJson(jsonDecode(json)))
          .where((alert) => !alert.isExpired)
          .toList();

      // Load community reports
      final reportsJson = prefs.getStringList('community_hazard_reports') ?? [];
      _communityReports = reportsJson
          .map((json) => CommunityHazardReport.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('HazardAlertService: Failed to load saved data - $e');
    }
  }

  /// Save active alerts to storage
  Future<void> _saveActiveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _activeAlerts
          .map((alert) => jsonEncode(alert.toJson()))
          .toList();
      await prefs.setStringList('active_hazard_alerts', alertsJson);
    } catch (e) {
      debugPrint('HazardAlertService: Failed to save alerts - $e');
    }
  }

  /// Save community reports to storage
  Future<void> _saveCommunityReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = _communityReports
          .map((report) => jsonEncode(report.toJson()))
          .toList();
      await prefs.setStringList('community_hazard_reports', reportsJson);
    } catch (e) {
      debugPrint('HazardAlertService: Failed to save reports - $e');
    }
  }

  /// Generate unique alert ID
  String _generateAlertId() {
    return 'ALERT_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// Generate unique report ID
  String _generateReportId() {
    return 'REPORT_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;
  bool get weatherAlertsEnabled => _weatherAlertsEnabled;
  bool get communityAlertsEnabled => _communityAlertsEnabled;
  bool get emergencyBroadcastsEnabled => _emergencyBroadcastsEnabled;

  List<HazardAlert> get activeAlerts =>
      List.from(_activeAlerts.where((a) => a.isActive && !a.isExpired));
  List<CommunityHazardReport> get communityReports =>
      List.from(_communityReports);
  List<WeatherAlert> get weatherAlerts => List.from(_weatherAlerts);
  List<EmergencyBroadcast> get emergencyBroadcasts =>
      List.from(_emergencyBroadcasts);

  // Setters
  set isEnabled(bool enabled) {
    _isEnabled = enabled;
    _savePreferences();
    _notifyAlertsUpdated();
    if (_isEnabled) {
      _rescheduleWeatherTimer();
    } else {
      _weatherUpdateTimer?.cancel();
    }
  }

  set weatherAlertsEnabled(bool enabled) {
    _weatherAlertsEnabled = enabled;
    _savePreferences();
    _notifyAlertsUpdated();
    if (_weatherAlertsEnabled && _isEnabled) {
      _rescheduleWeatherTimer();
    } else {
      _weatherUpdateTimer?.cancel();
    }
  }

  set communityAlertsEnabled(bool enabled) {
    _communityAlertsEnabled = enabled;
    _savePreferences();
    _notifyAlertsUpdated();
  }

  set emergencyBroadcastsEnabled(bool enabled) {
    _emergencyBroadcastsEnabled = enabled;
    _savePreferences();
    _notifyAlertsUpdated();
  }

  // Event handlers
  void setHazardAlertCallback(Function(HazardAlert) callback) {
    _onHazardAlert = callback;
  }

  void setCommunityReportCallback(Function(CommunityHazardReport) callback) {
    _onCommunityReport = callback;
  }

  void setWeatherAlertCallback(Function(WeatherAlert) callback) {
    _onWeatherAlert = callback;
  }

  void setAlertsUpdatedCallback(Function() callback) {
    _onAlertsUpdated = callback;
  }

  /// Multi-listener support for alerts updated
  void addAlertsUpdatedListener(VoidCallback listener) {
    if (!_alertsUpdatedListeners.contains(listener)) {
      _alertsUpdatedListeners.add(listener);
    }
  }

  void removeAlertsUpdatedListener(VoidCallback listener) {
    _alertsUpdatedListeners.remove(listener);
  }

  void _notifyAlertsUpdated() {
    _onAlertsUpdated?.call();
    for (final l in List<VoidCallback>.from(_alertsUpdatedListeners)) {
      try {
        l();
      } catch (e) {
        debugPrint('HazardAlertService: listener threw - $e');
      }
    }
  }

  /// Dispose of the service
  void dispose() {
    _weatherUpdateTimer?.cancel();
    _alertExpirationTimer?.cancel();
    _batterySub?.cancel();
    _offlineSub?.cancel();
  }

  /// Public manual refresh respecting guards
  Future<void> refreshWeatherAlerts() async {
    await _fetchWeatherAlerts();
  }
}
