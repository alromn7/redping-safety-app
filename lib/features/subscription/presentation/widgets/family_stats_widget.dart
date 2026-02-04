import 'package:flutter/material.dart';
import '../../../../models/auth_user.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/subscription_tier.dart';

class FamilyStatsWidget extends StatelessWidget {
  const FamilyStatsWidget({super.key, required this.family});

  final FamilySubscription family;

  @override
  Widget build(BuildContext context) {
    final essentialMembers = family.getMembersByTier(
      SubscriptionTier.essentialPlus,
    );
    final proMembers = family.getMembersByTier(SubscriptionTier.pro);
    final totalSavings = (4.99 * 4 + 14.99) - family.plan.monthlyPrice;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: AppTheme.warningOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.familyName ?? 'Family Subscription',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active since ${_formatDate(family.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Members',
                    '${family.totalMembers}',
                    Icons.people,
                    AppTheme.infoBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Monthly Savings',
                    '\$${totalSavings.toStringAsFixed(2)}',
                    Icons.savings,
                    AppTheme.safeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Essential Accounts',
                    '${essentialMembers.length}/${family.plan.essentialAccounts}',
                    Icons.shield,
                    AppTheme.safeGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pro Accounts',
                    '${proMembers.length}/${family.plan.proAccounts}',
                    Icons.star,
                    AppTheme.infoBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Family features status
            const Text(
              'Family Features',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildFeatureStatus(
              'Location Sharing',
              family.settings.allowLocationSharing,
            ),
            _buildFeatureStatus(
              'Cross-Account Notifications',
              family.settings.allowCrossAccountNotifications,
            ),
            _buildFeatureStatus(
              'Shared Emergency Contacts',
              family.settings.allowSharedEmergencyContacts,
            ),
            _buildFeatureStatus(
              'Activity Sharing',
              family.settings.allowActivitySharing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureStatus(String feature, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? AppTheme.safeGreen : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: isEnabled ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
