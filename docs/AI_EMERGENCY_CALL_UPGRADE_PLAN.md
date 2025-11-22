# RedPing AI Emergency Call Services - Comprehensive Upgrade Plan

## Executive Summary

This document outlines the upgraded AI emergency call services logic for RedPing, addressing platform limitations while maximizing emergency response effectiveness through WebRTC, SMS, and intelligent notification management.

---

## 1. Core Architecture Changes

### 1.1 Call Priority System (Updated)

```
Priority 1: WebRTC Voice Call to SAR Team/RedPing Users
Priority 2: Traditional Phone Call to User Emergency Contacts
Priority 3: SMS Notification to Emergency Contacts
Priority 4: Push Notifications (Smart Escalation)
```

### 1.2 Platform Limitation Workarounds

**Android/iOS Auto-Call Restrictions:**
- ❌ Cannot auto-dial emergency hotlines (911/000) - **CRITICAL LIMITATION FOR UNCONSCIOUS USERS**
- ❌ Cannot auto-dial regular phone numbers without user interaction
- ❌ Opening dialer requires manual tap to complete call - **FATAL FLAW FOR UNRESPONSIVE VICTIMS**
- ✅ CAN use WebRTC for app-to-app calls (no platform restrictions)
- ✅ CAN send SMS programmatically (**PRIMARY SAFETY MECHANISM**)
- ✅ CAN send push notifications
- ✅ CAN display emergency UI to prompt manual calling (limited effectiveness)

**Implementation Reality:**
- SMS alerts to emergency contacts are the **only fully automatic** emergency response
- Emergency dialer trigger cannot help unconscious users (requires manual tap)
- WebRTC to SAR teams works but relies on team availability
- No workaround exists for auto-dialing emergency services within platform constraints

---

## 2. Emergency Response Flow

### Phase 1: SOS Activation (0-10 seconds)

```mermaid
SOS Activated
    ↓
[Immediate Actions - Parallel]
    ├─→ Create Firestore SOS Session
    ├─→ Start Location Tracking (high accuracy)
    ├─→ Capture Device Context (speed, altitude, battery, etc.)
    ├─→ Initialize WebRTC Service
    └─→ Prepare Emergency Message Template
```

**Implementation:**
- Status: `countdown` → `active`
- Store: Session ID, timestamp, location, user profile
- Generate: AI emergency message with context

---

### Phase 2: SAR Team Notification (10-30 seconds)

```mermaid
Active SOS Session
    ↓
[WebRTC Call to SAR Team]
    ├─→ Find Available SAR Members (online status)
    ├─→ Initiate WebRTC Call (Priority 1)
    ├─→ AI Voice Announcement
    │   "Emergency alert from [User Name]"
    │   "Location: [Address/Coordinates]"
    │   "Situation: [Detected Activity]"
    │   "Speed: [X] km/h, Altitude: [Y]m"
    └─→ Wait for SAR Acknowledgment
```

**AI Voice Message Template:**
```
"Emergency alert from {userName}.
Accident detected at {timestamp}.
Type: {accidentType} - {description}
Current location: {address}
Coordinates: {latitude}, {longitude}
Speed: {speed} km/h
Altitude: {altitude} meters
Battery: {batteryLevel}%
Please acknowledge receipt and respond immediately."
```

**WebRTC Features:**
- Auto-answer for SAR team (configurable)
- Two-way voice communication
- Background call capability
- Reconnection on network drop
- Call recording (optional, with consent)

---

### Phase 3: Emergency Contact SMS Blast (30-45 seconds)

```mermaid
If SAR Not Available or No Response
    ↓
[Send SMS to Emergency Contacts]
    ↓
SMS Content:
"🚨 EMERGENCY! {userName} has triggered SOS.
Type: {accidentType}
Time: {timestamp}
Location: {googleMapsLink}
Phone: {userPhone}

URGENT ACTIONS:
1. Call {userName} at {userPhone} to verify
2. If no response, call emergency: 911/000
3. Monitor RedPing app for updates

Cancel: Press & hold RedPing button 5s in app
or visit SAR Dashboard → Resolve

Next update in 2 minutes."
```

**SMS Details:**
- Priority contacts: Top 3 from user's emergency contact list
- Include: Name, phone, relation, timestamp
- Google Maps link with coordinates
- Battery level and device info
- Estimated response time

---

### Phase 4: Push Notification Escalation (Smart Timing)

