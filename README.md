# REDP!NG - Emergency Safety & Monitoring System

A Flutter-based emergency monitoring application with industry-leading battery optimization for 24/7 operation.

---

## ⚠️ MANDATORY GOVERNANCE FOR DEVELOPERS

**Before making ANY changes to this codebase, READ:**

1. 🔒 **[BATTERY GOVERNANCE RULES](BATTERY_GOVERNANCE_RULES.md)** - MANDATORY compliance framework
2. 📖 **[Battery Optimization Blueprint](docs/ultra_battery_optimization.md)** - Complete technical specification
3. 📋 **[Quick Reference Card](BATTERY_QUICK_REFERENCE.md)** - Developer checklist (print & keep)

**Key Rules**:
- ✅ Battery impact assessment required before ANY sensor/battery code changes
- ✅ 24-hour battery test must pass (≤32% daily consumption)
- ✅ All 5 smart enhancements must remain functional
- ✅ Always-on reliability must stay ≥95%
- ✅ Documentation must be updated with every change
- ✅ 2 code reviewers required (1 battery-certified)

**Non-compliance = PR blocked + potential rollback**

---

## 🎯 Battery Optimization Achievements

**Status**: 🔒 **PRODUCTION READY + GOVERNANCE ENFORCED**

| Metric | Achievement |
|--------|-------------|
| **Battery Efficiency** | 95-98% reduction vs baseline |
| **Runtime** | 25-40 hours on single charge |
| **Daily Consumption** | 25-32% (was ~90%) |
| **Always-On Reliability** | 95%+ (with battery exemption) |
| **Post-Reboot** | Automatic restart (was manual) |

**Features**:
- ✅ Motion-based processing (95% reduction when stationary)
- ✅ Battery-adaptive sampling (0.1-10 Hz dynamic)
- ✅ 5 smart enhancements (sleep, charging, location, pattern, temperature)
- ✅ Android Doze bypass (battery optimization exemption)
- ✅ Auto-start after device reboot
- ✅ SOS emergency override (<1 second response)

---

## 📚 Documentation Structure

### **For Developers** (READ BEFORE CODING):
1. **[BATTERY_GOVERNANCE_RULES.md](BATTERY_GOVERNANCE_RULES.md)** ⚠️ MANDATORY
   - 12 non-negotiable compliance rules
   - Battery impact assessment process
   - Testing requirements
   - Code review checklist
   - Developer certification program

2. **[BATTERY_QUICK_REFERENCE.md](BATTERY_QUICK_REFERENCE.md)** 📋 PRINT & KEEP
   - Pre-commit checklist
   - Do's and don'ts
   - Sacred numbers (sampling rates)
   - PR template
   - Emergency contacts

3. **[docs/ultra_battery_optimization.md](docs/ultra_battery_optimization.md)** 📖 PRIMARY BLUEPRINT
   - Complete technical specification (2300+ lines)
   - Architecture overview
   - Implementation details
   - Testing scenarios
   - Performance metrics

### **For Reference**:
4. **[COMPLETE_BATTERY_OPTIMIZATION_SUMMARY.md](COMPLETE_BATTERY_OPTIMIZATION_SUMMARY.md)** - Quick overview
5. **[ALWAYS_ON_FUNCTIONALITY_CHECK.md](ALWAYS_ON_FUNCTIONALITY_CHECK.md)** - Platform analysis (3000+ lines)
6. **[ALWAYS_ON_IMPLEMENTATION_SUMMARY.md](ALWAYS_ON_IMPLEMENTATION_SUMMARY.md)** - Implementation guide
7. **[ENHANCEMENT_SUMMARY.md](ENHANCEMENT_SUMMARY.md)** - 5 enhancements detail

---

## 🚀 Getting Started

### **Prerequisites**:
- Flutter SDK ^3.9.2
- Android Studio / Xcode
- Physical device for testing (battery tests require real hardware)

### **Installation**:
```bash
# Clone repository
git clone <repository-url>
cd redping_14v

# Install dependencies
flutter pub get

# Run on device (NOT emulator for battery testing)
flutter run
```

### **Release Build (Local)**
```bash
flutter build appbundle --release
flutter build apk --release
```

