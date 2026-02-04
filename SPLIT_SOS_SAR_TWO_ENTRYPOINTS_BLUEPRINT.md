# Blueprint: 1 repo → 2 apps via 2 Flutter entrypoints

**Generated:** 2026-02-02

This blueprint provides the concrete file layout, wiring approach, and build configuration needed to produce:
- SOS app (consumer)
- SAR app (responder)

---

## A) File layout (proposed)

### Entry points
- `lib/main_sos.dart`
- `lib/main_sar.dart`

### Routers
- `lib/core/routing/sos_router.dart`
- `lib/core/routing/sar_router.dart`
- (Optional) `lib/core/routing/router_shared.dart` for common redirect helpers

### Firebase options
- `lib/firebase/firebase_options_sos.dart`
- `lib/firebase/firebase_options_sar.dart`

Reason: the current `lib/firebase_options.dart` is platform-aware but not flavor/variant-aware.

### Variant selection
- Continue using `lib/core/app_variant.dart` (`emergency`, `sar`).
- Use `AppServiceManager().setVariant(...)` very early in each entrypoint.

---

## B) Entry point wiring (pseudocode)

### `main_sos.dart`
Responsibilities:
1. Set variant: `AppVariant.emergency`
2. Initialize Firebase using SOS options
3. Initialize global services needed for SOS
4. Run app with SOS router

High-level shape:
- Create a `RedPingApp` widget that accepts a `GoRouter`.
- Provide `SosRouter.router`.

### `main_sar.dart`
Responsibilities:
1. Set variant: `AppVariant.sar`
2. Initialize Firebase using SAR options
3. Initialize global services needed for SAR
4. Run app with SAR router

---

## C) Router split (exact routing decisions)

### SOS router should include
- `/`, `/login`, `/signup`, `/auth/email-link`
- Main shell: `/main`, `/map`, `/safety`, `/profile`, `/settings`
- `/profile/emergency-contacts`
- `/sos` (active session overlay)
- `/sos/:sessionId` (public emergency card deep link)
- `/hazard-alerts` (optional)
- Subscriptions: `/subscription/*`, `/subscribe`
- AI assistant: `/ai-assistant` (optional)

### SAR router should include
- `/`, `/login`, `/signup`, `/auth/email-link`
- `/sar` as the home/main route (can be the initialLocation after auth)
- `/sar-registration`, `/sar-verification`
- `/organization-registration`, `/organization-dashboard`
- `/session-history`
- Doctor utilities only if responders need them (likely no)
- **Do not** include consumer SOS activation routes unless responders need to view the emergency card.

### Redirect policy differences
- SOS: authenticated users go to `/main`
- SAR: authenticated users go to `/sar`

---

## D) Android build flavors (recommended)

### 1) Add flavors in `android/app/build.gradle.kts`

Proposed structure:
- `flavorDimensions += "app"`
- `productFlavors { sos { ... } sar { ... } }`

Recommended IDs:
- SOS: `com.redping.sos` (or keep `com.redping.redping`)
- SAR: `com.redping.sar`

If you want to keep the existing package as SOS:
- SOS: `com.redping.redping`
- SAR: `com.redping.redping.sar` (via `applicationIdSuffix = ".sar"`)

App label per flavor:
- `resValue("string", "app_name", "REDP!NG SOS")`
- `resValue("string", "app_name", "REDP!NG SAR")`

### 2) Per-flavor google-services.json
- `android/app/src/sos/google-services.json`
- `android/app/src/sar/google-services.json`

(Keep the current one in `android/app/google-services.json` as legacy only if needed; ideally move to `src/sos/`.)

### 3) Per-flavor manifest override (permissions)

Create:
- `android/app/src/sar/AndroidManifest.xml`

Goal: remove SOS-only permissions from SAR build (SEND_SMS, READ_CONTACTS, background location, etc.).

Note: manifests merge; you can override/omit or use `tools:node="remove"` on permissions.

---

## E) iOS split (later phase)

iOS requires separate bundle identifiers for two App Store apps.

Recommended approach:
- Create two schemes/configurations: `Runner-SOS` and `Runner-SAR`
- Set unique `PRODUCT_BUNDLE_IDENTIFIER` per scheme
- Add per-target `GoogleService-Info.plist`
- Adjust display name per target

This can be done after Android flavors are stable.

---

## F) Firebase strategy (two apps)

You will need **two Firebase app registrations** at minimum:
- Android SOS (applicationId)
- Android SAR (applicationId)

and optionally:
- iOS SOS bundle id
- iOS SAR bundle id

Then generate:
- `firebase_options_sos.dart`
- `firebase_options_sar.dart`

via FlutterFire CLI runs scoped to each app.

---

## G) Deep links and universal links

### Recommendation
- SOS app owns `redping://sos/{sessionId}` and universal link `https://redping.app/auth/*`.
- SAR app should avoid claiming the same deep links unless you want both apps to compete.

If SAR needs to open SOS sessions:
- Prefer internal navigation based on session ID copied from within SAR dashboard.
- Or use a separate scheme for SAR like `redpingsar://...`.

---

## H) Size/performance cleanup (optional)

After split is working:
- Remove unused routes and avoid initializing unused services per app.
- Consider splitting dependencies only if necessary (requires package refactors).

---

## I) Acceptance criteria (for “Phase 1 split complete”)

- `flutter run -t lib/main_sos.dart` boots into SOS shell.
- `flutter run -t lib/main_sar.dart` boots into SAR dashboard.
- No SAR-only routes are reachable from SOS app.
- No SOS activation UI is reachable from SAR app.
- `flutter analyze` remains clean.

