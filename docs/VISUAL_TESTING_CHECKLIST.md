# RedPing Mode System - Visual Testing Checklist

**Purpose**: Quick manual testing guide to verify all integrations work correctly  
**Time Required**: ~15 minutes  
**Status**: Ready for testing

---

## 🎯 Quick Start

### Prerequisites
1. Run test data generators:
```dart
// In main.dart or run in debug console
await FamilyLocationTestData.generateAll();
await GroupActivityTestData.generateAll();
await ExtremeActivityTestData.generateAll();
await TravelModeTestData.generateAll();
await WorkModeTestData.generateAll();
```

2. Launch app on emulator/device
3. Navigate to SOS Page

---

## ✅ Test Sequence

### Test 1: Family Mode (2 minutes)

**Steps**:
1. On SOS page, tap "RedPing Mode" selector
2. Select "Family Protection" mode
3. **VERIFY**: Status indicator shows:
   - Left: "✅ All Systems Active" (green)
   - Right: "👨‍👩‍👧‍👦 Family Protection Active" (blue)
4. **VERIFY**: "Family Dashboard" button appears below mode metrics
5. Tap "Family Dashboard" button
6. **VERIFY**: FamilyModeDashboard opens with 3 tabs (Members, Safe Zones, History)
7. **VERIFY**: Test data appears (5 members, 3 safe zones)
8. Navigate back to SOS page
9. Deactivate mode
10. **VERIFY**: Status indicator returns to single-wide system status

**Expected Results**:
- [x] Mode activates without errors
- [x] Status indicator shows blue family icon
- [x] Dashboard button appears
- [x] Dashboard loads with data
- [x] Navigation works both ways

---

### Test 2: Group Mode (2 minutes)

**Steps**:
1. Activate "Group Activity" mode
2. **VERIFY**: Status indicator shows:
   - Left: "✅ All Systems Active" (green)
   - Right: "👥 Group Activity Active" (green)
3. **VERIFY**: "Group Dashboard" button appears
4. Tap "Group Dashboard" button
5. **VERIFY**: GroupActivityDashboard opens with 4 tabs
6. **VERIFY**: Test data appears (3 activities, 15 rally points, 20 members)
7. Navigate back and deactivate

**Expected Results**:
- [x] Mode activates with green theme
- [x] Dashboard shows 4 tabs (Activities, Rally Points, Members, History)
- [x] All tabs load without errors

---

### Test 3: Extreme Mode - Skiing (2 minutes)

