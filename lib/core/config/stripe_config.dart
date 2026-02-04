import 'package:flutter/foundation.dart';

/// Stripe SDK Configuration for RedPing Subscriptions
///
/// This class provides centralized Stripe configuration including:
/// - Publishable keys (test and live)
/// - Merchant identifiers for Apple Pay
/// - URL schemes for 3D Secure authentication
/// - Feature flags for development
class StripeConfig {
  /// Stripe Publishable Key
  ///
  /// Test Mode (Development/Staging): pk_test_...
  /// Live Mode (Production): pk_live_...
  ///
  /// SECURITY: Only publishable keys are safe to embed in client apps.
  /// Secret keys (sk_...) must NEVER be in client code - only in Cloud Functions.
  static String get publishableKey {
    // Allow forcing LIVE key on debug builds using a Dart define
    const bool forceLive = bool.fromEnvironment(
      'FORCE_LIVE_STRIPE',
      defaultValue: false,
    );

    if (kReleaseMode || forceLive) {
      // PRODUCTION or FORCE_LIVE in debug
      return const String.fromEnvironment(
        'STRIPE_PUBLISHABLE_KEY',
        defaultValue:
            'pk_live_51SVNMiPlurWsomXvjlPBOzpskjBW3hKF5aLKrapO23AVUAhBRZ1Ch8zOZl5UlxtQmf0HKJq0hoad3jzr148tpiXa00pDQw8lwi',
      );
    }

    // DEVELOPMENT/STAGING - Test key
    // Default test key placeholder; MUST override via --dart-define STRIPE_PUBLISHABLE_KEY_TEST=pk_test_xxx
    return const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY_TEST',
      defaultValue: 'pk_test_CHANGE_ME',
    );
  }

  /// Apple Pay Merchant Identifier
  ///
  /// Format: merchant.{your.bundle.id}
  /// Configure in Apple Developer Portal → Certificates, Identifiers & Profiles
  /// Link to Stripe in Stripe Dashboard → Settings → Apple Pay
  static const String merchantIdentifier = 'merchant.com.redping.redping';

  /// Merchant Display Name (shown in Apple Pay sheet)
  static const String merchantDisplayName = 'REDP!NG Safety';

  /// URL Scheme for 3D Secure redirects
  ///
  /// Must match URL scheme in:
  /// - Android: AndroidManifest.xml <data android:scheme="redping" />
  /// - iOS: Info.plist → URL Types → URL Schemes
  static const String urlScheme = 'redping';

  /// Return URL after 3D Secure authentication
  static const String returnUrl = 'redping://stripe-redirect';

  /// Enable test mode features
  static bool get isTestMode {
    const bool forceLive = bool.fromEnvironment(
      'FORCE_LIVE_STRIPE',
      defaultValue: false,
    );
    return !kReleaseMode && !forceLive;
  }

  /// Live mode convenience flag (inverse of test mode)
  static bool get isLiveMode => !isTestMode;

  /// Enable debug logging for Stripe operations
  static bool get enableLogging => kDebugMode;

  /// Test card numbers for development
  /// Source: https://stripe.com/docs/testing
  static const Map<String, String> testCards = {
    'success': '4242 4242 4242 4242',
    '3ds_required': '4000 0027 6000 3184',
    'declined': '4000 0000 0000 0002',
    'insufficient_funds': '4000 0000 0000 9995',
    'expired': '4000 0000 0000 0069',
  };

  /// Subscription Price IDs from Stripe Dashboard
  ///
  /// Configure these after creating products in Stripe:
  /// 1. Go to Stripe Dashboard → Products
  /// 2. Create 8 products (4 tiers × 2 billing periods)
  /// 3. Copy the Price ID for each (starts with price_...)
  /// 4. Update the values below
  // LIVE Price IDs (recurring) – pulled from Stripe Dashboard
  static const Map<String, Map<String, String>> _priceIdsLive = {
    'essentialPlus': {
      'monthly': 'price_1SYSJdPlurWsomXvLHqo1BQV',
      'yearly': 'price_1SYSKIPlurWsomXva4VUJL3b',
    },
    'pro': {
      'monthly': 'price_1SYSHUPlurWsomXvpIkKf7IZ',
      'yearly': 'price_1SYSI6PlurWsomXvJdn44f5k',
    },
    'ultra': {
      'monthly': 'price_1SYSAgPlurWsomXv5gYXx038',
      'yearly': 'price_1SYSDGPlurWsomXvpfBoxNmo',
    },
    'family': {
      'monthly': 'price_1SYSEzPlurWsomXva7HWAETB',
      'yearly': 'price_1SYSGBPlurWsomXvzv7yrZat',
    },
  };

  // TEST (sandbox) Price IDs – replace with real test mode IDs before exercising test charges.
  static const Map<String, Map<String, String>> _priceIdsTest = {
    'essentialPlus': {
      'monthly': 'price_test_essential_monthly',
      'yearly': 'price_test_essential_yearly',
    },
    'pro': {
      'monthly': 'price_test_pro_monthly',
      'yearly': 'price_test_pro_yearly',
    },
    'ultra': {
      'monthly': 'price_test_ultra_monthly',
      'yearly': 'price_test_ultra_yearly',
    },
    'family': {
      'monthly': 'price_test_family_monthly',
      'yearly': 'price_test_family_yearly',
    },
  };

  static Map<String, Map<String, String>> get priceIds =>
      isTestMode ? _priceIdsTest : _priceIdsLive;

  /// Get Price ID for specific tier and billing period
  static String? getPriceId(String tier, bool isYearly) {
    final billingPeriod = isYearly ? 'yearly' : 'monthly';
    return priceIds[tier]?[billingPeriod];
  }

  /// Subscription tier pricing (for display)
  static const Map<String, Map<String, double>> pricing = {
    'essentialPlus': {'monthly': 4.99, 'yearly': 49.99},
    'pro': {'monthly': 9.99, 'yearly': 99.99},
    'ultra': {'monthly': 29.99, 'yearly': 299.99},
    'family': {'monthly': 19.99, 'yearly': 199.99},
  };

  /// Trial period (days)
  static const int trialPeriodDays = 14;

  /// Currency code
  static const String currency = 'AUD';

  /// Validate configuration
  static void validate() {
    if (kReleaseMode) {
      // Production validation
      if (publishableKey.isEmpty) {
        throw StateError('Stripe publishable key must be configured');
      }
      if (publishableKey.startsWith('pk_test_')) {
        throw StateError(
          'Production build must use live Stripe key (pk_live_...), not test key',
        );
      }

      // Verify all live price IDs are present and not placeholders
      final requiredTiers = ['essentialPlus', 'pro', 'ultra', 'family'];
      final requiredPeriods = ['monthly', 'yearly'];

      for (final tier in requiredTiers) {
        for (final period in requiredPeriods) {
          final priceId = priceIds[tier]?[period];
          if (priceId == null || priceId.isEmpty) {
            throw StateError('Missing $tier $period price ID in production');
          }
          if (!priceId.startsWith('price_1')) {
            throw StateError(
              'Invalid $tier $period price ID: $priceId - must be real Stripe price ID',
            );
          }
        }
      }

      debugPrint('✅ Stripe LIVE mode validated: All 8 price IDs present');
    } else {
      // Development validation
      if (publishableKey.isEmpty) {
        debugPrint('WARNING: Stripe publishable key not configured');
      }
      if (!kReleaseMode && publishableKey.startsWith('pk_live_')) {
        debugPrint(
          'WARNING: Using LIVE key while in test mode; switch to pk_test_ to avoid real charges.',
        );
      }
      // Warn if test map still contains placeholder values
      if (isTestMode) {
        final incomplete = priceIds.entries
            .where(
              (e) => e.value.values.any(
                (v) =>
                    v.contains('price_test_') && v.endsWith('_monthly') ||
                    v.contains('price_test_') && v.endsWith('_yearly'),
              ),
            )
            .isNotEmpty;
        if (incomplete) {
          debugPrint(
            'WARNING: Test Price IDs appear to be placeholders; replace with real test Stripe price IDs.',
          );
        }
      }
    }
  }

  /// Initialize Stripe configuration
  /// Call this before using any Stripe features
  static Future<void> initialize() async {
    validate();
    if (enableLogging) {
      debugPrint('Stripe Configuration:');
      debugPrint('  Mode: ${isTestMode ? "TEST" : "LIVE"}');
      // Safely truncate key for logging
      final keyPreview = publishableKey.length > 20
          ? '${publishableKey.substring(0, 20)}...'
          : publishableKey;
      debugPrint('  Key: $keyPreview');
      debugPrint('  Merchant: $merchantDisplayName');
      debugPrint('  URL Scheme: $urlScheme');
      debugPrint('  Price IDs Source: ${isTestMode ? 'TEST MAP' : 'LIVE MAP'}');
    }

    // Release mode warning for live payments
    if (kReleaseMode && !isTestMode) {
      debugPrint('⚠️  LIVE MODE ACTIVE - Real charges will occur!');
      debugPrint(
        '   Using ${priceIds.length} subscription tiers with live price IDs',
      );
    }
  }
}
