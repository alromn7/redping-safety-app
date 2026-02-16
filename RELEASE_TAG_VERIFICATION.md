# Release Tag & Signing Verification Checklist

Certificate (current):
- SHA-256: 53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469
- SHA-1:    406fc289d379cd0a22d7329a607abc7e91733b8a
- DN:       CN=Redping, O=Redping, L=City, ST=State, C=US

## 1. Pre-tag Sanity
- [ ] Working branch is `main` and clean (`git status` has no changes).
- [ ] `flutter build apk --release --flavor sos -t lib/main_sos.dart` succeeds locally.
- [ ] `flutter build apk --release --flavor sar -t lib/main_sar.dart` succeeds locally.
- [ ] Local APK signature shows CN=Redping (no "Android Debug").
- [ ] Key passwords rotated & stored securely in secret manager.

Note: This repo builds multiple Android flavors (e.g. `sos`, `sar`). A plain
`flutter build apk --release` may succeed in Gradle but Flutter may not locate the
APK under the default `app-release.apk` name. Expected outputs:
- `build/app/outputs/flutter-apk/app-sos-release.apk`
- `build/app/outputs/flutter-apk/app-sar-release.apk`

## 2. Create Annotated Tag
```
git pull origin main
export REL_VER=v1.0.0   # adjust version
git tag -a $REL_VER -m "Release $REL_VER (Redping cert SHA256: 53b37f...)"
git push origin $REL_VER
```
(Windows PowerShell equivalent):
```
$REL_VER = "v1.0.0"
git pull origin main
git tag -a $REL_VER -m "Release $REL_VER (Redping cert SHA256: 53b37f...)"
git push origin $REL_VER
```

## 3. CI Workflow Expected Steps
- Decode base64 keystore → write `android/keystore/redping-release.jks`.
- Use `key.properties` or env vars for signing.
- Build APK/AAB.
- Verify signature step prints CN=Redping + correct SHA-256.
- Generate SHA-256 checksums artifact.

## 4. Post-build Verification
After workflow finishes:
- [ ] Download APK/AAB artifact.
- [ ] Run:
```
C:\Users\<you>\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat verify --print-certs app-release.apk
```
Ensure output SHA-256 matches `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`.
- [ ] Confirm no fallback to debug certificate (CN=Android Debug should NOT appear).

## 4a. Latest Local Verification (2026-02-04)
Tag: `v1.0.1+3`

Artifacts found under `build/app/outputs/flutter-apk/...`:
- SOS: `build/app/outputs/flutter-apk/app-sos-release.apk`
- SAR: `build/app/outputs/flutter-apk/app-sar-release.apk`

Package versions (from `aapt dump badging`):
- SOS: `com.redping.redping` versionCode `3`, versionName `1.0.1`
- SAR: `com.redping.redping.sar` versionCode `3`, versionName `1.0.1-sar`

`apksigner verify --print-certs` results (SOS + SAR):
- DN: `CN=Redping, O=Redping, L=City, ST=State, C=US`
- SHA-256: `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`
- SHA-1: `406fc289d379cd0a22d7329a607abc7e91733b8a`

## 4b. Latest Local Verification (2026-02-06)
Tag: `v1.0.1+4`

Artifacts found under `build/app/outputs/...`:
- SOS APK: `build/app/outputs/flutter-apk/app-sos-release.apk`
- SAR APK: `build/app/outputs/flutter-apk/app-sar-release.apk`
- SOS AAB: `build/app/outputs/bundle/sosRelease/app-sos-release.aab`
- SAR AAB: `build/app/outputs/bundle/sarRelease/app-sar-release.aab`

Package versions (from `aapt dump badging`):
- SOS: `com.redping.redping` versionCode `4`, versionName `1.0.1`
- SAR: `com.redping.redping.sar` versionCode `4`, versionName `1.0.1-sar`

`apksigner verify --print-certs` results (SOS + SAR APK):
- DN: `CN=Redping, O=Redping, L=City, ST=State, C=US`
- SHA-256: `53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469`
- SHA-1: `406fc289d379cd0a22d7329a607abc7e91733b8a`

`keytool -printcert -jarfile` results (SOS + SAR AAB):
- Owner/Issuer DN: `CN=Redping, O=Redping, L=City, ST=State, C=US`
- SHA-256: `53:B3:7F:0B:16:D5:29:18:A6:C4:D0:47:72:00:A3:21:4B:33:4F:5F:D3:6D:14:67:76:8A:05:57:42:15:F4:69`
- SHA-1: `40:6F:C2:89:D3:79:CD:0A:22:D7:32:9A:60:7A:BC:7E:91:73:3B:8A`

## 4c. Latest Local Verification (2026-02-07)

