# 🚨 AI Emergency Call System - Complete Documentation

## Overview

⚠️ **CRITICAL PLATFORM LIMITATION**: This system **CANNOT** automatically dial emergency services (911/112/999) due to Android/iOS platform restrictions. The app can only open the phone dialer with the emergency number pre-filled, requiring manual user tap to complete the call.
The AI Emergency Call System monitors potential severe impact or distress events and coordinates escalation pathways via the enhanced SMS alert pipeline and manual call UI actions. Automated dialer opening has been fully disabled by a global kill switch.
The AI Emergency Response System monitors crash/fall detection victims for signs of responsiveness and automatically sends SMS alerts to emergency contacts. While the system attempts to open the emergency dialer for unconscious users, **this cannot help users who are completely unresponsive** as they cannot press the "Call" button.

## 2. Goals
- Rapid detection of severe fall / impact signatures
- Provide user a clear verification dialog (cancel, false alarm suppression)
- Escalate to emergency contacts via intelligent, multi-phase SMS automatically
- Preserve and streamline manual SOS voice call activation paths
- Avoid ineffective auto-dialer flows; focus on actionable, high-fidelity human responses
- **🏥 Priority 2**: Closest local emergency services - Normal phone numbers for nearby hospitals, fire stations, police

See `AI_EMERGENCY_CONTACT_AUTO_UPDATE.md` for complete details on the auto-update system.

## 4. Architecture Summary

Primary components:
- `ai_emergency_call_service.dart` (event orchestration, timing, supervision; auto-call disabled by kill switch)
- `sms_service.dart` (enhanced outbound SMS sequencing v2.0)
- `emergency_contact.dart` (contact metadata / prioritization & availability)
- Firestore (session logging, responder acknowledgments)
- SharedPreferences (local cooldown / interaction stamps)

The AI Emergency Call Service automatically starts monitoring when:
- **Crash Detection** or **Fall Detection** SOS is activated
- User completes or bypasses the initial countdown
- SOS session becomes active
## 5. Automated Dialer Escalation (Retired)

Legacy behavior (auto dialer open at 2 minutes for ≥35G impacts) has been removed. The constant `EMERGENCY_CALL_ENABLED = false` enforces global disablement of any AI-initiated dialer actions. Manual pathways are the exclusive voice-call mechanism.

Rationale:
- Platform restriction requires manual confirmation.
- Unconscious user scenario not improved.
- SMS-first escalation yields higher responder engagement and earlier actionable interventions.

## 🤖 AI Decision Logic (5-Stage Verification)
## 6. SMS Sequencing (v2.0)
- Initial alert (T0) to priority subset (top 3 by composite score & availability)
- Active phase updates every 2 minutes (up to 10) unless acknowledged
- No-response escalation at T+5m to broader secondary contacts
- Responder acknowledgment shifts cadence to 10-minute intervals (acknowledged phase)
- Final resolution (RESOLVED / FALSE ALARM) broadcast to all contacted numbers
  // ✅ User is responsive - stop monitoring
  stopMonitoring();
## 7. Contact Prioritization
- Implemented composite scoring (priority tier + availability state + recent response + distance)
- Availability enum: `available`, `busy`, `emergencyOnly`, `unavailable`, `unknown`
- Distance and lastResponseTime used for secondary ordering refinements

### Stage 2: SAR Response Check
## 8. False Alarm Handling & Response Keywords
- User cancellation stops all timers immediately
- Incoming SMS replies parsed for confirmation or false alarm keywords
- Confirmation keywords: HELP, RESPONDING, ON MY WAY, COMING, YES, OK, CONFIRMED
- False alarm keywords: FALSE, MISTAKE, CANCEL, NO, SAFE
- Acknowledgment shifts phase; false alarm triggers resolution broadcast
  // ✅ SAR teams are coming - wait for them
  continueMonitoring();
