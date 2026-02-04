import 'subscription_service.dart';
import 'feature_access_service.dart';

class LocalSubscriptionService implements SubscriptionServiceCore, FeatureAccessServiceCore {
  String _tier;

  LocalSubscriptionService({String tier = 'pro'}) : _tier = tier;

  void setTier(String tier) {
    _tier = tier;
  }

  Map<String, dynamic> _limitsForTier(String tier) {
    // Simple mock limits mapping. Adjust as needed.
    switch (tier) {
      case 'free':
        return {
          'acfd': false,
          'hazardAlerts': false,
          'sosSMS': false,
          'sarParticipation': false,
          'sarVolunteerRegistration': false,
          'sarTeamManagement': false,
          'sarMissionCoordination': false,
          'sarAnalytics': false,
          'multiTeamCoordination': false,
        };
      case 'essential+':
        return {
          'acfd': true,
          'hazardAlerts': true,
          'sosSMS': true,
          'medicalProfile': true,
          'sarParticipation': false,
          'sarVolunteerRegistration': false,
          'sarTeamManagement': false,
          'sarMissionCoordination': false,
          'sarAnalytics': false,
          'multiTeamCoordination': false,
        };
      case 'pro':
      case 'org':
        return {
          'acfd': true,
          'hazardAlerts': true,
          'sosSMS': true,
          'medicalProfile': true,
          'redpingMode': true,
          'gadgetIntegration': true,
          'sarParticipation': true,
          'sarVolunteerRegistration': true,
          'sarTeamManagement': false,
          'sarMissionCoordination': true,
          'sarAnalytics': false,
          'multiTeamCoordination': false,
        };
      default:
        return {
          'acfd': false,
          'hazardAlerts': false,
          'sosSMS': false,
          'sarParticipation': false,
          'sarTeamManagement': false,
        };
    }
  }

  @override
  SubscriptionPlanLimits get currentPlanLimits => SubscriptionPlanLimits(_limitsForTier(_tier));

  @override
  bool hasFeatureAccess(String key) => currentPlanLimits.has(key);
}
