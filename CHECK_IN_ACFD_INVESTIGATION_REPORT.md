# Check-In Ping & ACFD Investigation Report

**Date**: November 30, 2025  
**Issue**: ACFD (Automatic Crash/Fall Detection) not working properly after check-in ping implementation

---

## 🔍 Executive Summary

After investigating the check-in ping features and ACFD functionality, I've identified **NO DIRECT CONFLICTS** between the two systems. However, there are **architectural concerns** and **potential resource contention** issues that could explain why ACFD appears to be malfunctioning.

---

## 📋 Systems Analyzed

### 1. Check-In Ping System
**Files**:
- `lib/services/check_in_service.dart` - Core check-in request/response logic
- `lib/models/check_in_request.dart` - Data models
- `lib/features/check_in/check_in_request_dialog.dart` - UI component
- `lib/main.dart` (_CheckInListener) - Global listener for incoming requests

**Functionality**:
- Family members can request location check-ins
- Target user receives notification and can approve/deny
- Guardian auto-approval bypass for designated guardians
- Daily rate limiting (max 5 requests/day by default)
- Auto-expiration after timeout

**Resource Usage**:
- Firebase Firestore listeners (one per user)
- Geolocator for location capture
- No sensor subscriptions
- No direct interference with ACFD

---

### 2. ACFD (Automatic Crash/Fall Detection) System
**Files**:
- `lib/services/sensor_service.dart` - Main sensor monitoring (3,375 lines!)
- `lib/services/emergency_detection_service.dart` - Emergency detection coordinator
- `lib/services/ai_verification_service.dart` - AI verification layer
- `lib/services/app_service_manager.dart` - Service lifecycle management

**Functionality**:
- Continuous accelerometer/gyroscope monitoring
- Physics-based crash detection (180+ m/s² threshold)
- Physics-based fall detection (150+ m/s² threshold)
- AI verification to prevent false positives
- Low-power and active monitoring modes

**Critical Dependencies**:
- `sensors_plus` package (accelerometer/gyroscope streams)
- `geolocator` for location context
- AI verification service for validation
- Battery monitoring for adaptive sampling

---

## ⚠️ Issues Identified

### Issue #1: Sensor Service NOT Auto-Starting

**Problem**: SensorService monitoring is **DISABLED BY DEFAULT** at app startup

**Evidence**:
```dart
// lib/services/app_service_manager.dart:297
// await _sensorService.startMonitoring(); // ❌ COMMENTED OUT!
```

**Impact**: ACFD will not work unless manually started or triggered by SOS activation

**Root Cause**: Performance optimization - sensors commented out to reduce CPU load when not in SOS mode

**Fix Required**: Uncomment sensor monitoring with proper conditional logic based on subscription tier

---

### Issue #2: Multiple Sensor Service Duplicates

**Problem**: Multiple services subscribing to the same sensor streams

**Duplicates Found**:
1. `sensor_service.dart` - Primary service (3,375 lines)
2. `emergency_detection_service.dart` - Duplicate ACFD logic
3. `ai_emergency_verification_service.dart` - Another sensor subscription
4. `chatgpt_ai_verification_service.dart` - Yet another subscription
5. `enhanced_emergency_detection_service.dart` - Another duplicate
6. `redping_ai_service.dart` - Another accelerometer subscription

**Evidence**:
```dart
// All these services have their own subscriptions:
StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
```

**Impact**:
- Resource waste (multiple streams for same data)
- Potential race conditions
- Conflicting detection logic
- Battery drain
- Harder to debug which service is actually working

**Recommendation**: Consolidate to a **single** sensor monitoring service

---

### Issue #3: Subscription Gate on ACFD

**Problem**: ACFD is gated behind Essential+ subscription tier

**Code**:
```dart
// lib/services/emergency_detection_service.dart:65
if (!_featureAccessService.hasFeatureAccess('acfd')) {
  debugPrint('⚠️ ACFD not available - Free tier (manual SOS only)');
  return; // EXITS WITHOUT STARTING
}
```

**Impact**: If user doesn't have Essential+ or above, ACFD will never start

