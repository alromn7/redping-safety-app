// Deprecated wrapper maintained for backward compatibility.
// Use `lib/core/config/stripe_config.dart` as the single source of truth.
import '../core/config/stripe_config.dart' as core;

class StripeConfig {
  static String get publishableKey => core.StripeConfig.publishableKey;
  static String get merchantIdentifier => core.StripeConfig.merchantIdentifier;
  static String get merchantDisplayName =>
      core.StripeConfig.merchantDisplayName;
  static String get currencyCode => core.StripeConfig.currency;
  static bool get isLiveMode => core.StripeConfig.isLiveMode;
  static bool get isTestMode => core.StripeConfig.isTestMode;
}
