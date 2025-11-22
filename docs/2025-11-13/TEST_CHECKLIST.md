# RedPing Emergency System - Test Checklist

## 📋 Pre-Test Setup

### ✅ Completed
- [x] Event Bus System implemented
- [x] WebRTC Token Service created
- [x] Native SMS Plugin (Android) created
- [x] Cloud SMS Function deployed
- [x] Service integration complete
- [x] Test scripts created

### ⚠️ Required Before Testing
- [ ] Build APK complete
- [ ] Install on Pixel 7 Pro
- [ ] Grant SMS permission
- [ ] Configure test emergency contacts

---

## 🧪 Test Sequence

### TEST 1: Event Bus Verification (In-App) ⭐ START HERE

**Objective:** Verify event bus fires and tracks events correctly

**Steps:**
1. Open app on Pixel 7 Pro
2. Check logs for event bus initialization
3. Trigger manual SOS
4. Watch for event logs:
   ```
   📡 Event: sosActivated | session_xyz
   📡 Event: smsInitialSent | session_xyz
   ```

**Success Criteria:**
- [x] Event bus initializes without errors
- [ ] sosActivated event fires on SOS trigger
- [ ] Events include correct sessionId
- [ ] Event history preserved

**Commands:**
```powershell
# Monitor events in real-time
adb logcat | Select-String "Event|📡"
```

---

### TEST 2: Native SMS Sending ⭐ PRIORITY

**Objective:** Verify SMS sends automatically without opening SMS app

**Setup:**
1. Add YOUR phone number as emergency contact
2. Ensure SMS permission granted
3. Have second phone ready to receive

**Steps:**
1. Open RedPing app
2. Go to Emergency Contacts
3. Add test contact: Your phone number
4. Trigger manual SOS button
5. **DO NOT CANCEL SOS YET**
6. Check your phone for SMS within 10 seconds

**Expected Behavior:**
- ✅ SMS arrives automatically (NO SMS app opens on Pixel)
- ✅ Message contains emergency details
- ✅ Digital card link included
- ✅ Follow-up SMS arrives after 2 minutes
- ✅ Escalation SMS arrives after 4 minutes

**Log Patterns to Watch:**
```
✅ SMS sent automatically to +...
📡 Event: smsInitialSent | 1 contacts
Native SMS sent successfully
```

**If SMS App Opens:** Native SMS failed, check:
- SMS permission granted?
- SMSPlugin initialized in MainActivity?
- Android version (should work on Android 6+)

---

### TEST 3: SMS Escalation Timing

**Objective:** Verify SMS escalation follows correct schedule

**Timeline:**
```
T+0:00  → Initial Alert SMS
T+2:00  → Follow-up SMS #1
T+4:00  → Escalation SMS #1 (Critical)
T+6:00  → Escalation SMS #2
T+8:00  → Escalation SMS #3
```

