# Shared Core Migration Plan

## Goal
Move common services/models/utilities from the main system into `packages/shared_core` to reduce duplication across Emergency and SAR apps.

## Phases
- Phase 1 (interfaces): ensure abstract interfaces exist for key services/models (done)
- Phase 2 (adapters): add thin adapters in apps to use shared interfaces without functional changes
- Phase 3 (incremental migration): move implementations into shared_core; update imports in apps
- Phase 4 (cleanup): remove duplicated code; consolidate tests

## Candidates (initial)
- Services: Auth, Profile, Contacts, Notification, Location, EmergencyMessaging, FeatureAccess, Subscription
- Models: SOSSession, SARIdentity, SubscriptionPlan
- Utilities: Env/feature flags, secure storage, crypto utils

## Non-shared (remain in apps)
- Emergency: Sensor/ACFD pipeline, verification UI, hazard alerts
- SAR: Org/team services, SAR messaging specifics, dashboards

## Steps
1. Add app adapters that implement shared interfaces while delegating to existing services
2. Migrate models and pure utils first (low risk)
3. Migrate services one by one, starting with `FeatureAccessService` and `SubscriptionService`
4. Update imports in apps to point to `shared_core`
5. Keep CI green; run analyze/tests after each migration

## Risks
- Import churn; mitigate via adapters and phased updates
- Hidden deps; audit and extract only common logic

## Acceptance
- Apps compile and pass tests with shared_core providing common services
- No functional regressions
