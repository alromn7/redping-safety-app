import '../models/subscription_tier.dart';
import '../models/subscription_plan.dart';
import 'feature_access_service.dart';

/// Comprehensive access controller for subscription-based feature restrictions
/// Implements the REDP!NG subscription plan blueprint
class SubscriptionAccessController {
  static final SubscriptionAccessController _instance =
      SubscriptionAccessController._internal();
  factory SubscriptionAccessController() => _instance;
  SubscriptionAccessController._internal();

  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;

  /// Check if user has access to a specific feature based on their subscription
  bool hasFeatureAccess(String feature) {
    return _featureAccessService.hasFeatureAccess(feature);
  }

  /// Get the required subscription tier for a feature
  SubscriptionTier? getRequiredTierForFeature(String feature) {
    return _featureAccessService.getRequiredTierForFeature(feature);
  }

  /// Check if user can access a feature with usage limits
  bool canUseFeatureWithLimit(String feature) {
    // Subscriptions/limits have been removed; access is determined by the
    // feature access service (which is currently configured for full access).
    return hasFeatureAccess(feature);
  }

  /// Get feature usage information
  Map<String, dynamic> getFeatureUsageInfo(String feature) {
    final limit = _featureAccessService.getFeatureLimit(feature);

    return {
      'hasAccess': hasFeatureAccess(feature),
      'limit': limit,
      'used': 0, // TODO: Get actual usage from usage tracking service
      'remaining': limit,
      'requiredTier': getRequiredTierForFeature(feature),
      'currentTier': SubscriptionTier.ultra,
    };
  }

  /// Get subscription plan recommendations for a feature
  List<SubscriptionPlan> getRecommendedPlansForFeature(String feature) {
    // Subscriptions have been removed; no upgrade recommendations.
    return const [];
  }

  /// Check if a tier is higher or equal to another tier
  bool _isTierHigherOrEqual(SubscriptionTier tier1, SubscriptionTier tier2) {
    const tierOrder = {
      SubscriptionTier.free: 0,
      SubscriptionTier.essentialPlus: 1,
      SubscriptionTier.pro: 2,
      SubscriptionTier.ultra: 3,
      SubscriptionTier.family: 4,
    };

    return (tierOrder[tier1] ?? 0) >= (tierOrder[tier2] ?? 0);
  }

  /// Get feature access summary for current user
  Map<String, dynamic> getFeatureAccessSummary() {
    return {
      'tier': 'full',
      'features': _featureAccessService.getAvailableFeatures(
        SubscriptionTier.ultra,
      ),
      'restrictions': const <String, dynamic>{},
    };
  }

  /// Get restriction summary for a tier
  Map<String, dynamic> _getRestrictionSummary(SubscriptionTier tier) {
    return const <String, dynamic>{};
  }

  /// Check if user can upgrade to access a feature
  bool canUpgradeForFeature(String feature) {
    // Subscriptions have been removed.
    return false;
  }

  /// Get upgrade recommendation for a feature
  Map<String, dynamic> getUpgradeRecommendation(String feature) {
    return {
      'canUpgrade': false,
      'reason': 'Subscriptions removed',
    };
  }

  /// Get all restricted features for current user
  List<Map<String, dynamic>> getRestrictedFeatures() {
    // Subscriptions removed; no restricted features.
    return const [];
  }
}
