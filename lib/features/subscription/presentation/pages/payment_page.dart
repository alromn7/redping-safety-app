import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  final _cardNumberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();

  final PaymentService _paymentService = PaymentService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  bool _isProcessing = false;
  bool _savePaymentMethod = true;
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _loadPlanDetails() {
    _selectedPlan = _subscriptionService.availablePlans.firstWhere(
      (plan) => plan.tier == widget.tier,
    );
    setState(() {});
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Add payment method
      final paymentMethod = await _paymentService.addPaymentMethod(
        type: PaymentMethodType.creditCard,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expMonth: int.parse(_expMonthController.text),
        expYear: int.parse('20${_expYearController.text}'),
        cvc: _cvcController.text,
        setAsDefault: _savePaymentMethod,
      );

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
          context.go('/main');
        }
      } else {
        // Show error dialog
        _showErrorDialog(
          transaction.errorMessage ?? 'Payment failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: $e');
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
    if (_selectedPlan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

              // Card number
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  final cleaned = value.replaceAll(' ', '');
                  if (cleaned.length < 13 || cleaned.length > 16) {
                    return 'Invalid card number';
                  }
                  return null;
                },
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

              // Expiry and CVC
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expMonthController,
                      decoration: const InputDecoration(
                        labelText: 'Exp Month',
                        hintText: 'MM',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final month = int.tryParse(value);
                        if (month == null || month < 1 || month > 12) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _expYearController,
                      decoration: const InputDecoration(
                        labelText: 'Exp Year',
                        hintText: 'YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final year = int.tryParse('20$value');
                        if (year == null || year < DateTime.now().year) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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

/// Card number formatter to add spaces every 4 digits
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
