import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../config/env.dart';
import '../../features/sos/presentation/pages/sos_page.dart';
import '../../features/sos/presentation/pages/emergency_card_page.dart';
import '../../features/sos/presentation/pages/redping_help_status_page.dart';
import '../../features/safety/presentation/pages/safety_dashboard_page.dart';
// Safety Fund routes removed (feature canceled)
// Community chat removed - now available on RedPing website only
import '../../features/communication/presentation/pages/satellite_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/emergency_contacts_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/sensor_calibration_page.dart';
import '../../features/settings/presentation/pages/battery_optimization_page.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_service_manager.dart';
import '../../features/sar/presentation/pages/sar_page.dart';
import '../../features/sar/presentation/pages/sar_registration_page.dart';
import '../../features/sar/presentation/pages/sar_verification_page.dart';
import '../../features/sar/presentation/pages/sar_history_page.dart';
import '../../features/sar/presentation/pages/organization_registration_page.dart';
import '../../features/sar/presentation/pages/organization_dashboard_page.dart';
import '../../features/help/presentation/pages/help_assistant_page.dart';
import '../../features/activities/presentation/pages/activities_page.dart';
import '../../features/activities/presentation/pages/create_activity_page.dart';
import '../../features/activities/presentation/pages/start_activity_page.dart';
import '../../models/user_activity.dart';
import '../../features/privacy/presentation/pages/privacy_test_page.dart';
import '../../features/hazard/presentation/pages/hazard_alerts_page.dart';
// cross_messaging_test_widget removed - community chat removed
// import '../../features/sar/presentation/pages/sos_ping_dashboard_page.dart'; // Removed - using SARPage instead
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/email_link_signin_page.dart';
import '../../features/gadgets/presentation/pages/gadgets_management_page.dart';
import '../../shared/presentation/pages/main_navigation_page.dart';
import '../../shared/presentation/pages/onboarding_page.dart';
import '../../shared/presentation/pages/splash_page.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/connectivity_monitor_service.dart';
// sar_chat_screen import removed - community chat removed
import '../app/app_launch_config.dart';
import '../app_variant.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// Simple notifier to trigger router refreshes from a stream
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Onboarding preference helper
class OnboardingPreferenceHelper {
  bool _loaded = false;
  bool _completed = false;

  bool get isCompleted => _completed;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _completed = prefs.getBool('onboarding_completed') ?? false;
      _loaded = true;
    } catch (_) {
      _completed = false;
      _loaded = true;
    }
  }

  Future<void> setCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', value);
    } catch (_) {}
    _completed = value;
    _loaded = true;
  }
}

