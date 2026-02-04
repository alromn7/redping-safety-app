import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/subscription_tier.dart';

/// Quick reference card showing what each tier unlocks
class TierBenefitsQuickRef extends StatelessWidget {
  const TierBenefitsQuickRef({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: AppTheme.warningOrange),
                SizedBox(width: 8),
                Text(
                  'What Each Tier Unlocks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quick reference guide to help you choose',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),

            _buildTierSection(
              'FREE - Basic Safety',
              SubscriptionTier.free,
              AppTheme.neutralGray,
              Icons.person,
              [
                'RedPing 1-Tap Help (unlimited)',
                'Community (website only)',
                'Quick Call',
                'Basic Map',
                'Manual SOS only',
                '2 emergency contacts',
              ],
              'Great for: Trying out RedPing basics',
            ),

            const SizedBox(height: 16),

            _buildTierSection(
              'ESSENTIAL+ - \$4.99/mo',
              SubscriptionTier.essentialPlus,
              AppTheme.successGreen,
              Icons.shield_outlined,
              [
                '✨ Medical Profile (NEW)',
                '✨ Auto Crash/Fall Detection (NEW)',
                '✨ Hazard Alerts (NEW)',
                '✨ SOS SMS Alerts (NEW)',
                'Everything in Free',
                '5 emergency contacts',
              ],
              'Great for: Daily safety with automatic protection',
            ),

            const SizedBox(height: 16),

            _buildTierSection(
              'PRO - \$9.99/mo',
              SubscriptionTier.pro,
              AppTheme.infoBlue,
              Icons.star,
              [
                '✨ RedPing Mode (Activity-based) (NEW)',
                '✨ Full SAR Dashboard Access (NEW)',
                '✨ Gadget Integration (NEW)',
                'Everything in Essential+',
                'Unlimited contacts',
              ],
              'Great for: Active users, SAR volunteers, power users',
            ),

            const SizedBox(height: 16),

            _buildTierSection(
              'ULTRA - \$29.99/mo',
              SubscriptionTier.ultra,
              AppTheme.primaryRed,
              Icons.diamond,
              [
                '✨ SAR Admin Management (NEW)',
                '✨ Organization Management (NEW)',
                '✨ Add Pro Members (+\$5 each) (NEW)',
                '✨ Team Coordination Tools (NEW)',
                'Everything in Pro',
                'Full admin capabilities',
              ],
              'Great for: SAR organizations, team leaders, coordinators',
            ),

            const SizedBox(height: 16),

            _buildTierSection(
              'FAMILY - \$19.99/mo',
              SubscriptionTier.family,
              AppTheme.warningOrange,
              Icons.family_restroom,
              [
                '✨ 1 Pro + 3 Essential+ accounts (NEW)',
                '✨ Family Dashboard (NEW)',
                '✨ Family Location Sharing (NEW)',
                '✨ Family Portal Messaging (not in-app)',
                'Save \$4.96/month vs individual',
                'Perfect for families of 4',
              ],
              'Great for: Families, protecting loved ones together',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSection(
    String title,
    SubscriptionTier tier,
    Color color,
    IconData icon,
    List<String> benefits,
    String bestFor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    benefit.startsWith('✨')
                        ? Icons.new_releases
                        : Icons.check_circle,
                    color: benefit.startsWith('✨') ? color : AppTheme.safeGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: benefit.startsWith('✨')
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              bestFor,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
