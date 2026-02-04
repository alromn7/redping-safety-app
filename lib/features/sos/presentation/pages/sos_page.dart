// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:redping_14v/utils/activity_classifier.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/location_service.dart';
import '../../../../services/connectivity_monitor_service.dart';
import '../../../../services/sms_service.dart';
import '../../../../models/sos_session.dart' hide MessageType;
import '../../../../models/emergency_contact.dart';
import '../../../../models/redping_mode.dart';
import '../../../../models/hazard_alert.dart';
import '../../../../widgets/auth_status_widget.dart';
import '../widgets/user_identification_card.dart';
import '../widgets/rescue_response_widget.dart';
import '../widgets/sos_status_tracker.dart';
// import '../widgets/sos_messaging_widget.dart'; // Removed: messaging UI removed
import '../widgets/redping_logo_button.dart';
import '../widgets/sensor_data_display.dart';
import '../widgets/active_mode_dashboard.dart';
import '../widgets/emergency_hotline_card.dart';
// Removed old inline test widget in favor of a comprehensive test page
import 'redping_mode_selection_page.dart';
import '../../../../services/redping_mode_service.dart';
import '../../../gadgets/presentation/widgets/gadgets_management_card.dart';
import '../../../redping_mode/presentation/pages/family_mode_dashboard.dart';
import '../../../../config/env.dart';
import '../../../redping_mode/presentation/pages/group_activity_dashboard.dart';
import '../../../redping_mode/presentation/pages/extreme_activity_dashboard.dart';
import '../../../redping_mode/presentation/pages/travel_mode_dashboard.dart';
import '../../../redping_mode/presentation/pages/work_mode_dashboard.dart';
import '../../../../services/offline_sos_queue_service.dart';
import '../../../../services/emergency_contacts_service.dart';

