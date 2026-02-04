# Crash Investigation Report: Coroutine Cancellation & App Kill

**Date:** November 30, 2025  
**Error:** `DiagnosticCoroutineContextException: [StandaloneCoroutine{Cancelling}@ca12e70, Dispatchers.IO]`  
**Result:** `I/Process (2036): Sending signal. PID: 2036 SIG: 9` → **App Killed**

---

## 🔴 ROOT CAUSE IDENTIFIED

### Primary Issue: Double Hive Initialization
**Location 1:** `lib/main.dart` line ~195
```dart
await Hive.initFlutter();
debugPrint('Hive initialized for encrypted local storage');
```

**Location 2:** `lib/services/messaging/dtn_storage_service.dart` line 30
```dart
await Hive.initFlutter();
// Open boxes
_outboxBox = await Hive.openBox<Map>(_outboxBoxName);
```

**Problem:** Hive throws exception when `initFlutter()` is called twice, causing:
1. DTN storage initialization fails
2. MessagingInitializer crashes during startup
3. Coroutines in SatellitePlugin get cancelled
4. App receives SIGKILL from Android

### Secondary Issue: Coroutine Scope Management
**Location:** `android/app/src/main/kotlin/com/redping/redping/SatellitePlugin.kt` line 31
```kotlin
private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
```

**Problem:** When app crashes, the coroutine scope is cancelled but:
- The `dispose()` method may not be called properly
- Background status updates continue running
- Leads to "StandaloneCoroutine{Cancelling}" error

---

## 🔍 Error Chain Analysis

```
1. App starts → main.dart initializes Hive ✅
                ↓
2. MessagingInitializer.initialize() called
                ↓
3. DTNStorageService.initialize() → Hive.initFlutter() AGAIN ❌
                ↓
4. Exception: "Hive is already initialized"
                ↓
5. MessagingInitializer crashes with "Failed to initialize DTN storage"
                ↓
6. Unhandled exception propagates up
                ↓
7. SatellitePlugin coroutines try to continue
                ↓
8. DiagnosticCoroutineContextException thrown
                ↓
9. Android sends SIGKILL → App terminated
```

---

## 🛠️ FIXES REQUIRED

### Fix #1: Remove Double Hive Initialization ✅ CRITICAL

**File:** `lib/services/messaging/dtn_storage_service.dart`

**Change:**
```dart
// BEFORE (WRONG)
Future<void> initialize() async {
  if (_initialized) return;
  
  try {
    await Hive.initFlutter(); // ❌ REMOVE THIS - Already done in main.dart
    
    // Open boxes
    _outboxBox = await Hive.openBox<Map>(_outboxBoxName);
    ...
  }
}

// AFTER (CORRECT)
Future<void> initialize() async {
  if (_initialized) return;
  
  try {
    // Hive.initFlutter() is already called in main.dart
    // Just open the boxes
    _outboxBox = await Hive.openBox<Map>(_outboxBoxName);
    _conversationBox = await Hive.openBox<Map>(_conversationBoxName);
    _processedIdsBox = await Hive.openBox<int>(_processedIdsBoxName);
    
    _initialized = true;
    debugPrint('✅ DTN Storage initialized');
    ...
  } catch (e) {
    debugPrint('❌ Failed to initialize DTN storage: $e');
    rethrow;
  }
}
```

### Fix #2: Add Proper Error Handling ✅ HIGH PRIORITY

**File:** `lib/services/messaging_initializer.dart`

**Change:**
```dart
Future<void> initialize() async {
  if (_initialized) {
    debugPrint('⚠️ Messaging system already initialized');
    return;
  }

  try {
    debugPrint('🚀 Initializing Messaging v2 System (Phase 2)...');

    // Initialize components with individual error handling
    try {
      await _storage.initialize();
    } catch (e) {
      debugPrint('❌ DTN storage failed to initialize: $e');
      debugPrint('⚠️ Continuing without offline storage...');
      // Continue - some features will be limited but app won't crash
    }

    final deviceId = await _getDeviceId();
    debugPrint('📱 Device ID: $deviceId');
    
    // ... rest of initialization
  } catch (e) {
    debugPrint('❌ Failed to initialize messaging system: $e');
    // DON'T rethrow - gracefully degrade instead
    _initialized = false; // Mark as not initialized
  }
}
```

