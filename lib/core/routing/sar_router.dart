import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/email_link_signin_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/profile/presentation/pages/emergency_contacts_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/privacy/presentation/pages/privacy_settings_page.dart';
import '../../features/sos/presentation/pages/emergency_card_page.dart';
import '../../features/sar/presentation/pages/organization_dashboard_page.dart';
import '../../features/sar/presentation/pages/organization_registration_page.dart';
import '../../features/sar/presentation/pages/sar_history_page.dart';
import '../../features/sar/presentation/pages/sar_map_page.dart';
import '../../features/sar/presentation/pages/sar_page.dart';
import '../../features/sar/presentation/pages/sar_registration_page.dart';
import '../../features/sar/presentation/pages/sar_verification_page.dart';
import '../../services/auth_service.dart';
import '../../shared/presentation/pages/splash_page.dart';

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

/// Router configuration for the SAR-focused entrypoint.
///
/// Goal: keep the SAR app's navigation surface minimal and avoid depending on
/// SOS shell routes like `/main`.
class SarRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailLinkSignIn = '/auth/email-link';
  static const String sar = '/sar';
  static const String map = '/sar/map';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static final _auth = AuthService.instance;
  static final _refresh = _GoRouterRefreshStream(_auth.statusStream);

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    refreshListenable: _refresh,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == splash;
      final isAuthed = _auth.isAuthenticated;

      final isAuthRoute =
          state.matchedLocation == login || state.matchedLocation == signup;
      final isEmailLinkRoute = state.matchedLocation.startsWith(emailLinkSignIn);
      final isEmergencyCardRoute = state.matchedLocation.startsWith('/sos/');

      if (!isAuthed && !isSplash && !isAuthRoute && !isEmailLinkRoute && !isEmergencyCardRoute) {
        return login;
      }

      if (isAuthed && (isAuthRoute || isEmailLinkRoute)) {
        return sar;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: signup,
        builder: (context, state) => const SignupPage(),
      ),

      GoRoute(
        path: emailLinkSignIn,
        builder: (context, state) {
          final extra = state.extra;
          final link = extra is Map ? (extra['link'] as String?) : null;
          return EmailLinkSignInPage(emailLink: link);
        },
      ),

      // Public route for emergency card viewing.
      GoRoute(
        path: '/sos/:sessionId',
        name: 'emergency-card',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return EmergencyCardPage(sessionId: sessionId);
        },
      ),

      GoRoute(
        path: sar,
        builder: (context, state) => const SARPage(),
      ),

      GoRoute(
        path: map,
        builder: (context, state) => const SarMapPage(),
      ),

      // Profile (shared account functionality)
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'emergency-contacts',
            builder: (context, state) => const EmergencyContactsPage(),
          ),
        ],
      ),

      // Minimal Settings surface needed by Profile (privacy)
      GoRoute(
        path: '$settings/privacy',
        builder: (context, state) => const PrivacySettingsPage(),
      ),

      GoRoute(
        path: '/sar-registration',
        builder: (context, state) => const SARRegistrationPage(),
      ),

      GoRoute(
        path: '/sar-verification',
        builder: (context, state) => const SARVerificationPage(),
      ),

      GoRoute(
        path: '/organization-registration',
        builder: (context, state) => const OrganizationRegistrationPage(),
      ),

      GoRoute(
        path: '/organization-dashboard',
        builder: (context, state) => const OrganizationDashboardPage(),
      ),

      GoRoute(
        path: '/session-history',
        builder: (context, state) => const SARHistoryPage(),
      ),
    ],
  );
}
