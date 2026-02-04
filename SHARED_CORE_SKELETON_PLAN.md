# Shared Core Skeleton Plan

## Purpose
Extract common services/models/utilities into a `packages/shared_core` to avoid duplication across Emergency and SAR apps.

## Proposed Structure
```
packages/
  shared_core/
    lib/
      core/
        env/
        logging/
        routing/
      services/
        auth_service.dart
        profile_service.dart
        contacts_service.dart
        notification_service.dart
        location_service.dart
        emergency_messaging_service.dart
        feature_access_service.dart
        subscription_service.dart
      models/
        sos_session.dart
        sar_identity.dart
        subscription_plan.dart
      utils/
        secure_storage.dart
        crypto_utils.dart
```

## Dependency Setup
- Each app adds a path dependency in `pubspec.yaml`:
```yaml
dependencies:
  shared_core:
    path: ../packages/shared_core
```

## Initial Tasks
- [ ] Create package `packages/shared_core` (pubspec + lib folder)
- [ ] Move non-product-specific code from main system into shared_core
- [ ] Keep product-specific code in app repos (Emergency: Sensor/ACFD; SAR: Team/Org/SARMessaging)
- [ ] Provide adapters for app-specific init via DI

## Melos Integration
- Add `packages/*` to `melos.yaml` packages list
- Use `melos bootstrap` later to wire dependencies

## Notes
- No code execution now; this is a planning outline
- Start with interfaces and small utilities, then migrate services gradually
