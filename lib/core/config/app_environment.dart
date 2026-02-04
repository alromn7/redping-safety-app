import 'package:flutter/foundation.dart';
import 'stripe_config.dart';

/// Environment configuration for RedPing app
/// Handles API keys, endpoints, and feature flags for different environments
class AppEnvironment {
  /// Current environment mode
  static const Environment environment = kReleaseMode
      ? Environment.production
      : Environment.development;

  /// Stripe Configuration
  static String get stripePublishableKey => StripeConfig.publishableKey;

  /// Stripe Merchant Identifier (for Apple Pay)
  static const String stripeMerchantIdentifier =
      StripeConfig.merchantIdentifier;

  /// Stripe URL Scheme (for 3D Secure)
  static const String stripeUrlScheme = StripeConfig.urlScheme;

  /// Firebase Cloud Functions URL
  static String get cloudFunctionsUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:5001/redping-dev/us-central1';
      case Environment.staging:
        return 'https://us-central1-redping-staging.cloudfunctions.net';
      case Environment.production:
        return 'https://us-central1-redping-prod.cloudfunctions.net';
    }
  }

  /// Feature Flags
  static bool get enableMockPayments => environment == Environment.development;
  static bool get enablePaymentLogs => !kReleaseMode;
  static bool get enableStripeTestMode => environment != Environment.production;

  /// API Endpoints
  static String get paymentEndpoint =>
      '$cloudFunctionsUrl/processSubscriptionPayment';
  static String get cancelSubscriptionEndpoint =>
      '$cloudFunctionsUrl/cancelSubscription';
  static String get updatePaymentMethodEndpoint =>
      '$cloudFunctionsUrl/updatePaymentMethod';
  static String get getSubscriptionStatusEndpoint =>
      '$cloudFunctionsUrl/getSubscriptionStatus';

  /// Stripe Price IDs (configured in Stripe Dashboard)
  static Map<String, Map<String, String>> get stripePriceIds {
    switch (environment) {
      case Environment.development:
      case Environment.staging:
        return {
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
      case Environment.production:
        return {
          'essentialPlus': {
            'monthly': 'price_1SVjOcPlurWsomXvo3cJ8YO9',
            'yearly': 'price_live_essential_yearly',
          },
          'pro': {
            'monthly': 'price_1SVjOIPlurWsomXvOvgWfPFK',
            'yearly': 'price_live_pro_yearly',
          },
          'ultra': {
            'monthly': 'price_1SVjNIPlurWsomXvMAxQouxd',
            'yearly': 'price_live_ultra_yearly',
          },
          'family': {
            'monthly': 'price_1SVjO7PlurWsomXv9CCcDrGF',
            'yearly': 'price_live_family_yearly',
          },
        };
    }
  }

  /// Validation
  static void validate() {
    if (environment == Environment.production) {
      if (stripePublishableKey.isEmpty) {
        throw Exception(
          'STRIPE_PUBLISHABLE_KEY_PROD must be set in production',
        );
      }
      if (stripePublishableKey.startsWith('pk_test_')) {
        throw Exception('Production must use live Stripe keys (pk_live_)');
      }
    }
  }
}

/// Environment modes
enum Environment { development, staging, production }
