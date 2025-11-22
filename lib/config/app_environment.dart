class AppEnvironment {
  // Placeholder endpoints; replace with your actual Cloud Function endpoints
  static const String paymentEndpoint = 'https://example.com/api/payment';
  static const String cancelSubscriptionEndpoint =
      'https://example.com/api/cancel-subscription';

  // Toggle Stripe test mode, used by Google Pay init
  static const bool enableStripeTestMode = true;
}
