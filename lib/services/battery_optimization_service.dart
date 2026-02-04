import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/battery_optimization_settings.dart';

/// Service for managing battery optimization and power-saving features
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  final Battery _battery = Battery();

  // Battery state tracking
  BatteryState _currentBatteryState = BatteryState.unknown;
  int _currentBatteryLevel = 100;
  bool _isOptimizationEnabled = true;

  // Optimization settings
  BatteryOptimizationSettings _settings = BatteryOptimizationSettings();

  // Timers for different optimization levels
  Timer? _batteryMonitorTimer;
  Timer? _lowBatteryTimer;

  // Callbacks
  Function(BatteryOptimizationLevel)? _onOptimizationLevelChanged;
  Function(String)? _onBatteryWarning;

  /// Initialize the battery optimization service
  Future<void> initialize() async {
    try {
      await _updateBatteryStatus();
      _startBatteryMonitoring();
      debugPrint('BatteryOptimizationService: Initialized successfully');
    } catch (e) {
      debugPrint('BatteryOptimizationService: Error initializing - $e');
    }
  }

  /// Start monitoring battery status
  void _startBatteryMonitoring() {
    _batteryMonitorTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _updateBatteryStatus();
    });
  }

  /// Update current battery status
  Future<void> _updateBatteryStatus() async {
    try {
      // Skip if monitoring is disabled (prevents warnings during hot reload)
      if (_batteryMonitorTimer == null || !_batteryMonitorTimer!.isActive) {
        return;
      }

      _currentBatteryState = await _battery.batteryState;
      _currentBatteryLevel = await _battery.batteryLevel;

      // Determine optimization level based on battery status
      final optimizationLevel = _determineOptimizationLevel();

      // Trigger optimization level change if needed
      _onOptimizationLevelChanged?.call(optimizationLevel);

      // Check for low battery warnings
      _checkLowBatteryWarnings();
    } catch (e) {
      debugPrint(
        'BatteryOptimizationService: Error updating battery status - $e',
      );
    }
  }

  /// Determine optimization level based on battery status
  BatteryOptimizationLevel _determineOptimizationLevel() {
    if (!_isOptimizationEnabled) {
      return BatteryOptimizationLevel.none;
    }

    if (_currentBatteryLevel <= 15) {
      return BatteryOptimizationLevel.aggressive;
    } else if (_currentBatteryLevel <= 25) {
      return BatteryOptimizationLevel.moderate;
    } else if (_currentBatteryLevel <= 50) {
      return BatteryOptimizationLevel.light;
    } else {
      return BatteryOptimizationLevel.none;
    }
  }

  /// Check for low battery warnings
  void _checkLowBatteryWarnings() {
    if (_currentBatteryLevel <= 20 &&
        _currentBatteryState == BatteryState.discharging) {
      _onBatteryWarning?.call(
        'Battery level is $_currentBatteryLevel%. Consider charging your device.',
      );
    }

    if (_currentBatteryLevel <= 10 &&
        _currentBatteryState == BatteryState.discharging) {
      _onBatteryWarning?.call(
        'Critical battery level: $_currentBatteryLevel%. Charging recommended immediately.',
      );
    }
  }

  /// Get current optimization settings
  BatteryOptimizationSettings get optimizationSettings => _settings;

  /// Update optimization settings
  void updateSettings(BatteryOptimizationSettings settings) {
    _settings = settings;
    _isOptimizationEnabled = settings.enabled;
    debugPrint('BatteryOptimizationService: Settings updated');
  }

  /// Get recommended sensor update intervals based on battery level
  Duration getRecommendedSensorInterval() {
    final level = _determineOptimizationLevel();

    switch (level) {
      case BatteryOptimizationLevel.none:
        return const Duration(milliseconds: 500); // 2 Hz (reduced from 10 Hz)
      case BatteryOptimizationLevel.light:
        return const Duration(milliseconds: 1000); // 1 Hz (reduced from 5 Hz)
      case BatteryOptimizationLevel.moderate:
        return const Duration(milliseconds: 2000); // 0.5 Hz (reduced from 2 Hz)
      case BatteryOptimizationLevel.aggressive:
        return const Duration(milliseconds: 5000); // 0.2 Hz (reduced from 1 Hz)
    }
  }

  /// Get recommended location update intervals based on battery level
  Duration getRecommendedLocationInterval() {
    final level = _determineOptimizationLevel();

    switch (level) {
      case BatteryOptimizationLevel.none:
        return const Duration(seconds: 30); // Reduced from 5s
      case BatteryOptimizationLevel.light:
        return const Duration(minutes: 1); // Reduced from 10s
      case BatteryOptimizationLevel.moderate:
        return const Duration(minutes: 2); // Reduced from 30s
      case BatteryOptimizationLevel.aggressive:
        return const Duration(minutes: 5); // Reduced from 1min
    }
  }

  /// Get recommended background processing frequency based on battery level
  Duration getRecommendedBackgroundProcessingInterval() {
    final level = _determineOptimizationLevel();

    switch (level) {
      case BatteryOptimizationLevel.none:
        return const Duration(
          seconds: 5,
        ); // Process every 5s (reduced from 500ms)
      case BatteryOptimizationLevel.light:
        return const Duration(
          seconds: 10,
        ); // Process every 10s (reduced from 1s)
      case BatteryOptimizationLevel.moderate:
        return const Duration(
          seconds: 30,
        ); // Process every 30s (reduced from 2s)
      case BatteryOptimizationLevel.aggressive:
        return const Duration(
          minutes: 1,
        ); // Process every 1min (reduced from 5s)
    }
  }

  /// Check if background processing should be reduced
  bool shouldReduceBackgroundProcessing() {
    final level = _determineOptimizationLevel();
    return level == BatteryOptimizationLevel.moderate ||
        level == BatteryOptimizationLevel.aggressive;
  }

  /// Check if network requests should be batched
  bool shouldBatchNetworkRequests() {
    final level = _determineOptimizationLevel();
    return level == BatteryOptimizationLevel.moderate ||
        level == BatteryOptimizationLevel.aggressive;
  }

  /// Get current battery level
  int get currentBatteryLevel => _currentBatteryLevel;

  /// Get current battery state
  BatteryState get currentBatteryState => _currentBatteryState;

  /// Check if battery is low
  bool get isBatteryLow => _currentBatteryLevel <= 20;

  /// Check if battery is critical
  bool get isBatteryCritical => _currentBatteryLevel <= 10;

  /// Set optimization level change callback
  void setOptimizationLevelCallback(
    Function(BatteryOptimizationLevel) callback,
  ) {
    _onOptimizationLevelChanged = callback;
  }

  /// Set battery warning callback
  void setBatteryWarningCallback(Function(String) callback) {
    _onBatteryWarning = callback;
  }

  /// Enable or disable optimization
  void setOptimizationEnabled(bool enabled) {
    _isOptimizationEnabled = enabled;
    debugPrint(
      'BatteryOptimizationService: Optimization ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Dispose of resources
  void dispose() {
    _batteryMonitorTimer?.cancel();
    _lowBatteryTimer?.cancel();
  }
}
