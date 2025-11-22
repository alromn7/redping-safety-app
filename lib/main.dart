import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:quick_actions/quick_actions.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/config/app_optimization_config.dart';
import 'services/app_service_manager.dart';
// import 'services/phone_ai_service.dart'; // AI emergency calls removed
import 'services/notification_scheduler.dart';
import 'test_firestore.dart';
import 'config/env.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/logging/safe_log.dart';
import 'widgets/phone_ai_debug_hud.dart';
import 'core/test_overrides.dart';
import 'services/auth_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      installSafeDebugPrint();

      // Initialize services (including Crashlytics) before starting app
      await _initializeAppInBackground();

      runApp(const RedPingApp());
    },
    (error, stack) {
      // Forward uncaught errors to Crashlytics (no-op if not initialized)
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    },
  );
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final app = Firebase.app();
    debugPrint(
      'Firebase initialized successfully (projectId: ${app.options.projectId})',
    );

    // Initialize Firebase App Check for security
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    debugPrint('Firebase App Check activated');

    // Ensure we are authenticated (anonymous is fine for rules that require auth)
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        final cred = await auth.signInAnonymously();
        debugPrint(
          'Firebase Auth: signed in anonymously (uid: ${cred.user?.uid})',
        );
      } else {
        debugPrint(
          'Firebase Auth: already signed in (uid: ${auth.currentUser?.uid})',
        );
      }
    } catch (e) {
      debugPrint('Anonymous auth failed: $e');
    }

    // Enable Crashlytics data collection (safe to call even if already enabled)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      AppOptimizationConfig.isProduction,
    );

    // Optional connectivity test, gated by feature flag to avoid rule errors
    if (Env.flag<bool>('doFirestoreConnectivityTest', false)) {
      await FirestoreTest.testConnection();
    }
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
  const RedPingApp({super.key});

  @override
  State<RedPingApp> createState() => _RedPingAppState();
}

class _RedPingAppState extends State<RedPingApp> with WidgetsBindingObserver {
  // final PhoneAIService _aiService = PhoneAIService(); // AI emergency calls removed
  final QuickActions _quickActions = QuickActions();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupGlobalCallbacks();
    _initializeAIServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _aiService.dispose(); // AI emergency calls removed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppServiceManager().handleAppLifecycleChange(state);
  }

  /// Initialize Quick Actions (Phone AI Services removed)
  Future<void> _initializeAIServices() async {
    if (TestOverrides.isTest) {
      return; // Skip QuickActions in tests to avoid platform channel errors
    }
    try {
      // Initialize Phone AI Service removed - AI emergency calls disabled
      // await _aiService.initialize();
      debugPrint('✅ Quick Actions initialized (Phone AI Service removed)');

      // Setup Quick Actions for Siri/Google Assistant
      _quickActions.initialize((shortcutType) {
        _handleQuickAction(shortcutType);
      });

      debugPrint('✅ Quick Actions initialized');
    } catch (e) {
      debugPrint('❌ AI Services initialization error: $e');
    }
  }

  /// Handle Quick Actions from Siri/Google Assistant
  void _handleQuickAction(String shortcutType) {
    if (TestOverrides.isTest) return;
    debugPrint('Quick Action triggered: $shortcutType');

    // Navigate based on quick action
    final router = AppRouter.router;
    switch (shortcutType) {
      case 'activate_sos':
        router.go('/sos');
        break;
      case 'send_help_request':
        router.go('/help');
        break;
      case 'call_emergency_contact':
        // Could open contacts or directly call
        router.go('/profile');
        break;
      case 'view_location':
        router.go('/location');
        break;
    }
  }

  void _setupGlobalCallbacks() {
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

    // Register global verification callback for crash/fall detection
    AppServiceManager().sensorService.setVerificationNeededCallback((event) {
      debugPrint('Global: Verification needed for ${event.type.name}');
      // Navigate to SOS page which will show the verification dialog
      AppRouter.router.go('/sos');
    });
  }

  void _setupVoiceCommands() {
    // Voice commands disabled - AI emergency calls removed
    /*
    final phoneAI = AppServiceManager().phoneAIIntegrationService;
    
    phoneAI.setOnVoiceCommand((command) {
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
          phoneAI.speak('System is active and monitoring for emergencies');
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
    debugPrint('🎤 Voice commands disabled (AI emergency calls removed)');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RedPing Safety',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.darkTheme,

      // Router configuration
      routerConfig: AppRouter.router,

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

        // Wrap with debug HUD in dev mode
        return PhoneAIDebugHUD(
          enabled: Env.flag<bool>('enablePhoneAIDebugHUD', false),
          child: scaledChild,
        );
      },
    );
  }
}
