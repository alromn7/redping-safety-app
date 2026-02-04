# RedPing App – Full Functionality & Capability Report

**Generated:** 2026-02-02

This document summarizes the *current* functionality and capabilities of the RedPing Flutter application as implemented in this workspace. It is based on a repo scan of:
- App feature modules under `lib/features/`
- Core services under `lib/services/`
- Routing configuration in `lib/core/routing/app_router.dart`
- Published project docs in the repository root

---

## 1) Product overview

RedPing is a safety-focused mobile application designed for:
- Individual emergency activation and tracking (SOS)
- Emergency contact notification and coordination
- Search-and-Rescue (SAR) workflows (registration, verification, dashboard)
- Hazard alerting and AI-assisted hazard prioritization
- Privacy controls and restricted visibility for emergency sessions
- Subscription/entitlement-based feature gating and Stripe payments
- Always-on sensor monitoring with strong battery governance and optimization

The app is built in Flutter with a Firebase backend and optional Stripe billing.

---

## 2) Supported platforms

Workspace contains platform projects for:
- **Android** (`android/`)
- **iOS** (`ios/`)
- **Web** (`web/`)
- **Windows** (`windows/`)
- **macOS** (`macos/`)
- **Linux** (`linux/`)

Operationally, the most mature/explicitly optimized target is **Android**, with heavy emphasis on always-on reliability and battery optimization.

---

## 3) Primary app modes and user roles

### 3.1 Emergency/User mode (primary)
Core consumer safety experience:
- SOS activation, countdown/cancel
- Emergency contacts
- Location tracking & sharing
- Messaging to contacts / responders
- Safety dashboard and monitoring

### 3.2 SAR mode (responder)
Professional/volunteer responder experience:
- SAR registration and verification
- SAR dashboard with active SOS list, help requests, assignments
- Organization management dashboards

### 3.3 Roles (conceptual)
- Regular user / subscriber
- Emergency contacts (invited/allowed viewers)
- Verified SAR participant/coordinator/admin (gated)

---

## 4) Navigation surface (what users can reach)

Routing is defined in `lib/core/routing/app_router.dart` and includes, at minimum:
- Splash and onboarding flows
- Auth flows (login/signup + email-link sign-in handler)
- Main shell pages: SOS, Map, Safety dashboard, Profile, Settings
- Emergency contacts page
- Hazard alerts page
- SAR pages (dashboard, registration, verification, org dashboard)
- AI assistant page
- Subscription management pages (plans, management, payment, methods, billing history)
- Gadgets management page
- Activities pages (create/start)
- Doctor-related pages (medications/appointments/medical profile editor)

Notes:
- Comments in routing indicate some features were **removed/disabled** (e.g., community chat and safety-fund routes).

---

## 5) Core functionality by capability area

### 5.1 SOS emergency activation and session management
Capabilities:
- **One-touch SOS** with a **countdown** and false-alarm prevention
- SOS session lifecycle (active → resolved)
- Real-time tracking updates during a session
- Deep link support for SOS session card URLs/paths

Offline-first / resilience (implemented in recent work):
- SOS can be activated while offline/airplane mode by queueing work and avoiding network-dependent blockers.
- Location acquisition uses last-known fallback and avoids blocking on reverse geocoding.


### 5.2 Emergency contacts
Capabilities:
- Create and manage a list of emergency contacts
- Contacts receive alerts (primarily via SMS; other channels may exist but are environment-dependent)
- “Invite via magic link” flows are implemented for contacts


### 5.3 Location, tracking, and mapping
Capabilities:
- Location permission handling and current-location acquisition
- Map view and location visualization
- Location sharing service (live share in app contexts)

Resilience improvements (notably for airplane mode):
- GPS-first acquisition with last-known fallback
- Reverse-geocoding is treated as optional and does not block location delivery


### 5.4 Messaging system (Emergency + SAR)
The repository contains a multi-phase upgraded messaging architecture (Phase 1–3 complete per docs):
- Unified **MessageEngine**
- **End-to-end encryption** (AES-GCM, X25519 key exchange, Ed25519 signatures)
- **Offline queue** (delay-tolerant storage)
- **Deduplication** to prevent message loops
- Services for emergency messaging and SAR messaging wired through the engine

