# Real-World Behavior Analysis & Issue Investigation

**Date**: October 26, 2025  
**Scope**: Investigation of app behavior during real-world testing (driving, movement, stationary)

## 🔍 Issues Reported

1. ✅ **FIXED: Mock data appearing in SAR dashboard** - November 1, 2025
2. **SOS status indicators behaving incorrectly**
3. **False crash detection while sitting on bench (not driving)**

---

## 📊 Diagnostic Findings

### 1. Mock SAR Teams Generation

**Location**: `lib/services/sar_service.dart` lines 71-72, 934-991

**Issue**: The app automatically initializes 5 mock SAR teams on startup:
- Ground Team Alpha
- Medical Response Unit  
- Air Rescue Helicopter
- K9 Search Unit
- Water Rescue Team

**Code**:
```dart
// Initialize mock SAR teams (in production, this would come from a server)
_initializeMockSARTeams();
```

**Impact**: These appear in the SAR dashboard even when there are no real SAR teams connected.

**Root Cause**: Development/demo code still active in production build.

---

### 2. Crash Detection Sensitivity Issues

**Location**: `lib/services/sensor_service.dart` lines 69-72

**Current Thresholds**:
```dart
double _crashThreshold = 180.0; // m/s² - 60+ km/h crashes only
double _fallThreshold = 100.0;  // m/s² - >1 meter falls only
final double _severeImpactThreshold = 250.0; // m/s² - 80+ km/h
final double _phoneDropThreshold = 100.0; // m/s² - Filter normal phone handling
```

**Problem Analysis**:
The crash threshold is correctly set at 180 m/s² (which corresponds to 60+ km/h impacts), BUT there are several potential false-positive triggers:

#### A. Sensor Calibration Issues
**Lines 42-43**:
```dart
bool _crashDetectionEnabled = true; // ENABLED: Real phone testing
bool _fallDetectionEnabled = true; // ENABLED: Real phone testing
```

- Crash/fall detection is **always enabled**
- Runs even when user is stationary (sitting on bench)
- No context-aware disable mechanism

#### B. Calibration System Behavior
**Lines 253-271 (calibration system)**:
The app has an **auto-calibration system** that learns phone-specific sensor characteristics:

```dart
// SENSOR CALIBRATION SYSTEM
// Problem: Phone sensors are too sensitive - detect every tiny vibration
// Solution: Start with default real-world patterns, then learn user's specific patterns
```

**Issues Found**:
1. **Auto-calibration may be incorrectly adjusting thresholds downward**
   - Lines 783-800: Learning system can adjust thresholds
   - If phone is dropped/bumped during calibration, it may learn wrong baseline
   
2. **Calibration runs on first launch** (line 651)
   - If user sits down abruptly during first launch, system may calibrate incorrectly
   
3. **Device-specific profiles might be misapplied** (lines 188-213)
   - Samsung profile applies 0.95 scaling + 1.2 noise factor
   - Could cause false positives if wrong profile loaded

#### C. Sustained Pattern Detection
**Lines 1201-1235**: Requires sustained high-impact pattern BUT:

```dart
if (!_hasSustainedHighImpactPattern()) {
  return; // Not a sustained crash-level impact - ignoring
}
```

**Potential Issue**: The sustained pattern check may not be strict enough:
- Buffer size is only 50 readings (line 102)
- At 10Hz sampling = 5 seconds of data
- A hard sit-down on bench could create brief high-acceleration spike

---

### 3. Low Power Mode False Positives

**Lines 859-982**: Smart battery optimization

**Problem**: In low power mode, the app:
1. Processes **every Nth reading** (line 968)
2. Still checks for **significant motion** (line 1013)
3. May misinterpret sitting down as "significant motion"

**Code showing issue**:
```dart
// ✅ ALWAYS process if in significant motion (vehicle movement)
if (_isInSignificantMotion()) {
  return true;
}
```