Sanity checks after SOS/SAR feature cleanup (Hazard Alerts removed):
- `flutter analyze` => No issues found
- `flutter build apk --debug --flavor sar -t lib/main_sar.dart` => success
  - Output: `build/app/outputs/flutter-apk/app-sar-debug.apk`
- `flutter build apk --debug --flavor sos -t lib/main_sos.dart` => success
  - Output: `build/app/outputs/flutter-apk/app-sos-debug.apk`

Note: An initial SOS debug build failed due to `C:` disk full; after cleaning build artifacts, it succeeded.

## 4d. Latest Functional Verification (2026-02-13)

Device test status (SOS/SAR integration):
- ✅ Manual SOS activation working properly.
- ✅ ACFD open-app trigger working properly.
- ✅ ACFD closed-app trigger working properly.
- ✅ ACFD offline + online behavior verified working properly.
- ✅ ACFD offline closed-app test verified: SOS ping delivered to SAR dashboard without opening the SOS app.
- ✅ SAR receives a single active SOS ping per session (duplicate active ping issue resolved).
- ✅ SOS reset flow clears active state correctly (no stale active session/ping residue observed in SAR).
- ✅ SOS countdown final voice prompt ("SOS activated.") completes without cut-off.

Supporting stability checks:
- `flutter analyze` => No issues found.
- SOS logging filter added at `scripts/tail_sos_logs.ps1` to reduce logcat noise during verification.

Notes:
- `BLASTBufferQueue` spam was identified as Android rendering noise and is excluded from SOS-focused log review.
- Online/offline activation logs were clarified to avoid false interpretation during connectivity checks.

## 4e. Comprehensive Core Check (2026-02-14)

Automated core validation (post SOS/ACFD/SAR scope cleanup):
- `flutter analyze` => No issues found.
- Focused tests => Passed (7 passed, 0 failed):
  - `test/e2e/sos_flow_test.dart`
  - `test/services/sensor_service_test.dart`
  - `test/voice_session_controller_test.dart`
  - `test/coordinator_fallback_test.dart`
- Build verification:
  - `flutter build apk --debug --flavor sos -t lib/main_sos.dart` => success
    - Output: `build/app/outputs/flutter-apk/app-sos-debug.apk`
  - `flutter build apk --debug --flavor sar -t lib/main_sar.dart` => success
    - Output: `build/app/outputs/flutter-apk/app-sar-debug.apk`

Manual device checks still required for final sign-off (operator validation):
- Manual SOS activation end-to-end on device.
- ACFD open-app and closed-app trigger confirmation on device.
- Offline-to-online delivery behavior confirmation on device.
- SAR single active ping and reset-clears-active confirmation on device.
- Countdown final voice prompt completion confirmation on device.

Additional fix validation note (2026-02-14):
- Fixed SOS app SAR-state propagation gap where SAR dashboard status updates (e.g., `acknowledged`) were not reliably reflected in SOS UI.
- `SOSService` Firestore listener now pushes updates to `sessionNotifier` on status and metadata/responder changes.
- SOS UI now displays granular emergency phase labels (`ACKNOWLEDGED`, `ASSIGNED`, `EN ROUTE`, etc.) instead of a generic `SOS ACTIVE` label.

Additional reset/offline-duplicate prevention note (2026-02-14):
- Fixed post-reset stale-session resurrection that could trigger unintended re-delivery/offline duplicate behavior.
- Added local end-guard window in `SOSService` to block restore/redelivery while manual reset cleanup is in progress.
- Hardened resolved-status fallback write path to avoid creating/updating non-canonical/missing session docs.

Additional SAR-state consistency hardening (2026-02-14):
- Fixed race where rescue-tracking callback could overwrite Firestore-authoritative SOS status/metadata with stale session fields.
- `SOSService` now merges only rescue-response fields from `RescueResponseService` and preserves canonical status/metadata from Firestore listener updates.
- Added listener auto-heal to ensure Firestore subscription follows the current active session ID after local/canonical ID transitions.
- Validation: `flutter analyze` => No issues found; focused SOS tests => passed (7/7).

Additional reset completion hardening (2026-02-14):
- Fixed `resolveSession()` ordering bug where end-guard was set before restore attempt, which could block local session restore during reset and cause partial cleanup.
- Reset now attempts local/remote canonical session adoption first, then applies end-guard and completes resolution.
- Removed reset-time `createOrUpdateFromSession` upsert step to avoid recreating non-canonical/local ghost session docs during cleanup.
- Validation: `flutter analyze` => No issues found; focused SOS tests => passed (7/7).

