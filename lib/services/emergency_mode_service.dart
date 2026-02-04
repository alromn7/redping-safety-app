import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/sos_session.dart';
import '../models/battery_optimization_settings.dart';
import 'battery_optimization_service.dart';
import 'performance_monitoring_service.dart';
import 'memory_optimization_service.dart';

/// Service for managing emergency mode optimization during SOS activation
class EmergencyModeService {
  static final EmergencyModeService _instance =
      EmergencyModeService._internal();
  factory EmergencyModeService() => _instance;
  EmergencyModeService._internal();

  // Emergency state
  bool _isEmergencyModeActive = false;
  SOSSession? _currentEmergencySession;

  // Original settings backup
  Map<String, dynamic> _originalSettings = {};

  // Services
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();
  final PerformanceMonitoringService _performanceService =
      PerformanceMonitoringService();
  final MemoryOptimizationService _memoryService = MemoryOptimizationService();

  // Emergency mode timers
  Timer? _emergencyModeTimer;
  Timer? _batteryCheckTimer;

  // Callbacks
  Function(bool)? _onEmergencyModeChanged;
  Function(String)? _onBatteryWarning;

  /// Initialize the emergency mode service
  Future<void> initialize() async {
    try {
      debugPrint('EmergencyModeService: Initialized successfully');
    } catch (e) {
      debugPrint('EmergencyModeService: Error initializing - $e');
    }
  }

  /// Activate emergency mode during SOS
  Future<void> activateEmergencyMode(SOSSession session) async {
    if (_isEmergencyModeActive) return;

    _isEmergencyModeActive = true;
    _currentEmergencySession = session;

    debugPrint(
      'EmergencyModeService: Activating emergency mode for SOS ${session.id}',
    );

    // Backup current settings
    await _backupCurrentSettings();

    // Apply emergency optimizations
    await _applyEmergencyOptimizations();

    // Start emergency monitoring
    _startEmergencyMonitoring();

    _onEmergencyModeChanged?.call(true);
  }

  /// Deactivate emergency mode
  Future<void> deactivateEmergencyMode() async {
    if (!_isEmergencyModeActive) return;

    debugPrint('EmergencyModeService: Deactivating emergency mode');

    // Stop emergency monitoring
    _stopEmergencyMonitoring();

    // Restore original settings
    await _restoreOriginalSettings();

    _isEmergencyModeActive = false;
    _currentEmergencySession = null;

    _onEmergencyModeChanged?.call(false);
  }

  /// Backup current optimization settings
  Future<void> _backupCurrentSettings() async {
    _originalSettings = {
      'sensor_interval': _batteryService.getRecommendedSensorInterval(),
      'location_interval': _batteryService.getRecommendedLocationInterval(),
      'processing_interval': _batteryService
        .getRecommendedBackgroundProcessingInterval(),
      'background_processing': _batteryService
          .shouldReduceBackgroundProcessing(),
      'network_batching': _batteryService.shouldBatchNetworkRequests(),
      'performance_monitoring': _performanceService.isMonitoring,
      'memory_cleanup': true, // Will be restored
    };

    debugPrint('EmergencyModeService: Settings backed up');
  }

  /// Apply emergency optimizations
  Future<void> _applyEmergencyOptimizations() async {
    // Ultra-aggressive battery optimization
    _batteryService.updateSettings(
      BatteryOptimizationSettings(
        enabled: true,
        reduceAnimations: true,
        reduceBackgroundProcessing: true,
        batchNetworkRequests: true,
        disableNonEssentialFeatures: true,
        lowBatteryThreshold: 30, // Higher threshold for emergency
        criticalBatteryThreshold: 15, // Higher threshold for emergency
      ),
    );

    // Disable non-essential services
    _performanceService.setMonitoringEnabled(false);

    // Force memory cleanup
    _memoryService.forceGarbageCollection();

    debugPrint('EmergencyModeService: Emergency optimizations applied');
  }