**Line 1020-1030**: Significant motion detection is overly sensitive:
```dart
bool _isInSignificantMotion() {
  // Significant motion if:
  // - Multiple consecutive readings > 12.0 m/s²
  // - Or recent motion detected within last 10 seconds
  if (_significantMotionCount >= 3) return true;
```

**Issue**: Sitting down on bench can easily generate 3+ readings above 12 m/s², triggering crash detection.

---

### 4. Cross-Emulator Alert System

**Lines 74-77**: Timer that runs every 5 minutes:
```dart
_crossEmulatorCheckTimer = Timer.periodic(
  const Duration(minutes: 5),
  (_) => checkForCrossEmulatorAlerts(),
);
```

**Purpose**: Check for SOS alerts from other instances (for testing)

**Concern**: This might be reading stale test data from SharedPreferences

---

### 5. Mock User Profile Data

**Location**: `lib/services/sos_ping_service.dart` line 1645

```dart
// For now, return a mock user profile
```

**Impact**: User data shown in SAR dashboard may include mock/placeholder values

---

## 🎯 Recommended Fixes

### Priority 1: Disable Mock SAR Teams in Production ✅ FIXED - November 1, 2025

**File**: `lib/services/sar_service.dart`

**Issue**: Mock SAR teams were appearing in production builds

**Fixes Applied**:

1. **Mock SAR Teams** (Lines 102-109):
```dart
// FIXED: Only load mock teams in debug mode
if (kDebugMode) {
  _initializeMockSARTeams();
  debugPrint('SARService: Mock SAR teams loaded (DEBUG MODE ONLY)');
} else {
  debugPrint('SARService: Production mode - SAR teams from Firestore');
}
```

2. **Cross-Emulator Timer** (Lines 111-120):
```dart
// FIXED: Only run cross-emulator checks in debug mode
if (kDebugMode) {
  _crossEmulatorCheckTimer = Timer.periodic(
    const Duration(minutes: 5),
    (_) => checkForCrossEmulatorAlerts(),
  );
  debugPrint('SARService: Cross-emulator alert timer started (DEBUG MODE ONLY)');
} else {
  debugPrint('SARService: Production mode - alerts from Firebase only');
}
```

3. **Mock User Profiles** (File: `lib/services/sos_ping_service.dart`, Lines 1668-1693):
```dart
// FIXED: Use real UserProfileService, only fallback to mock in debug mode
Future<dynamic> _getUserProfile() async {
  try {
    final userProfile = _userProfileService.currentProfile;
    
    if (userProfile != null) {
      return {
        'id': userProfile.id,
        'name': userProfile.name,
        'phone': userProfile.phoneNumber,
      };
    }
    
    // Only use fallback in debug mode
    if (kDebugMode) {
      debugPrint('SOSPingService: No user profile found, using debug fallback');
      return {/* mock data */};
    }
    
    // In production, return null if no profile exists
    return null;
  } catch (e) {
    return null;
  }
}
```

**Result**: 
- ✅ Mock SAR teams only appear in debug builds
- ✅ Cross-emulator alerts only run during development
- ✅ User profiles use real data from UserProfileService
- ✅ No fake notifications in production
- ✅ Clean production builds with Firebase-only data

**Additional Services Fixed**:

4. **Chat Service** (File: `lib/services/chat_service.dart`, Lines 415-422):
```dart
// FIXED: Only simulate incoming messages in debug mode
if (kDebugMode) {
  _simulateIncomingMessages();
  debugPrint('ChatService: Message simulation enabled (DEBUG MODE ONLY)');
}
```

5. **Rescue Response Service** (File: `lib/services/rescue_response_service.dart`, Lines 203-208):
```dart
// FIXED: Only simulate status updates in debug mode
if (kDebugMode) {
  _simulateResponseUpdates(session.id, response);
  debugPrint('RescueResponseService: Status simulation enabled (DEBUG MODE ONLY)');
}
```