Additional duplicate-ping hardening (2026-02-14):
- Fixed cross-isolate terminal pushback race where a reset-driven `resolved` could be overwritten back to `acknowledged`, re-enabling ping redelivery and duplicate SAR ping appearance.
- Resolved status writes now stamp `metadata.clientTerminalRequested*` markers.
- Firestore listener now accepts terminal updates carrying client-terminal markers (in addition to SAR-attributed terminal actions), preventing stale acknowledged pushback after manual reset.
- Validation: `flutter analyze` => No issues found; focused SOS tests => passed (7/7).

Deep producer/consumer duplicate analysis (2026-02-14):
- Root mechanism is SOS-side session status resurrection (post-reset `resolved` drifting back to active-like status), not primary SAR dashboard list rendering logic.
- Added SOS listener guard to reject non-terminal regressions when a client terminal marker exists and self-heal status back to terminal.
- Added SAR-side safety in duplicate-ping cleanup to update only existing `sos_pings` docs (avoid creating synthetic ping docs during dedupe).

Additional countdown cancel black-screen fix (2026-02-14):
- Fixed navigator lock/assert race (`!_debugLocked`) when tapping `I'm OK` in countdown dialog by removing direct dialog `pop()` from the button callback and letting SOS page/service dismissal own the close flow.
- Fixed unhandled async exception in `cancelSOS()` Firestore cancellation write path for local-only countdown session IDs (now handled via async `catchError` + offline enqueue fallback).
- Validation: `flutter analyze` => No issues found; focused SOS tests => passed (7/7).

Countdown-safe-dismiss expansion (2026-02-14):
- Applied the same safe dialog-pop retry mechanism across SOS countdown-related dialogs in `SOSPage` (countdown + voice verification close paths).
- Removed direct flag-forced close behavior in countdown callbacks and route close now consistently goes through guarded dismiss helpers.
- This prevents navigator lock races during rapid countdown/session state transitions and keeps dismissal behavior consistent across all countdown session flows.

Countdown `I'm OK` delivery suppression fix (2026-02-14):
- Fixed path where cancelled countdown sessions could still be enqueued (`cancel_firestore_write_failed`) and later published to SAR.
- `OfflineSOSQueueService.enqueue()` now rejects terminal sessions (`cancelled`, `resolved`, `false_alarm`) and removes any existing queued item for that session.
- `cancelSOS()` now sets local end-guard and skips queue fallback when Firestore cancellation fails due to missing session doc (local-only countdown cancel case).
- `_activateSOS()` now checks local end-guard to block late activation from concurrent isolate flow after user cancellation.

ACFD post-cancel re-trigger suppression (2026-02-14):
- Added cross-isolate ACFD suppression window (SharedPreferences-backed) after user cancel (`I'm OK`) to prevent immediate crash/fall auto-retrigger from headless/background sensor flow.
- Enforced suppression in all auto-trigger entry points: `_handleCrashDetected`, `_handleFallDetected`, `startSOSCountdown` (auto types), and `activateSOSImmediately` (auto types).
- Also stamps `_lastSessionStart` on cancel to reinforce in-isolate cooldown.

Post-cancel late-activation hardening (2026-02-14):
- Extended local end-guard duration on `cancelSOS()` to 3 minutes (was short window) to cover delayed background activation attempts.
- Added guard in `_activateSOS()` to block activation of auto-triggered sessions (`crashDetection`/`fallDetection`) while ACFD suppression is active.
- This specifically targets the observed case where SOS UI is cancelled but a later background countdown still promotes to a new active SOS and publishes to SAR.

Cross-isolate guard cache hardening (2026-02-14):
- Added `SharedPreferences.reload()` before reading both local end-guard and ACFD suppression keys in `SOSService`.
- This ensures background/headless isolates do not use stale cached values after `I'm OK` cancel, so `_activateSOS()` suppression/end-guard checks see the latest persisted state.
- Validation: `flutter analyze` => No issues found.

Countdown UI visibility hardening (2026-02-14):
- Improved countdown dialog action layout so the `I'm OK` button remains visible and tappable on constrained/smaller displays (`scrollable` dialog + full-width primary action).
- Added explicit voice verification status line (`ON` / `OFF`) in the countdown dialog.
- Updated SOS page voice-active indicator logic to treat pending voice-phase metadata as active, ensuring voice status displays during transient Firestore/session hydration gaps.
- Validation: `flutter analyze` => No issues found.

Voice verification flow restoration (2026-02-14):
- Fixed root cause where pre-activation voice verification was effectively disabled (`_startPreActivationVoiceVerificationIfNeeded()` always returned `false`), which prevented voice verification UI from ever appearing in normal countdown flow.
- Restored guarded pre-activation voice phase startup (respects auto-trigger/high-speed/session status rules and `voice_verification_enabled`).
- Countdown expiry now attempts pre-activation voice verification first; SOS auto-activation runs only when that phase is not applicable.
- Added prefs cache refresh in voice-verification setting read path to avoid stale cross-isolate setting reads.
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

