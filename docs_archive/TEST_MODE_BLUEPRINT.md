# RedPing Comprehensive Testing Mode Blueprint v2.0

## 1. Purpose & Goals
Testing Mode provides a **production-equivalent environment** with **lowered sensitivity thresholds** to enable rapid testing of complete ACFD detection → verification → escalation → SOS flows using simple gestures (phone shaking, gentle drops). Unlike v1.0 which bypassed verification and suppressed dialogs, **v2.0 runs the full production pipeline** with comprehensive real-time diagnostics.

### High-Level Objectives
1. **Full Production Flow Testing:** All services, dialogs, SMS, verification, escalation run exactly as in production.
2. **Lowered Sensitivity Triggers:** Simple phone shake or gentle motion triggers ACFD (adjustable thresholds).
3. **Comprehensive Diagnostics:** Real-time sensor data, state transitions, timing metrics, decision logic visible during tests.
4. **Zero Functional Bypass:** No shortcuts—test the actual user experience end-to-end.
5. **Diagnostic Export:** Structured telemetry export for post-run analysis and debugging.
6. **Safety Preserved:** Real emergency detection still works; test mode only lowers thresholds, doesn't suppress responses.

## 2. Scope (v2.0 - Production Flow Testing)

### What Testing Mode v2.0 DOES:
- **Lowers detection thresholds:** Crash/fall sensitivity reduced so simple phone shaking triggers ACFD.
- **Runs full production pipeline:** All verification, dialogs, SMS, escalation services execute normally.
- **Enables comprehensive diagnostics:** Real-time overlay showing sensor data, states, timings, decisions.
- **Provides diagnostic export:** JSON/CSV export of complete test session data.
- **Maintains all safety features:** Haptics, alerts, manual SOS, kill switches all function normally.

### What Testing Mode v2.0 DOES NOT:
- **Bypass any logic:** No shortcuts or suppression of verification/dialogs/services.
- **Modify raw sensor data:** Sensors report actual values; only thresholds change.
- **Disable production features:** SMS, Firebase logging, notifications all active.
- **Override emergency call kill switch:** `EMERGENCY_CALL_ENABLED = false` remains in effect.
- **Send test SMS to real contacts:** Optional flag to use test phone numbers instead.

## 3. Activation Mechanisms
| Mechanism | Layer | Use Case |
|-----------|-------|----------|
| Runtime UI Toggle (Settings) | End-user tester | Ad‑hoc bench/run sessions |
| `TestingMode.activate()` API | Developer / integration tests | Programmatic harness setup |
| Dart define flag `FEATURE_FLAGS={"aiVerificationTestingMode":true}` | CI / scripted builds | Automated device labs |
| Environment gating (appEnv==test) | Build pipeline | Broader test suite runs |

### Files & Hooks
- `lib/config/testing_mode.dart`: Runtime state & activation helpers.
- `lib/core/constants/app_constants.dart`: Mutable lab flags + `testingModeEnabled`.
- `lib/services/ai_verification_service.dart`: Reads testing bypass flags to skip auto-analysis phases.
- `lib/features/settings/presentation/pages/settings_page.dart`: UI toggle (SwitchListTile) for Testing Mode.

## 4. Behavior Matrix v2.0

| Feature | Normal Mode | Testing Mode v2.0 | Notes |
|---------|-------------|-------------------|-------|
| **Detection Thresholds** | Production (35G crash, 1m fall) | **Lowered (8G crash, 0.3m fall)** | Configurable via constants |
| **Verification Dialogs** | Full production UI | **Full production UI** | No suppression |
| **Countdown Dialog** | 10-second countdown | **10-second countdown** | Exact production behavior |
| **AI Verification** | Full voice/motion/inactivity | **Full voice/motion/inactivity** | All phases execute |
| **SMS Escalation** | Production contacts | **Test contacts OR production** | Toggle via flag |
| **Diagnostic Overlay** | None | **Real-time sensor/state display** | Floating window with metrics |
| **Logging** | Standard Firebase | **Enhanced + diagnostic buffer** | Extra timing/decision data |
| **Sensor Sensitivity** | Normal accelerometer | **Same raw data, lower thresholds** | Actual physics preserved |
| **Manual SOS** | Available | **Available** | Identical behavior |
| **Kill Switches** | Active | **Active** | Emergency call disabled remains |