6. **Hazard Alert Service** (File: `lib/services/hazard_alert_service.dart`, Lines 60-64):
```dart
// FIXED: Only generate mock alerts in debug mode
if (kDebugMode) {
  await _generateMockAlerts();
  debugPrint('HazardAlertService: Mock alerts generated (DEBUG MODE ONLY)');
}
```

**Complete Mock Data Sources Eliminated in Production**:
1. ✅ Mock SAR teams (5 fake teams)
2. ✅ Mock user profiles (fake user data)
3. ✅ Cross-emulator alerts (test notifications)
4. ✅ Simulated chat messages (every 3 minutes)
5. ✅ Simulated rescue response updates (fake status changes)
6. ✅ Mock hazard alerts (fake weather/emergency broadcasts)

**Production Behavior**:
- All data comes from Firebase/Firestore
- No automatic test notifications
- No simulated messages or updates
- Clean, real-world data only

---

### Priority 2: Add Context-Aware Crash Detection ✅ FIXED

**File**: `lib/services/sensor_service.dart`

Add state management to disable crash detection when user is clearly stationary:

```dart
// Add new fields:
bool _isUserLikelyStationary = false;
int _stationaryReadingsCount = 0;
static const int _stationaryReadingsRequired = 300; // 5 minutes at 1Hz
```

**✅ IMPLEMENTED** - Stationary detection now pauses crash detection after 5 minutes of stable readings.

---

### Priority 2.5: Fix SOS Status Indicator Auto-Update ✅ FIXED

**File**: `lib/features/sos/presentation/pages/sos_page.dart`

**Issue**: Firebase listener was calling `setState()` on EVERY snapshot, even when nothing changed, causing the status indicator to flicker and appear to "auto-update" constantly.

**Root Cause**: Lines 415-420 always triggered UI rebuild:
```dart
// OLD CODE - ALWAYS rebuilds UI
setState(() {
  _currentSession = updatedSession;
});
```

**Fix Applied**: Only call setState when data actually changes:
```dart
// Calculate what actually changed BEFORE updating
final statusChanged = oldRawStatus != updatedStatus;
final metadataChanged = oldResponderId != updatedMetadata['responderId'] ||
                        oldResponderName != updatedMetadata['responderName'];
final responsesChanged = updatedRescueResponses.length != oldResponsesLength ||
                         (updatedRescueResponses.isNotEmpty && 
                          oldLastResponseStatus != null &&
                          updatedRescueResponses.last.status != oldLastResponseStatus);

// CRITICAL FIX: Only call setState if something actually changed
final hasActualChanges = statusChanged || metadataChanged || responsesChanged;

if (hasActualChanges) {
  setState(() {
    _currentSession = updatedSession;
  });
  debugPrint('✅ Session Updated (changes detected):');
} else {
  // Update internal state without triggering rebuild
  _currentSession = updatedSession;
  debugPrint('🔄 Session synced (no UI changes needed)');
}
```

**Result**: 
- Status indicator only updates when SAR dashboard actually changes status
- No more flickering or "auto-updating" behavior
- Significant performance improvement (fewer UI rebuilds)
- Firebase listener still maintains real-time sync

---

### Priority 2.6: Fix Resolved Page Not Receiving Resolved Cases ✅ FIXED

**File**: `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`

**Issue 1**: Inconsistent status value format when marking SOS as "in progress". The dashboard was writing `'inProgress'` (camelCase) instead of `'in_progress'` (snake_case).

**Issue 2**: Null safety error when displaying resolved SOS sessions with missing priority field.

**Root Causes**:
- **Lines 2207, 2090**: Used `'inProgress'` ❌ (should be `'in_progress'`)
- **Line 1005**: `final priority = data['priority'];` ❌ (can be null, causes type error)
- **Repository mapping** (sos_repository.dart line 210): Expects `'in_progress'` ✅