Transport concepts:
- Internet transport is implemented; additional transports (Bluetooth/Wi‑Fi/satellite) are documented as roadmap.


### 5.5 Hazard alerts
Capabilities:
- Hazard alerts page and hazard alert service
- Subscription gating (hazard alerts require Essential+ or above)

AI enhancement:
- AI-driven hazard prioritization/summary using Gemini (top threats, risk scoring, recommended actions)


### 5.6 AI assistant and AI safety assistant
Two layers exist:

1) **Text-based AI Assistant (Gemini integration)**
- Pro-gated (entitlements/feature access)
- Command-based interface with conversation history
- Produces suggestions and can speak short responses (TTS enabled for some flows)

2) **Phone/voice AI integration**
- The `PhoneAIIntegrationService` is documented as **stubbed/disabled** for optimization (voice recognition features are not fully active).

AI permissions:
- There is an AI permissions UI and permissions model; permissions can be updated and are surfaced to the AI assistant service.


### 5.7 Sensors and automatic incident detection (ACFD)
Capabilities:
- Sensor monitoring and detection pipelines exist in the app layer (`SensorService` and related services).
- Subscription gating exists for ACFD (Essential+ and above).

Note:
- There is also a `shared_core` ACFD stub used for shared packaging, but the production behavior is driven by the app’s sensor services.


### 5.8 Always-on operation and battery optimization
This is a major pillar of the project:
- Battery governance rules and documentation are prominent.
- Optimization components exist (battery optimization service, performance monitoring, memory optimization).
- SOS is treated as a priority override for rapid response.


### 5.9 SAR (Search & Rescue) workflows
Capabilities:
- SAR registration flows and identity/verification pages
- SAR dashboard with tabs including active SOS, help requests, assignments
- Organization registration and organization dashboard/management pages
- Role-based gating and coordinator-only actions

Privacy model:
- Recent work tightened SOS/SAR visibility so sessions are not broadly public.


### 5.10 Subscriptions, entitlements, and payments (Stripe)
Capabilities:
- Subscription tiers (Free, Essential+, Pro, Ultra, Family)
- Feature gates enforced in services (and some UI gating)
- Stripe integration using `flutter_stripe` and Firebase Cloud Functions
- Payment UI, payment methods, billing history, subscription management

Notes:
- Firebase App Check is present as a dependency but currently disabled in `main.dart` (documented as a TODO to enable after proper configuration).


### 5.11 Doctor / medical utilities
Capabilities indicated by routes and dependencies:
- Medication list/editor
- Appointment list
- Medical profile editor
- OCR/text recognition is enabled via ML Kit (useful for prescription cards / documents)


### 5.12 Activities, check-in, and “RedPing Mode”
Capabilities:
- Activities pages (create/start)
- A check-in feature exists (check-in service and request dialog)
- RedPing “activity modes” exist and are Pro-gated


### 5.13 Notifications
Capabilities:
- Push notifications via Firebase Messaging
- Local notifications scheduling
- Timezone handling for scheduled alerts


### 5.14 Privacy, legal, and security
Capabilities:
- Dedicated privacy feature module and test/settings pages
- Legal documents service + bundled legal docs in assets
- Secure local storage via `flutter_secure_storage` and encryption utilities
- Firestore rules exist in repository and have been tightened in recent work to restrict SOS visibility


---

## 6) Feature gating summary (high level)

Based on Phase 2 gating docs:
- **Free:** Manual safety and basic flows; limited/no automation.
- **Essential+:** ACFD, hazard alerts, SOS SMS alerts.
- **Pro:** AI Safety Assistant, RedPing Mode, gadget integration (and more).
- **Ultra:** Higher-level admin capabilities (e.g., SAR admin management), premium features.
- **Family:** Shared access bundle.

(Exact entitlements/flags vary by environment and are enforced via `FeatureAccessService` and `EntitlementService`.)

---

