# RedPing Emergency System - Testing Guide

## 🧪 Test Status Overview

### ✅ Completed Components
- [x] Event Bus System (emergency_event_bus.dart)
- [x] WebRTC Token Service (agora_token_service.dart)
- [x] Native SMS Plugin (SMSPlugin.kt)
- [x] Cloud SMS Function (Firebase)
- [x] Service Integration & Event Coordination

### 📋 Functions Deployed
```
✅ generateAgoraToken     - Token generation for WebRTC calls
✅ generateAgoraTokenWithAccount - Alternative token endpoint
✅ sendSMS                - Cloud SMS via Twilio/SNS
✅ createSosSession       - Multi-region SOS creation
✅ onSosSessionCreated    - Firestore trigger
✅ onLocationPingCreated  - Location tracking trigger
```

---

## 🔧 Configuration Required

### 1. Agora Credentials (REQUIRED for WebRTC)

**Current Status:** ⚠️ NOT CONFIGURED

```bash
# Set Agora App ID and Certificate
firebase functions:config:set agora.app_id="a4d1ae536fb44710aa2c19d825f79ddb"
firebase functions:config:set agora.app_certificate="YOUR_AGORA_APP_CERTIFICATE"

# Redeploy functions
cd functions
firebase deploy --only functions:generateAgoraToken
```

**⚠️ Migration Note:** Firebase functions.config() is deprecated. Consider migrating to .env files.

---

### 2. SMS Provider (OPTIONAL - Currently Mocked)

**Option A: Twilio**
```bash
cd functions
npm install twilio

firebase functions:config:set twilio.account_sid="YOUR_ACCOUNT_SID"
firebase functions:config:set twilio.auth_token="YOUR_AUTH_TOKEN"
firebase functions:config:set twilio.phone_number="YOUR_TWILIO_NUMBER"

# Uncomment Twilio code in functions/index.js line ~190
firebase deploy --only functions:sendSMS
```

**Option B: AWS SNS**
```bash
cd functions
npm install aws-sdk

firebase functions:config:set aws.access_key_id="YOUR_KEY"
firebase functions:config:set aws.secret_access_key="YOUR_SECRET"
firebase functions:config:set aws.region="us-east-1"

# Implement SNS code in functions/index.js
firebase deploy --only functions:sendSMS
```

---

## 🧪 Test Procedures

### TEST 1: Event Bus System ✅

**Status:** Ready to test in Flutter app

**Test Steps:**
1. Open Flutter app
2. Add this to your test file or main.dart:

```dart
import 'package:redping/services/emergency_event_bus.dart';

void testEventBus() {
  final eventBus = EmergencyEventBus();
  
  // Listen to all events
  eventBus.stream.listen((event) {
    print('📡 Event: ${event.type}');
    print('   Session: ${event.sessionId}');
    print('   Message: ${event.message}');
  });
  
  // Fire test events
  eventBus.fireSOSActivated('test_123', 'manual', {});
  eventBus.fireSMSSent('test_123', EmergencyEventType.smsInitialSent, 3);
  
  // Check history
  final events = eventBus.getSessionEvents('test_123');
  print('Total events: ${events.length}');
}
```

3. Run app and trigger SOS
4. Watch console logs for event flow
5. Verify all services fire events

**Expected Output:**
```
📡 Event: sosActivated | test_123
📡 Event: smsInitialSent | test_123 | 3 contacts
📡 Event: webrtcCallStarted | test_123
📡 Event: aiMonitoringStarted | test_123
```

---

### TEST 2: WebRTC Token Generation ⚠️

**Status:** Requires Agora certificate configuration

**Test Steps:**

1. **Configure Agora credentials** (see Configuration section above)

2. **Test via curl:**
```bash
curl -X POST https://australia-southeast1-redping-a2e37.cloudfunctions.net/generateAgoraToken \
  -H "Content-Type: application/json" \
  -d '{
    "channelName": "test_emergency_channel",
    "uid": 12345,
    "role": "publisher",
    "expirationTimeInSeconds": 3600
  }'
```