This mismatch meant:
1. When SAR marked session as "In Progress", it wrote camelCase `'inProgress'`
2. Later when marking as "Resolved", the status chain was broken
3. Filtering logic in resolved tab (line 928) correctly looked for `'resolved'` status
4. But corrupted status history caused sessions to not display properly
5. When displaying resolved sessions, null priority values caused: `type 'Null' is not a subtype of type 'String'`

**Fixes Applied**: 

1. Changed all status updates to use snake_case format:
```dart
// OLD CODE - Lines 2207, 2090
'status': 'inProgress',  // ❌ Wrong format

// NEW CODE - Consistent snake_case
'status': 'in_progress',  // ✅ Matches repository mapping
```

2. Added null safety for priority field:
```dart
// OLD CODE - Line 1005
final priority = data['priority'];  // ❌ Can be null

// NEW CODE - Safe with default
final priority = (data['priority'] ?? 'medium').toString();  // ✅ Never null
```

**Additional Verifications**:
- ✅ Line 681: `(data['priority'] ?? 'medium').toString()` (active SOS tab)
- ✅ Line 1005: `(data['priority'] ?? 'medium').toString()` (resolved SOS tab)
- ✅ Line 2393: `'acknowledged'` (correct)
- ✅ Line 2421: `'en_route'` (correct)
- ✅ Line 2435: `'on_scene'` (correct)
- ✅ Line 2443: `'resolved'` (correct)
- ✅ Line 2737: `'assigned'` (correct)

**Result**: 
- All status updates now use consistent snake_case format
- Resolved tab filtering works correctly
- Status history chain maintained properly
- Sessions transition smoothly from active → in_progress → resolved
- No more null type errors when displaying resolved sessions

---

### Priority 3: Fix Calibration System

**File**: `lib/services/sensor_service.dart` line 651+

Add safeguards to prevent bad calibration:

```dart
bool _shouldRunCalibration() {
  // Run on first launch (never calibrated)
  if (!_isCalibrated) {
    debugPrint('SensorService: First launch - calibration needed');
    
    // NEW: Only calibrate if phone appears stable
    if (_isPhoneCurrentlyStable()) {
      return true;
    } else {
      debugPrint('SensorService: Phone not stable - delaying calibration');
      return false;
    }
  }
  
  // ... rest of existing code
}

// Add stability check:
bool _isPhoneCurrentlyStable() {
  // Check last 10 readings for stability
  if (_accelerometerBuffer.length < 10) return false;
  
  final recentReadings = _accelerometerBuffer.sublist(
    _accelerometerBuffer.length - 10
  );
  
  final avgMagnitude = recentReadings
      .map((r) => r.magnitude)
      .reduce((a, b) => a + b) / recentReadings.length;
  
  // Phone is stable if magnitude is close to gravity (9.8 m/s²)
  // Allow ±2 m/s² tolerance
  return (avgMagnitude - 9.8).abs() < 2.0;
}
```

---

### Priority 4: Stricter Sustained Pattern Detection

**File**: `lib/services/sensor_service.dart`

Make sustained pattern check more strict:

```dart
bool _hasSustainedHighImpactPattern() {
  if (_accelerometerBuffer.length < 10) {
    return false; // Need at least 10 readings (1 second at 10Hz)
  }

  // Get most recent readings
  final recentReadings = _accelerometerBuffer.sublist(
    max(0, _accelerometerBuffer.length - 30) // Last 3 seconds
  );

  // Count readings above crash threshold
  final highImpactCount = recentReadings
      .where((r) => r.magnitude > _crashThreshold)
      .length;

  // STRICTER: Require 80% of readings above threshold
  // OLD: 50% (too lenient)
  final sustainedRatio = highImpactCount / recentReadings.length;
  final isS sustained = sustainedRatio >= 0.80; // NEW: 80% threshold
  
  if (!isSustained && highImpactCount > 0) {
    debugPrint('SensorService: Brief spike detected ($highImpactCount/${recentReadings.length} readings) - NOT sustained, ignoring');
  }

  return isSustained;
}
```

---

### Priority 5: Add User Settings Toggle

