# 🧪 Transportation Detection Testing & Verification Guide

## Overview
This guide provides step-by-step testing procedures to verify the sensor service correctly detects and responds to different transportation modes (car, airplane, boat) and movement patterns.

---

## 🎯 Pre-Test Setup

### Requirements:
- ✅ GPS enabled and accurate
- ✅ Location permission granted
- ✅ Sensor service initialized
- ✅ Debug logs enabled (check console output)
- ✅ Battery >50% for extended testing

### Enable Debug Logging:
```dart
// Ensure these debug prints are visible in your console
debugPrint('SensorService: ...');
debugPrint('✈️ SensorService: ...');
debugPrint('🚤 SensorService: ...');
```

---

## 🚗 Test 1: Normal Car Driving

### Objective: Verify sensors activate during driving and detect normal movement

### Steps:
1. Start app while stationary
2. **Expected**: "Sensors: OFF (waiting for movement)"
3. Start driving (>5 km/h)
4. **Expected**: "🚀 ACTIVATING sensor monitoring (movement detected)"
5. Drive normally for 10 minutes
6. **Expected**: Crash detection ENABLED (180 m/s² threshold)
7. Stop car and stay stationary for 5+ minutes
8. **Expected**: "😴 DEACTIVATING sensor monitoring (no movement for 5 min)"

### Success Criteria:
- ✅ Sensors activate when car moves
- ✅ Crash threshold = 180 m/s² (normal)
- ✅ Sensors hibernate after 5 min stationary
- ✅ No false crash alerts during normal driving

---

## ✈️ Test 2: Airplane Flight

### Objective: Verify airplane mode detection and crash suppression

### Test 2A: Takeoff Detection
**Steps:**
1. Board airplane (stationary at gate)
2. **Expected**: Sensors OFF or in low power
3. Airplane begins taxi and takeoff roll
4. **Expected**: Speed increases, altitude climbing
5. Watch for takeoff detection
6. **Expected Log**: 
   ```
   ✈️ SensorService: TAKEOFF detected - climb rate: XXX m/min, speed: XXX km/h
   ```

**Success Criteria:**
- ✅ Detects takeoff when climb rate >300 m/min + speed >200 km/h
- ✅ Sets `_isPotentialFlight = true`

### Test 2B: Cruising Altitude Confirmation
**Steps:**
1. Wait for airplane to reach cruising altitude (10,000+ feet / 3,000+ meters)
2. Monitor speed (should be >400 km/h)
3. **Expected Log**: 
   ```
   ✈️ SensorService: FLIGHT CONFIRMED - altitude: XXXXm, speed: XXX km/h
   ✈️ SensorService: AIRPLANE MODE ACTIVATED
     - Crash detection: DISABLED (turbulence filtering)
     - Fall detection: DISABLED (flight movement)
     - Sensor monitoring: LOW POWER (minimal battery)
   ```

**Success Criteria:**
- ✅ Confirms flight when altitude 3,000-13,000m + speed >400 km/h + stable
- ✅ `_isInAirplaneMode = true`
- ✅ Crash detection suppressed

### Test 2C: Turbulence Handling
**Steps:**
1. During flight, experience turbulence
2. Monitor sensor readings (may see high acceleration)
3. **Expected**: NO crash alert triggered
4. **Expected Log**: 
   ```
   SensorService: ✈️ Crash detection suppressed (airplane mode)
   ```

**Success Criteria:**
- ✅ No false crash alerts during turbulence
- ✅ Suppression active throughout flight

### Test 2D: Landing Detection
**Steps:**
1. Airplane begins descent
2. Monitor altitude dropping
3. **Expected**: When altitude <1,000m + descent rate >300 m/min
4. **Expected Log**: 
   ```
   ✈️ SensorService: LANDING detected - descent rate: XXX m/min
   ✈️ SensorService: AIRPLANE MODE DEACTIVATED
     - Crash detection: ENABLED
     - Fall detection: ENABLED
     - Sensor monitoring: NORMAL
   ```

**Success Criteria:**
- ✅ Detects landing when descending through 1,000m
- ✅ `_isInAirplaneMode = false`
- ✅ Crash detection restored to normal (180 m/s²)

---

## 🚤 Test 3: Boat/Marine Vessel

### Objective: Verify boat mode detection and wave motion filtering

