import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../models/redping_mode.dart';
import 'sensor_service.dart';
import 'location_service.dart';

/// RedPing Mode Service - Manages activity-based safety modes
class RedPingModeService extends ChangeNotifier {
  static final RedPingModeService _instance = RedPingModeService._internal();
  factory RedPingModeService() => _instance;
  RedPingModeService._internal();

  final SensorService _sensorService = SensorService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = const Uuid();

  // Current active mode
  RedPingMode? _activeMode;
  ActiveModeSession? _activeSession;

  // Mode history
  final List<ActiveModeSession> _modeHistory = [];

  // Getters
  RedPingMode? get activeMode => _activeMode;
  ActiveModeSession? get activeSession => _activeSession;
  bool get hasActiveMode => _activeMode != null;
  List<ActiveModeSession> get modeHistory => List.unmodifiable(_modeHistory);

  /// Initialize service
  Future<void> initialize() async {
    await _loadActiveMode();
    await _loadModeHistory();
  }

  /// Activate a mode
  Future<void> activateMode(RedPingMode mode) async {
    try {
      // End current session if exists
      if (_activeSession != null) {
        await deactivateMode();
      }

      // Create new session
      final session = ActiveModeSession(
        sessionId: _uuid.v4(),
        mode: mode,
        startTime: DateTime.now(),
      );

      _activeMode = mode;
      _activeSession = session;

      // Apply sensor configuration
      await _applySensorConfig(mode.sensorConfig);

      // Apply location configuration
      await _applyLocationConfig(mode.locationConfig);

      // Save to preferences
      await _saveActiveMode();

      notifyListeners();

      debugPrint('✅ RedPing Mode activated: ${mode.name}');
    } catch (e) {
      debugPrint('❌ Error activating mode: $e');
      rethrow;
    }
  }

  /// Deactivate current mode
  Future<void> deactivateMode() async {
    try {
      if (_activeSession != null) {
        // End session
        _activeSession!.endTime = DateTime.now();

        // Add to history
        _modeHistory.insert(0, _activeSession!);
        if (_modeHistory.length > 50) {
          _modeHistory.removeLast();
        }

        await _saveModeHistory();
      }

      _activeMode = null;
      _activeSession = null;

      // Reset to default configurations
      await _resetToDefaults();

      // Clear from preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_redping_mode');

      notifyListeners();

      debugPrint('✅ RedPing Mode deactivated');
    } catch (e) {
      debugPrint('❌ Error deactivating mode: $e');
      rethrow;
    }
  }

  /// Apply sensor configuration
  Future<void> _applySensorConfig(SensorConfig config) async {
    try {
      // Apply RedPing Mode overrides into SensorService
      await _sensorService.applyRedPingModeConfig(config);

      // Ensure monitoring is active with location tracking
      final desiredLowPower = switch (config.powerMode) {
        PowerMode.high => false,
        PowerMode.low => true,
        PowerMode.balanced => true,
      };

      // Ensure monitoring is active with location tracking
      await _sensorService.startMonitoring(
        locationService: _locationService,
        lowPowerMode: desiredLowPower,
      );

      // If already monitoring, apply power mode preference (avoid toggling if SOS already forced active)
      if (_sensorService.isMonitoring) {
        if (config.powerMode == PowerMode.high && _sensorService.isLowPowerMode) {
          await _sensorService.setActiveMode();
        } else if (config.powerMode == PowerMode.low && !_sensorService.isLowPowerMode) {
          await _sensorService.setLowPowerMode();
        }
      }

      debugPrint(
        '✅ Sensor config applied: Crash=${config.crashThreshold} Fall=${config.fallThreshold}',
      );
    } catch (e) {
      debugPrint('❌ Error applying sensor config: $e');
    }
  }

  /// Apply location configuration
  Future<void> _applyLocationConfig(LocationConfig config) async {
    try {
      // Store config for reference (location settings currently use defaults)
      // Future enhancement: Make location service configurable

      // Ensure location tracking is active
      await _locationService.getCurrentLocation();

      debugPrint(
        '✅ Location config applied: Breadcrumb=${config.breadcrumbInterval.inSeconds}s',
      );
    } catch (e) {
      debugPrint('❌ Error applying location config: $e');
    }
  }

  /// Reset to default configurations
  Future<void> _resetToDefaults() async {
    try {
      await _sensorService.clearRedPingModeConfig();

      debugPrint('✅ Reset to default configurations');
    } catch (e) {
      debugPrint('❌ Error resetting to defaults: $e');
    }
  }

