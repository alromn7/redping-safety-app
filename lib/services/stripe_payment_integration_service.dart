import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/config/stripe_config.dart';

/// Service for managing Stripe payment processing
///
/// Handles:
/// - Creating payment intents
/// - Presenting payment sheets
/// - Processing one-time payments
/// - Managing payment methods
/// - Payment confirmation
class StripePaymentService {
  static final StripePaymentService _instance =
      StripePaymentService._internal();
  factory StripePaymentService() => _instance;
  StripePaymentService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process subscription payment via Stripe
  ///
  /// This method:
  /// 1. Creates a payment intent via Cloud Function
  /// 2. Shows Stripe payment sheet
  /// 3. Processes payment
  /// 4. Creates subscription via Cloud Function
  ///
  /// Parameters:
  /// - [userId]: Firebase user ID
  /// - [tier]: Subscription tier (essentialPlus, pro, ultra, family)
  /// - [isYearly]: Whether to use yearly billing
  /// - [email]: User's email address
  /// - [name]: User's display name (optional)
  ///
  /// Returns payment result with subscription details
  Future<Map<String, dynamic>> processSubscriptionPayment({
    required String userId,
    required String tier,
    required bool isYearly,
    required String email,
    String? name,
  }) async {
    try {
      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Processing subscription payment');
        debugPrint('  User: $userId');
        debugPrint('  Tier: $tier');
        debugPrint('  Billing: ${isYearly ? "Yearly" : "Monthly"}');
        debugPrint('  Email: $email');
      }

      // Get price ID
      final priceId = StripeConfig.getPriceId(tier, isYearly);
      if (priceId == null) {
        throw Exception('Price ID not found for tier: $tier');
      }

      if (priceId.contains('REPLACE_WITH_REAL')) {
        throw Exception(
          'Yearly price IDs not configured. Please create yearly prices in Stripe Dashboard.',
        );
      }

      // Show payment sheet and collect payment method
      final paymentMethod = await _showPaymentSheet(
        userId: userId,
        tier: tier,
        isYearly: isYearly,
        priceId: priceId,
        email: email,
      );

      if (paymentMethod == null) {
        return {'success': false, 'error': 'Payment cancelled by user'};
      }

      // Call Cloud Function to create subscription
      final callable = _functions.httpsCallable('processSubscriptionPayment');
      final result = await callable.call({
        'userId': userId,
        'tier': tier,
        'isYearly': isYearly,
        'paymentMethodId': paymentMethod.id,
        'savePaymentMethod': true,
      });

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Subscription created successfully');
        debugPrint('  Subscription ID: ${result.data['subscriptionId']}');
        debugPrint('  Status: ${result.data['status']}');
      }