**Question**: Are you testing with a Free tier account? Check subscription status!

---

### Issue #4: Check-In Location Requests Competing

**Problem**: Check-in service uses Geolocator, same as ACFD

**Code**:
```dart
// lib/main.dart:479
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
```

**Impact**: When check-in request arrives, it may:
- Delay location updates for ACFD
- Compete for location permission
- Interfere with location-based crash detection

**Severity**: Low - unlikely to break ACFD entirely, but could cause delays

---

### Issue #5: Find My Gadgets Location Tracking

**Problem**: Find My Gadgets also uses location services

**Code**:
```dart
// lib/features/gadgets/presentation/pages/find_my_gadget_page.dart
_locationSubscription = Geolocator.getPositionStream(...).listen(...)
```

**Impact**: Another consumer of location services competing with ACFD

---

## 🔧 Root Cause Analysis

### Why ACFD is Not Working

**Most Likely Causes (in order of probability)**:

1. **Sensor monitoring not started** (90% confidence)
   - Commented out in app_service_manager.dart line 297
   - Only starts in background services (lines 669)
   - May not be initializing at all

2. **Subscription tier blocking** (80% confidence)
   - User may be on Free tier
   - ACFD requires Essential+ or above
   - Check user's subscription status

3. **Service duplication confusion** (60% confidence)
   - Multiple services competing
   - Unclear which service is "active"
   - May be monitoring wrong service

4. **Resource contention** (30% confidence)
   - Check-in + gadgets + ACFD all using location
   - Could cause delays but shouldn't break it entirely

---

## 🚑 Immediate Fixes Required

### Fix #1: Re-enable Sensor Monitoring
**File**: `lib/services/app_service_manager.dart`

**Current (line 297)**:
```dart
// await _sensorService.startMonitoring(); // ❌ DISABLED
```

**Fix**:
```dart
// Start sensor monitoring based on subscription tier
if (_featureAccessService.hasFeatureAccess('acfd')) {
  await _sensorService.startMonitoring(
    locationService: _locationService,
    notificationService: _notificationService,
    lowPowerMode: true,
  );
  debugPrint('✅ ACFD enabled - monitoring started');
} else {
  debugPrint('⚠️ ACFD disabled - Free tier (upgrade to Essential+ for auto-detection)');
}
```

---

### Fix #2: Verify Subscription Status
**Check**: What tier is the test user on?

**Query**:
```dart
final hasACFD = _featureAccessService.hasFeatureAccess('acfd');
debugPrint('ACFD Access: $hasACFD');
```

**Expected**: `true` for Essential+, Pro, Ultra, Family tiers

---

### Fix #3: Consolidate Sensor Services
**Problem**: 6 different services all monitoring sensors

**Recommendation**:
1. Keep `sensor_service.dart` as the **single source of truth**
2. Remove sensor subscriptions from:
   - `emergency_detection_service.dart`
   - `ai_emergency_verification_service.dart`
   - `chatgpt_ai_verification_service.dart`
   - `enhanced_emergency_detection_service.dart`
   - `redping_ai_service.dart`
3. Use event bus or callbacks to distribute sensor data

---

### Fix #4: Add Diagnostic Logging
**Add to** `lib/services/sensor_service.dart`:

```dart
void printDiagnostics() {
  debugPrint('=== SENSOR SERVICE DIAGNOSTICS ===');
  debugPrint('Monitoring: $_isMonitoring');
  debugPrint('Crash Detection: $_crashDetectionEnabled');
  debugPrint('Fall Detection: $_fallDetectionEnabled');
  debugPrint('Crash Threshold: $_crashThreshold m/s²');
  debugPrint('Fall Threshold: $_fallThreshold m/s²');
  debugPrint('Low Power Mode: $_isLowPowerMode');
  debugPrint('AI Verification: ${_aiVerificationService != null}');
  debugPrint('Last Crash: $_lastCrashDetection');
  debugPrint('Last Fall: $_lastFallDetection');
  debugPrint('================================');
}
```

---

