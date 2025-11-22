# RedPing Phone AI Integration - Comprehensive Guide

## 🎤 Overview

The Phone AI Integration system provides **hands-free voice control** and **AI-powered emergency calling** for the RedPing Safety App. It integrates with your phone's native AI assistant (Google Assistant on Android, Siri on iOS) to enable voice commands and automated emergency calls with spoken messages.

---

## 📋 Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Voice Commands](#voice-commands)
4. [AI Emergency Calling](#ai-emergency-calling)
5. [UI Components](#ui-components)
6. [Setup & Configuration](#setup--configuration)
7. [Testing Guide](#testing-guide)
8. [Troubleshooting](#troubleshooting)

---

## ✨ Features

### Voice Command Control
- **Wake word detection**: "Hey RedPing" or "RedPing" activates voice listening
- **Hands-free operation**: Control app without touching screen
- **Continuous listening**: Always ready for voice commands
- **Voice feedback**: AI speaks confirmations and status updates
- **Command recognition**: Natural language understanding for safety commands

### AI Emergency Calling
- **Automated calling**: AI calls emergency contacts when user unresponsive
- **Spoken messages**: AI speaks comprehensive emergency information during call
- **Multi-platform**: Works with Google Assistant (Android) and Siri (iOS)
- **Fallback system**: Graceful degradation to regular phone dialer if AI unavailable
- **Family contact priority**: Calls highest priority contact (wife/family) instead of 911

### Safety Integration
- **Crash detection trigger**: Voice activation works during emergencies
- **SOS integration**: Voice commands can activate/cancel SOS
- **Status monitoring**: Check system status via voice
- **Emergency mode**: Optimized for hands-free emergency response

---

## 🏗️ Architecture

### Core Services

```
PhoneAIIntegrationService
├── Voice Recognition (speech_to_text)
│   ├── Wake word detection
│   ├── Command pattern matching
│   └── Continuous listening
│
├── Text-to-Speech (flutter_tts)
│   ├── Voice feedback
│   ├── Status announcements
│   └── Command confirmations
│
├── Phone AI Integration
│   ├── Google Assistant (Android)
│   ├── Siri (iOS)
│   └── Voice call automation
│
└── Command Router
    ├── SOS activation/cancellation
    ├── Navigation commands
    └── System control
```

### Integration Points

1. **AppServiceManager**
   - Initializes PhoneAIIntegrationService
   - Provides global access to voice services
   - Coordinates with other services

2. **AIEmergencyCallService**
   - Uses PhoneAIIntegrationService for voice calls
   - Prepares emergency messages
   - Handles call fallback logic

3. **Main App**
   - Sets up voice command handlers
   - Starts continuous listening
   - Routes commands to appropriate services

---

## 🎙️ Voice Commands

### Available Commands

| Category | Command Phrases | Action |
|----------|----------------|---------|
| **Wake Word** | "Hey RedPing", "RedPing" | Activates voice listening |
| **SOS Activation** | "activate sos", "emergency sos", "help me", "i need help", "call for help", "emergency" | Activates SOS countdown |
| **SOS Cancellation** | "cancel sos", "stop sos", "false alarm", "i am okay", "i am fine" | Cancels active SOS |
| **Emergency Call** | "call emergency", "call 911", "call 000", "dial emergency" | Opens emergency dialer |
| **Navigation** | "open sos", "show sos", "sos page" | Opens SOS page |
| **Status Check** | "status", "check status", "how am i", "system status" | Speaks system status |
| **Crash Detection** | "enable crash detection", "turn on crash detection" | Enables crash/fall detection |
| **Crash Detection** | "disable crash detection", "turn off crash detection" | Disables crash/fall detection |

### Command Flow

```
1. User speaks command
2. Speech recognition detects words
3. Pattern matching identifies command
4. Command handler executes action
5. Voice feedback confirms execution
```

### Adding Custom Commands

Edit `phone_ai_integration_service.dart`:

```dart
final Map<String, List<String>> _commandPatterns = {
  'your_command': [
    'trigger phrase 1',
    'trigger phrase 2',
    'alternative phrase',
  ],
};
```

Add handler in `main.dart`:

```dart
case 'your_command':
  // Your action code
  phoneAI.speak('Command executed');
  break;
```

---

## 📞 AI Emergency Calling

### How It Works

When the AI determines you're unresponsive after a crash/fall:

1. **Detection Phase** (0-30s)
   - Crash/fall detected
   - AI verification dialog appears
   - User has 30 seconds to respond

2. **Verification Phase** (30s-60s)
   - AI attempts 3 verification checks
   - Monitors for user movement
   - Analyzes response patterns

3. **Decision Phase** (60s-5min)
   - If no response after 3 attempts
   - AI decides to call for help
   - Maximum 5 minutes before call

4. **Call Execution**
   - Gets family emergency contacts
   - Sorts by priority (wife = priority 1)
   - Triggers Google Assistant/Siri

5. **Voice Call**
   - AI opens phone dialer
   - Attempts to activate voice assistant
   - Speaks emergency message

### Emergency Message Content

The AI speaks this message during the call:

```
"Emergency alert from RedPing Safety App.
[Impact magnitude] G impact detected at [time].
User is unresponsive after multiple verification attempts.
Location: [GPS coordinates].
Please check on them immediately.
This is an automated emergency call."
```

### Call Methods

#### Android (Google Assistant)

1. **Primary**: Voice command intent
   ```
   "Call [Contact Name] and say: [Emergency Message]"
   ```

2. **Fallback**: Assistant activation
   ```
   Opens Google Assistant with call command
   Speaks message after connection
   ```

3. **Last Resort**: Regular phone dialer
   ```
   Opens tel: URL
   User or recipient handles call
   ```

#### iOS (Siri)

1. **Primary**: Siri shortcuts
   ```
   Activates Siri with voice command
   Speaks emergency message
   ```

2. **Fallback**: Regular phone dialer
   ```
   Opens tel: URL
   Manual call handling
   ```

### Family Contact Configuration

Priority system (lower number = higher priority):

- **Priority 1**: Wife/Spouse (called first)
- **Priority 2**: Second family member (backup)
- **Priority 3+**: Additional contacts

Configure in: **Profile → Emergency Contacts → Set Priority**

---

## 🎨 UI Components

### VoiceCommandWidget

Full-featured voice control panel:

```dart
VoiceCommandWidget(
  // Shows:
  // - Listening status with pulse animation
  // - Recognized text display
  // - Last command executed
  // - Available commands list
  // - Start/Stop listening button
  // - Test voice button
)
```

**Features:**
- Real-time listening indicator
- Recognized speech display
- Command history
- Expandable command list
- Voice enable/disable toggle

### VoiceStatusIndicator

Compact status badge for app bar:

```dart
VoiceStatusIndicator(
  // Shows:
  // - Red pulsing badge when listening
  // - Hides when not listening
)
```

**Features:**
- Animated pulse effect
- Minimal screen space
- Always visible indicator

### Usage Example

```dart
Scaffold(
  appBar: AppBar(
    title: Text('RedPing'),
    actions: [
      VoiceStatusIndicator(), // Shows when listening
    ],
  ),
  body: Column(
    children: [
      VoiceCommandWidget(), // Full voice control panel
      // ... other widgets
    ],
  ),
)
```

---

## ⚙️ Setup & Configuration

### 1. Permissions (Android)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Voice recognition -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />

<!-- Phone calls -->
<uses-permission android:name="android.permission.CALL_PHONE" />

<!-- Google Assistant -->
<queries>
  <intent>
    <action android:name="android.intent.action.ASSIST" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VOICE_COMMAND" />
  </intent>
</queries>
```

### 2. Permissions (iOS)

Add to `ios/Runner/Info.plist`:

```xml
<!-- Voice recognition -->
<key>NSMicrophoneUsageDescription</key>
<string>RedPing needs microphone access for voice commands and emergency detection</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>RedPing uses speech recognition for hands-free voice control</string>

<!-- Siri -->
<key>NSSiriUsageDescription</key>
<string>RedPing uses Siri for emergency voice calling</string>
```

### 3. Dependencies

Already included in `pubspec.yaml`:

```yaml
dependencies:
  speech_to_text: ^7.0.0      # Voice recognition
  flutter_tts: ^4.2.0         # Text-to-speech
  android_intent_plus: ^5.1.0 # Android intents
```

### 4. Initialization

Auto-initialized by AppServiceManager:

```dart
// Happens automatically in main.dart
await AppServiceManager().phoneAIIntegrationService.initialize();
```

### 5. Enable Voice Commands

```dart
// Enable/disable voice listening
await phoneAI.setVoiceCommandsEnabled(true);

// Start continuous listening
await phoneAI.startVoiceListening();

// Stop listening
await phoneAI.stopVoiceListening();
```

---

## 🧪 Testing Guide

### Test Voice Commands

1. **Start the app**
   ```
   flutter run --verbose
   ```

2. **Wait for initialization**
   ```
   Look for: "🎤 Voice commands initialized"
   ```

3. **Test wake word**
   ```
   Say: "Hey RedPing"
   Expect: "Yes, I'm listening" (spoken response)
   ```

4. **Test SOS activation**
   ```
   Say: "Activate SOS"
   Expect: 
   - Voice: "Activating emergency SOS"
   - Navigation to SOS page
   - SOS countdown starts
   ```

5. **Test status check**
   ```
   Say: "Check status"
   Expect: "System is active and monitoring for emergencies"
   ```

### Test AI Emergency Calling

1. **Configure family contact**
   ```
   - Go to Profile → Emergency Contacts
   - Add wife's contact with Priority 1
   - Save changes
   ```

2. **Trigger crash detection**
   ```
   - Drop phone from height
   - Wait for crash detection
   - Don't respond to verification dialog
   ```

3. **Wait for AI call**
   ```
   Timeline:
   0:00 - Crash detected
   0:30 - Verification timeout
   0:40 - SOS activated
   5:40 - AI calls wife
   ```

4. **Verify call behavior**
   ```
   Expected:
   - Google Assistant/Siri activates
   - Phone dialer opens with wife's number
   - Emergency message attempted
   ```

### Test Voice Recognition Quality

```dart
// Check recognition accuracy
phoneAI.setOnVoiceRecognized((text) {
  print('Recognized: $text');
});

// Test phrases:
- Clear room, normal volume
- Background noise
- Different accents
- Fast/slow speech
```

---

## 🔧 Troubleshooting

### Voice Commands Not Working

**Problem**: App doesn't respond to voice commands

**Solutions**:
1. Check microphone permission granted
2. Verify initialization: `phoneAI.isInitialized`
3. Check if listening: `phoneAI.isListening`
4. Test device microphone in other apps
5. Restart voice listening manually

```dart
if (!phoneAI.isListening) {
  await phoneAI.startVoiceListening();
}
```

### Wake Word Not Detected

**Problem**: "Hey RedPing" doesn't trigger response

**Solutions**:
1. Speak clearly and slowly
2. Try alternative: Just "RedPing"
3. Check background noise levels
4. Increase microphone sensitivity
5. Test with different phrases

### AI Call Not Working

**Problem**: AI doesn't call emergency contacts

**Solutions**:
1. Verify family contacts configured with priority
2. Check CALL_PHONE permission granted
3. Test regular phone calls work
4. Check Google Assistant/Siri enabled
5. Review logs for error messages

```dart
// Check contact configuration
final contacts = emergencyContactsService.contacts;
print('Contacts: ${contacts.length}');
print('Primary: ${contacts.first.name}, Priority: ${contacts.first.priority}');
```

### Speech Recognition Errors

**Problem**: "Speech recognition not available"

**Solutions**:
1. **Android**: Install Google app, enable voice input
2. **iOS**: Enable Siri in Settings
3. Check internet connection (required for recognition)
4. Update Google app / iOS version
5. Clear speech recognition cache

### TTS Not Speaking

**Problem**: AI doesn't provide voice feedback

**Solutions**:
1. Check device volume not muted
2. Verify TTS engine installed
3. Test TTS manually:
   ```dart
   await phoneAI.speak('Test message');
   ```
4. **Android**: Settings → Accessibility → Text-to-Speech
5. **iOS**: Settings → Accessibility → Spoken Content

### Google Assistant Not Activating

**Problem**: AI call doesn't open Assistant

**Solutions**:
1. Enable "Hey Google" detection
2. Update Google app to latest version
3. Grant Assistant permissions
4. Test Assistant manually: Long-press home button
5. Check Intent permissions in manifest

### Performance Issues

**Problem**: Voice recognition causing lag

**Solutions**:
1. Disable continuous listening when not needed
2. Use manual activation instead
3. Reduce background service load
4. Check battery optimization settings
5. Monitor memory usage

```dart
// Disable when not needed
await phoneAI.stopVoiceListening();

// Re-enable when required
await phoneAI.startVoiceListening();
```

---

## 📊 Performance & Battery

### Battery Impact

- **Continuous listening**: ~2-5% per hour
- **Idle (not listening)**: Minimal impact
- **AI emergency call**: One-time spike

### Optimization Tips

1. **Smart activation**: Only enable in emergency mode
2. **Timeout**: Stop listening after inactivity
3. **Wake word only**: Don't analyze all speech
4. **Battery saver mode**: Reduce recognition frequency

```dart
// Enable only when needed
if (emergencyMode) {
  await phoneAI.startVoiceListening();
} else {
  await phoneAI.stopVoiceListening();
}
```

---

## 🔐 Privacy & Security

### Voice Data

- **Local processing**: Speech-to-text uses device API
- **No cloud storage**: Recognized text not saved
- **Temporary**: Voice data discarded after recognition
- **Opt-in**: User must enable voice commands

### Emergency Calls

- **Automatic**: AI calls without confirmation when unresponsive
- **Logged**: Call attempts recorded locally
- **Family only**: Calls configured contacts, not 911
- **Testing mode**: Enabled for development

### Permissions

- **Microphone**: Required for voice recognition
- **Phone**: Required for emergency calling
- **Storage**: Stores voice preferences only

---

## 📱 Platform Differences

### Android
- ✅ Google Assistant integration
- ✅ Voice command intents
- ✅ Background listening
- ✅ Continuous recognition

### iOS
- ⚠️ Siri integration (limited)
- ⚠️ Background listening (restricted)
- ✅ On-demand recognition
- ⚠️ Requires app foreground

---

## 🚀 Future Enhancements

- [ ] Multi-language support
- [ ] Custom wake word training
- [ ] Voice biometrics verification
- [ ] Offline voice recognition
- [ ] Smart home integration
- [ ] Voice-controlled navigation
- [ ] Emergency voice notes
- [ ] AI conversation mode

---

## 📚 API Reference

### PhoneAIIntegrationService

#### Properties
```dart
bool isInitialized      // Service ready status
bool isListening        // Currently listening for voice
bool voiceCommandsEnabled // Voice commands on/off
String lastRecognizedCommand // Last executed command
```

#### Methods
```dart
Future<void> initialize()
Future<void> startVoiceListening()
Future<void> stopVoiceListening()
Future<void> speak(String text)
Future<void> makeAIVoiceCall({
  required String phoneNumber,
  required String contactName,
  required String emergencyMessage,
})
Future<void> setVoiceCommandsEnabled(bool enabled)
void setOnVoiceCommand(Function(String) callback)
void setOnVoiceRecognized(Function(String) callback)
void setOnListeningStateChanged(Function(bool) callback)
Map<String, List<String>> getAvailableCommands()
```

---

## 📞 Support

For issues or questions:
- Check logs: Look for "PhoneAI" tag
- Test manually: Use UI widgets to verify functionality
- Review permissions: Ensure all required permissions granted
- Check device: Test voice features in other apps

---

**Last Updated**: November 8, 2025
**Version**: 1.0.0
**Author**: RedPing Development Team
