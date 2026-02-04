# 🧪 Testing Crash Fix - Quick Guide

**Issue Fixed:** DiagnosticCoroutineContextException + SIGKILL crash  
**Fix:** Removed duplicate Hive.initFlutter() from DTNStorageService  

---

## ⚡ Quick Test (30 seconds)

```powershell
# 1. Wait for build (running now)
flutter build apk --debug

# 2. Install
flutter install

# 3. Watch logs (should see success messages)
adb logcat | Select-String "Hive|DTN|Messaging|FATAL"
```

---

## ✅ What Success Looks Like

### Good Logs (No Crash)
```
✅ Hive initialized for encrypted local storage
✅ DTN Storage initialized (boxes opened)
✅ Messaging v2 System (Phase 2) initialized successfully
```

### Bad Logs (Still Crashing)
```
❌ Failed to initialize DTN storage
DiagnosticCoroutineContextException
I/Process: Sending signal. PID: XXX SIG: 9
```

---

## 🔍 Detailed Test Plan

### Test 1: App Startup (CRITICAL)
**What:** Launch app  
**Expected:** No crash, no SIGKILL  
**Time:** 10 seconds  

```powershell
flutter run --debug
# App should reach home screen
```

### Test 2: Messaging Initialization
**What:** Check messaging system starts  
**Expected:** See "Messaging v2 System initialized" in logs  
**Time:** 5 seconds  

### Test 3: Send Message
**What:** Send a test message  
**Expected:** Message queued in DTN storage  
**Time:** 30 seconds  

```dart
// In app, try sending a message
// Should see: "Message queued for offline delivery"
```

### Test 4: Storage Operations
**What:** Check Hive boxes working  
**Expected:** Can read/write to storage  
**Time:** 1 minute  

### Test 5: Extended Run
**What:** Let app run for 5+ minutes  
**Expected:** No crashes, no coroutine errors  
**Time:** 5 minutes  

---

## 🐛 If It Still Crashes

### Check 1: Verify Fix Applied
```powershell
# Check the file was actually modified
Select-String -Path "lib\services\messaging\dtn_storage_service.dart" -Pattern "Hive.initFlutter"
# Should find NO matches (we removed it)
```

### Check 2: Clean Build
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

### Check 3: Check All Hive Calls
```powershell
# Find all Hive.initFlutter calls
Select-String -Path "lib\**\*.dart" -Pattern "Hive\.initFlutter" -Recurse
# Should only see main.dart
```

### Check 4: Look for Other Issues
```powershell
adb logcat | Select-String "Exception|Error|FATAL"
# Check what's actually failing
```

---

## 📊 Success Metrics

| Metric | Target | How to Check |
|--------|--------|--------------|
| **Crash Rate** | 0% | App launches and stays running |
| **Init Success** | 100% | See ✅ messages in logs |
| **Messaging Works** | Yes | Can send/queue messages |
| **No Coroutine Errors** | Yes | No "Cancelling" in logs |
| **Stable Runtime** | 5+ min | No crashes during use |

---

## 🎯 One-Line Test

```powershell
flutter run --debug; adb logcat | Select-String "DTN Storage initialized"
```
**If you see:** `✅ DTN Storage initialized (boxes opened)` → **FIX WORKS! 🎉**

---

## 📝 Test Results

### Device Info
- **Device:** _____________
- **Android Version:** _____________
- **Build:** Debug APK

### Test Run 1
- **Date/Time:** _____________
- **Result:** ☐ PASS ☐ FAIL
- **Notes:** _____________________________________________

### Test Run 2 (Extended)
- **Duration:** _____ minutes
- **Result:** ☐ PASS ☐ FAIL
- **Crashes:** _____ times
- **Notes:** _____________________________________________

---

## 💡 Quick Diagnosis

**Symptom** → **Likely Cause** → **Solution**

1. **Still crashes with same error**  
   → Fix not applied correctly  
   → Re-check dtn_storage_service.dart

2. **Different error now**  
   → Uncovered new issue  
   → Check new error logs

3. **App works but messages fail**  
   → Messaging config issue  
   → Check MessagingInitializer logs

4. **Intermittent crashes**  
   → Race condition  
   → Add initialization locks

5. **Crash on specific action**  
   → Feature-specific bug  
   → Test that feature in isolation

---

## 🚀 Ready to Test?

**Current Status:**
- ✅ Fix applied to code
- 🔄 Build in progress
- ⏳ Waiting for APK
- ⏳ Testing pending

**Next Step:** Wait for build to complete, then run quick test! 🎯