**Expected Response:**
```json
{
  "token": "00674...xyz",
  "expiresAt": 1731456789,
  "channelName": "test_emergency_channel",
  "uid": 12345
}
```

3. **Test in Flutter app:**
```dart
import 'package:redping/services/agora_token_service.dart';

void testTokenGeneration() async {
  final tokenService = AgoraTokenService();
  
  final token = await tokenService.generateToken(
    channelName: 'emergency_test',
    uid: 0,
  );
  
  print('Token: ${token.substring(0, 20)}...');
  print('Length: ${token.length}');
}
```

4. Verify token caching works (second call should use cached token)

---

### TEST 3: Native SMS Sending 📱

**Status:** Ready for device testing

**Test Steps:**

1. **Build and install app on Android device:**
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

2. **Configure test emergency contacts:**
   - Open app → Settings → Emergency Contacts
   - Add TEST contacts (your own numbers)
   - Set priority and relationship

3. **Trigger test SOS:**
   - Enable TESTING mode in app settings (if available)
   - Press SOS button OR trigger fall detection
   - Grant SMS permission when prompted

4. **Verify SMS delivery:**
   - SMS should send automatically (NO SMS app opens)
   - Check test contacts receive Initial Alert
   - Verify digital card link works
   - Wait 2 min → Follow-up SMS arrives
   - Wait 4 min → Escalation SMS arrives

5. **Check logs:**
```bash
# Android logs
adb logcat | Select-String -Pattern "SMS"

# Flutter logs
flutter logs | Select-String -Pattern "SMS|Emergency"
```

**Expected Logs:**
```
✅ SMS sent automatically to +1234567890
📡 Event: smsInitialSent | session_xyz | 3 contacts
✅ SMS sent to Emergency Contact 1
✅ SMS sent to Emergency Contact 2
```

**Fallback Testing:**
- If native SMS fails → Should try cloud SMS function
- If cloud fails → Should open SMS app with pre-filled message

---

### TEST 4: Cloud SMS Function 🌐

**Status:** Ready (mock mode), configure Twilio for production

**Test via curl:**
```bash
curl -X POST https://australia-southeast1-redping-a2e37.cloudfunctions.net/sendSMS \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+1234567890",
    "message": "RedPing Test - Emergency alert system",
    "timestamp": "2025-11-13T10:30:00Z"
  }'
```

**Expected Response (Mock Mode):**
```json
{
  "success": true,
  "messageId": "mock_1731456789123",
  "provider": "mock",
  "note": "Install twilio package and configure for production"
}
```

**Production Testing (after Twilio setup):**
- Same curl command
- Should return real Twilio message ID
- Verify SMS delivered to phone

---

### TEST 5: Complete SOS Flow 🚨

**Status:** Ready for end-to-end testing

**Full Integration Test:**

#### PHASE 1: Preparation
- [ ] Firebase functions deployed and configured
- [ ] Agora credentials set (for WebRTC test)
- [ ] App installed on Android test device
- [ ] SMS permission granted
- [ ] Test emergency contacts configured
- [ ] Event bus listener active in app

#### PHASE 2: SOS Activation
1. Trigger SOS (manual button)
2. Check Firestore: `sos_sessions` collection
3. Verify event: `sosActivated`
4. UI shows active SOS status

#### PHASE 3: SMS Notifications (0-20 minutes)
1. **T+0 sec:** Initial Alert SMS sent automatically
2. **T+2 min:** Follow-up SMS #1
3. **T+4 min:** Escalation SMS #1 (critical)
4. **T+6 min:** Escalation SMS #2
5. Verify all contacts receive messages
6. Check digital card links work
7. Verify events: `smsInitialSent`, `smsFollowUpSent`, `smsEscalationSent`

#### PHASE 4: WebRTC Call (Optional)
1. SAR user accepts emergency
2. WebRTC call initiated
3. Token generated (verify in logs)
4. Channel joined successfully
5. Verify events: `webrtcCallStarted`, `webrtcTokenGenerated`, `webrtcCallConnected`

