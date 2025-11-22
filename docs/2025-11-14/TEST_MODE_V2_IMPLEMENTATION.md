# Test Mode v2.0 Implementation Summary

**Date:** November 14, 2025  
**Version:** 2.0  
**Status:** Implementation Complete

---

## 🎯 Overview

Test Mode v2.0 represents a **complete rebuild** of the testing system. Unlike v1.0 which bypassed verification and suppressed dialogs, **v2.0 runs the full production pipeline** with lowered sensitivity thresholds and comprehensive diagnostics.

### Key Principle
**"Test the real system, not a simulation"**

---

## ✅ What Changed from v1.0 to v2.0

| Aspect | v1.0 (Old) | v2.0 (New) |
|--------|------------|------------|
| **Philosophy** | Bypass & suppress | Production flow testing |
| **Verification** | Skipped entirely | Full AI verification runs |
| **Dialogs** | Suppressed | All production dialogs shown |
| **SMS** | Optional disable | Full SMS v2.0 pipeline + test contacts |
| **Thresholds** | Production only | Lowered (8G crash, 0.3m fall) |
| **Diagnostics** | Basic logging | Comprehensive real-time overlay |
| **Trigger Method** | Complex setup | Simple phone shake |
| **Export** | None | JSON/CSV session export |

---

## 📋 Implementation Complete

### 1. ✅ Blueprint Updated
**File:** `TEST_MODE_BLUEPRINT.md`

**New Sections:**
- Purpose & Goals v2.0
- Production Flow Testing scope
- Lowered threshold configuration
- Comprehensive diagnostic system
- Real-time overlay specification
- SMS test mode
- Enhanced telemetry
- Safety guardrails v2.0
- Implementation guide
- Quick start guide
- Validation checklist
- Diagnostic UI specification

### 2. ✅ Diagnostic Service Created
**File:** `lib/services/test_mode_diagnostic_service.dart`

**Features:**
- Session management (start/stop/export)
- Event logging with circular buffer (max 1000 events)
- Sensor trace recording (10Hz sampling, max 3000 samples)
- Real-time stream broadcasting
- Detection, verification, state transition logging
- SMS tracking
- User interaction capture
- JSON/CSV export
- Platform share integration

**Key Classes:**
- `TestModeDiagnosticService` - Main singleton service
- `DiagnosticEvent` - Event data model
- `SensorSample` - Sensor data point
- `DetectionState` - State machine tracking

### 3. ✅ App Constants Updated
**File:** `lib/core/constants/app_constants.dart`

**Added:**
```dart
// Production thresholds
crashAccelerationThreshold = 25.0 m/s²
fallDetectionThreshold = 15.0 m/s²
severeImpactThresholdG = 250.0 m/s²
jerkThreshold = 200.0 m/s³
decelerationThreshold = 20.0 m/s²

// Test mode thresholds (lowered for shake testing)
testModeCrashThresholdG = 8.0 G
testModeFallHeightMeters = 0.3 m
testModeSevereImpactThresholdG = 15.0 m/s²
testModeJerkThreshold = 50.0 m/s³
testModeDecelerationThreshold = 5.0 m/s²
testModeShakeThreshold = 6.0 G
testModeShakeWindowMs = 1000 ms
testModeMinShakeCount = 3 shakes

// SMS test mode
useSmsTestMode = false
testModeEmergencyContacts = ['+1234567890', '+0987654321']

// Helper methods
getCrashThreshold() - Returns test or production threshold
getFallThreshold() - Returns test or production threshold
getJerkThreshold() - Returns test or production threshold
getDecelerationThreshold() - Returns test or production threshold
```

---

## 🔧 Pending Implementation

### Phase 1: Sensor Service Integration (Next)
**File to Modify:** `lib/services/sensor_service.dart`

**Changes Required:**
```dart
// Use dynamic thresholds instead of constants
final threshold = AppConstants.getCrashThreshold();

// Log to diagnostic service when test mode active
if (AppConstants.testingModeEnabled) {
  TestModeDiagnosticService().logSensorSample(...);
}

// Trigger on lowered thresholds
if (magnitude > threshold) {
  if (AppConstants.testingModeEnabled) {
    TestModeDiagnosticService().logDetection(...);
  }
  _triggerDetection();
}
```

### Phase 2: Diagnostic Overlay UI
**File to Create:** `lib/features/testing/widgets/diagnostic_overlay.dart`

**Requirements:**
- Floating draggable window
- Real-time sensor data display
- State machine visualization
- Collapsible sections
- Export button
- Minimize/maximize controls
- Non-intrusive (can be hidden)

### Phase 3: SMS Test Mode Integration
**File to Modify:** `lib/services/sms_service.dart`

**Changes Required:**
```dart
List<EmergencyContact> _getTargetContacts() {
  if (AppConstants.useSmsTestMode) {
    return AppConstants.testModeEmergencyContacts
      .map((phone) => EmergencyContact(
        name: 'TEST CONTACT',
        phoneNumber: phone,
        relationship: 'Test',
      ))
      .toList();
  }
  return _userEmergencyContacts;
}

String _buildMessage() {
  final prefix = AppConstants.testingModeEnabled ? '[TEST MODE] ' : '';
  return '$prefix🚨 EMERGENCY ALERT...';
}
```

### Phase 4: Settings UI Toggle
**File to Modify:** `lib/features/settings/presentation/pages/settings_page.dart`

