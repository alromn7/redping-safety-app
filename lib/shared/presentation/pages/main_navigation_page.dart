import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_status_widget.dart';
import '../../../services/feature_access_service.dart';
// import '../../../services/auth_service.dart';
// import '../../../models/auth_user.dart';

/// Main navigation shell with bottom navigation bar
class MainNavigationPage extends StatefulWidget {
  final Widget child;

  const MainNavigationPage({super.key, required this.child});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.sos_outlined),
      selectedIcon: Icon(Icons.sos, color: AppTheme.primaryRed),
      label: 'SOS',
    ),
    const NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map, color: AppTheme.primaryRed),
      label: 'Map',
    ),
    const NavigationDestination(
      icon: Icon(Icons.manage_search_rounded),
      selectedIcon: Icon(Icons.manage_search, color: AppTheme.warningOrange),
      label: 'SAR',
    ),
    const NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people, color: AppTheme.primaryRed),
      label: 'Community',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person, color: AppTheme.primaryRed),
      label: 'Profile',
    ),
  ];

  final List<String> _routes = [
    AppRouter.main,
    AppRouter.map,
    AppRouter.sar,
    AppRouter.community,
    AppRouter.profile,
  ];

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      // Check Community access for Community tab (index 3 now)
      if (index == 3) {
        _handleCommunityTabClick();
        return;
      }

      setState(() {
        _selectedIndex = index;
      });
      context.go(_routes[index]);
    }
  }

  /// Handle Community tab click with access control
  void _handleCommunityTabClick() {
    // Essential users can access Community but with limited features
    // Pro+ users get full access (handled within the Community page)
    setState(() {
      _selectedIndex = 3;
    });
    context.go(_routes[3]);
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current route
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        if (_selectedIndex != i) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedIndex = i;
              });
            }
          });
        }
        break;
      }
    }

    // Prevent popping the last page (GoRouter underflow) and route to main when appropriate.
    final router = GoRouter.of(context);
    return PopScope(
      // Intercept back at the shell level to avoid dispatcher churn and underflow
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Re-evaluate route on back event to avoid stale path captures
        final currentPath = GoRouterState.of(context).uri.path;

        // Prefer normal pop when there is history
        if (router.canPop()) {
          router.pop();
          return;
        }

        // If at a nested route but no navigator history (e.g., shell), go to main
        if (!currentPath.startsWith(AppRouter.main)) {
          context.go(AppRouter.main);
          return;
        }

        // Already at main; swallow back to avoid app underflow/exit
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations,
          backgroundColor: AppTheme.darkSurface,
          indicatorColor: AppTheme.primaryRed.withValues(alpha: 0.2),
          elevation: 8,
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        drawer: _buildDrawer(context),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.darkSurface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 96,
            decoration: const BoxDecoration(gradient: AppTheme.sosGradient),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 0,
                  child: Image.asset(
                    'assets/images/RedPing logo.png',
                    height: 38,
                    width: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'REDP!NG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your Safety Companion',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // App Status Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AppStatusWidget(),
          ),

          const Divider(height: 1, color: AppTheme.neutralGray),

          // SAR Mode
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                color: AppTheme.warningOrange,
                size: 22,
              ),
            ),
            title: const Text(
              'SAR Mode',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: const Text(
              'Search & Rescue Operations',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.sar);
            },
          ),

          // Settings
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppTheme.infoBlue,
                size: 22,
              ),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.settings);
            },
          ),

          // Emergency Contacts
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.contact_emergency_outlined,
                color: AppTheme.primaryRed,
                size: 22,
              ),
            ),
            title: const Text(
              'Emergency Contacts',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('${AppRouter.profile}/emergency-contacts');
            },
          ),

          // Hazard Alerts
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningOrange,
                size: 22,
              ),
            ),
            title: const Text(
              'Hazard Alerts',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () async {
              Navigator.pop(context);
              // Gate access similar to SOS quick-access
              FeatureAccessService.instance.initialize();
              final allowed = await FeatureAccessService.instance
                  .checkFeatureAccessWithUpgrade(
                    context,
                    'hazardAlerts',
                    customMessage:
                        'Advanced hazard alerts and weather monitoring require Pro tier or higher. Upgrade to access comprehensive safety alerts and environmental monitoring.',
                  );
              if (allowed && context.mounted) {
                context.go(AppRouter.hazardAlerts);
              }
            },
          ),

          // Session History
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppTheme.successGreen,
                size: 22,
              ),
            ),
            title: const Text(
              'Session History',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.sessionHistory);
            },
          ),

          const Divider(height: 1, color: AppTheme.neutralGray),
          const SizedBox(height: 4),

          // Help & Support
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppTheme.primaryText,
                size: 22,
              ),
            ),
            title: const Text(
              'Help & Support',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog(context);
            },
          ),

          // About
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryText,
                size: 22,
              ),
            ),
            title: const Text(
              'About',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.secondaryText,
            ),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              color: AppTheme.primaryRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Help & Support', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency Features Section
              _buildSectionHeader(
                context,
                Icons.emergency,
                'Emergency Features',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                '🚨 SOS Button',
                'Press and hold for 3 seconds to trigger emergency',
              ),
              _buildHelpItem(
                '🚗 Crash Detection',
                'Automatic detection with AI verification',
              ),
              _buildHelpItem(
                '🤸 Fall Detection',
                'Monitors falls with voice confirmation',
              ),
              _buildHelpItem(
                '🎤 AI Verification',
                'Speak "Yes" or "Help" to confirm emergency',
              ),
              const SizedBox(height: 16),

              // Quick Actions Section
              _buildSectionHeader(context, Icons.flash_on, 'Quick Actions'),
              const SizedBox(height: 8),
              _buildHelpItem(
                '📍 Location Sharing',
                'Real-time GPS tracking during emergencies',
              ),
              _buildHelpItem(
                '👥 Emergency Contacts',
                'Instant alerts to your contacts',
              ),
              _buildHelpItem(
                '🚁 SAR Integration',
                'Professional rescue coordination',
              ),
              _buildHelpItem(
                '💬 Emergency Messaging',
                'Two-way communication with rescuers',
              ),
              const SizedBox(height: 16),

              // Settings & Configuration
              _buildSectionHeader(context, Icons.settings, 'Configuration'),
              const SizedBox(height: 8),
              _buildHelpItem(
                '🎯 Sensor Calibration',
                'Settings → Device → Sensor Calibration',
              ),
              _buildHelpItem(
                '🔋 Battery Optimization',
                'Settings → Device → Battery Optimization',
              ),
              _buildHelpItem('🔔 Notifications', 'Settings → Notifications'),
              _buildHelpItem(
                '🔒 Privacy Controls',
                'Settings → Privacy & Security',
              ),
              const SizedBox(height: 16),

              // Troubleshooting
              _buildSectionHeader(context, Icons.build, 'Troubleshooting'),
              const SizedBox(height: 8),
              _buildHelpItem(
                '❌ SOS Not Working',
                'Check internet & location permissions',
              ),
              _buildHelpItem(
                '📡 Location Issues',
                'Enable GPS & grant location access',
              ),
              _buildHelpItem(
                '🔇 No Notifications',
                'Check notification settings & DND mode',
              ),
              _buildHelpItem(
                '🔋 Battery Drain',
                'Enable battery exemption for app',
              ),
              const SizedBox(height: 20),

              // Emergency Services Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryRed.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.primaryRed,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Services',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'For life-threatening emergencies, always call local emergency services first:',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '🇺🇸 USA: 911 | 🇦🇺 Australia: 000\n🇬🇧 UK: 999 | 🇪🇺 EU: 112',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Support Contact
              _buildSectionHeader(context, Icons.support_agent, 'Get Support'),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📧 Email: alromn7@gmail.com',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    Text(
                      '📱 Response: 24-48 hours',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    Text(
                      '📚 Full Guide: Settings → Help',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Footer
              const Text(
                'REDP!NG Safety v1.0.2+3',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/images/REDP!NG.png', height: 32, width: 32),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('REDP!NG Safety', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REDP!NG Safety Ecosystem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.2+3',
                style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your comprehensive safety companion providing real-time emergency detection, '
                'instant SOS alerts, and seamless SAR integration. Built with cutting-edge '
                'AI technology to keep you and your loved ones safe.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),

              // Core Features
              _buildSectionHeader(context, Icons.stars, 'Core Features'),
              const SizedBox(height: 8),
              _buildFeatureItem('🚨 Emergency Response System'),
              _buildFeatureItem('🛡️ AI-Powered Safety Monitoring'),
              _buildFeatureItem('🚁 SAR Integration & Coordination'),
              _buildFeatureItem('👥 Community Safety Network'),
              _buildFeatureItem('💬 Real-time Communication'),
              _buildFeatureItem('📍 Advanced Location Services'),
              const SizedBox(height: 16),

              // Technology Stack
              _buildSectionHeader(context, Icons.code, 'Technology'),
              const SizedBox(height: 8),
              _buildFeatureItem('Flutter & Dart Framework'),
              _buildFeatureItem('Firebase Cloud Services'),
              _buildFeatureItem('Google AI (Gemini Pro)'),
              _buildFeatureItem('Advanced Sensor Integration'),
              const SizedBox(height: 16),

              // Platform Availability
              _buildSectionHeader(context, Icons.devices, 'Availability'),
              const SizedBox(height: 8),
              _buildFeatureItem('✅ Android (Available Now)'),
              _buildFeatureItem('📱 iOS (Q1 2026)'),
              _buildFeatureItem('🌐 Web (Q3 2026)'),
              const SizedBox(height: 16),

              // Statistics
              _buildSectionHeader(context, Icons.analytics, 'Statistics'),
              const SizedBox(height: 8),
              _buildFeatureItem('50+ Safety Features'),
              _buildFeatureItem('95%+ Detection Accuracy'),
              _buildFeatureItem('99.9% Service Uptime'),
              _buildFeatureItem('Real-time Emergency Response'),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 16),
              // Creator credit with logo
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
                          height: 32,
                          width: 32,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Created & Developed by:',
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Creator & Lead Developer',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact Information
              _buildSectionHeader(context, Icons.email, 'Contact'),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 26),
                child: Text(
                  'alromn7@gmail.com',
                  style: TextStyle(fontSize: 13, color: AppTheme.primaryRed),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '© 2025 REDP!NG Safety Ecosystem. All rights reserved.',
                style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'PCI DSS, GDPR & CCPA Compliant',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryRed,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}
