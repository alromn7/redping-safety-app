# RedPing Split Comprehensive Plan (Emergency + SAR)

## Phase 0 — Preparation (Week 0)
- Confirm goals, branding, IDs, and Firebase strategy (single vs dual projects).
- Freeze critical flows (ACFD, SOS, SAR messaging) to avoid moving targets.
- Enable `AppVariant` gate in main system to validate separation logic without new apps.

## Phase 1 — Monorepo Scaffolding (Week 1)
- Create folders: `apps/redping_emergency`, `apps/redping_sar`, `packages/shared_core`.
- Move shared services, models, and utilities to `packages/shared_core`.
- Add melos or Dart workspace configs for local package management.
- Wire each app to depend on `shared_core` via path dependencies.

## Phase 2 — App Entries & Flavoring (Week 2)
- Add `lib/main_emergency.dart` and `lib/main_sar.dart` entries in each app.
- Android: add productFlavors `emergency`, `sar` with distinct `applicationId`s.
- iOS: add targets/schemes `Emergency`, `SAR` with distinct bundle IDs.
- Add icons, name strings, and splash per app.
- Gate initialization via `AppServiceManager.setVariant(AppVariant.emergency|sar)`.

## Phase 3 — Feature Isolation (Week 3)
- Emergency app: enable ACFD pipeline; ensure `acfd` entitlement gating remains intact.
- SAR app: remove/skip `SensorService` initialization; configure SAR dashboards and messaging.
- Extract and isolate messaging channels; ensure Emergency ↔ SAR routes are well-defined and secure.

## Phase 4 — Data & Rules (Week 4)
- If single Firebase project: enforce Firestore rules by collection and role; add tests.
- If dual projects: configure separate `google-services.json`/`GoogleService-Info.plist` and CI secrets.
- Audit PII access; add consent screens per app.

## Phase 5 — Subscriptions & Paywalls (Week 5)
- Emergency paywall: `acfd`, `hazardAlerts`, `sosSms`, medical profile.
- SAR paywall: `sarParticipation`, `sarTeamManagement`, org billing.
- Update Stripe product metadata and client-side entitlement mapping.

## Phase 6 — QA & Performance (Week 6)
- Emergency: battery impact tests, sensor calibration UX, verification dialog latency < 200 ms.
- SAR: dashboard update latency, messaging reliability, admin verification flows.
- Accessibility, localization, and offline behavior.

## Phase 7 — CI/CD & Releases (Week 7)
- CI matrix: `flutter analyze`, `flutter test`, `flutter build` for both apps.
- Fastlane lanes: Emergency and SAR uploads to Play Store/App Store.
- Release notes, store listings, privacy policies.

## Ongoing — Support & Observability
- Crash reporting, privacy-aware analytics, and logs.
- Feature flags for phased rollouts; remote kill switches.

## Detailed Task List
- Scaffolding:
  - Create app folders, add entrypoints, setup workspace config.
  - Migrate shared code to `packages/shared_core`.
- Emergency app:
  - Verify ACFD gating and foreground notification policy.
  - Finalize SOS flows and hazard alerts.
- SAR app:
  - Implement SAR identity and org management screens.
  - Integrate `SARMessagingService` and dashboard.
- Data & Security:
  - Rules per collection; role-based access; audit logs for SAR.
- Subscriptions:
  - Stripe SKU alignment; entitlement checks.
- Build & IDs:
  - Distinct app IDs/bundle IDs; assets and naming; env keys.
- Testing:
  - Unit/integration/device tests as per strategy.
- CI/CD:
  - Pipelines; code signing material; release automation.

## Risk Register
- Scope creep → enforce phase gates and feature flags.
- Data leakage → strict rules tests and project separation if needed.
- Build complexity → start with flavors, iterate to full app folders.
- App store review friction → clear descriptions and policy adherence.

## Acceptance Criteria
- Both apps build and run with isolated features and correct entitlements.
- Emergency idle power ≤ 5%/day; SAR idle power ≤ 2%/day.
- CI green; basic E2E flows pass on physical devices.

## Rollback Plan
- Keep main system app intact; flavors allow reverting to single app deployment.
- Feature flags to rejoin shared views if needed.

## Try-It Commands (for later, do not run now)
```bash
flutter run --flavor emergency -t apps/redping_emergency/lib/main_emergency.dart
flutter run --flavor sar -t apps/redping_sar/lib/main_sar.dart
```