### Test 3A: Boarding and Stationary
**Steps:**
1. Board boat while docked (stationary)
2. **Expected**: Sensors OFF or monitoring at low power
3. Altitude should be <100m (sea level)
4. Speed <5 km/h

**Success Criteria:**
- ✅ No boat mode activated while docked
- ✅ Low altitude detected

### Test 3B: Boat Departure and Wave Motion
**Steps:**
1. Boat departs and reaches cruising speed (10-50 km/h typical)
2. Boat experiences wave motion (rhythmic up/down)
3. Wait 3 minutes for pattern confirmation
4. **Expected Log**: 
   ```
   🚤 SensorService: BOAT pattern detected - variance: X.X m/s², speed: XX km/h
   🚤 SensorService: BOAT CONFIRMED - sustained wave motion detected
   🚤 SensorService: BOAT MODE ACTIVATED
     - Wave motion filtering: ENABLED
     - Crash threshold: INCREASED (ignore wave impacts)
     - Fall detection: ADJUSTED (water-specific)
   ```

**Success Criteria:**
- ✅ Detects boat when:
  - Altitude <100m (sea level)
  - Speed 5-100 km/h
  - Motion variance 2-15 m/s² (rhythmic waves)
  - Pattern sustained 3+ minutes
- ✅ `_isOnBoat = true`
- ✅ Crash threshold increased to 250 m/s²
- ✅ Fall threshold increased to 120 m/s²

### Test 3C: Wave Impact Filtering
**Steps:**
1. While boat mode active, experience wave impacts
2. Monitor sensor readings
3. Normal waves (variance 2-15 m/s²) should be filtered
4. **Expected**: NO crash alert for normal wave motion

**Success Criteria:**
- ✅ Wave impacts <250 m/s² ignored
- ✅ Rhythmic motion filtered correctly
- ✅ No false crash alerts

### Test 3D: Real Emergency Detection (Boat Collision)
**Steps:**
1. Simulate or test severe impact (>250 m/s²)
2. **Expected**: Crash alert SHOULD trigger
3. **Expected**: Higher threshold still provides safety

**Success Criteria:**
- ✅ Severe impacts (>250 m/s²) still detected
- ✅ Safety maintained despite threshold adjustment

### Test 3E: Docking/Exit Detection
**Steps:**
1. Boat slows down and approaches dock
2. Speed drops below 5 km/h
3. **Expected Log**: 
   ```
   🚤 SensorService: BOAT EXIT detected - speed: X km/h, altitude: XXm
   🚤 SensorService: BOAT MODE DEACTIVATED
     - Crash detection: NORMAL thresholds restored
     - Fall detection: NORMAL thresholds restored
   ```

**Success Criteria:**
- ✅ Detects exit when speed <5 km/h OR altitude >150m
- ✅ `_isOnBoat = false`
- ✅ Thresholds restored to normal (180 m/s², 100 m/s²)

---

## 🏃 Test 4: Walking/Hiking

### Objective: Verify sensors activate for pedestrian movement

### Steps:
1. Start walking (>5 km/h)
2. **Expected**: "Movement detected - speed: X km/h"
3. **Expected**: Sensors activate
4. Walk up stairs (altitude change >10m)
5. **Expected**: "Movement detected - altitude change: XXm"
6. Stop walking for 5+ minutes
7. **Expected**: Sensors hibernate

### Success Criteria:
- ✅ Activates for speed >5 km/h
- ✅ Activates for altitude change >10m
- ✅ Normal crash thresholds (180 m/s²)
- ✅ Hibernates after 5 min stationary

---

## 🛗 Test 5: Elevator/Multi-Story Building

### Objective: Verify altitude-based activation without speed

### Steps:
1. Enter elevator (speed ~0 km/h)
2. Travel multiple floors (altitude change >10m)
3. **Expected**: "Movement detected - altitude change: XXm"
4. **Expected**: Sensors activate

### Success Criteria:
- ✅ Activates based on altitude change alone
- ✅ No false airplane detection (speed too low)
- ✅ No false boat detection (altitude changing)

---

## 📊 Verification Checklist

### Motion-Based Activation ✅
- [ ] Sensors activate when speed >5 km/h
- [ ] Sensors activate when altitude changes >10m
- [ ] Sensors hibernate after 5 min of no movement
- [ ] Battery consumption reduced during hibernation