  /// Update session stats
  void updateSessionStats(String key, dynamic value) {
    if (_activeSession != null) {
      _activeSession!.stats[key] = value;
      notifyListeners();
    }
  }

  /// Get session stat
  dynamic getSessionStat(String key) {
    return _activeSession?.stats[key];
  }

  /// Save active mode to preferences
  Future<void> _saveActiveMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeMode != null && _activeSession != null) {
        final data = {
          'mode': _activeMode!.toJson(),
          'session': _activeSession!.toJson(),
        };
        await prefs.setString('active_redping_mode', jsonEncode(data));
      }
    } catch (e) {
      debugPrint('❌ Error saving active mode: $e');
    }
  }

  /// Load active mode from preferences
  Future<void> _loadActiveMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('active_redping_mode');

      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _activeMode = RedPingMode.fromJson(
          json['mode'] as Map<String, dynamic>,
        );
        _activeSession = ActiveModeSession.fromJson(
          json['session'] as Map<String, dynamic>,
        );

        // Reapply configurations
        if (_activeMode != null) {
          await _applySensorConfig(_activeMode!.sensorConfig);
          await _applyLocationConfig(_activeMode!.locationConfig);
        }

        notifyListeners();
        debugPrint('✅ Loaded active mode: ${_activeMode?.name}');
      }
    } catch (e) {
      debugPrint('❌ Error loading active mode: $e');
    }
  }

  /// Save mode history
  Future<void> _saveModeHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _modeHistory.map((s) => s.toJson()).toList();
      await prefs.setString('redping_mode_history', jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Error saving mode history: $e');
    }
  }

  /// Load mode history
  Future<void> _loadModeHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('redping_mode_history');

      if (data != null) {
        final list = jsonDecode(data) as List<dynamic>;
        _modeHistory.clear();
        _modeHistory.addAll(
          list.map(
            (json) => ActiveModeSession.fromJson(json as Map<String, dynamic>),
          ),
        );
        debugPrint('✅ Loaded ${_modeHistory.length} mode sessions');
      }
    } catch (e) {
      debugPrint('❌ Error loading mode history: $e');
    }
  }

  /// Get predefined modes (will be expanded in next task)
  static List<RedPingMode> getPredefinedModes() {
    return [
      // Remote Area Mode
      RedPingMode(
        id: 'remote_area',
        name: 'Remote Area',
        description: 'Working in remote locations with limited connectivity',
        category: ModeCategory.work,
        icon: Icons.terrain,
        themeColor: Colors.orange,
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 150.0,
          enableFreefallDetection: true,
          enableAltitudeTracking: false,
          powerMode: PowerMode.balanced,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 30,
          enableOfflineMaps: true,
          enableRouteTracking: true,
          mapCacheRadiusKm: 10,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 15),
          autoCallEmergency: false,
          preferredRescue: RescueType.aerial,
        ),
        activeHazardTypes: ['isolation', 'weather', 'wildlife'],
        dashboardMetrics: ['duration', 'distance', 'altitude', 'signal'],
      ),

      // Working at Height Mode
      RedPingMode(
        id: 'working_height',
        name: 'Working at Height',
        description: 'Construction, maintenance, or climbing activities',
        category: ModeCategory.work,
        icon: Icons.construction,
        themeColor: Colors.amber,
        sensorConfig: const SensorConfig(
          crashThreshold: 160.0,
          fallThreshold: 120.0,
          enableFreefallDetection: true,
          enableAltitudeTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 20,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableProximityAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 5),
          autoCallEmergency: false,
          preferredRescue: RescueType.aerial,
        ),
        activeHazardTypes: ['fall', 'altitude', 'weather'],
        dashboardMetrics: ['duration', 'altitude', 'fall_events'],
      ),

      // High Risk Task Mode
      RedPingMode(
        id: 'high_risk',
        name: 'High Risk Task',
        description: 'Hazardous work environments requiring maximum monitoring',
        category: ModeCategory.work,
        icon: Icons.warning,
        themeColor: Colors.red,
        sensorConfig: const SensorConfig(
          crashThreshold: 150.0,
          fallThreshold: 130.0,
          violentHandlingMin: 80.0,
          enableFreefallDetection: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 20),
          accuracyTargetMeters: 20,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
          enableProximityAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 5),
          autoCallEmergency: false,
          enableVideoEvidence: true,
        ),
        activeHazardTypes: ['impact', 'fall', 'chemical', 'confined_space'],
        dashboardMetrics: ['duration', 'incidents', 'hazards'],
      ),

      // Travel Mode
      RedPingMode(
        id: 'travel',
        name: 'Travel Mode',
        description:
            'Journey safety with route tracking and destination monitoring',
        category: ModeCategory.travel,
        icon: Icons.flight_takeoff,
        themeColor: Colors.blue,
        sensorConfig: const SensorConfig(
          crashThreshold: 200.0, // Higher for vehicle impacts
          fallThreshold: 150.0,
          enableFreefallDetection: true,
          enableMotionTracking: true,
          powerMode: PowerMode.balanced,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(minutes: 1),
          accuracyTargetMeters: 50,
          enableOfflineMaps: true,
          enableRouteTracking: true,
          mapCacheRadiusKm: 20,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableTrafficAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 10),
          autoCallEmergency: false,
          emergencyMessage: 'I need help during my journey',
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: ['traffic', 'weather', 'route_deviation'],
        dashboardMetrics: ['journey_time', 'distance', 'checkpoints'],
      ),

      // Skiing/Snowboarding Mode
      RedPingMode(
        id: 'skiing',
        name: 'Skiing/Snowboarding',
        description:
            'Winter sports with avalanche awareness and slope monitoring',
        category: ModeCategory.extreme,
        icon: Icons.downhill_skiing,
        themeColor: const Color(0xFF1E88E5), // Snow blue
        sensorConfig: const SensorConfig(
          crashThreshold: 220.0, // High-speed impacts
          fallThreshold: 140.0,
          enableFreefallDetection: true,
          enableAltitudeTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 20),
          accuracyTargetMeters: 30,
          enableOfflineMaps: true,
          enableRouteTracking: true,
          mapCacheRadiusKm: 5,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true, // Avalanche alerts
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 5),
          autoCallEmergency: false,
          preferredRescue: RescueType.aerial,
        ),
        activeHazardTypes: ['avalanche', 'tree_well', 'altitude', 'cold'],
        dashboardMetrics: ['runs', 'altitude_gain', 'max_speed', 'crashes'],
      ),

      // Rock Climbing Mode
      RedPingMode(
        id: 'climbing',
        name: 'Rock Climbing',
        description:
            'Indoor/outdoor climbing with fall detection and belayer safety',
        category: ModeCategory.extreme,
        icon: Icons.terrain,
        themeColor: const Color(0xFF8D6E63), // Rock brown
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 100.0, // Lower for climbing falls
          enableFreefallDetection: true,
          enableAltitudeTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 20,
          enableRouteTracking: true,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 5),
          autoCallEmergency: false,
          preferredRescue: RescueType.aerial,
        ),
        activeHazardTypes: ['fall', 'altitude', 'rope_failure', 'weather'],
        dashboardMetrics: ['climbs', 'altitude', 'falls', 'duration'],
      ),

      // Hiking/Trekking Mode
      RedPingMode(
        id: 'hiking',
        name: 'Hiking/Trekking',
        description:
            'Trail safety with waypoint tracking and wilderness monitoring',
        category: ModeCategory.extreme,
        icon: Icons.hiking,
        themeColor: const Color(0xFF689F38), // Forest green
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 150.0,
          enableFreefallDetection: true,
          enableAltitudeTracking: true,
          powerMode: PowerMode.balanced,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 45),
          accuracyTargetMeters: 30,
          enableOfflineMaps: true,
          enableRouteTracking: true,
          mapCacheRadiusKm: 10,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 15),
          autoCallEmergency: false,
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: ['wildlife', 'weather', 'terrain', 'lost'],
        dashboardMetrics: [
          'distance',
          'altitude_gain',
          'waypoints',
          'duration',
        ],
      ),

      // Mountain Biking Mode
      RedPingMode(
        id: 'mountain_biking',
        name: 'Mountain Biking',
        description: 'Off-road cycling with crash detection and trail tracking',
        category: ModeCategory.extreme,
        icon: Icons.pedal_bike,
        themeColor: const Color(0xFFFF6F00), // Orange
        sensorConfig: const SensorConfig(
          crashThreshold: 200.0, // High-speed bike crashes
          fallThreshold: 140.0,
          enableFreefallDetection: true,
          enableMotionTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 15),
          accuracyTargetMeters: 25,
          enableRouteTracking: true,
          mapCacheRadiusKm: 15,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableTrafficAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 10),
          autoCallEmergency: false,
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: ['crash', 'fall', 'terrain', 'wildlife'],
        dashboardMetrics: ['distance', 'speed', 'crashes', 'elevation'],
      ),

      // Boating/Sailing Mode
      RedPingMode(
        id: 'boating',
        name: 'Boating/Sailing',
        description:
            'Water safety with man overboard detection and marine rescue',
        category: ModeCategory.extreme,
        icon: Icons.sailing,
        themeColor: const Color(0xFF0277BD), // Deep blue
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 130.0, // Man overboard
          enableFreefallDetection: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 20,
          enableOfflineMaps: true,
          enableRouteTracking: true,
          mapCacheRadiusKm: 30,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 0), // Immediate for man overboard
          autoCallEmergency: false,
          emergencyMessage: 'MAN OVERBOARD - Immediate assistance required',
          preferredRescue: RescueType.marine,
        ),
        activeHazardTypes: ['man_overboard', 'weather', 'marine_hazard'],
        dashboardMetrics: ['distance', 'speed', 'waypoints', 'duration'],
      ),

      // Scuba Diving Mode
      RedPingMode(
        id: 'scuba_diving',
        name: 'Scuba Diving',
        description:
            'Underwater safety with depth tracking and dive buddy monitoring',
        category: ModeCategory.extreme,
        icon: Icons.scuba_diving,
        themeColor: const Color(0xFF006064), // Deep ocean
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 150.0,
          enableAltitudeTracking: true, // For depth
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(minutes: 2),
          accuracyTargetMeters: 50,
          enableRouteTracking: true,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 0), // Immediate for dive emergency
          autoCallEmergency: false,
          emergencyMessage: 'DIVE EMERGENCY - Medical assistance required',
          preferredRescue: RescueType.marine,
        ),
        activeHazardTypes: [
          'decompression',
          'air_supply',
          'marine_life',
          'current',
        ],
        dashboardMetrics: ['dive_time', 'max_depth', 'dives', 'air_remaining'],
      ),

      // Open Water Swimming Mode
      RedPingMode(
        id: 'swimming',
        name: 'Open Water Swimming',
        description:
            'Swimmer safety with drift monitoring and fatigue detection',
        category: ModeCategory.extreme,
        icon: Icons.pool,
        themeColor: const Color(0xFF00ACC1), // Cyan
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 120.0, // Drowning detection
          enableFreefallDetection: true,
          enableMotionTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 25,
          enableRouteTracking: true,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 0), // Immediate
          autoCallEmergency: false,
          emergencyMessage: 'SWIMMER IN DISTRESS - Immediate rescue needed',
          preferredRescue: RescueType.marine,
        ),
        activeHazardTypes: [
          'drowning',
          'current',
          'marine_life',
          'hypothermia',
        ],
        dashboardMetrics: ['distance', 'pace', 'duration', 'drift'],
      ),

      // 4WD Off-roading Mode
      RedPingMode(
        id: 'offroad_4wd',
        name: '4WD Off-roading',
        description:
            'Vehicle recovery and wilderness navigation for off-road adventures',
        category: ModeCategory.extreme,
        icon: Icons.terrain,
        themeColor: const Color(0xFF795548), // Brown
        sensorConfig: const SensorConfig(
          crashThreshold: 250.0, // Very high for vehicle impacts
          fallThreshold: 180.0, // Rollover detection
          enableFreefallDetection: true,
          powerMode: PowerMode.balanced,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 30,
          enableOfflineMaps: true,
          enableRouteTracking: true,
          mapCacheRadiusKm: 25,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 15),
          autoCallEmergency: false,
          emergencyMessage: 'Vehicle emergency - assistance required',
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: ['rollover', 'stuck', 'wildlife', 'weather'],
        dashboardMetrics: [
          'distance',
          'terrain_difficulty',
          'stops',
          'duration',
        ],
      ),

      // Trail Running Mode
      RedPingMode(
        id: 'trail_running',
        name: 'Trail Running',
        description: 'Fast-paced trail monitoring with injury detection',
        category: ModeCategory.extreme,
        icon: Icons.directions_run,
        themeColor: const Color(0xFF7CB342), // Light green
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0,
          fallThreshold: 140.0,
          enableFreefallDetection: true,
          enableMotionTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 20),
          accuracyTargetMeters: 20,
          enableRouteTracking: true,
          mapCacheRadiusKm: 10,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 10),
          autoCallEmergency: false,
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: ['fall', 'injury', 'wildlife', 'lost'],
        dashboardMetrics: ['distance', 'pace', 'elevation', 'heart_rate'],
      ),

      // Skydiving/Paragliding Mode
      RedPingMode(
        id: 'skydiving',
        name: 'Skydiving/Paragliding',
        description:
            'Freefall and parachute monitoring with landing zone tracking',
        category: ModeCategory.extreme,
        icon: Icons.flight,
        themeColor: const Color(0xFFE91E63), // Pink
        sensorConfig: const SensorConfig(
          crashThreshold: 300.0, // Extreme impact
          fallThreshold: 50.0, // Freefall detection
          enableFreefallDetection: true,
          enableAltitudeTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 10),
          accuracyTargetMeters: 15,
          enableRouteTracking: true,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 0), // Immediate
          autoCallEmergency: false,
          emergencyMessage:
              'SKYDIVING EMERGENCY - Parachute malfunction or hard landing',
          preferredRescue: RescueType.aerial,
        ),
        activeHazardTypes: [
          'hard_landing',
          'parachute_fail',
          'wind',
          'altitude',
        ],
        dashboardMetrics: [
          'jumps',
          'freefall_time',
          'max_altitude',
          'landing_accuracy',
        ],
      ),

      // Flying (Private Pilot) Mode
      RedPingMode(
        id: 'flying',
        name: 'Flying (Private Pilot)',
        description:
            'General aviation safety with flight tracking and emergency landing',
        category: ModeCategory.extreme,
        icon: Icons.flight_takeoff,
        themeColor: const Color(0xFF1976D2), // Aviation blue
        sensorConfig: const SensorConfig(
          crashThreshold: 400.0, // Aircraft crash
          fallThreshold: 100.0,
          enableFreefallDetection: true,
          enableAltitudeTracking: true,
          powerMode: PowerMode.high,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(seconds: 30),
          accuracyTargetMeters: 50,
          enableRouteTracking: true,
          mapCacheRadiusKm: 50,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
          enableTrafficAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 0), // Immediate
          autoCallEmergency: false,
          emergencyMessage:
              'AIRCRAFT EMERGENCY - Immediate assistance required',
          preferredRescue: RescueType.aerial,
        ),
        activeHazardTypes: ['crash', 'engine_failure', 'weather', 'altitude'],
        dashboardMetrics: ['flight_time', 'altitude', 'speed', 'fuel'],
      ),

      // ====== FAMILY MODES ======

      // Family Mode (Age-Based Safety)
      RedPingMode(
        id: 'family_protection',
        name: 'Family Protection',
        description:
            'Comprehensive family safety with age-based thresholds, geofencing, and family circle management. Perfect for monitoring children, teens, and elderly family members.',
        category: ModeCategory.family,
        icon: Icons.family_restroom,
        themeColor: Colors.blue,
        sensorConfig: const SensorConfig(
          crashThreshold:
              140.0, // Balanced for all ages (children: 130, teens: 140, elderly: 120)
          fallThreshold: 130.0, // Sensitive for elderly fall detection
          violentHandlingMin: 90.0,
          violentHandlingMax: 140.0,
          monitoringInterval: Duration(
            milliseconds: 200,
          ), // Frequent monitoring for family safety
          enableFreefallDetection: true,
          enableMotionTracking: true,
          enableAltitudeTracking: false,
          powerMode: PowerMode.balanced,
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(
            minutes: 5,
          ), // Family movement tracking every 5 minutes
          accuracyTargetMeters: 20, // High accuracy for child tracking
          enableOfflineMaps: false,
          enableRouteTracking: true,
          enableGeofencing: true, // Geofence for schools, homes, parks
          mapCacheRadiusKm: 3,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
          enableProximityAlerts: true,
          enableTrafficAlerts: true,
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(
            seconds: 8,
          ), // 8s countdown for family confirmation
          autoCallEmergency: false, // Notify family first
          emergencyMessage:
              'FAMILY ALERT - A family member may need assistance. Last known location attached.',
          enableVideoEvidence: false,
          enableVoiceMessage: true,
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: const [
          'geofence',
          'wandering',
          'fall',
          'speed',
          'check_in',
        ],
        dashboardMetrics: const [
          'family_members',
          'geofence_status',
          'check_in_status',
          'last_location',
        ],
        autoTriggers: const [
          // Geofence exit trigger
          AutoTriggerRule(
            id: 'geofence_exit_alert',
            condition: 'geofence_exit',
            action: TriggerAction.notify,
            delay: Duration(seconds: 0),
            message: 'Family member has left the safe zone',
          ),
          // Wandering detection (elderly)
          AutoTriggerRule(
            id: 'wandering_detection',
            condition: 'unusual_movement_pattern',
            action: TriggerAction.notify,
            delay: Duration(minutes: 5),
            message:
                'Unusual movement detected. Please check on family member.',
          ),
          // Missed check-in
          AutoTriggerRule(
            id: 'missed_check_in',
            condition: 'check_in_overdue',
            action: TriggerAction.checkIn,
            delay: Duration(minutes: 15),
            message: 'Check-in missed. Attempting to locate...',
          ),
          // Teen driver speed alert
          AutoTriggerRule(
            id: 'teen_driver_speed',
            condition: 'speed_threshold_exceeded',
            action: TriggerAction.notify,
            delay: Duration(seconds: 10),
            message: 'Teen driver exceeding speed limit',
          ),
        ],
        statusMessage: 'Family safety monitoring active',
      ),

      // ====== GROUP MODES ======

      // Group Mode (Dynamic Groups)
      RedPingMode(
        id: 'group_activity',
        name: 'Group Activity',
        description:
            'Coordinate and track groups up to 50 members with live map, rally points, and activity-specific safety configs. Perfect for hiking groups, cycling clubs, team sports, and organized events.',
        category: ModeCategory.group,
        icon: Icons.groups,
        themeColor: Colors.green,
        sensorConfig: const SensorConfig(
          crashThreshold: 180.0, // Standard group activity threshold
          fallThreshold: 140.0,
          violentHandlingMin: 100.0,
          violentHandlingMax: 180.0,
          monitoringInterval: Duration(
            milliseconds: 500,
          ), // Balance battery vs tracking
          enableFreefallDetection: true,
          enableMotionTracking: true,
          enableAltitudeTracking: false,
          powerMode: PowerMode.high, // High power for constant group tracking
        ),
        locationConfig: const LocationConfig(
          breadcrumbInterval: Duration(
            minutes: 2,
          ), // Frequent for group coordination
          accuracyTargetMeters: 10, // High accuracy for group positions
          enableOfflineMaps: true, // Essential for group outdoor activities
          enableRouteTracking: true,
          enableGeofencing: true, // 1km group activity zone
          mapCacheRadiusKm: 10,
        ),
        hazardConfig: const HazardConfig(
          enableWeatherAlerts: true,
          enableEnvironmentalAlerts: true,
          enableProximityAlerts: true,
          enableTrafficAlerts: false, // Usually outdoor activities
        ),
        emergencyConfig: const EmergencyConfig(
          sosCountdown: Duration(seconds: 5), // Quick SOS for group emergencies
          autoCallEmergency: false, // Alert group leader first
          emergencyMessage:
              'GROUP EMERGENCY - A group member needs help! Location attached.',
          enableVideoEvidence: false,
          enableVoiceMessage: true,
          preferredRescue: RescueType.ground,
        ),
        activeHazardTypes: const [
          'separation',
          'rally_point',
          'weather',
          'member_emergency',
          'group_split',
        ],
        dashboardMetrics: const [
          'group_size',
          'members_in_range',
          'next_rally_point',
          'group_spread_meters',
        ],
        autoTriggers: const [
          // Member separation alert
          AutoTriggerRule(
            id: 'member_separation',
            condition: 'distance_from_group_exceeded',
            action: TriggerAction.alert,
            delay: Duration(seconds: 30),
            message: 'You are separated from the group. Return to group.',
          ),
          // Rally point check-in
          AutoTriggerRule(
            id: 'rally_point_check_in',
            condition: 'rally_point_reached',
            action: TriggerAction.checkIn,
            delay: Duration(seconds: 0),
            message: 'Rally point reached. Check in with group leader.',
          ),
          // Group emergency broadcast
          AutoTriggerRule(
            id: 'group_emergency_broadcast',
            condition: 'member_sos_triggered',
            action: TriggerAction.notify,
            delay: Duration(seconds: 0),
            message: 'GROUP EMERGENCY! A member needs assistance.',
          ),
          // Headcount mismatch
          AutoTriggerRule(
            id: 'headcount_check',
            condition: 'headcount_mismatch',
            action: TriggerAction.alert,
            delay: Duration(minutes: 1),
            message:
                'Headcount mismatch detected. Leader confirmation required.',
          ),
        ],
        statusMessage: 'Group activity coordination active',
      ),
    ];
  }
}