## 📊 Check-In vs ACFD Comparison

| Feature | Check-In Ping | ACFD |
|---------|---------------|------|
| **Uses Sensors** | ❌ No | ✅ Yes (accelerometer/gyro) |
| **Uses Location** | ✅ Yes (on-demand) | ✅ Yes (continuous) |
| **Firebase Listeners** | ✅ Yes (check_in_requests) | ❌ No |
| **Battery Impact** | Low (intermittent) | Medium (continuous) |
| **Resource Conflict** | Minimal | **Possible** (location contention) |
| **Auto-Start** | ✅ Yes (main.dart) | ❌ **NO** (commented out!) |

---

## 🎯 Recommendations

### Priority 1 (Critical) - Restore ACFD
1. Uncomment sensor monitoring in `app_service_manager.dart`
2. Add subscription tier check
3. Verify user has Essential+ or above
4. Add diagnostic logging

### Priority 2 (High) - Code Cleanup
1. Remove duplicate sensor services
2. Consolidate to single sensor monitoring service
3. Document which service is "the one"
4. Remove unused/deprecated services

### Priority 3 (Medium) - Location Management
1. Implement location request queue
2. Prioritize ACFD location updates
3. Throttle check-in location requests
4. Add location service usage monitoring

### Priority 4 (Low) - Architecture Review
1. Consider event-driven architecture for sensor data
2. Implement proper service lifecycle management
3. Add service health monitoring
4. Create service dependency graph

---

## 🧪 Testing Protocol

### Step 1: Verify Sensor Service Status
```dart
// Add to debug screen
final sensorService = AppServiceManager().sensorService;
print('Is Monitoring: ${sensorService.isMonitoring}');
print('Crash Enabled: ${sensorService.crashDetectionEnabled}');
print('Fall Enabled: ${sensorService.fallDetectionEnabled}');
```

### Step 2: Check Subscription Tier
```dart
final featureAccess = FeatureAccessService.instance;
print('Has ACFD: ${featureAccess.hasFeatureAccess('acfd')}');
print('Current Tier: ${featureAccess.currentTier}');
```

### Step 3: Manual Start Test
```dart
await AppServiceManager().sensorService.startMonitoring(
  locationService: AppServiceManager().locationService,
  notificationService: AppServiceManager().notificationService,
  lowPowerMode: false,
);
```

### Step 4: Trigger Test Event
```dart
// Use test mode to trigger with lower thresholds
AppConstants.testingModeEnabled = true;
// Shake phone vigorously
// Should trigger ACFD if working
```

---

## 📝 Conclusion

**The check-in ping feature is NOT directly breaking ACFD**. However, the **sensor monitoring service is not being started at app launch**, which is the primary reason ACFD isn't working.

**Action Items**:
1. ✅ Re-enable sensor monitoring (fix #1)
2. ✅ Verify subscription tier (fix #2)
3. ⏳ Clean up duplicate services (fix #3)
4. ⏳ Add diagnostics (fix #4)

**Impact Assessment**:
- **Check-In Ping**: Working correctly, no issues found
- **Find My Gadgets**: Minor location contention, acceptable
- **ACFD**: **BROKEN** - not starting due to commented code

---

## 🔗 Related Files

**Check-In System**:
- `lib/services/check_in_service.dart`
- `lib/models/check_in_request.dart`
- `lib/features/check_in/check_in_request_dialog.dart`
- `lib/main.dart` (_CheckInListener)
- `functions/src/checkInRequests.js` (backend)

**ACFD System**:
- `lib/services/sensor_service.dart` ⭐ PRIMARY
- `lib/services/emergency_detection_service.dart`
- `lib/services/app_service_manager.dart`
- `lib/services/ai_verification_service.dart`
- `docs/Auto_crash_fall_detection_logic_blueprint.md`

**Configuration**:
- `lib/core/constants/app_constants.dart`
- `lib/services/feature_access_service.dart`
- `PHASE_2_FEATURE_GATING_COMPLETE.md`

---

**Next Steps**: Apply Fix #1 immediately to restore ACFD functionality.
