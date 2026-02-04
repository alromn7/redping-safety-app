import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app/app_launch_config.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../../../../core/theme/app_theme.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../models/subscription_plan.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/subscription_service.dart';

/// Payment page for processing subscription payments
class PaymentPage extends StatefulWidget {
  final SubscriptionTier tier;
  final bool isYearlyBilling;

  const PaymentPage({
    super.key,
    required this.tier,
    this.isYearlyBilling = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final PaymentService _paymentService = PaymentService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  bool _isProcessing = false;
  bool _savePaymentMethod = true;
  bool _isInitializing = true;
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _initializePaymentPage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializePaymentPage() async {
    try {
      // Initialize PaymentService first (this sets up Stripe PaymentConfiguration)
      await _paymentService.initialize();
      _loadPlanDetails();
    } catch (e) {
      debugPrint('❌ Failed to initialize payment page: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showErrorDialog(
            'Payment system initialization failed. Please try again.',
          );
          Navigator.of(context).pop();
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _loadPlanDetails() {
    try {
      _selectedPlan = _subscriptionService.availablePlans.firstWhere(
        (plan) => plan.tier == widget.tier,
      );
    } catch (e) {
      debugPrint('❌ Failed to load plan for tier ${widget.tier}: $e');
      // If plan not found, show error and go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showErrorDialog('Plan not available. Please try again.');
          Navigator.of(context).pop();
        }
      });
    }
    setState(() {});
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate cardholder name
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter cardholder name');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create token from CardField (CardField must be present in the form)
      // CardField automatically provides card data to Stripe SDK
      final tokenData = await stripe.Stripe.instance.createToken(
        const stripe.CreateTokenParams.card(params: stripe.CardTokenParams()),
      );

      // Create payment method from token
      final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
        params: stripe.PaymentMethodParams.cardFromToken(
          paymentMethodData: stripe.PaymentMethodDataCardFromToken(
            token: tokenData.id,
          ),
        ),
      );

      if (!mounted) return;

      // Process payment
      final transaction = await _paymentService.processSubscriptionPayment(
        userId: 'current_user', // In production: get from auth service
        tier: widget.tier,
        isYearlyBilling: widget.isYearlyBilling,
        paymentMethodId: paymentMethod.id,
      );

      if (!mounted) return;

      if (transaction.status == PaymentStatus.succeeded) {
        // Show success dialog
        await _showSuccessDialog();

        // Navigate back to profile or main
        if (mounted) {
          context.go(AppLaunchConfig.homeRoute);
        }
      } else {
        // Show error dialog
        _showErrorDialog(
          transaction.errorMessage ?? 'Payment failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ${_selectedPlan?.name}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your subscription has been activated and all premium features are now unlocked.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s Next:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Explore your new features'),
                  const Text('• Update your profile'),
                  const Text('• Configure safety settings'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeGreen,
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: AppTheme.criticalRed),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing Stripe or loading plan
    if (_isInitializing || _selectedPlan == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing payment system...'),
            ],
          ),
        ),
      );
    }

    final amount = widget.isYearlyBilling
        ? _selectedPlan!.yearlyPrice
        : _selectedPlan!.monthlyPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary
              Card(
                color: AppTheme.infoBlue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: AppTheme.infoBlue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedPlan!.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isYearlyBilling
                            ? 'Billed annually'
                            : 'Billed monthly',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Due Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.infoBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment method section
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Cardholder name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Stripe CardField widget (collects card number, expiry, CVC securely)
              stripe.CardField(
                onCardChanged: (card) {
                  // Card data is automatically captured by Stripe SDK
                  // No need to manually store it
                },
                enablePostalCode: false,
                decoration: const InputDecoration(
                  labelText: 'Card Information',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Save payment method checkbox
              CheckboxListTile(
                value: _savePaymentMethod,
                onChanged: _isProcessing
                    ? null
                    : (value) => setState(() => _savePaymentMethod = value!),
                title: const Text('Save payment method for future use'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              // Security notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neutralGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.neutralGray.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 20, color: AppTheme.neutralGray),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment information is encrypted and secure. We never store your full card details.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Pay button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safeGreen,
                    disabledBackgroundColor: AppTheme.neutralGray,
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing Payment...'),
                          ],
                        )
                      : Text(
                          'Pay \$${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isProcessing ? null : () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