/// Main SOS page with emergency button and safety features
class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> with TickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;
  late AnimationController _beaconController;
  late Animation<double> _beaconAnimation;
  late final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(
    AppConstants.sosCountdownSeconds,
  );

  // Service Manager
  final AppServiceManager _serviceManager = AppServiceManager();
  final RedPingModeService _modeService = RedPingModeService();

  // State
  SOSSession? _currentSession;
  bool _isSOSActive = false;
  bool _isCountdownActive = false;
  // Removed _isSOSActivated - button state now reflects actual SOS session state only
  int _countdownSeconds = AppConstants.sosCountdownSeconds;

  // REDP!NG Help state
  String _selectedHelpCategory = '';

  // Simple system status
  bool _allSystemsActive = true;
  Timer? _statusRefreshTimer;
  bool _hasShownReadinessWarning = false;
  bool _isDialogShowing = false;
  bool _callbacksRegistered = false;
  // Monitoring status
  bool _monitoringOn = false;
  String _monitoringMode = '—';
  String _monitoringSummary = '';
  // Dev-only flight simulation controls
  bool _devSimFlight = false;
  double _devSimSpeedKmh = 280.0;
  double _devSimAltitudeM = 9000.0;
  // Reactive updates for hazard alerts quick-access
  void _onHazardAlertsUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showEmergencyHotlineSheet() async {
    final countryCode = Localizations.localeOf(context).countryCode;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.neutralGray.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Emergency Hotline (Manual Dial)',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'This opens your phone dialer so you can call local emergency services yourself. SOS alerts will notify your personal contacts separately.',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  EmergencyHotlineCard(userCountryCode: countryCode),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _heartbeatController = AnimationController(
      duration: Duration(
        milliseconds: AppConstants.heartbeatAnimationDurationMs,
      ),
      vsync: this,
    );

    _heartbeatAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    // Beacon animation for SOS status indicator (pulsing effect)
    _beaconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _beaconAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _beaconController, curve: Curves.easeInOut),
    );

    _beaconController.repeat(reverse: true);

    _startHeartbeat();

    // Listen to RedPing Mode changes
    _modeService.addListener(_onModeChanged);

    // Listen to hazard alerts updates for reactive quick-access counts
    _serviceManager.hazardService.addAlertsUpdatedListener(
      _onHazardAlertsUpdated,
    );
  }

  /// Handle RedPing Mode changes
  void _onModeChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild to update status indicator
      });
    }
  }

  // Reset SOS back to normal state after a 5-second hold on the RedPing button
  Future<void> _onSOSReset() async {
    debugPrint('🔄 SOS Page: User initiated 5-second reset');
    debugPrint(
      '🔄 SOS Page: Current state - isSOSActive: $_isSOSActive, isCountdownActive: $_isCountdownActive',
    );

    // Resolve any active SOS session (marks as resolved, not cancelled)
    if (_isSOSActive || _isCountdownActive) {
      debugPrint(
        '🔄 SOS Page: Resolving active SOS session via 5-second reset',
      );

      try {
        // Await the resolution to ensure it completes
        await _serviceManager.sosService.resolveSession();

        debugPrint('🔄 SOS Page: ✅ SOS session resolved successfully');

        // Update local state after successful resolution
        setState(() {
          _isSOSActive = false;
          _isCountdownActive = false;
          _currentSession = null;
        });
      } catch (e) {
        debugPrint('🔄 SOS Page: ❌ Error resolving SOS session: $e');
        // Still update UI even if resolution fails
        setState(() {
          _isSOSActive = false;
          _isCountdownActive = false;
          _currentSession = null;
        });
      }
    } else {
      debugPrint('🔄 SOS Page: No active SOS session to resolve');
    }

    HapticFeedback.heavyImpact();

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ SOS Reset Complete\nSession marked as resolved in SAR dashboard',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    debugPrint(
      '🔄 SOS Page: Reset complete - final state isSOSActive: $_isSOSActive',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize services after widget dependencies are ready
    if (!_callbacksRegistered) {
      // Always (re)register page callbacks once; services are globally initialized elsewhere
      _initializeServices();
      _startStatusRefreshTimer();
      _callbacksRegistered = true;
    }

    // Refresh system status when returning from other pages (using post-frame callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshSystemStatus();
        _refreshMonitoringStatus();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatController.repeat(reverse: true);
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
      debugPrint('Dev Flight Override error: $e');
    }
  }

  void _openDevFlightSimulator() {
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
                      Icon(Icons.build_circle),
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

  void _startStatusRefreshTimer() {
    // Refresh system status every 30 seconds to reduce performance impact
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshSystemStatus();
      _refreshMonitoringStatus();
    });
  }

  /// Initialize services and set up callbacks
  Future<void> _initializeServices() async {
    try {
      // Services are already initialized by AppServiceManager in main()
      // Just set up page-specific callbacks
      _serviceManager.sosService.setSessionStartedCallback(
        _onSOSSessionStarted,
      );
      _serviceManager.sosService.setSessionUpdatedCallback(
        _onSOSSessionUpdated,
      );
      _serviceManager.sosService.setSessionEndedCallback(_onSOSSessionEnded);
      _serviceManager.sosService.setCountdownTickCallback(_onCountdownTick);

      // Set up settings change callback
      _serviceManager.setSettingsChangedCallback(_refreshSystemStatus);

      // Check if there's an existing active session and restore state
      final existingSession = _serviceManager.sosService.currentSession;
      if (existingSession != null) {
        debugPrint(
          '🔄 SOS Page: Restoring existing session - Status: ${existingSession.status}',
        );
        if (mounted) {
          setState(() {
            _currentSession = existingSession;
            // Restore SOS active state for all active-related statuses
            _isSOSActive =
                existingSession.status == SOSStatus.active ||
                existingSession.status == SOSStatus.acknowledged ||
                existingSession.status == SOSStatus.assigned ||
                existingSession.status == SOSStatus.enRoute ||
                existingSession.status == SOSStatus.onScene ||
                existingSession.status == SOSStatus.inProgress;
            _isCountdownActive = existingSession.status == SOSStatus.countdown;
          });
        }
      }

      // Update simple system status
      if (mounted) {
        setState(() {
          _allSystemsActive =
              _serviceManager.isInitialized &&
              _serviceManager.sensorService.crashDetectionEnabled &&
              _serviceManager.sensorService.fallDetectionEnabled &&
              _serviceManager.locationService.hasPermission;
        });
      }

      // Check emergency readiness (only show once per page session).
      // IMPORTANT: Service initialization happens in the background after UI start.
      // If we compute readiness too early, it will always look low and spam users.
      await _waitForReadinessInputs();
      if (!mounted) return;
      _checkAndMaybeShowReadinessWarning();

      debugPrint('SOS Page: Services connected successfully');

      // Proactively fetch a fresh location so emergency number uses GPS first
      // and the UI updates once coordinates are available.
      try {
        await _serviceManager.locationService.getCurrentLocation(
          highAccuracy: true,
          forceFresh: true,
        );
        if (mounted) setState(() {});
      } catch (_) {
        // Non-fatal: fallback paths (locale/default) will handle number selection
      }
    } catch (e) {
      debugPrint('SOS Page: Error connecting to services - $e');
      if (mounted) {
        setState(() {
          _allSystemsActive = false;
        });
      }
    }
  }

  Future<void> _waitForReadinessInputs() async {
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (mounted && DateTime.now().isBefore(deadline)) {
      // AppServiceManager marks itself initialized after essential services are ready.
      if (_serviceManager.isInitialized &&
          _serviceManager.profileService.isInitialized &&
          _serviceManager.contactsService.isInitialized) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _checkAndMaybeShowReadinessWarning() {
    final readinessScore = _serviceManager.getEmergencyReadinessScore();
    if (readinessScore < 0.7 && !_hasShownReadinessWarning && !_isDialogShowing) {
      _hasShownReadinessWarning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showReadinessWarning(readinessScore);
      });
    } else if (readinessScore >= 0.7) {
      _hasShownReadinessWarning = false;
      _isDialogShowing = false;
    }
  }

  /// Refresh system status (called when returning from settings)
  void _refreshSystemStatus() {
    if (!mounted) return;

    try {
      // Re-evaluate system status based on current service states
      // Use cached permission status to avoid calling location service
      final newSystemStatus =
          _serviceManager.isInitialized &&
          _serviceManager.sensorService.crashDetectionEnabled &&
          _serviceManager.sensorService.fallDetectionEnabled &&
          _serviceManager.locationService.hasPermission &&
          _serviceManager.notificationService.isEnabled;

      // Only update if status actually changed to avoid unnecessary rebuilds
      if (_allSystemsActive != newSystemStatus) {
        setState(() {
          _allSystemsActive = newSystemStatus;
        });

        debugPrint(
          'SOS Page: System status refreshed - Active: $newSystemStatus',
        );

        // Show feedback to user if status changed (using post-frame callback)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (newSystemStatus) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ All systems are now active'),
                backgroundColor: AppTheme.safeGreen,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Some systems need attention'),
                backgroundColor: AppTheme.warningOrange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('SOS Page: Error refreshing system status - $e');
    }
  }

  void _refreshMonitoringStatus() {
    try {
      final sensor = _serviceManager.sensorService;
      final newOn = sensor.isMonitoring;

      // Determine the display state based on motion/activity
      String newMode;
      if (!newOn) {
        newMode = 'Off';
      } else if (sensor.isUserLikelyStationary) {
        newMode = 'Stationary';
      } else if (sensor.isActivelyMoving) {
        if (sensor.lastKnownSpeed != null && sensor.lastKnownSpeed! > 5) {
          newMode = 'Driving ${sensor.lastKnownSpeed!.toStringAsFixed(0)} km/h';
        } else {
          newMode = 'Moving';
        }
      } else {
        newMode = 'Idle';
      }

      final newSummary = sensor.getCompactStatusSummary();

      if (_monitoringOn != newOn ||
          _monitoringMode != newMode ||
          _monitoringSummary != newSummary) {
        setState(() {
          _monitoringOn = newOn;
          _monitoringMode = newMode;
          _monitoringSummary = newSummary;
        });
      }
    } catch (_) {
      // Keep previous status on error
    }
  }

  /// Determine if detailed status should be shown (only for interesting contexts)
  bool _shouldShowDetailedStatus() {
    if (_monitoringSummary.isEmpty) return false;

    // Show if driving (speed detected)
    if (_monitoringMode.contains('Driving')) return true;

    // Show if in special context (Airplane or Boat)
    if (_monitoringSummary.contains('Airplane') ||
        _monitoringSummary.contains('Boat')) {
      return true;
    }

    // Show if actively moving (not just idle/stationary)
    if (_monitoringMode == 'Moving') return true;

    // Hide for normal idle/stationary states
    return false;
  }

  /// Update monitoring status based on GPS speed from sensor display
  void _onGPSSpeedUpdate(double? speedKmh) {
    _lastSpeedKmh = speedKmh;
    _updateMonitoringFromSensors();
  }

  void _onAltitudeUpdate(double? altitudeM) {
    _lastAltitudeM = altitudeM;
    _updateMonitoringFromSensors();
  }

  double? _lastSpeedKmh;
  double? _lastAltitudeM;

  void _updateMonitoringFromSensors() {
    final status = ActivityClassifier.classify(_lastSpeedKmh, _lastAltitudeM);
    if (_monitoringMode != status.mode ||
        _monitoringSummary != status.summary) {
      setState(() {
        _monitoringMode = status.mode;
        _monitoringSummary = status.summary;
        _monitoringOn = true;
      });
    }
  }

  @override
  void dispose() {
    _countdownNotifier.dispose();
    _heartbeatController.dispose();
    _beaconController.dispose();
    _statusRefreshTimer?.cancel();
    _modeService.removeListener(_onModeChanged);
    _serviceManager.hazardService.removeAlertsUpdatedListener(
      _onHazardAlertsUpdated,
    );
    // Don't dispose services here - they're managed by AppServiceManager
    super.dispose();
  }

  /// Build stylized RedPing title with location pin "!" marker
  Widget _buildStylizedTitle() {
    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
        children: [
          const TextSpan(text: 'RedP'),

          // Stylized "!" mark as location pin
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glow effect
                  Positioned(
                    left: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 24,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The "!" mark styled as a pin
                  SizedBox(
                    width: 12,
                    height: 20,
                    child: CustomPaint(painter: _PingLocationPainter()),
                  ),
                ],
              ),
            ),
          ),

          const TextSpan(text: 'ng Safety'),
        ],
      ),
    );
  }

  // SOS Service Callbacks
  void _onSOSSessionStarted(SOSSession session) {
    if (!mounted) return;

    // Stop heartbeat animation when SOS becomes active to prevent conflicts
    if (session.status == SOSStatus.active) {
      _heartbeatController.stop();
    }

    setState(() {
      _currentSession = session;
      _isCountdownActive = session.status == SOSStatus.countdown;
      // Keep SOS active for all active-related statuses
      _isSOSActive =
          session.status == SOSStatus.active ||
          session.status == SOSStatus.acknowledged ||
          session.status == SOSStatus.assigned ||
          session.status == SOSStatus.enRoute ||
          session.status == SOSStatus.onScene ||
          session.status == SOSStatus.inProgress;
      _countdownSeconds = AppConstants.sosCountdownSeconds;
    });
    _countdownNotifier.value = AppConstants.sosCountdownSeconds;

    // Show countdown dialog for crash detection
    if (session.status == SOSStatus.countdown && mounted) {
      debugPrint('SOSPage: 🎯 Countdown status - showing dialog');
      _showSOSCountdownDialog();
    } else if (session.status == SOSStatus.active && mounted) {
      debugPrint(
        'SOSPage: 🎯 Active status - closing countdown dialog and using inline UI',
      );
      // Close any countdown dialog and rely on inline SOS Active strip.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_isDialogShowing) {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            try {
              nav.pop();
            } catch (_) {}
          }
          _isDialogShowing = false;
        }
      });
    }
  }

  void _onSOSSessionUpdated(SOSSession session) {
    if (!mounted) return;
    // Capture previous state to detect transitions
    final wasCountdown = _isCountdownActive;
    final wasActive = _isSOSActive;

    debugPrint('🔄 SOS Page: Session updated - Status: ${session.status}');

    setState(() {
      _currentSession = session;
      // Keep SOS active for all active-related statuses (acknowledged, assigned, enRoute, onScene, inProgress)
      _isSOSActive =
          session.status == SOSStatus.active ||
          session.status == SOSStatus.acknowledged ||
          session.status == SOSStatus.assigned ||
          session.status == SOSStatus.enRoute ||
          session.status == SOSStatus.onScene ||
          session.status == SOSStatus.inProgress;
      _isCountdownActive = session.status == SOSStatus.countdown;

      debugPrint(
        '🔄 SOS Page: _isSOSActive = $_isSOSActive, _currentSession != null: ${_currentSession != null}',
      );
    });

    // If we transitioned to active, just ensure the countdown dialog is closed
    if (session.status == SOSStatus.active && (!wasActive || wasCountdown)) {
      // Stop heartbeat animation when SOS becomes active to prevent conflicts
      _heartbeatController.stop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_isDialogShowing) {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            try {
              nav.pop();
            } catch (_) {}
          }
          _isDialogShowing = false;
        }
      });
    }
  }

  void _onSOSSessionEnded(SOSSession session) {
    if (!mounted) return;

    // Restart heartbeat animation when SOS ends
    _startHeartbeat();

    setState(() {
      _currentSession = null;
      _isSOSActive = false;
      _isCountdownActive = false;
      _countdownSeconds = AppConstants.sosCountdownSeconds;
    });

    // Close any open dialogs safely after the current frame; avoid popping the last page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      // Pop any transient routes (dialogs/sheets) but keep the first page intact
      try {
        nav.popUntil((route) => route.isFirst);
      } catch (_) {
        // If popUntil fails for any reason, do nothing
      }
      _isDialogShowing = false;
    });
  }

  void _onCountdownTick(int remainingSeconds) {
    if (!mounted) return;
    debugPrint(
      'SOSPage: ⏱️ Countdown tick: $remainingSeconds seconds remaining',
    );
    setState(() {
      _countdownSeconds = remainingSeconds;
    });
    // Update dialog via notifier (dialog rebuilds without needing page setState)
    _countdownNotifier.value = remainingSeconds;
  }

  // Removed unused _onSOSPressed; manual SOS is handled by activation flow

  // _onSOSLongPress removed; SOS activation now handled by RedPing button long hold

  void _onSOSActivated() async {
    // Called after 10-second press - activate real SOS
    try {
      // Emergency SOS with phone map integration
      await _sendEmergencySOS();

      HapticFeedback.heavyImpact();

      // Show confirmation that SOS is now in activated state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ SOS ACTIVATED - Emergency ping sent! Hold 5s to reset',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // If offline, show a clear banner indicating queued delivery + SMS fallback
        try {
          final isOffline = ConnectivityMonitorService().isOffline;
          if (isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '📴 Offline Mode: SOS queued. SMS fallback available.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } catch (_) {
          // Best-effort banner; ignore any connectivity lookup issues
        }
      }
    } catch (e) {
      debugPrint('Error activating SOS: $e');
      _showErrorDialog('Failed to activate SOS: ${e.toString()}');
    }
  }

  /// Emergency SOS with full SAR system integration
  Future<void> _sendEmergencySOS() async {
    try {
      // 1. Get current location (offline-friendly)
      // Use service-based fetch which falls back to cached values and returns null on failure,
      // avoiding a hard 10s TimeoutException that blocks SOS activation in airplane mode.
      final locInfo = await _serviceManager.locationService.getCurrentLocation(
        highAccuracy: true,
        forceFresh: false,
      );

      // 2. Activate FULL SOS Service with SAR coordination
      // The 10-second button hold served as the countdown, so activate immediately
      await _serviceManager.sosService.activateSOSImmediately(
        type: SOSType.manual,
        userMessage: 'Emergency SOS - Full SAR coordination activated',
      );

      debugPrint(
        'REDP!NG Button: Full SOS service activated immediately with SAR coordination',
      );

      // 3. The SOS service automatically:
      //    - Creates SOS ping for SAR teams (_activateSOS in sos_service.dart line 199)
      //    - Sends alerts to emergency contacts
      //    - Starts location tracking
      //    - Enables two-way communication with SAR
      //    - Sends satellite emergency alert if available
      //    - Tracks rescue responses

      // 4. Send additional Firebase alert for redundancy (online-only)
      try {
        final offline = ConnectivityMonitorService().isOffline;
        if (!offline && locInfo != null) {
          final firebaseService = _serviceManager.firebaseService;
          final userId = firebaseService.currentUser?.uid ?? 'anonymous';
          final sosSession = SOSSession(
            id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            type: SOSType.manual,
            status: SOSStatus.active,
            startTime: DateTime.now(),
            location: LocationInfo(
              latitude: locInfo.latitude,
              longitude: locInfo.longitude,
              accuracy: locInfo.accuracy,
              timestamp: DateTime.now(),
            ),
            userMessage: 'Emergency SOS - Full SAR coordination activated',
          );
          // Send to Firebase for backup/logging (best-effort)
          await firebaseService.sendSosAlert(sosSession);
        }
      } catch (_) {}

      // Stay on SOS page so the inline "SOS Activated" banner/section and
      // activation dialog appear above the RedPing button, matching the
      // crash-detection UX. We intentionally avoid navigating away (e.g. to
      // the map) or showing a separate instructions dialog here so the user
      // sees the same in-page activation UI.
      if (!mounted) return;

      if (locInfo != null) {
        debugPrint(
          'Emergency SOS initiated (manual). Location: ${locInfo.latitude}, ${locInfo.longitude}',
        );
      } else {
        debugPrint('Emergency SOS initiated (manual). Location unavailable');
      }
    } catch (e) {
      debugPrint('Error sending emergency SOS: $e');
      rethrow;
    }
  }

  // Removed separate emergency instructions dialog for manual activation to
  // keep UX consistent with crash detection: inline banner and activation
  // dialog are presented on the SOS page.

  // _onSOSReset removed; reset flow handled within activation service / RedPing button UX

  // Removed _storeActivatedState and _loadActivatedState
  // Button state now reflects actual SOS session state only (no separate UI state)

  // Manual countdown and cancel helpers are not used in current flow; SOSService manages lifecycle

  /// Show SOS countdown dialog (crash detection auto-trigger)
  void _showSOSCountdownDialog() {
    debugPrint(
      'SOSPage: 🚨 SHOWING COUNTDOWN DIALOG - $_countdownSeconds seconds',
    );
    // LAB: Suppress countdown dialog during testing
    if (AppConstants.labSuppressAllSOSDialogs ||
        AppConstants.labSuppressCountdownDialog) {
      debugPrint('SOSPage: [LAB] Suppressing countdown dialog');
      return;
    }
    if (_isDialogShowing) {
      debugPrint(
        'SOSPage: Countdown dialog already showing; skipping duplicate',
      );
      return;
    }
    _isDialogShowing = true;
    // Schedule on next frame to avoid context/routing races
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            // Should not happen because barrierDismissible=false, but keep state safe
            if (didPop) _isDialogShowing = false;
          },
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return AlertDialog(
                backgroundColor: AppTheme.warningOrange,
                title: const Text(
                  '⚠️ CRASH DETECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.car_crash, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Are you okay?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: _countdownNotifier,
                      builder: (context, value, _) => Text(
                        'SOS will activate in $value seconds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<int>(
                      valueListenable: _countdownNotifier,
                      builder: (context, value, _) => Text(
                        '$value',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      _serviceManager.sosService.cancelSOS();
                      _isDialogShowing = false;
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.safeGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'I\'M OK - CANCEL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  // Legacy SOS Active dialog removed; using inline action strip instead.

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_isSOSActive || _isCountdownActive),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Keep SOS page pinned while countdown or active
        if (!didPop && (_isSOSActive || _isCountdownActive)) {
          // Pop was prevented, do nothing
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(child: _buildStylizedTitle()),
              if (_isSOSActive || _isCountdownActive) ...[
                const SizedBox(width: 8),
                // Ensure the status chip never overflows the app bar width
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isSOSActive
                          ? AppTheme.primaryRed
                          : AppTheme.warningOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isSOSActive ? 'SOS ACTIVE' : 'COUNTDOWN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: _isSOSActive || _isCountdownActive
              ? (_isSOSActive ? AppTheme.primaryRed : AppTheme.warningOrange)
                    .withValues(alpha: 0.1)
              : null,
          actions: [
            IconButton(
              tooltip: 'Emergency Hotline (Manual Dial)',
              icon: const Icon(Icons.local_phone, color: AppTheme.criticalRed),
              onPressed: _showEmergencyHotlineSheet,
            ),
            if (kDebugMode)
              IconButton(
                tooltip: 'Dev: Simulate Flight',
                icon: const Icon(Icons.flight_takeoff),
                onPressed: _openDevFlightSimulator,
              ),
            if (_isSOSActive || _isCountdownActive)
              IconButton(
                icon: const Icon(Icons.cancel, color: AppTheme.primaryRed),
                onPressed: () => _serviceManager.sosService.cancelSOS(),
                tooltip: 'Cancel SOS',
              ),
            // Removed: App bar test icon (moved to a dedicated test card below)
            const AuthStatusWidget(),
            GestureDetector(
              onLongPress: () async {
                try {
                  final ok = await _serviceManager.googleCloudApiService
                      .protectedPing();
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Protected ping: success (HMAC + Integrity OK)'
                            : 'Protected ping: failed (see logs)',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Protected ping error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.go(AppRouter.settings),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - AppConstants.defaultPadding * 2,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // SOS Active Banner (if active)
                        if (_isSOSActive || _isCountdownActive)
                          _buildSOSActiveBanner(),

                        if (kDebugMode) _buildRedPingModeDebugCard(),

                        // User Identification Card (if SOS is active)
                        if (_isSOSActive)
                          UserIdentificationCard(
                            userProfile:
                                _serviceManager.profileService.currentProfile,
                          ),

                        // SOS Status Tracker (if SOS is active)
                        if (_isSOSActive && _currentSession != null)
                          SOSStatusTracker(session: _currentSession!),

                        // SAR Coordination Status removed from homepage
                        // (Previously showed _buildSARCoordinationCard())

                        // Rescue team and emergency contact responses
                        if (_currentSession != null)
                          RescueResponseWidget(session: _currentSession!),

                        // Emergency messaging (removed per request)
                        // if (_currentSession != null && _isSOSActive)
                        //   _buildEmergencyMessagingCard(),

                        // Status indicators

                        // Simple system status
                        _buildSimpleSystemStatus(),

                        const SizedBox(height: 16),

                        // Compact SOS Active action strip above RedPing button
                        if (_isSOSActive) _buildSOSActiveActionStrip(),

                        // Main SOS button - flexible height
                        Flexible(
                          flex: 3,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 200),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isCountdownActive) ...[
                                    Text(
                                      'SOS in $_countdownSeconds',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryRed,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Release to cancel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.secondaryText,
                                          ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Dual Button System
                                  _buildDualButtonSystem(),

                                  const SizedBox(height: 24),

                                  // Quick Actions (Call, Medical, Message)
                                  _buildQuickActionsRow(),

                                  const SizedBox(height: 16),

                                  // RedPing Mode Card
                                  _buildRedPingModeCard(),

                                  const SizedBox(height: 16),

                                  // Active Mode Dashboard
                                  const ActiveModeDashboard(),

                                  if (!_isSOSActive && !_isCountdownActive)
                                    ...[],

                                  if (_isSOSActive) ...[
                                    const Icon(
                                      Icons.radio_button_checked,
                                      color: AppTheme.primaryRed,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'SOS ACTIVE',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppTheme.primaryRed,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SAR Quick Access removed from homepage

                        // Hazard Alerts Quick Access
                        _buildHazardAlertsQuickAccess(),

                        const SizedBox(height: 16),

                        // (Removed) Developer test cards for voice/WebRTC calls

                        // Removed duplicate Help section (HelpAssistantCard) to avoid redundancy with RedPing button

                        // Gadgets Management
                        const GadgetsManagementCard(),

                        const SizedBox(height: 16),

                        // Volunteer Rescue Quick Access removed from homepage
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSOSActiveBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSOSActive ? AppTheme.primaryRed : AppTheme.warningOrange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isSOSActive ? AppTheme.primaryRed : AppTheme.warningOrange)
                .withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing icon
          AnimatedBuilder(
            animation: _heartbeatAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartbeatAnimation.value,
                child: Icon(
                  _isSOSActive ? Icons.emergency : Icons.timer,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSOSActive ? 'SOS ACTIVE' : 'SOS COUNTDOWN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSOSActive
                      ? 'Your emergency contacts have been notified'
                      : 'SOS will activate in $_countdownSeconds seconds',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Cancel button
          if (_isCountdownActive || _isSOSActive)
            IconButton(
              onPressed: () => _serviceManager.sosService.cancelSOS(),
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              tooltip: 'Cancel SOS',
            ),
        ],
      ),
    );
  }

  Widget _buildRedPingModeDebugCard() {
    final activeMode = _modeService.activeMode;
    final sensorStatus = _serviceManager.sensorService.getSensorStatus();

    final crashThreshold = (sensorStatus['crashThreshold'] as num?)?.toDouble();
    final fallThreshold = (sensorStatus['fallThreshold'] as num?)?.toDouble();
    final isMonitoring = sensorStatus['isMonitoring'] == true;
    final isLowPower = _serviceManager.sensorService.isLowPowerMode;
    final hasOverrides = sensorStatus['hasRedPingModeOverrides'] == true;
    final samplingOverrideMs = sensorStatus['samplingPeriodOverrideMs'];
    final powerModeOverride = sensorStatus['powerModeOverride'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black.withValues(alpha: 0.06),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: const Text(
          'Dev: RedPing Mode / Sensors',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${activeMode?.name ?? 'No active mode'} • ${isMonitoring ? 'Monitoring' : 'Not monitoring'}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode id: ${activeMode?.id ?? '—'}'),
                Text('Overrides: ${hasOverrides ? 'ON' : 'OFF'}'),
                Text('Power: ${isLowPower ? 'LOW POWER' : 'ACTIVE'} (override: ${powerModeOverride ?? '—'})'),
                Text('Sampling override: ${samplingOverrideMs ?? '—'} ms'),
                Text(
                  'Crash threshold: ${crashThreshold?.toStringAsFixed(1) ?? '—'} m/s²',
                ),
                Text(
                  'Fall threshold: ${fallThreshold?.toStringAsFixed(1) ?? '—'} m/s²',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContacts() {
    context.go('${AppRouter.profile}/emergency-contacts');
  }

  /// Handle hazard alerts access with access control
  void _handleHazardAlertsAccess() {
    context.push(AppRouter.hazardAlerts);
  }

  void _showMedicalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood Type: O+'),
            Text('Allergies: None'),
            Text('Medications: None'),
            Text('Medical Conditions: None'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to medical info page
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showUserIdentificationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Identification'),
            backgroundColor: AppTheme.criticalRed,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareEmergencyDetails(),
                tooltip: 'Share Details',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: UserIdentificationCard(
              userProfile: _serviceManager.profileService.currentProfile,
            ),
          ),
        ),
      ),
    );
  }

  void _shareEmergencyDetails() {
    // TODO: Implement sharing emergency details
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency details sharing coming soon'),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReadinessWarning(double score) {
    final percentage = (score * 100).toInt();

    if (_isDialogShowing) {
      debugPrint('SOS Page: Readiness dialog already showing, skipping.');
      return;
    }
    _isDialogShowing = true;
    debugPrint('SOS Page: Showing readiness warning dialog - $percentage%');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _isDialogShowing = false;
            debugPrint(
              'SOS Page: Dialog dismissed by back button or tap outside',
            );
          }
        },
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.warningOrange),
              SizedBox(width: 8),
              Text('Setup Incomplete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your emergency readiness is $percentage%. For optimal safety, please complete:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (!_serviceManager.profileService
                  .isProfileReadyForEmergency()) ...[
                const Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppTheme.criticalRed),
                    SizedBox(width: 8),
                    Text('Complete your profile information'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_serviceManager.contactsService.enabledContacts.isEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.contacts, size: 16, color: AppTheme.criticalRed),
                    SizedBox(width: 8),
                    Text('Add emergency contacts'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (!_serviceManager.locationService.hasPermission) ...[
                const Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 16,
                      color: AppTheme.criticalRed,
                    ),
                    SizedBox(width: 8),
                    Text('Enable location permissions'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint(
                  'SOS Page: Later button pressed - dismissing dialog',
                );
                _isDialogShowing = false;
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint(
                  'SOS Page: Setup Now pressed - opening emergency contacts + medical profile',
                );
                _isDialogShowing = false;
                Navigator.of(context).pop();

                // Small delay to ensure dialog is dismissed before navigation.
                await Future.delayed(const Duration(milliseconds: 120));
                if (!mounted) return;

                // Guide user through the two most common missing readiness items.
                // 1) Emergency contacts
                // 2) Medical profile (medical card)
                final router = GoRouter.of(context);
                await router.push('/profile/emergency-contacts');
                if (!mounted) return;
                await router.push('/doctor/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Setup Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardAlertsQuickAccess() {
    // Pull live counts from HazardAlertService
    final hazardService = _serviceManager.hazardService;
    final bool hazardEnabled = hazardService.isEnabled;
    final int weatherCount = hazardService.weatherAlerts.length;
    final int communityCount = hazardService.communityReports.length;
    // Treat non-weather active alerts as "Emergency" for quick glance
    final int emergencyCount = hazardService.activeAlerts
        .where((a) => a.type != HazardType.weather)
        .length;

    String fmtStatus(
      int count, {
      String zero = 'None',
      String label = 'Active',
    }) {
      if (!hazardEnabled) return 'Off';
      return count > 0 ? '$count $label' : zero;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: AppTheme.criticalRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hazard Alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        'Weather & emergency alerts',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _handleHazardAlertsAccess(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.criticalRed,
                    side: const BorderSide(color: AppTheme.criticalRed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('View Alerts'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildHazardStatusIndicator(
                  'Weather',
                  Icons.cloud,
                  AppTheme.infoBlue,
                  fmtStatus(weatherCount, label: 'Active'),
                ),
                const SizedBox(width: 16),
                _buildHazardStatusIndicator(
                  'Community',
                  Icons.people,
                  AppTheme.warningOrange,
                  fmtStatus(communityCount, label: 'Reports'),
                ),
                const SizedBox(width: 16),
                _buildHazardStatusIndicator(
                  'Emergency',
                  Icons.emergency,
                  AppTheme.criticalRed,
                  fmtStatus(emergencyCount, label: 'Alerts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (Removed) Test emergency-call card and handler

  // (Removed) Test WebRTC Emergency Call card and handler

  Widget _buildHazardStatusIndicator(
    String label,
    IconData icon,
    Color color,
    String status,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleHazardStatusClick(label.toLowerCase()),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHazardAlerts(String category) {
    // Navigate to hazard alerts page with specific category
    context.push('/hazard-alerts?category=$category');
  }

  /// Handle hazard status click with access control
  void _handleHazardStatusClick(String category) {
    _navigateToHazardAlerts(category);
  }

  // Emergency messaging access handlers removed (UI removed per user request)
  // void _handleEmergencyMessagingAccess() { ... }
  // void _handleQuickMessageAccess(String message) { ... }

  /// Build SAR Coordination Card showing active connection to SAR teams

  Widget _buildSimpleSystemStatus() {
    final activeMode = _modeService.activeMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // System Status Indicator
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _allSystemsActive
                    ? AppTheme.safeGreen.withValues(alpha: 0.1)
                    : AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _allSystemsActive
                      ? AppTheme.safeGreen.withValues(alpha: 0.3)
                      : AppTheme.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _allSystemsActive ? Icons.check_circle : Icons.warning,
                    color: _allSystemsActive
                        ? AppTheme.safeGreen
                        : AppTheme.warningOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _allSystemsActive
                          ? 'All Systems Active'
                          : 'System Check Required',
                      style: TextStyle(
                        color: _allSystemsActive
                            ? AppTheme.safeGreen
                            : AppTheme.warningOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RedPing Mode Status Indicator
          if (activeMode != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: activeMode.themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: activeMode.themeColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activeMode.icon,
                      color: activeMode.themeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${activeMode.name} Active',
                        style: TextStyle(
                          color: activeMode.themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Emergency messaging card removed per user request (duplicate of action strip)
  // Widget _buildEmergencyMessagingCard() { ... }

  /// Compact inline action strip shown above the RedPing button when SOS is active
  Widget _buildSOSActiveActionStrip() {
    final emergencyNumber = _getEmergencyNumber();

    // Get status display for current session
    String statusText = 'Emergency Alert Sent';
    String statusDescription = 'SAR teams have been notified';
    Color statusColor = AppTheme.warningOrange;
    IconData statusIcon = Icons.radar;

    if (_currentSession != null) {
      // Check raw status from Firebase first (for SAR workflow status)
      final rawStatus = _currentSession!.metadata['rawStatus'] as String?;
      if (rawStatus != null) {
        switch (rawStatus.toLowerCase()) {
          case 'acknowledged':
            statusText = 'SAR Reviewing';
            statusDescription = 'Emergency acknowledged by SAR';
            statusColor = AppTheme.warningOrange;
            statusIcon = Icons.assignment_turned_in;
            break;
          case 'assigned':
          case 'responder_assigned':
            statusText = 'Team Assigned';
            statusDescription =
                _currentSession!.metadata['responderName'] != null
                ? 'SAR: ${_currentSession!.metadata['responderName']}'
                : 'Rescue team assigned';
            statusColor = AppTheme.infoBlue;
            statusIcon = Icons.support_agent;
            break;
          case 'en_route':
            statusText = 'Help En Route';
            statusDescription = 'Team is on the way';
            statusColor = AppTheme.infoBlue;
            statusIcon = Icons.directions_run;
            break;
          case 'on_scene':
            statusText = 'Help On Scene';
            statusDescription = 'Team has arrived at location';
            statusColor = AppTheme.safeGreen;
            statusIcon = Icons.local_hospital;
            break;
          default:
            break;
        }
      }
      // Check for responder assignment metadata
      else if (_currentSession!.metadata.containsKey('responderName') &&
          _currentSession!.metadata['responderName'] != null) {
        statusText = 'Responder Assigned';
        statusDescription =
            'SAR: ${_currentSession!.metadata['responderName']}';
        statusColor = AppTheme.infoBlue;
        statusIcon = Icons.support_agent;
      }
      // Check rescue team responses array
      else if (_currentSession!.rescueTeamResponses.isNotEmpty) {
        final latestResponse = _currentSession!.rescueTeamResponses.last;
        switch (latestResponse.status) {
          case ResponseStatus.acknowledged:
            statusText = 'SAR Team Responding';
            statusDescription = 'Team acknowledged emergency';
            statusColor = AppTheme.warningOrange;
            statusIcon = Icons.notifications_active;
            break;
          case ResponseStatus.enRoute:
            statusText = 'Help En Route';
            statusDescription = 'Team is on the way';
            statusColor = AppTheme.infoBlue;
            statusIcon = Icons.directions_run;
            break;
          case ResponseStatus.onScene:
            statusText = 'Responders On Scene';
            statusDescription = 'Team has arrived';
            statusColor = AppTheme.safeGreen;
            statusIcon = Icons.local_hospital;
            break;
          default:
            break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SOS ACTIVE Header Row
            Row(
              children: [
                // Pulsing red indicator
                AnimatedBuilder(
                  animation: _beaconAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withValues(
                              alpha: 0.8 * _beaconAnimation.value,
                            ),
                            blurRadius: 12 * _beaconAnimation.value,
                            spreadRadius: 4 * _beaconAnimation.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'SOS ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                // Emergency Active badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Emergency Active',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status Indicator Row
            Row(
              children: [
                AnimatedBuilder(
                  animation: _beaconAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.2 * _beaconAnimation.value,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(
                              alpha: 0.3 * _beaconAnimation.value,
                            ),
                            blurRadius: 8 * _beaconAnimation.value,
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 18),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Offline/Queued inline indicator
            Builder(builder: (context) {
              try {
                final offline = ConnectivityMonitorService().isOffline;
                final queued = OfflineSOSQueueService().queueCount;
                if (offline || queued > 0) {
                  final text = offline
                      ? (queued > 1
                          ? 'Offline mode: queued ($queued); SMS available'
                          : 'Offline mode: queued; SMS available')
                      : (queued > 1
                          ? 'Queued for delivery ($queued)'
                          : 'Queued for delivery');
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          offline ? Icons.wifi_off : Icons.outgoing_mail,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Optional quick action: open SMS composer
                        TextButton.icon(
                          onPressed: _currentSession == null
                              ? null
                              : () async {
                                  try {
                                    await EmergencyContactsService()
                                        .openSMSComposerForEnabledContacts(
                                      _currentSession!,
                                    );
                                  } catch (_) {}
                                },
                          icon: const Icon(
                            Icons.sms,
                            color: Colors.orange,
                            size: 18,
                          ),
                          label: const Text(
                            'SMS Now',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            backgroundColor:
                                Colors.orange.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } catch (_) {}
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            // Primary Action Buttons Row
            Row(
              children: [
                // Emergency Call Button
                Expanded(
                  child: _buildCompactActionButton(
                    icon: Icons.phone,
                    label: emergencyNumber,
                    color: const Color(0xFFFF4757),
                    onPressed: () => _showEmergencyCallOptions(emergencyNumber),
                    tooltip: 'Emergency Call Options',
                  ),
                ),
                const SizedBox(width: 8),
                // Chat Button
                Expanded(
                  child: _buildCompactActionButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Messaging',
                    color: AppTheme.neutralGray,
                    onPressed: _openSOSChat,
                    tooltip: 'Messaging not available in-app',
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Message Button
                Expanded(
                  child: _buildCompactActionButton(
                    icon: Icons.send_rounded,
                    label: 'Message',
                    color: AppTheme.neutralGray,
                    onPressed: _sendSOSMessage,
                    tooltip: 'Messaging not available in-app',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Secondary Action Buttons Row
            Row(
              children: [
                // Call Emergency Contacts
                Expanded(
                  child: _buildSecondaryActionButton(
                    icon: Icons.contact_phone,
                    label: 'Contacts',
                    onPressed: _showEmergencyContactCallOptions,
                    tooltip: 'Call Emergency Contacts',
                  ),
                ),
                const SizedBox(width: 8),
                // Share Location
                Expanded(
                  child: _buildSecondaryActionButton(
                    icon: Icons.location_on,
                    label: 'Location',
                    onPressed: _openIncidentInMaps,
                    onLongPress: _shareCurrentLocation,
                    tooltip: 'Open incident in Maps',
                  ),
                ),
                const SizedBox(width: 8),
                // Medical Info
                Expanded(
                  child: _buildSecondaryActionButton(
                    icon: Icons.medical_services,
                    label: 'Medical',
                    onPressed: _showMedicalInfo,
                    tooltip: 'Medical Information',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get emergency hotline number based on country
  String _getEmergencyNumber() {
    // Emergency numbers by country code
    const emergencyNumbers = {
      'AU': '000', // Australia
      'US': '911', // United States
      'GB': '999', // United Kingdom
      'NZ': '111', // New Zealand
      'AT': '112', // Austria
      'BE': '112', // Belgium
      'BG': '112', // Bulgaria
      'HR': '112', // Croatia
      'CY': '112', // Cyprus
      'CZ': '112', // Czech Republic
      'DK': '112', // Denmark
      'EE': '112', // Estonia
      'FI': '112', // Finland
      'FR': '112', // France
      'DE': '112', // Germany
      'GR': '112', // Greece
      'HU': '112', // Hungary
      'IE': '112', // Ireland
      'IT': '112', // Italy
      'LV': '112', // Latvia
      'LT': '112', // Lithuania
      'LU': '112', // Luxembourg
      'MT': '112', // Malta
      'NL': '112', // Netherlands
      'PL': '112', // Poland
      'PT': '112', // Portugal
      'RO': '112', // Romania
      'SK': '112', // Slovakia
      'SI': '112', // Slovenia
      'ES': '112', // Spain
      'SE': '112', // Sweden
      'IN': '112', // India
      'CN': '110', // China
      'JP': '110', // Japan
      'KR': '112', // South Korea
      'CA': '911', // Canada
      'MX': '911', // Mexico
      'BR': '190', // Brazil
      'ZA': '10111', // South Africa
      'SG': '999', // Singapore
      'MY': '999', // Malaysia
      'TH': '191', // Thailand
      'PH': '911', // Philippines
      'ID': '112', // Indonesia
      'AE': '999', // UAE
      'SA': '997', // Saudi Arabia
      'RU': '112', // Russia
      'TR': '112', // Turkey
      'NO': '112', // Norway
      'CH': '112', // Switzerland
    };

    // Prefer GPS if available (more accurate than locale)
    try {
      final position = _serviceManager.locationService.currentPosition;
      if (position != null) {
        final lat = position.latitude;
        final lng = position.longitude;

        // Australia rough bounds: lat -44 to -10, lng 113 to 154
        if (lat >= -44 && lat <= -10 && lng >= 113 && lng <= 154) {
          debugPrint('Emergency number detected from GPS: 000 (Australia)');
          return '000';
        }

        // New Zealand bounds: lat -47 to -34, lng 166 to 179
        if (lat >= -47 && lat <= -34 && lng >= 166 && lng <= 179) {
          debugPrint('Emergency number detected from GPS: 111 (New Zealand)');
          return '111';
        }

        // UK bounds: lat 49 to 61, lng -8 to 2
        if (lat >= 49 && lat <= 61 && lng >= -8 && lng <= 2) {
          debugPrint(
            'Emergency number detected from GPS: 999 (United Kingdom)',
          );
          return '999';
        }

        // USA bounds: lat 24 to 50, lng -125 to -66
        if (lat >= 24 && lat <= 50 && lng >= -125 && lng <= -66) {
          debugPrint('Emergency number detected from GPS: 911 (United States)');
          return '911';
        }

        // Canada bounds: lat 41 to 84, lng -141 to -52
        if (lat >= 41 && lat <= 84 && lng >= -141 && lng <= -52) {
          debugPrint('Emergency number detected from GPS: 911 (Canada)');
          return '911';
        }
      }
    } catch (e) {
      debugPrint('Error detecting country from GPS: $e');
    }

    // Preferred default when GPS is unavailable: Australia (user request)
    try {
      const String defaultCountryCode = 'AU';
      if (emergencyNumbers.containsKey(defaultCountryCode)) {
        debugPrint(
          'Emergency number using default country: ${emergencyNumbers[defaultCountryCode]} (Australia)',
        );
        return emergencyNumbers[defaultCountryCode]!; // '000'
      }
    } catch (_) {}

    // Fallback: device locale
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final countryCode = locale.countryCode?.toUpperCase();
      if (countryCode != null && emergencyNumbers.containsKey(countryCode)) {
        debugPrint(
          'Emergency number detected from locale: ${emergencyNumbers[countryCode]} ($countryCode)',
        );
        return emergencyNumbers[countryCode]!;
      }
    } catch (e) {
      debugPrint('Error detecting country from locale: $e');
    }

    // Default to 112 (EU/International emergency number)
    debugPrint('Emergency number defaulting to 000 (Australia default)');
    return '000';
  }

  // Build Quick Actions Row (Call, Medical, Message)
  Widget _buildQuickActionsRow() {
    final emergencyNumber = _getEmergencyNumber();

    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.phone,
            label: 'Call',
            subtitle: emergencyNumber,
            color: AppTheme.safeGreen,
            onTap: () => _makeEmergencyCall(emergencyNumber),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.local_hospital,
            label: 'Medical',
            subtitle: 'Info',
            color: AppTheme.warningOrange,
            onTap: _showMedicalInfo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.message,
            label: 'Message',
            subtitle: 'SAR',
            color: AppTheme.infoBlue,
            onTap: _showEmergencyContacts,
          ),
        ),
      ],
    );
  }

  // Build individual quick action button
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Make emergency call
  void _makeEmergencyCall(String number) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: AppTheme.safeGreen),
            const SizedBox(width: 12),
            Text('Call $number'),
          ],
        ),
        content: Text(
          'This will call the emergency services number $number.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchEmergencyCall(number);
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Launch emergency call
  Future<void> _launchEmergencyCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          _showErrorDialog(
            'Unable to make phone call. Please dial $number manually.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error making call: $e');
      }
    }
  }

  // RedPing Mode Card
  Widget _buildRedPingModeCard() {
    final hasActiveMode = _modeService.hasActiveMode;
    final activeMode = _modeService.activeMode;
    final activeSession = _modeService.activeSession;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasActiveMode && activeMode != null
                        ? activeMode.themeColor.withValues(alpha: 0.15)
                        : AppTheme.primaryRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasActiveMode && activeMode != null
                        ? activeMode.icon
                        : Icons.security,
                    color: hasActiveMode && activeMode != null
                        ? activeMode.themeColor
                        : AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActiveMode && activeMode != null
                            ? activeMode.name
                            : 'RedPing Mode',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasActiveMode && activeSession != null
                            ? 'Active for ${_formatModeDuration(activeSession.duration)}'
                            : 'Activate activity-based safety modes',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasActiveMode && activeMode != null
                              ? activeMode.themeColor
                              : AppTheme.secondaryText,
                          fontWeight: hasActiveMode
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RedPingModeSelectionPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    hasActiveMode ? Icons.settings : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(hasActiveMode ? 'Manage' : 'Select Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasActiveMode && activeMode != null
                        ? activeMode.themeColor
                        : AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            if (hasActiveMode && activeMode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildModeMetric(
                      'Crash',
                      '${activeMode.sensorConfig.crashThreshold.toInt()} m/s²',
                    ),
                    const SizedBox(width: 16),
                    _buildModeMetric(
                      'Fall',
                      '${activeMode.sensorConfig.fallThreshold.toInt()} m/s²',
                    ),
                    const SizedBox(width: 16),
                    _buildModeMetric(
                      'SOS',
                      '${activeMode.emergencyConfig.sosCountdown.inSeconds}s',
                    ),
                  ],
                ),
              ),
              // Family Mode Dashboard link
              if (activeMode.id == 'family_protection') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FamilyModeDashboard(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard, size: 16),
                    label: const Text('Family Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeMode.themeColor,
                      side: BorderSide(
                        color: activeMode.themeColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
              // Group Activity Dashboard link
              if (activeMode.id == 'group_activity') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupActivityDashboard(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.groups, size: 16),
                    label: const Text('Group Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeMode.themeColor,
                      side: BorderSide(
                        color: activeMode.themeColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
              // Extreme Activity Dashboard link (all extreme sports modes)
              if (activeMode.category == ModeCategory.extreme) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExtremeActivityDashboard(
                            activityType: activeMode.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fitness_center, size: 16),
                    label: const Text('Extreme Activity Manager'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeMode.themeColor,
                      side: BorderSide(
                        color: activeMode.themeColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
              // Travel Mode Dashboard link
              if (activeMode.id == 'travel') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TravelModeDashboard(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flight_takeoff, size: 16),
                    label: const Text('Travel Manager'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeMode.themeColor,
                      side: BorderSide(
                        color: activeMode.themeColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
              // Work Mode Dashboard link (all work modes)
              if (activeMode.category == ModeCategory.work) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkModeDashboard(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.work, size: 16),
                    label: const Text('Work Manager'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeMode.themeColor,
                      side: BorderSide(
                        color: activeMode.themeColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatModeDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Quick message button and send logic removed (UI removed per user request)
  // Widget _buildQuickMessageButton(String text, IconData icon, Color color) { ... }
  // Future<void> _sendQuickMessage(String message) async { ... }
  // void _showMessagingDialog() { ... } // Dialog also removed

  Widget _buildDualButtonSystem() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning, color: AppTheme.warningOrange, size: 14),
              SizedBox(width: 6),
              Text(
                'SOS: emergency use only',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // RedPing Button is now the primary control:
          // - Tap: open RedPing quick services
          // - Hold 5s: activate SOS
          const SizedBox(height: 8),

          // RedPing Logo Button (Round) with a small status chip below
          Center(
            child: Column(
              children: [
                RedPingLogoButton(
                  onPressed: _onREDPINGHelpPressed,
                  enableHeartbeat: !_isSOSActive && !_isCountdownActive,
                  size: 160.0,
                  // When SOS active: hold 5s to reset
                  // When SOS inactive: hold 5s to activate
                  onHoldToActivate: _isSOSActive
                      ? _onSOSReset
                      : _onSOSActivated,
                  holdSeconds: 5,
                  // Turn green when SOS session is actually active
                  isSosActivated: _isSOSActive,
                ),
                const SizedBox(height: 12),
                // Real-time sensor data with GPS speed callback
                SensorDataDisplay(
                  onSpeedUpdate: _onGPSSpeedUpdate,
                  onAltitudeUpdate: _onAltitudeUpdate,
                  forceGPS: true,
                ),
                if (kDebugMode && LocationService().debugOverrideEnabled) ...[
                  const SizedBox(height: 6),
                  _buildDevSimulationBanner(),
                ],
                const SizedBox(height: 10),
                // Monitoring status strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _monitoringOn ? Icons.sensors : Icons.sensors_off,
                      color: _monitoringOn
                          ? AppTheme.safeGreen
                          : AppTheme.secondaryText,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _monitoringOn
                          ? _monitoringMode // Just show "Idle", "Low power", or "Active" in green
                          : 'Monitoring: Off',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _monitoringOn
                            ? AppTheme
                                  .safeGreen // Green when on
                            : AppTheme.secondaryText, // Gray when off
                      ),
                    ),
                  ],
                ),
                // Only show detailed summary when interesting (Driving, Boat, Airplane)
                if (_shouldShowDetailedStatus()) ...[
                  const SizedBox(height: 6),
                  Text(
                    _monitoringSummary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const _SosDeliveryStatusStrip(),
                const SizedBox(height: 12),
                Text(
                  _isSOSActive
                      ? 'Tap to open RedPing quick services\nHold 5s to reset SOS'
                      : 'Tap to open RedPing quick services\nHold 5s to activate SOS',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevSimulationBanner() {
    final ls = LocationService();
    final speedKmh = (ls.debugOverrideSpeedMps ?? 0.0) * 3.6;
    final alt = ls.debugOverrideAltitudeM;
    final parts = <String>[];
    if (speedKmh > 0) parts.add('${speedKmh.toStringAsFixed(0)} km/h');
    if (alt != null) parts.add('${alt.toStringAsFixed(0)} m');
    final detail = parts.isEmpty ? '' : ' — ${parts.join(' • ')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight_takeoff, size: 14, color: AppTheme.infoBlue),
          const SizedBox(width: 6),
          Text(
            'Simulation ON$detail',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.infoBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _onREDPINGHelpPressed() async {
    // Quick-help: let user pick a non-SOS category and send immediately
    await _showRedpingQuickHelpSheet();
  }

  // Removed _showREDPINGCountdownDialog and references to _REDPINGCountdownDialog

  Future<void> _sendREDPINGPing() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Sending help request...'),
            backgroundColor: AppTheme.infoBlue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Ensure messaging integration service is initialized
      try {
        await _serviceManager.messagingIntegrationService.initialize();
      } catch (e) {
        debugPrint('MessagingIntegrationService initialize (continuing): $e');
      }

      if (_selectedHelpCategory.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please choose a quick service'),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
        return;
      }

      // Create REDP!NG help request using the messaging integration service with timeout
      final pingId = await _serviceManager.messagingIntegrationService
          .createREDPINGHelpRequest(
            helpCategory: _selectedHelpCategory,
            userMessage: 'REDP!NG Help request for $_selectedHelpCategory',
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Help request timeout - please try again');
            },
          );

      debugPrint(
        'REDP!NG: Help request sent for service: $_selectedHelpCategory (ID: $pingId)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Help request sent to SAR teams'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View SAR',
              textColor: Colors.white,
              onPressed: () {
                if (!mounted) return;
                context.go(AppRouter.sosPingDashboard);
              },
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _selectedHelpCategory = '';
        });
      }
    } catch (e, st) {
      debugPrint('Error sending REDP!NG ping: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send help request: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _selectedHelpCategory = '';
        });
      }
    }
  }

  // Quick picker for REDP!NG quick services, then send via messaging integration
  Future<void> _showRedpingQuickHelpSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      // Allow the sheet to take more height and become scrollable if needed
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              // Ensure content is above system insets/keyboard if shown
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.neutralGray.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quick Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _quickServiceButton(
                        label: 'Police',
                        icon: Icons.local_police,
                        color: AppTheme.criticalRed,
                        onTap: () => _quickSendHelp('police_emergency'),
                      ),
                      _quickServiceButton(
                        label: 'Ambulance',
                        icon: Icons.medical_services,
                        color: AppTheme.infoBlue,
                        onTap: () => _quickSendHelp('medical_emergency'),
                      ),
                      _quickServiceButton(
                        label: 'Fire',
                        icon: Icons.local_fire_department,
                        color: Colors.deepOrange,
                        onTap: () => _quickSendHelp('fire_emergency'),
                      ),
                      _quickServiceButton(
                        label: 'Hazard',
                        icon: Icons.warning_amber,
                        color: AppTheme.warningOrange,
                        onTap: () {
                          Navigator.of(context).pop();
                          _handleHazardAlertsAccess();
                        },
                      ),
                      _quickServiceButton(
                        label: 'Quick Call',
                        icon: Icons.call,
                        color: AppTheme.safeGreen,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showEmergencyContacts();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickServiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickSendHelp(String categoryId) async {
    Navigator.of(context).pop();
    _selectedHelpCategory = categoryId;
    await _sendREDPINGPing();
  }

  // ============================================================================
  // WEBRTC DISABLED - Using SMS logic only
  // ============================================================================
  // These methods are isolated for future re-enablement
  // To re-enable: Uncomment these methods and restore WebRTC button in action strip
  // ============================================================================

  /// Build active WebRTC call indicator (DISABLED)
  // Widget _buildActiveCallIndicator() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
  //           blurRadius: 8,
  //           spreadRadius: 0,
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 8,
  //           height: 8,
  //           decoration: const BoxDecoration(
  //             color: Colors.white,
  //             shape: BoxShape.circle,
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         const Icon(Icons.call, color: Colors.white, size: 18),
  //         const SizedBox(width: 6),
  //         const Text(
  //           'WebRTC Call Active',
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Build WebRTC call button (DISABLED)
  // Widget _buildWebRTCCallButton() {
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: _startSOSWebRTCCall,
  //       borderRadius: BorderRadius.circular(12),
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         decoration: BoxDecoration(
  //           gradient: const LinearGradient(
  //             colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: Colors.white.withValues(alpha: 0.2),
  //             width: 1,
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Icon(
  //               Icons.video_call_rounded,
  //               color: Colors.white,
  //               size: 20,
  //             ),
  //             const SizedBox(width: 8),
  //             const Text(
  //               'WebRTC Call',
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ============================================================================
  // END WEBRTC DISABLED SECTION
  // ============================================================================

  /// Build compact action button (primary)
  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build secondary action button (smaller, icon + text inline)
  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // WEBRTC CALL FUNCTION DISABLED
  // ============================================================================

  /// Start WebRTC call to emergency contacts or SAR team (DISABLED)
  /*
  Future<void> _startSOSWebRTCCall() async {
    try {
      final webrtcService =
          _serviceManager.phoneVoiceIntegrationService.webrtcService;

      if (!webrtcService.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WebRTC service not initialized'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if we have emergency contacts
      final contacts = _serviceManager.contactsService.contacts;
      final sortedContacts = List.from(contacts)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      if (sortedContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No emergency contacts configured. Add contacts in Profile > Emergency Contacts',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      final primaryContact = sortedContacts.first;
      final currentUserName =
          _serviceManager.authService.currentUser.displayName;
      final location = _serviceManager.locationService.currentPosition;

      final message =
          '''EMERGENCY SOS from $currentUserName

I need immediate assistance!

${location != null ? 'My location: ${location.latitude}, ${location.longitude}' : 'Location unavailable'}

This is an urgent emergency call. Please respond if you can hear me.''';

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          title: Text('Starting WebRTC Call...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to emergency contact...'),
            ],
          ),
        ),
      );

      // Start the call
      final channelName = await webrtcService.makeEmergencyCall(
        contactId: primaryContact.id,
        emergencyMessage: message,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // Wait a bit for dialog to close
      await Future.delayed(const Duration(milliseconds: 300));

      // Show success dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.video_call, color: AppTheme.primaryRed),
              const SizedBox(width: 12),
              const Text('Emergency Call Active'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📞 SOS Call to ${primaryContact.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Channel: $channelName',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 Emergency voice call established',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Speak clearly to communicate with your emergency contact.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                    await _serviceManager.phoneVoiceIntegrationService
                      .endWebRTCCall();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Call ended')));
                  }
                } catch (e) {
                  AppLogger.e('Failed to end call', tag: 'SOS', error: e);
                }
              },
              child: const Text(
                'End Call',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Keep Active'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.e('WebRTC call failed', tag: 'SOS', error: e);

      // Close any open dialogs
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start WebRTC call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  */
  // ============================================================================
  // END WEBRTC CALL FUNCTION DISABLED
  // ============================================================================

  /// Open chat with SAR team or emergency contacts
  Future<void> _openSOSChat() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging is not available in-app in this build.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Send quick message to SAR team or emergency contacts
  Future<void> _sendSOSMessage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging is not available in-app in this build.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Show custom message dialog
  Future<void> _showCustomMessageDialog() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging is not available in-app in this build.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ============================================================================
  // COMPREHENSIVE CALL & MESSAGING FUNCTIONALITY
  // ============================================================================

  /// Show emergency call options (911/000 + emergency contacts)
  Future<void> _showEmergencyCallOptions(String emergencyNumber) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: AppTheme.primaryRed,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Emergency Call Options',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                // Emergency Service Call
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: AppTheme.primaryRed,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Emergency Services ($emergencyNumber)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Call police, ambulance, or fire service',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _makeEmergencyCall(emergencyNumber);
                  },
                ),
                const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                // Emergency Contacts Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                // Emergency contacts list
                _buildEmergencyContactsList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build emergency contacts list for calling
  Widget _buildEmergencyContactsList() {
    final contacts = _serviceManager.contactsService.contacts;

    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No emergency contacts configured',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/profile/emergency-contacts');
                },
                child: const Text('Add Contacts'),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by priority
    final sortedContacts = List.from(contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Column(
      children: sortedContacts.take(5).map((contact) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.safeGreen,
              size: 20,
            ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            contact.phoneNumber,
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.phone, color: AppTheme.safeGreen),
            onPressed: () {
              Navigator.pop(context);
              _callEmergencyContact(contact);
            },
          ),
        );
      }).toList(),
    );
  }

  /// Call specific emergency contact
  Future<void> _callEmergencyContact(EmergencyContact contact) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contact.phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        AppLogger.i('Calling emergency contact: ${contact.name}', tag: 'SOS');

        // Log call attempt to session
        if (_currentSession != null) {
          await FirebaseFirestore.instance
              .collection('sos_sessions')
              .doc(_currentSession!.id)
              .collection('activity_log')
              .add({
                'type': 'emergency_contact_call',
                'contactName': contact.name,
                'contactPhone': contact.phoneNumber,
                'timestamp': FieldValue.serverTimestamp(),
              });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to call ${contact.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error calling emergency contact', tag: 'SOS', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show emergency contact call options
  Future<void> _showEmergencyContactCallOptions() async {
    final contacts = _serviceManager.contactsService.contacts;

    if (contacts.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Text('No Emergency Contacts'),
            ],
          ),
          content: const Text(
            'You haven\'t configured any emergency contacts yet. Add contacts in your profile to call them during emergencies.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/profile/emergency-contacts');
              },
              child: const Text('Add Contacts'),
            ),
          ],
        ),
      );
      return;
    }

    _showEmergencyCallOptions(_getEmergencyNumber());
  }

  /// Share current location via SMS
  Future<void> _shareCurrentLocation() async {
    try {
      // Prefer active SOS incident coordinates, else current location
      final sessionLoc = _currentSession?.location;
      var locInfo =
          sessionLoc ?? _serviceManager.locationService.currentLocationInfo;

      locInfo ??= await _serviceManager.locationService.getCurrentLocation();

      if (locInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not available. Please wait for GPS fix.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final lat = locInfo.latitude.toStringAsFixed(6);
      final lng = locInfo.longitude.toStringAsFixed(6);

      final googleMapsLink = 'https://maps.google.com/?q=$lat,$lng';

      // Show options for sharing location
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.infoBlue,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Share Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Location details
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Coordinates:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$lat, $lng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Share options
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sms, color: AppTheme.infoBlue),
                    ),
                    title: const Text(
                      'Send via SMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Send to emergency contacts',
                      style: TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _sendLocationViaSMS(googleMapsLink);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.map,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                    title: const Text(
                      'Open in Maps',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'View on Google Maps',
                      style: TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _serviceManager.nativeMapService.openLocation(
                        latitude: double.tryParse(lat) ?? 0,
                        longitude: double.tryParse(lng) ?? 0,
                        label: _currentSession != null
                            ? 'SOS Incident'
                            : 'My Location',
                      );
                    },
                  ),
                  // Start Navigation
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: AppTheme.safeGreen,
                      ),
                    ),
                    title: const Text(
                      'Start Navigation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Turn-by-turn to this point',
                      style: TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _serviceManager.nativeMapService.openNavigation(
                        latitude: double.tryParse(lat) ?? 0,
                        longitude: double.tryParse(lng) ?? 0,
                        label: _currentSession != null
                            ? 'SOS Incident'
                            : 'My Location',
                      );
                    },
                  ),
                  // Copy link
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link, color: Colors.white70),
                    ),
                    title: const Text(
                      'Copy Link',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Copy Google Maps URL to clipboard',
                      style: TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await Clipboard.setData(
                        ClipboardData(text: googleMapsLink),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.e('Error sharing location', tag: 'SOS', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open the incident/current location directly in native Maps
  Future<void> _openIncidentInMaps() async {
    try {
      // Prefer active session's initial/last known location for incident
      final sessionLoc = _currentSession?.location;
      var locInfo =
          sessionLoc ?? _serviceManager.locationService.currentLocationInfo;
      locInfo ??= await _serviceManager.locationService.getCurrentLocation();

      if (locInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not available. Please wait for GPS fix.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final label = _currentSession != null
          ? 'SOS Incident ${DateTime.now().toLocal().toString().substring(0, 16)}'
          : 'My Location';

      final launched = await _serviceManager.nativeMapService.openLocation(
        latitude: locInfo.latitude,
        longitude: locInfo.longitude,
        label: label,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Maps application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to open map', tag: 'SOS', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Send location via SMS to emergency contacts
  Future<void> _sendLocationViaSMS(String mapsLink) async {
    try {
      final contacts = _serviceManager.contactsService.contacts;

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts to send SMS'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Use SMS service to send to all contacts
      if (_currentSession != null) {
        final session = _currentSession!;
        final emergencyContacts = contacts
            .map(
              (c) => EmergencyContact(
                id: c.id,
                name: c.name,
                phoneNumber: c.phoneNumber,
                type: c.type,
                priority: c.priority,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList();

        await SMSService.instance.startSMSNotifications(
          session,
          emergencyContacts,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location sent to ${contacts.length} contacts'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error sending location SMS', tag: 'SOS', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // END COMPREHENSIVE CALL & MESSAGING FUNCTIONALITY
  // ============================================================================

  // Removed unused _getCategoryDisplayName method
}

class _SosDeliveryStatusStrip extends StatefulWidget {
  const _SosDeliveryStatusStrip();

  @override
  State<_SosDeliveryStatusStrip> createState() => _SosDeliveryStatusStripState();
}

class _SosDeliveryStatusStripState extends State<_SosDeliveryStatusStrip> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _refreshTimer;

  List<ConnectivityResult> _results = const [];
  bool _hasInternetAccess = true;
  bool _enableSms = false;
  int _enabledContacts = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await ConnectivityMonitorService().initialize();
    } catch (_) {}

    // Prime with a one-shot check (best-effort)
    try {
      _results = await Connectivity().checkConnectivity();
    } catch (_) {
      _results = const [];
    }

    // Subscribe to changes
    try {
      _sub = ConnectivityMonitorService().connectivityStream.listen((results) {
        if (!mounted) return;
        setState(() {
          _results = results;
        });
      });
    } catch (_) {}

    // Periodically pull cheap state (prefs + cached reachability flag)
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_refresh());
    });
    await _refresh();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enableSms = prefs.getBool('enable_sms_notifications') ?? false;
      final enabledContacts = EmergencyContactsService().enabledContacts.length;
      final hasInternetAccess = ConnectivityMonitorService().hasInternetAccess;

      if (!mounted) return;
      setState(() {
        _enableSms = enableSms;
        _enabledContacts = enabledContacts;
        _hasInternetAccess = hasInternetAccess;
      });
    } catch (_) {
      // best-effort only
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyBearer = _results.any((r) => r != ConnectivityResult.none);
    final hasMobile = _results.contains(ConnectivityResult.mobile);
    final hasWifi = _results.contains(ConnectivityResult.wifi);

    final smsAvailable = _enableSms && hasMobile;
    final internetShareAvailable = hasAnyBearer && _hasInternetAccess;
    final effectivelyOffline = !internetShareAvailable;

    Color chipBg(bool ok) => ok
        ? AppTheme.safeGreen.withValues(alpha: 0.18)
        : AppTheme.neutralGray.withValues(alpha: 0.12);
    Color chipFg(bool ok) => ok ? AppTheme.safeGreen : AppTheme.secondaryText;

    Widget chip({required IconData icon, required String label, required bool ok}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipBg(ok),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: (ok ? AppTheme.safeGreen : AppTheme.neutralGray)
                .withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: chipFg(ok)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: chipFg(ok),
              ),
            ),
          ],
        ),
      );
    }

    final modeText = hasWifi && !hasMobile
        ? 'Wi‑Fi only'
        : (hasMobile ? 'Mobile' : (hasAnyBearer ? 'Connected' : 'No network'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                effectivelyOffline ? Icons.cloud_off : Icons.cloud_done,
                size: 14,
                color: effectivelyOffline ? AppTheme.warningOrange : AppTheme.safeGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Delivery: $modeText • Contacts: $_enabledContacts',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              chip(icon: Icons.sms, label: 'SMS', ok: smsAvailable),
              chip(
                icon: Icons.share,
                label: 'Internet Share',
                ok: internetShareAvailable,
              ),
              chip(
                icon: Icons.cloud_upload,
                label: 'Offline Queue',
                ok: effectivelyOffline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the ping location marker "!"
class _PingLocationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryRed
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw pin-shaped "!"
    // Top teardrop/pin shape for the exclamation body
    final path = Path();
    path.moveTo(size.width / 2, 2); // Top point

    // Right curve
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.3,
      size.width / 2,
      size.height * 0.6,
    );

    // Left curve back to top
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.3,
      size.width / 2,
      2,
    );

    path.close();

    // Draw filled pin
    canvas.drawPath(path, paint);
    // Draw outline
    canvas.drawPath(path, strokePaint);

    // Bottom dot of "!"
    final dotRadius = size.width * 0.25;
    final dotCenter = Offset(size.width / 2, size.height * 0.85);

    canvas.drawCircle(dotCenter, dotRadius, paint);
    canvas.drawCircle(dotCenter, dotRadius, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Removed _REDPINGCountdownDialog and replaced with confirmation dialog
