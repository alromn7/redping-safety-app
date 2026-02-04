import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../core/theme/app_theme.dart';

/// Dialog shown when user tries to access a premium feature
class UpgradeRequiredDialog extends StatelessWidget {
  final String featureName;
  final String featureDescription;
  final SubscriptionTier? requiredTier;
  final List<String> benefits;
  final VoidCallback? onUpgradePressed;

  const UpgradeRequiredDialog({
    super.key,
    required this.featureName,
    required this.featureDescription,
    this.requiredTier,
    this.benefits = const [],
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock_outline,
              color: AppTheme.warningOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upgrade Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
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
            featureDescription,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.primaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Subscriptions have been removed; all features are available.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
          ),
          if (benefits.isNotEmpty) ...[
            Text(
              'This upgrade includes:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...benefits
                .take(3)
                .map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
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
            if (benefits.length > 3)
              Text(
                '+ ${benefits.length - 3} more features...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.disabledText,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Maybe Later',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            if (onUpgradePressed != null) {
              onUpgradePressed!();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getTierColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'OK',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getTierColor() {
    if (requiredTier == null) return AppTheme.primaryRed;

    switch (requiredTier!) {
      case SubscriptionTier.free:
        return AppTheme.neutralGray;
      case SubscriptionTier.essentialPlus:
        return AppTheme.safeGreen;
      case SubscriptionTier.pro:
        return AppTheme.infoBlue;
      case SubscriptionTier.ultra:
        return AppTheme.primaryRed;
      case SubscriptionTier.family:
        return AppTheme.warningOrange;
    }
  }

  IconData _getTierIcon() {
    if (requiredTier == null) return Icons.star;

    switch (requiredTier!) {
      case SubscriptionTier.free:
        return Icons.person;
      case SubscriptionTier.essentialPlus:
        return Icons.shield;
      case SubscriptionTier.pro:
        return Icons.star;
      case SubscriptionTier.ultra:
        return Icons.diamond;
      case SubscriptionTier.family:
        return Icons.family_restroom;
    }
  }

  /// Static method to show upgrade dialog for a specific feature
  static Future<bool?> show(
    BuildContext context, {
    required String featureName,
    required String featureDescription,
    List<String> benefits = const [],
    VoidCallback? onUpgradePressed,
  }) {
    // Dialogs disabled globally; do not show anything
    return Future.value(false);
  }

  /// Show upgrade dialog for REDP!NG Help feature
  static Future<bool?> showForRedpingHelp(BuildContext context) {
    return Future.value(false);
  }

  /// Show upgrade dialog for SAR participation
  static Future<bool?> showForSARParticipation(BuildContext context) {
    return Future.value(false);
  }

  /// Show upgrade dialog for satellite communication
  static Future<bool?> showForSatelliteComm(BuildContext context) {
    return Future.value(false);
  }

  /// Show upgrade dialog for organization management
  static Future<bool?> showForOrganizationManagement(BuildContext context) {
    return Future.value(false);
  }

  /// Show upgrade dialog for SAR volunteer registration
  static Future<bool?> showForSARVolunteerRegistration(BuildContext context) {
    return Future.value(false);
  }

  /// Show upgrade dialog for SAR team management
  static Future<bool?> showForSARTeamManagement(BuildContext context) {
    return Future.value(false);
  }
}