## 5. Test Mode Sensitivity Configuration

### Threshold Adjustments (AppConstants)
```dart
// lib/core/constants/app_constants.dart

// Production thresholds
static const double crashThresholdG = 35.0;           // 35G for crash
static const double fallHeightMeters = 1.0;            // 1 meter fall
static const double severeImpactThresholdG = 250.0;   // 250 m/s² severe

// Test mode thresholds (when testingModeEnabled = true)
static const double testModeCrashThresholdG = 8.0;          // 8G (phone shake)
static const double testModeFallHeightMeters = 0.3;         // 0.3m (gentle toss)
static const double testModeSevereImpactThresholdG = 15.0;  // 15 m/s²
static const double testModeJerkThreshold = 50.0;           // 50 m/s³ (vs 200)
static const double testModeDecelerationThreshold = 5.0;    // 5 m/s² (vs 20)

// Gesture patterns that trigger in test mode
static const double testModeShakeThreshold = 6.0;           // Moderate phone shake
static const int testModeShakeWindowMs = 1000;              // 1 second window
static const int testModeMinShakeCount = 3;                 // 3+ shakes
```

### Dynamic Threshold Application
When `testingModeEnabled == true`, sensor service uses test thresholds:
- All ACFD detection logic runs normally
- Physics calculations unchanged
- Only comparison thresholds lowered
- Preserves realistic timing and flow

## 6. Comprehensive Diagnostic System

### 6.1 Real-Time Diagnostic Overlay
**Floating translucent window** showing live data during test sessions:

```dart
// lib/features/testing/widgets/diagnostic_overlay.dart

DiagnosticOverlay(
  visible: testingModeEnabled,
  sections: [
    SensorDataSection(
      accelerometerX/Y/Z: current values,
      gyroscopeX/Y/Z: current values,
      magnetometerX/Y/Z: current values,
      magnitude: calculated resultant,
      jerk: rate of change,
    ),
    DetectionStateSection(
      currentState: idle | detecting | verifying | escalating,
      lastTrigger: crash | fall | manual,
      threshold: production vs test value comparison,
      confidence: AI verification score,
      timeInState: milliseconds,
    ),
    TimingMetricsSection(
      detectionTimestamp: exact time,
      verificationStarted: elapsed time,
      verificationPhase: voice | motion | inactivity,
      escalationTimer: countdown remaining,
      smsSentCount: number of SMS,
    ),
    DecisionLogSection(
      lastDecision: why ACFD triggered,
      thresholdMet: which threshold exceeded,
      patternMatched: crash/fall pattern details,
      falseAlarmIndicators: pickup, voice detected, etc.,
    ),
  ],
)
```

### 6.2 Diagnostic Data Buffer
**In-memory circular buffer** capturing detailed events:

```dart
class DiagnosticEvent {
  final DateTime timestamp;
  final String eventType;
  final String phase;
  final Map<String, dynamic> data;
  final Duration elapsedSinceDetection;
}

// Captures:
- Sensor readings (every 100ms during active detection)
- State transitions with reasons
- Threshold comparisons (value vs threshold)
- Timer starts/stops
- User interactions (dialog responses, cancellations)
- Service calls (SMS, Firebase, notifications)
- AI verification decisions
- False alarm indicators detected
```

### 6.3 Test Session Export
Export complete diagnostic data as structured JSON:

```dart
// lib/services/test_mode_diagnostic_service.dart

TestSessionExport {
  sessionId: UUID,
  startTime: timestamp,
  endTime: timestamp,
  deviceInfo: {
    model, osVersion, appVersion,
    sensorCapabilities,
  },
  configuration: {
    testModeEnabled: true,
    thresholds: {production vs test values},
    smsTestMode: true/false,
  },
  events: [
    {timestamp, type, phase, data, elapsed},
    ...
  ],
  summary: {
    totalDetections: count,
    truePositives: count,
    falseAlarms: count,
    avgResponseTime: milliseconds,
    smsDelivered: count,
  },
  sensorTrace: {
    accelerometer: [[x,y,z,t], ...],
    gyroscope: [[x,y,z,t], ...],
  },
}
```

Export formats:
- JSON (full detail)
- CSV (tabular for spreadsheet analysis)
- Share via platform share sheet

## 7. SMS Test Mode Configuration

### Test Contact Override
```dart
// lib/core/constants/app_constants.dart

static bool useSmsTestMode = false;  // Toggle via settings

static List<String> testModeEmergencyContacts = [
  '+1234567890',  // Test device 1
  '+0987654321',  // Test device 2
];

// When useSmsTestMode == true:
// - SMS sent to testModeEmergencyContacts instead of user's real contacts
// - SMS messages prefixed with [TEST MODE]
// - Allows safe testing without spamming real emergency contacts
```

### Test Mode SMS Template
```
[TEST MODE] 🚨 EMERGENCY ALERT 🚨

This is a TEST MODE emergency alert from RedPing.

User: John Doe (TEST USER)
Phone: +1234567890
Time: 2:45 PM, Nov 14, 2025

Location: 
https://maps.google.com/?q=37.7749,-122.4194

Status: Crash detected (TEST SENSITIVITY)

This is NOT a real emergency - Testing Mode Active

Reply HELP to acknowledge | Reply FALSE for false alarm
```

## 8. Telemetry & Logging Requirements (Enhanced)

### Core Detection Fields
- `detectionType` (crash|fall|manual|shake)
- `detectionReason` (sharpDeceleration, impactSpike, shakePattern, etc.)
- `thresholdUsed` (production vs test value)
- `thresholdExceeded` (actual sensor value vs threshold)
- `testingModeEnabled` (bool) + `activationSource` (ui|api|dart-define)
- `timestamp` (detection time with millisecond precision)

### Verification & Response Fields
- `verificationPhase` (voice|motion|inactivity|skipped)
- `verificationDuration` (milliseconds per phase)
- `verificationOutcome` (genuine|uncertain|falseAlarm|noResponse)
- `userInteractionDetected` (bool, type, timestamp)
- `aiConfidenceScore` (0-1 if computed)
- `falseAlarmIndicators` (pickup, voice, movement patterns)

### Escalation & Timing Fields
- `fallbackTriggered` (bool + latency ms)
- `sosCountdownStarted` (timestamp)
- `sosCountdownCancelled` (bool, at seconds remaining)
- `sosActivated` (timestamp)
- `totalFlowDuration` (detection → activation milliseconds)
- `smsCount` (number sent)
- `smsTestMode` (bool)

### Diagnostic-Specific Fields (Test Mode Only)
- `sensorTraceBuffered` (bool, number of samples)
- `diagnosticEventsRecorded` (count)
- `thresholdComparisons` (all values vs thresholds during detection window)
- `stateTransitions` (list of state changes with timestamps)
- `performanceMetrics` (CPU, memory, battery during session)

### Extended ML Preparation Fields
- `featureSnapshot` (peakMagnitude, jerk, decel, freeFallPattern, sustainedHighImpactCount)
- `environmentContext` (hourOfDay, avgSpeedLastN, stationaryPreImpact, locationCategory)
- `deviceOrientation` (portrait|landscape|flat|pocket)
- `batteryLevel` (percentage at detection time)

