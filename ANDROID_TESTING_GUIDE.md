# Android Testing Guide

**Date:** November 25, 2025  
**APK Location:** `build/app/outputs/flutter-apk/app-release.apk`  
**APK Size:** 94.8 MB  
**Test Device:** Pixel 7 Pro (Android 16, API 36)

## Build Information

### Release APK Built Successfully ✅
```
Font optimization: 99.7% reduction (CupertinoIcons)
Font optimization: 97.0% reduction (MaterialIcons)
Build time: 377.6s (~6 minutes)
Output: app-release.apk (94.8MB)
```

### Configuration
- **Bundle ID:** `com.redping.redping`
- **Version:** 1.0.1+2
- **Target SDK:** API 36 (Android 14)
- **Min SDK:** API 24 (Android 7.0)
- **ABI:** arm64-v8a only (optimized)

## Installation

### Install on Connected Device
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or via Flutter
flutter install --release

# Or manually
# 1. Copy APK to device: adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/
# 2. Open Files app on device
# 3. Navigate to Downloads
# 4. Tap app-release.apk
# 5. Allow installation from unknown sources if prompted
```

## Testing Checklist

### 1. First Launch & Authentication ⏳
- [ ] App launches without crashes
- [ ] Splash screen displays correctly
- [ ] App name shows as "REDP!NG Safety"
- [ ] Google Sign-In works
- [ ] Login bypass works (for development)
- [ ] Profile creation completes
- [ ] Firebase Authentication connected

### 2. Permissions Request ⏳
- [ ] Location permission requested
- [ ] Location permission "Always Allow" option available
- [ ] Motion/Activity permission requested
- [ ] Camera permission requested (when needed)
- [ ] Notifications permission requested
- [ ] Phone permission requested (for calls)
- [ ] Contacts permission requested
- [ ] All permissions display proper rationale

### 3. Core Emergency Features ⏳

#### SOS Alert System
- [ ] SOS button accessible from main screen
- [ ] SOS button triggers emergency alert
- [ ] Location sent with SOS alert
- [ ] SMS sent to emergency contacts
- [ ] Firebase Cloud Function triggered
- [ ] Real-time updates work
- [ ] Audio recording starts (if configured)
- [ ] Emergency contacts notified

#### Crash Detection
- [ ] Accelerometer data being collected
- [ ] Simulated crash triggers alert
- [ ] 60-second countdown starts
- [ ] Cancel option available
- [ ] Automatic alert sent after countdown
- [ ] Location tracked during incident
- [ ] Battery level monitored

#### Check-In System
- [ ] Check-in requests appear
- [ ] Can respond to check-ins
- [ ] Expiration timer works
- [ ] Notifications for check-in requests
- [ ] Status updates in real-time

### 4. Location Services ⏳
- [ ] Current location detected
- [ ] Location updates in background
- [ ] Location accuracy sufficient (<50m)
- [ ] Battery optimization not killing location
- [ ] Location persists after app restart
- [ ] Works in low-signal areas

### 5. Subscription System (Stripe) ⏳

#### Free Tier
- [ ] Basic features available
- [ ] Premium features locked
- [ ] Upgrade prompts display

#### Essential+ ($4.99/month)
- [ ] Checkout screen loads
- [ ] Test card accepted: 4242 4242 4242 4242
- [ ] Payment processing works
- [ ] Webhook received
- [ ] Subscription status updated in Firestore
- [ ] Premium features unlocked
- [ ] Weather alerts enabled
- [ ] Extended history access

#### Pro ($9.99/month)
- [ ] Upgrade option available
- [ ] All Essential+ features plus advanced
- [ ] Video calls enabled
- [ ] Priority support badge

#### Payment Testing
- [ ] Stripe SDK initialized
- [ ] Payment sheet displays correctly
- [ ] Test mode indicator visible
- [ ] Success callback triggers
- [ ] Failure handling works
- [ ] Receipt displayed

### 6. Hazard Alert System ⏳
(Requires Essential+ subscription)
- [ ] Weather alerts appear
- [ ] Geolocation-based alerts
- [ ] Notification for severe weather
- [ ] Alert history accessible
- [ ] Alert details display correctly
- [ ] Exponential backoff working (check logs)

### 7. AI Assistant ⏳
- [ ] Voice commands work
- [ ] Speech recognition functional
- [ ] AI responses generated
- [ ] Emergency triggers via voice
- [ ] Hands-free mode works

### 8. Family/Group Features ⏳
- [ ] Create family group
- [ ] Invite members
- [ ] Accept invitations
- [ ] View family member locations
- [ ] Receive family member alerts
- [ ] Leave family group

### 9. Profile & Settings ⏳
- [ ] Profile picture upload
- [ ] Emergency contact management
- [ ] Add/edit/delete contacts
- [ ] Notification settings
- [ ] Privacy settings
- [ ] Account deletion option

### 10. Performance & Stability ⏳
- [ ] No memory leaks (run for 30+ min)
- [ ] Battery drain acceptable (<5%/hour)
- [ ] No ANR (Application Not Responding)
- [ ] Smooth animations (60fps)
- [ ] Quick app startup (<3 seconds)
- [ ] Background services stable

### 11. Network Scenarios ⏳
- [ ] Works on WiFi
- [ ] Works on 4G/5G
- [ ] Handles network loss gracefully
- [ ] Offline mode functional
- [ ] Auto-reconnect works
- [ ] Cached data accessible offline

### 12. Edge Cases ⏳
- [ ] App survives low memory
- [ ] Works during phone calls
- [ ] Battery saver mode compatible
- [ ] Data saver mode compatible
- [ ] Airplane mode handling
- [ ] Do Not Disturb handling
- [ ] Multiple rapid SOS presses
- [ ] Expired subscriptions handled

## Test Scenarios

### Scenario 1: Emergency SOS Flow
1. Launch app
2. Tap SOS button
3. Confirm emergency
4. Verify location sent
5. Check Firestore for session
6. Verify Cloud Function triggered
7. Check emergency contact notifications
8. Resolve alert

### Scenario 2: Subscription Purchase
1. Go to Settings → Subscription
2. Tap "Upgrade to Essential+"
3. Enter test card: 4242 4242 4242 4242
4. Complete purchase
5. Check Stripe Dashboard for payment
6. Verify webhook received
7. Confirm subscription in Firestore
8. Verify premium features unlocked

### Scenario 3: Crash Detection
1. Enable crash detection in settings
2. Simulate crash (rapid shake or test button)
3. Observe 60-second countdown
4. Wait for automatic alert
5. Verify location captured
6. Check Firestore for incident record
7. Verify notifications sent

### Scenario 4: Background Location
1. Start location tracking
2. Lock phone
3. Walk around for 5-10 minutes
4. Unlock phone
5. Check location history
6. Verify continuous tracking
7. Check battery impact

### Scenario 5: Family Group
1. Create family group
2. Generate invite code
3. Share with test account
4. Accept on second device
5. Verify real-time location sharing
6. Trigger SOS from one device
7. Verify alert received on other device

## Known Issues to Verify

### Firebase Configuration
- [x] Cloud Functions migrated to .env
- [x] All functions.config() removed
- [x] Stripe keys configured
- [x] Agora credentials set
- [x] Twilio configured

### Android-Specific
- [ ] Verify battery optimization disabled
- [ ] Check notification channels created
- [ ] Confirm foreground service running
- [ ] Verify wake locks working
- [ ] Check power management exceptions

## Performance Benchmarks

### Target Metrics
- **App Startup:** <3 seconds (cold start)
- **SOS Trigger:** <1 second response
- **Location Update:** <5 seconds
- **Payment Flow:** <10 seconds
- **Battery Drain:** <5% per hour (background)
- **Memory Usage:** <150MB average
- **APK Size:** <100MB

### Actual Results
- **App Startup:** TBD
- **SOS Trigger:** TBD
- **Location Update:** TBD
- **Payment Flow:** TBD
- **Battery Drain:** TBD
- **Memory Usage:** TBD
- **APK Size:** 94.8MB ✅

## Test Commands

### Check Logcat for Errors
```bash
adb logcat -s flutter
adb logcat | grep -i "redping\|error\|exception"
```

### Monitor Performance
```bash
# CPU and Memory
adb shell dumpsys meminfo com.redping.redping