**Steps**:
1. Activate "Skiing/Snowboarding" mode
2. **VERIFY**: Status indicator shows:
   - Left: "✅ All Systems Active" (green)
   - Right: "⛷️ Skiing/Snowboarding Active" (blue #1E88E5)
3. **VERIFY**: "Extreme Activity Manager" button appears
4. Tap "Extreme Activity Manager" button
5. **VERIFY**: ExtremeActivityDashboard opens with 4 tabs
6. **VERIFY**: Equipment, safety checklists, and sessions load
7. Navigate back and deactivate

**Expected Results**:
- [x] Mode activates with snow blue theme
- [x] Dashboard button labeled "Extreme Activity Manager"
- [x] Dashboard shows equipment for skiing

---

### Test 4: Extreme Mode - Climbing (2 minutes)

**Steps**:
1. Activate "Rock Climbing" mode
2. **VERIFY**: Status indicator shows:
   - Left: "✅ All Systems Active" (green)
   - Right: "🧗 Rock Climbing Active" (brown #8D6E63)
3. **VERIFY**: "Extreme Activity Manager" button appears
4. Tap button
5. **VERIFY**: Dashboard filters to climbing-specific equipment
6. Navigate back and deactivate

**Expected Results**:
- [x] Same dashboard, different activity type
- [x] Equipment changes based on sport

---

### Test 5: Travel Mode (2 minutes)

**Steps**:
1. Activate "Travel Mode"
2. **VERIFY**: Status indicator shows:
   - Left: "✅ All Systems Active" (green)
   - Right: "✈️ Travel Mode Active" (blue)
3. **VERIFY**: "Travel Manager" button appears
4. Tap "Travel Manager" button
5. **VERIFY**: TravelModeDashboard opens with 4 tabs
6. **VERIFY**: Test data appears (3 trips, documents, itinerary, expenses)
7. Check Documents tab for expiry alerts
8. Navigate back and deactivate

**Expected Results**:
- [x] Mode activates with blue theme
- [x] Dashboard shows 4 tabs (Trips, Itinerary, Documents, Expenses)
- [x] Document expiry alerts visible
- [x] Active trip shown

---

### Test 6: Work Mode - Working at Height (2 minutes)

**Steps**:
1. Activate "Working at Height" mode
2. **VERIFY**: Status indicator shows:
   - Left: "✅ All Systems Active" (green)
   - Right: "🏗️ Working at Height Active" (amber)
3. **VERIFY**: "Work Manager" button appears
4. Tap "Work Manager" button
5. **VERIFY**: WorkModeDashboard opens with 4 tabs
6. **VERIFY**: Test data appears (5 shifts, tasks, incidents)
7. Check Shifts tab for active shift
8. Navigate back and deactivate

**Expected Results**:
- [x] Mode activates with amber theme
- [x] Dashboard shows 4 tabs (Shifts, Time, Tasks, Incidents)
- [x] Live clock visible in Time tab
- [x] Shift status displayed

---

### Test 7: Work Mode - Remote Area (2 minutes)

**Steps**:
1. Activate "Remote Area" mode
2. **VERIFY**: Status indicator shows orange theme
3. **VERIFY**: "Work Manager" button still appears (same dashboard for all work modes)
4. Tap button
5. **VERIFY**: Same WorkModeDashboard loads
6. Navigate back and deactivate

**Expected Results**:
- [x] Different work mode, same dashboard
- [x] Theme color changes based on mode

---

### Test 8: Mode Switching (1 minute)

**Steps**:
1. Activate Family mode
2. **VERIFY**: Family dashboard button appears
3. Switch to Group mode (without deactivating Family first)
4. **VERIFY**: Family button disappears
5. **VERIFY**: Group button appears
6. **VERIFY**: Status indicator updates to show Group mode

**Expected Results**:
- [x] Switching modes updates UI immediately
- [x] Only one dashboard button visible at a time
- [x] Status indicator updates correctly

---

### Test 9: Status Indicator Overflow (1 minute)

**Steps**:
1. Activate "Skydiving/Paragliding" mode (longest name)
2. **VERIFY**: Status indicator text doesn't overflow
3. **VERIFY**: Both system status and mode status fit on screen
4. **VERIFY**: Text truncates with ellipsis if needed

**Expected Results**:
- [x] No text overflow
- [x] Layout remains 50/50 split
- [x] Text readable on all screen sizes

---

### Test 10: No Active Mode (1 minute)

**Steps**:
1. Ensure no mode is active
2. **VERIFY**: Status indicator shows only:
   - "✅ All Systems Active" (full width, no split)
3. **VERIFY**: No dashboard buttons visible
4. **VERIFY**: Mode metrics section not visible

**Expected Results**:
- [x] Single-wide status indicator
- [x] No dashboard buttons
- [x] Clean UI when no mode active

---

## 🎨 Visual Verification Matrix

| Mode Category | Icon | Color | Dashboard Button | Dashboard Loads |
|--------------|------|-------|------------------|-----------------|
| Family Protection | 👨‍👩‍👧‍👦 | Blue | "Family Dashboard" | ✅ 3 tabs |
| Group Activity | 👥 | Green | "Group Dashboard" | ✅ 4 tabs |
| Skiing | ⛷️ | Snow Blue | "Extreme Activity Manager" | ✅ 4 tabs |
| Climbing | 🧗 | Brown | "Extreme Activity Manager" | ✅ 4 tabs |
| Hiking | 🥾 | Forest Green | "Extreme Activity Manager" | ✅ 4 tabs |
| Mountain Biking | 🚵 | Orange | "Extreme Activity Manager" | ✅ 4 tabs |
| Boating | ⛵ | Deep Blue | "Extreme Activity Manager" | ✅ 4 tabs |
| Scuba Diving | 🤿 | Deep Ocean | "Extreme Activity Manager" | ✅ 4 tabs |
| Swimming | 🏊 | Cyan | "Extreme Activity Manager" | ✅ 4 tabs |
| 4WD Off-road | 🚙 | Brown | "Extreme Activity Manager" | ✅ 4 tabs |
| Trail Running | 🏃 | Light Green | "Extreme Activity Manager" | ✅ 4 tabs |
| Skydiving | 🪂 | Pink | "Extreme Activity Manager" | ✅ 4 tabs |
| Flying | ✈️ | Aviation Blue | "Extreme Activity Manager" | ✅ 4 tabs |
| Travel Mode | ✈️ | Blue | "Travel Manager" | ✅ 4 tabs |
| Remote Area | 🏔️ | Orange | "Work Manager" | ✅ 4 tabs |
| Working at Height | 🏗️ | Amber | "Work Manager" | ✅ 4 tabs |
| High Risk Task | ⚠️ | Red | "Work Manager" | ✅ 4 tabs |

---

## 🐛 Common Issues to Check

### Issue 1: Dashboard Not Opening
**Symptom**: Tapping button does nothing  
**Check**:
- [ ] Verify import statement exists for dashboard file
- [ ] Check console for navigation errors
- [ ] Verify mode ID matches condition (e.g., `activeMode.id == 'travel'`)

### Issue 2: Status Indicator Not Updating
**Symptom**: Indicator doesn't change when mode activated  
**Check**:
- [ ] Verify `RedPingModeService.activateMode()` was called
- [ ] Check if SOS page rebuilds on `notifyListeners()`
- [ ] Verify `_buildSimpleSystemStatus()` is in widget tree

### Issue 3: Wrong Dashboard Opens
**Symptom**: Clicking Family button opens Group dashboard  
**Check**:
- [ ] Verify conditional logic: `if (activeMode.id == 'family_protection')`
- [ ] Check no overlapping conditions
- [ ] Verify correct dashboard class imported

### Issue 4: Test Data Not Appearing
**Symptom**: Dashboards open but show empty lists  
**Check**:
- [ ] Verify test data generators ran: `await XxxTestData.generateAll()`
- [ ] Check SharedPreferences keys are correct
- [ ] Verify service `initialize()` method was called
- [ ] Check StreamBuilder is listening to correct stream

### Issue 5: Theme Color Wrong
**Symptom**: Status indicator or button shows wrong color  
**Check**:
- [ ] Verify mode definition in `redping_mode_service.dart`
- [ ] Check `activeMode.themeColor` is used, not hardcoded color
- [ ] Verify color hex codes match documentation

---

## 📊 Testing Results Template

### Test Session Details
- **Date**: _______________
- **Tester**: _______________
- **Device**: _______________
- **Flutter Version**: _______________

### Results Summary

| Test # | Mode Tested | Status | Notes |
|--------|-------------|--------|-------|
| 1 | Family Protection | ⬜ PASS / ⬜ FAIL | |
| 2 | Group Activity | ⬜ PASS / ⬜ FAIL | |
| 3 | Skiing/Snowboarding | ⬜ PASS / ⬜ FAIL | |
| 4 | Rock Climbing | ⬜ PASS / ⬜ FAIL | |
| 5 | Travel Mode | ⬜ PASS / ⬜ FAIL | |
| 6 | Working at Height | ⬜ PASS / ⬜ FAIL | |
| 7 | Remote Area | ⬜ PASS / ⬜ FAIL | |
| 8 | Mode Switching | ⬜ PASS / ⬜ FAIL | |
| 9 | Status Overflow | ⬜ PASS / ⬜ FAIL | |
| 10 | No Active Mode | ⬜ PASS / ⬜ FAIL | |

### Overall Assessment
- **Total Tests**: 10
- **Passed**: _____ / 10
- **Failed**: _____ / 10
- **Pass Rate**: _____ %

### Issues Found
1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

### Recommendations
1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

---

## 🚀 Quick Debug Commands

### Check Active Mode
```dart
// Run in debug console
print(RedPingModeService().activeMode?.name);
print(RedPingModeService().activeMode?.id);
print(RedPingModeService().hasActiveMode);
```

### Check Service Initialization
```dart
print(FamilyLocationService.instance.isInitialized);
print(GroupActivityService.instance.isInitialized);
print(ExtremeActivityService.instance.isInitialized);
print(TravelModeService.instance.isInitialized);
print(WorkModeService.instance.isInitialized);
```

### Check Test Data
```dart
print(FamilyLocationService.instance.familyMembers.length);
print(GroupActivityService.instance.activities.length);
print(ExtremeActivityService.instance.equipment.length);
print(TravelModeService.instance.trips.length);
print(WorkModeService.instance.shifts.length);
```

---

## ✅ Sign-off

**Verified by**: _______________  
**Date**: _______________  
**Signature**: _______________

**System Status**: ⬜ Production Ready / ⬜ Needs Fixes

---

**END OF CHECKLIST**