#### PHASE 5: AI Monitoring (Optional)
1. If fall/crash detection active
2. AI monitoring starts
3. Verification prompts issued
4. Responsiveness detected
5. Verify events: `aiMonitoringStarted`, `aiVerificationAttempt`

#### PHASE 6: Event Coordination
1. All services firing events
2. Check event history: `eventBus.getSessionEvents(sessionId)`
3. Verify statistics accurate
4. No duplicate events
5. Session-specific tracking working

#### PHASE 7: Resolution
1. Cancel SOS via app
2. Final cancellation SMS sent
3. All timers stopped
4. Event: `sosCancelled` or `sosResolved`
5. Firestore session marked complete

---

## 📊 Expected Test Results

### Success Criteria ✅

**Event Bus:**
- [x] All 24 event types available
- [ ] Events fire at correct moments
- [ ] Session tracking works
- [ ] History preserved correctly

**WebRTC Token:**
- [x] Token service implemented
- [ ] Token generated from Firebase
- [ ] Caching works (5-min buffer)
- [ ] Fallback to empty token for dev

**SMS Sending:**
- [x] Native Android plugin created
- [ ] SMS sends without user interaction
- [ ] 3-tier fallback works
- [ ] All 5 SMS templates send correctly
- [ ] Escalation timing accurate (2, 4, 6+ min)

**Service Coordination:**
- [x] Event bus integrated in all services
- [ ] Services react to each other's events
- [ ] No missed or duplicate events
- [ ] Real-time status updates working

---

## 🐛 Troubleshooting

### Issue: SMS Permission Denied
**Solution:** Check AndroidManifest.xml has:
```xml
<uses-permission android:name="android.permission.SEND_SMS"/>
```

### Issue: WebRTC Token Empty
**Check:**
1. Agora credentials configured?
2. Firebase function deployed?
3. Network connectivity?
**Fallback:** App works in dev mode with empty token (no encryption)

### Issue: SMS Opens SMS App Instead of Auto-Send
**Check:**
1. SMS permission granted?
2. Native plugin initialized in MainActivity?
3. Check logs for SMSPlugin errors

### Issue: Events Not Firing
**Check:**
1. Event bus singleton initialized?
2. Services have `_eventBus = EmergencyEventBus()` reference?
3. `fire()` methods being called?

### Issue: Cloud SMS Function Fails
**Check:**
1. Function deployed? `firebase functions:list`
2. CORS headers present?
3. Request body format correct?
4. Check Firebase console logs

---

## 📝 Test Report Template

After testing, document results:

```markdown
# RedPing Emergency System - Test Report
Date: YYYY-MM-DD
Tester: [Your Name]
Device: [Android Device Model]

## Test Results

### Event Bus System
- Status: PASS/FAIL
- Events fired: X/24
- Issues: [None/List]

### WebRTC Token
- Status: PASS/FAIL
- Token generated: YES/NO
- Issues: [None/List]

### Native SMS
- Status: PASS/FAIL
- Messages sent: X/Y
- Fallback used: Native/Cloud/App
- Issues: [None/List]

### Complete SOS Flow
- Status: PASS/FAIL
- Duration: X minutes
- Messages sent: Y
- Events tracked: Z
- Issues: [None/List]

## Overall Status
✅ Production Ready / ⚠️ Issues Found / ❌ Failed

## Next Steps
1. [Action item]
2. [Action item]
```

---

## 🎯 Next Steps After Testing

1. **If tests pass:**
   - Configure production Twilio/SNS
   - Set up Agora certificate
   - Deploy to production
   - Monitor real-world usage

2. **If tests fail:**
   - Document errors
   - Check logs in Firebase Console
   - Review service integration code
   - Re-test after fixes

3. **Production Checklist:**
   - [ ] Remove test mode flags
   - [ ] Configure real emergency contacts
   - [ ] Set up monitoring/alerts
   - [ ] Document emergency procedures
   - [ ] Train SAR users on system

---

**Ready to start testing!** 🚀

Choose your test:
1. Event Bus (in-app test)
2. WebRTC Token (requires Agora config)
3. Native SMS (requires Android device)
4. Complete SOS Flow (full integration)