### Airplane Detection ✅
- [ ] Takeoff detected (climb >300 m/min + speed >200 km/h)
- [ ] Cruising confirmed (altitude 3,000-13,000m + speed >400 km/h)
- [ ] Landing detected (descent + altitude <1,000m)
- [ ] Crash detection suppressed during flight
- [ ] Normal mode restored after landing
- [ ] No false alerts during turbulence

### Boat Detection ✅
- [ ] Boat pattern detected (sea level + marine speed + wave motion)
- [ ] Pattern confirmed after 3 minutes
- [ ] Crash threshold increased to 250 m/s²
- [ ] Fall threshold increased to 120 m/s²
- [ ] Wave impacts filtered (variance 2-15 m/s²)
- [ ] Severe impacts (>250 m/s²) still detected
- [ ] Normal mode restored after docking

### Normal Car Driving ✅
- [ ] Sensors activate during driving
- [ ] Normal thresholds maintained (180 m/s²)
- [ ] No false alerts for potholes/bumps
- [ ] Sensors hibernate when parked

### Edge Cases ✅
- [ ] No airplane mode triggered during car driving
- [ ] No boat mode triggered during car driving
- [ ] No boat mode triggered in airplane
- [ ] Walking doesn't trigger airplane/boat mode
- [ ] Elevator altitude changes don't trigger airplane mode

---

## 🐛 Debugging Failed Tests

### Airplane Mode Not Activating
**Check:**
1. Altitude in correct range (3,000-13,000m)?
2. Speed >400 km/h?
3. Altitude stable (variance <100m)?
4. Pattern sustained >10 minutes?

**Debug Logs:**
```
// Look for:
✈️ SensorService: TAKEOFF detected
✈️ SensorService: FLIGHT CONFIRMED
```

### Boat Mode Not Activating
**Check:**
1. Altitude <100m?
2. Speed 5-100 km/h?
3. Motion variance 2-15 m/s²?
4. Pattern sustained >3 minutes?

**Debug Logs:**
```
// Look for:
🚤 SensorService: BOAT pattern detected
🚤 SensorService: BOAT CONFIRMED
```

### Sensors Not Hibernating
**Check:**
1. Speed <5 km/h?
2. Altitude not changing?
3. 5 minutes elapsed?
4. Movement timeout timer active?

**Debug Logs:**
```
// Look for:
SensorService: 😴 DEACTIVATING sensor monitoring
```

### False Crash Alerts
**Check:**
1. Current mode (airplane/boat/normal)?
2. Active threshold value?
3. Magnitude of impact?

**Debug Logs:**
```
// Look for:
SensorService: ✈️ Crash detection suppressed (airplane mode)
🚤 SensorService: BOAT MODE ACTIVATED (threshold: 250 m/s²)
```

---

## 📈 Performance Metrics

### Expected Results:

| Scenario | Sensor Active | Threshold | Battery Impact |
|----------|---------------|-----------|----------------|
| **Stationary** | ❌ No | N/A | Minimal (~5% of normal) |
| **Walking** | ✅ Yes | 180 m/s² | Low |
| **Car Driving** | ✅ Yes | 180 m/s² | Normal |
| **Airplane** | 🟡 Low Power | Suppressed | Very Low (~10% of normal) |
| **Boat** | ✅ Yes | 250 m/s² | Normal |

### Battery Consumption Targets:
- **Stationary**: <2% per hour
- **Normal movement**: <5% per hour
- **Airplane mode**: <3% per hour
- **Boat mode**: <5% per hour

---

## ✅ Final Validation

### Before Production Release:
- [ ] All test scenarios passed
- [ ] No false positives in any mode
- [ ] Correct threshold adjustments verified
- [ ] Battery consumption within targets
- [ ] Debug logs clearly show mode transitions
- [ ] Real emergencies still detected in all modes
- [ ] GPS integration working correctly
- [ ] Location service feeding sensor service properly

### Sign-Off:
- [ ] Car driving tested ✅
- [ ] Airplane flight tested ✅
- [ ] Boat travel tested ✅
- [ ] Walking/hiking tested ✅
- [ ] Stationary hibernation tested ✅
- [ ] Battery optimization verified ✅

---

**Status**: Ready for comprehensive field testing across all transportation modes! 🚗✈️🚤🚶
