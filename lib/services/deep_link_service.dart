import 'dart:async';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../core/logging/app_logger.dart';
import '../core/app/app_launch_config.dart';
import '../core/app_variant.dart';

/// Service for handling deep links between RedPing apps
class DeepLinkService {
  static const String mainAppScheme = 'redping';
  static const String doctorAppScheme = 'redpingdoctor';

  StreamSubscription? _linkSubscription;
  GoRouter? _router;
  final _appLinks = AppLinks();

  /// Initialize deep link handling
  Future<void> initialize({GoRouter? router}) async {
    _router = router;

    // Handle initial link if app was closed
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
    } on PlatformException catch (e) {
      AppLogger.e(
        'Error getting initial deep link',
        tag: 'DeepLinkService',
        error: e,
      );
    } catch (e) {
      AppLogger.e(
        'Unexpected error getting initial deep link',
        tag: 'DeepLinkService',
        error: e,
      );
    }

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        AppLogger.e(
          'Deep link stream error',
          tag: 'DeepLinkService',
          error: err,
        );
      },
    );
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    AppLogger.i('Deep link received: $uri', tag: 'DeepLinkService');

    // Handle custom app scheme links (redping://)
    if (uri.scheme == mainAppScheme) {
      switch (uri.host) {
        case 'sos':
          final alertId = uri.queryParameters['alert'];
          final type = uri.queryParameters['type'];
          final action = uri.queryParameters['action'];
          final source = uri.queryParameters['source'];

          AppLogger.i(
            'SOS deep link - alert: $alertId, type: $type, action: $action, source: $source',
            tag: 'DeepLinkService',
          );

          // OS Assistant integration: "Hey Google, start SOS in RedPing"
          if (action == 'start' && source == 'assistant') {
            AppLogger.i(
              '🎤 OS Assistant triggered SOS start',
              tag: 'DeepLinkService',
            );
            if (_router != null) {
              _router!.go(AppLaunchConfig.homeRoute);
              // TODO: Auto-trigger SOS countdown via service
            }
          } else if (action == 'cancel' && source == 'assistant') {
            AppLogger.i(
              '🎤 OS Assistant triggered SOS cancel',
              tag: 'DeepLinkService',
            );
            if (_router != null) {
              _router!.go(AppLaunchConfig.homeRoute);
              // TODO: Cancel active SOS via service
            }
          } else if (type == 'fall' && _router != null) {
            // Navigate to SAR dashboard with fall alert
            _router!.go('/sar?alert=$alertId&type=fall');
          } else if (_router != null) {
            // SAR entrypoint does not include the SOS activation route.
            if (AppLaunchConfig.variant == AppVariant.sar) {
              _router!.go('/sar?alert=$alertId');
            } else {
              _router!.go('/sos?alert=$alertId');
            }
          }
          break;

        case 'status':
          final source = uri.queryParameters['source'];
          AppLogger.i(
            '🎤 OS Assistant status check request, source: $source',
            tag: 'DeepLinkService',
          );

          if (_router != null) {
            _router!.go(AppLaunchConfig.homeRoute);
            // TODO: Show status overlay or speak status via TTS
          }
          break;

        case 'location':
          final action = uri.queryParameters['action'];
          final source = uri.queryParameters['source'];

          AppLogger.i(
            '🎤 OS Assistant location share request, action: $action, source: $source',
            tag: 'DeepLinkService',
          );

          if (action == 'share' && _router != null) {
            // SOS app no longer includes an in-app map page.
            // SAR entrypoint can still route to the SAR map surface.
            if (AppLaunchConfig.variant == AppVariant.sar) {
              _router!.go('/sar/map');
            } else {
              _router!.go(AppLaunchConfig.homeRoute);
            }
            // TODO: Trigger location share via service
          }
          break;

        case 'command':
          // Legacy voice command routing
          final command = uri.pathSegments.isNotEmpty
              ? uri.pathSegments[0]
              : '';
          AppLogger.i(
            '🎤 Voice command received: $command',
            tag: 'DeepLinkService',
          );

          if (_router != null) {
            switch (command) {
              case 'status':
                _router!.go(AppLaunchConfig.homeRoute);
                break;
              case 'hazards':
                _router!.go('/hazard-alerts');
                break;
              case 'battery':
                _router!.go('/settings');
                break;
              default:
                _router!.go(AppLaunchConfig.homeRoute);
            }
          }
          break;

        case 'medical-card':
          final userId = uri.queryParameters['userId'];
          AppLogger.i(
            'Medical card deep link - user: $userId',
            tag: 'DeepLinkService',
          );

          if (_router != null && userId != null) {
            _router!.go('/medical-card/$userId');
          }
          break;

        case 'sar':
          final sessionId = uri.queryParameters['session'];
          AppLogger.i(
            'SAR session deep link - session: $sessionId',
            tag: 'DeepLinkService',
          );

          if (_router != null) {
            _router!.go('/sar?session=$sessionId');
          }
          break;

        default:
          AppLogger.w(
            'Unknown deep link host: ${uri.host}',
            tag: 'DeepLinkService',
          );
      }
    }

    // Handle universal links for magic sign-in and web deep links
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      try {
        final host = uri.host.toLowerCase();
        final path = uri.path;
        // Magic link continue URL: https://redping.app/auth
        if (host == 'redping.app' && path.startsWith('/auth')) {
          AppLogger.i('Magic link detected via universal link', tag: 'DeepLinkService');
          if (_router != null) {
            _router!.go('/auth/email-link', extra: {'link': uri.toString()});
          }
          return;
        }

        // Optional: map web SOS links to in-app emergency card
        if (host == 'redping.app' && path.startsWith('/sos/')) {
          final segments = uri.pathSegments;
          final sessionId = segments.length >= 2 ? segments[1] : null;
          if (sessionId != null && _router != null) {
            _router!.go('/sos/$sessionId');
            return;
          }
        }
      } catch (e) {
        AppLogger.e('Error handling universal link', tag: 'DeepLinkService', error: e);
      }
    }
  }

  /// Launch Doctor Plus app to view health card
  Future<bool> launchDoctorAppHealthCard(String userId) async {
    final uri = Uri.parse('$doctorAppScheme://health-card?userId=$userId');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.w(
          'Cannot launch Doctor Plus app - not installed?',
          tag: 'DeepLinkService',
        );
        return false;
      }
    } catch (e) {
      AppLogger.e(
        'Error launching Doctor Plus app',
        tag: 'DeepLinkService',
        error: e,
      );
      return false;
    }
  }

  /// Launch Doctor Plus app to view vitals
  Future<bool> launchDoctorAppVitals(String userId, {DateTime? date}) async {
    final dateStr = date?.toIso8601String() ?? DateTime.now().toIso8601String();
    final uri = Uri.parse(
      '$doctorAppScheme://vitals?userId=$userId&date=$dateStr',
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      AppLogger.e(
        'Error launching Doctor Plus app',
        tag: 'DeepLinkService',
        error: e,
      );
      return false;
    }
  }

  /// Check if Doctor Plus app is installed
  Future<bool> isDoctorAppInstalled() async {
    final uri = Uri.parse('$doctorAppScheme://');
    try {
      return await canLaunchUrl(uri);
    } catch (e) {
      AppLogger.e(
        'Error checking Doctor Plus app installation',
        tag: 'DeepLinkService',
        error: e,
      );
      return false;
    }
  }

  /// Dispose and clean up
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
