# Split RedPing into SOS + SAR apps (1 repo, 2 Flutter entrypoints)

**Generated:** 2026-02-02

This plan defines how to split the current application into two deliverables:
- **SOS app** (consumer emergency activation + contacts + tracking)
- **SAR app** (responder dashboard + coordination)

while keeping **one repository** and maximum code reuse.

---

## 0) Current-state snapshot (from repo scan)

### Android
- Current `applicationId`/namespace: `com.redping.redping` (see `android/app/build.gradle.kts`)
- Current manifest package: `com.redping.redping` (see `android/app/src/main/AndroidManifest.xml`)
- Manifest includes a broad permission set (location + background, SMS, contacts, audio, etc.) suitable for SOS but excessive for SAR.

### iOS
- `Info.plist` display name: `REDP!NG Safety` (bundle id comes from `$(PRODUCT_BUNDLE_IDENTIFIER)`)

### Router
- Single router surface includes both SOS and SAR pages: `lib/core/routing/app_router.dart`
- Router-level auth redirect allows these public routes:
  - `/` (splash)
  - `/login` and `/signup`
  - `/sos/:sessionId` (emergency card deep link)
  - `/auth/email-link` (email link auth)

### Variant support
- `AppVariant` exists (`lib/core/app_variant.dart`): `emergency` and `sar`
- `AppServiceManager` already has `setVariant()` and conditional behaviors in a few places.

---

## 1) Goals / non-goals

### Goals
1. Produce **two separate app builds** from this repo: SOS + SAR.
2. Ensure each build has a **minimal route surface** and **minimal permissions**.
3. Keep code reuse high: shared models, encryption/messaging engine, location primitives, Firestore rules logic.
4. Keep developer workflow simple:
   - `flutter run -t lib/main_sos.dart`
   - `flutter run -t lib/main_sar.dart`

### Non-goals (for the first iteration)
- Rewriting features or doing large refactors across all services.
- Re-architecting Firestore schema.
- Implementing missing TODO features.

---

## 2) Proposed split strategy (recommended)

## 2.1) Implementation status (as of 2026-02-02)
- Implemented: `lib/main_sos.dart` and `lib/main_sar.dart` entrypoints.
- Implemented: SAR-focused router at `lib/core/routing/sar_router.dart`.
- Implemented: variant-aware home routing via `lib/core/app/app_launch_config.dart`.
- Added: VS Code Run & Debug configs in `.vscode/launch.json`:
  - `RedPing SOS (lib/main_sos.dart)`
  - `RedPing SAR (lib/main_sar.dart)`
- Added: Android flavors (`sos`, `sar`) that set launcher label to `SOS` / `SAR`.
  - SOS keeps `applicationId = com.redping.redping`.
  - SAR uses `applicationIdSuffix = .sar` → `com.redping.redping.sar` for side-by-side installs.
  - Firebase step required: add a second Android app in Firebase for `com.redping.redping.sar`, then download a new `android/app/google-services.json` that includes BOTH package clients.

### SAR login note (Google Sign-In)
- If SAR Google Sign-In fails with `DEVELOPER_ERROR`, it is almost always a missing SHA-1/OAuth client mapping for the SAR package.
- We confirmed this on-device via `adb logcat`: `ConnectionResult{statusCode=DEVELOPER_ERROR}` when signing in.

Fix (Firebase Console):
1. Firebase Console → Project Settings → Your Apps → **Android app** `com.redping.redping.sar`
2. Add **SHA certificate fingerprints**:
  - Debug SHA-1: `DF:30:43:A5:F6:29:5B:ED:6C:F3:B7:B2:75:3D:C5:D9:76:26:B8:8A`
  - Release SHA-1: `40:6F:C2:89:D3:79:CD:0A:22:D7:32:9A:60:7A:BC:7E:91:73:3B:8A`
3. Firebase Console → Authentication → Sign-in method → ensure **Google** provider is enabled.
4. Download the updated `google-services.json` and replace `android/app/google-services.json`.
  - Verify the SAR client section includes an `oauth_client` entry with `client_type: 1` (Android) and the matching `package_name`.
5. Rebuild/reinstall SAR:
  - `flutter build apk --debug --flavor sar -t lib/main_sar.dart`
  - `adb install -r build/app/outputs/flutter-apk/app-sar-debug.apk`

### Step A — Two Flutter entrypoints (fast, low-risk)
- Add:
  - `lib/main_sos.dart`
  - `lib/main_sar.dart`
- Each entrypoint:
  - Sets the variant (`AppVariant.emergency` vs `AppVariant.sar`)
  - Chooses the correct router instance (SOS router vs SAR router)
  - Initializes Firebase with the correct FirebaseOptions

Result: you can ship two distinct apps without duplicating the repo.

### Step B — Router split (two routers)
- Create:
  - `lib/core/routing/sos_router.dart`
  - `lib/core/routing/sar_router.dart`
- Each router defines:
  - Only the screens relevant to that app
  - Redirect rules appropriate for that app

Keep common routing utilities shared (refresh listenable, onboarding helpers).

