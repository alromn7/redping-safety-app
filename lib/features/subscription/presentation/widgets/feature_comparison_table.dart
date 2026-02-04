import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/subscription_tier.dart';

/// Comprehensive feature comparison table for all subscription tiers
class FeatureComparisonTable extends StatelessWidget {
  const FeatureComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compare Plans',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the plan that fits your safety needs',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Scrollable comparison table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppTheme.neutralGray.withValues(alpha: 0.1),
                ),
                border: TableBorder.all(
                  color: AppTheme.neutralGray.withValues(alpha: 0.2),
                  width: 1,
                ),
                columns: const [
                  DataColumn(
                    label: SizedBox(
                      width: 150,
                      child: Text(
                        'Feature',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Free',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Essential+\n\$4.99/mo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Pro\n\$9.99/mo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ultra\n\$29.99/mo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Family\n\$19.99/mo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                rows: [
                  // Core Features
                  _buildCategoryRow('CORE FEATURES'),
                  _buildFeatureRow(
                    'RedPing 1-Tap Help',
                    free: '✓ Unlimited',
                    essentialPlus: '✓ Unlimited',
                    pro: '✓ Unlimited',
                    ultra: '✓ Unlimited',
                    family: '✓ Unlimited',
                  ),
                  _buildFeatureRow(
                    'Community (website)',
                    free: 'Web only',
                    essentialPlus: 'Web only',
                    pro: 'Web only',
                    ultra: 'Web only',
                    family: 'Web only',
                  ),
                  _buildFeatureRow(
                    'Quick Call',
                    free: '✓',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                  ),
                  _buildFeatureRow(
                    'Map Access',
                    free: '✓ Basic',
                    essentialPlus: '✓ Full',
                    pro: '✓ Full',
                    ultra: '✓ Full',
                    family: '✓ Full',
                  ),
                  _buildFeatureRow(
                    'Emergency Contacts',
                    free: '2',
                    essentialPlus: '5',
                    pro: 'Unlimited',
                    ultra: 'Unlimited',
                    family: 'Unlimited',
                  ),

                  // Profile & Medical
                  _buildCategoryRow('PROFILE & MEDICAL'),
                  _buildFeatureRow(
                    'Standard Profile',
                    free: '✓',
                    essentialPlus: '✓',
                    pro: '✓ Pro',
                    ultra: '✓ Pro',
                    family: '✓ Pro',
                  ),
                  _buildFeatureRow(
                    'Medical Profile',
                    free: '✗',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                    highlight: SubscriptionTier.essentialPlus,
                  ),

                  // Emergency Detection
                  _buildCategoryRow('EMERGENCY DETECTION'),
                  _buildFeatureRow(
                    'Manual SOS',
                    free: '✓',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                  ),
                  _buildFeatureRow(
                    'Auto Crash/Fall Detection',
                    free: '✗',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                    highlight: SubscriptionTier.essentialPlus,
                  ),
                  _buildFeatureRow(
                    'RedPing Mode',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓ Pro',
                    highlight: SubscriptionTier.pro,
                  ),

                  // Alerts & Monitoring
                  _buildCategoryRow('ALERTS & MONITORING'),
                  _buildFeatureRow(
                    'Hazard Alerts',
                    free: '✗',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                    highlight: SubscriptionTier.essentialPlus,
                  ),
                  _buildFeatureRow(
                    'SOS SMS Alerts',
                    free: '✗',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                    highlight: SubscriptionTier.essentialPlus,
                  ),

                  // Devices & Integration
                  _buildCategoryRow('DEVICES & INTEGRATION'),
                  _buildFeatureRow(
                    'Gadget Integration',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓ Pro',
                    highlight: SubscriptionTier.pro,
                  ),
                  _buildFeatureRow(
                    'Smartwatch Support',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓ Pro',
                  ),
                  _buildFeatureRow(
                    'Car Device Support',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓ Pro',
                  ),

                  // SAR Dashboard
                  _buildCategoryRow('SAR DASHBOARD'),
                  _buildFeatureRow(
                    'View SAR Dashboard',
                    free: '✓',
                    essentialPlus: '✓',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓',
                  ),
                  _buildFeatureRow(
                    'Respond to Emergencies',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✓',
                    ultra: '✓',
                    family: '✓ Pro',
                    highlight: SubscriptionTier.pro,
                  ),
                  _buildFeatureRow(
                    'SAR Admin Management',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✗',
                    ultra: '✓',
                    family: '✗',
                    highlight: SubscriptionTier.ultra,
                  ),

                  // Organization
                  _buildCategoryRow('ORGANIZATION'),
                  _buildFeatureRow(
                    'Organization Management',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✗',
                    ultra: '✓',
                    family: '✗',
                    highlight: SubscriptionTier.ultra,
                  ),
                  _buildFeatureRow(
                    'Add Pro Members',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✗',
                    ultra: '✓ +\$5 ea',
                    family: '✗',
                  ),

                  // Family Features
                  _buildCategoryRow('FAMILY FEATURES'),
                  _buildFeatureRow(
                    'Family Dashboard',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✗',
                    ultra: '✗',
                    family: '✓',
                    highlight: SubscriptionTier.family,
                  ),
                  _buildFeatureRow(
                    'Family Location Sharing',
                    free: '✗',
                    essentialPlus: '✗',
                    pro: '✗',
                    ultra: '✗',
                    family: '✓',
                  ),
                  _buildFeatureRow(
                    'Family Chat (not in-app)',
                    free: 'Not in-app',
                    essentialPlus: 'Not in-app',
                    pro: 'Not in-app',
                    ultra: 'Not in-app',
                    family: 'Not in-app',
                  ),
                  _buildFeatureRow(
                    'Account Mix',
                    free: '-',
                    essentialPlus: '-',
                    pro: '-',
                    ultra: '-',
                    family: '1 Pro +\n3 Ess+',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildCategoryRow(String category) {
    return DataRow(
      color: WidgetStateProperty.all(AppTheme.infoBlue.withValues(alpha: 0.1)),
      cells: [
        DataCell(
          Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.infoBlue,
            ),
          ),
        ),
        const DataCell(SizedBox()),
        const DataCell(SizedBox()),
        const DataCell(SizedBox()),
        const DataCell(SizedBox()),
        const DataCell(SizedBox()),
      ],
    );
  }

  DataRow _buildFeatureRow(
    String feature, {
    required String free,
    required String essentialPlus,
    required String pro,
    required String ultra,
    required String family,
    SubscriptionTier? highlight,
  }) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(feature, style: const TextStyle(fontSize: 13)),
          ),
        ),
        DataCell(_buildValueCell(free, SubscriptionTier.free, highlight)),
        DataCell(
          _buildValueCell(
            essentialPlus,
            SubscriptionTier.essentialPlus,
            highlight,
          ),
        ),
        DataCell(_buildValueCell(pro, SubscriptionTier.pro, highlight)),
        DataCell(_buildValueCell(ultra, SubscriptionTier.ultra, highlight)),
        DataCell(_buildValueCell(family, SubscriptionTier.family, highlight)),
      ],
    );
  }

  Widget _buildValueCell(
    String value,
    SubscriptionTier tier,
    SubscriptionTier? highlight,
  ) {
    final isHighlighted = highlight == tier;
    final isAvailable = value.startsWith('✓');
    final isNotAvailable = value.startsWith('✗');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: isHighlighted
          ? BoxDecoration(
              color: _getTierColor(tier).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getTierColor(tier), width: 2),
            )
          : null,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          color: isNotAvailable
              ? AppTheme.neutralGray
              : isAvailable
              ? AppTheme.safeGreen
              : AppTheme.primaryText,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
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
}