  /// Start emergency monitoring
  void _startEmergencyMonitoring() {
    // Monitor battery every 30 seconds during emergency
    _batteryCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkEmergencyBatteryStatus();
    });

    // Auto-deactivate after 24 hours if still active
    _emergencyModeTimer = Timer(const Duration(hours: 24), () {
      if (_isEmergencyModeActive) {
        debugPrint(
          'EmergencyModeService: Auto-deactivating emergency mode after 24 hours',
        );
        deactivateEmergencyMode();
      }
    });
  }

  /// Stop emergency monitoring
  void _stopEmergencyMonitoring() {
    _batteryCheckTimer?.cancel();
    _emergencyModeTimer?.cancel();
  }

  /// Check battery status during emergency
  void _checkEmergencyBatteryStatus() {
    final batteryLevel = _batteryService.currentBatteryLevel;
    final batteryState = _batteryService.currentBatteryState;

    // Emergency battery warnings
    if (batteryLevel <= 20 && batteryState == BatteryState.discharging) {
      _onBatteryWarning?.call(
        'EMERGENCY: Battery at $batteryLevel%. Consider charging or reducing usage.',
      );
    }

    if (batteryLevel <= 10 && batteryState == BatteryState.discharging) {
      _onBatteryWarning?.call(
        'CRITICAL: Battery at $batteryLevel%. Emergency features may be limited.',
      );
    }

    if (batteryLevel <= 5 && batteryState == BatteryState.discharging) {
      _onBatteryWarning?.call(
        'FINAL WARNING: Battery at $batteryLevel%. Device may shut down soon.',
      );
    }
  }

  /// Restore original settings
  Future<void> _restoreOriginalSettings() async {
    // Restore performance monitoring
    _performanceService.setMonitoringEnabled(
      _originalSettings['performance_monitoring'] ?? true,
    );

    // Restore memory cleanup
    if (_originalSettings['memory_cleanup'] == true) {
      _memoryService.forceGarbageCollection();
    }

    debugPrint('EmergencyModeService: Original settings restored');
  }

  /// Get emergency-optimized sensor interval
  Duration getEmergencySensorInterval() {
    if (!_isEmergencyModeActive) {
      return _batteryService.getRecommendedSensorInterval();
    }

    // Emergency mode: Ultra-low frequency to preserve battery
    return const Duration(seconds: 2); // 0.5 Hz
  }

  /// Get emergency-optimized location interval
  Duration getEmergencyLocationInterval() {
    if (!_isEmergencyModeActive) {
      return _batteryService.getRecommendedLocationInterval();
    }

    // Emergency mode: More frequent location updates for safety
    return const Duration(seconds: 10); // Every 10 seconds
  }

  /// Get emergency-optimized background processing interval
  Duration getEmergencyBackgroundProcessingInterval() {
    if (!_isEmergencyModeActive) {
      return _batteryService.getRecommendedBackgroundProcessingInterval();
    }

    // Emergency mode: Minimal background processing
    return const Duration(minutes: 2); // Every 2 minutes
  }

  /// Check if a service should be disabled during emergency
  bool shouldDisableService(String serviceName) {
    if (!_isEmergencyModeActive) return false;

    // Services to disable during emergency
    const disabledServices = [
      'chat_service',
      'satellite_service',
      'activity_service',
      'help_assistant_service',
      'privacy_security_service',
      'legal_documents_service',
      'volunteer_rescue_service',
      'organization_service',
    ];

    return disabledServices.contains(serviceName);
  }

  /// Check if a feature should be disabled during emergency
  bool shouldDisableFeature(String featureName) {
    if (!_isEmergencyModeActive) return false;

    // Features to disable during emergency
    const disabledFeatures = [
      'animations',
      'background_sync',
      'performance_monitoring',
      'memory_optimization',
      'network_batching',
      'ui_enhancements',
    ];

    return disabledFeatures.contains(featureName);
  }

  /// Get emergency battery consumption estimate
  double getEmergencyBatteryConsumptionPerHour() {
    if (!_isEmergencyModeActive) {
      return 3.0; // Normal optimized consumption
    }

    // Emergency mode consumption
    return 2.0; // Even lower consumption during emergency
  }

  /// Get current emergency session
  SOSSession? get currentEmergencySession => _currentEmergencySession;

  /// Check if emergency mode is active
  bool get isEmergencyModeActive => _isEmergencyModeActive;

  /// Get emergency mode duration
  Duration get emergencyModeDuration {
    if (!_isEmergencyModeActive || _currentEmergencySession == null) {
      return Duration.zero;
    }

    return DateTime.now().difference(_currentEmergencySession!.startTime);
  }

  /// Set emergency mode change callback
  void setEmergencyModeCallback(Function(bool) callback) {
    _onEmergencyModeChanged = callback;
  }

  /// Set battery warning callback
  void setBatteryWarningCallback(Function(String) callback) {
    _onBatteryWarning = callback;
  }

  /// Dispose of resources
  void dispose() {
    _emergencyModeTimer?.cancel();
    _batteryCheckTimer?.cancel();
  }
}
