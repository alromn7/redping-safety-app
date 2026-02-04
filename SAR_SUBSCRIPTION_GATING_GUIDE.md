# SAR Subscription Gating Guide (Planning)

## Goals
- Gate SAR features by tiers with clear, enforceable checks in shared core.

## Entitlements & Flags
- Entitlement keys (examples):
  - `sarParticipation` (Member)
  - `sarTeamManagement` (Coordinator/Admin)
  - `orgCapacity` (limits)

## FeatureAccessService Examples
```dart
// Pseudocode illustrating checks — do not execute
class FeatureAccessService {
  bool hasFeatureAccess(String key) {
    final limits = SubscriptionService.instance.currentPlanLimits;
    return limits[key] == true;
  }

  Future<String> getSARAccessLevel() async {
    final limits = SubscriptionService.instance.currentPlanLimits;
    if (limits['sarTeamManagement'] == true) return 'coordinator';
    if (limits['sarParticipation'] == true) return 'member';
    return 'observer';
  }
}
```

## Usage Patterns
- At app init (SAR app): prevent SensorService start; enable SAR services only if `sarParticipation`.
- For admin screens: require `sarTeamManagement`.
- For org growth features: check `orgCapacity` before adding members/teams.

## UI Gating
- Display role-based navigation: observer → read-only; member → incidents/messages; coordinator → team/org admin.
- Show upgrade prompts when actions exceed entitlement.

## Stripe Mapping
- Observer → free/low-cost plan
- Member → paid plan with participation
- Coordinator → higher tier with management
- Ultra/Org Admin → org-wide billing features

## Testing
- Unit tests: `hasFeatureAccess('sarParticipation')` true/false per plan.
- Integration: role navigation visibility; attempted admin actions blocked without entitlement.
