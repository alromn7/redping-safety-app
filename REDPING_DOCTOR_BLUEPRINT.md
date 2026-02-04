# REDP!NG Doctor — Comprehensive Blueprint (v1.0)

## TL;DR
- Purpose: A focused, $5/month add‑on that helps members manage medications, appointments, and a shareable medical card that strengthens SOS and family care without conflicting with ACFD.
- Status: Core MVP shipped (models, services, OCR scan, UI, routing, SOS panel). Daily reminder scheduling implemented with local notifications and timezone support. Global reminders toggle added in Settings. Lightweight unit test added for scheduling/cancel.
- Next: Expand scheduling controls, polish permissions/UX, optional family sharing views, and incremental analytics.

## Objectives
- Provide a simple medical utility that boosts retention and SOS outcomes.
- Keep “external coverage” strictly informational (operational only); never bill or penalize via coverage flags.
- Respect privacy: medical data is private by default; opt‑in family visibility only.
- Avoid feature conflict with ACFD (no overlapping paid guardian services). Focus on medications, appointments, and medical info.

## Non‑Goals
- No diagnosis, triage, or clinical decision support.
- No insurance billing, splits, penalties, or payments.
- No always‑on snore/fall monitoring by default (possible opt‑in later; separate SKU if needed).

## Personas & Primary Use Cases
- Individual member: Track meds, set reminders, carry a digital medical card during SOS.
- Family organizer: View shared medical info for dependents (opt‑in), coordinate meds and appointments.
- Rescuers: Read a concise SOS medical panel (blood type, allergies, key conditions, recent meds).

## Feature Set (MVP)
- Medical Profile editor: blood type, allergies, conditions, medications on file, notes, and family sharing toggle.
- Medications: add/edit/delete; times‑per‑day; adherence counters; daily reminders.
- Appointments: add/edit/delete upcoming appointments.
- OCR scanning: scan prescription labels or cards to draft medication entries.
- SOS integration: in SOS flow, show a compact medical card panel.
- Settings integration: global “Medication Reminders” toggle (default on).
- External coverage: store operational coverage info (informational only; family/rescuers visibility only where needed).

## Architecture Overview
- Framework: Flutter + Firebase (Auth/Firestore), GoRouter
- State: Uses local service composition; Riverpod available elsewhere if desired
- OCR: `google_mlkit_text_recognition`
- Notifications: `flutter_local_notifications` + `timezone` + `flutter_timezone`

### Data Model (Firestore)
- `users/{uid}/medical/profile` (document)
  - `bloodType`: string (e.g., O+, A-)
  - `allergies`: string[]
  - `conditions`: string[]
  - `notes`: string
  - `shareCoverageWithFamily`: bool (opt‑in)
  - Optional: coverage‑related flags (informational only)
- `users/{uid}/medical/profile/medications/{id}` (collection)
  - `name`, `dosage`, `form`, `timesOfDay` (HH:mm strings), `remindersEnabled`, `dosesTaken`, `lastTakenAt`
- `users/{uid}/medical/profile/appointments/{id}` (collection)
  - `title`, `provider`, `location`, `scheduledAt`, `notes`
- OCR transient (local): `DocumentScanResult`

### Code Map (MVP shipped)
- Models:
  - `lib/models/medical/medical_profile.dart`
  - `lib/models/medical/medication.dart`
  - `lib/models/medical/appointment.dart`
  - `lib/models/medical/document_scan_result.dart`
- Services:
  - `lib/services/medical/medical_profile_service.dart`
  - `lib/services/medical/medication_service.dart`
  - `lib/services/medical/appointment_service.dart`
  - `lib/services/medical/ocr_scan_service.dart`
  - `lib/services/medical/external_coverage_service.dart`
  - Notifications foundation: `lib/services/notification_service.dart` (daily schedule + cancel), `lib/services/notification_scheduler.dart` (SOS phases)
- UI:
  - `lib/features/doctor/pages/medical_profile_editor_page.dart`
  - `lib/features/doctor/pages/medication_list_page.dart`
  - `lib/features/doctor/pages/medication_editor_page.dart`
  - `lib/features/doctor/pages/appointment_list_page.dart`
  - `lib/features/doctor/widgets/medical_card_sos_panel.dart`
- Routing:
  - `lib/core/routing/app_router.dart` → `/doctor/profile`, `/doctor/medications`, `/doctor/medications/edit`, `/doctor/appointments`
- Integrations:
  - Profile quick‑links card → “RedPing Doctor” entries
  - SOS medical dialog → dynamic panel via `MedicalCardSosPanel`
  - Settings → “Medication Reminders” global toggle
- Tests:
  - `test/doctor/medication_notifications_test.dart` (dry‑run scheduling + cancel‑by‑prefix)

### Notifications (Daily Scheduling)
- Libs: `flutter_local_notifications`, `timezone`, `flutter_timezone`
- Approach: For each medication time (HH:mm), schedule a daily notification in local tz.
- ID Strategy: `hash(userId, medicationId, time)` → stable positive int.
- Payload Scheme: `med:<medId>:<HH:mm>` → allows prefix cancel by `med:<medId>`.
- Cancellation: on med update/delete, call `cancelScheduledByPayloadPrefix('med:<id>')` then re‑schedule.
- Settings Gate: global `medical_reminders_enabled` (SharedPreferences) enforced in `MedicationService._scheduleReminders`.