#### 4.1 Initial Phase (Active Status)

**Frequency:** Every 2 minutes
**Duration:** Until SAR acknowledgment

```json
{
  "title": "🚨 SOS ACTIVE - {userName}",
  "body": "{accidentType} detected. Help dispatched.",
  "priority": "high",
  "sound": "emergency_alert.mp3",
  "actions": [
    { "id": "acknowledge", "title": "I'm Responding" },
    { "id": "view_location", "title": "View Location" },
    { "id": "call_user", "title": "Call Now" }
  ],
  "data": {
    "sosSessionId": "{sessionId}",
    "latitude": "{lat}",
    "longitude": "{lon}",
    "timestamp": "{timestamp}"
  }
}
```

**Recipients:**
1. All SAR team members within 50km
2. User's emergency contacts
3. Nearby RedPing community users (opt-in)

#### 4.2 Acknowledged Phase (Acknowledged/Assigned/En Route Status)

**Frequency:** Every 10 minutes
**Duration:** Until on-scene or resolved

```json
{
  "title": "📍 SOS Update - {userName}",
  "body": "SAR team responding. ETA: {estimatedTime}",
  "priority": "normal",
  "data": {
    "sosSessionId": "{sessionId}",
    "sarTeamId": "{responderId}",
    "status": "acknowledged"
  }
}
```

#### 4.3 Resolution Phase (On Scene/Resolved Status)

**Frequency:** Final notification only

```json
{
  "title": "✅ SOS Resolved - {userName}",
  "body": "Emergency concluded. All responders stood down.",
  "priority": "normal"
}
```

---

## 3. Enhanced SMS Logic

### 3.1 SMS Template System

**SMS #1 - Initial Alert (0 min):**
```
🚨 EMERGENCY ALERT
User: {userName}
Type: {accidentType}
Time: {HH:MM AM/PM}
Location: {address}
Map: {shortLink}
Phone: {userPhone}

ACTION REQUIRED:
1. Call {userName}: {userPhone}
2. If unreachable → 911/000
3. Share location with responders

Cancel: App → Hold RedPing 5s
Track: {appDeepLink}

Alert #1 of 5
```

**SMS #2 - Follow-up (2 min):**
```
⚠️ SOS ONGOING - {userName}
Status: Waiting for response
Location updated: {address}
Battery: {battery}%
Speed: {speed} km/h

No response yet. Please:
→ Call {userPhone}
→ Check RedPing app
→ Contact 911 if needed

Alert #2 of 5 • Next in 2 min
```

**SMS #3 - Escalation (4 min):**
```
🚨 URGENT - {userName} SOS
No acknowledgment received
Time elapsed: 4 minutes

IMMEDIATE ACTION NEEDED:
→ Call emergency: 911/000
→ Provide location: {coordinates}
→ Mention: Unresponsive alert

Cancel in app or call:
{supportPhone}

Alert #3 of 5
```

**SMS #4+ - Acknowledged:**
```
✓ SAR RESPONDING - {userName}
Responder: {sarName}
Status: En route
ETA: {estimatedMinutes} min

You can:
→ Track in app: {deepLink}
→ Contact SAR: {sarPhone}
→ View updates

Alert #4 • Next in 10 min
```

**SMS Final - Resolved:**
```
✅ SOS RESOLVED - {userName}
Status: Safe
Time: {HH:MM AM/PM}
Duration: {durationMinutes} min

Emergency concluded.
No further action needed.

Thank you for your response.
RedPing Team
```

### 3.2 SMS Rate Limiting

```javascript
const SMS_SCHEDULE = {
  active: {
    interval: 120, // 2 minutes
    maxCount: 10,
    priority: "high"
  },
  acknowledged: {
    interval: 600, // 10 minutes
    maxCount: 6,
    priority: "medium"
  },
  resolved: {
    interval: null, // One-time only
    maxCount: 1,
    priority: "low"
  }
};
```

---

## 4. Emergency Hotline Integration (Manual Only)

### 4.1 UI Prompt System