## 9. Safety Guardrails v2.0
1. **CI Build Gate:** Testing Mode must not ship pre-enabled (assert `testingModeEnabled == false` in release builds).
2. **Full Production Pipeline:** No bypasses—all verification, dialogs, SMS, Firebase logging runs normally.
3. **Test Contact Protection:** Optional SMS test mode prevents spamming real emergency contacts during testing.
4. **Clear Test Indicators:** All SMS, logs, UI, Firebase entries marked with `[TEST MODE]` prefix or flag.
5. **Emergency Call Kill Switch:** `EMERGENCY_CALL_ENABLED = false` remains active; testing mode doesn't override.
6. **Manual SOS Always Works:** User can trigger real SOS even in test mode; full escalation occurs.
7. **User Cancellation Honored:** Cancel button stops all escalation immediately, no override.
8. **Diagnostic Data Isolation:** Test sessions tagged separately (`testMode: true`) in analytics.
9. **Threshold Safety:** Even lowered thresholds (8G) still detect real emergencies effectively.
10. **Production Behavior Guarantee:** Except detection thresholds, everything behaves exactly as production.
11. **Real Emergency Override:** If production-level thresholds (35G) met during test mode, system escalates normally.
12. **Diagnostic Overlay Non-Intrusive:** Overlay can be minimized/hidden but doesn't block UI interactions.

## 9a. Legacy Safety Guardrails (Kept for Reference)
1. Testing Mode must not ship pre‑enabled in production builds (verify by CI check: reject if `testingModeEnabled == true` during release artifact creation).
2. SMS / real external escalation (enhanced SMS system) remains active; Testing Mode does not suppress the SMS pipeline.
3. **Automated Emergency Calling Disabled:** A global kill switch (`EMERGENCY_CALL_ENABLED = false`) fully prevents any AI‑initiated dialing or dialer auto‑open attempts for severe impacts. This replaces the former “2‑minute native emergency dialer trigger” design. Manual user‑initiated call buttons still function in Testing & Normal Mode.
4. Manual SOS activation always honored—even under dialog suppression.
5. Logs clearly label testing mode to prevent contaminating production analytics.
6. No silent override of user cancellation: cancel still short‑circuits countdown or verification.
7. Response confirmation and false‑alarm SMS keywords (HELP / FALSE) continue to operate identically in testing mode for end‑to‑end flow verification.

## 9. Extensibility Roadmap
| Phase | Enhancement | Description |
|-------|-------------|-------------|
| Short | Persist toggle (SharedPreferences) | Survives app restarts for lab sessions |
| Short | Per‑phase progress callbacks | Real-time UI heartbeat updates (every 5s) |
| Mid | Dynamic threshold sandbox | Adjustable impact/fall sensitivities via UI sliders (stored separately from production prefs) |
| Mid | Sensor replay ingestion | Feed recorded sensor trace files (.json) to AIVerificationService external feed mode |
| Mid | Structured test session export | JSON artifact with all metrics + device build info |
| Long | Automatic regression diff | Compare two sessions’ distributions (impact, false positives) |
| Long | ML feature capture gating | Collect labeled snapshots only when testing mode active with manual annotation action |

## 10. Recommended Test Scenarios
| Category | Scenario | Expected Outcome |
|----------|----------|------------------|
| Crash (bench) | Quick swing then soft stop | Possibly reject (no crash) or uncertain → fallback |
| Crash (vehicle) | Moderate brake from 25–30 km/h | Crash detected → verification sequence |
| Fall (drop) | Pocket-height drop onto cushion | Fall detected → verification/noResponse → fallback |
| False Alarm | Gentle shake cycles | No detection / suppressed heuristics |
| Manual SOS | Long press 10s | Immediate activation (skip countdown) |
| Countdown Cancel | Trigger fallback then cancel at 3s remaining | SOS not activated |
| Testing Toggle Live | Enable mid-verification | Next cycle bypasses auto-analysis |