## 9. Manual Call Pathways
- UI hotlines & contact action buttons remain fully functional
- `quickCall()` bypasses kill switch for explicit user voice-call intent
- These are the sole voice-call routes under disabled auto-call architecture
  continueVerification();
}
## 11. Testing Mode Interaction
- Does not override kill switch (auto-call remains disabled)
- May suppress verification dialog for test acceleration
- Labels sessions distinctly for analytics isolation
- Exercises full SMS pipeline (including escalation & keyword parsing)
```dart
// Check 1: User interaction (screen touch, button press)
## 13. Conditional Re-Enable Strategy (Optional / Controlled)
- Flip `EMERGENCY_CALL_ENABLED` to `true` or inject via build-time `--dart-define` for controlled lab tests
- Requires: Legal review, regression tests, explicit UX warning, analytics gating
- Not recommended for production release
}
Revision: v1.4 (Kill switch active, SMS v2.0, auto-call retired)
// Check 2: Location movement (>5 meters)
if (movedDistance > 5.0) {
  return RESPONSIVE;
}

// Check 3: Future - Sensor activity
// TODO: Accelerometer/gyroscope activity
```

### Stage 4: Verification Attempt Tracking
```dart
verificationAttempts++;
if (userResponsive) {
  verificationAttempts = 0; // Reset
} else {
  logAttempt(verificationAttempts);
}
```

### Stage 5: Emergency Dialer Trigger (Limited Effectiveness)
```dart
bool shouldOpenEmergencyDialer() {
  // Critical Impact: Severe crash (>35g) + no SAR + 2min elapsed
  if (impactMagnitude > 35.0g && !hasSAR && timeElapsed >= 2min) 
    return true; // Opens dialer, but unconscious user cannot complete call
  
  // Unresponsive: 3 failed verifications + 3min elapsed
  if (verificationAttempts >= 3 && timeElapsed >= 3min) 
    return true; // Opens dialer, but unconscious user cannot complete call
  
  // Timeout: 5 minutes total elapsed
  if (timeElapsed >= 5min) 
    return true; // Opens dialer, but unconscious user cannot complete call
  
  // SAR Delayed: SAR acknowledged but 4min+ passed
  if (hasSAR && timeElapsed >= 4min) 
    return true; // Opens dialer, but unconscious user cannot complete call
  
  return false;
}
```

**⚠️ Critical Limitation:**
- Function only **opens dialer** with pre-filled emergency number
- ❌ Cannot force-dial (Android/iOS platform restriction)
- ❌ Unconscious users cannot press "Call" button
- ✅ SMS alerts to emergency contacts sent automatically (primary safety mechanism)

---

## ⏱️ Timeline Example

### Scenario: Unresponsive Crash Victim

| Time | Event | AI Action |
|------|-------|-----------|
| 00:00 | Crash detected (42g impact) | Start 10s countdown |
| 00:10 | User doesn't cancel | Activate SOS, Start AI monitoring, SMS alerts sent |
| 00:10-00:40 | Initial verification window | AI checks for user interaction/movement |
| 00:45 | First verification check | No movement detected → Attempt 1 |
| 01:00 | Second verification check | No movement detected → Attempt 2 |
| 01:15 | Third verification check | No movement detected → Attempt 3 |
| 01:30 | SAR team acknowledges | AI continues monitoring SAR |
| 03:00 | SAR response timeout | SAR delayed - AI escalates |
| 03:00 | **AI OPENS EMERGENCY DIALER** | ⚠️ Dialer opens with 911 pre-filled |
| 03:00 | **USER MUST TAP "CALL"** | ❌ Unconscious user cannot complete this step |
| 03:00+ | Emergency contacts receive SMS | ✅ This works automatically |

### Scenario: Responsive User (Normal)

| Time | Event | AI Action |
|------|-------|-----------|
| 00:00 | Crash detected | Start countdown |
| 00:05 | **User presses "I'm OK"** | Cancel SOS, Stop AI monitoring ✅ |

---

## 📱 Emergency Number Selection