ACFD second-trigger responsiveness hardening (2026-02-14):
- Reduced ACFD/session restart cooldown from 60s to 12s in normal mode, and to 2s in testing mode, so legitimate second shake/fall tests are not dropped for a full minute.
- Added explicit cooldown-block debug logs in crash/fall handlers and session-start guard to make trigger suppression reason visible during field testing.
- Existing duplicate protections remain intact (active-session guard, start lock, activation lock, cancel suppression window).
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

Countdown/voice dialog fallback hardening (2026-02-14):
- Fixed UI race where countdown dialog could early-exit on pending voice phase, but voice dialog might not actually mount in that frame, leaving no visible `I'm OK` cancel path.
- `SOSPage._showSOSCountdownDialog()` now falls back to showing countdown dialog unless voice dialog is actually queued/showing.
- Removed pending-voice early-suppression in the dialog post-frame gate so countdown can still render as a safe fallback while voice state settles.
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

Official ACFD countdown standardization (2026-02-14):
- Locked ACFD/SOS countdown flow to a single official 30-second path (`AppConstants.acfdOfficialCountdownSeconds`) with the existing countdown UI (`I'm OK` cancel button + voice verification dialog flow).
- Removed variable countdown-duration plumbing from `SOSService` (`countdownSeconds` start parameter and `metadata.countdownDurationSeconds` writes/restore reads) to prevent multi-path duration drift.
- Retained countdown restore via `metadata.countdownEndTimeMs` with official constant fallback for safer resume behavior.
- Aligned legacy `EmergencyScreen` local countdown state to the same official countdown constant to remove hidden alternate timing behavior.
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

Device confirmation (2026-02-14):
- Operator confirmed official ACFD flow now behaves correctly on device:
  - 30s countdown UI displays properly.
  - Voice verification dialog appears in flow.
  - `I'm OK` button is visible and cancels reliably.

Final cleanup pass (2026-02-14):
- Removed temporary/high-noise SOS countdown investigation logs from `SOSPage` (per-tick and transition debug spam).
- No functional logic changes in this pass; countdown/voice/cancel behavior remains on the validated official flow.
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

Final cleanup pass (SOSService log noise trim, 2026-02-14):
- Removed repetitive activation lifecycle debug logs in `SOSService` (`activateSOSImmediately` / `_activateSOS` connectivity/location trace spam).
- Preserved safety-critical guard diagnostics (cooldown/suppression/end-guard block logs) for incident triage.
- No functional behavior changes.
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

Final cleanup pass (ACFD debug-noise trim, 2026-02-14):
- Removed non-actionable ACFD routine chatter from background isolate and startup paths (`acfd_background.dart`, `app_service_manager.dart`) such as ping/setEnabled/status-threshold/info traces.
- Preserved failure/recovery diagnostics (native wake failures, test-trigger failures, heartbeat missing/stale recovery, monitoring start failures).
- No functional behavior changes.
- Validation: `flutter analyze` => No issues found; focused tests => passed (7/7).

Verification rerun (2026-02-14):
- Static analysis: `flutter analyze` => No issues found.
- Focused automated tests: passed (7/7):
  - `test/e2e/sos_flow_test.dart`
  - `test/services/sensor_service_test.dart`
  - `test/voice_session_controller_test.dart`
  - `test/coordinator_fallback_test.dart`
- Build verification:
  - `flutter build apk --debug --flavor sos -t lib/main_sos.dart` => success (`build/app/outputs/flutter-apk/app-sos-debug.apk`)
  - `flutter build apk --debug --flavor sar -t lib/main_sar.dart` => success (`build/app/outputs/flutter-apk/app-sar-debug.apk`)