## 7) Known removals / disabled components (as of current codebase)

Items explicitly marked as removed/disabled in code/docs include:
- **Community chat**: removed from app (available via website per routing comments).
- **Safety Fund**: routes removed (feature previously documented but currently not part of the primary navigation).
- **Crashlytics**: removed/disabled (logging via console/Firebase Console).
- **Firebase App Check**: present but disabled in startup due to prior auth issues.
- **Full voice assistant**: phone/voice AI integration partially disabled (stubbed) per AI assistant implementation report.

---

## 8) Operational tooling & diagnostics

Repo contains:
- Extensive documentation and checklists
- Multiple test scripts for messaging, SAR access control, device and integration scenarios
- Battery governance and on-device testing guidance

---

## 9) Capability matrix (status)

**Legend:** ✅ Implemented & wired | 🔒 Gated by tier | ⚠️ Present but limited/stubbed | 📴 Disabled/removed | 🧭 Roadmap

- SOS activation + tracking: ✅
- Offline-first SOS activation: ✅
- Emergency contacts: ✅
- SMS alerts: 🔒 (Essential+)
- Encrypted messaging engine: ✅
- Hazard alerts: 🔒 (Essential+)
- AI hazard summary: 🔒 (Pro for AI; depends on AI enable flags)
- AI assistant (text): 🔒 (Pro)
- Voice AI / OS assistant integration: ⚠️
- SAR dashboard + org management: ✅ (and gated by verification/roles)
- Payments + subscriptions (Stripe): ✅ (requires configured keys/functions)
- Gadgets integration: 🔒 (Pro) / depends on device capabilities
- Doctor utilities + OCR: ✅ (surface exists; depends on workflow completion)
- Community chat: 📴
- Safety fund: 📴 (in navigation)

---

## 10) Suggested next improvements (if you want a tighter “source-of-truth”)

If you want this report to stay accurate as features evolve:
1. Add a small “capabilities registry” (one JSON/Dart map) that lists features and their state (enabled/gated/disabled).
2. Auto-generate this report from that registry + router scan.

---

## 11) Route-by-route appendix (current router surface)

Source of truth: `lib/core/routing/app_router.dart`

### 11.1 Access control behavior (router-level)

The router enforces authentication broadly:
- If **not authenticated**, navigation redirects to `/login` **except** for:
	- `/` (splash)
	- `/login` and `/signup`
	- `/sos/:sessionId` (emergency card deep link)
	- `/auth/email-link` (passwordless email link handler)

If authenticated, attempts to visit `/login`, `/signup`, or `/auth/email-link` are redirected to `/main`.

### 11.2 Public routes (reachable without login)

| Route | Name | Page | Notes |
|------|------|------|------|
| `/` | `splash` | `SplashPage` | App bootstrap and initialization |
| `/login` | `login` | `LoginPage` | Authentication entry |
| `/signup` | `signup` | `SignupPage` | Account creation |
| `/auth/email-link` | `email-link-signin` | `EmailLinkSignInPage` | Completes Firebase email-link sign-in; can be opened from universal links |
| `/sos/:sessionId` | `emergency-card` | `EmergencyCardPage(sessionId)` | Deep link “emergency card” preview; intended for shared SOS session card links |

### 11.3 Main shell routes (tabs/navigation)

These are mounted under the router’s `ShellRoute` and represent primary navigation destinations:

| Route | Name | Page |
|------|------|------|
| `/main` | `main` | `SOSPage` |
| `/map` | `map` | `MapPage` |
| `/safety` | `safety` | `SafetyDashboardPage` |
| `/profile` | `profile` | `ProfilePage` |
| `/settings` | `settings` | `SettingsPage` |

#### Nested under `/profile`
| Route | Name | Page |
|------|------|------|
| `/profile/emergency-contacts` | `emergency-contacts` | `EmergencyContactsPage` |

