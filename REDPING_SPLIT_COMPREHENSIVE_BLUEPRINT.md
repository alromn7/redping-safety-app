# RedPing Split Architecture Blueprint (Emergency vs SAR)

## Goals
- Lightweight, purpose-built apps with minimal background footprint.
- Clear separation of consumer safety (Emergency) and professional operations (SAR).
- Shared core to avoid duplication and simplify maintenance.
- Straightforward build, release, and compliance paths for each product.

## Product Scopes
- RedPing Emergency: ACFD, SOS flows, hazard alerts, emergency contacts, medical profile, SMS alerts.
- RedPing SAR: SAR identity, team/org management, operations dashboard, SAR messaging, incident coordination.

## Monorepo Structure
- apps/
  - redping_emergency/ (Flutter app: consumer safety)
  - redping_sar/ (Flutter app: SAR ops center)
- packages/
  - shared_core/ (Dart package: services, models, UI components)
  - shared_ui/ (optional package: theming, widgets)
- tools/
  - ci/ (pipelines, scripts)

## Shared Core (packages/shared_core)
- Services: `AuthService`, `ProfileService`, `ContactsService`, `NotificationService`, `LocationService`, `EmergencyMessagingService`, `Transport`, `GoogleCloudApiService`, `SecureStorageService`.
- Models: `SOSSession`, `SARIdentity`, `SubscriptionPlan`, enums.
- Feature Access: `SubscriptionService`, `FeatureAccessService` (entitlements: `acfd`, `sarParticipation`, `sarTeamManagement`, `hazardAlerts`, `sosSms`).
- Common utilities: logging, env, routing primitives, error handling.

## Emergency App (apps/redping_emergency)
- Entry: `main_emergency.dart` → registers `AppServiceManager` with Emergency variant.
- Services used: `SensorService` (ACFD), `SOSService`, `HazardAlertService`, `EmergencyMessagingService`.
- Gating: `acfd` unlocks auto detection; free tier manual SOS only.
- Background policy: minimal; foreground service only during verification/SOS.
- UI: SOS screen, verification dialog, contacts, hazard alerts.

## SAR App (apps/redping_sar)
- Entry: `main_sar.dart` → registers `AppServiceManager` with SAR variant.
- Services used: `SARService`, `SARMessagingService`, `SARIdentityService`, `SAROrganizationService`, `RescueResponseService`, `VolunteerRescueService`.
- Gating: `sarParticipation`, `sarTeamManagement`; org billing for advanced features.
- Background policy: dashboard updates via messaging; no sensor monitoring.
- UI: SAR operations center, team management, verification/admin flows.

## Data & Firebase
- Option A (simpler): Single Firebase project; strict Firestore security rules with per-app collections (`sos_*`, `sar_*`).
- Option B (cleaner separation): Two Firebase projects; Emergency app → consumer data; SAR app → operations data.
- Messaging isolation: `EmergencyMessagingService` and `SARMessagingService` route to distinct topics/collections.

## Subscriptions & Billing
- Stripe products:
  - Emergency: Free, Essential+, Pro — `acfd`, `hazardAlerts`, `sosSms`, medical profile.
  - SAR: Observer, Member, Coordinator, Ultra — `sarParticipation`, `sarTeamManagement`, org features.
- App-specific paywalls and feature lists; shared entitlement validation in core.

## Build & IDs
- Android: product flavors `emergency`, `sar` with distinct `applicationId` (e.g., `com.redping.emergency`, `com.redping.sar`).
- iOS: targets/schemes `Emergency`, `SAR` with distinct bundle IDs.
- Icons, names, splash screens per app.

## Permissions Matrix
- Emergency: location (foreground + background), activity recognition, sensors, notifications, SMS (where applicable).
- SAR: location (foreground), notifications, internet; avoid background sensors.
- Rationale strings tailored for each app store submission.

## Background Services & Power
- Emergency: sensor sampling adaptive based on battery/sleep; foreground service during ACFD verification window.
- SAR: no sensor sampling; periodic messaging updates; battery-friendly polling or streams.

## Store Policies
- Emergency: emergency claims must be accurate; explain ACFD limits; clear opt-in/consent; foreground notification during active monitoring windows.
- SAR: professional/volunteer tool; no consumer auto-detection; data privacy and retention policies.

## Telemetry & Privacy
- Shared logging with privacy filters; PII minimization.
- Per-app consent screens; independent privacy policies.
- Audit logs for SAR admin actions.

## CI/CD
- Matrix builds for both apps (analyze, test, build APK/IPA).
- Melos or Dart workspaces to manage packages.
- Fastlane lanes per app; play/app store upload separated.

## Testing Strategy
- Unit tests: shared core services, entitlements.
- Integration tests: Emergency ACFD → verification → SOS messaging; SAR registration → messaging → team flows.
- Device tests: battery impact for Emergency; dashboard performance for SAR.

## Risks & Mitigations
- Data cross-access: use separate projects or strict rules; isolate messaging.
- UI drift: shared UI package + design tokens.
- Build complexity: start with flavors inside current repo, then move to separate app folders.
- Support overhead: distinct help flows; clear in-app guidance.

## Success Criteria
- Emergency app idle battery impact ≤ 2–5%/day; SAR app ≤ 1–2%/day.
- Clear, app-specific onboarding and paywalls.
- Release pipelines green for both apps; crash-free sessions > 99%.
