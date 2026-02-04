# Melos Workspace Plan (Planning)

## Goal
Manage shared packages and multiple apps in a monorepo.

## Structure
```
apps/
  redping_emergency_app/
  redping_sar_app/
packages/
  shared_core/
  shared_ui/ (optional)
```

## melos.yaml (example)
```yaml
name: redping_workspace
packages:
  - apps/*
  - packages/*
scripts:
  analyze: flutter analyze
  test: flutter test
  build: |
    melos exec --scope="redping_*_app" -- flutter build apk
```

## shared_core (planning)
- Expose services, models, env utilities, feature access.
- Each app depends on `packages/shared_core` via path dependency.

## Next Steps
- Create `packages/shared_core` with pubspec and minimal code skeleton.
- Configure melos and verify `melos list` and `melos bootstrap` (later).