**When SOS Activated - Show Emergency Call Card:**

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.red.shade900,
    border: Border.all(color: Colors.red, width: 2),
  ),
  child: Column(
    children: [
      Text("EMERGENCY HOTLINE"),
      Text("Tap to call 911/000", style: largeFont),
      ElevatedButton(
        onPressed: () => launchUrl("tel:911"),
        child: Text("CALL 911"),
      ),
      Text("RedPing cannot auto-dial emergency services"),
    ],
  ),
);
```

**Features:**
- Large, prominent button
- Clear instructions
- One-tap to dial
- Regional number detection (911 US, 000 AU, 112 EU, etc.)
- Voice prompt: "Would you like to call emergency services?"

### 4.2 Regional Emergency Numbers

```dart
const EMERGENCY_NUMBERS = {
  'US': '911',
  'AU': '000',
  'EU': '112',
  'UK': '999',
  'IN': '112',
  'CA': '911',
  'JP': '119',
};

String getEmergencyNumber(String countryCode) {
  return EMERGENCY_NUMBERS[countryCode] ?? '911';
}
```

---

## 5. WebRTC Call Implementation

### 5.1 Auto-Answer for SAR Team

```dart
class WebRTCCallConfig {
  bool autoAnswerForSAR = true;
  int ringDurationSec = 30;
  bool enableAI_TTS = true;
  bool recordCall = false; // Requires consent
  int maxCallDurationMin = 60;
}
```

### 5.2 AI Voice Integration

**Initial Announcement (TTS):**
```dart
void speakEmergencyDetails(SOSSession session) {
  final message = '''
    Emergency alert from ${session.userName}.
    Accident type: ${session.accidentType}.
    Location: ${session.address}.
    Time: ${formatTime(session.timestamp)}.
    Current speed: ${session.speed} kilometers per hour.
    Battery level: ${session.battery} percent.
    Please acknowledge and respond.
  ''';
  
  flutterTts.speak(message);
}
```

**Periodic Updates (Every 30 sec during call):**
```dart
void speakLocationUpdate(SOSSession session) {
  final message = '''
    Location update.
    Moving at ${session.speed} kilometers per hour.
    Current position: ${session.latitude}, ${session.longitude}.
  ''';
  
  flutterTts.speak(message);
}
```

---

## 6. Cancellation & Resolution Logic

### 6.1 User-Initiated Cancellation

**Method 1: Press & Hold RedPing Button (5 seconds)**

```dart
void onSOSReset() async {
  // Show confirmation
  final confirmed = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Cancel SOS?"),
      content: Text("Are you sure you want to cancel the emergency alert?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("No, Keep Active"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Yes, Cancel SOS"),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    await cancelSOS();
  }
}

Future<void> cancelSOS() async {
  // 1. Update Firestore status
  await FirebaseFirestore.instance
      .collection('sos_sessions')
      .doc(currentSessionId)
      .update({
    'status': 'cancelled',
    'endTime': FieldValue.serverTimestamp(),
    'cancelReason': 'user_initiated',
  });
  
  // 2. End WebRTC calls
  await webrtcService.endCall();
  
  // 3. Send cancellation SMS
  await sendCancellationSMS();
  
  // 4. Stop push notifications
  await stopNotifications(currentSessionId);
  
  // 5. Update UI
  setState(() {
    isSOSActive = false;
    currentSession = null;
  });
  
  // 6. Show confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("SOS cancelled. All responders notified.")),
  );
}
```

**Cancellation SMS:**
```
✅ SOS CANCELLED - {userName}
User has cancelled emergency alert.
Time: {HH:MM AM/PM}
Reason: User-initiated

No action needed.
All responders stood down.

RedPing Team
```

### 6.2 SAR-Initiated Resolution

**Method 2: SAR Dashboard → Resolve Button**

```dart
Future<void> resolveSOSSession(String sessionId, String resolution) async {
  // Update session
  await FirebaseFirestore.instance
      .collection('sos_sessions')
      .doc(sessionId)
      .update({
    'status': 'resolved',
    'endTime': FieldValue.serverTimestamp(),
    'resolution': resolution,
    'resolvedBy': currentSARUserId,
  });
  
  // Send resolution SMS
  await sendResolutionSMS(sessionId, resolution);
  
  // Stop notifications
  await stopNotifications(sessionId);
  
  // Log analytics
  await logSOSResolution(sessionId);
}
```

**Resolution SMS:**
```
✅ SOS RESOLVED - {userName}
SAR Team: {sarTeamName}
Resolution: {resolutionSummary}
Duration: {durationMinutes} min

All clear. No further action needed.

