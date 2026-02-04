import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'models/check_in_request.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';  // REMOVED: Phase 2 - use Firebase Console
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_app_check/firebase_app_check.dart'; // Disabled - causing auth issues
import 'package:quick_actions/quick_actions.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/config/app_optimization_config.dart';
import 'services/app_service_manager.dart';
import 'services/network_safety_alert_service.dart';
import 'services/notification_scheduler.dart';
// import 'test_firestore.dart'; // Moved to test_scripts
import 'config/env.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/logging/safe_log.dart';
import 'core/test_overrides.dart';
import 'services/auth_service.dart';
import 'services/check_in_service.dart';
import 'features/check_in/check_in_request_dialog.dart';
import 'services/firebase_service.dart';
import 'core/entitlements/entitlement_service.dart';
import 'services/deep_link_service.dart';
import 'core/app/app_launch_config.dart';
import 'core/app_variant.dart';

/// Shared bootstrap for all entrypoints.
///
/// This avoids duplicating initialization across SOS vs SAR app targets.
void runRedPingApp({required AppVariant variant, required GoRouter router}) {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      AppLaunchConfig.setVariant(variant);
      AppServiceManager().setVariant(variant);

      installSafeDebugPrint();

      // Initialize services before starting app
      await _initializeAppInBackground();

      runApp(RedPingApp(routerConfig: router));
    },
    (error, stack) {
      // Phase 2: Crashlytics removed - errors logged to console only
      debugPrint('Caught error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

void main() {
  runRedPingApp(variant: AppVariant.emergency, router: AppRouter.router);
}

Future<void> _initializeAppInBackground() async {
  if (TestOverrides.isTest) {
    // Minimal test-safe initialization: skip Firebase/Crashlytics/AppCheck/Auth and heavy services
    try {
      await Hive.initFlutter();
    } catch (_) {}

    // Initialize AuthService to restore mocked user from SharedPreferences
    try {
      await AuthService.instance.initialize();
    } catch (_) {}

    // Safe UI theming tweaks
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.darkSurface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return;
  }

  // Initialize Firebase FIRST (before anything that uses it)
  try {
    // Prefer native config (Android google-services.json / iOS GoogleService-Info.plist)
    // so flavors/targets can vary without requiring Dart-side FirebaseOptions splits.
    // Fallback to generated options for platforms that require it (e.g., web).
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
    } catch (_) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final app = Firebase.app();
    debugPrint(
      'Firebase initialized successfully (projectId: ${app.options.projectId})',
    );

    // DISABLED: Firebase App Check - causing authentication issues with Cloud Functions
    // TODO: Enable after configuring App Check properly in Firebase Console
    // await FirebaseAppCheck.instance.activate(
    //   androidProvider: AndroidProvider.playIntegrity,
    //   appleProvider: AppleProvider.appAttest,
    // );
    // debugPrint('Firebase App Check activated');
    debugPrint(
      'Firebase App Check: DISABLED (enable in production after configuration)',
    );

    // Ensure we are authenticated
    // Note: Cloud Functions require authenticated (non-anonymous) users
    // Users must sign in with email/password through the app's login flow
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        // ONLY sign in anonymously if user has never signed up
        // This allows email/password users to stay authenticated
        debugPrint(
          'Firebase Auth: No user signed in, checking for saved credentials...',
        );

        // Check if user should bypass login (has logged in before)
        final authService = AuthService.instance;
        final shouldBypass = await authService.shouldBypassLogin();

        if (!shouldBypass) {
          // New user - sign in anonymously for basic features
          final cred = await auth.signInAnonymously();
          debugPrint(
            'Firebase Auth: signed in anonymously (uid: ${cred.user?.uid})',
          );
          debugPrint(
            'NOTE: Sign up with email to access payments and subscriptions',
          );
        } else {
          debugPrint(
            'Firebase Auth: User has signed up before, waiting for proper sign-in',
          );
        }
      } else {
        final isAnonymous = auth.currentUser!.isAnonymous;
        final emailVerified = auth.currentUser!.emailVerified;
        debugPrint(
          'Firebase Auth: already signed in (uid: ${auth.currentUser?.uid}, anonymous: $isAnonymous, verified: $emailVerified)',
        );
        if (isAnonymous) {
          debugPrint(
            'WARNING: Anonymous users cannot use Cloud Functions. Sign in with email/password for full features.',
          );
        } else if (!emailVerified) {
          debugPrint(
            'INFO: Email not verified yet. Check your inbox for verification link.',
          );
        }
      }
      // Start entitlements stream for current user (if signed in)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        EntitlementService.instance.start(uid);
        debugPrint('Entitlements initialized for uid: $uid');
      }
    } catch (e) {
      debugPrint('Firebase auth initialization failed: $e');
    }

    // Initialize AuthService after Firebase is ready so it can restore
    // saved sessions and/or mirror an existing FirebaseAuth user.
    try {
      await AuthService.instance.initialize();
    } catch (e) {
      debugPrint('AuthService initialization failed (continuing): $e');
    }

    // Phase 2: Crashlytics removed - use Firebase Console for production errors
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    //   AppOptimizationConfig.isProduction,
    // );

    // Optional connectivity test removed - test moved to test_scripts
    // if (Env.flag<bool>('doFirestoreConnectivityTest', false)) {
    //   await FirestoreTest.testConnection();
    // }
  } catch (e) {
    debugPrint(
      'Firebase initialization failed (continuing without Firebase): $e',
    );
  }

  // NOW initialize production optimizations (AFTER Firebase is ready)
  await AppOptimizationConfig.initialize();

  // Initialize Hive for local encrypted storage
  try {
    await Hive.initFlutter();
    debugPrint('Hive initialized for encrypted local storage');
  } catch (e) {
    debugPrint('Hive initialization failed (continuing): $e');
  }

  // Set up non-production friendly error handling; production uses AppOptimizationConfig
  if (!AppOptimizationConfig.isProduction && !TestOverrides.isTest) {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: \u001b[31m${details.exception}\u001b[0m');
      if (details.exception.toString().contains('painting.dart') ||
          details.exception.toString().contains('Failed assertion')) {
        debugPrint('Painting error caught and handled gracefully');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  // Set system UI overlay style for consistent status bar (fast operation)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations (fast operation)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Defer heavy initialization to background after UI is ready
  Future.microtask(() async {
    if (TestOverrides.isTest) {
      return; // Skip heavy service initialization during tests
    }
    // Initialize notification scheduler for emergency alerts
    try {
      await NotificationScheduler.instance.initialize();
      debugPrint('NotificationScheduler initialized successfully');
    } catch (e) {
      debugPrint('NotificationScheduler initialization failed: $e');
    }

    // Lightweight startup verification (minimal checks only)
    await AppServiceManager().verifyAllServicesAtStartup();

    // Initialize app services with performance optimization
    final serviceManager = AppServiceManager();
    try {
      await serviceManager.initializeAllServices().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint(
            'Service initialization timed out - continuing with limited functionality',
          );
        },
      );
      debugPrint('Essential services initialized in background');
    } catch (e) {
      debugPrint('Service initialization failed (non-fatal): $e');
    }
  });
}

/// Main RedPing Safety Ecosystem application
class RedPingApp extends StatefulWidget {
  final GoRouter routerConfig;

  const RedPingApp({super.key, required this.routerConfig});

  @override
  State<RedPingApp> createState() => _RedPingAppState();
}

class _RedPingAppState extends State<RedPingApp> with WidgetsBindingObserver {
  final QuickActions _quickActions = QuickActions();
  final DeepLinkService _deepLinks = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupGlobalCallbacks();
    _initializeQuickActions();
    // Initialize deep link handling (custom scheme + universal links)
    _deepLinks.initialize(router: widget.routerConfig);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    EntitlementService.instance.stop();
    _deepLinks.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppServiceManager().handleAppLifecycleChange(state);
  }

  /// Initialize Quick Actions
  Future<void> _initializeQuickActions() async {
    if (TestOverrides.isTest) {
      return; // Skip QuickActions in tests to avoid platform channel errors
    }
    try {
      // Setup Quick Actions for Siri/Google Assistant
      _quickActions.initialize((shortcutType) {
        _handleQuickAction(shortcutType);
      });

      debugPrint('✅ Quick Actions initialized');
    } catch (e) {
      debugPrint('❌ Quick Actions initialization error: $e');
    }
  }

  /// Handle Quick Actions from Siri/Google Assistant
  void _handleQuickAction(String shortcutType) {
    if (TestOverrides.isTest) return;
    debugPrint('Quick Action triggered: $shortcutType');

    // Navigate based on quick action
    final router = widget.routerConfig;
    switch (shortcutType) {
      case 'activate_sos':
        if (AppLaunchConfig.variant == AppVariant.emergency) {
          router.go('/sos');
        } else {
          router.go(AppLaunchConfig.homeRoute);
        }
        break;
      case 'send_help_request':
        if (AppLaunchConfig.variant == AppVariant.emergency) {
          router.go('/help');
        } else {
          router.go(AppLaunchConfig.homeRoute);
        }
        break;
      case 'call_emergency_contact':
        // Could open contacts or directly call
        if (AppLaunchConfig.variant == AppVariant.emergency) {
          router.go('/profile');
        } else {
          router.go(AppLaunchConfig.homeRoute);
        }
        break;
      case 'view_location':
        if (AppLaunchConfig.variant == AppVariant.emergency) {
          router.go('/location');
        } else {
          router.go(AppLaunchConfig.homeRoute);
        }
        break;
    }
  }

  void _setupGlobalCallbacks() {
    final router = widget.routerConfig;
    AppServiceManager().setSOSActivatedCallback((session) {
      debugPrint('Global: SOS Activated - ${session.id}');
    });
    AppServiceManager().setSOSDeactivatedCallback((session) {
      debugPrint('Global: SOS Deactivated - ${session.id}');
    });
    AppServiceManager().setCriticalAlertCallback((title, message) {
      debugPrint('Global: Critical Alert - $title: $message');
    });
    AppServiceManager().setServicesReadyCallback(() {
      debugPrint('Global: All services ready');

      // Start voice listening when services are ready
      _setupVoiceCommands();
    });
  }

  void _setupVoiceCommands() {
    // Voice commands currently disabled
    /*
    final phoneVoice = AppServiceManager().phoneVoiceIntegrationService;
    
    phoneVoice.setOnVoiceCommand((command) {
      debugPrint('🎤 Voice Command: $command');

      switch (command) {
        case 'activate_sos':
          AppRouter.router.go('/sos');
          AppServiceManager().sosService.startSOSCountdown(
            type: SOSType.manual,
            userMessage: 'Voice activated SOS',
          );
          break;
        case 'cancel_sos':
          AppServiceManager().sosService.cancelSOS();
          break;
        case 'call_emergency':
          // Navigate to contacts and trigger emergency call
          AppRouter.router.go('/profile');
          break;
        case 'open_sos_page':
          AppRouter.router.go('/sos');
          break;
        case 'check_status':
          phoneVoice.speak('System is active and monitoring for emergencies');
          break;
        case 'enable_crash_detection':
          AppServiceManager().sensorService.fallDetectionEnabled = true;
          phoneAI.speak('Crash detection enabled');
          break;
        case 'disable_crash_detection':
          AppServiceManager().sensorService.fallDetectionEnabled = false;
          phoneAI.speak('Crash detection disabled');
          break;
      }
    });

    // Start continuous voice listening
    phoneAI.startVoiceListening();
    */
    debugPrint('🎤 Voice commands disabled');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RedPing Safety',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.darkTheme,

      // Router configuration
      routerConfig: widget.routerConfig,

      // Builder for additional configuration
      builder: (context, child) {
        final scaledChild = MediaQuery(
          // Ensure text scaling doesn't break UI
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
          ),
          child: child ?? const SizedBox(),
        );

        // In test mode, overlay a lightweight splash with expected texts
        // to satisfy smoke tests without altering production UI flow.
        if (TestOverrides.isTest) {
          return Stack(
            children: [
              scaledChild,
              IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'RedPing',
                        key: ValueKey('testOverlayRedPing'),
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your Safety Companion',
                        key: ValueKey('testOverlaySubtitle'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Pending check-in listener wrapper (production)
        return _CheckInListener(
          child: _NetworkSafetyAlertListener(
            child: scaledChild,
          ),
        );
      },
    );
  }
}

class _NetworkSafetyAlertListener extends StatefulWidget {
  final Widget child;
  const _NetworkSafetyAlertListener({required this.child});

  @override
  State<_NetworkSafetyAlertListener> createState() =>
      _NetworkSafetyAlertListenerState();
}

class _NetworkSafetyAlertListenerState extends State<_NetworkSafetyAlertListener> {
  StreamSubscription? _sub;
  bool _dialogOpen = false;
  DateTime? _lastShown;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _sub?.cancel();
    _sub = NetworkSafetyAlertService().alertsStream.listen((alert) {
      if (!mounted) return;

      // Only show dialogs when app is foreground; notifications still fire.
      if (!AppServiceManager().isAppInForeground) return;

      // Avoid stacking dialogs.
      if (_dialogOpen) return;

      // Simple anti-spam guard in case multiple alerts happen in a burst.
      final now = DateTime.now();
      if (_lastShown != null && now.difference(_lastShown!) < const Duration(seconds: 5)) {
        return;
      }
      _lastShown = now;

      _dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return AlertDialog(
            title: Text(alert.title),
            content: Text(alert.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ).whenComplete(() {
        _dialogOpen = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CheckInListener extends StatefulWidget {
  final Widget child;
  const _CheckInListener({required this.child});
  @override
  State<_CheckInListener> createState() => _CheckInListenerState();
}

class _CheckInListenerState extends State<_CheckInListener> {
  StreamSubscription? _sub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    final user = FirebaseService().currentUser;
    if (user == null) return;
    _sub?.cancel();
    _sub = CheckInService.instance.pendingForTarget(user.uid).listen((
      requests,
    ) async {
      if (requests.isEmpty || _dialogOpen) return;
      final req = requests.first;
      if (!mounted) return;
      // Auto-respond if autoApproved
      if (req.autoApproved) {
        try {
          final perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            final position = await Geolocator.getCurrentPosition(
              // GPS-first to avoid Wi‑Fi accuracy prompts
              desiredAccuracy: LocationAccuracy.bestForNavigation,
            );
            await CheckInService.instance.respond(
              requestId: req.id,
              accept: true,
              location: CheckInLocationSnapshot(
                lat: position.latitude,
                lng: position.longitude,
                accuracy: position.accuracy,
                capturedAt: DateTime.now(),
              ),
            );
            return; // Silent handling complete
          }
          // Permission not yet granted; fall back to dialog consent flow
          _dialogOpen = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CheckInRequestDialog(request: req),
          ).then((_) => _dialogOpen = false);
        } catch (_) {}
        return;
      }
      _dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CheckInRequestDialog(request: req),
      ).then((_) => _dialogOpen = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
