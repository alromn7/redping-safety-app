import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../models/auth_user.dart' show UserSubscription;

/// Subscription Management Page - View and manage active subscription
class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final PaymentService _paymentService = PaymentService.instance;
  late AnimationController _animationController;

  bool _isLoading = true;
  bool _isCancelling = false;
  UserSubscription? _subscription;
  List<PaymentTransaction> _transactions = [];
  Map<String, dynamic>? _upcomingInvoice;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadSubscriptionData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);

    try {
      await _subscriptionService.initialize();
      await _paymentService.initialize();

      setState(() {
        _subscription = _subscriptionService.currentSubscription;
        _transactions = _paymentService.transactionHistory;
      });

      if (_subscription != null) {
        final invoice = await _paymentService.getUpcomingInvoice(
          'current_user',
        );
        setState(() => _upcomingInvoice = invoice);
      }
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Your subscription will remain active until the end of your billing period. '
          'After that, you\'ll be downgraded to the free plan.\n\n'
          'Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      await _paymentService.cancelSubscription('current_user');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled. Active until period end.'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );

        // Reload data
        await _loadSubscriptionData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling subscription: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Subscription',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                strokeWidth: 2,
              ),
            )
          : _subscription == null
          ? _buildNoSubscriptionView()
          : _buildSubscriptionView(),
    );
  }

  Widget _buildNoSubscriptionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Hero section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 64,
                  color: Colors.amber[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Plan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock premium features',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Feature highlights
          Text(
            'Premium Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureHighlight(
            Icons.family_restroom,
            'Family Protection',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildFeatureHighlight(
            Icons.location_on,
            'Real-time Tracking',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildFeatureHighlight(Icons.emergency, 'Priority SOS', Colors.red),
          const SizedBox(height: 8),
          _buildFeatureHighlight(
            Icons.analytics,
            'Advanced Analytics',
            Colors.blue,
          ),

          const SizedBox(height: 24),

          // CTA Button
          ElevatedButton(
            onPressed: () => context.go('/subscription/plans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Plans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 18),
        ],
      ),
    );
  }

  Widget _buildSubscriptionView() {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact plan header
            _buildCompactPlanHeader(),

            const SizedBox(height: 16),

            // Quick stats
            _buildQuickStatsGrid(),

            const SizedBox(height: 16),

            // Billing info
            if (_upcomingInvoice != null) ...[
              _buildModernBillingSection(),
              const SizedBox(height: 16),
            ],

            // Payment methods
            _buildModernPaymentMethodsSection(),

            const SizedBox(height: 16),

            // Transaction history
            _buildModernTransactionHistory(),

            const SizedBox(height: 16),

            // Actions
            _buildManagementActions(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPlanHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTierColor().withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTierColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getTierIcon(), color: _getTierColor(), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subscription!.plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subscription!.isActive ? 'Active' : 'Cancelled',
                      style: TextStyle(
                        fontSize: 12,
                        color: _subscription!.isActive
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoTile(
                  'Price',
                  '\$${(_subscription!.isYearlyBilling ? _subscription!.plan.yearlyPrice : _subscription!.plan.monthlyPrice).toStringAsFixed(0)}',
                  _subscription!.isYearlyBilling ? '/year' : '/mo',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[800]),
              Expanded(
                child: _buildCompactInfoTile(
                  'Next Bill',
                  _subscription!.renewalDate != null
                      ? _formatDate(_subscription!.renewalDate!)
                      : 'N/A',
                  _getDaysUntilBilling(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoTile(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
      ],
    );
  }

  String _getDaysUntilBilling() {
    if (_subscription!.renewalDate == null) return '';
    final days = _subscription!.renewalDate!.difference(DateTime.now()).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'in $days days';
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Members',
            _subscription!.familyMembers.isNotEmpty
                ? '${_subscription!.familyMembers.length + 1}'
                : '1',
            Icons.people_outline,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Type',
            _subscription!.plan.tier == SubscriptionTier.family
                ? 'Family'
                : 'Solo',
            Icons.security,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Billing',
            _subscription!.isYearlyBilling ? 'Yearly' : 'Monthly',
            Icons.calendar_today,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildModernBillingSection() {
    if (_upcomingInvoice == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Billing',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_upcomingInvoice!['dueDate'] as DateTime?),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '\$${(_upcomingInvoice!['amount'] as double).toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernPaymentMethodsSection() {
    final methods = _paymentService.savedPaymentMethods;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[300],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/subscription/payment-methods'),
              icon: const Icon(Icons.add, size: 16, color: Colors.white70),
              label: const Text(
                'Manage',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (methods.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Center(
              child: Text(
                'No payment methods',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          )
        else
          ...methods.map(
            (method) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: method.isDefault ? Colors.green : Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${method.brand ?? 'Card'} •••• ${method.last4}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (method.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModernTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[300],
              ),
            ),
            if (_transactions.isNotEmpty)
              TextButton(
                onPressed: () => context.push('/subscription/billing-history'),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Center(
              child: Text(
                'No transactions',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Column(
              children: _transactions.take(3).map((transaction) {
                final isSuccess = transaction.status == PaymentStatus.succeeded;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[850]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.tier.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(transaction.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${transaction.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildManagementActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons
        _buildActionButton(
          'Change Plan',
          Icons.swap_horiz,
          () => context.go('/subscription/plans'),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          'Payment Methods',
          Icons.payment,
          () => context.push('/subscription/payment-methods'),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          'Billing History',
          Icons.receipt,
          () => context.push('/subscription/billing-history'),
        ),
        const SizedBox(height: 16),
        // Cancel button
        if (_subscription!.isActive)
          OutlinedButton.icon(
            onPressed: !_isCancelling ? _cancelSubscription : null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1),
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.cancel, size: 18),
            label: Text(
              _isCancelling ? 'Cancelling...' : 'Cancel Subscription',
              style: const TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
          ],
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (_subscription!.plan.tier) {
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

  IconData _getTierIcon() {
    switch (_subscription!.plan.tier) {
      case SubscriptionTier.free:
        return Icons.person;
      case SubscriptionTier.essentialPlus:
        return Icons.shield_outlined;
      case SubscriptionTier.pro:
        return Icons.star;
      case SubscriptionTier.ultra:
        return Icons.diamond;
      case SubscriptionTier.family:
        return Icons.family_restroom;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '\${date.month}/\${date.day}/\${date.year}';
  }
}
