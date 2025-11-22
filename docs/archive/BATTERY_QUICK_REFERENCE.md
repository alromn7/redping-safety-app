# ⚠️ BATTERY OPTIMIZATION - QUICK REFERENCE CARD

**Print this and keep at your desk when working on REDP!NG code**

---

## 🔒 MANDATORY RULES

### **Before Touching Sensor/Battery Code:**

✅ **READ FIRST**: `BATTERY_GOVERNANCE_RULES.md`  
✅ **PRIMARY DOC**: `docs/ultra_battery_optimization.md`

---

## 🚫 NEVER DO THIS (WILL BREAK BATTERY)

```dart
// ❌ Fixed high-frequency sampling
int _getSamplingRateForBattery() {
  return 100; // 10 Hz continuous = CATASTROPHIC
}

// ❌ Disable motion detection
void _processSensorData(event) {
  _detectCrashOrFall(event); // Always process = BATTERY KILLER
}

// ❌ Remove smart enhancements
bool _isLikelySleeping = false;  // Hardcoded
bool _isCharging = false;         // Ignored
bool _isInSafeLocation = false;   // Disabled

// ❌ Bypass battery exemption
void initState() {
  // Start monitoring without exemption = Doze will kill app
}

// ❌ Process every reading when stationary
if (_sampleCounter++ % 1 == 0) { // Was % 10
  _detectCrashOrFall(event); // 10x battery consumption
}
```

---

## ✅ DO THIS (BATTERY-FRIENDLY)

```dart
// ✅ Respect sampling rate hierarchy
int _getSamplingRateForBattery() {
  if (sosTriggered) return _SAMPLING_RATE_SOS;        // 10 Hz - Priority 1
  if (_isLikelySleeping) return _SAMPLING_RATE_SLEEP; // 0.1 Hz - Priority 2
  if (_isCharging) return _SAMPLING_RATE_CHARGING;    // 5 Hz - Priority 3
  if (_isInSafeLocation) return rate * 0.5;           // 50% reduction
  return _batteryAdaptiveRate();                      // 0.2-2 Hz adaptive
}

// ✅ Use motion-triggered processing
if (_isMoving) {
  _detectCrashOrFall(event);
} else if (_sampleCounter++ % 10 == 0) {
  _safetyCheckOnly(event); // Minimal processing
}

// ✅ Request battery exemption on startup
await PlatformService.requestBatteryOptimizationExemption();
final isExempt = await PlatformService.isBatteryOptimizationDisabled();

// ✅ Add new optimization (not remove existing)
bool _isInMeeting = false; // Calendar-based reduction
if (_isInMeeting && _isStationary) {
  return _SAMPLING_RATE_SLEEP; // Extra savings
}
```

---

## 📊 SACRED NUMBERS (DO NOT CHANGE)

| Parameter | Value | Why |
|-----------|-------|-----|
| **SOS Sampling** | 10 Hz | Emergency = full power |
| **Sleep Sampling** | 0.1 Hz | Night mode (11pm-7am) |
| **Charging Sampling** | 5 Hz | Battery cost = 0% |
| **Standard Sampling** | 0.2-2 Hz | Battery-adaptive |
| **Stationary Process** | Every 10th | 90% reduction |
| **Daily Consumption** | ≤32% | Acceptance criteria |
| **Runtime Target** | ≥25 hours | User requirement |
| **Sleep Hours** | 11pm-7am (8h) | User pattern |
| **High Temp** | >40°C | Overheat protection |

---

## ✅ PRE-COMMIT CHECKLIST

**Print this and fill out for EVERY sensor/battery PR:**

```
□ Read battery governance rules (BATTERY_GOVERNANCE_RULES.md)
□ Completed battery impact assessment
□ No fixed high-frequency sampling added (>10 Hz)
□ Motion-based processing still works
□ All 5 enhancements functional (_isLikelySleeping, _isCharging, 
  _isInSafeLocation, _historicalMotionPatterns, _deviceTemperature)
□ Always-on components not removed (exemption, boot receiver)
□ Sampling rate hierarchy unchanged (SOS > Sleep > Charging...)
□ Ran local 24-hour battery test
□ Battery consumption ≤32% daily
□ Updated docs/ultra_battery_optimization.md
□ Updated COMPLETE_BATTERY_OPTIMIZATION_SUMMARY.md
□ Added code comments explaining battery decisions
□ Written PR with battery compliance section
□ Added/updated battery regression test
□ SOS override tested (10 Hz within 1 second)
□ Always-on reliability ≥95%
□ Boot receiver auto-start tested
□ Battery exemption persistence verified

Developer: ________________  Date: ________
Battery-Certified Reviewer 1: ____________  Date: ________
Battery-Certified Reviewer 2: ____________  Date: ________
```

---

## 🎯 FILES YOU'LL MODIFY

### **Core Files** (HIGH RISK - Extra caution):
- `lib/services/sensor_service.dart` - Sampling logic, 5 enhancements
- `lib/services/platform_service.dart` - Battery exemption
- `android/.../MainActivity.kt` - Platform channel
- `android/.../BootReceiver.kt` - Auto-start
- `android/.../AndroidManifest.xml` - Permissions

### **Documentation** (MUST UPDATE):
- `docs/ultra_battery_optimization.md` - Primary blueprint
- `COMPLETE_BATTERY_OPTIMIZATION_SUMMARY.md` - Metrics
- Code comments - Battery impact notes

