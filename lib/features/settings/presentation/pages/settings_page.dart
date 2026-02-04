// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/location_service.dart';
import '../../../../services/google_cloud_api_service.dart';
import '../../../sos/presentation/widgets/emergency_info_card.dart';
import '../../../privacy/presentation/widgets/privacy_dashboard_card.dart';
import '../../../../config/testing_mode.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../tools/nonce_ttl_verifier.dart';

/// Settings page for app configuration and preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppServiceManager _serviceManager = AppServiceManager();

  // Settings state
  bool _crashDetectionEnabled = true;
  bool _fallDetectionEnabled = true;
  bool _voiceVerificationEnabled = true;
  bool _locationSharingEnabled = true;
  bool _hazardAlertsEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _communityAlertsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _medicalRemindersEnabled = true;
  bool _healthMonitoringEnabled = false;
  bool _snoringDetectionEnabled = false;
  // Sensitivity sliders: 0.0..1.0 (1.0 = most sensitive allowed by blueprint)
  double _crashSensitivity = 1.0; // maps to 180 m/s² at 1.0
  double _fallSensitivity = 0.85; // maps near 150 m/s² at ~0.83..0.85
  int _sosCountdown = 10;
  bool _alwaysSmsFallback = false;
  bool _alwaysAllowEmergencySms = false;

  // Status tracking
  bool _locationServicesEnabled = false;
  bool _isRefreshing = false;
  Timer? _statusRefreshTimer;

  // Dev flight simulation (debug only)
  bool _devSimFlight = false;
  double _devSimSpeedKmh = 280.0;
  double _devSimAltitudeM = 9000.0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _refreshLocationStatus();
    _startStatusRefresh();
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _applyDevFlightOverride({required bool enabled}) async {
    try {
      final ls = LocationService();
      await ls.initialize();
      if (enabled) {
        await ls.startTracking();
        ls.setDebugOverride(
          enabled: true,
          speedMps: _devSimSpeedKmh / 3.6,
          altitudeM: _devSimAltitudeM,
        );
      } else {
        ls.setDebugOverride(enabled: false);
      }
    } catch (e) {
      debugPrint('Settings Dev Flight Override error: $e');
    }
  }

  void _openDevFlightSimulator() {
    if (!kDebugMode) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        bool enabled = _devSimFlight;
        double speed = _devSimSpeedKmh;
        double alt = _devSimAltitudeM;
        return StatefulBuilder(
          builder: (context, setModalState) {
            void syncApply() {
              setState(() {
                _devSimFlight = enabled;
                _devSimSpeedKmh = speed;
                _devSimAltitudeM = alt;
              });
              _applyDevFlightOverride(enabled: enabled);
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.flight_takeoff),
                      SizedBox(width: 8),
                      Text('Developer Flight Simulator',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Simulate Flight'),
                    subtitle: const Text('Overrides GPS speed/altitude in-app'),
                    value: enabled,
                    onChanged: (v) {
                      setModalState(() => enabled = v);
                      syncApply();
                    },
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: enabled ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !enabled,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Speed (km/h)'),
                              Text(speed.toStringAsFixed(0)),
                            ],
                          ),
                          Slider(
                            min: 0,
                            max: 1200,
                            divisions: 120,
                            value: speed,
                            onChanged: (v) {
                              setModalState(() => speed = v);
                              syncApply();
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Altitude (m)'),
                              Text(alt.toStringAsFixed(0)),
                            ],
                          ),
                          Slider(
                            min: 0,
                            max: 12000,
                            divisions: 120,
                            value: alt,
                            onChanged: (v) {
                              setModalState(() => alt = v);
                              syncApply();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startStatusRefresh() {
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          // Update network and battery status
          _updateSystemStatus();
        });
      }
    });
  }

  void _updateSystemStatus() {
    // Update battery level and network status
    // In a real implementation, would use battery_plus package
    // For now, keeping static values updated by refresh
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _alwaysSmsFallback = prefs.getBool('always_sms_fallback') ?? false;
        _alwaysAllowEmergencySms =
            prefs.getBool('always_allow_emergency_sms') ?? false;
        _crashDetectionEnabled =
            prefs.getBool('crash_detection_enabled') ?? true;
        _fallDetectionEnabled = prefs.getBool('fall_detection_enabled') ?? true;
        _crashSensitivity =
            prefs.getDouble('crash_sensitivity') ?? 1.0; // default max allowed
        _fallSensitivity =
            prefs.getDouble('fall_sensitivity') ?? 0.85; // ~150 m/s²
        // Hazard alerts enabled: prefer stored pref, fallback to service state
        _hazardAlertsEnabled =
            prefs.getBool('hazard_alerts_enabled') ??
            _serviceManager.hazardService.isEnabled;
        _weatherAlertsEnabled =
            prefs.getBool('weather_alerts_enabled') ??
            _serviceManager.hazardService.weatherAlertsEnabled;
        _communityAlertsEnabled =
            prefs.getBool('community_alerts_enabled') ??
            _serviceManager.hazardService.communityAlertsEnabled;
        _medicalRemindersEnabled =
            prefs.getBool('medical_reminders_enabled') ?? true;
        _healthMonitoringEnabled =
            prefs.getBool('health_monitoring_enabled') ?? false;
        _snoringDetectionEnabled =
            prefs.getBool('snoring_detection_enabled') ?? false;
      });

      // Apply to live sensor service
      _applyDetectionToggles();
      _applySensitivityToSensorService();
      debugPrint(
        '[SafetyFlags] crash=$_crashDetectionEnabled fall=$_fallDetectionEnabled location=$_locationServicesEnabled hazard=$_hazardAlertsEnabled weather=$_weatherAlertsEnabled community=$_communityAlertsEnabled',
      );
    } catch (_) {}
  }

  Future<void> _refreshLocationStatus() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      // Ensure the service is initialized (requests permission if needed)
      await _serviceManager.locationService.initialize();

      // Read both permission and service availability
      final hasPermission = _serviceManager.locationService.hasPermission;
      final serviceEnabled = await _serviceManager.locationService
          .isLocationServiceAvailable();

      if (!mounted) return;
      setState(() {
        _locationServicesEnabled = hasPermission && serviceEnabled;
      });
      debugPrint(
        '[LocationStatus] permission=$hasPermission service=$serviceEnabled enabled=$_locationServicesEnabled',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status refreshed')));
      }
    } catch (_) {
      // Keep previous value on failure
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // Removed: _restoreSafetyProductionDefaults (Safety Detection UI removed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.main),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: _isRefreshing ? null : _refreshLocationStatus,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRouter.main),
            tooltip: 'Close Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Mode v2.0
            Text(
              'Test Mode v2.0 (Developer Tools)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Test Mode'),
                    subtitle: Text(
                      AppConstants.testingModeEnabled
                          ? 'Active: Lowered thresholds (8G shake triggers crash)'
                          : 'Off: Production thresholds (60+ km/h crashes only)',
                    ),
                    value: AppConstants.testingModeEnabled,
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          TestingMode.activate(
                            suppressDialogs: false,
                          );
                        } else {
                          TestingMode.deactivate();
                        }
                      });
                    },
                  ),
                  if (AppConstants.testingModeEnabled) ...[
                    SwitchListTile(
                      title: const Text('SMS Test Mode'),
                      subtitle: Text(
                        AppConstants.useSmsTestMode
                            ? 'SMS sent to test contacts (+1234567890, +0987654321)'
                            : 'SMS sent to real emergency contacts',
                      ),
                      value: AppConstants.useSmsTestMode,
                      onChanged: (val) {
                        setState(() {
                          AppConstants.useSmsTestMode = val;
                        });
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '🧪 Test Mode v2.0 Features:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Production Flow: All verification gates remain active',
                          ),
                          Text(
                            '• Lowered Thresholds: Shake phone (8G) triggers detection',
                          ),
                          Text(
                            '• Diagnostic Logging: Real-time sensor data capture',
                          ),
                          Text('• SMS Override: Optional test contact routing'),
                          SizedBox(height: 8),
                          Text(
                            'Thresholds:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '  Crash: 78.4 m/s² (8G shake) vs 180 m/s² production',
                          ),
                          Text(
                            '  Fall: 48 m/s² (0.3m drop) vs 150 m/s² production',
                          ),
                        ],
                      ),
                    ),
                    // Developer quick actions for security verification
                    const Divider(),
                    _DevSecurityActions(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status indicators moved to unified card above

            // const SizedBox(height: 16),

            // Emergency Information
            Text(
              'Emergency Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            const EmergencyInfoCard(),

            const SizedBox(height: 16),

            // Privacy & Security
            const PrivacyDashboardCard(),

            const SizedBox(height: 32),

            // Satellite Communication
            Text(
              'Satellite Communication',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.satellite_alt,
                  color: _serviceManager.satelliteService.isAvailable
                      ? AppTheme.safeGreen
                      : AppTheme.neutralGray,
                ),
                title: const Text('Satellite Settings'),
                subtitle: Text(
                  _serviceManager.satelliteService.isAvailable
                      ? 'Emergency satellite communication available'
                      : 'Satellite communication not supported',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                // Use push so back navigation returns to Settings without losing the stack
                onTap: () => context.push('/satellite'),
              ),
            ),
            const SizedBox(height: 32),

            // SOS Settings
            Text(
              'SOS Configuration',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'SOS Countdown Duration',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: Text(
                      '$_sosCountdown seconds',
                      style: const TextStyle(color: AppTheme.secondaryText),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: DropdownButton<int>(
                        value: _sosCountdown,
                        items: [5, 10, 15, 20, 30].map((seconds) {
                          return DropdownMenuItem<int>(
                            value: seconds,
                            child: Text('${seconds}s'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sosCountdown = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Voice Verification',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Use voice commands to confirm or cancel SOS',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _voiceVerificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _voiceVerificationEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Always allow emergency SMS',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Request SMS permission automatically at startup to ensure automatic emergency texts can send without delay.',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _alwaysAllowEmergencySms,
                    onChanged: (value) async {
                      setState(() {
                        _alwaysAllowEmergencySms = value;
                      });
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(
                          'always_allow_emergency_sms',
                          value,
                        );
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy & Location Settings
            Text(
              'Privacy & Location',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Location Sharing',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Share location with emergency contacts',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _locationSharingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationSharingEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Alerts & Notifications
            Text(
              'Alerts & Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Medication Reminders',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Daily notifications for your medications',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _medicalRemindersEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _medicalRemindersEnabled = value;
                      });
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('medical_reminders_enabled', value);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Medication reminders enabled'
                                    : 'Medication reminders disabled',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (_) {}
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Health Monitoring',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Track heart rate, steps, and sleep score (opt-in)',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _healthMonitoringEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _healthMonitoringEnabled = value;
                      });
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('health_monitoring_enabled', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Health monitoring enabled'
                                  : 'Health monitoring disabled',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Snoring Detection',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Local-only nightly snoring summary (no recordings saved)',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _snoringDetectionEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _snoringDetectionEnabled = value;
                      });
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('snoring_detection_enabled', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Snoring detection enabled'
                                  : 'Snoring detection disabled',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Hazard Alerts',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Receive weather and emergency alerts',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _hazardAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _hazardAlertsEnabled = value;
                      });
                      // Apply to service (persists to SharedPreferences internally)
                      try {
                        _serviceManager.hazardService.isEnabled = value;
                        final message = value
                            ? 'Hazard alerts enabled'
                            : 'Hazard alerts disabled';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Weather Alerts',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Official alerts from weather authorities',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _weatherAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _weatherAlertsEnabled = value;
                      });
                      try {
                        _serviceManager.hazardService.weatherAlertsEnabled =
                            value;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Weather alerts enabled'
                                  : 'Weather alerts disabled',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Community Reports',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Allow community-reported hazards',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _communityAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _communityAlertsEnabled = value;
                      });
                      try {
                        _serviceManager.hazardService.communityAlertsEnabled =
                            value;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Community reports enabled'
                                  : 'Community reports disabled',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Sound',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Play alert sounds',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Vibration',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Vibrate for alerts and notifications',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Always show SMS fallback',
                      style: TextStyle(color: AppTheme.primaryText),
                    ),
                    subtitle: const Text(
                      'Offer SMS prompt immediately on SOS (helps in poor data areas)',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    value: _alwaysSmsFallback,
                    onChanged: (value) async {
                      setState(() {
                        _alwaysSmsFallback = value;
                      });
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('always_sms_fallback', value);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Developer Tools
            if (kDebugMode) ...[
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.flight_takeoff,
                        color: AppTheme.infoBlue,
                      ),
                      title: const Text(
                        'Flight Simulation (Dev)',
                        style: TextStyle(color: AppTheme.primaryText),
                      ),
                      subtitle: Text(
                        _devSimFlight
                            ? 'Enabled • ${_devSimSpeedKmh.toStringAsFixed(0)} km/h • ${_devSimAltitudeM.toStringAsFixed(0)} m'
                            : 'Disabled',
                        style: const TextStyle(color: AppTheme.secondaryText),
                      ),
                      trailing: Switch(
                        value: _devSimFlight,
                        onChanged: (v) {
                          setState(() => _devSimFlight = v);
                          _applyDevFlightOverride(enabled: v);
                        },
                      ),
                      onTap: _openDevFlightSimulator,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.message_outlined,
                        color: AppTheme.warningOrange,
                      ),
                      title: const Text(
                        'Cross Messaging Test',
                        style: TextStyle(color: AppTheme.primaryText),
                      ),
                      subtitle: const Text(
                        'Test cross messaging policies (Development)',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.neutralGray,
                        size: 16,
                      ),
                      onTap: () => context.go('/settings/cross-messaging-test'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Reset Settings
            Card(
              child: ListTile(
                title: const Text(
                  'Reset to Defaults',
                  style: TextStyle(color: AppTheme.criticalRed),
                ),
                subtitle: const Text(
                  'Reset all settings to default values',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                leading: const Icon(Icons.restore, color: AppTheme.criticalRed),
                onTap: () {
                  _showResetDialog();
                },
              ),
            ),

            const SizedBox(height: 32),

            // Creator Credit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryRed.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/REDP!NG.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Created by:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alfredo Jr Romana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'REDP!NG Safety Ecosystem Developer',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRouter.main),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos),
        label: const Text('Back to SOS'),
      ),
    );
  }

  // (Removed) _buildComprehensiveTestCard — ACFD test UI disabled

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _crashDetectionEnabled = true;
      _fallDetectionEnabled = true;
      _voiceVerificationEnabled = true;
      _locationSharingEnabled = true;
      _hazardAlertsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _crashSensitivity = 1.0;
      _fallSensitivity = 0.85;
      _sosCountdown = 10;
    });

    _applyDetectionToggles();
    _applySensitivityToSensorService();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: AppTheme.safeGreen,
      ),
    );
  }
}