## 11. Automation Hooks (Future)
- Provide `TestingModeScenarioRunner` class:
  - `runCrashSimulation(duration, pattern)`
  - `runFallSimulation(dropHeight)`
  - Emits structured session artifact.
- Integration with Flutter Driver / next-gen testing harness using sensor mock streams.

## 12. Deactivation Procedure
1. Toggle off via Settings or call `TestingMode.deactivate()`.
2. Confirm dialogs reappear (trigger small test event).
3. Ensure `testingModeEnabled=false` appears in log before publishing release.
4. Run production smoke test (crash & manual SOS) — verify full chain including SMS logging.

## 13. Risk Register
| Risk | Impact | Mitigation |
|------|--------|------------|
| Forget to disable before release | User safety expectations broken | CI gate: assert build variant + flag state |
| Misinterpreted metrics (mixing test & prod) | ML confidence miscalibration | Tag all test sessions; filter in analytics pipeline |
| Over-suppression hides real emergency during field trial | Delayed response | Keep activated UI & manual SOS path always visible |
| Threshold tweaks persist | Elevated false positives in prod | Use separate ephemeral test prefs namespace (`test_*` keys) |

## 14. Future ML Integration Alignment
Testing Mode sessions generate richer labeled buffers for model training without spamming real users. Dedicated ML adapter phases can optionally record raw window feature arrays when `testingModeEnabled` is true and user adds an incident label (e.g., button: “Mark genuine” / “Mark false alarm”).

## 15. Quick Usage Cheat Sheet
```dart
// Enable (runtime)
TestingMode.activate(suppressDialogs: true, aiBypass: true);

// Disable
TestingMode.deactivate();

// Dart define (CI/device farm)
flutter run --dart-define=FEATURE_FLAGS={"aiVerificationTestingMode":true}
```

## 16. Validation Checklist Before Release
- [ ] Settings toggle OFF.
- [ ] No testing bypass feature flag in build command.
- [ ] Sample detection shows full verification dialog.
- [ ] Logs do NOT contain `testingModeEnabled: true`.
- [ ] Fallback + countdown flow verified.

## 17. Current ACFD Logic (Updated Implementation)

### SMS-First Approach
Due to Android/iOS platform limitations preventing auto-dial of emergency services, the app now uses **SMS alerts to emergency contacts** as the primary escalation mechanism after crash/fall detection.

### ✅ Updated: Emergency Dialer Auto-Open Removed
The historical “2‑minute severe impact dialer auto‑open” flow has been retired and is fully disabled by the global kill switch. Under current architecture:
* No automated dialer presentation occurs, even for ≥35G impacts.
* All escalation relies on the enhanced SMS system + manual call UI buttons.
* Manual call actions (hotline card, contact call buttons, quick call methods) remain available and are the sole voice-call path.

**Why Removed:**
Platform restrictions + unconscious user inability to tap “Call” made the feature ineffective; SMS-first plus human verification yields faster, higher fidelity responses.

**Implementation Artifact:** `EMERGENCY_CALL_ENABLED = false` in `ai_emergency_call_service.dart`.

**Re-Enable (Testing Only):** Set constant to `true` or introduce a dart define; not recommended for production.

### Enhanced SMS Escalation Timeline (v2.0)
1. **T0 (Activation):** Initial SMS to top 3 priority contacts (smart selection by priority & availability). Includes reply instructions (HELP / FALSE).
2. **T+2m:** Follow‑up SMS #1 (status reminder + responder acknowledgment if any).
3. **T+4m:** Follow‑up SMS #2.
4. **T+5m:** No-response check → automatic escalation SMS to secondary contacts (those not in initial priority set) if no HELP reply received.
5. **Active Phase Continuation:** Up to 10 active-phase messages (every 2m) unless session resolved/cancelled.
6. **Acknowledged Phase:** If a contact responds (HELP), interval shifts to 10m (acknowledged phase) with status updates.
7. **Resolution:** Final RESOLVED or FALSE-ALARM SMS broadcast to all contacted numbers.