# Battery stats
adb shell dumpsys batterystats com.redping.redping

# Network usage
adb shell dumpsys package com.redping.redping | grep -i network
```

### Test Notifications
```bash
# Send test notification
adb shell am broadcast -a com.redping.redping.TEST_NOTIFICATION
```

### Force Stop App
```bash
adb shell am force-stop com.redping.redping
```

### Clear App Data
```bash
adb shell pm clear com.redping.redping
```

## Stripe Test Cards

### Successful Payments
- **Generic:** 4242 4242 4242 4242
- **Visa:** 4000 0566 5566 5556
- **Mastercard:** 5555 5555 5555 4444
- **Amex:** 3782 822463 10005

### Failed Payments (Test Error Handling)
- **Declined:** 4000 0000 0000 0002
- **Insufficient Funds:** 4000 0000 0000 9995
- **Expired Card:** 4000 0000 0000 0069
- **Processing Error:** 4000 0000 0000 0119

### 3D Secure (SCA Testing)
- **Auth Required:** 4000 0025 0000 3155
- **Auth Optional:** 4000 0027 6000 3184

## Test Data

### Test Emergency Contacts
```
Contact 1: Test User (+1 555-0100)
Contact 2: Emergency Contact (+1 555-0101)
Contact 3: Family Member (+1 555-0102)
```

### Test Locations
```
Sydney, Australia: -33.8688, 151.2093
New York, USA: 40.7128, -74.0060
London, UK: 51.5074, -0.1278
```

## Firebase Verification

### Check Firestore Data
1. Go to https://console.firebase.google.com
2. Select project: redping-a2e37
3. Navigate to Firestore Database
4. Check collections:
   - `users` - User profiles
   - `sos_sessions` - Emergency alerts
   - `subscriptions` - Stripe subscriptions
   - `check_ins` - Check-in requests
   - `family_groups` - Family/group data

### Check Cloud Functions Logs
1. Go to Functions section
2. Click on function name
3. View logs for errors
4. Verify successful executions

### Monitor Analytics
1. Go to Analytics section
2. Check active users
3. View events (sos_triggered, subscription_created)
4. Monitor crashes

## Issue Reporting Template

```markdown
### Issue Title
[Brief description]

### Device Information
- Device: Pixel 7 Pro
- Android Version: 16 (API 36)
- App Version: 1.0.1+2

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### Logs
[Paste relevant logcat output]

### Screenshots
[If applicable]

### Severity
[ ] Critical (App crash/data loss)
[ ] High (Feature broken)
[ ] Medium (Degraded UX)
[ ] Low (Minor issue)
```

## Test Completion

### Sign-off Criteria
All test sections must have:
- [ ] 80%+ tests passing
- [ ] No critical bugs
- [ ] No data loss scenarios
- [ ] Acceptable performance metrics
- [ ] All security features working
- [ ] Subscription flow functional
- [ ] Emergency features reliable

### Final Approval
- [ ] QA Lead: _________________
- [ ] Product Manager: _________________
- [ ] Technical Lead: _________________
- [ ] Date: _________________

---

**Next Steps:**
1. Complete all testing sections
2. Document any issues found
3. Create bug tickets for failures
4. Retest after fixes
5. Prepare for Play Store submission