- Status: automated verification complete; final release sign-off still requires operator manual/device scenarios.

  ## 4f. Manual Device Validation Checklist (Operator Sign-off)

  Execution context:
  - Device ID: `ZY22LZMX9T`
  - SOS flavor: `lib/main_sos.dart`
  - SAR flavor: `lib/main_sar.dart`

  Mark each item as pass/fail and add notes/screenshots/log references where relevant.

  ### A. ACFD + Countdown UI (Official 30s flow)
  - [x] A1. Trigger ACFD (shake/test trigger) and verify countdown dialog appears immediately.
  - [x] A2. Verify countdown duration is 30 seconds.
  - [x] A3. Verify `I'm OK` button is visible and tappable throughout countdown.
  - [x] A4. Verify voice verification dialog appears in countdown flow (or safe fallback still keeps `I'm OK` visible).
  - [x] A5. Tap `I'm OK` and verify SOS is cancelled (no active SOS state remains in SOS UI).

  ### B. Post-cancel Safety / No unintended reactivation
  - [x] B1. After `I'm OK`, verify no delayed/new SOS session appears within suppression window.
  - [x] B2. Verify no new SAR ping is published after cancellation.
  - [x] B3. Re-trigger ACFD after cooldown window and verify it starts normally (second trigger responsiveness).

  ### C. SOS/SAR State Consistency
  - [x] C1. Activate SOS and verify SAR receives one active incident (no duplicate active pings).
  - [x] C2. From SAR, change status (acknowledged/assigned/en route) and verify SOS app phase label updates.
  - [x] C3. Resolve/reset session and verify both SOS and SAR clear active state consistently.

  ### D. Offline/Online Reliability
  - [x] D1. Trigger SOS while offline and verify queued behavior is shown in SOS app.
  - [x] D2. Restore connectivity and verify queued SOS/pings deliver once (no duplicate publish).
  - [x] D3. Cancel/reset after reconnect and verify terminal status remains terminal (no status pushback regression).

  ### E. Closed-app / Background ACFD
  - [x] E1. Force-stop app, trigger ACFD, verify app wake/countdown behavior is correct.
  - [x] E2. Verify background flow remains stable and follows the official path.
  - [x] E3. Verify cancellation from this path behaves the same as open-app flow.

  ### F. Final Sign-off
  - [x] F1. `flutter analyze` clean on candidate build.
  - [x] F2. Focused tests pass (7/7).
  - [x] F3. SOS + SAR debug builds succeed.
  - [ ] F4. Operator approval recorded (name/date).

  Operator sign-off:
  - Name: ____________________
  - Date/Time: ____________________
  - Build tested: ____________________
  - Result: [ ] PASS  [ ] FAIL
  - Notes:
    - ________________________________________________
    - ________________________________________________

  Offline/SAR ping note (2026-02-14):
  - Applied safe fix for D2 failure mode where queued SOS items could be skipped after reconnect if queue id and active marker diverged during canonical session-id adoption.
  - `OfflineSOSQueueService.processQueue()` now accepts `originSessionId` alias reconciliation and delivers using canonical active session payload.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  Closed-app ACFD E1 retest note (2026-02-14):
  - Applied safe debug/testing-mode-only bypass for post-cancel ACFD suppression window in `SOSService._isAcfdSuppressed()` to avoid false-negative shake tests during rapid validation cycles.
  - Production/release suppression behavior is unchanged.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  Runtime ACFD self-heal reliability note (2026-02-14):
  - Added lightweight ACFD health re-arm on app resume in `AppServiceManager` to reduce cases where prolonged/continuous testing leaves ACFD partially inactive until a full `flutter run` restart.
  - Resume self-heal now re-registers SOS callbacks, reapplies detection settings, restarts sensor monitoring if needed, and ensures background ACFD service is enabled (with recovery check).
  - Includes short cooldown guard to avoid repeated heavy work during rapid lifecycle flapping.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  Offline reconnect latency hardening note (2026-02-14):
  - Fixed delayed D2 delivery path where reconnect-triggered queue flushes could be deferred by startup grace/backoff windows.
  - `OfflineSOSQueueService.processQueue()` now supports reconnect-triggered immediate flush (`bypassStartupGrace: true`) for interface-online/effectively-online transitions and SOS connectivity redelivery path.
  - Tightened live-session short retry interval on reconnect when internet probe is not yet reachable (15s → 4s) to speed SAR ping publish confirmation.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  Closed-app countdown-start recovery hardening note (2026-02-14):
  - Fixed E1/E2 failure mode where background/closed-app ACFD trigger could stop after a single countdown-start exception, resulting in no visible 30s countdown and no SOS activation.
  - `SOSService._startAcfdCountdownLocked()` now applies guarded recovery: quick local restore/adopt, one short retry for countdown start, then safety fallback to immediate activation if countdown start repeatedly fails.
  - Goal: ensure closed-app auto-trigger never fails silently; countdown remains primary path, activation fallback only on repeated internal start failure.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  ACFD materializing-lock loop fix (2026-02-14):
  - Investigated logs showing repeated `SOS start blocked: another SOS session is still materializing` during crash-trigger handling.
  - Root cause: cross-isolate/local marker drift could make restore miss the in-flight session, so ACFD retries stayed blocked by materializing guard.
  - `SOSService` now treats materializing errors as recoverable handoff, adopts in-flight session before retry/fallback, and heals local marker/session-id alias drift (`originSessionId` reconciliation) during local restore.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  Lock-screen wake behavior adjustment (2026-02-14):
  - Investigated report where closed-app ACFD shake opened lock-screen PIN entry instead of keeping notification/alarm-only behavior.
  - ACFD auto-trigger now avoids forced foreground wake/navigation when running in headless/background isolate (closed-app/lock-screen path).
  - Main-isolate/in-app behavior is unchanged: countdown UI still opens normally while app is already active.
  - Validation after fix: `flutter analyze` clean; focused tests pass (7/7).

  Closed-app ACFD notification/alarm restoration (2026-02-14):
  - Investigated report where closed-app/screen-off ACFD could activate SOS without an obvious local alert.
  - `SOSService` now emits a high-priority local detection notification in background/headless auto-trigger paths (crash/fall) and posts persistent SOS activation notification on activation for auto-triggered flows.
  - This preserves no-forced-wake lock-screen behavior while restoring user-visible alerting when the app is not foregrounded.
  - Validation after fix: `flutter analyze` clean.
  - Manual E1/E2 retest required: verify notification/alarm is present during closed-app screen-off trigger.

  Closed-app headless alert fallback hardening (2026-02-14):
  - Follow-up for E1 failure case (`SOS triggered but no notification/alarm`): in some headless/background runs, Flutter local notification plugin is unavailable, so Dart-side notification calls can be dropped.
  - Added native fallback path in `AcfdFlutterService` (`notifyAcfdAlert`) and routed headless callback reasons (`acfd_alert_*` / `sos_alert_*`) from `acfd_background.dart`.
  - `SOSService` now falls back to native alert-only ACFD notification posting when Flutter notification display fails in headless mode, without forcing app wake.
  - Validation after fix: `flutter analyze` clean.
  - Manual E1 retest required: verify closed-app screen-off shake now produces notification/alarm reliably.

  Closed-app headless alert routing fix (2026-02-14):
  - Reproduced E1 again (`still no notification/alarm appear`) after initial fallback patch.
  - Root cause: Flutter local notification calls in headless isolate can no-op without throwing, so fallback path was not always entered.
  - `SOSService` now routes ACFD detection/activation alerts directly to native alert posting when running headless (`!_isMainIsolate`) and also checks local plugin readiness (`NotificationService.isLocalPluginReady`) before using Flutter local notifications.
  - Validation after fix: `flutter analyze` clean.
  - Manual E1 retest required.

  Alert-tap startup-freeze mitigation (2026-02-14):
  - Follow-up after operator report: notification/alarm appears, but SOS app can freeze during startup when opened from the alert.
  - Root cause candidate: alert-only notification tap intent was setting `from_acfd=true`, which triggers lock-screen wake/dismiss handling in `MainActivity.handleAcfdWake()` intended for forced full-screen wake flow.
  - `AcfdFlutterService.postAcfdAlertNotification()` now opens `MainActivity` with `from_acfd=false` for alert-only taps, preserving normal startup path.
  - Validation: Kotlin compilation reached `:app:compileSosDebugKotlin`; full APK merge blocked by disk-space error (`There is not enough space on the disk`).
  - Manual E1/E2 retest required.

  Alert persistence behavior fix (2026-02-14):
  - Operator feedback: alert appears, but alarm stops when phone screen is opened before notification tap.
  - Added native continuous alarm loop in `AcfdFlutterService` for alert-only ACFD notifications (`MediaPlayer` loop on default alarm URI) so alarm persists until user interaction.
  - Added explicit stop action (`ACFD_STOP_ALERT`) and invoked it from `MainActivity` open/reopen paths (`onCreate`/`onNewIntent`) so alarm stops only when app is actually opened from notification/user action.
  - Intended behavior: alert keeps alarming while pending; on notification tap, app opens and 30s countdown flow proceeds.
  - Validation: `:app:compileSosDebugKotlin` build success.
  - Manual E1/E2 retest required.

  Final expected behavior (locked, 2026-02-15):
  - ACFD impact detected while app is closed/screen-off triggers immediate local alarm notification.
  - Official 30s SOS countdown starts immediately in background/headless flow.
  - Pre-activation voice verification phase starts with countdown in background.
  - When app is opened from alert/notification, voice dialog appears immediately from pending voice state.
  - No forced full-screen wake/lock-screen takeover in alert-only mode.

  Functional restoration baseline (locked, 2026-02-15):
  - Stage status: SOS + SAR apps are considered fully functional for current release scope.
  - This stage is designated as the restoration point for future rollback/recovery.
  - Restore target criteria: preserve official ACFD flow, single active SOS ping behavior, and verified SOS/SAR state consistency.
  - Recommended release control: create/retain an annotated git tag for this exact state before further feature changes.
  - Recommended restoration tag name: `v1.0.1+5-restoration-2026-02-15`.
  - Tag command (PowerShell):
    - `$REL_TAG = "v1.0.1+5-restoration-2026-02-15"`
    - `git tag -a $REL_TAG -m "SOS/SAR restoration baseline (2026-02-15)"`
    - `git push origin $REL_TAG`
  - Tag command (bash):
    - `REL_TAG="v1.0.1+5-restoration-2026-02-15"`
    - `git tag -a "$REL_TAG" -m "SOS/SAR restoration baseline (2026-02-15)"`
    - `git push origin "$REL_TAG"`

