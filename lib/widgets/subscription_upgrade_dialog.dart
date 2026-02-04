import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../core/theme/app_theme.dart';

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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.verified, color: AppTheme.safeGreen),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Full Access',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        '$featureName is available. Subscriptions and tiers have been removed.',
        style: const TextStyle(color: AppTheme.secondaryText, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (onUpgradePressed != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onUpgradePressed!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
      ],
    );
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