### **Keystore & CI Secrets Setup**
1. Generate release keystore:
```bash
keytool -genkeypair -v -keystore android/keystore/redping-release.jks -storetype JKS -keyalg RSA -keysize 4096 -validity 12000 -alias redping_release
```
2. Base64 encode for GitHub secret:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('android\keystore\redping-release.jks')) | Out-File keystore.b64
Get-Content keystore.b64 | Set-Clipboard
```
3. Add repository secrets (Settings → Secrets → Actions):
   - `ANDROID_KEYSTORE_BASE64` – contents of `keystore.b64`
   - `ANDROID_KEYSTORE_PASSWORD` – keystore password
   - `ANDROID_KEY_PASSWORD` – key (alias) password
   - `ANDROID_KEY_ALIAS` – `redping_release` (or custom alias)
4. (Optional local file) `key.properties` for developer machines:
```
storeFile=android/keystore/redping-release.jks
storePassword=<storePassword>
keyAlias=redping_release
keyPassword=<keyPassword>
```
5. Run script locally:
```powershell
powershell -ExecutionPolicy Bypass -File .\release_build_verify.ps1
```
6. Trigger CI build by pushing a tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Artifacts (AAB + APK) appear in GitHub Actions under "Release Build & Verify".

### **First-Time Setup**:
1. Read `BATTERY_GOVERNANCE_RULES.md` (REQUIRED)
2. Complete Level 1 battery certification quiz
3. Review `docs/ultra_battery_optimization.md`
4. Print and keep `BATTERY_QUICK_REFERENCE.md` at desk
5. Set up local 24-hour battery test environment

---

## 🧪 Testing

### **Battery Tests** (REQUIRED before PR):
```bash
# Unit tests
flutter test test/services/sensor_service_test.dart
flutter test test/services/platform_service_test.dart

# 24-hour on-device test (MANDATORY)
# 1. Fully charge device to 100%
# 2. Start app with monitoring enabled
# 3. Use device normally for 24 hours
# 4. Check battery consumption ≤32%
# 5. Verify always-on reliability ≥95%
# 6. Document results in PR
```

### **Acceptance Criteria**:
- ✅ Daily battery consumption ≤32%
- ✅ 24-hour runtime ≥25 hours (extrapolated)
- ✅ Always-on reliability ≥95%
- ✅ SOS response time ≤1 second
- ✅ Sleep mode consumption ≤0.5%/hour
- ✅ Automatic restart after reboot

---

## 🔧 Development Workflow

### **Making Changes**:
1. **STOP** - Read `BATTERY_GOVERNANCE_RULES.md` Rule 1
2. Complete battery impact assessment checklist
3. If ANY item = YES → Redesign or get exception approval
4. Implement with battery optimization in mind
5. Run required battery tests (8 tests)
6. Update documentation (blueprint + summary + code comments)
7. Complete PR checklist (10 items)
8. Get 2 reviewer approvals (1 battery-certified)
9. Pass CI/CD regression tests
10. Tag stable version if merged

### **Files to Update** (for battery-related changes):
- `docs/ultra_battery_optimization.md` - Blueprint
- `COMPLETE_BATTERY_OPTIMIZATION_SUMMARY.md` - Metrics
- Code comments - Battery impact notes
- Test files - Regression tests

---

## 📊 Weekly Compliance Monitoring

**Every Monday, review**:
- Average daily battery consumption (target ≤32%)
- Always-on reliability percentage (target ≥95%)
- SOS response time p95 (target ≤1s)
- User-reported battery issues (target 0)
- Code review compliance rate (target 100%)

**Alert Thresholds**:
- ⚠️ Daily consumption >35% → Investigate
- 🚨 Daily consumption >40% → Emergency rollback
- ⚠️ Always-on reliability <90% → Check exemption
- 🚨 SOS response >2s → Critical bug

---

## 🏆 Battery Certification Levels

### **Level 1: Battery Basics** (All developers)
- Read full blueprint
- Understand sampling hierarchy  
- Pass 10-question quiz

### **Level 2: Battery Expert** (Sensor/battery code)
- Complete Level 1
- Study sensor_service.dart
- Run 24-hour battery test
- Shadow code review

### **Level 3: Battery Reviewer** (Can approve PRs)
- Complete Level 2
- Conduct 5 reviews
- Fix battery regression
- Design optimized feature
- Tech lead approval

---

## 🚨 Emergency Rollback

**If battery regression detected**:
```bash
# 1. Stop all deployments
# 2. Identify last stable version
git tag --list 'battery-v*'

# 3. Rollback
git checkout battery-v1.2  # Last stable tag
git checkout -b hotfix/battery-regression

# 4. Fix and re-test
# ... fix code ...
# Run 24-hour battery test

# 5. Merge when ≤32% daily confirmed
```

---

## 📞 Support & Contact

**Battery Questions**: See `BATTERY_GOVERNANCE_RULES.md` → Emergency Contact section

**General Issues**: Create GitHub issue with battery impact assessment

---

## ⚖️ License

[Your License Here]

---

## ✅ Developer Certification Statement

> "I certify that I have read and understand the Ultra Battery Optimization Blueprint governance rules. I commit to following all mandatory requirements for battery impact assessment, testing, and documentation. I understand that non-compliance may result in production issues affecting user safety and device longevity."

**Sign before committing**: ________________ [Developer Name] - [Date]

---

**Last Updated**: December 2024  
**Battery Optimization Version**: v1.2  
**Governance Framework**: v1.0  

**"Optimize for battery, prepare for always-on, never compromise on safety."**