---

## 🧪 REQUIRED TESTS

**ALL must pass before merge:**

1. ✅ **24-hour continuous test** → Battery ≤32%
2. ✅ **Sleep mode** (11pm-7am) → ≤0.5%/hour
3. ✅ **Charging optimization** → 0% cost when plugged
4. ✅ **Safe location** → 50% reduction at WiFi
5. ✅ **Battery exemption** → Persists after app restart
6. ✅ **Boot receiver** → Auto-starts after reboot
7. ✅ **Doze mode** → Works with exemption
8. ✅ **SOS override** → 10 Hz within 1 second

**Test Command**:
```bash
flutter test test/services/platform_service_test.dart
flutter test test/services/sensor_service_test.dart
# Then run 24-hour on-device test
```

---

## 🚨 ALERT THRESHOLDS

**Automated Alerts** (CI/CD + Weekly Dashboard):

| Metric | Warning (⚠️) | Critical (🚨) | Action |
|--------|-------------|---------------|---------|
| Daily Battery | >35% | >40% | Investigate / Rollback |
| Always-On | <90% | <80% | Check exemption |
| SOS Response | >1.5s | >2s | Critical bug |
| Runtime | <20h | <15h | Emergency fix |

---

## 📞 WHO TO ASK

**Battery Questions**:
- Tech Lead (battery certified Level 3)
- Senior Engineer (battery certified Level 3)

**Emergency Battery Regression**:
1. Stop all deployments
2. Post in #battery-alerts Slack
3. Check `git log lib/services/sensor_service.dart`
4. Rollback to last stable battery tag
5. Page on-call if not resolved in 4 hours

---

## 🎓 CERTIFICATION LEVELS

**Level 1** (All developers):
- Read full blueprint (2300+ lines)
- Understand sampling hierarchy
- Know 5 enhancements
- Pass 10-question quiz

**Level 2** (Sensor/battery developers):
- Complete Level 1
- Study sensor_service.dart
- Run 24-hour battery test
- Shadow code review

**Level 3** (Battery code reviewers):
- Complete Level 2
- Conduct 5 battery reviews
- Fix battery regression
- Design optimized feature
- Tech lead approval

---

## 🔄 SAMPLING RATE HIERARCHY (PRIORITY ORDER)

**NEVER CHANGE THIS ORDER**:

```
1. SOS Mode        → 10 Hz   (0.1s)  ⚠️ HIGHEST
2. Sleep Mode      → 0.1 Hz  (10s)   🌙 11pm-7am
3. Charging Mode   → 5 Hz    (0.2s)  ⚡ Battery >80%
4. Safe Location   → 50% reduction   🏠 WiFi
5. Pattern Learning→ Routine-based   🧠 2-week learning
6. Temperature     → Reduce if >40°C 🌡️ Protection
7. Battery Level   → 0.2-2 Hz       🔋 Adaptive
8. Stationary      → Every 10th     💤 95% reduction
```

**Emergency Override**: SOS ALWAYS wins (all else disabled)

---

## 📝 PR TEMPLATE - BATTERY COMPLIANCE

```markdown
## Battery Optimization Compliance

**Impact Assessment**:
- [ ] Reviewed sampling rate impact
- [ ] Verified motion-based processing preserved
- [ ] Confirmed 5 enhancements not disabled
- [ ] Tested battery consumption (before/after)
- [ ] Updated blueprint documentation
- [ ] Added battery regression test
- [ ] Verified always-on reliability maintained
- [ ] Tested SOS override still works
- [ ] Checked manufacturer compatibility
- [ ] Updated performance metrics

**Battery Impact Measurements**:
| Scenario | Before | After | Change |
|----------|--------|-------|--------|
| Stationary | X%/h | Y%/h | +/-Z% |
| Active | X%/h | Y%/h | +/-Z% |
| Sleep | X%/h | Y%/h | +/-Z% |
| Daily Total | X% | Y% | +/-Z% |

**24-Hour Test Results**:
- Device: __________
- Battery Level Start: ____%
- Battery Level End: ____%
- Total Consumption: ____% (must be ≤32%)
- Always-On Reliability: ____% (must be ≥95%)

**Justification**: 
<Explain why this change is needed and how it maintains/improves battery>

**Reviewers**: Tag 2 reviewers (1 must be battery-certified Level 3)
```

---

## 🏆 SUCCESS METRICS

**You're doing it right if:**
- ✅ Daily battery consumption ≤32%
- ✅ Runtime ≥25 hours on single charge
- ✅ Always-on reliability ≥95%
- ✅ SOS response time ≤1 second
- ✅ Sleep mode consumption ≤0.5%/hour
- ✅ Zero user complaints about battery
- ✅ Automatic post-reboot operation
- ✅ All 5 enhancements active

**You broke it if:**
- 🚨 Daily consumption >40%
- 🚨 Runtime <15 hours
- 🚨 Always-on reliability <80%
- 🚨 SOS response >2 seconds
- 🚨 App dies in Doze mode
- 🚨 Manual restart after reboot required

---

## 💡 GOLDEN RULE

> **"Every line of code that touches sensors or battery MUST make the system more efficient OR maintain existing efficiency. If it makes battery consumption worse, redesign it or don't ship it."**

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Next Review**: Monthly

**Keep this card visible while coding. Battery optimization is not optional.**