**File**: `lib/features/settings/presentation/pages/safety_settings_page.dart` (create if needed)

Add user control:

```dart
// Allow users to disable crash detection when not driving
SwitchListTile(
  title: const Text('Auto Crash Detection'),
  subtitle: const Text('Detect car crashes automatically (disable when not driving)'),
  value: _crashDetectionEnabled,
  onChanged: (value) {
    setState(() => _crashDetectionEnabled = value);
    SensorService().setCrashDetectionEnabled(value);
  },
)
```

---

## 🧪 Testing Recommendations

### Test Case 1: Sitting Down on Bench
1. Open app and sit on bench
2. Wait 10 minutes with phone in pocket/hand
3. **Expected**: No crash alerts
4. **Check logs** for "Crash detection skipped - user stationary"

### Test Case 2: Normal Driving
1. Drive on smooth road at 60 km/h
2. Go over speed bump
3. **Expected**: No crash alert (brief spike, motion continues)
4. **Check logs** for "Motion resumed (driving continues)"

### Test Case 3: Real Crash Simulation
1. Place phone in car
2. Simulate hard braking (0 to 60 km/h stop)
3. **Expected**: Crash detection after 3-second verification
4. **Check logs** for "Crash verification complete - Vehicle stopped"

### Test Case 4: SAR Dashboard
1. Open SAR dashboard
2. **Expected**: NO mock SAR teams visible (unless debug mode)
3. **Check**: Only real Firestore data shown

---

## 📝 Log Analysis Commands

To analyze phone logs, run:

```powershell
# Get crash detection logs
flutter logs | Select-String "SensorService.*crash"

# Get calibration status
flutter logs | Select-String "calibration"

# Get mock data references
flutter logs | Select-String "mock|Mock|MOCK"

# Get SAR dashboard data
flutter logs | Select-String "SARService"
```

---

## 🔧 Immediate Action Items

1. **Disable mock SAR teams** → Apply Priority 1 fix
2. **Add stationary detection** → Apply Priority 2 fix  
3. **Test calibration** → Check if phone was calibrated during movement
4. **Enable debug logs** → Add more detailed logging to crash detection
5. **User feedback** → Add UI indicator showing crash detection state

---

## 📊 Metrics to Monitor

After applying fixes, track:

1. **False Positive Rate**: Crash alerts when not driving
2. **True Positive Rate**: Crash alerts during actual impacts
3. **Calibration Quality**: How often calibration succeeds vs fails
4. **Battery Impact**: CPU/battery usage from sensor monitoring
5. **User Feedback**: Manual enable/disable usage patterns

---

## 🎓 Learning Points

### Why False Positives Occur:

1. **Phone sensors are VERY sensitive** - designed for gaming/AR, not crash detection
2. **Sitting down generates 15-40 m/s² easily** - enough to trigger some checks
3. **Brief spikes can exceed 180 m/s²** - without sustained pattern
4. **Calibration is critical** - wrong baseline = wrong thresholds
5. **Context matters** - stationary vs driving makes huge difference

### Best Practices Applied:

✅ Physics-based thresholds (180 m/s² = 60 km/h)  
✅ Sustained pattern detection (not just single spike)  
✅ Motion resume detection (car keeps moving = false alarm)  
✅ Calibration system (adapts to phone-specific sensors)  
❌ **MISSING**: Stationary state detection  
❌ **MISSING**: User control toggle  
❌ **MISSING**: Production flag for mock data  

---

## 📌 Conclusion

The app has **excellent crash detection architecture** with physics-based thresholds and multi-layer verification, BUT suffers from:

1. **Mock data pollution** (easy fix - add debug flag)
2. **Lack of context awareness** (needs stationary detection)
3. **Overly sensitive "significant motion" detector** (12 m/s² too low)
4. **No user control** (should allow manual disable)

**Recommendation**: Apply Priority 1-3 fixes immediately, then test in real-world scenarios before deploying.
