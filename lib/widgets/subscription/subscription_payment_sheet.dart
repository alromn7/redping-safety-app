import 'package:flutter/material.dart';
import '../../core/config/stripe_config.dart';
import '../../services/stripe_payment_integration_service.dart';

/// Widget for displaying subscription payment options with Stripe integration
///
/// Shows:
/// - Subscription tier pricing cards
/// - Monthly vs Yearly billing toggle
/// - Savings display for yearly billing
/// - Payment button with Stripe integration
class SubscriptionPaymentSheet extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String? userName;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentCancelled;

  const SubscriptionPaymentSheet({
    super.key,
    required this.userId,
    required this.userEmail,
    this.userName,
    this.onPaymentSuccess,
    this.onPaymentCancelled,
  });

  @override
  State<SubscriptionPaymentSheet> createState() =>
      _SubscriptionPaymentSheetState();
}

class _SubscriptionPaymentSheetState extends State<SubscriptionPaymentSheet> {
  bool _isYearly = false;
  String? _selectedTier;
  bool _isProcessing = false;

  final _stripeService = StripePaymentService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onPaymentCancelled,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Billing period toggle
          _buildBillingPeriodToggle(),
          const SizedBox(height: 24),

          // Subscription tiers
          _buildSubscriptionTier(
            tier: 'essentialPlus',
            name: 'Essential+',
            icon: Icons.shield,
            features: [
              'Automatic crash detection',
              'Medical profile & digital card',
              'Unlimited emergency contacts',
              'Priority response',
            ],
          ),
          const SizedBox(height: 16),
          _buildSubscriptionTier(
            tier: 'pro',
            name: 'Pro',
            icon: Icons.star,
            features: [
              'All Essential+ features',
              'SMS broadcasting',
              'REDP!NG Mode access',
            ],
            popular: true,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionTier(
            tier: 'ultra',
            name: 'Ultra',
            icon: Icons.rocket_launch,
            features: [
              'All Pro features',
              'Gadget integration',
              'Satellite communication',
              'Premium SAR coordination',
            ],
          ),
          const SizedBox(height: 16),
          _buildSubscriptionTier(
            tier: 'family',
            name: 'Family',
            icon: Icons.family_restroom,
            features: [
              'Pro features for 5 members',
              'Family dashboard',
              'Shared emergency contacts',
              'Group location tracking',
            ],
          ),
          const SizedBox(height: 24),

          // Payment button
          if (_selectedTier != null) _buildPaymentButton(),

          // Trial period notice
          const SizedBox(height: 16),
          const Text(
            '14-day free trial • Cancel anytime',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Monthly',
              isSelected: !_isYearly,
              onTap: () => setState(() => _isYearly = false),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Yearly',
              isSelected: _isYearly,
              onTap: () => setState(() => _isYearly = true),
              badge: 'Save ${_getMaxSavingsPercentage()}%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4D4D) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null && isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFFFF4D4D),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTier({
    required String tier,
    required String name,
    required IconData icon,
    required List<String> features,
    bool popular = false,
  }) {
    final pricing = StripeConfig.pricing[tier];
    final price = _isYearly
        ? (pricing != null ? pricing['yearly'] : 0.0)
        : (pricing != null ? pricing['monthly'] : 0.0);
    final billingPeriod = _isYearly ? 'year' : 'month';
    final savings = _isYearly
        ? StripePaymentService.calculateYearlySavings(tier)
        : 0.0;

    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1F1F1F),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4D4D) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFF4D4D)),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (popular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price?.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per $billingPeriod',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isYearly && savings > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Save \$${savings.toStringAsFixed(2)}/year',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildPaymentButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF4D4D),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Start Free Trial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedTier == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _stripeService.processSubscriptionPayment(
        userId: widget.userId,
        tier: _selectedTier!,
        isYearly: _isYearly,
        email: widget.userEmail,
        name: widget.userName,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        widget.onPaymentSuccess?.call();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  int _getMaxSavingsPercentage() {
    return StripeConfig.pricing.values
        .map((pricing) {
          final monthly = pricing['monthly'] ?? 0.0;
          final yearly = pricing['yearly'] ?? 0.0;
          final monthlyTotal = monthly * 12;
          final savings = monthlyTotal - yearly;
          return (savings / monthlyTotal * 100).round();
        })
        .reduce((max, value) => value > max ? value : max);
  }
}
