import 'package:flutter/material.dart';
import '../../../../models/subscription_plan.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../core/theme/app_theme.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.isYearlyBilling,
    required this.onSubscribe,
    this.isCurrentPlan = false,
    this.isFamilyPlan = false,
  });

  final SubscriptionPlan plan;
  final bool isYearlyBilling;
  final VoidCallback onSubscribe;
  final bool isCurrentPlan;
  final bool isFamilyPlan;

  @override
  Widget build(BuildContext context) {
    final price = isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;
    final period = isYearlyBilling ? 'year' : 'month';
    final savings = isYearlyBilling ? plan.yearlySavingsPercent : 0.0;

    return Card(
      elevation: isCurrentPlan ? 8 : 2,
      color: isCurrentPlan ? AppTheme.safeGreen.withValues(alpha: 0.1) : null,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 400, // Prevent cards from getting too wide
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isCurrentPlan
              ? Border.all(color: AppTheme.safeGreen, width: 2)
              : _getTierBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced from 20 to 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tier badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getTierIcon(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getTierColor(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.safeGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Trial Period Banner (for paid plans)
              if (plan.tier != SubscriptionTier.free) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningOrange, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.celebration,
                        color: AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '14-day FREE trial • No charge until Dec 4, 2025',
                          style: TextStyle(
                            color: AppTheme.warningOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pricing
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  if (plan.tier != SubscriptionTier.free) ...[
                    Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                    Text(
                      'for 14 days',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getTierColor(),
                      ),
                    ),
                    Text(
                      '/$period',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                  if (isYearlyBilling && savings > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SAVE ${savings.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (plan.tier != SubscriptionTier.free) ...[
                const SizedBox(height: 8),
                Text(
                  'Then \$${price.toStringAsFixed(2)}/$period',
                  style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
                ),
              ],
              const SizedBox(height: 20),

              // Family account breakdown (for family plan)
              if (isFamilyPlan) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.family_restroom,
                            color: AppTheme.infoBlue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Family Package Includes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _buildAccountTypeChip(
                            '3× Essential+',
                            AppTheme.successGreen,
                            Icons.shield_outlined,
                          ),
                          const SizedBox(height: 8),
                          _buildAccountTypeChip(
                            '1× Pro',
                            AppTheme.infoBlue,
                            Icons.star,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total Value: \$${(4.99 * 3 + 9.99).toStringAsFixed(2)}/month',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'You Pay: \$${plan.monthlyPrice}/month',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.safeGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Features list
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check,
                        color: AppTheme.safeGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Limits information
              if (plan.limits.isNotEmpty) ...[
                const Text(
                  'Plan Limits:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...plan.limits.entries.map(
                  (entry) => _buildLimitItem(entry.key, entry.value),
                ),
                const SizedBox(height: 20),
              ],

              // Subscribe button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentPlan ? null : onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentPlan
                        ? Colors.grey
                        : _getTierColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isCurrentPlan
                        ? 'CURRENT PLAN'
                        : plan.tier == SubscriptionTier.free
                        ? 'GET STARTED FREE'
                        : isFamilyPlan
                        ? 'START 14-DAY FREE TRIAL'
                        : 'START FREE TRIAL',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeChip(String text, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem(String key, dynamic value) {
    String displayText = '';

    switch (key) {
      case 'sosAlertsPerMonth':
        displayText = value == -1
            ? 'Unlimited SOS alerts'
            : '$value SOS alerts per month';
        break;
      case 'emergencyContacts':
        displayText = value == -1
            ? 'Unlimited emergency contacts'
            : 'Up to $value emergency contacts';
        break;
      case 'satelliteMessages':
        displayText = value == 0
            ? 'No satellite communication'
            : value == -1
            ? 'Unlimited satellite messages'
            : '$value satellite messages per month';
        break;
      case 'sarParticipation':
        displayText = value
            ? 'SAR volunteer participation'
            : 'No SAR participation';
        break;
      case 'organizationManagement':
        displayText = value
            ? 'Organization management'
            : 'No organization management';
        break;
      case 'redpingHelp':
        if (value is int) {
          displayText = value == -1
              ? 'Unlimited REDP!NG Help'
              : value == 0
              ? 'No REDP!NG Help'
              : '$value REDP!NG Help requests/month';
        } else {
          displayText = 'REDP!NG Help available';
        }
        break;
      default:
        displayText = '$key: $value';
    }

    // Helper function to determine if feature is completely disabled
    bool isFeatureDisabled(dynamic value) {
      if (value is bool) return !value;
      if (value is int) return value == 0;
      if (value is String) return value == 'false' || value == '0';
      return value == null || value == false || value == 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isFeatureDisabled(value) ? Icons.close : Icons.info_outline,
            color: isFeatureDisabled(value) ? Colors.grey : AppTheme.infoBlue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                color: isFeatureDisabled(value)
                    ? AppTheme.disabledText
                    : AppTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor() {
    switch (plan.tier) {
      case SubscriptionTier.free:
        return AppTheme.neutralGray;
      case SubscriptionTier.essentialPlus:
        return AppTheme.successGreen;
      case SubscriptionTier.pro:
        return AppTheme.infoBlue;
      case SubscriptionTier.ultra:
        return AppTheme.primaryRed;
      case SubscriptionTier.family:
        return AppTheme.warningOrange;
    }
  }

  Widget _getTierIcon() {
    switch (plan.tier) {
      case SubscriptionTier.free:
        return const Icon(Icons.person, color: AppTheme.neutralGray);
      case SubscriptionTier.essentialPlus:
        return const Icon(Icons.shield_outlined, color: AppTheme.successGreen);
      case SubscriptionTier.pro:
        return const Icon(Icons.star, color: AppTheme.infoBlue);
      case SubscriptionTier.ultra:
        return const Icon(Icons.diamond, color: AppTheme.primaryRed);
      case SubscriptionTier.family:
        return const Icon(Icons.family_restroom, color: AppTheme.warningOrange);
    }
  }

  Border? _getTierBorder() {
    if (isCurrentPlan) return null;

    switch (plan.tier) {
      case SubscriptionTier.free:
        return Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3));
      case SubscriptionTier.essentialPlus:
        return Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3));
      case SubscriptionTier.pro:
        return Border.all(
          color: AppTheme.infoBlue.withValues(alpha: 0.3),
          width: 2,
        );
      case SubscriptionTier.ultra:
        return Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
          width: 2,
        );
      case SubscriptionTier.family:
        return Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
          width: 2,
        );
    }
  }
}