Thank you for your support.
RedPing SAR Team
```

---

## 7. Notification Management Service

### 7.1 Smart Notification Scheduler

```dart
class NotificationScheduler {
  Timer? _activeTimer;
  Timer? _acknowledgedTimer;
  String? _currentSessionId;
  int _notificationCount = 0;
  
  void startActivePhase(String sessionId) {
    _currentSessionId = sessionId;
    _notificationCount = 0;
    
    // Send immediate notification
    sendNotification(sessionId);
    
    // Schedule every 2 minutes
    _activeTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (_notificationCount < 10) {
        sendNotification(sessionId);
        _notificationCount++;
      } else {
        // Auto-escalate after 20 minutes
        escalateToAuthorities(sessionId);
        timer.cancel();
      }
    });
  }
  
  void switchToAcknowledgedPhase() {
    _activeTimer?.cancel();
    _notificationCount = 0;
    
    // Schedule every 10 minutes
    _acknowledgedTimer = Timer.periodic(Duration(minutes: 10), (timer) {
      if (_notificationCount < 6) {
        sendUpdateNotification(_currentSessionId!);
        _notificationCount++;
      } else {
        timer.cancel();
      }
    });
  }
  
  void stopAll() {
    _activeTimer?.cancel();
    _acknowledgedTimer?.cancel();
    sendFinalNotification(_currentSessionId!);
    _currentSessionId = null;
    _notificationCount = 0;
  }
}
```

### 7.2 Notification Content by Phase

**Active Phase (0-20 min):**
- Title: 🚨 **URGENT** - SOS Active
- Sound: Loud emergency alert
- Vibration: Long continuous
- Priority: MAX
- Bypass Do Not Disturb: YES

**Acknowledged Phase (20+ min):**
- Title: 📍 **UPDATE** - SAR Responding  
- Sound: Standard notification
- Vibration: Normal
- Priority: HIGH
- Bypass Do Not Disturb: NO

**Resolved Phase (Final):**
- Title: ✅ **RESOLVED** - Emergency Concluded
- Sound: Success chime
- Vibration: Short single
- Priority: NORMAL
- Bypass Do Not Disturb: NO

---

## 8. Analytics & Logging

### 8.1 Tracked Metrics

```javascript
{
  "sosSessionId": "string",
  "userId": "string",
  "timestamps": {
    "sosActivated": "datetime",
    "firstWebRTCCall": "datetime",
    "sarAcknowledged": "datetime",
    "firstSMSSent": "datetime",
    "resolved": "datetime"
  },
  "responses": {
    "sarCallAnswered": "boolean",
    "emergencyContactCalled": "boolean",
    "userCancelled": "boolean",
    "falseAlarm": "boolean"
  },
  "metrics": {
    "timeToAcknowledgment": "seconds",
    "totalDuration": "seconds",
    "smsCount": "number",
    "pushNotificationCount": "number",
    "webrtcCallDuration": "seconds"
  },
  "resolution": {
    "status": "resolved|cancelled|false_alarm",
    "resolvedBy": "user|sar|system",
    "outcome": "string"
  }
}
```

---

## 9. Additional Improvements

### 9.1 Location Sharing Enhancements

**Live Location Tracking:**
- Update every 30 seconds during active SOS
- Breadcrumb trail visualization
- Speed and direction indicators
- Geofencing alerts (if user moves >500m)

**Share Options:**
- Generate shareable link (24-hour expiry)
- QR code for quick access
- SMS link with embedded map
- Email report with full details

### 9.2 Multi-Language Support

```dart
const EMERGENCY_MESSAGES = {
  'en': 'Emergency alert',
  'es': 'Alerta de emergencia',
  'fr': 'Alerte d\'urgence',
  'de': 'Notfallalarm',
  'zh': '紧急警报',
  'ar': 'تنبيه طارئ',
};
```

### 9.3 Accessibility Features

- **Voice Commands:** "RedPing, emergency!" activates SOS
- **Large Touch Targets:** Easy activation for impaired users
- **High Contrast Mode:** Better visibility in stress
- **Screen Reader Support:** Full TalkBack/VoiceOver integration

### 9.4 False Alarm Prevention

```dart
void onSOSActivated() async {
  // Show 10-second countdown
  final cancelled = await showCountdownDialog(
    duration: 10,
    message: "SOS will activate in:",
    allowCancel: true,
  );
  
  if (!cancelled) {
    activateSOS();
  }
}
```

### 9.5 Battery Optimization

**During Active SOS:**
- Increase GPS frequency (high accuracy)
- Keep screen awake
- Disable background app restrictions
- Priority wake locks

**During Acknowledged SOS:**
- Reduce GPS to every 60 seconds
- Allow screen timeout
- Normal power management

**After Resolution:**
- Return to normal power mode
- Stop all tracking services

---

## 10. Implementation Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Update WebRTC service for SAR priority calls
- [ ] Implement SMS template system
- [ ] Create notification scheduler service
- [ ] Build cancellation logic (5-second hold)
- [ ] Add emergency hotline UI prompts

### Phase 2: SMS & Notifications (Week 3-4)
- [ ] Implement smart SMS escalation
- [ ] Add 2-minute active phase notifications
- [ ] Add 10-minute acknowledged phase notifications
- [ ] Build final resolution notifications
- [ ] Test rate limiting and scheduling

### Phase 3: SAR Dashboard (Week 5-6)
- [ ] Add resolve button to SAR dashboard
- [ ] Implement session status updates
- [ ] Build resolution form (outcome, notes)
- [ ] Add analytics tracking
- [ ] Test cross-user notification stops

### Phase 4: Testing & Refinement (Week 7-8)
- [ ] End-to-end SOS flow testing
- [ ] Network interruption testing
- [ ] Battery drain analysis
- [ ] Load testing (multiple concurrent SOS)
- [ ] User acceptance testing

### Phase 5: Documentation & Launch (Week 9-10)
- [ ] User guide for emergency contacts
- [ ] SAR team training materials
- [ ] Legal compliance review
- [ ] Beta launch with select users
- [ ] Monitor and iterate

---

## 11. Compliance & Legal

### 11.1 Required Disclaimers

```
⚠️ IMPORTANT LEGAL NOTICE

