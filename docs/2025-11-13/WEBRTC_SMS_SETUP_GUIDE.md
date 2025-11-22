# WebRTC & SMS Integration - Setup Guide

## Overview

This guide covers the complete setup of:
1. **Agora WebRTC Token Service** - Secure token generation for emergency calls
2. **Automatic SMS Sending** - Native Android + Cloud fallback for emergency notifications

---

## 🚀 Part 1: Firebase Cloud Functions Setup

### Step 1: Navigate to Functions Directory

```powershell
cd c:\flutterapps\redping_14v\functions
```

### Step 2: Install Dependencies

```powershell
npm install
```

This installs:
- `firebase-functions` - Cloud Functions framework
- `firebase-admin` - Firebase Admin SDK
- `agora-access-token` - Agora RTC token generation

### Step 3: Configure Agora Credentials

```powershell
# Set Agora App ID and Certificate
firebase functions:config:set agora.app_id="a4d1ae536fb44710aa2c19d825f79ddb"
firebase functions:config:set agora.app_certificate="YOUR_APP_CERTIFICATE_HERE"
```

**Get Your App Certificate:**
1. Go to [Agora Console](https://console.agora.io/)
2. Navigate to Project Management
3. Find your project (App ID: a4d1ae536fb44710aa2c19d825f79ddb)
4. Enable "Primary Certificate" if not already enabled
5. Copy the certificate value

### Step 4: Deploy Functions

```powershell
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:generateAgoraToken
firebase deploy --only functions:sendSMS
```

### Step 5: Verify Deployment

After deployment, Firebase will show URLs like:
```
✔  functions[us-central1-generateAgoraToken]: Successful create operation.
Function URL: https://us-central1-redping-a2e37.cloudfunctions.net/generateAgoraToken

✔  functions[us-central1-sendSMS]: Successful create operation.
Function URL: https://us-central1-redping-a2e37.cloudfunctions.net/sendSMS
```

### Step 6: Test Functions

**Test Agora Token Generation:**
```powershell
curl -X POST https://us-central1-redping-a2e37.cloudfunctions.net/generateAgoraToken `
  -H "Content-Type: application/json" `
  -d '{"channelName":"test_channel","uid":"0","role":"publisher"}'
```

**Test SMS Function:**
```powershell
curl -X POST https://us-central1-redping-a2e37.cloudfunctions.net/sendSMS `
  -H "Content-Type: application/json" `
  -d '{"phoneNumber":"+1234567890","message":"Test emergency SMS"}'
```

---

## 📱 Part 2: Native Android SMS Setup

### Android Files Created/Modified:

1. ✅ **SMSPlugin.kt** - Native SMS sending plugin
2. ✅ **MainActivity.kt** - Plugin initialization and permission handling
3. ✅ **AndroidManifest.xml** - SEND_SMS permission (already present)

### Testing Native SMS:

1. **Build and install the app:**
```powershell
cd c:\flutterapps\redping_14v
flutter build apk --release
# Or for testing
flutter run
```

2. **Grant SMS Permission:**
   - App will request SMS permission on first use
   - Or go to: Settings > Apps > RedPing > Permissions > SMS > Allow

3. **Test from Dart code:**
```dart
// In your test file or debug screen
final smsSender = PlatformSMSSenderService();

// Check permission
final hasPermission = await smsSender.hasSMSPermission();
print('Has SMS permission: $hasPermission');

// Request if needed
if (!hasPermission) {
  await smsSender.requestSMSPermission();
}

// Send test SMS
final success = await smsSender.sendSMSNative(
  phoneNumber: '+1234567890',
  message: 'Test emergency SMS from RedPing',
);
print('SMS sent: $success');
```

---

## 🔄 Part 3: Service Integration

### Updated Services:

1. ✅ **webrtc_emergency_call_service.dart** - Now uses token service
2. ✅ **sms_service.dart** - Now uses platform SMS sender
3. ✅ **agora_token_service.dart** - NEW: Token generation client
4. ✅ **platform_sms_sender_service.dart** - NEW: SMS sending client

### SMS Sending Flow:

```
SOS Activation
    ↓
SMSService._sendSMS()
    ↓
PlatformSMSSenderService.sendSMSWithFallback()
    ↓
├── Android: Native SMS (SmsManager) ✅ Fast, free, no network needed
│   └── Success → Done
│   └── Fail → Try Cloud
│
└── Cloud: Firebase Function + Twilio/SNS ✅ Works iOS, network-based
    └── Success → Done
    └── Fail → Open SMS app (manual fallback)
```

### WebRTC Call Flow:

```
Emergency Call
    ↓
WebRTCEmergencyCallService.makeEmergencyCall()
    ↓
AgoraTokenService.generateToken()
    ↓
├── Request token from Firebase Function
│   └── Success → Use token to join channel
│   └── Fail → Use empty token (dev mode, requires App Certificate disabled)
│
└── Join Agora channel with token
    └── Speak AI emergency message
```

---

## 🧪 Part 4: Testing the Complete Flow

### Test 1: WebRTC Emergency Call

1. Open RedPing app
2. Navigate to SOS page
3. Scroll to "Test WebRTC Emergency Call" card
4. Tap "TEST CALL NOW"
5. **Expected:** Dialog shows channel name and "Token generated" message
6. **Check logs** for token generation

### Test 2: SMS Sending

1. Activate SOS (press and hold RedPing button 10 seconds)
2. **Expected:** SMS sent automatically to emergency contacts
3. **Check logs:**
   - `✅ SMS sent automatically to +1234567890`
   - Or `⚠️ Automatic SMS failed, falling back to SMS app`

### Test 3: Complete Emergency Scenario

1. **Setup:** Add yourself as emergency contact
2. **Trigger:** Activate crash detection SOS
3. **Expected sequence:**
   - SMS #1: Immediate alert (automatic)
   - AI monitoring starts
   - SMS #2: Follow-up after 2 min (automatic)
   - If unresponsive → WebRTC call with fresh token

---

## 🔐 Part 5: Production Configuration

### For WebRTC (Production):

1. **Enable App Certificate** in Agora Console
2. **Verify** Firebase Function is deployed and working
3. **Test** token generation with real credentials
4. **Monitor** Firebase Functions logs for errors

### For SMS (Production):

#### Option A: Twilio (Recommended)

```powershell
# Install Twilio in functions/
cd functions
npm install twilio

# Configure Twilio
firebase functions:config:set twilio.account_sid="YOUR_TWILIO_ACCOUNT_SID"
firebase functions:config:set twilio.auth_token="YOUR_TWILIO_AUTH_TOKEN"
firebase functions:config:set twilio.phone_number="YOUR_TWILIO_PHONE_NUMBER"

# Redeploy
firebase deploy --only functions:sendSMS
```

**Uncomment in functions/index.js:**
```javascript
// Around line 35 in sendViaTwilio function
const twilio = require('twilio');
const client = twilio(accountSid, authToken);

const twilioMessage = await client.messages.create({
  body: message,
  from: fromNumber,
  to: phoneNumber
});

console.log(`Twilio SMS sent: ${twilioMessage.sid}`);
return { success: true, messageId: twilioMessage.sid };
```

#### Option B: AWS SNS (Alternative)

```powershell
# Install AWS SDK
npm install aws-sdk

# Configure AWS
firebase functions:config:set aws.region="us-east-1"
firebase functions:config:set aws.access_key_id="YOUR_AWS_KEY"
firebase functions:config:set aws.secret_access_key="YOUR_AWS_SECRET"
```

---

## 📊 Monitoring & Debugging

### Firebase Functions Logs:

```powershell
# View real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only generateAgoraToken
firebase functions:log --only sendSMS
```

### Android Logs:

```powershell
# View all logs
flutter logs

# Filter SMS
flutter logs | Select-String "SMS"

# Filter WebRTC
flutter logs | Select-String "WebRTC"
```

### Common Issues:

**1. Token Generation Fails:**
- Check Agora App ID and Certificate are correct
- Verify Firebase Function is deployed
- Check Firebase Functions logs for errors
- Test with curl command

**2. SMS Not Sending:**
- Check SEND_SMS permission granted
- Verify phone number format (+1234567890)
- Check Android logs for SMSPlugin errors
- Test cloud fallback separately

**3. WebRTC Call Fails:**
- Check token is generated (not empty)
- Verify Agora App Certificate status
- Check microphone permission
- Test with different channel names

---

## 🎯 Cost Estimates

### Agora WebRTC:
- **Free Tier:** 10,000 minutes/month
- **Paid:** $0.99 per 1,000 minutes
- **Emergency Usage:** ~3 min/call = ~3,000 calls free/month

### Firebase Functions:
- **Free Tier:** 2M invocations/month, 400K GB-sec
- **Paid:** $0.40 per million invocations
- **Emergency Usage:** Essentially free for RedPing scale

### Twilio SMS:
- **Cost:** ~$0.0075 per SMS (US)
- **Emergency Usage:** 5 SMS/emergency × 100 emergencies = $3.75/month

**Total Monthly Cost (100 emergencies):** < $5

---

## ✅ Checklist

- [ ] Firebase Functions deployed
- [ ] Agora credentials configured
- [ ] Token generation tested
- [ ] SMS permission granted on test device
- [ ] Native SMS tested
- [ ] Cloud SMS function tested (mock mode works)
- [ ] WebRTC call with token tested
- [ ] Complete emergency flow tested
- [ ] Production SMS provider configured (Twilio/SNS)
- [ ] Monitoring setup (Firebase Console)

---

## 📚 Additional Resources

- [Agora RTC Documentation](https://docs.agora.io/en/)
- [Firebase Functions Guide](https://firebase.google.com/docs/functions)
- [Twilio SMS API](https://www.twilio.com/docs/sms)
- [Android SmsManager](https://developer.android.com/reference/android/telephony/SmsManager)

---

## 🆘 Support

If you encounter issues:
1. Check logs (Firebase + Android)
2. Verify all credentials are correct
3. Test each component separately
4. Review this guide step-by-step

For RedPing-specific issues, check the project documentation in `/docs` folder.