## 5. Fingerprint Archival
Append/update fingerprints in `SIGNING_FINGERPRINTS.md` (create if missing):
```
## YYYY-MM-DD Rotation
Alias: redping-key
SHA-256: 53b37f0b16d52918a6c4d0477200a3214b334f5fd36d1467768a05574215f469
SHA-1:    406fc289d379cd0a22d7329a607abc7e91733b8a
DN:       CN=Redping, O=Redping, L=City, ST=State, C=US
```
Store outside repo in secure secrets vault as well.

## 6. (Optional) Play Console Prep
- [ ] Upload AAB to internal testing track.
- [ ] Confirm Google Play reports correct SHA-1 (matches above).
- [ ] Roll out to closed/instrumented testers before production.

## 7. Roll-forward Strategy
If future rotation: keep prior fingerprints in the same doc with date stamps; never delete old entries.

## 8. Rollback Strategy
If CI artifacts show debug cert or mismatched fingerprint:
1. Stop distribution and revoke tag (`git tag -d <tag>; git push origin :refs/tags/<tag>`).
2. Re-run keystore rotation script or restore previous backup `.bak` file.
3. Rebuild and re-tag.

---
Checklist owner: Release Engineer / Security.

Privacy/Security UI hardening pass (2026-02-16):
- Fixed SOS routing to use the full Privacy & Security page implementation (removed placeholder route shadowing).
- Replaced dead Privacy Help/Policy route navigations with safe in-page dialogs to avoid broken links.
- Clarified non-enforced security controls as preference-level where backend/platform enforcement is partial.
- Added explicit Compliance fallback card when live compliance status is unavailable.
- Added audit-friendly timestamps (`Last updated` / `Last assessed`) for privacy, security, and compliance blocks.
- Added safe `Reset Privacy/Security Defaults` button in Privacy Quick Actions with confirmation.
  - Scope: resets privacy preferences and security configuration to defaults only.
  - Does not delete data and does not revoke OS-level permissions.
