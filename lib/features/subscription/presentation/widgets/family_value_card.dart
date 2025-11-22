import 'package:flutter/material.dart';
import '../../../../models/subscription_plan.dart';
import '../../../../core/theme/app_theme.dart';

class FamilyValueCard extends StatelessWidget {
  const FamilyValueCard({
    super.key,
    required this.plan,
    required this.isYearlyBilling,
  });

  final SubscriptionPlan plan;
  final bool isYearlyBilling;

  @override
  Widget build(BuildContext context) {
    final individualCost = 4.99 * 3 + 9.99; // 3 Essential+ + 1 Pro
    final familyCost = isYearlyBilling
        ? plan.yearlyPrice / 12
        : plan.monthlyPrice;
    final savings = individualCost - familyCost;
    final savingsPercent = (savings / individualCost) * 100;

    return Card(
      elevation: 4,
      color: AppTheme.warningOrange.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warningOrange, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.family_restroom,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FAMILY PACKAGE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                        Text(
                          'Complete Family Safety Protection',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Value comparison
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    // Individual cost breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '3× Essential+ Plans:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '\$${(4.99 * 3).toStringAsFixed(2)}/month',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '1× Pro Plan:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '\$${9.99.toStringAsFixed(2)}/month',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Individual Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${individualCost.toStringAsFixed(2)}/month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Family Package:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                        Text(
                          '\$${familyCost.toStringAsFixed(2)}/month',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Savings highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOU SAVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${savings.toStringAsFixed(2)}/month',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${savingsPercent.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Family benefits
              const Text(
                'Exclusive Family Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildFamilyBenefit(
                'Family Dashboard',
                'Central management for all accounts',
              ),
              _buildFamilyBenefit(
                'Shared Contacts',
                'One emergency contact list',
              ),
              _buildFamilyBenefit(
                'Location Sharing',
                'See family member locations',
              ),
              _buildFamilyBenefit(
                'Cross Notifications',
                'Get alerts from family emergencies',
              ),
              _buildFamilyBenefit(
                'Family Chat',
                'Private family communication channel',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyBenefit(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.family_restroom,
            color: AppTheme.warningOrange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
