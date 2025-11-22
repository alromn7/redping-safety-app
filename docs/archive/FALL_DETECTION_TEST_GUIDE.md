# 🧪 Fall Detection Test Guide

> **Test Date**: October 27, 2025  
> **Purpose**: Verify fall detection with real-world calibration formula  
> **Status**: Ready for testing

---

## 🎯 Test Objectives

1. ✅ Verify free-fall detection (weightlessness <2.0 m/s²)
2. ✅ Verify impact detection (ground impact >100 m/s²)
3. ✅ Verify height threshold (must be ≥1.0 meter)
4. ✅ Verify phone pickup cancellation (normal movement 10-15 m/s²)
5. ✅ Verify real-world formula is applied correctly
6. ✅ Test false positive prevention (pocket drops <1m)

---

## 📋 Pre-Test Checklist

### System Requirements:
- [ ] App running on device (10.177.98.199:5555)
- [ ] WiFi debugging active and connected
- [ ] Location services enabled
- [ ] Sensor service initialized and calibrated
- [ ] Emergency contact configured (for testing alerts)

### Monitoring Setup:
```powershell
# Terminal 1: Watch sensor logs
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "SensorService"

# Terminal 2: Watch fall detection specifically
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "Fall|FREE FALL|IMPACT"

# Terminal 3: Watch calibration values
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "calibrat|real.*world|convert"
```

### Check Calibration Status:
Look for these logs on app startup:
```
✅ Enhanced calibration complete!
  - Calibrated gravity: XX.XX m/s²
  - Noise factor: X.XX
  - Scaling factor: X.XX
  - Sensor quality: [Excellent/Good/Fair]
```

---

## 🧪 Test Scenarios

### Test 1: False Positive Prevention - Pocket Drop (Should NOT Alert)

**Setup**:
- Place phone in pocket (standing position)
- Height: ~0.5-0.8 meters from ground

**Procedure**:
1. Take phone out of pocket
2. Let it "slip" from hand naturally
3. Catch it before hitting ground OR let it drop on soft surface (carpet/cushion)

**Expected Results**:
```
❌ Should NOT trigger fall alert
Reason: Height < 1.0 meter threshold

Debug logs should show:
- Free fall detected: X.X seconds
- Calculated height: ~0.5-0.8m
- Height check: FAILED (below 1.0m threshold)
- Fall detection: CANCELLED
```

**Real-World Formula Check**:
- Free fall readings should be <2.0 m/s² (converted)
- Impact should be ~50-80 m/s² (converted)
- Height calculation: h = ½ × 9.8 × t²

---

### Test 2: Minimum Detection Height - 1 Meter Drop (SHOULD Alert)

**Setup**:
- Hold phone at waist height (~1.0-1.2 meters)
- Stand over soft surface (bed, couch, thick carpet)