### OCR (Prescriptions)
- Engine: `google_mlkit_text_recognition`
- Heuristics: name + dosage regex, basic frequency keywords (od/bd/tds/qid), rough time hints (morning/noon/evening/night)
- Flow: Capture → process → produce `DocumentScanResult` → convert to `Medication` draft → user edits and saves.

## Privacy, Security, and Sharing
- Default: medical data private to user.
- Family Sharing: opt‑in toggle in medical profile; restrict read access to trusted family accounts only.
- External Coverage: store purely as informational; shown to family/rescuers; no billing logic.
- Recommended Firestore Rules (sketch):
  - Users can read/write their own `users/{uid}/medical/**`.
  - Family members listed in `users/{uid}/family/{memberId}` with explicit `medicalRead: true` may read profile and SOS panel subset.
  - SAR/rescuer app contexts may receive limited SOS medical snapshot via server function (strictly controlled).

## UX Flows
- Medications: List → Add/Edit → (optional) Scan → Save → Schedules created (if reminders enabled and global toggle on).
- Appointments: List → Add/Edit → Save.
- Profile: Edit medical details + sharing toggle.
- SOS: Tap “Medical Info” → `MedicalCardSosPanel` with concise, high‑contrast summary.
- Settings: Toggle Medication Reminders ON/OFF (with SnackBar confirmation).

## Routing (GoRouter)
- `/doctor/profile` → MedicalProfileEditorPage
- `/doctor/medications` → MedicationListPage
- `/doctor/medications/edit` → MedicationEditorPage
- `/doctor/appointments` → AppointmentListPage

## Analytics & KPIs (Phase 1 lightweight)
- KPIs: active Doctor users/week, medications with reminders, reminder openings, SOS medical panel opens, edits per week.
- Events: medication_added, reminder_scheduled, reminder_fired (local), appointment_added, medical_profile_updated, sos_med_card_viewed.
- Privacy: only event counts and minimal metadata; no PII in analytics payloads.

## Rollout Plan
1) Internal QA (staging): OCR/device matrix, schedule reliability, dark theme and accessibility.
2) Limited Beta: 5–10% of subscribers; monitor crashes, ANRs, and feedback.
3) 100% rollout + Spotlight Card in Profile; Settings toggle announced in release notes.

## Testing Strategy
- Unit: services (profile, medications, appointments, OCR parsing, scheduling/cancel prefixes).
- Widget: medication editor scan path, profile editor toggles, settings switch state.
- Integration (optional): end‑to‑end scheduling with a device‑compat test lane.
- Non‑functional: battery impact (inexact alarms), dark theme contrast, slow network resilience, offline behavior.

## Edge Cases & Failure Modes
- Timezone changes/daylight shift → next fire computed with tz, daily match ensures roll‑over.
- Permissions denied → scan flow shows friendly prompt; continue manual entry.
- Device reboot → plugin persists schedules; we reschedule on edits; future enhancement: rehydrate on app start if needed.
- Multiple meds at same time → distinct IDs; notifications coalesce by channel.

## Pricing & Positioning
- Add‑on: $5/month (fits utility scope, high retention lever, no ACFD conflict).
- Value messaging: “Never miss a dose; carry your medical card with SOS; help family coordinate care.”

## Implementation Status
- ✔ Models, services, routes, UI pages/widgets.
- ✔ OCR dependency + basic heuristics.
- ✔ SOS panel integration.
- ✔ Daily reminder scheduling with tz + global toggle.
- ✔ Unit test for schedule/cancel (dry‑run).
- ☐ Enhanced scheduling UI (per‑medication enable/disable by weekday; snooze; exact/priority alarms).
- ☐ Family reader view (opt‑in) and audit trail.
- ☐ Broader widget tests and integration tests.

## Backlog / Next Steps
- Scheduling controls: weekday selection, snooze, exact vs inexact selection for Android (`AndroidScheduleMode`).
- UX polish: banners if global reminders disabled; clarify permission rationale copy for camera/notifications.
- Family: add read‑only family view for shared profiles; per‑field sharing scope.
- SOS: quick link to edit medical profile from SOS panel when safe.
- Analytics: add coarse metrics; protect by user consent toggle.
- Optional future SKUs: pharmacy refill reminders, attachment of lab results, provider directories, and opt‑in passive wellness (separate from ACFD).

## Acceptance Criteria (MVP)
- Users can create/edit Medical Profile and Medications with times.
- Toggling reminders per‑medication and globally behaves as expected.
- Daily notifications fire at scheduled times in local timezone.
- SOS dialog shows a concise, readable medical card panel.
- OCR scan produces a reasonable draft and never crashes if denied permissions.
- No billing/penalty logic tied to external coverage flags.

---
Document owner: Product + Engineering (Safety/Doctor)
Last updated: 2025‑12‑02