/// Application routing configuration using GoRouter
class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String sos = '/sos';
  static const String safety = '/safety';
  // community route removed - community chat now available on website only
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String satellite = '/satellite';
  static const String sar = '/sar';
  static const String sarRegistration = '/sar-registration';
  static const String sarVerification = '/sar-verification';
  static const String organizationRegistration = '/organization-registration';
  static const String organizationDashboard = '/organization-dashboard';
  static const String sosPingDashboard = '/sos-ping-dashboard';
  static const String redpingHelpStatus = '/redping-help-status';
  static const String helpAssistant = '/help-assistant';
  static const String activities = '/activities';
  static const String createActivity = '/activities/create';
  static const String startActivity = '/activities/start';
  static const String privacySettings = '/privacy-settings';
  static const String emergencyContacts = '/emergency-contacts';
  static const String hazardAlerts = '/hazard-alerts';
  static const String sessionHistory = '/session-history';
  static const String deviceSettings = '/device-settings';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailLinkSignIn = '/auth/email-link';
  static const String gadgets = '/gadgets';

  static final _auth = AuthService.instance;
  static final _refresh = _GoRouterRefreshStream(_auth.statusStream);

  static final GoRouter _router = GoRouter(
    initialLocation: splash,
    refreshListenable: _refresh,
    redirect: (context, state) {
      // Splash must be allowed to load and perform async initializations
      final isSplash = state.matchedLocation == splash;

      final isEmergencyVariant =
          AppLaunchConfig.variant == AppVariant.emergency;
      final isEmergencyCoreRoute =
          state.matchedLocation == main ||
          state.matchedLocation == sos ||
          state.matchedLocation == safety ||
          state.matchedLocation.startsWith(profile) ||
          state.matchedLocation.startsWith(settings) ||
          state.matchedLocation.startsWith(emergencyContacts);

      // Variant gating: SOS build should not expose SAR routes.
      if (AppLaunchConfig.variant == AppVariant.emergency &&
          state.matchedLocation.startsWith(sar)) {
        return AppLaunchConfig.homeRoute;
      }

      // Auth status
      final isAuthed = _auth.isAuthenticated;

      // If not authenticated, send to login except for public routes
      final isAuthRoute =
          state.matchedLocation == login || state.matchedLocation == signup;
      final isEmergencyCardRoute = state.matchedLocation.startsWith('/sos/');
      final isEmailLinkRoute = state.matchedLocation.startsWith(
        emailLinkSignIn,
      );

      // SOS app is allowed to be used without login only when offline.
      // ConnectivityMonitorService is primed in SplashPage.
      final effectivelyOffline =
          ConnectivityMonitorService().isEffectivelyOffline;

      if (!isAuthed &&
          !isSplash &&
          !isAuthRoute &&
          !isEmergencyCardRoute &&
          !isEmailLinkRoute) {
        // Integration/dev testing: allow SOS to run without auth gating.
        if (!kReleaseMode &&
            isEmergencyVariant &&
            isEmergencyCoreRoute &&
            AppConstants.testingModeEnabled) {
          return null;
        }
        // Emergency/SOS app must remain usable offline.
        if (isEmergencyVariant && isEmergencyCoreRoute && effectivelyOffline) {
          return null;
        }
        return login;
      }

      // If authenticated, prevent returning to login/signup
      if (isAuthed && (isAuthRoute || isEmailLinkRoute)) {
        return AppLaunchConfig.homeRoute;
      }

      return null;
    },
    routes: [
      // Deep Link: Emergency Card (redping://sos/{sessionId})
      GoRoute(
        path: '/sos/:sessionId',
        name: 'emergency-card',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          // Show emergency card page - user can tap to view full app
          return EmergencyCardPage(sessionId: sessionId);
        },
      ),

      // SAR Chat route removed - community chat now available on website only
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding Flow
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Main Navigation Shell
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationPage(child: child);
        },
        routes: [
          // SOS Page
          GoRoute(
            path: main,
            name: 'main',
            builder: (context, state) => const SOSPage(),
          ),

          // Safety Dashboard
          GoRoute(
            path: safety,
            name: 'safety',
            builder: (context, state) => const SafetyDashboardPage(),
          ),

          // Safety Fund routes removed

          // Community route removed - community chat now available on website only

          // Profile Page
          GoRoute(
            path: profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              // Emergency Contacts Sub-page
              GoRoute(
                path: 'emergency-contacts',
                name: 'emergency-contacts',
                builder: (context, state) => const EmergencyContactsPage(),
              ),
            ],
          ),

          // Settings Page
          GoRoute(
            path: settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              // Device Settings Sub-page
              GoRoute(
                path: 'device',
                name: 'device-settings',
                builder: (context, state) => const DeviceSettingsPage(),
                routes: [
                  GoRoute(
                    path: 'sensor-calibration',
                    name: 'sensor-calibration',
                    builder: (context, state) => const SensorCalibrationPage(),
                  ),
                  GoRoute(
                    path: 'battery-optimization',
                    name: 'battery-optimization',
                    builder: (context, state) =>
                        const BatteryOptimizationPage(),
                  ),
                ],
              ),

              // Privacy Settings Sub-page
              GoRoute(
                path: 'privacy',
                name: 'settings-privacy',
                builder: (context, state) => const PrivacySettingsPage(),
              ),

              // Privacy Test Sub-page (temporary)
              GoRoute(
                path: 'privacy-test',
                name: 'privacy-test',
                builder: (context, state) => const PrivacyTestPage(),
              ),

              // Cross Messaging Test removed - community chat removed

              // Gadgets Management Sub-page
              GoRoute(
                path: 'gadgets',
                name: 'gadgets',
                builder: (context, state) => const GadgetsManagementPage(),
              ),
            ],
          ),

          // SAR (Search and Rescue) Page
          GoRoute(
            path: sar,
            name: 'sar',
            builder: (context, state) => const SARPage(),
          ),

          // SAR Registration
          GoRoute(
            path: sarRegistration,
            name: 'sar-registration',
            builder: (context, state) => const SARRegistrationPage(),
          ),

          // SAR Verification
          GoRoute(
            path: sarVerification,
            name: 'sar-verification',
            builder: (context, state) => const SARVerificationPage(),
          ),

          // Organization Registration
          GoRoute(
            path: organizationRegistration,
            name: 'organization-registration',
            builder: (context, state) => const OrganizationRegistrationPage(),
          ),

          // Organization Dashboard
          GoRoute(
            path: organizationDashboard,
            name: 'organization-dashboard',
            builder: (context, state) => const OrganizationDashboardPage(),
          ),

          // SOS Ping Dashboard (now using SARPage with professional dashboard)
          GoRoute(
            path: sosPingDashboard,
            name: 'sos-ping-dashboard',
            builder: (context, state) => const SARPage(),
          ),
          // REDP!NG Help Status (SOS civilian tracking)
          GoRoute(
            path: redpingHelpStatus,
            name: 'redping-help-status',
            builder: (context, state) => RedpingHelpStatusPage(
              pingId: state.uri.queryParameters['pingId'],
            ),
          ),
          GoRoute(
            path: helpAssistant,
            name: 'help-assistant',
            builder: (context, state) => const HelpAssistantPage(),
          ),

          // Activities
          GoRoute(
            path: activities,
            name: 'activities',
            builder: (context, state) => const ActivitiesPage(),
          ),
          GoRoute(
            path: createActivity,
            name: 'create-activity',
            builder: (context, state) => const CreateActivityPage(),
          ),
          GoRoute(
            path: startActivity,
            name: 'start-activity',
            builder: (context, state) {
              final type = state.uri.queryParameters['type'];
              final templateId = state.uri.queryParameters['template'];
              final activityId = state.uri.queryParameters['activityId'];

              ActivityType? activityType;
              if (type != null) {
                try {
                  activityType = ActivityType.values.firstWhere(
                    (t) => t.name == type,
                  );
                } catch (e) {
                  // Invalid type, will be null
                }
              }

              return StartActivityPage(
                activityType: activityType,
                templateId: templateId,
                activityId: activityId,
              );
            },
          ),

          // Removed duplicate privacy settings route - available under /settings/privacy
        ],
      ),

      // Authentication Pages
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),

      // Email Link Sign-In (passwordless)
      GoRoute(
        path: emailLinkSignIn,
        name: 'email-link-signin',
        builder: (context, state) {
          final extra = state.extra as Map<dynamic, dynamic>?;
          final link = extra != null ? (extra['link'] as String?) : null;
          return EmailLinkSignInPage(emailLink: link);
        },
      ),

      // Full-screen SOS Session (when active)
      GoRoute(
        path: sos,
        name: 'sos-session',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          return SOSSessionPage(sessionId: sessionId);
        },
      ),

      // Hazard Alerts
      GoRoute(
        path: hazardAlerts,
        name: 'hazard-alerts',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return HazardAlertsPage(initialCategory: category);
        },
      ),

      // Satellite Communication Page
      GoRoute(
        path: satellite,
        name: 'satellite',
        builder: (context, state) => const SatellitePage(),
      ),

      // Session History
      GoRoute(
        path: sessionHistory,
        name: 'session-history',
        builder: (context, state) => const SARHistoryPage(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(main),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    // Note: redirect is defined above; no duplicate redirect here.
  );

  static GoRouter get router => _router;
}

