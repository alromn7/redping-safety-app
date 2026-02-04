import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/onboarding_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/app/app_launch_config.dart';
import '../../../core/app_variant.dart';

/// Splash screen with RedPing branding and initialization
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await _textController.forward();

    // Simulate initialization time
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    // Check if user needs onboarding or go directly to main
    _navigateToNext();
  }

  void _navigateToNext() async {
    final auth = AuthService.instance;
    // Capture router to avoid using State.context across async gaps
    final router = GoRouter.of(context);
    await OnboardingPrefs.instance.ensureLoaded();

    if (!mounted) return;

    // Check if user can bypass login (3+ successful logins on same device, <7 days)
    final canBypass = await auth.shouldBypassLogin();

    if (!auth.isAuthenticated && !canBypass) {
      router.go(AppRouter.login);
      return;
    }

    // SAR entrypoint: skip SOS-focused onboarding and extra permission flows.
    if (AppLaunchConfig.variant == AppVariant.sar) {
      router.go(AppLaunchConfig.homeRoute);
      return;
    }

    // SOS entrypoint: skip startup onboarding entirely.
    if (AppLaunchConfig.skipStartupOnboarding) {
      router.go(AppLaunchConfig.homeRoute);
      return;
    }

    // If user is authenticated (either through session or bypass), proceed
    if (!OnboardingPrefs.instance.isCompleted) {
      router.go(AppRouter.onboarding);
      return;
    }
    router.go(AppLaunchConfig.homeRoute);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkBackground, AppTheme.darkSurface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'assets/images/REDP!NG.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Simple fallback without SOS elements
                          return Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppTheme.darkSurface,
                            ),
                            child: const Center(
                              child: Text(
                                'REDP!NG',
                                style: TextStyle(
                                  color: AppTheme.primaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // App Name Animation
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textAnimation.value)),
                      child: Column(
                        children: [
                          Text(
                            'REDP!NG',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Safety Companion',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Creator Credit
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value * 0.8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryRed.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/REDP!NG.png',
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Created by: Alfredo Jr Romana',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Loading Indicator
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryRed.withValues(alpha: 0.8),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing Safety Systems...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.disabledText),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