### Country-Based Emergency Numbers
```dart
final emergencyNumbers = {
  'US': '911',  // United States
  'CA': '911',  // Canada
  'MX': '911',  // Mexico
  'GB': '999',  // United Kingdom
  'IE': '112',  // Ireland
  'AU': '000',  // Australia
  'NZ': '111',  // New Zealand
  'IN': '112',  // India
  'ZA': '10111', // South Africa
  'JP': '119',  // Japan
  'CN': '120',  // China
  'KR': '119',  // South Korea
  'BR': '192',  // Brazil
  'AR': '107',  // Argentina
  'EU': '112',  // European Union
  'DEFAULT': '112', // International
};
```

### Current Implementation
- **Default**: `112` (works in most countries worldwide)
- **Future**: GPS-based country detection
- **Fallback**: Always `112` if detection fails

---

## 🛠️ Technical Implementation

### Service Architecture

```
lib/services/ai_emergency_call_service.dart (468 lines)
├── Singleton pattern for global access
├── Timer-based monitoring (every 15 seconds)
├── SharedPreferences for interaction tracking
├── url_launcher for phone dialing
└── LocationService for movement detection
```

### Key Classes & Methods

#### AIEmergencyCallService
```dart
class AIEmergencyCallService {
  // Configuration
  static const Duration _initialVerificationWindow = Duration(seconds: 30);
  static const Duration _verificationCheckInterval = Duration(seconds: 15);
  static const Duration _sarResponseTimeout = Duration(minutes: 3);
  static const Duration _totalWaitBeforeCall = Duration(minutes: 5);
  static const int _maxVerificationAttempts = 3;
  
  // Public Methods
  Future<void> initialize()
  Future<void> startMonitoringSession(SOSSession session)
  Future<void> stopMonitoringSession(String sessionId)
  Future<void> recordUserInteraction(String sessionId)
  void dispose()
  
  // Callbacks
  void setOnEmergencyCallInitiated(callback)
  void setOnAIDecision(callback)
  void setOnVerificationAttempt(callback)
  
  // Private Methods
  Future<void> _checkSessionStatus(SOSSession session)
  Future<bool> _verifyUserResponsiveness(SOSSession session)
  bool _shouldMakeEmergencyCall(SOSSession session, ...)
  Future<void> _makeEmergencyCall(SOSSession session)
  String _getEmergencyNumber(SOSSession session)
  Future<void> _dialEmergencyNumber(String number, SOSSession session)
  double _calculateDistance(lat1, lon1, lat2, lon2)
}
```

### Integration Points

#### 1. SOS Service Integration (sos_service.dart)
```dart
// Initialize AI monitoring on crash/fall detection
if (session.type == SOSType.crashDetection || 
    session.type == SOSType.fallDetection) {
  await _aiEmergencyCallService.initialize();
  await _aiEmergencyCallService.startMonitoringSession(session);
  
  // Set up callbacks for logging
  _aiEmergencyCallService.setOnEmergencyCallInitiated((session, number) {
    AppLogger.e('🚨 AI called $number for session ${session.id}');
  });
}

// Stop monitoring when user cancels
_aiEmergencyCallService.stopMonitoringSession(sessionId);

// Record user interaction to prove responsiveness
Future<void> recordUserInteraction(String sessionId) async {
  await _aiEmergencyCallService.recordUserInteraction(sessionId);
}
```

#### 2. SOS Page Integration (sos_page.dart)
```dart
void _cancelSOS() async {
  // 🤖 Record user interaction (user is responsive)
  if (_currentSession != null) {
    await _serviceManager.sosService.recordUserInteraction(_currentSession!.id);
  }
  
  // Cancel the SOS
  _serviceManager.sosService.cancelSOS();
}
```

---

## 📊 Movement Detection Algorithm

### Haversine Formula
Calculates the great-circle distance between two GPS coordinates:

```dart
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // π / 180
  final a = 0.5 - 
      (cos((lat2 - lat1) * p) / 2) + 
      (cos(lat1 * p) * cos(lat2 * p) * 
      (1 - cos((lon2 - lon1) * p)) / 2);
  
  return 12742 * asin(sqrt(a)) * 1000; // Distance in meters
}
```