**Procedure**:
1. Hold phone horizontally, screen facing up
2. Release phone (don't throw)
3. Let it fall naturally onto soft surface
4. DO NOT PICK UP immediately - wait 5 seconds

**Expected Results**:
```
✅ SHOULD trigger fall alert after 5 seconds

Debug logs should show:
1. "FREE FALL detected! Duration: X.X seconds"
2. "Calculated height: X.Xm (≥1.0m threshold)"
3. "IMPACT detected! Magnitude: XXX m/s²"
4. "Fall conditions met - starting cancellation window (5 seconds)"
5. After 5s: "Fall alert triggered - no phone pickup detected"
6. "AI verification: Are you okay?"
```

**Real-World Formula Verification**:
```
Free fall phase:
- Readings: <2.0 m/s² (weightlessness)
- Duration: ~0.45 seconds
- Calculated height: h = ½ × 9.8 × (0.45)² = ~1.0m ✅

Impact phase:
- Raw reading: ~1000-1200 m/s² (device-specific)
- Converted: (raw - calibrated_gravity) × scaling / noise + 9.8
- Result: Should be ~100-120 m/s² ✅
- Threshold: >100 m/s² ✅ PASS
```

---

### Test 3: Phone Pickup Cancellation (Should AUTO-CANCEL)

**Setup**:
- Hold phone at waist height (~1.0-1.2 meters)
- Stand over soft surface

**Procedure**:
1. Drop phone from 1+ meter height
2. **IMMEDIATELY pick it up** within 2-3 seconds
3. Walk around normally with phone in hand

**Expected Results**:
```
✅ Should CANCEL fall alert automatically

Debug logs should show:
1. "FREE FALL detected! Duration: X.X seconds"
2. "IMPACT detected! Magnitude: XXX m/s²"
3. "Fall conditions met - starting cancellation window (5 seconds)"
4. "Monitoring for phone pickup..."
5. "Normal movement detected: XX% of readings in 10-15 m/s² range"
6. "Fall CANCELLED - User picked up phone and moving normally"
```

**Real-World Formula Verification**:
```
Pickup detection phase:
- Normal walking: 10-15 m/s² (converted) ✅
- Detection threshold: 60% of readings in range
- Raw readings: ~100-150 m/s² (device-specific)
- Converted: Should be 10-15 m/s² ✅
```

---

### Test 4: Higher Drop - 2 Meter Ladder (SHOULD Alert - Severe)

**⚠️ SAFETY WARNING**: Only perform if you have VERY THICK cushions/mattress!

**Setup**:
- Use stepladder or elevated surface (~2 meters)
- Place thick mattress or multiple cushions below
- Have someone spot you

**Procedure**:
1. Stand on ladder/elevated surface
2. Hold phone at chest level (total height ~2+ meters)
3. Drop phone onto thick cushioning
4. DO NOT pick up for 5+ seconds

**Expected Results**:
```
✅ SHOULD trigger fall alert (more severe than 1m)

Debug logs should show:
1. "FREE FALL detected! Duration: X.X seconds"
2. "Calculated height: X.Xm (≥2.0m - SEVERE FALL)"
3. "IMPACT detected! Magnitude: XXX m/s² (higher than 1m drop)"
4. "Fall conditions met - starting cancellation window (5 seconds)"
5. After 5s: "SEVERE fall alert triggered!"
6. "AI verification: Are you okay?"
```

**Real-World Formula Verification**:
```
Free fall phase:
- Duration: ~0.64 seconds
- Calculated height: h = ½ × 9.8 × (0.64)² = ~2.0m ✅

Impact phase:
- Raw reading: ~2000-2500 m/s² (device-specific)
- Converted: Should be ~150-200 m/s² ✅
- Threshold: >100 m/s² ✅ PASS (well above)
```

---

### Test 5: Toss and Catch (Should NOT Alert)

**Setup**:
- Clear area with no obstacles
- Stand on soft surface (carpet)

**Procedure**:
1. Toss phone gently upward (~0.5 meters)
2. Catch it before it falls

**Expected Results**:
```
❌ Should NOT trigger fall alert
Reason: No impact detected (caught in hand)

Debug logs might show:
- Brief free fall detected
- No impact reading
- Fall detection: NOT TRIGGERED
```

---

### Test 6: Phone on Table Vibration (Should NOT Alert)

**Setup**:
- Place phone on table/desk
- Ensure table is stable

**Procedure**:
1. Leave phone sitting on table
2. Bang table hard or shake table
3. Observe sensor readings

**Expected Results**:
```
❌ Should NOT trigger fall alert
Reason: No free fall detected (gravity always present)

Debug logs should show:
- Magnitude: 9-12 m/s² (table vibration + gravity)
- No free fall phase detected
- Fall detection: NOT TRIGGERED
```

---

## 📊 Test Results Template

### Test Session Information:
```
Date: __________
Time: __________
Device: __________
Calibration Values:
  - Calibrated Gravity: ______ m/s²
  - Noise Factor: ______
  - Scaling Factor: ______
  - Sensor Quality: ______
```

### Individual Test Results:

#### Test 1: Pocket Drop (0.5-0.8m)
- [ ] PASS - No alert triggered ✅
- [ ] FAIL - False positive ❌
- Notes: _________________________________

#### Test 2: 1 Meter Drop (no pickup)
- [ ] PASS - Alert triggered after 5s ✅
- [ ] FAIL - No alert or wrong timing ❌
- Free fall duration: ______ seconds
- Calculated height: ______ meters
- Impact magnitude (converted): ______ m/s²
- Notes: _________________________________

#### Test 3: 1 Meter Drop (immediate pickup)
- [ ] PASS - Auto-cancelled ✅
- [ ] FAIL - Alert triggered despite pickup ❌
- Pickup detection time: ______ seconds
- Normal movement ratio: ______%
- Notes: _________________________________

#### Test 4: 2 Meter Drop (severe)
- [ ] PASS - Alert triggered (severe) ✅
- [ ] FAIL - No alert or wrong severity ❌
- Free fall duration: ______ seconds
- Calculated height: ______ meters
- Impact magnitude (converted): ______ m/s²
- Notes: _________________________________

#### Test 5: Toss and Catch
- [ ] PASS - No alert ✅
- [ ] FAIL - False positive ❌
- Notes: _________________________________

#### Test 6: Table Vibration
- [ ] PASS - No alert ✅
- [ ] FAIL - False positive ❌
- Notes: _________________________________

---

## 🔍 What to Look For in Logs

### ✅ Correct Behavior Indicators:

**Free Fall Detection**:
```
SensorService: FREE FALL detected! Duration: 0.45 seconds
SensorService: Calculated fall height: 1.0m (≥1.0m threshold) ✅
```

**Real-World Conversion Active**:
```
SensorService: Impact magnitude: 115.3 m/s² (converted from raw: 1150 m/s²)
```

**Height Threshold Working**:
```
SensorService: Fall height 0.7m < 1.0m threshold - REJECTED ✅
```

**Pickup Detection Working**:
```
SensorService: Normal movement detected - 80% of readings show handling
SensorService: Fall CANCELLED - User picked up phone ✅
```

### ❌ Error Indicators:

**Not Using Real-World Conversion** (BAD):
```
❌ Impact magnitude: 1150 m/s² (comparing raw value to threshold)
```

**Should see instead** (GOOD):
```
✅ Impact magnitude: 115.3 m/s² (real-world converted)
```

**Wrong Height Calculation** (BAD):
```
❌ Calculated height: 0.1m from 0.45s fall (wrong formula)
```

**Should see instead** (GOOD):
```
✅ Calculated height: 1.0m from 0.45s fall (h = ½gt²)
```

---

## 🎯 Success Criteria

### For Production Approval:

**Must Pass ALL**:
- [ ] Test 1: No false positive on pocket drop (<1m)
- [ ] Test 2: Alert triggered on 1m+ drop without pickup
- [ ] Test 3: Auto-cancelled when phone picked up
- [ ] Test 5: No false positive on toss and catch
- [ ] Test 6: No false positive on table vibration

**Must Show Correct Values**:
- [ ] Free fall readings: <2.0 m/s² (converted)
- [ ] Impact readings: 100-200 m/s² (converted, not raw)
- [ ] Height calculation: Accurate ±0.2m
- [ ] Pickup detection: 60%+ normal movement threshold

**Optional (Safety Test)**:
- [ ] Test 4: Severe fall detection on 2m+ drop

---

## 📝 Troubleshooting

### Issue: No fall detected despite 1m+ drop

**Check**:
1. Is calibration complete? Look for "Enhanced calibration complete!"
2. Are sensor readings being logged? Check "Accel:" messages
3. Is fall detection enabled? Check settings

**Debug**:
```powershell
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "calibrat|_checkForFall|FREE FALL"
```

### Issue: False positives on normal movement

**Check**:
1. Height threshold working? Should reject <1.0m
2. Free fall duration adequate? Should be >0.3s
3. Impact threshold correct? Should be >100 m/s² (converted)

**Debug**:
```powershell
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "Fall.*height|threshold|REJECT"
```

### Issue: Pickup cancellation not working

**Check**:
1. Normal movement detection using converted values?
2. Detection ratio threshold at 60%?
3. Movement range 10-15 m/s² (converted)?

**Debug**:
```powershell
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "pickup|movement.*detect|normal.*movement"
```

---

## 🚀 Quick Start Commands

### 1. Start App and Monitor:
```powershell
# Terminal 1: Run app
cd C:\flutterapps\redping_14v
flutter run --device-id=10.177.98.199:5555

# Terminal 2: Watch fall detection
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "Fall|IMPACT|FREE FALL|pickup|cancel"

# Terminal 3: Watch calibration values
adb -s 10.177.98.199:5555 logcat -s flutter:I | Select-String "convert|calibrat|real.*world"
```

### 2. Hot Reload After Viewing Logs:
```powershell
# In the flutter run terminal, press: r
```

### 3. Full Restart If Needed:
```powershell
# In the flutter run terminal, press: R
```

---

## ✅ Test Completion

After completing all tests, document:

1. **Overall Result**: PASS / FAIL
2. **Tests Passed**: ___/6
3. **Critical Issues Found**: ___________
4. **Production Ready**: YES / NO
5. **Recommended Actions**: ___________

---

**END OF FALL DETECTION TEST GUIDE**
