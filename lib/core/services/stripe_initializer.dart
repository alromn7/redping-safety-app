import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../config/app_environment.dart';

/// Stripe initialization service
/// Sets up Stripe SDK with environment-specific configuration
class StripeInitializer {
  static bool _initialized = false;

  /// Initialize Stripe SDK
  /// Must be called before app starts (in main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Validate environment configuration
      AppEnvironment.validate();

      // Configure Stripe
      Stripe.publishableKey = AppEnvironment.stripePublishableKey;
      Stripe.merchantIdentifier = AppEnvironment.stripeMerchantIdentifier;
      Stripe.urlScheme = AppEnvironment.stripeUrlScheme;

      // Set Apple Pay merchant identifier
      await Stripe.instance.applySettings();

      _initialized = true;
      debugPrint('✅ Stripe initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Stripe: $e');
      rethrow;
    }
  }

  /// Check if Stripe is initialized
  static bool get isInitialized => _initialized;
}
