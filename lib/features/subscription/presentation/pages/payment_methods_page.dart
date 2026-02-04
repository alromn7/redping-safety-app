// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/payment_service.dart';

/// Payment Methods Management Page
class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final PaymentService _paymentService = PaymentService.instance;

  bool _isLoading = true;
  List<PaymentMethod> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);

    try {
      await _paymentService.initialize();
      setState(() {
        _paymentMethods = _paymentService.savedPaymentMethods;
      });
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultPaymentMethod(String methodId) async {
    try {
      await _paymentService.setDefaultPaymentMethod(methodId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );

        await _loadPaymentMethods();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating default method: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  Future<void> _removePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method?'),
        content: Text(
          'Are you sure you want to remove ${method.brand ?? 'this card'} ending in ${method.last4}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _paymentService.removePaymentMethod(method.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method removed'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );

        await _loadPaymentMethods();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing payment method: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  Future<void> _showAddPaymentMethodDialog() async {
    bool isProcessing = false;
    bool isCardComplete = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment Method'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your card details',
                  style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 16),
                // Stripe CardField widget (simpler, directly integrates with SDK)
                stripe.CardField(
                  onCardChanged: (card) {
                    setDialogState(() {
                      isCardComplete = card?.complete ?? false;
                    });
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.neutralGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.neutralGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.infoBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secured by Stripe',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (!isCardComplete || isProcessing)
                  ? null
                  : () async {
                      setDialogState(() => isProcessing = true);

                      try {
                        debugPrint('Creating token from CardField data...');

                        // Create token first (CardField automatically provides card data to SDK)
                        final tokenData = await stripe.Stripe.instance
                            .createToken(
                              const stripe.CreateTokenParams.card(
                                params: stripe.CardTokenParams(),
                              ),
                            );

                        debugPrint(
                          'Token created successfully: ${tokenData.id}',
                        );

                        // Create payment method from token
                        final paymentMethod = await stripe.Stripe.instance
                            .createPaymentMethod(
                              params: stripe.PaymentMethodParams.cardFromToken(
                                paymentMethodData:
                                    stripe.PaymentMethodDataCardFromToken(
                                      token: tokenData.id,
                                    ),
                              ),
                            );

                        debugPrint(
                          'Payment method created: ${paymentMethod.id}',
                        );

                        // Save to local service
                        await _paymentService.addPaymentMethod(
                          type: PaymentMethodType.creditCard,
                          cardNumber: paymentMethod.card.last4 ?? '****',
                          expMonth: paymentMethod.card.expMonth ?? 1,
                          expYear: paymentMethod.card.expYear ?? 2025,
                          cvc: '***',
                          setAsDefault: true,
                        );

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment method added successfully',
                              ),
                              backgroundColor: AppTheme.safeGreen,
                            ),
                          );
                          await _loadPaymentMethods();
                        }
                      } catch (e) {
                        debugPrint('Error adding payment method: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppTheme.criticalRed,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isProcessing = false);
                        }
                      }
                    },
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Card'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentMethodDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
        backgroundColor: AppTheme.infoBlue,
      ),
    );
  }

  Widget _buildContent() {
    if (_paymentMethods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.credit_card_outlined,
                size: 80,
                color: AppTheme.neutralGray,
              ),
              const SizedBox(height: 24),
              const Text(
                'No Payment Methods',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Add a payment method to manage your subscriptions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        return _buildPaymentMethodCard(method);
      },
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCardIcon(method.brand),
                    color: AppTheme.infoBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.brand ?? 'Card',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (method.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.safeGreen.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: AppTheme.safeGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• •••• •••• ${method.last4}',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Expires ${method.expMonth}/${method.expYear}',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'default') {
                      _setDefaultPaymentMethod(method.id);
                    } else if (value == 'remove') {
                      _removePaymentMethod(method);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!method.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppTheme.criticalRed,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Remove',
                            style: TextStyle(color: AppTheme.criticalRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String? brand) {
    if (brand == null) return Icons.credit_card;

    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}