### Movement Threshold
- **Threshold**: 5 meters
- **Reasoning**: 
  - Less than 5m = GPS drift (not real movement)
  - More than 5m = User is conscious and moving

---

## 🔐 User Interaction Tracking

### SharedPreferences Storage
```dart
// Store last interaction timestamp
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('last_interaction_$sessionId', DateTime.now().millisecondsSinceEpoch);

// Retrieve last interaction
final lastInteraction = prefs.getInt('last_interaction_$sessionId');
if (lastInteraction != null) {
  final timeSinceInteraction = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(lastInteraction)
  );
}
```

### What Counts as Interaction?
- User cancels SOS (button press)
- User dismisses notification
- User touches screen during active SOS
- Any explicit user action

---

## 📞 Phone Call Integration

### url_launcher Package
```dart
Future<void> _dialEmergencyNumber(String number, SOSSession session) async {
  final uri = Uri(scheme: 'tel', path: number);
  
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    AppLogger.e('🚨 Emergency call initiated to $number');
    
    // Record in database
    await _recordEmergencyCall(session, number);
  }
}
```

### Call Behavior and Platform Limitations
- **iOS**: Opens phone app with number pre-filled
- **Android**: Opens dialer with number ready
- **User Must**: Press final "Call" button (platform requirement, not just legal)

**⚠️ Critical Platform Limitations:**
- Neither Android nor iOS allow apps to force-dial emergency numbers
- This is intentional platform policy to prevent false automated emergency calls
- No workaround exists - apps can only use `tel:` URI which opens dialer
- ❌ **Fatal flaw**: Unconscious users cannot press "Call" button
- ✅ **Workaround**: SMS alerts to emergency contacts work automatically

---

## 🧪 Testing Procedures

### Unit Testing
```bash
# Run tests for AI logic
flutter test test/services/ai_emergency_call_service_test.dart
```

### Manual Testing

#### Test 1: User Cancels Immediately (Normal)
1. Trigger crash detection (shake phone hard)
2. **Press "I'm OK" during countdown**
3. ✅ Expected: SOS cancelled, AI monitoring stops

#### Test 2: User Unresponsive (Emergency)
1. Trigger crash detection
2. **DO NOT touch phone for 5 minutes**
3. ✅ Expected: AI calls emergency services at 5:00 mark

#### Test 3: SAR Team Responds (Wait for SAR)
1. Trigger crash detection
2. Have SAR team acknowledge within 3 minutes
3. **DO NOT move phone**
4. ✅ Expected: AI waits for SAR team, no emergency call

#### Test 4: Movement Detection
1. Trigger crash detection
2. After countdown, **walk 10 meters**
3. ✅ Expected: AI detects movement, stops monitoring

#### Test 5: Critical Impact Scenario
1. Simulate high-impact crash (>35g)
2. **DO NOT touch phone**
3. ✅ Expected: AI calls emergency at 2:00 mark (faster escalation)

---

## 📈 Logging & Monitoring

### AI Decision Logs
```dart
// Every AI decision is logged
AppLogger.i('🤖 AI: SAR teams responding - monitoring');
AppLogger.w('🤖 AI: User unresponsive - attempt 3/3');
AppLogger.e('🚨 CALLING EMERGENCY SERVICES: 911');
```

### Callback Events
```dart
// Emergency call initiated
onEmergencyCallInitiated: (session, number) {
  print('AI called $number for ${session.id}');
}

// AI decision made
onAIDecision: (session, decision) {
  print('AI Decision: $decision');
}

// Verification attempt
onVerificationAttempt: (session, attempts) {
  print('Verification attempt $attempts');
}
```

---

## 🚀 Deployment Checklist

### Pre-Deployment
- ✅ All compilation errors resolved
- ✅ url_launcher package installed (v6.2.1)
- ✅ SharedPreferences dependency confirmed
- ✅ Location permissions configured
- ✅ Phone call permissions configured

### Configuration Files

