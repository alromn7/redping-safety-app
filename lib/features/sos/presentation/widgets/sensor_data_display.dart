import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// GPS stream handled by LocationService to avoid duplicates
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/weather_service.dart';
import '../../../../core/test_overrides.dart';
import '../../../../services/location_service.dart';
import '../../../../models/sos_session.dart'; // Import LocationInfo type

/// Compact sensor data display showing GPS speed, altitude, pressure, and temperature
class SensorDataDisplay extends StatefulWidget {
  final Function(double?)?
  onSpeedUpdate; // Callback to update parent with GPS speed
  final Function(double?)?
  onAltitudeUpdate; // Callback to update parent with GPS altitude (meters)
  final bool forceGPS; // If true, run GPS even when not charging

  const SensorDataDisplay({
    super.key,
    this.onSpeedUpdate,
    this.onAltitudeUpdate,
    this.forceGPS = false,
  });

  @override
  State<SensorDataDisplay> createState() => _SensorDataDisplayState();
}

class _SensorDataDisplayState extends State<SensorDataDisplay>
    with WidgetsBindingObserver {
  // GPS data
  double? _speed; // m/s
  double? _altitude; // meters

  // Sensor data
  double? _pressure; // hPa (hectopascals) from barometer
  double? _temperature; // Celsius (if available)

  Function(LocationInfo)? _locationListener; // Listener for location updates
  StreamSubscription<BarometerEvent>? _barometerSubscription;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _weatherUpdateTimer;

  bool _hasLocationPermission = false;
  bool _isInitializing = true;
  bool _isCharging = false;
  bool _isAppActive = true;

  final Battery _battery = Battery();
  final WeatherService _weatherService = WeatherService();
  // LocationService provides shared GPS updates

  // Diagnostics throttling
  DateTime? _lastLogTime;
  double? _lastLoggedSpeedKmh;
  double? _lastLoggedAltitudeM;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (TestOverrides.isTest) {
      // Skip platform-dependent initializations during tests
      _isInitializing = false;
      return;
    }
    _initializeSensors();
    _monitorBatteryState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Pause GPS when app goes to background/inactive
    _isAppActive = state == AppLifecycleState.resumed;

    final locationService = LocationService();
    if (_isAppActive) {
      debugPrint(
        'SensorDisplay: App active - ensuring LocationService running',
      );
      locationService.startTracking();
    } else {
      debugPrint('SensorDisplay: App inactive - hibernating LocationService');
      locationService.hibernate();
    }
  }

  /// Monitor battery charging state
  void _monitorBatteryState() async {
    try {
      // Check initial state
      final initialState = await _battery.batteryState;
      if (!mounted) return; // Prevent updates after disposal

      _isCharging =
          initialState == BatteryState.charging ||
          initialState == BatteryState.full;

      debugPrint('SensorDisplay: Initial charging state: $_isCharging');
      // Charging no longer gates GPS; LocationService manages lifecycle.

      // Listen for changes
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        BatteryState state,
      ) {
        if (!mounted) return; // Prevent updates after disposal

        final wasCharging = _isCharging;
        _isCharging =
            state == BatteryState.charging || state == BatteryState.full;

        if (wasCharging != _isCharging) {
          debugPrint('SensorDisplay: Charging changed: $_isCharging');
          // No GPS start/stop here; keep LocationService running as needed.
        }
      });
    } catch (e) {
      debugPrint('SensorDisplay: Battery monitoring error - $e');
    }
  }

  /// Subscribe to LocationService updates for speed/altitude
  void _subscribeLocationUpdates() {
    final locationService = LocationService();
    _locationListener = (LocationInfo location) {
      if (!mounted) return;
      final speedMps = location.speed ?? 0.0;
      final speedKmh = speedMps * 3.6;
      setState(() {
        _speed = speedMps;
        _altitude = location.altitude;
      });
      if (widget.onSpeedUpdate != null) {
        widget.onSpeedUpdate!(speedKmh < 2.0 ? 0.0 : speedKmh);
      }
      if (widget.onAltitudeUpdate != null) {
        widget.onAltitudeUpdate!(_altitude);
      }

      // Lightweight diagnostics: log every ~5s or on significant change
      _logDiagnostics(
        speedKmh: speedKmh,
        altitudeM: _altitude,
        accuracyM: location.accuracy,
      );
    };
    locationService.addLocationListener(_locationListener!);
  }

  void _logDiagnostics({
    required double speedKmh,
    required double? altitudeM,
    required double? accuracyM,
  }) {
    if (!kDebugMode) return;

    final now = DateTime.now();
    final shouldTimeLog = _lastLogTime == null ||
        now.difference(_lastLogTime!).inSeconds >= 5;
    final speedDelta = (_lastLoggedSpeedKmh == null)
        ? double.infinity
        : (speedKmh - _lastLoggedSpeedKmh!).abs();
    final altDelta = (_lastLoggedAltitudeM == null || altitudeM == null)
        ? double.infinity
        : (altitudeM - _lastLoggedAltitudeM!).abs();
    final shouldValueLog = speedDelta >= 5.0 || altDelta >= 50.0;

    if (shouldTimeLog || shouldValueLog) {
      debugPrint(
        'SensorDataDisplay: speed ${speedKmh.toStringAsFixed(1)} km/h, alt ${(altitudeM ?? 0).toStringAsFixed(0)} m, acc ${(accuracyM ?? 0).toStringAsFixed(1)} m',
      );
      _lastLogTime = now;
      _lastLoggedSpeedKmh = speedKmh;
      _lastLoggedAltitudeM = altitudeM;
    }
  }

  Future<void> _initializeSensors() async {
    setState(() {
      _isInitializing = true;
    });
    // Initialize LocationService (manages permissions internally)
    final locationService = LocationService();
    final initialized = await locationService.initialize();
    _hasLocationPermission = initialized;
    if (_hasLocationPermission) {
      _subscribeLocationUpdates();
      await locationService.startTracking();
      _startWeatherUpdates();
    }

    // Barometer is low power, always run
    _startBarometerTracking();

    // Mark initialization complete after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }

  void _startWeatherUpdates() {
    // Fetch weather immediately
    _updateWeather();

    // Then update every 10 minutes
    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _updateWeather();
    });
  }

  Future<void> _updateWeather() async {
    final temp = await _weatherService.fetchTemperature();
    if (mounted && temp != null) {
      setState(() {
        _temperature = temp;
      });
    }
  }

  // GPS tracking handled by LocationService; no direct stream here

  void _stopGPSTracking() {
    // No-op: LocationService manages GPS lifecycle
  }

  void _startBarometerTracking() {
    try {
      _barometerSubscription = barometerEventStream().listen(
        (BarometerEvent event) {
          if (mounted) {
            setState(() {
              // BarometerEvent provides pressure in pascals
              // Convert to hPa (hectopascals/millibars): 1 hPa = 100 Pa
              // Standard atmospheric pressure is ~1013 hPa
              _pressure = event.pressure / 100.0;
            });
          }
        },
        onError: (error) {
          // Barometer not available on this device
          if (mounted) {
            setState(() {
              _pressure = null;
            });
          }
        },
      );
    } catch (e) {
      // Barometer sensor not supported
      debugPrint('Barometer not available: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // No direct GPS subscription here; LocationService manages it
    _barometerSubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _weatherUpdateTimer?.cancel();
    if (_locationListener != null) {
      try {
        LocationService().removeLocationListener(_locationListener!);
      } catch (_) {}
    }
    _weatherService.stopUpdates();
    super.dispose();
  }

  String _formatSpeed(double? speedMps) {
    if (_isInitializing) return '...';
    if (!_hasLocationPermission) return 'N/A';
    if (speedMps == null || speedMps < 0) return '0.0';
    final speedKmh = speedMps * 3.6;
    // Clamp unrealistic speeds (max 1500 km/h for commercial aircraft)
    if (speedKmh > 1500) return '1500+';
    return speedKmh.toStringAsFixed(1);
  }

  String _formatAltitude(double? altitude) {
    if (_isInitializing) return '...';
    if (!_hasLocationPermission) return 'N/A';
    if (altitude == null) return '0';
    // Handle negative altitudes (below sea level)
    return altitude.toStringAsFixed(0);
  }

  String _formatPressure(double? pressure) {
    if (_isInitializing) return '...';
    if (pressure == null) return 'N/A';
    // Validate reasonable pressure range (850-1100 hPa)
    if (pressure < 850 || pressure > 1100) return 'N/A';
    return pressure.toStringAsFixed(1);
  }

  String _formatTemperature(double? temp) {
    if (_isInitializing) return '...';
    if (!_hasLocationPermission) return 'N/A';
    if (temp == null) return 'N/A';
    return temp.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCharging
              ? AppTheme.safeGreen.withValues(alpha: 0.3)
              : AppTheme.primaryRed.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Power status indicator
          if (!_isCharging)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.battery_saver,
                    size: 10,
                    color: AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Power saver',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppTheme.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Sensor readings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed
              _buildSensorItem(
                icon: Icons.speed,
                label: 'Speed',
                value: _formatSpeed(_speed),
                unit: 'km/h',
              ),

              // Altitude
              _buildSensorItem(
                icon: Icons.terrain,
                label: 'Alt',
                value: _formatAltitude(_altitude),
                unit: 'm',
              ),

              // Pressure
              _buildSensorItem(
                icon: Icons.compress,
                label: 'Pressure',
                value: _formatPressure(_pressure),
                unit: 'hPa',
              ),

              // Temperature (from weather API)
              _buildSensorItem(
                icon: Icons.thermostat,
                label: 'Temp',
                value: _formatTemperature(_temperature),
                unit: '°C',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryRed.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 8,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
