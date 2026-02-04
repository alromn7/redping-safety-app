class SubscriptionPlanLimits {
  final Map<String, dynamic> limits;
  const SubscriptionPlanLimits(this.limits);

  bool has(String key) => limits[key] == true;
}

abstract class SubscriptionServiceCore {
  SubscriptionPlanLimits get currentPlanLimits;
}