      return {
        'success': true,
        'subscriptionId': result.data['subscriptionId'],
        'status': result.data['status'],
        'renewalDate': result.data['renewalDate'],
      };
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'StripePaymentService: Cloud Function error - ${e.code}: ${e.message}',
      );
      return {
        'success': false,
        'error': 'Payment processing failed: ${e.message}',
      };
    } on StripeException catch (e) {
      debugPrint(
        'StripePaymentService: Stripe error - ${e.error.code}: ${e.error.message}',
      );
      return {
        'success': false,
        'error':
            'Payment failed: ${e.error.localizedMessage ?? e.error.message}',
      };
    } catch (e) {
      debugPrint('StripePaymentService: Unexpected error - $e');
      return {'success': false, 'error': 'Payment failed: $e'};
    }
  }

  /// Show Stripe payment sheet to collect payment method
  Future<PaymentMethod?> _showPaymentSheet({
    required String userId,
    required String tier,
    required bool isYearly,
    required String priceId,
    required String email,
  }) async {
    try {
      // Create payment intent via Cloud Function
      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Creating payment intent');
      }

      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call({
        'userId': userId,
        'priceId': priceId,
        'tier': tier,
        'isYearly': isYearly,
        'email': email,
      });

      final paymentIntentClientSecret = result.data['clientSecret'] as String;
      final customerId = result.data['customerId'] as String;
      final ephemeralKey = result.data['ephemeralKey'] as String;

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Payment intent created');
        debugPrint('  Customer ID: $customerId');
      }

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: StripeConfig.merchantDisplayName,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          paymentIntentClientSecret: paymentIntentClientSecret,
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'AU'),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'AU',
            testEnv: kDebugMode,
          ),
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFFF4D4D), // RedPing red
              background: Color(0xFF1A1A1A),
            ),
          ),
          allowsDelayedPaymentMethods: true,
        ),
      );

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Presenting payment sheet');
      }

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Payment completed');
      }

      // Payment successful
      // The payment method is managed by Stripe on the server side
      return null;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('StripePaymentService: Payment cancelled by user');
        return null;
      }
      debugPrint('StripePaymentService: Stripe error - ${e.error.code}');
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'StripePaymentService: Function error - ${e.code}: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('StripePaymentService: Unexpected error - $e');
      rethrow;
    }
  }

  /// Update payment method for existing subscription
  Future<bool> updatePaymentMethod(String userId) async {
    try {
      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Updating payment method for $userId');
      }

      // Get customer ID from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      final customerId = data?['stripeCustomerId'] as String?;

      if (customerId == null) {
        throw Exception('No Stripe customer found for user');
      }

      // Create setup intent for new payment method
      final callable = _functions.httpsCallable('createSetupIntent');
      final result = await callable.call({
        'userId': userId,
        'customerId': customerId,
      });

      final clientSecret = result.data['clientSecret'] as String;
      final ephemeralKey = result.data['ephemeralKey'] as String;

      // Initialize payment sheet for setup
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: StripeConfig.merchantDisplayName,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          setupIntentClientSecret: clientSecret,
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'AU'),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'AU',
            testEnv: kDebugMode,
          ),
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFFF4D4D),
              background: Color(0xFF1A1A1A),
            ),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Payment method updated');
      }

      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('StripePaymentService: Payment method update cancelled');
        return false;
      }
      debugPrint('StripePaymentService: Update error - ${e.error.code}');
      return false;
    } catch (e) {
      debugPrint('StripePaymentService: Error updating payment method - $e');
      return false;
    }
  }

  /// Get subscription status from Firestore
  Future<Map<String, dynamic>?> getSubscriptionStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      final subscription = data?['subscription'] as Map<String, dynamic>?;

      if (subscription == null) return null;

      return {
        'tier': subscription['tier'],
        'status': subscription['status'],
        'isActive': subscription['isActive'] ?? false,
        'currentPeriodEnd': (subscription['currentPeriodEnd'] as Timestamp?)
            ?.toDate()
            .toIso8601String(),
        'isYearlyBilling': subscription['isYearlyBilling'] ?? false,
        'autoRenew': subscription['autoRenew'] ?? true,
      };
    } catch (e) {
      debugPrint('StripePaymentService: Error fetching subscription - $e');
      return null;
    }
  }

  /// Cancel subscription at period end
  Future<bool> cancelSubscription(String userId) async {
    try {
      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Cancelling subscription for $userId');
      }

      final callable = _functions.httpsCallable('cancelSubscription');
      await callable.call({'userId': userId});

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Subscription cancelled');
      }

      return true;
    } catch (e) {
      debugPrint('StripePaymentService: Error cancelling subscription - $e');
      return false;
    }
  }

  /// Reactivate cancelled subscription
  Future<bool> reactivateSubscription(String userId) async {
    try {
      if (StripeConfig.enableLogging) {
        debugPrint(
          'StripePaymentService: Reactivating subscription for $userId',
        );
      }

      final callable = _functions.httpsCallable('reactivateSubscription');
      await callable.call({'userId': userId});

      if (StripeConfig.enableLogging) {
        debugPrint('StripePaymentService: Subscription reactivated');
      }

      return true;
    } catch (e) {
      debugPrint('StripePaymentService: Error reactivating subscription - $e');
      return false;
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'],
          'tier': data['tier'],
          'amount': data['amount'],
          'status': data['status'],
          'timestamp': (data['timestamp'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
        };
      }).toList();
    } catch (e) {
      debugPrint('StripePaymentService: Error fetching payment history - $e');
      return [];
    }
  }

  /// Calculate savings for yearly billing
  static double calculateYearlySavings(String tier) {
    final pricing = StripeConfig.pricing[tier];
    if (pricing == null) return 0.0;

    final monthly = pricing['monthly'] ?? 0.0;
    final yearly = pricing['yearly'] ?? 0.0;

    final monthlyTotal = monthly * 12;
    return monthlyTotal - yearly;
  }

  /// Get discount percentage for yearly billing
  static int getYearlyDiscountPercentage(String tier) {
    final pricing = StripeConfig.pricing[tier];
    if (pricing == null) return 0;

    final monthly = pricing['monthly'] ?? 0.0;
    final yearly = pricing['yearly'] ?? 0.0;

    final monthlyTotal = monthly * 12;
    final savings = monthlyTotal - yearly;
    final percentage = (savings / monthlyTotal * 100).round();

    return percentage;
  }
}
