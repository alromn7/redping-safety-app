# 🤖 AI Voice Call Integration

## Overview
RedPing now integrates with your phone's native AI assistant (Google Assistant/Siri) to make intelligent voice calls during emergencies when you're unresponsive.

## How It Works

### 1. **Detection & Monitoring**
- Crash/fall detected → AI verification dialog shows
- If you don't respond after 3 attempts (~1 minute)
- AI continues monitoring for up to 5 minutes

### 2. **AI Voice Call Trigger**
When the AI decides to call for help, it will:

#### **Android (Google Assistant)**
- Activates Google Assistant automatically
- Sends voice command: "Call [Wife's Name] and say: [Emergency Message]"
- Google Assistant makes the call and speaks the message

**Fallback Methods:**
1. Try `VOICE_COMMAND` intent
2. Try `CALL_PRIVILEGED` intent + TTS
3. Regular phone dial + TTS audio message

#### **iOS (Siri)**
- Activates Siri using Shortcuts URL scheme
- Siri makes call with pre-recorded message
- Fallback: Regular call + TTS message

### 3. **Emergency Message Content**
The AI will speak this message when calling your wife:

```
"Emergency alert. This is an automated message from RedPing Safety App.
Your contact has been detected in a [crash/fall] situation and is unresponsive.
Last known location: latitude -XX.XXXX, longitude XXX.XXXX.
Please check on them immediately. This is not a test."
```

## Technical Implementation

### **Key Features:**
- ✅ Uses phone's native AI (Google Assistant/Siri)
- ✅ Automatic voice message delivery
- ✅ Multiple fallback methods
- ✅ TTS (Text-to-Speech) integration
- ✅ Calls family contacts instead of 911
- ✅ Logs all call attempts

### **Required Permissions:**
Already configured in your app:
- `CALL_PHONE` - Make phone calls
- `READ_PHONE_STATE` - Monitor call status
- Internet - For location data

### **Dependencies Used:**
- `android_intent_plus` - Trigger Google Assistant
- `flutter_tts` - Speak emergency message
- `url_launcher` - Fallback dialing

## Call Flow Timeline

```
0:00  Crash detected
0:10  SOS countdown (10 seconds)
0:20  AI verification dialog appears
0:50  Verification timeout (30s) - No response
1:05  AI check #1 - Still unresponsive
1:20  AI check #2 - Still unresponsive
1:35  AI check #3 - Still unresponsive
5:20  AI VOICE CALL - Calls wife's number
      ↓
      Google Assistant/Siri activated
      ↓
      Call connects to wife
      ↓
      AI speaks emergency message
      ↓
      Wife can respond or take action
```

## Testing the AI Voice Call

### **Test Procedure:**
1. Drop your phone to trigger crash detection
2. Let verification dialog timeout (don't respond)
3. Wait ~5 minutes
4. AI will activate Google Assistant
5. Listen for the voice message

### **Expected Behavior:**
- ✅ Phone unlocks/wakes up
- ✅ Google Assistant voice appears
- ✅ Call connects to wife's contact
- ✅ AI message plays automatically
- ✅ Logs stored in app

### **Safety Notes:**
- Testing mode active - calls family, not 911
- You can cancel the call manually
- All attempts logged for review
- Multiple fallback methods ensure reliability

## Configuration

### **Change AI Voice Settings:**
Edit `ai_emergency_call_service.dart`:

```dart
// Change TTS speed (0.5 = slower, 1.0 = normal)
await _tts!.setSpeechRate(0.5);

// Change language
await _tts!.setLanguage('en-US');

// Customize message
String _prepareEmergencyMessage(...) {
  return 'Your custom message here';
}
```

### **Adjust Timing:**
```dart
static const Duration _initialVerificationWindow = Duration(seconds: 30);
static const Duration _verificationCheckInterval = Duration(seconds: 15);
static const Duration _maxMonitoringDuration = Duration(minutes: 5);
```

## Troubleshooting

### **AI Voice Call Not Working?**

1. **Google Assistant disabled:**
   - Enable Google Assistant in phone settings
   - Grant microphone permissions

2. **Siri disabled (iOS):**
   - Enable Siri in iPhone settings
   - Allow Siri when locked

3. **TTS not speaking:**
   - Check phone volume (not muted)
   - Check TTS engine installed
   - Test with: "Hey Google, test voice"

4. **Call not connecting:**
   - Verify wife's contact number saved correctly
   - Check phone signal strength
   - Test manual call to wife first

### **Fallback Behavior:**
If AI assistant fails:
- App will use regular phone dialer
- TTS will play message through speaker
- Contact can still answer normally

## Production Deployment

### **Before Going Live:**

1. **Revert Testing Mode:**
   - Change from family contacts back to 911/000
   - Remove `[TESTING]` logs
   - Restore pattern detection gates

2. **Test with Real Contacts:**
   - Coordinate with family member
   - Test full flow end-to-end
   - Verify message clarity

3. **Legal Compliance:**
   - Inform users AI will call emergency services
   - Update privacy policy (voice recordings)
   - Add consent during onboarding

## Advanced Features (Future)

### **Potential Enhancements:**
- [ ] AI listens for voice response during call
- [ ] AI can relay user's vital signs to responder
- [ ] Multi-language support for messages
- [ ] Record call audio for later review
- [ ] Integration with emergency dispatch systems
- [ ] Video call option for visual verification

## Support

For issues or questions:
- Check logs: `AIEmergencyCall` tag
- Test TTS separately: Use `flutter_tts` test app
- Test Assistant: "Hey Google, call [contact]"
- Review call history in app logs

---

**Status:** ✅ Implemented and Ready for Testing  
**Last Updated:** November 8, 2025  
**Version:** 1.0.2+3