### Step C — Platform build targets (Android flavors first)
- Android: introduce `productFlavors { sos {} sar {} }`
  - Each flavor has different `applicationId`
  - Each flavor has different `app_name` and icon if desired
  - Each flavor can have separate `google-services.json`

- iOS: later add a second scheme/target with a different bundle id and its own `GoogleService-Info.plist`.

---

## 3) Deliverables

### Deliverable 1: Two entrypoints
- `lib/main_sos.dart`
- `lib/main_sar.dart`

### Deliverable 2: Router split
- `lib/core/routing/sos_router.dart`
- `lib/core/routing/sar_router.dart`
- Minimal changes to existing `AppRouter` (either kept as legacy or converted into a shared base)

### Deliverable 3: Android flavors
- `android/app/build.gradle.kts`: add flavors and per-flavor IDs
- `android/app/src/sos/` and `android/app/src/sar/` source sets for
  - `google-services.json`
  - manifest overrides (optional)
  - app name/icon overrides

### Deliverable 4: Firebase config split
- Create two Firebase option files:
  - `lib/firebase/firebase_options_sos.dart`
  - `lib/firebase/firebase_options_sar.dart`

Each entrypoint imports the corresponding options.

---

## 4) SOS app scope (what stays)

### Keep
- SOS flows and session management
- Emergency contacts
- Location/map/safety dashboard
- Offline-first SOS logic, SMS-first workflows
- Subscriptions (if SOS app is monetized)
- Hazard alerts (optional; depends on product decision)
- AI assistant (optional; if it is part of SOS product)

### Remove / hide
- SAR registration/verification/dashboard/organization pages
- SAR-only services or responders UI

### Permissions goal (Android)
- Keep: location (+ background if needed), notifications, vibration, boot receiver (if always-on)
- Optional: SMS (if SOS uses it), contacts (if importing contacts)
- Remove: SAR-only / AI-only permissions where possible

---

## 5) SAR app scope (what stays)

### Keep
- SAR dashboard and operational flows
- SAR registration/verification
- Organization dashboard and management
- SAR messaging, SOS session viewing, assignment tracking

### Remove / hide
- Consumer SOS activation UI (button, countdown)
- Subscription purchase flows (optional; depends on org licensing model)
- Emergency contacts management (not needed)

### Permissions goal (Android)
- Likely keep: notifications, location (foreground), network
- Likely remove: background location, SMS, contacts, audio recording, camera (unless used for credential uploads)

---

## 6) Data & security considerations

### Firestore rules
- Maintain strict rules so that:
  - SOS sessions are visible only to allowed viewers (emergency contacts) and verified SAR members
  - SAR app can only read what its authenticated/authorized user is allowed to

### Authentication
- Both apps use Firebase Auth, but:
  - SOS app targets consumer users
  - SAR app targets verified SAR accounts

### Deep links
- Decide whether SAR app should handle `redping://sos/{id}` or only SOS app.
  - Recommendation: SOS app owns public emergency-card deep link.
  - SAR app can use internal links or separate schemes like `redpingsar://...`.

---

## 7) Rollout plan (safe sequencing)

### Phase 1 (code-only, no platform flavors)
1. Add `main_sos.dart` + `main_sar.dart`.
2. Split router into two minimal routers.
3. Make sure both entrypoints run in debug:
   - `flutter run -t lib/main_sos.dart`
   - `flutter run -t lib/main_sar.dart`

### Phase 2 (Android flavors)
4. Add Android flavors + per-flavor app id & app name.
5. Add per-flavor `google-services.json`.
6. Confirm builds:
   - `flutter run --flavor sos -t lib/main_sos.dart`
   - `flutter run --flavor sar -t lib/main_sar.dart`

### Phase 3 (iOS split)
7. Add a second iOS scheme/target (RunnerSOS / RunnerSAR).
8. Add per-target `GoogleService-Info.plist`.

### Phase 4 (shrink permissions & dependencies)
9. Reduce permissions in SAR flavor manifest.
10. Optionally remove unused dependencies per flavor (advanced; may require conditional imports or split packages).

---

## 8) Validation checklist

### Functional
- SOS app: SOS activation works offline; emergency contacts and SMS-first alerting behave.
- SAR app: SAR login/verification gating works; dashboard loads; can view allowed SOS sessions.

### Security
- SOS session privacy enforced (no public reads).
- SAR app cannot read arbitrary SOS sessions.

### UX
- App label/icon clearly indicates SOS vs SAR.
- Store listings are distinct.

---

## 9) Risks & mitigations

- **Firebase config**: `firebase_options.dart` is not flavor-aware.
  - Mitigation: generate two option files and select in entrypoints.
- **Deep link collisions**: both apps registering same scheme/host.
  - Mitigation: keep `redping://sos` only in SOS app; SAR app uses different scheme or only https links.
- **Permissions creep**: SAR app inherits SOS manifest permissions.
  - Mitigation: per-flavor manifest override.

---

## 10) Next steps (what we will implement first)

1. Add `lib/main_sos.dart` + `lib/main_sar.dart`.
2. Create `sos_router.dart` + `sar_router.dart` and wire each entrypoint.
3. Run both entrypoints on device/emulator to confirm clean startup.
