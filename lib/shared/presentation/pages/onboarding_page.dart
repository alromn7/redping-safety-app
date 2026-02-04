import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/app/app_launch_config.dart';
import '../../../services/onboarding_prefs.dart';

/// Onboarding flow for new users
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: Icons.sos,
      title: 'Emergency SOS',
      description:
          'Instantly alert emergency contacts and services with our one-touch SOS system.',
      color: AppTheme.primaryRed,
    ),
    OnboardingStep(
      icon: Icons.sensors,
      title: 'Automatic Detection',
      description:
          'Advanced crash and fall detection using your device sensors for automatic alerts.',
      color: AppTheme.warningOrange,
    ),
    OnboardingStep(
      icon: Icons.location_on,
      title: 'Location Tracking',
      description:
          'Share your real-time location with emergency contacts and track your journey.',
      color: AppTheme.infoBlue,
    ),
    OnboardingStep(
      icon: Icons.people,
      title: 'Community Support',
      description:
          'Connect with nearby RedPing users and local emergency responders.',
      color: AppTheme.safeGreen,
    ),
    OnboardingStep(
      icon: Icons.security,
      title: 'Privacy First',
      description:
          'End-to-end encryption and privacy-focused design keep your data secure.',
      color: AppTheme.neutralGray,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    _persistAndExit();
  }

  void _skipOnboarding() {
    _persistAndExit();
  }

  Future<void> _persistAndExit() async {
    final router = GoRouter.of(context);
    await OnboardingPrefs.instance.setCompleted(true);
    if (!mounted) return;
    router.go(AppLaunchConfig.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingStep(_steps[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryRed
                        : AppTheme.neutralGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _steps.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.color.withValues(alpha: 0.2),
              border: Border.all(color: step.color, width: 2),
            ),
            child: Icon(step.icon, size: 60, color: step.color),
          ),
          const SizedBox(height: 48),
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