RedPing is a supplementary emergency response tool and should 
NOT replace traditional emergency services (911/000).

- Cannot auto-dial emergency hotlines (platform limitation)
- Requires cellular/data connection for SMS/notifications
- SAR team availability not guaranteed
- Response times may vary by location

Always call 911/000 directly for life-threatening emergencies.

By using RedPing, you acknowledge these limitations.
```

### 11.2 User Consent

**Required Consents:**
- [ ] Emergency contact SMS notifications
- [ ] Location sharing with SAR team
- [ ] Push notifications (critical alerts)
- [ ] Call recording (optional)
- [ ] Data sharing with emergency responders

---

## 12. Cost Analysis

### 12.1 Per-SOS-Session Costs

| Service | Cost per Use | Monthly (100 SOS) |
|---------|-------------|-------------------|
| WebRTC (Agora) | $0.01/min | $10-30 |
| SMS (Twilio) | $0.02/SMS | $20-60 |
| Push Notifications (FCM) | Free | $0 |
| Firestore Writes | $0.18/100K | $1-5 |
| Storage | $0.026/GB | $1-3 |
| **TOTAL** | **~$0.50** | **$32-98** |

**Scalability:** Costs scale linearly with usage. Break-even at ~200 paid users.

---

## 13. Success Metrics

### 13.1 Key Performance Indicators (KPIs)

- **Response Time:** Average time to SAR acknowledgment < 2 minutes
- **False Alarm Rate:** < 5% of total SOS activations
- **User Cancellation:** User cancels within 10 seconds (false alarm prevention working)
- **SMS Delivery:** > 99% delivery rate within 30 seconds
- **Push Notification:** > 95% delivery rate
- **WebRTC Connection:** > 90% successful call establishment
- **Resolution Time:** Average SOS duration < 30 minutes

---

## Conclusion

This comprehensive upgrade plan addresses all platform limitations while maximizing emergency response effectiveness through:

1. **WebRTC-First Architecture:** Leverages app-to-app calling for SAR team
2. **Smart SMS Escalation:** Automated, contextual messages to emergency contacts
3. **Intelligent Notification Management:** Frequency adjusts based on SOS status
4. **User-Friendly Cancellation:** 5-second hold + SAR dashboard resolve
5. **Legal Compliance:** Clear disclaimers about auto-dial limitations

**Next Steps:**
1. Review and approve this plan
2. Prioritize features (MVP vs. future)
3. Assign development resources
4. Begin Phase 1 implementation

---

**Document Version:** 1.0  
**Last Updated:** November 12, 2025  
**Author:** RedPing Development Team  
**Status:** Pending Approval