- Validation: `flutter analyze` => No issues found.

Privacy/Security SOS realignment (2026-02-16):
- Reconstructed `PrivacySettingsPage` from legacy multi-tab/doctor-oriented surface into a simplified SOS-focused page.
- Scope now aligns to current SOS implementation:
  - SOS data-use summary
  - Relevant permissions (Location, Notifications, Microphone when present)
  - Minimal privacy controls (Location Sharing, Crash Reporting)
  - Basic security status + refresh
  - Safe actions (App Settings, Export Data, Reset Privacy/Security Defaults)
- Removed compliance-heavy/legacy sections from the UI surface to reduce mismatch risk.
- Validation: `flutter analyze` => No issues found.

SAR alignment (2026-02-16):
- SAR router now uses the same simplified Privacy & Security page implementation.
- Privacy copy is variant-aware: SOS build shows SOS data-use text; SAR build shows SAR coordination/rescue data-use text.
- Validation: `flutter analyze` => No issues found.

Quick SAR run-through checklist (Privacy & Security):
- [ ] Launch SAR flavor (`flutter run --flavor sar -t lib/main_sar.dart`) and open `Settings -> Privacy & Security`.
- [ ] Verify header copy shows `SAR Data Use` (not `SOS Data Use`).
- [ ] Verify permissions card renders relevant permission statuses and `Allow` works for denied entries.
- [ ] Verify `Location Sharing` subtitle references SAR coordination and toggle persists after page reopen.
- [ ] Verify `Security` card refresh updates threat/encryption status and app remains stable.
- [ ] Verify `Reset Privacy/Security Defaults` shows confirmation and resets only preferences (no data deletion, no OS permission revoke).

## 9. RedPing Safety Scope (SOS + SAR)

Product positioning (official):
- RedPing is a safety communication and coordination app.
- RedPing helps people in distress quickly notify emergency contacts and share information to speed up response.
- RedPing can support coordination workflows with SAR participants.
- RedPing does **not** own or operate emergency teams.
- RedPing does **not** replace public emergency services (e.g., 000/911/112) or SAR authorities.

Operational disclaimer:
- Users should still contact official emergency services immediately where available.
- RedPing is designed to reduce response friction (faster alerts, clearer location/context), not to serve as a substitute for emergency dispatch.