class _DevSecurityActions extends StatelessWidget {
  const _DevSecurityActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Run Protected Ping (HMAC + Integrity)'),
          subtitle: const Text(
            'Validates TLS pinning, HMAC+nonce, and platform integrity',
          ),
          onTap: () async {
            final total = Stopwatch()..start();
            const int maxAttempts = 3;
            bool ok = false;
            int attempt = 0;
            for (attempt = 1; attempt <= maxAttempts; attempt++) {
              final sw = Stopwatch()..start();
              ok = await GoogleCloudApiService().protectedPing();
              sw.stop();
              if (ok) {
                break;
              }
              // Backoff between attempts (0.5s, 1.0s)
              if (attempt < maxAttempts) {
                await Future.delayed(Duration(milliseconds: attempt * 500));
              }
            }
            total.stop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Protected ping: success in ${total.elapsedMilliseconds} ms (attempt $attempt/$maxAttempts)'
                      : 'Protected ping: failed after ${total.elapsedMilliseconds} ms ($maxAttempts attempts, see logs)',
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Verify Nonce TTL Cleanup'),
          subtitle: const Text(
            'Checks that expired nonces are being deleted by Firestore TTL',
          ),
          onTap: () async {
            final report = await NonceTtlVerifier.verify(
              expiredCutoff: DateTime.now().subtract(
                const Duration(minutes: 10),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'TTL: sample ${report.totalSample}, expired ${report.expiredStillPresent}, valid ${report.validPresent}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ===== Helpers: mapping & UI wiring =====

extension on _SettingsPageState {
  // Crash: 180–220 m/s²; sensitivity 1.0 => 180 (most sensitive allowed), 0.0 => 220 (least)
  double _mapCrashSensitivityToThreshold(double s) {
    final clamped = s.clamp(0.0, 1.0);
    return 180.0 + (1.0 - clamped) * 40.0;
  }

  // Fall: 140–200 m/s²; default ~150. sensitivity 1.0 => 140 (more sensitive), 0.0 => 200
  double _mapFallSensitivityToThreshold(double s) {
    final clamped = s.clamp(0.0, 1.0);
    return 140.0 + (1.0 - clamped) * 60.0;
  }

  // Removed: _formatSensitivityPercent (no longer displayed)

  void _applyDetectionToggles() {
    final sensor = _serviceManager.sensorService;
    sensor.crashDetectionEnabled = _crashDetectionEnabled;
    sensor.fallDetectionEnabled = _fallDetectionEnabled;
  }

  void _applySensitivityToSensorService() {
    final sensor = _serviceManager.sensorService;
    // Apply mapped thresholds with safety clamps
    sensor.crashThreshold = _mapCrashSensitivityToThreshold(_crashSensitivity);
    sensor.fallThreshold = _mapFallSensitivityToThreshold(_fallSensitivity);
  }
}

// Removed: _ThresholdHelper and _SliderWithDefaultMarker (Safety Detection UI removed)