**Safety Core:** Fully automatic multi-contact SMS pipeline + human verification via replies; no auto dialing.

### Response & Availability Features
* Keyword confirmation: HELP, RESPONDING, ON MY WAY, COMING, YES, OK, CONFIRMED.
* False alarm: FALSE, MISTAKE, CANCEL, NO, SAFE.
* Contact availability states: available, busy, emergencyOnly, unavailable, unknown.
* Escalation ensures broader coverage without overwhelming all contacts at T0.

---

## 18. Blueprint Maintenance
Update this document when:
- Verification window timings change.
- New dialog types or suppression flags added.
- ML adapter moves from stub to active inference.
- Additional emergency modes introduce unique countdown semantics.
- Native emergency trigger thresholds or timing adjusted.

---

## 19. Test Mode v2.0 Implementation Guide

### Phase 1: Core Infrastructure (Immediate)
**Files to Create:**
1. `lib/services/test_mode_diagnostic_service.dart` - Diagnostic data collection and export
2. `lib/features/testing/widgets/diagnostic_overlay.dart` - Real-time data display
3. `lib/features/testing/models/diagnostic_event.dart` - Event data structure
4. `lib/features/testing/pages/test_mode_dashboard.dart` - Test session management UI

**Files to Modify:**
1. `lib/core/constants/app_constants.dart` - Add test mode thresholds
2. `lib/services/sensor_service.dart` - Read test mode thresholds when active
3. `lib/services/sms_service.dart` - Add SMS test mode logic
4. `lib/config/testing_mode.dart` - Update activation logic

### Phase 2: Diagnostic Overlay (Immediate)
```dart
// Features:
- Floating draggable window
- Collapsible sections
- Real-time sensor graphs
- State machine visualization  
- Export session button
- Minimize/maximize controls
```

### Phase 3: SMS Test Mode (Immediate)
```dart
// Implementation:
- Add useSmsTestMode toggle in settings
- Override getEmergencyContacts() when test mode active
- Prefix all SMS with [TEST MODE]
- Log test mode state in Firebase
```

### Phase 4: Session Export (Short Term)
```dart
// Export formats:
- JSON: Complete diagnostic data
- CSV: Tabular sensor/event data
- Share: Via platform share sheet
- Storage: Local + optional Firebase upload
```

---

## 20. Quick Start Guide v2.0

### Enable Testing Mode
1. Open RedPing app
2. Go to Settings → Developer Options
3. Toggle "Testing Mode" ON
4. (Optional) Toggle "SMS Test Mode" ON
5. Diagnostic overlay appears

### Trigger Test Detection
**Method 1: Phone Shake**
- Hold phone firmly
- Shake vigorously 3-4 times in 1 second
- 8G threshold triggers crash detection

**Method 2: Gentle Drop**
- Drop phone 30cm (1 foot) onto soft surface
- 0.3m threshold triggers fall detection

**Method 3: Manual SOS**
- Long press SOS button (works same as production)

### Monitor Diagnostics
- Watch real-time overlay for:
  - Current sensor values
  - Threshold comparisons
  - State transitions
  - Timer countdowns
  - Decision logic

### Export Session Data
1. After test completes
2. Tap "Export Session" in diagnostic overlay
3. Choose format (JSON/CSV)
4. Share or save locally

### Disable Testing Mode
1. Settings → Developer Options
2. Toggle "Testing Mode" OFF
3. Diagnostic overlay disappears
4. Production thresholds restored

---

## 21. Validation Checklist v2.0