#### pubspec.yaml
```yaml
dependencies:
  url_launcher: ^6.2.1
  shared_preferences: ^2.2.2
  geolocator: ^10.1.0
```

#### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

#### Info.plist (iOS)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required to verify user movement during emergencies</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Monitor location during SOS for user safety</string>
```

---

## 🎓 AI Logic Explained

### Why These Specific Timeframes?

#### 30-Second Initial Window
- Allows user to cancel false positives
- Standard emergency response delay
- Balances false alarms vs real emergencies

#### 15-Second Check Intervals
- Frequent enough to detect movement
- Not too aggressive on battery
- Standard monitoring cadence

#### 3-Minute SAR Timeout
- Average SAR acknowledgment time
- Industry standard response window
- Prevents premature escalation

#### 5-Minute Total Timeout
- Critical medical intervention window
- "Golden Hour" first 5 minutes crucial
- Ensures help is always dispatched

### Multi-Factor Decision Algorithm

The AI doesn't rely on a single factor. It combines:
1. **Impact Severity** - How hard was the crash?
2. **Time Elapsed** - How long unresponsive?
3. **Verification Attempts** - How many checks failed?
4. **SAR Response** - Are rescuers coming?
5. **User Interaction** - Any signs of consciousness?

This multi-factor approach minimizes false positives while ensuring real emergencies get help.

---

## 🔮 Future Enhancements

### Planned Features
1. **GPS-Based Country Detection**
   - Reverse geocoding for automatic country detection
   - Correct emergency number for user's location

2. **Voice AI Integration**
   - AI speaks to emergency dispatcher
   - Provides automated incident report
   - GPS coordinates, impact data, victim status

3. **Sensor Fusion**
   - Accelerometer activity detection
   - Gyroscope orientation changes
   - Proximity sensor (phone picked up)

4. **Machine Learning**
   - Learn user movement patterns
   - Detect abnormal stillness
   - Reduce false positives over time

5. **Emergency Contact Escalation**
   - Call emergency contacts first
   - If no response, call 911
   - Multi-tiered escalation

---

## 📚 Related Documentation

- `REAL_PING_TESTING_GUIDE.md` - SOS testing procedures
- `SAR_DASHBOARD_REBUILD_COMPLETE.md` - SAR team integration
- `SOS_RESET_FIX_GUIDE.md` - SOS troubleshooting
- `AI_HAZARD_INTEGRATION_COMPLETE.md` - AI Safety Assistant

---

## 🤝 Contributing

When modifying the AI Emergency Call System:
1. **Test thoroughly** - False positives = 911 abuse
2. **Log everything** - AI decisions must be auditable
3. **Consider edge cases** - What if GPS fails? No internet?
4. **Document changes** - Update this file with any changes

---

## ⚠️ Legal & Safety Considerations

### Important Notes
1. **User Must Press Call**: App pre-fills number, user presses final "Call" button (legal requirement)
2. **False Alarms**: Sophisticated verification to minimize false 911 calls
3. **Liability**: System is assistive, not medical device
4. **Emergency Number**: Verify correct number for deployment region
5. **Testing**: NEVER test with real emergency numbers, use test numbers

### Disclaimer
This AI system is designed to assist in emergencies but should not replace professional medical advice or emergency services. Users should always seek immediate medical attention in serious emergencies.

---

## 📊 System Metrics

| Metric | Value |
|--------|-------|
| **Lines of Code** | 468 lines |
| **Verification Stages** | 5 stages |
| **Check Interval** | 15 seconds |
| **Initial Window** | 30 seconds |
| **SAR Timeout** | 3 minutes |
| **Total Timeout** | 5 minutes |
| **Movement Threshold** | 5 meters |
| **Max Verification Attempts** | 3 attempts |
| **Supported Countries** | 15+ countries |
| **Emergency Numbers** | 10+ different numbers |

---

**🚨 AI Emergency Call System - Saving Lives Through Intelligent Automation 🚨**

*Built with ❤️ for RedPing v14*