Current SOS capabilities (app scope):
- Manual SOS activation and alert escalation flow.
- ACFD-assisted triggers (crash/fall detection) with countdown/verification safety flow.
- Emergency contact alerting and SMS fallback support.
- Location sharing and incident status updates.
- Offline-aware handling with queued delivery/retry behavior.

Current SAR capabilities (app scope):
- SAR dashboard/incident visibility based on app access model.
- SAR participation and coordination workflows (role/tier dependent).
- Mission status progression (e.g., acknowledged/assigned/en-route/resolved).
- Organization/team features for higher-tier administrative workflows.

Copy/use guidance:
- Marketing, in-app text, legal copy, and support docs must consistently state that RedPing is a communication aid and coordination layer.
- Avoid wording that implies RedPing is an emergency responder operator or guaranteed replacement for emergency services.

## 4f. Latest Local Verification (2026-02-16)

Production-readiness checks completed:
- `flutter analyze` => No issues found.
- `flutter test` => Passed (`15` skipped tests).

Latest full-suite rerun confirmation (2026-02-16):
- `flutter test` => `00:13 +116 ~15: All other tests passed!`
- Timestamp (local): `2026-02-16 22:00:10 +10:00`
- Terminal exit code: `0`

Release artifact builds completed successfully:
- SOS APK: `build/app/outputs/flutter-apk/app-sos-release.apk` (~119.5 MB)
- SOS AAB: `build/app/outputs/bundle/sosRelease/app-sos-release.aab` (~89.9 MB)
- SAR APK: `build/app/outputs/flutter-apk/app-sar-release.apk` (~120.6 MB)
- SAR AAB: `build/app/outputs/bundle/sarRelease/app-sar-release.aab` (~90.4 MB)

Latest SOS build confirmation (local artifact timestamps):
- SOS APK timestamp (local): `2026-02-16 21:12:55 +10:00`
- SOS AAB timestamp (local): `2026-02-16 21:15:37 +10:00`
- Build command status: `success` (completed without errors)

Latest SAR build confirmation (local artifact timestamps):
- SAR APK timestamp (local): `2026-02-16 21:27:41 +10:00`
- SAR AAB timestamp (local): `2026-02-16 21:28:59 +10:00`
- Build command status: `success` (completed without errors)

Obfuscation/symbol split used for both flavors:
- `--obfuscate --split-debug-info=build/debug-info/sos/...`
- `--obfuscate --split-debug-info=build/debug-info/sar/...`

## 4g. Auditable SOS Duplicate-Proof Run (2026-02-16)

Objective:
- Verify that one full SOS activation produces exactly one SOS ping creation and one SOS ping publish event (no duplicate ping generation).

Proof-run setup:
- Device: `ZY22LZMX9T` (`moto g04s`)
- SOS app run target: `flutter run -d ZY22LZMX9T --flavor sos -t lib/main_sos.dart`
- SAR app: operator-confirmed running concurrently
- Log reset before run: `adb logcat -c`

Captured evidence (single activation run):
- `SOSPingService: Creating REAL SOS ping from session ZWFiQW2ttTyuXQgJszQW ...`
- `SOSService: Published SOS ping to SAR dashboard for session ZWFiQW2ttTyuXQgJszQW`

Deterministic grouped counts from `adb logcat -d`:
- CREATE_COUNTS: `ZWFiQW2ttTyuXQgJszQW = 1`
- PUBLISH_COUNTS: `ZWFiQW2ttTyuXQgJszQW = 1`

Result:
- ✅ PASS — no duplicate SOS ping observed in this auditable proof run.

Supporting artifact:
- `SOS_DUPLICATE_PROOF_RUN_2026-02-16.md`

## 4h. Auditable SOS Duplicate-Proof Re-run (2026-02-16)

Objective:
- Repeat duplicate-proof validation to confirm stability across consecutive live runs.

Proof-run setup:
- Device: `ZY22LZMX9T` (`moto g04s`)
- SOS app target: `flutter run -d ZY22LZMX9T --flavor sos -t lib/main_sos.dart`
- SAR app: operator-confirmed running concurrently
- Log reset before re-run: `adb logcat -c`

Captured evidence (second single activation):
- `SOSPingService: Creating REAL SOS ping from session GqduI26RcpMGswdpOrZP ...`
- `SOSService: Published SOS ping to SAR dashboard for session GqduI26RcpMGswdpOrZP`

Outcome:
- ✅ PASS — second consecutive auditable run also shows one create + one publish for one session (no duplicate SOS ping observed).

Supporting artifact:
- `SOS_DUPLICATE_PROOF_RUN_2026-02-16.md` (second run section appended)