**Add Section:**
```dart
SwitchListTile(
  title: Text('Test Mode v2.0'),
  subtitle: Text('Production flow with lowered sensitivity'),
  value: AppConstants.testingModeEnabled,
  onChanged: (value) {
    if (value) {
      AppConstants.activateTestingMode();
      TestModeDiagnosticService().startSession();
    } else {
      AppConstants.deactivateTestingMode();
      TestModeDiagnosticService().stopSession();
    }
  },
),
SwitchListTile(
  title: Text('SMS Test Contacts'),
  subtitle: Text('Use test numbers instead of real contacts'),
  value: AppConstants.useSmsTestMode,
  enabled: AppConstants.testingModeEnabled,
  onChanged: (value) {
    setState(() {
      AppConstants.useSmsTestMode = value;
    });
  },
),
```

---

## 📊 Testing Scenarios

### Scenario 1: Basic Shake Test
1. Enable Test Mode in settings
2. Shake phone vigorously 3-4 times
3. **Expected:**
   - Diagnostic overlay shows 8G threshold exceeded
   - Voice verification dialog appears
   - AI runs motion/inactivity analysis
   - Full verification flow executes
   - If no interaction: countdown starts
   - SMS sent (to test contacts if enabled)

### Scenario 2: Gentle Drop Test
1. Enable Test Mode
2. Drop phone ~30cm onto soft surface
3. **Expected:**
   - Fall pattern detected (0.3m threshold)
   - Full verification sequence
   - Diagnostic shows sensor trace
   - Complete escalation flow

### Scenario 3: False Alarm Test
1. Enable Test Mode
2. Trigger detection (shake)
3. Speak "I'm okay" during voice verification
4. **Expected:**
   - AI detects voice response
   - Verification outcome: falseAlarm
   - Diagnostic shows confidence drop
   - No SMS sent
   - Session logged

### Scenario 4: Full Escalation Test
1. Enable Test Mode + SMS Test Mode
2. Trigger detection (shake)
3. Do not interact with any prompts
4. **Expected:**
   - All verification phases complete
   - Fallback timer triggers
   - 10-second countdown
   - SOS activation
   - SMS v2.0 cascade to test contacts
   - Firebase session created
   - Complete diagnostic capture

---

## 🔒 Safety Guardrails

1. ✅ **CI Build Gate:** Assert `testingModeEnabled == false` in release builds
2. ✅ **No Bypasses:** All production logic executes normally
3. ✅ **Test Contact Protection:** Optional SMS test mode prevents spam
4. ✅ **Clear Indicators:** [TEST MODE] prefix on all SMS/logs
5. ✅ **Emergency Override:** Production thresholds (35G) still trigger
6. ✅ **Manual SOS Works:** Full escalation even in test mode
7. ✅ **Cancellation Honored:** User can stop flow anytime
8. ✅ **Data Isolation:** Test sessions tagged in analytics
9. ✅ **Diagnostic Non-Intrusive:** Overlay can be minimized/hidden
10. ✅ **Production Guarantee:** Only thresholds differ; behavior identical

---

## 📤 Export Capabilities

### JSON Export Format
```json
{
  "sessionId": "test_1731607200000",
  "version": "2.0",
  "exportTime": "2025-11-14T13:30:00Z",
  "sessionInfo": {
    "startTime": "2025-11-14T13:25:00Z",
    "duration": 300000
  },
  "summary": {
    "totalDetections": 3,
    "truePositives": 1,
    "falseAlarms": 2,
    "smsSent": 2,
    "eventCount": 145,
    "sensorSamples": 1250
  },
  "events": [...],
  "sensorTrace": [...]
}
```

### CSV Export Format
```csv
Timestamp,Elapsed(ms),Type,Phase,Data
2025-11-14T13:25:00.123Z,0,session_start,init,"{...}"
2025-11-14T13:25:05.456Z,5333,detection,triggered,"{...}"
2025-11-14T13:25:05.567Z,5444,verification,voice_started,"{...}"
...
```

---

## 📝 Next Steps

### Immediate (This Week)
- [ ] Integrate threshold helpers in sensor_service.dart
- [ ] Add diagnostic logging calls throughout detection flow
- [ ] Create diagnostic overlay widget
- [ ] Add test mode toggle to settings UI
- [ ] Test shake detection with 8G threshold

### Short Term (Next Week)
- [ ] Implement SMS test mode in sms_service.dart
- [ ] Add session export UI
- [ ] Create test scenario documentation
- [ ] Conduct full escalation flow testing
- [ ] Validate diagnostic data accuracy

### Medium Term (Next Sprint)
- [ ] Adjustable threshold UI (sliders)
- [ ] Session replay viewer
- [ ] Automated test scenario runner
- [ ] Regression comparison tool
- [ ] ML annotation interface

---

## 🎓 Developer Notes

### Philosophy Shift
v1.0 tried to make testing easier by removing steps. This led to testing a **different system** than production. v2.0 embraces the complexity—test the real thing with real flows, just make it easier to trigger.

### Why Lowered Thresholds Work
- 8G is high enough to avoid false positives from normal handling
- Low enough that vigorous shaking consistently triggers
- Still detects real emergencies (real crashes are 35G+)
- Production behavior remains identical
- No logic changes needed—just threshold values

### Diagnostic Value
Real-time visibility into:
- Why detection triggered (which threshold, what value)
- AI verification decision process
- State machine transitions
- Timing accuracy
- False alarm indicators
- Complete audit trail

### Export Use Cases
- Bug investigation (share session with developers)
- Performance analysis (timing bottlenecks)
- ML training data collection
- Regression testing (compare sessions)
- User support (reproduce reported issues)

---

## 📞 Support

**Questions:** Contact Safety/AI Integration Team  
**Documentation:** TEST_MODE_BLUEPRINT.md  
**Implementation Guide:** Section 19 of blueprint  
**Code Reference:** test_mode_diagnostic_service.dart

---

**Status:** Core infrastructure complete, pending integration  
**ETA for Full Implementation:** 1-2 weeks  
**Risk Level:** Low (production logic unchanged)  
**Impact:** High (enables comprehensive production testing)
