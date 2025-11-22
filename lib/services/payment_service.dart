import 'package:flutter/foundation.dart';
import '../models/subscription_tier.dart';
import '../models/auth_user.dart' as auth show PaymentMethod;
import 'subscription_service.dart';

/// Payment methods supported by RedPing
enum PaymentMethodType { creditCard, debitCard, applePay, googlePay, paypal }

/// Payment status for transactions
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
}

/// Represents a payment method
class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String last4;
  final String? brand; // Visa, Mastercard, etc.
  final int expMonth;
  final int expYear;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    this.brand,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'last4': last4,
    'brand': brand,
    'expMonth': expMonth,
    'expYear': expYear,
    'isDefault': isDefault,
  };

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as String,
    type: PaymentMethodType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => PaymentMethodType.creditCard,
    ),
    last4: json['last4'] as String,
    brand: json['brand'] as String?,
    expMonth: json['expMonth'] as int,
    expYear: json['expYear'] as int,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

/// Represents a payment transaction
class PaymentTransaction {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethodType paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final bool isYearlyBilling;
  final String? paymentMethodId;
  final DateTime? updatedAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.tier,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.isYearlyBilling = false,
    this.paymentMethodId,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'tier': tier.name,
    'amount': amount,
    'currency': currency,
    'status': status.name,
    'paymentMethod': paymentMethod.name,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'isYearlyBilling': isYearlyBilling,
    'paymentMethodId': paymentMethodId,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        id: json['id'] as String,
        userId: json['userId'] as String,
        tier: SubscriptionTier.values.firstWhere((e) => e.name == json['tier']),
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == json['status'],
        ),
        paymentMethod: PaymentMethodType.values.firstWhere(
          (e) => e.name == json['paymentMethod'],
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
        isYearlyBilling: json['isYearlyBilling'] as bool? ?? false,
        paymentMethodId: json['paymentMethodId'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

/// Payment Service - Handles subscription payments and billing
///
/// **IMPORTANT**: This is a mock implementation for development.
/// Production implementation requires:
/// 1. Stripe SDK integration (flutter_stripe package)
/// 2. Firebase Cloud Functions for secure payment processing
/// 3. Webhook handlers for subscription events
/// 4. PCI compliance for card data handling
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  static PaymentService get instance => _instance;

  PaymentService._internal();

  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  // Mock storage for development
  final List<PaymentMethod> _savedPaymentMethods = [];
  final List<PaymentTransaction> _transactionHistory = [];
  PaymentMethod? _defaultPaymentMethod;

  /// Initialize payment service
  Future<void> initialize() async {
    debugPrint('PaymentService: Initializing...');
    // In production: Initialize Stripe SDK
    // await Stripe.instance.initialize(publishableKey: stripePublishableKey);
    await _loadSavedPaymentMethods();
    debugPrint('PaymentService: Initialized successfully');
  }

  /// Get list of saved payment methods
  List<PaymentMethod> get savedPaymentMethods =>
      List.unmodifiable(_savedPaymentMethods);

  /// Get default payment method
  PaymentMethod? get defaultPaymentMethod => _defaultPaymentMethod;

  /// Get transaction history
  List<PaymentTransaction> get transactionHistory =>
      List.unmodifiable(_transactionHistory);

  /// Load saved payment methods from storage
  Future<void> _loadSavedPaymentMethods() async {
    // In production: Load from Firestore or Stripe API
    // For now, mock data for development
    debugPrint('PaymentService: Loading saved payment methods...');
  }

  /// Add a new payment method
  ///
  /// In production, this would:
  /// 1. Collect card details via Stripe Elements
  /// 2. Create payment method via Stripe API
  /// 3. Save payment method ID to Firestore
  /// 4. Return payment method object
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType type,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    bool setAsDefault = false,
  }) async {
    debugPrint('PaymentService: Adding payment method...');

    // Mock implementation for development
    final last4 = cardNumber.length >= 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;

    final paymentMethod = PaymentMethod(
      id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      last4: last4,
      brand: _detectCardBrand(cardNumber),
      expMonth: expMonth,
      expYear: expYear,
      isDefault: setAsDefault || _savedPaymentMethods.isEmpty,
    );

    _savedPaymentMethods.add(paymentMethod);

    if (paymentMethod.isDefault) {
      _defaultPaymentMethod = paymentMethod;
      // Update other methods to not be default
      for (final method in _savedPaymentMethods) {
        if (method.id != paymentMethod.id) {
          _savedPaymentMethods[_savedPaymentMethods.indexOf(
            method,
          )] = PaymentMethod(
            id: method.id,
            type: method.type,
            last4: method.last4,
            brand: method.brand,
            expMonth: method.expMonth,
            expYear: method.expYear,
            isDefault: false,
          );
        }
      }
    }

    debugPrint('PaymentService: Payment method added successfully');
    return paymentMethod;
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    debugPrint('PaymentService: Setting default payment method...');

    final index = _savedPaymentMethods.indexWhere(
      (m) => m.id == paymentMethodId,
    );
    if (index == -1) {
      throw Exception('Payment method not found');
    }

    // Update all methods
    for (int i = 0; i < _savedPaymentMethods.length; i++) {
      final method = _savedPaymentMethods[i];
      _savedPaymentMethods[i] = PaymentMethod(
        id: method.id,
        type: method.type,
        last4: method.last4,
        brand: method.brand,
        expMonth: method.expMonth,
        expYear: method.expYear,
        isDefault: i == index,
      );
    }

    _defaultPaymentMethod = _savedPaymentMethods[index];
    debugPrint('PaymentService: Default payment method updated');
  }

  /// Remove a payment method
  Future<void> removePaymentMethod(String paymentMethodId) async {
    debugPrint('PaymentService: Removing payment method...');

    _savedPaymentMethods.removeWhere((m) => m.id == paymentMethodId);

    if (_defaultPaymentMethod?.id == paymentMethodId) {
      _defaultPaymentMethod = _savedPaymentMethods.isNotEmpty
          ? _savedPaymentMethods.first
          : null;
    }

    debugPrint('PaymentService: Payment method removed');
  }

  /// Process subscription payment
  ///
  /// In production, this would:
  /// 1. Create payment intent via Cloud Function
  /// 2. Confirm payment via Stripe SDK
  /// 3. Handle 3D Secure if required
  /// 4. Update subscription in Firestore
  /// 5. Return transaction result
  Future<PaymentTransaction> processSubscriptionPayment({
    required String userId,
    required SubscriptionTier tier,
    required bool isYearlyBilling,
    String? paymentMethodId,
  }) async {
    debugPrint('PaymentService: Processing subscription payment...');

    // Get plan details
    final plan = _subscriptionService.availablePlans.firstWhere(
      (p) => p.tier == tier,
    );

    final amount = isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;

    // Use provided payment method or default
    final method = paymentMethodId != null
        ? _savedPaymentMethods.firstWhere((m) => m.id == paymentMethodId)
        : _defaultPaymentMethod;

    if (method == null) {
      throw Exception('No payment method available');
    }

    // Create transaction record
    final transaction = PaymentTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      tier: tier,
      amount: amount,
      currency: 'USD',
      status: PaymentStatus.processing,
      paymentMethod: method.type,
      createdAt: DateTime.now(),
      isYearlyBilling: isYearlyBilling,
    );

    _transactionHistory.add(transaction);

    // Mock payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock successful payment (90% success rate for development)
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    final completedTransaction = PaymentTransaction(
      id: transaction.id,
      userId: transaction.userId,
      tier: transaction.tier,
      amount: transaction.amount,
      currency: transaction.currency,
      status: isSuccess ? PaymentStatus.succeeded : PaymentStatus.failed,
      paymentMethod: transaction.paymentMethod,
      createdAt: transaction.createdAt,
      completedAt: DateTime.now(),
      errorMessage: isSuccess ? null : 'Card declined - Insufficient funds',
      isYearlyBilling: transaction.isYearlyBilling,
    );

    // Update transaction in history
    final index = _transactionHistory.indexWhere((t) => t.id == transaction.id);
    _transactionHistory[index] = completedTransaction;

    if (isSuccess) {
      // Update subscription in SubscriptionService
      await _subscriptionService.subscribeToPlan(
        userId: userId,
        tier: tier,
        paymentMethod: auth.PaymentMethod.creditCard,
        isYearlyBilling: isYearlyBilling,
      );
      debugPrint('PaymentService: Payment successful - Subscription activated');
    } else {
      debugPrint(
        'PaymentService: Payment failed - ${completedTransaction.errorMessage}',
      );
    }

    return completedTransaction;
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    debugPrint('PaymentService: Cancelling subscription...');

    // In production: Cancel via Stripe API
    // The subscription will remain active until the end of the billing period

    await _subscriptionService.cancelSubscription();

    debugPrint(
      'PaymentService: Subscription cancelled (effective at period end)',
    );
  }

  /// Get upcoming invoice preview
  Future<Map<String, dynamic>> getUpcomingInvoice(String userId) async {
    debugPrint('PaymentService: Fetching upcoming invoice...');

    // In production: Fetch from Stripe API
    final subscription = _subscriptionService.currentSubscription;

    if (subscription == null) {
      return {'amount': 0.0, 'dueDate': null, 'items': []};
    }

    final amount = subscription.isYearlyBilling
        ? subscription.plan.yearlyPrice
        : subscription.plan.monthlyPrice;

    // Calculate due date - use renewalDate if available, otherwise calculate from start date
    final dueDate =
        subscription.renewalDate ??
        subscription.startDate.add(
          Duration(days: subscription.isYearlyBilling ? 365 : 30),
        );

    return {
      'amount': amount,
      'currency': 'USD',
      'dueDate': dueDate,
      'items': [
        {
          'description': '${subscription.plan.name} Subscription',
          'amount': amount,
        },
      ],
    };
  }

  /// Detect card brand from card number
  String? _detectCardBrand(String cardNumber) {
    final cleaned = cardNumber.replaceAll(' ', '');
    if (cleaned.startsWith('4')) return 'Visa';
    if (cleaned.startsWith(RegExp(r'^5[1-5]'))) return 'Mastercard';
    if (cleaned.startsWith(RegExp(r'^3[47]'))) return 'Amex';
    if (cleaned.startsWith('6')) return 'Discover';
    return 'Unknown';
  }

  /// Clear all payment data (for testing)
  void clear() {
    _savedPaymentMethods.clear();
    _transactionHistory.clear();
    _defaultPaymentMethod = null;
  }
}