// Placeholder pages - these will be implemented in their respective feature modules
class SOSSessionPage extends StatelessWidget {
  final String? sessionId;

  const SOSSessionPage({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'SOS ACTIVE',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sessionId != null) ...[
              const SizedBox(height: 10),
              Text(
                'Session: $sessionId',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.main),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
              ),
              child: const Text('Cancel SOS'),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({super.key});

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  final AppServiceManager _serviceManager = AppServiceManager();

  bool _isCalibrating = false;
  Map<String, dynamic> _sensor = const {};
  int _batteryLevel = 100;
  String _batteryStateText = 'unknown';

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    _loadSensor();
    await _serviceManager.batteryOptimizationService.initialize();
    _loadBattery();
  }

  void _loadSensor() {
    setState(() {
      _sensor = _serviceManager.sensorService.getSensorStatus();
    });
  }

  void _loadBattery() {
    final svc = _serviceManager.batteryOptimizationService;
    setState(() {
      _batteryLevel = svc.currentBatteryLevel;
      _batteryStateText = svc.currentBatteryState.toString().split('.').last;
    });
  }

  Future<void> _calibrateNow() async {
    if (_isCalibrating) return;
    setState(() => _isCalibrating = true);
    try {
      await _serviceManager.sensorService.calibrateSensors();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sensor calibration completed'),
          backgroundColor: AppTheme.safeGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calibration failed: $e'),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    } finally {
      _loadSensor();
      if (mounted) setState(() => _isCalibrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCalibrated = _sensor['isCalibrated'] == true;
    final conversionActive = _sensor['realWorldConversionActive'] == true;
    final calibratedGravity = (_sensor['calibratedGravity'] ?? 9.8) as double;
    final scaling = (_sensor['accelerationScalingFactor'] ?? 1.0) as double;
    final noise = (_sensor['sensorNoiseFactor'] ?? 1.0) as double;
    final crashThreshold = (_sensor['crashThreshold'] ?? 180.0) as double;
    final fallThreshold = (_sensor['fallThreshold'] ?? 150.0) as double;

    final sensorInterval = _serviceManager.batteryOptimizationService
        .getRecommendedSensorInterval();
    final locInterval = _serviceManager.batteryOptimizationService
        .getRecommendedLocationInterval();
    final backgroundInterval = _serviceManager.batteryOptimizationService
        .getRecommendedBackgroundProcessingInterval();

    return Scaffold(
      appBar: AppBar(title: const Text('Device Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sensor Calibration Card (summary + action)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sensors, color: AppTheme.infoBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Sensor Calibration',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(isCalibrated ? 'Calibrated' : 'Pending'),
                        backgroundColor: (isCalibrated
                            ? AppTheme.safeGreen.withOpacity(0.15)
                            : AppTheme.warningOrange.withOpacity(0.15)),
                        labelStyle: TextStyle(
                          color: isCalibrated
                              ? AppTheme.safeGreen
                              : AppTheme.warningOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _kv(
                    'Real-World Conversion',
                    conversionActive ? 'Active' : 'Fallback',
                  ),
                  _kv(
                    'Calibrated Gravity',
                    '${calibratedGravity.toStringAsFixed(2)} m/s²',
                  ),
                  _kv('Scaling Factor', scaling.toStringAsFixed(2)),
                  _kv('Noise Factor', noise.toStringAsFixed(2)),
                  const Divider(height: 24),
                  _kv(
                    'Crash Threshold',
                    '${crashThreshold.toStringAsFixed(0)} m/s²',
                  ),
                  _kv(
                    'Fall Threshold',
                    '${fallThreshold.toStringAsFixed(0)} m/s²',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCalibrating ? null : _calibrateNow,
                          icon: _isCalibrating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.tune),
                          label: Text(
                            _isCalibrating ? 'Calibrating…' : 'Calibrate Now',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () =>
                            context.go('/settings/device/sensor-calibration'),
                        child: const Text('Open details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Battery Optimization Card (summary + action)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.battery_full, color: AppTheme.infoBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Battery Optimization',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '$_batteryLevel%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'State: $_batteryStateText',
                    style: const TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  _kv(
                    'Sensors interval',
                    '${sensorInterval.inMilliseconds} ms',
                  ),
                  _kv('Location interval', _fmt(locInterval)),
                  _kv('Background processing', _fmt(backgroundInterval)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(
                            '/settings/device/battery-optimization',
                          ),
                          icon: const Icon(Icons.settings),
                          label: const Text('Manage optimization'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _refreshAll,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          Text(v, style: const TextStyle(color: AppTheme.primaryText)),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes} min';
    if (d.inSeconds >= 1) return '${d.inSeconds} s';
    return '${d.inMilliseconds} ms';
  }
}

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: const Center(child: Text('Privacy & Security Settings')),
    );
  }
}
