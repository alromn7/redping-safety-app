# RedPing Project – Step‑By‑Step Plan

Purpose: a concise, actionable roadmap we can execute together. Each step links to concrete files, has acceptance criteria, and can be checked off as we progress.

NOTE: This plan aligns with the unified blueprint in `assets/docs/Redping_unified_communication_blueprint` — treating `sos_sessions` as the single source of truth.

---

## Milestone 1 – Single Source Of Truth (SOS Sessions)

- [x] 1.1 Add `SosRepository` for Firestore writes
  - Files:
    - New: `lib/repositories/sos_repository.dart`
    - Uses: `cloud_firestore`, writes to `GoogleCloudConfig.firestoreCollectionSosAlerts` (`sos_sessions`)
  - Acceptance:
    - A single method to create/update SOS sessions with validated JSON (no NaN/Infinity), returns doc id.

- [x] 1.2 Wire SOS creation into `SOSService`
  - Files:
    - Update: `lib/services/sos_service.dart`
  - Acceptance:
    - On activation (end of countdown), the session is persisted via `SosRepository` to `sos_sessions`.
    - Errors are caught and logged without crashing; the app continues.

- [x] 1.3 Stop client‑side writes to `sos_pings` (transitional flag)
  - Files:
    - Update: `lib/services/sos_ping_service.dart`
  - Acceptance:
    - Introduce a dev flag (e.g., from `Env`) to disable direct client writes to `sos_pings` in production builds.
    - Reading pings remains functional.

- [x] 1.4 Cloud Function: derive `sos_pings` from `sos_sessions`
  - Files:
    - New: `functions/src/triggers/sosSessions.ts` (or `index.ts` if mono‑file)
  - Acceptance:
    - On write/update of `sos_sessions`, a derived document appears/updates under `sos_pings` with computed fields (priority, riskLevel, etc.).
    - Function is idempotent and logs structured output.

---

## Milestone 2 – Config & Secrets

- [x] 2.1 Introduce env provider and flavors
  - Files:
    - New: `lib/config/env.dart` (reads `--dart-define` vars, exposes `Env.current`)
    - New: `lib/config/env_keys.dart` (constants for define keys)
  - Acceptance:
    - App builds with `--dart-define` for `BASE_URL`, `REGION`, `FEATURE_FLAGS`.

- [x] 2.2 Replace hardcoded keys/URLs
  - Files:
    - Update: `lib/config/google_cloud_config.dart`
  - Acceptance:
    - Values come from `Env` with safe defaults; no nonessential private keys hardcoded.

- [x] 2.3 Flavor scaffolding
  - Files:
    - Update: platform runners as needed; add build scripts (`scripts/`)
  - Acceptance:
    - Distinct dev/staging/prod builds with different API endpoints and flags.

---

## Milestone 3 — Routing Guards

- [x] 3.1 Implement auth/onboarding redirect
  - Files:
    - Update: `lib/core/routing/app_router.dart`
  - Acceptance:
    - Unauthenticated → `login`
    - First‑run/not onboarded → `onboarding`
    - Default → `main`

---

## Milestone 4 — Clean Encoding/Strings

- [x] 4.1 Remove garbled Unicode in UI/logs
  - Files (examples):
    - `lib/test_firestore.dart`
    - `lib/features/profile/presentation/pages/profile_test_page.dart`
    - `docs/redping_website_architecture_blueprint.md`
  - Acceptance:
    - Replace odd glyphs with plain text or proper icons; pass analyzer without odd characters.

---

## Milestone 5 – Logging & Crash Reporting

- [x] 5.1 Standardize logging
  - Files:
    - Update: replace scattered `debugPrint` with `logger` where feasible.
  - Acceptance:
    - Leveled logs (debug/info/warn/error) and consistent tags for services.

- [x] 5.2 Crashlytics integration
  - Files:
    - Update: `lib/core/config/app_optimization_config.dart`
  - Acceptance:
    - Non‑dev builds report uncaught Flutter errors to Crashlytics.

---

## Milestone 6 — Tests

- [ ] 6.1 Unit tests: core services
  - Files:
    - New: `test/sos_service_test.dart`
    - New: `test/sos_ping_service_test.dart`
    - New: `test/emergency_messaging_service_test.dart`
  - Acceptance:
    - SOS countdown → activation → resolve paths verified; offline queue behavior verified.

- [ ] 6.2 Integration tests (golden path)
  - Files:
    - Under `integration_test/`: login → SOS → SAR assignment happy path
  - Acceptance:
    - Test passes locally with a dev emulator/project.

---

## Milestone 7 — Performance & Reliability

- [ ] 7.1 Rate‑limit costly calls
  - Files:
    - Update: `lib/services/location_service.dart` (reverse geocoding cadence)
    - Update: timers in `sos_ping_service.dart`, `sar_service.dart`
  - Acceptance:
    - No noticeable UI jank; background timers don’t overload logs or main thread.

- [ ] 7.2 Telemetry for hotspots (optional)
  - Files:
    - New: lightweight metrics helper (time‑to‑init, error rates)
  - Acceptance:
    - Visible timings during dev builds for startup and SOS activation path.

---

## Milestone 8 — Firestore Rules & Roles

- [ ] 8.1 Role‑based access controls
  - Files:
    - Firebase console / `firestore.rules` in the functions project (if tracked)
  - Acceptance:
    - Civilians read/write only their SOS sessions; SAR roles read assigned/region sessions; public cannot access restricted data.

---

## Milestone 9 — Housekeeping

- [ ] 9.1 Remove binaries from VCS
  - Files:
    - `build/app/outputs/flutter-apk/app-debug.apk` (tracked file)
  - Acceptance:
    - APK removed from repo, `.gitignore` continues to exclude build outputs.

- [ ] 9.2 Update README
  - Files:
    - `README.md`
  - Acceptance:
    - Clear setup, flavors, how to run tests, and core features.

---

## Execution Guide

1) We’ll pick a milestone, create a short PR with only focused changes, and validate via tests.
2) Keep changes minimal and consistent with current style.
3) Use feature flags (via `Env`) for transitional behavior.

### Suggested Order
1. Milestone 1 (SOT + Functions)
2. Milestone 2 (Env/Flavors)
3. Milestone 3 (Routing)
4. Milestone 4 (Strings)
5. Milestones 5–7 (Logging, Tests, Perf)
6. Milestone 8 (Rules)
7. Milestone 9 (Housekeeping)

### Acceptance Summary (per milestone)
- Code compiles, app starts, and no regressions on SOS flow.
- New unit tests pass locally.
- For Functions: deployment succeeds and derived pings reflect session changes.

---

## Working Log

- [x] Plan created in `docs/redping_step_by_step_plan.md`
- [x] Milestone 1 started
- [x] Milestone 1 completed
- [x] Milestone 2 started
- [x] Milestone 2 completed
- [x] Milestone 3 started
- [x] Milestone 3 completed
- [x] Milestone 4 started
- [x] Milestone 4 completed
- [x] Milestone 5 started
- [x] Milestone 5 completed
- [x] Milestone 4 started