**Steps:**
1. Trigger SOS
2. Note exact start time
3. Keep app running (don't cancel)
4. Count SMS received over 10 minutes
5. Verify timing matches schedule

**Success Criteria:**
- [ ] Exactly 1 SMS at T+0
- [ ] Exactly 1 SMS at T+2
- [ ] Exactly 1 SMS at T+4
- [ ] Messages escalate in urgency
- [ ] All SMS arrive within ±30 seconds of schedule

---

### TEST 4: WebRTC Token Generation

**Objective:** Test Agora token generation from Firebase

**⚠️ PREREQUISITE:** Configure Agora credentials first!

```powershell
# Set credentials
firebase functions:config:set agora.app_id="a4d1ae536fb44710aa2c19d825f79ddb"
firebase functions:config:set agora.app_certificate="YOUR_CERT_HERE"

# Redeploy
cd functions
firebase deploy --only functions:generateAgoraToken
```

**Test via curl:**
```powershell
$body = @{
    channelName = "test_emergency"
    uid = 12345
    role = "publisher"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "https://australia-southeast1-redping-a2e37.cloudfunctions.net/generateAgoraToken" -Body $body -ContentType "application/json"
```

**Expected Response:**
```json
{
  "token": "00674d1ae536fb447...",
  "expiresAt": 1731456789,
  "channelName": "test_emergency",
  "uid": 12345
}
```

**Test in App:**
1. Trigger SOS with SAR response
2. Initiate WebRTC call
3. Check logs for token generation
4. Verify call connects

---

### TEST 5: Cloud SMS Fallback

**Objective:** Test Firebase SMS function

**Test Mock Mode:**
```powershell
$body = @{
    phoneNumber = "+1234567890"
    message = "RedPing Test SMS"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "https://australia-southeast1-redping-a2e37.cloudfunctions.net/sendSMS" -Body $body -ContentType "application/json"
```

**Expected Response (Mock):**
```json
{
  "success": true,
  "messageId": "mock_1731456789",
  "provider": "mock",
  "note": "Install twilio package and configure for production"
}
```

**For Production:** Configure Twilio and test real delivery

---

### TEST 6: Service Coordination

**Objective:** Verify all services fire events and coordinate

**Event Flow to Verify:**

**SOS Activation:**
```
1. sosActivated (SOS Service)
2. smsInitialSent (SMS Service)
3. aiMonitoringStarted (AI Service - if fall/crash)
```

**SAR Response:**
```
4. sarTeamAssigned (SAR Service)
5. webrtcCallStarted (WebRTC Service)
6. webrtcTokenGenerated (Token Service)
7. webrtcCallConnected (WebRTC Service)
```

**Follow-ups:**
```
8. smsFollowUpSent (SMS Service, T+2min)
9. aiVerificationAttempt (AI Service)
10. smsEscalationSent (SMS Service, T+4min)
```

**Resolution:**
```
11. sosResolved or sosCancelled
12. All timers stopped
13. Final SMS sent
```

**Test Steps:**
1. Add event logging to app (if not already present)
2. Trigger complete SOS flow
3. Monitor event sequence
4. Verify all events fire in order
5. Check no events duplicated or missed

---

### TEST 7: Complete E2E Flow ⭐ FINAL TEST

**Objective:** Full emergency simulation

**Scenario:** Simulated fall detection

1. **Setup Phase** (T-5 min)
   - Configure 2-3 test emergency contacts
   - Enable location services
   - Ensure network connectivity
   - Start log capture

2. **Emergency Phase** (T+0)
   - Trigger SOS (manual or test fall)
   - Verify SOS session created in Firestore
   - Check Initial Alert SMS sent immediately

3. **Active Monitoring** (T+0 to T+10)
   - Verify Follow-up SMS at T+2
   - Verify Escalation SMS at T+4
   - Monitor event bus for all service events
   - Check digital card links work

4. **SAR Response** (T+5) [Optional]
   - Have test SAR user accept emergency
   - Verify WebRTC call initiated
   - Check token generated
   - Test audio/video connection

5. **Resolution** (T+10)
   - Cancel SOS via app
   - Verify cancellation SMS sent
   - Confirm all timers stopped
   - Check Firestore session marked resolved

**Success Criteria:**
- [ ] All SMS sent automatically (5+ messages)
- [ ] Event bus tracked 10+ events
- [ ] WebRTC call connected (if tested)
- [ ] No crashes or errors
- [ ] All services coordinated correctly

---

## 📊 Test Results Template

```markdown
# Test Results - [Date]

## Device Info
- Device: Pixel 7 Pro
- Android: 16 (API 36)
- App Version: [version]

## Test 1: Event Bus
Status: PASS / FAIL
Notes: [observations]

## Test 2: Native SMS
Status: PASS / FAIL
SMS Received: X/Y
Timing: Accurate / Delayed
Notes: [observations]

## Test 3: SMS Escalation
Status: PASS / FAIL
Schedule Accuracy: ±X seconds
Notes: [observations]

## Test 4: WebRTC Token
Status: PASS / FAIL / SKIPPED
Token Generated: YES / NO
Notes: [observations]

## Test 5: Cloud SMS
Status: PASS / FAIL
Provider: Mock / Twilio / SNS
Notes: [observations]

## Test 6: Service Coordination
Status: PASS / FAIL
Events Tracked: X events
Coordination: Working / Issues
Notes: [observations]

## Test 7: Complete E2E
Status: PASS / FAIL
Duration: X minutes
SMS Count: Y
Events Count: Z
Issues: [list]

## Overall Assessment
✅ Production Ready
⚠️ Minor Issues
❌ Major Issues

## Issues Found
1. [Issue description]
2. [Issue description]

## Recommendations
1. [Recommendation]
2. [Recommendation]
```

---

## 🚀 Quick Start Command

**Run automated test:**
```powershell
.\test_on_device.ps1
```

This will:
1. ✅ Check device connection
2. ✅ Build APK
3. ✅ Install on device
4. ✅ Grant SMS permission
5. ✅ Start log monitoring

Then manually:
6. Open app → Add contacts → Trigger SOS
7. Watch logs for SMS and events
8. Verify SMS delivery on test phones

---

## 📞 Emergency Contacts for Testing

**Use Your Own Numbers:**
```
Contact 1 (Primary): YOUR_PHONE
Contact 2 (Secondary): FRIEND/FAMILY
Contact 3 (Tertiary): ANOTHER_DEVICE
```

**⚠️ Important:** Inform contacts they'll receive test emergency alerts!

---

## 🔍 Key Log Patterns

**Success Indicators:**
```
✅ SMS sent automatically to +...
📡 Event: sosActivated
📡 Event: smsInitialSent
🔑 Token generated successfully
✅ WebRTC call connected
✅ SOS resolved
```

**Failure Indicators:**
```
❌ Failed to send SMS
⚠️ SMS permission denied
❌ Token generation failed
❌ WebRTC call failed
⚠️ Event not fired
```

---

## ⏱️ Estimated Testing Time

- Setup: 10 minutes
- Test 1-2: 15 minutes
- Test 3: 10 minutes
- Test 4-5: 10 minutes
- Test 6-7: 20 minutes

**Total: ~60 minutes for complete testing**

---

**Ready? Run: `.\test_on_device.ps1`** 🚀
