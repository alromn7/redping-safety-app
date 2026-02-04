class SubscriptionPlanCore {
  final String tier; // free, essential+, pro, family
  final Map<String, dynamic> limits;

  const SubscriptionPlanCore({
    required this.tier,
    required this.limits,
  });
}
