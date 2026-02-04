import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_tier.dart';
import '../models/auth_user.dart' as auth show PaymentMethod;
import '../core/config/stripe_config.dart';
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
    debugPrint(
      'PaymentService: Initializing Stripe (${StripeConfig.isTestMode ? 'TEST' : 'LIVE'} mode)...',
    );
    await StripeConfig.initialize();

    // Initialize Stripe SDK with proper PaymentConfiguration
    // This MUST be done before any Stripe UI widgets (like CardField) are created
    Stripe.publishableKey = StripeConfig.publishableKey;
    Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
    Stripe.urlScheme = StripeConfig.urlScheme;

    // Apply settings to initialize PaymentConfiguration internally
    await Stripe.instance.applySettings();

    debugPrint('PaymentService: Stripe PaymentConfiguration initialized');

    await _loadSavedPaymentMethods();
    debugPrint('PaymentService: Stripe initialized successfully');
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

  /// Add a new payment method using Stripe SDK
  /// NOTE: This method requires Stripe CardField widget to collect card details
  /// The cardNumber, expMonth, expYear, cvc parameters are kept for API compatibility
  /// but the actual card data must be collected via Stripe's CardField widget
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType type,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    bool setAsDefault = false,
  }) async {
    debugPrint('PaymentService: Adding payment method via Stripe...');

    try {
      // Create payment method using Stripe SDK
      // This will use the card details from Stripe's CardField widget
      final billingDetails = BillingDetails();

      final paymentMethodParams = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(billingDetails: billingDetails),
      );

      // Create payment method with Stripe
      // This requires that card details were collected via CardField widget
      final stripePaymentMethod = await Stripe.instance.createPaymentMethod(
        params: paymentMethodParams,
      );

      final last4 = stripePaymentMethod.card.last4 ?? '****';
      final brand = stripePaymentMethod.card.brand ?? 'Unknown';

      final paymentMethod = PaymentMethod(
        id: stripePaymentMethod.id,
        type: type,
        last4: last4,
        brand: brand,
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
    } catch (e) {
      debugPrint('PaymentService: Error adding payment method: $e');
      rethrow;
    }
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

  /// Process subscription payment via Stripe Cloud Function
  Future<PaymentTransaction> processSubscriptionPayment({
    required String userId,
    required SubscriptionTier tier,
    required bool isYearlyBilling,
    String? paymentMethodId,
  }) async {
    debugPrint('PaymentService: Processing subscription payment...');

    try {
      // Get plan details
      final plan = _subscriptionService.availablePlans.firstWhere(
        (p) => p.tier == tier,
      );

      final amount = isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;

      // Validate payment method ID is provided
      if (paymentMethodId == null || paymentMethodId.isEmpty) {
        throw Exception('No payment method available');
      }

      // Create transaction record
      final transaction = PaymentTransaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        tier: tier,
        amount: amount,
        currency: 'AUD',
        status: PaymentStatus.processing,
        paymentMethod: PaymentMethodType.creditCard, // Card payment
        createdAt: DateTime.now(),
        isYearlyBilling: isYearlyBilling,
      );

      _transactionHistory.add(transaction);

      // Check if user is properly authenticated (not anonymous)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        throw Exception(
          'Payment requires email/password authentication. '
          'Anonymous users cannot make payments. '
          'Please sign in with email and password.',
        );
      }

      debugPrint(
        'PaymentService: Calling Cloud Function with paymentMethodId: $paymentMethodId',
      );
      debugPrint(
        'PaymentService: User authenticated - uid: ${user.uid}, email: ${user.email}',
      );

      // Get fresh ID token to ensure authentication
      final idToken = await user.getIdToken();
      debugPrint(
        'PaymentService: ID Token obtained: ${idToken?.substring(0, 20)}...',
      );

      // Call Firebase Cloud Function to process payment
      // Using us-central1 region (default) - match your Cloud Function deployment region
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('processSubscriptionPayment')
          .call({
            'userId': user.uid,
            'paymentMethodId': paymentMethodId,
            'tier': tier.name,
            // Amount & currency are determined by Stripe Price IDs server-side; client fields retained for trace/debug only.
            'amount': amount,
            'currency': 'AUD',
            'isYearlyBilling': isYearlyBilling,
            'savePaymentMethod': true,
          });

      debugPrint('PaymentService: Cloud Function response: ${result.data}');

      if (StripeConfig.isTestMode &&
          StripeConfig.publishableKey.startsWith('pk_live_')) {
        debugPrint(
          'WARNING: Live publishable key detected during test mode payment processing.',
        );
      }

      final data = result.data as Map<String, dynamic>;
      final isSuccess = data['success'] == true;

      final completedTransaction = PaymentTransaction(
        id: data['subscriptionId'] as String? ?? transaction.id,
        userId: transaction.userId,
        tier: transaction.tier,
        amount: transaction.amount,
        currency: transaction.currency,
        status: isSuccess ? PaymentStatus.succeeded : PaymentStatus.failed,
        paymentMethod: transaction.paymentMethod,
        createdAt: transaction.createdAt,
        completedAt: DateTime.now(),
        errorMessage: isSuccess ? null : data['error'] as String?,
        isYearlyBilling: transaction.isYearlyBilling,
      );

      // Update transaction in history
      final index = _transactionHistory.indexWhere(
        (t) => t.id == transaction.id,
      );
      _transactionHistory[index] = completedTransaction;

      if (isSuccess) {
        // Update subscription in SubscriptionService
        await _subscriptionService.subscribeToPlan(
          userId: userId,
          tier: tier,
          paymentMethod: auth.PaymentMethod.creditCard,
          isYearlyBilling: isYearlyBilling,
        );
        debugPrint(
          'PaymentService: Payment successful - Subscription activated',
        );
      } else {
        debugPrint(
          'PaymentService: Payment failed - ${completedTransaction.errorMessage}',
        );
      }

      return completedTransaction;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'PaymentService: Firebase Functions error: ${e.code} - ${e.message}',
      );
      debugPrint('PaymentService: Error details: ${e.details}');

      // Update transaction status to failed
      final failedTransaction = PaymentTransaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        tier: tier,
        amount: 0.0,
        currency: 'AUD',
        status: PaymentStatus.failed,
        paymentMethod: PaymentMethodType.creditCard,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        errorMessage: 'Firebase error: ${e.code} - ${e.message}',
        isYearlyBilling: isYearlyBilling,
      );

      _transactionHistory.add(failedTransaction);
      return failedTransaction;
    } catch (e) {
      debugPrint('PaymentService: Error processing payment: $e');

      // Update transaction status to failed
      final failedTransaction = PaymentTransaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        tier: tier,
        amount: 0.0,
        currency: 'AUD',
        status: PaymentStatus.failed,
        paymentMethod: PaymentMethodType.creditCard,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
        isYearlyBilling: isYearlyBilling,
      );

      _transactionHistory.add(failedTransaction);
      rethrow;
    }
  }

  /// Cancel subscription via Stripe Cloud Function
  Future<void> cancelSubscription(String userId, String subscriptionId) async {
    debugPrint('PaymentService: Cancelling subscription $subscriptionId...');

    try {
      // Call Cloud Function to cancel subscription
      final callable = FirebaseFunctions.instance.httpsCallable(
        'cancelSubscription',
      );

      await callable.call({'userId': userId, 'subscriptionId': subscriptionId});

      // Update local subscription state
      await _subscriptionService.cancelSubscription();

      debugPrint(
        'PaymentService: Subscription cancelled (effective at period end)',
      );
    } catch (e) {
      debugPrint('PaymentService: Error cancelling subscription: $e');
      rethrow;
    }
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
      'currency': 'AUD',
      'dueDate': dueDate,
      'items': [
        {
          'description': '${subscription.plan.name} Subscription',
          'amount': amount,
        },
      ],
    };
  }

  /// Clear all payment data (for testing)
  void clear() {
    _savedPaymentMethods.clear();
    _transactionHistory.clear();
    _defaultPaymentMethod = null;
  }
}
