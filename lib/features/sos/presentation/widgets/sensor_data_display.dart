import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/weather_service.dart';
import '../../../../core/test_overrides.dart';

/// Compact sensor data display showing GPS speed, altitude, pressure, and temperature
class SensorDataDisplay extends StatefulWidget {
  final Function(double?)?
  onSpeedUpdate; // Callback to update parent with GPS speed
  final bool forceGPS; // If true, run GPS even when not charging

  const SensorDataDisplay({
    super.key,
    this.onSpeedUpdate,
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

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<BarometerEvent>? _barometerSubscription;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _weatherUpdateTimer;

  bool _hasLocationPermission = false;
  bool _isInitializing = true;
  bool _isCharging = false;
  bool _isAppActive = true;

  final Battery _battery = Battery();
  final WeatherService _weatherService = WeatherService();

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

    if (_isAppActive) {
      debugPrint('SensorDisplay: App active - checking GPS state');
      _updateGPSState();
    } else {
      debugPrint('SensorDisplay: App inactive - pausing GPS to save battery');
      _stopGPSTracking();
    }
  }

  /// Monitor battery charging state
  void _monitorBatteryState() async {
    // Check initial state
    final initialState = await _battery.batteryState;
    _isCharging =
        initialState == BatteryState.charging ||
        initialState == BatteryState.full;

    debugPrint('SensorDisplay: Initial charging state: $_isCharging');
    _updateGPSState();

    // Listen for changes
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
      BatteryState state,
    ) {
      final wasCharging = _isCharging;
      _isCharging =
          state == BatteryState.charging || state == BatteryState.full;

      if (wasCharging != _isCharging) {
        debugPrint('SensorDisplay: Charging changed: $_isCharging');
        _updateGPSState();
      }
    });
  }

  /// Update GPS tracking based on charging and app state
  void _updateGPSState() {
    final shouldRun =
        _isAppActive &&
        _hasLocationPermission &&
        (widget.forceGPS || _isCharging);
    if (shouldRun) {
      debugPrint(
        'SensorDisplay: Starting GPS (reason: ${widget.forceGPS ? 'forceGPS' : 'charging'})',
      );
      _startGPSTracking();
    } else {
      if (!_isAppActive) {
        debugPrint('SensorDisplay: Stopping GPS (app inactive)');
      } else if (!_hasLocationPermission) {
        debugPrint('SensorDisplay: Stopping GPS (no permission)');
      } else if (!_isCharging && !widget.forceGPS) {
        debugPrint('SensorDisplay: Stopping GPS (power save - not charging)');
      }
      _stopGPSTracking();
    }
  }

  Future<void> _initializeSensors() async {
    setState(() {
      _isInitializing = true;
    });

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _hasLocationPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (_hasLocationPermission) {
      // GPS will be controlled by charging state
      _updateGPSState();
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

  void _startGPSTracking() async {
    // Don't start if already running
    if (_positionSubscription != null) return;

    try {
      debugPrint('SensorDisplay: Starting GPS tracking with HIGH accuracy');

      // Get initial position immediately with high accuracy
      final Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.best, // Best accuracy for speed/altitude
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _speed = initialPosition.speed; // m/s
          _altitude = initialPosition.altitude; // meters
        });
        // Notify parent (SOS page) of speed update for movement status
        if (widget.onSpeedUpdate != null && _speed != null) {
          final speedKmh = _speed! * 3.6; // Convert m/s to km/h
          widget.onSpeedUpdate!(speedKmh);
        }
        debugPrint(
          'GPS Initial: Speed=$_speed m/s (${(_speed! * 3.6).toStringAsFixed(1)} km/h), Altitude=$_altitude m (${(_altitude! * 3.28084).toStringAsFixed(0)} ft)',
        );
      }

      // Stream updates with high accuracy + time-based refresh
      const LocationSettings locationSettings = LocationSettings(
        accuracy:
            LocationAccuracy.best, // Best accuracy for precise speed/altitude
        distanceFilter: 5, // Update every 5 meters minimum
        timeLimit: Duration(
          seconds: 3,
        ), // Force update every 3 seconds even if stationary
      );

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _speed = position.speed; // m/s
                _altitude = position.altitude; // meters
              });
              // Notify parent (SOS page) of speed update for movement status
              if (widget.onSpeedUpdate != null && _speed != null) {
                final speedKmh = _speed! * 3.6; // Convert m/s to km/h
                widget.onSpeedUpdate!(speedKmh);
              }
              debugPrint(
                'GPS Update: Speed=${_speed!.toStringAsFixed(2)} m/s (${(_speed! * 3.6).toStringAsFixed(1)} km/h), Altitude=${_altitude!.toStringAsFixed(1)} m (${(_altitude! * 3.28084).toStringAsFixed(0)} ft), Accuracy=${position.accuracy.toStringAsFixed(1)}m',
              );
            }
          });
    } catch (e) {
      debugPrint('GPS Error: $e');
    }
  }

  void _stopGPSTracking() {
    if (_positionSubscription != null) {
      debugPrint('SensorDisplay: Stopping GPS tracking');
      _positionSubscription?.cancel();
      _positionSubscription = null;
      // Keep last known values instead of clearing them
    }
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
    _positionSubscription?.cancel();
    _barometerSubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _weatherUpdateTimer?.cancel();
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
                    'GPS paused (power save)',
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
