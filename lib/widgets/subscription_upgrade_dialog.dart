import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';
import '../services/subscription_access_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/routing/app_router.dart';
import 'package:go_router/go_router.dart';

/// Enhanced upgrade dialog that shows subscription plans based on feature requirements
class SubscriptionUpgradeDialog extends StatelessWidget {
  final String feature;
  final String featureName;
  final String featureDescription;
  final SubscriptionTier? requiredTier;
  final List<String> benefits;
  final VoidCallback? onUpgradePressed;

  const SubscriptionUpgradeDialog({
    super.key,
    required this.feature,
    required this.featureName,
    required this.featureDescription,
    this.requiredTier,
    this.benefits = const [],
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService.instance;
    final accessController = SubscriptionAccessController();
    final upgradeRecommendation = accessController.getUpgradeRecommendation(
      feature,
    );
    final currentSubscription = subscriptionService.currentSubscription;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.warningOrange.withValues(alpha: 0.8),
                    AppTheme.warningOrange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upgrade Required',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    featureName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature description
                    Text(
                      featureDescription,
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Current plan info
                    if (currentSubscription != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.neutralGray.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.infoBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current: ${currentSubscription.plan.name}',
                                style: const TextStyle(
                                  color: AppTheme.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Recommended plans
                    if (upgradeRecommendation['canUpgrade'] == true) ...[
                      const Text(
                        'Recommended Plans',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendedPlans(context, upgradeRecommendation),
                      const SizedBox(height: 16),
                    ],

                    // Benefits
                    if (benefits.isNotEmpty) ...[
                      const Text(
                        'What you get:',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...benefits.map(
                        (benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.safeGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: const TextStyle(
                                    color: AppTheme.secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Maybe Later'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (onUpgradePressed != null) {
                                onUpgradePressed!();
                              } else {
                                context.push(AppRouter.subscriptionPlans);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'View Plans',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedPlans(
    BuildContext context,
    Map<String, dynamic> recommendation,
  ) {
    final subscriptionService = SubscriptionService.instance;
    final requiredTier = recommendation['requiredTier'] as String?;

    if (requiredTier == null) return const SizedBox.shrink();

    // Get plans that meet the requirement
    final availablePlans = subscriptionService.availablePlans;
    final recommendedPlans = availablePlans
        .where((plan) {
          return _isTierSufficient(plan.tier, requiredTier);
        })
        .take(2)
        .toList(); // Show up to 2 recommended plans

    return Column(
      children: recommendedPlans.map((plan) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warningOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${plan.monthlyPrice.toStringAsFixed(2)}/month',
                      style: TextStyle(
                        color: AppTheme.warningOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.yearlySavingsPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.safeGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Save ${plan.yearlySavingsPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.safeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isTierSufficient(SubscriptionTier tier, String requiredTierName) {
    const tierOrder = {
      SubscriptionTier.free: 0,
      SubscriptionTier.essentialPlus: 1,
      SubscriptionTier.pro: 2,
      SubscriptionTier.ultra: 3,
      SubscriptionTier.family: 4,
    };

    final currentTierLevel = tierOrder[tier] ?? 0;

    // Parse required tier name to enum
    SubscriptionTier? requiredTier;
    try {
      requiredTier = SubscriptionTier.values.firstWhere(
        (t) => t.name.toLowerCase() == requiredTierName.toLowerCase(),
      );
    } catch (e) {
      return false;
    }

    final requiredTierLevel = tierOrder[requiredTier] ?? 0;
    return currentTierLevel >= requiredTierLevel;
  }

  /// Show upgrade dialog for a specific feature
  static Future<void> showForFeature(
    BuildContext context, {
    required String feature,
    required String featureName,
    required String featureDescription,
    SubscriptionTier? requiredTier,
    List<String> benefits = const [],
    VoidCallback? onUpgradePressed,
  }) {
    // Dialogs disabled globally; no-op
    return Future.value();
  }
}