### Before Release
- [ ] Testing Mode toggle is OFF
- [ ] `testingModeEnabled = false` in AppConstants
- [ ] No test mode dart-defines in build command
- [ ] Sample shake does NOT trigger detection (production thresholds active)
- [ ] Diagnostic overlay does not appear
- [ ] SMS sent to real contacts, not test contacts
- [ ] Firebase logs do not contain `[TEST MODE]` tag
- [ ] Build variant is `release` not `debug`

### Test Mode Functional Verification
- [ ] Toggle ON enables lowered thresholds
- [ ] Phone shake (6-8G) triggers crash detection
- [ ] Gentle drop (0.3m) triggers fall detection
- [ ] Diagnostic overlay displays real-time data
- [ ] Full verification dialog sequence appears
- [ ] AI verification all phases execute
- [ ] 10-second countdown runs normally
- [ ] SMS test mode prevents real contact spam
- [ ] Cancel button stops flow immediately
- [ ] Manual SOS works identically
- [ ] Session export generates valid JSON/CSV
- [ ] Firebase logs tagged with `testMode: true`
- [ ] Production thresholds (35G) still trigger if exceeded

---

## 22. Diagnostic Overlay UI Specification

### Layout
```
┌─────────────────────────────────┐
│ 📊 Test Mode Diagnostics    [–][×]│
├─────────────────────────────────┤
│ ▼ Sensors (Real-time)          │
│   📈 Accel: X:2.1 Y:-0.3 Z:9.8 │
│   📈 Magnitude: 10.1 m/s²      │
│   📈 Jerk: 5.2 m/s³            │
├─────────────────────────────────┤
│ ▼ Detection State              │
│   🟢 DETECTING                  │
│   ⚡ Threshold: 8.0G (Test)    │
│   ⚡ Current: 7.2G              │
│   ⏱️  Time: 2.3s                │
├─────────────────────────────────┤
│ ▼ Verification (ACTIVE)        │
│   🎤 Voice Phase: 15s remaining │
│   📊 Confidence: 0.65           │
│   🔍 Indicators: None           │
├─────────────────────────────────┤
│ ▼ Timers                       │
│   ⏲️  Detection: 00:05.234      │
│   ⏲️  Verification: 00:12.102   │
│   ⏲️  Countdown: Not started    │
├─────────────────────────────────┤
│ ▼ SMS Status                   │
│   📧 Mode: TEST CONTACTS       │
│   📧 Sent: 0                   │
│   📧 Next: Pending activation  │
├─────────────────────────────────┤
│ [📤 Export] [🔄 Reset] [⏸️ Pause]│
└─────────────────────────────────┘
```

### Controls
- **Drag:** Move overlay anywhere on screen
- **[–]:** Minimize to small badge
- **[×]:** Hide (access via settings)
- **▼/▶:** Collapse/expand sections
- **Export:** Generate and share session data
- **Reset:** Clear current session, start fresh
- **Pause:** Freeze display for screenshot/review

---

## 23. Advanced Features (Future)

### Threshold Adjustment UI
```dart
// Settings → Test Mode → Sensitivity
Crash Threshold: [====|====] 8G - 35G
Fall Height:     [==|======] 0.3m - 1.0m  
Shake Threshold: [===|=====] 6G - 15G
```

### Sensor Trace Visualization
```dart
// After session export, view:
- Time-series graphs of accelerometer XYZ
- Magnitude overlay with threshold lines
- State transition markers
- Decision points annotated
- Zoom/pan controls
```

### Automated Test Runner
```dart
TestScenario scenario = TestScenario(
  name: "Crash Detection Flow",
  steps: [
    SimulateShake(intensity: 8.5, duration: 1000),
    WaitFor(VerificationDialog()),
    SimulateVoice("I'm okay"),
    AssertOutcome(Outcome.falseAlarm),
  ],
);

TestRunner.run(scenario);
```

---

Maintained: 2025-11-14
Owner: Safety/AI Integration Team
Revision: v2.0 (Complete Rebuild: Production Flow + Comprehensive Diagnostics)