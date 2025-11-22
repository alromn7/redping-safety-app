// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
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

  void _showAddPaymentMethodDialog() {
    final cardNumberController = TextEditingController();
    final cardholderNameController = TextEditingController();
    final expMonthController = TextEditingController();
    final expYearController = TextEditingController();
    final cvcController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment Method'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: '1234 5678 9012 3456',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter card number';
                      }
                      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length < 13 || digitsOnly.length > 16) {
                        return 'Invalid card number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cardholderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter cardholder name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: expMonthController,
                          decoration: const InputDecoration(
                            labelText: 'MM',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'MM';
                            }
                            final month = int.tryParse(value);
                            if (month == null || month < 1 || month > 12) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: expYearController,
                          decoration: const InputDecoration(labelText: 'YY'),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'YY';
                            }
                            final year = int.tryParse(value);
                            if (year == null) {
                              return 'Invalid';
                            }
                            final currentYear = DateTime.now().year % 100;
                            if (year < currentYear) {
                              return 'Expired';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: cvcController,
                          decoration: const InputDecoration(
                            labelText: 'CVC',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CVC';
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
                ],
              ),
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
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isProcessing = true);

                      try {
                        final cardNumber = cardNumberController.text.replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        final expMonth = int.parse(expMonthController.text);
                        final expYear = int.parse(expYearController.text);

                        await _paymentService.addPaymentMethod(
                          type: PaymentMethodType.creditCard,
                          cardNumber: cardNumber,
                          expMonth: expMonth,
                          expYear: expYear,
                          cvc: cvcController.text,
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
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding payment method: $e'),
                              backgroundColor: AppTheme.criticalRed,
                            ),
                          );
                        }
                      } finally {
                        setDialogState(() => isProcessing = false);
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