#### Nested under `/settings`
| Route | Name | Page | Notes |
|------|------|------|------|
| `/settings/device` | `device-settings` | `DeviceSettingsPage` | Summary + shortcuts for sensor calibration and battery optimization |
| `/settings/device/sensor-calibration` | `sensor-calibration` | `SensorCalibrationPage` | Detailed calibration UX |
| `/settings/device/battery-optimization` | `battery-optimization` | `BatteryOptimizationPage` | Optimization controls and guidance |
| `/settings/privacy` | `settings-privacy` | `PrivacySettingsPage` | Privacy settings surface |
| `/settings/privacy-test` | `privacy-test` | `PrivacyTestPage` | Marked temporary/test |
| `/settings/gadgets` | `gadgets` | `GadgetsManagementPage` | Device integrations management |

### 11.4 Emergency / SAR / AI / Activities routes

| Route | Name | Page | Notes |
|------|------|------|------|
| `/sar` | `sar` | `SARPage` | SAR home/dashboard; additional role checks may apply |
| `/sar-registration` | `sar-registration` | `SARRegistrationPage` | Register as SAR member |
| `/sar-verification` | `sar-verification` | `SARVerificationPage` | Verification flow |
| `/organization-registration` | `organization-registration` | `OrganizationRegistrationPage` | SAR org registration |
| `/organization-dashboard` | `organization-dashboard` | `OrganizationDashboardPage` | SAR org management |
| `/sos-ping-dashboard` | `sos-ping-dashboard` | `SARPage` | Alias to SAR experience |
| `/help-assistant` | `help-assistant` | `HelpAssistantPage` | Help assistant module |
| `/ai-assistant` | `ai-assistant` | `AIAssistantPage` | Text-based AI assistant (Pro-gated at runtime) |
| `/activities` | `activities` | `activities` | `ActivitiesPage` |
| `/activities/create` | `create-activity` | `CreateActivityPage` |
| `/activities/start` | `start-activity` | `StartActivityPage` | Reads `type`, `template`, `activityId` from query params |

### 11.5 Doctor (health utilities) routes

| Route | Name | Page | Notes |
|------|------|------|------|
| `/doctor/medications` | `doctor-medications` | `MedicationListPage(userId)` | Uses current user ID |
| `/doctor/medications/edit` | `doctor-medications-edit` | `MedicationEditorPage(userId, medication)` | Reads medication from `state.extra` |
| `/doctor/appointments` | `doctor-appointments` | `AppointmentListPage(userId)` | Uses current user ID |
| `/doctor/profile` | `doctor-profile` | `MedicalProfileEditorPage` | Medical profile editor |

### 11.6 Subscription and billing routes

| Route | Name | Page | Notes |
|------|------|------|------|
| `/subscription/plans` | `subscription-plans` | `SubscriptionPlansPage` | Plan selection |
| `/subscription/family-dashboard` | `family-dashboard` | `FamilyDashboardPage` | Family plan dashboard |
| `/subscription/payment` | `payment` | `PaymentPage` | Requires `tier` in `state.extra`, otherwise redirects to plans |
| `/subscribe` | `subscribe` | `PaymentPage` | Convenience alias; supports `?tier=pro&year=true` |
| `/subscription/manage` | `subscription-management` | `SubscriptionManagementPage` | View/cancel/manage subscription |
| `/subscription/payment-methods` | `payment-methods` | `PaymentMethodsPage` | Cards/wallet management |
| `/subscription/billing-history` | `billing-history` | `BillingHistoryPage` | Receipts and invoices surface |

### 11.7 SOS session route (active session overlay)

| Route | Name | Page | Notes |
|------|------|------|------|
| `/sos` | `sos-session` | `SOSSessionPage(sessionId)` | Takes `?sessionId=...`; note this coexists with `/sos/:sessionId` deep-link card route |

### 11.8 Hazard, satellite, and history

| Route | Name | Page | Notes |
|------|------|------|------|
| `/hazard-alerts` | `hazard-alerts` | `HazardAlertsPage(initialCategory)` | Accepts `?category=...` |
| `/satellite` | `satellite` | `SatellitePage` | Satellite comms surface (implementation depends on service availability) |
| `/session-history` | `session-history` | `SARHistoryPage` | Session history surface |

