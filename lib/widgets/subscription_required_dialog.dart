import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';

/// Reusable dialog for subscription upgrade prompts
class SubscriptionRequiredDialog extends StatelessWidget {
  final String featureName;
  final String featureDescription;
  final SubscriptionTier requiredTier;
  final List<String>? benefits;

  const SubscriptionRequiredDialog({
    super.key,
    required this.featureName,
    required this.featureDescription,
    required this.requiredTier,
    this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.lock, color: AppTheme.warningOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upgrade Required',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            featureName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            featureDescription,
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: AppTheme.primaryRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Requires ${_getTierName(requiredTier)} Plan',
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (benefits != null && benefits!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'What you\'ll get:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...benefits!.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.safeGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Not Now',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/subscription/plans');
          },
          icon: const Icon(Icons.upgrade),
          label: const Text('View Plans'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.essentialPlus:
        return 'Essential+';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.ultra:
        return 'Ultra';
      case SubscriptionTier.family:
        return 'Family';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  /// Show upgrade dialog for a feature
  static Future<void> show(
    BuildContext context, {
    required String featureName,
    required String featureDescription,
    required SubscriptionTier requiredTier,
    List<String>? benefits,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SubscriptionRequiredDialog(
        featureName: featureName,
        featureDescription: featureDescription,
        requiredTier: requiredTier,
        benefits: benefits,
      ),
    );
  }
}

/// Helper function to check subscription and show upgrade dialog if needed
Future<bool> checkSubscriptionAccess(
  BuildContext context, {
  required String featureName,
  required String featureDescription,
  required SubscriptionTier requiredTier,
  List<String>? benefits,
}) async {
  final subscriptionService = SubscriptionService.instance;
  final currentSub = subscriptionService.currentSubscription;
  final currentTier = currentSub?.plan.tier ?? SubscriptionTier.free;

  // Check if user has required tier or higher
  final tierOrder = {
    SubscriptionTier.free: 0,
    SubscriptionTier.essentialPlus: 1,
    SubscriptionTier.pro: 2,
    SubscriptionTier.ultra: 3,
    SubscriptionTier.family: 4,
  };

  if ((tierOrder[currentTier] ?? 0) >= (tierOrder[requiredTier] ?? 0)) {
    return true; // Has access
  }

  // Show upgrade dialog
  await SubscriptionRequiredDialog.show(
    context,
    featureName: featureName,
    featureDescription: featureDescription,
    requiredTier: requiredTier,
    benefits: benefits,
  );

  return false; // No access
}