### Fix #3: Improve SatellitePlugin Lifecycle Management ✅ MEDIUM

**File:** `android/app/src/main/kotlin/com/redping/redping/SatellitePlugin.kt`

**Add cleanup on plugin detach:**
```kotlin
class SatellitePlugin(private val context: Context) : 
    MethodChannel.MethodCallHandler,
    FlutterPlugin {
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // ... existing code ...
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        dispose()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        statusChannel?.setStreamHandler(null)
        statusChannel = null
    }
    
    fun dispose() {
        try {
            scope.cancel("Plugin disposed")
            statusSink?.endOfStream()
            statusSink = null
        } catch (e: Exception) {
            // Silently handle cancellation errors
        }
    }
}
```

### Fix #4: Add Crash Guard in Main ✅ RECOMMENDED

**File:** `lib/main.dart`

**Wrap service initialization:**
```dart
// Defer heavy initialization to background after UI is ready
Future.microtask(() async {
  if (TestOverrides.isTest) {
    return;
  }
  
  try {
    // Initialize notification scheduler
    await NotificationScheduler.instance.initialize();
    debugPrint('NotificationScheduler initialized successfully');
  } catch (e) {
    debugPrint('NotificationScheduler initialization failed: $e');
    // Continue - not critical
  }

  // Initialize app services with error isolation
  final serviceManager = AppServiceManager();
  try {
    await serviceManager.initializeAllServices().timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint('Service initialization timed out - continuing with limited functionality');
      },
    );
  } catch (e) {
    debugPrint('Service initialization failed: $e');
    // App continues but with limited functionality
    // Show user a warning if critical services failed
  }
});
```

---

## 📋 Testing Checklist

### Before Fix:
- [ ] App crashes with "DiagnosticCoroutineContextException"
- [ ] "Failed to initialize DTN storage" in logs
- [ ] Process killed with SIGKILL
- [ ] Messaging features don't work

### After Fix:
- [ ] App starts successfully
- [ ] DTN storage initializes without errors
- [ ] Messaging system works correctly
- [ ] SatellitePlugin coroutines run smoothly
- [ ] App handles service failures gracefully

---

## 🔬 How to Verify Fix

### Step 1: Check Logs
Look for these success messages:
```
✅ Hive initialized for encrypted local storage
✅ DTN Storage initialized
✅ Messaging v2 System (Phase 2) initialized successfully
```

### Step 2: Test Messaging
```dart
// Send test message
final messaging = MessagingInitializer();
await messaging.initialize();
await messaging.sendTestMessage(content: 'Test after fix');
```

### Step 3: Monitor for Crashes
- Run app for 5+ minutes
- Navigate between screens
- Send multiple messages
- Check logcat for coroutine errors

---

## 📊 Impact Analysis

### Without Fix:
- ❌ App crashes on startup
- ❌ Messaging system unavailable
- ❌ User experience broken
- ❌ Data loss possible

### With Fix:
- ✅ App starts reliably
- ✅ Messaging works correctly
- ✅ Graceful degradation if services fail
- ✅ Better error messages for debugging

---

## 🎯 Priority Level: **CRITICAL**

This is a **startup crash** that makes the app unusable. Must be fixed before any release.

**Estimated Fix Time:** 15 minutes  
**Testing Time:** 10 minutes  
**Total:** ~25 minutes

---

## 📝 Additional Notes

### Why Double Init Happens
1. `main.dart` initializes Hive early for general storage
2. `DTNStorageService` tries to initialize again for messaging
3. Hive doesn't allow re-initialization
4. Exception causes cascade failure

### Prevention
- Add a static flag `_hiveInitialized` to track global state
- OR remove all Hive.initFlutter() calls except one in main.dart
- OR check `Hive.isInitialized` before calling initFlutter()

### Related Issues
- MessagingInitializer test failures (same root cause)
- path_provider plugin errors in tests
- All stem from initialization order problems

---

## ✅ Implementation Order

1. **FIRST:** Fix DTNStorageService (remove double init) ← **DO THIS NOW**
2. **SECOND:** Add error handling in MessagingInitializer
3. **THIRD:** Improve SatellitePlugin lifecycle
4. **FOURTH:** Test thoroughly
5. **FIFTH:** Monitor in production

**Status:** Ready to implement
