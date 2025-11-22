# WebRTC Emergency Call Setup Guide

## Overview

The WebRTC Emergency Call Service uses **Agora RTC Engine** to enable internet-based voice calls where the AI emergency message can be directly injected into the call audio stream. This solves the fundamental limitation of traditional phone calls where Flutter TTS cannot route audio into the call stream.

## Why WebRTC?

### Traditional Phone Call Limitations:
- ❌ Flutter TTS plays through `STREAM_MUSIC` (device speaker)
- ❌ Phone calls use `STREAM_VOICE_CALL` (call audio)
- ❌ No way to inject TTS into phone call audio without root/system permissions
- ❌ Recipient cannot hear AI voice during emergency call

### WebRTC Solution:
- ✅ Complete control over audio streams
- ✅ TTS can be mixed directly into call audio
- ✅ Recipient hears AI voice clearly
- ✅ Critical for unconscious user scenario
- ✅ Works over internet (WiFi/cellular data)

## Setup Instructions

### 1. Get Agora App ID

1. Go to [Agora Console](https://console.agora.io/)
2. Sign up for free account (10,000 minutes free per month)
3. Create new project
4. Get your **App ID** from project settings
5. Copy the App ID

### 2. Configure App ID

Open `lib/services/webrtc_emergency_call_service.dart` and replace:

```dart
static const String _appId = 'YOUR_AGORA_APP_ID_HERE';
```

With your actual App ID:

```dart
static const String _appId = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

### 3. Dependencies

Already added to `pubspec.yaml`:

```yaml
dependencies:
  agora_rtc_engine: ^6.3.2
  flutter_tts: ^4.2.0
  permission_handler: ^12.0.1
```

Run to install:
```bash
flutter pub get
```

### 4. Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### iOS (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>RedPing needs microphone access for emergency voice calls</string>
<key>NSCameraUsageDescription</key>
<string>RedPing may use camera for future video call features</string>
```

## Usage

### Initialize Service

```dart
final webrtcService = WebRTCEmergencyCallService();

// Initialize on app startup
await webrtcService.initialize();
```

### Make Emergency Call

```dart
try {
  final channelName = await webrtcService.makeEmergencyCall(
    contactId: 'emergency_contact_123',
    emergencyMessage: 'This is an automated RedPing emergency alert. '
        'The user has been in an accident and needs immediate help. '
        'Current location: -22.4897, 120.0150. '
        'Please respond if you can hear this message.',
  );
  
  print('Emergency call initiated on channel: $channelName');
  // Send push notification to contact with channel name
} catch (e) {
  print('Emergency call failed: $e');
  // Fall back to traditional phone call
}
```

### Contact Receives Call

The emergency contact receives a push notification with:
- Channel name to join
- Emergency alert message
- Location information

Contact's app joins the call:

```dart
await webrtcService.joinEmergencyCall(channelName);
```

### End Call

```dart
await webrtcService.endCall();
```

## Call Flow

```
1. Accident detected → AI verification fails (no response)
2. App creates Agora channel: "emergency_1234567890_contact123"
3. App joins channel and enables audio
4. Push notification sent to emergency contact
5. Contact receives notification: "EMERGENCY CALL FROM [User]"
6. Contact taps notification → App opens and auto-joins channel
7. TTS speaks emergency message through call audio
8. Contact hears: "This is an automated RedPing emergency alert..."
9. Contact can speak back through call
10. Call remains open until resolved or timeout
```

## Architecture

### Key Components:

1. **RtcEngine**: Agora's core WebRTC engine
2. **Audio Mixing**: TTS audio mixed into call stream
3. **Event Handlers**: Track call state (joined, user joined, left, errors)
4. **Push Notifications**: Alert contacts of emergency call
5. **Deep Linking**: Auto-join channel from notification

### Audio Configuration:

```dart
await _engine!.setAudioProfile(
  profile: AudioProfileType.audioProfileMusicHighQuality,
  scenario: AudioScenarioType.audioScenarioChatroom,
);
```

- High-quality voice for clear emergency messages
- Chatroom scenario for low-latency communication

## Integration with Existing System

### Update `phone_ai_integration_service.dart`

```dart
class PhoneAIIntegrationService {
  final WebRTCEmergencyCallService _webrtcService;
  
  Future<void> makeEmergencyCall({
    required String contactPhone,
    required String contactId,
    required String message,
  }) async {
    try {
      // Try WebRTC first (better audio injection)
      if (_webrtcService.isInitialized) {
        await _webrtcService.makeEmergencyCall(
          contactId: contactId,
          emergencyMessage: message,
        );
        return;
      }
    } catch (e) {
      AppLogger.w('WebRTC call failed, falling back to phone call', error: e);
    }
    
    // Fall back to traditional phone call
    await _makeAndroidAICall(contactPhone, message);
  }
}
```

## Testing

### Test Emergency Call

```dart
// Test button on SOS page
ElevatedButton(
  onPressed: () async {
    await webrtcService.initialize();
    
    final channel = await webrtcService.makeEmergencyCall(
      contactId: 'test_contact',
      emergencyMessage: 'This is a test emergency call from RedPing.',
    );
    
    print('Test call created: $channel');
    // Manually join from another device/emulator
  },
  child: Text('Test WebRTC Emergency Call'),
)
```

### Two Device Testing

1. **Device 1** (Caller):
   - Trigger emergency call
   - Should create channel and speak message
   - Log: "Emergency call channel: emergency_xxx"

2. **Device 2** (Receiver):
   - Use logged channel name
   - Call `joinEmergencyCall(channelName)`
   - Should hear AI emergency message

## Production Considerations

### 1. Token Server (Security)

For production, use Agora token authentication:

```dart
// Get token from your backend server
final token = await _getTokenFromBackend(channelName, userId);

await _engine!.joinChannel(
  token: token,  // Use server-generated token
  channelId: channelName,
  uid: 0,
  options: options,
);
```

### 2. Push Notifications

Implement Firebase Cloud Messaging to notify contacts:

```dart
Future<void> _notifyContact(String contactId, String channelName) async {
  await FirebaseMessaging.instance.sendMessage(
    to: contactId,
    data: {
      'type': 'emergency_call',
      'channel': channelName,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
```

### 3. Deep Linking

Handle incoming emergency call notifications:

```dart
// Handle notification tap
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  if (message.data['type'] == 'emergency_call') {
    final channel = message.data['channel'];
    _joinEmergencyCall(channel);
  }
});
```

### 4. Network Fallback

Always have phone call as backup:

```dart
Future<void> makeEmergencyCall() async {
  try {
    await _webrtcEmergencyCall();
  } catch (e) {
    AppLogger.w('WebRTC failed, using phone call', error: e);
    await _traditionalPhoneCall();
  }
}
```

### 5. Battery Optimization

- Voice-only (no video) saves bandwidth and battery
- Auto-end call after message delivered + 30 seconds
- Use low-latency audio profile

## Advantages

| Feature | Traditional Phone Call | WebRTC Call |
|---------|----------------------|-------------|
| AI Voice Injection | ❌ Cannot inject TTS | ✅ Direct audio mixing |
| Audio Quality | Depends on network | ✅ High-quality RTC |
| Works Unconscious | ❌ Workaround needed | ✅ Perfect solution |
| Cost | Carrier charges | ✅ Free (10K mins/month) |
| International | Expensive | ✅ Same cost worldwide |
| Recording | Difficult | ✅ Built-in support |
| Analytics | None | ✅ Call quality metrics |

## Cost Analysis

### Agora Pricing:
- **Free Tier**: 10,000 minutes/month
- **Above Free Tier**: $0.99 per 1,000 minutes

### Usage Estimate:
- Average emergency call: 2-3 minutes
- Monthly emergencies (100 users): ~10 calls = 30 minutes
- **Total Cost**: Free (well under 10K minutes)

## Support & Resources

- **Agora Documentation**: https://docs.agora.io/en/
- **Flutter SDK**: https://pub.dev/packages/agora_rtc_engine
- **Sample Code**: https://github.com/AgoraIO/Flutter-SDK
- **Console**: https://console.agora.io/

## Troubleshooting

### Issue: "Engine not initialized"
**Solution**: Call `initialize()` before making calls

### Issue: "No audio heard"
**Solution**: Check microphone permissions and audio profile settings

### Issue: "Connection failed"
**Solution**: Verify internet connection and App ID is correct

### Issue: "User not joined"
**Solution**: Ensure contact received notification and joined channel

### Issue: "Echo during call"
**Solution**: Agora has built-in echo cancellation, check device settings

## Next Steps

1. ✅ Set up Agora App ID
2. ✅ Install dependencies (`flutter pub get`)
3. ⏳ Integrate with `phone_ai_integration_service.dart`
4. ⏳ Implement push notifications for contact alerts
5. ⏳ Add deep linking for auto-join
6. ⏳ Test with two devices
7. ⏳ Set up token server for production
8. ⏳ Deploy and monitor call quality metrics

## Critical For Life-Saving Feature

> "Imagine the user has had an accident, badly hurt, unconscious. The AI call is the only hope to get help."

WebRTC emergency calls ensure that even if the user cannot respond, the AI can clearly communicate the emergency to contacts who can then:
- Hear the exact situation
- Know the precise location
- Respond appropriately
- Dispatch help immediately

This makes RedPing a true life-saving application. 🚨❤️
