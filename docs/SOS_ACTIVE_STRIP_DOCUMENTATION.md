# SOS Active Strip Documentation

**Date**: November 13, 2025  
**Location**: `lib/features/sos/presentation/pages/sos_page.dart`  
**Widget**: `_buildSOSActiveActionStrip()`  
**Display Condition**: `if (_isSOSActive)` - Only visible when SOS session is active

---

## Overview

The **SOS Active Strip** is a compact emergency action panel that appears above the RedPing button when an SOS session is active. It provides immediate access to all critical emergency actions and displays real-time status updates from SAR teams.

**Key Principle**: Single source of truth - displays only when `_isSOSActive == true`, which reflects actual SOS session state from SOSService.

---

## Visual Structure

### 1. Header Section
- **Pulsing Red Indicator**: Animated circular dot with glow effect using `_beaconAnimation`
- **"SOS ACTIVE" Label**: Bold white text with letter spacing (1.2)
- **"Emergency Active" Badge**: Semi-transparent white badge on the right

### 2. Status Indicator Row

Shows real-time SAR team status with animated icon and color-coded display:

#### Status States:

**Default State** (No responder assigned):
```
Status: "Emergency Alert Sent"
Description: "SAR teams have been notified"
Color: Orange (AppTheme.warningOrange)
Icon: Icons.radar
```

**Responder Assigned** (metadata contains `responderName`):
```
Status: "Responder Assigned"
Description: "SAR: [responderName]"
Color: Blue (AppTheme.infoBlue)
Icon: Icons.support_agent
```

**SAR Team Responding** (rescueTeamResponses[].status == acknowledged):
```
Status: "SAR Team Responding"
Description: "Team acknowledged emergency"
Color: Orange (AppTheme.warningOrange)
Icon: Icons.notifications_active
```

**Help En Route** (rescueTeamResponses[].status == enRoute):
```
Status: "Help En Route"
Description: "Team is on the way"
Color: Blue (AppTheme.infoBlue)
Icon: Icons.directions_run
```

**Responders On Scene** (rescueTeamResponses[].status == onScene):
```
Status: "Responders On Scene"
Description: "Team has arrived"
Color: Green (AppTheme.safeGreen)
Icon: Icons.local_hospital
```

### 3. Primary Action Buttons Row

**Updated: November 13, 2025 - Comprehensive Messaging & Call System**

Three primary emergency action buttons with enhanced functionality:

#### Button 1: Emergency Call (Enhanced)
- **Color**: Red (#FF4757)
- **Icon**: `Icons.phone`
- **Label**: Local emergency number (911, 000, 112, etc.)
- **Action**: `_showEmergencyCallOptions()` - Opens comprehensive call menu
- **Tooltip**: "Emergency Call Options"
- **Layout**: Expanded (takes equal width)
- **Features**:
  - Call emergency services (911/000/112)
  - View and call emergency contacts list
  - Call history logging
  - Priority-sorted contact display

#### Button 2: Chat (Real-time)
- **Color**: Green (#2ECC71)
- **Icon**: `Icons.chat_bubble_rounded`
- **Label**: "Chat"
- **Action**: `_openSOSChat` - Opens real-time chat with SAR team
- **Tooltip**: "Open Chat with SAR"
- **Layout**: Expanded (takes equal width)
- **Features**:
  - Real-time messaging with SAR team
  - Message history
  - Read receipts
  - Typing indicators

#### Button 3: Send Message (Quick Messages)
- **Color**: Orange (#F39C12)
- **Icon**: `Icons.send_rounded`
- **Label**: "Send"
- **Action**: `_sendSOSMessage()` - Opens quick message selector
- **Tooltip**: "Quick Message"
- **Layout**: Expanded (takes equal width)
- **Features**:
  - "I'm okay" - Situation under control
  - "Need medical help" - Request immediate assistance
  - "Send my location" - Share GPS coordinates
  - "Situation worsening" - Alert team of deterioration
  - Custom message option

---

### 4. Secondary Action Buttons Row (NEW)

Three additional support buttons for extended functionality:

#### Button 1: Emergency Contacts
- **Icon**: `Icons.contact_phone`
- **Label**: "Contacts"
- **Action**: `_showEmergencyContactCallOptions()` - Quick access to contacts
- **Tooltip**: "Call Emergency Contacts"
- **Layout**: Compact with inline icon and text
- **Features**:
  - Priority-sorted contact list
  - One-tap call functionality
  - Contact management link if empty
  - Contact details display

#### Button 2: Share Location
- **Icon**: `Icons.location_on`
- **Label**: "Location"
- **Action**: `_shareCurrentLocation()` - Opens location sharing menu
- **Tooltip**: "Share Current Location"
- **Layout**: Compact with inline icon and text
- **Features**:
  - Send to SAR chat
  - Send via SMS to all emergency contacts
  - Open in Google Maps
  - GPS coordinates display
  - Real-time location updates

#### Button 3: Medical Info
- **Icon**: `Icons.medical_services`
- **Label**: "Medical"
- **Action**: `_showMedicalInfo()` - Display medical information
- **Tooltip**: "Medical Information"
- **Layout**: Compact with inline icon and text
- **Features**:
  - Medical conditions
  - Allergies
  - Medications
  - Blood type
  - Emergency medical notes

---

## WebRTC Functionality Status

**STATUS: DISABLED (November 13, 2025)**

WebRTC call functionality has been disabled to focus on SMS-based emergency notifications. The following components are commented out:

### Disabled Components:
1. **`_buildWebRTCCallButton()`** - Blue WebRTC call button widget
2. **`_buildActiveCallIndicator()`** - Green call active indicator widget
3. **`_startSOSWebRTCCall()`** - WebRTC call initiation function

### Location in Code:
- File: `lib/features/sos/presentation/pages/sos_page.dart`
- Lines: ~3798-4145 (marked with WEBRTC DISABLED comments)
- Action Strip: Line ~2680 (WebRTC button removed, 3 buttons now expanded)

### To Re-enable WebRTC:
1. Uncomment WebRTC widget methods (lines 3798-3893)
2. Uncomment `_startSOSWebRTCCall()` function (lines 3947-4135)
3. Restore WebRTC button in action strip (line 2680)
4. Change buttons back from `Expanded` wrappers to mixed layout

---

## Design Specifications

### Container:
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ],
)
```

### Padding:
- Container padding: `16px` all sides
- Internal spacing: `12px` between sections

### Animation:
- Uses `_beaconAnimation` (CurvedAnimation with Curves.easeInOut)
- Pulsing effect on:
  - Red indicator dot
  - Status icon background
  - Status icon shadow

---

## Emergency Number Detection

Function: `_getEmergencyNumber()`

Returns localized emergency number based on country code:
- **AU**: 000 (Australia)
- **US**: 911 (United States)
- **GB**: 999 (United Kingdom)
- **NZ**: 111 (New Zealand)
- **EU**: 112 (Most European countries)
- **Default**: 911

Detection method: Uses device locale to determine country code.

---

## Code Location

**File**: `lib/features/sos/presentation/pages/sos_page.dart`

**Widget Method**: Lines 2491-2716
```dart
Widget _buildSOSActiveActionStrip()
```

**Display Location**: Line 1018
```dart
if (_isSOSActive) _buildSOSActiveActionStrip(),
```

**Helper Methods**:

**Widget Builders:**
- `_buildCompactActionButton()` - Primary action button builder (active)
- `_buildSecondaryActionButton()` - Secondary action button builder (NEW)
- `_buildEmergencyContactsList()` - Emergency contacts widget (NEW)

**Call Functions:**
- `_showEmergencyCallOptions()` - Comprehensive call menu (NEW)
- `_callEmergencyContact()` - Call specific contact with logging (NEW)
- `_showEmergencyContactCallOptions()` - Quick contact access (NEW)
- `_makeEmergencyCall()` - Direct emergency service call (active)
- `_getEmergencyNumber()` - GPS-based emergency number detection (active)

**Messaging Functions:**
- `_sendSOSMessage()` - Quick message selector (enhanced)
- `_sendQuickMessage()` - Send predefined message (active)
- `_showCustomMessageDialog()` - Custom message input (active)
- `_openSOSChat()` - Real-time SAR chat (active)

**Location Functions:**
- `_shareCurrentLocation()` - Location sharing menu (NEW)
- `_sendLocationViaSMS()` - SMS location broadcast (NEW)

**Medical Functions:**
- `_showMedicalInfo()` - Medical information display (active)

**Disabled (WebRTC):**
- ~~`_buildActiveCallIndicator()`~~ - **DISABLED**
- ~~`_buildWebRTCCallButton()`~~ - **DISABLED**
- ~~`_startSOSWebRTCCall()`~~ - **DISABLED**

---

## State Dependencies

### Required State Variables:
- `_isSOSActive` (bool) - Controls strip visibility
- `_currentSession` (SOSSession?) - Provides status data
- `_beaconAnimation` (Animation<double>) - Pulsing animation

### External Service Dependencies:
- ~~`_serviceManager.phoneAIIntegrationService.isWebRTCInCall`~~ - **DISABLED** (WebRTC removed)
- `_currentSession.rescueTeamResponses` - SAR team response array
- `_currentSession.metadata['responderName']` - Assigned responder info

---

## Architecture Compliance

### Single Source of Truth:
✅ Strip displays only when `_isSOSActive == true`  
✅ `_isSOSActive` reflects actual SOSService session state  
✅ No separate UI state management  
✅ Status updates come from Firestore listener in SOSService  

### Blueprint Alignment:
- Complies with **SOS_RULES_AND_ENFORCEMENT.md**
- Single active session rule enforced
- Button state reflects actual session state
- Real-time status updates from SAR dashboard

---

## User Experience Flow

### 1. SOS Activation:
```
User holds button 10s → SOS activates → _isSOSActive = true → Strip appears
```

### 2. During Active SOS:
```
Strip visible → Shows status updates → Provides quick actions → Updates in real-time
```

### 3. SOS Resolution:
```
SAR resolves session → _isSOSActive = false → Strip disappears
```

---

## Future Considerations

### Potential Adjustments:
- Re-enable WebRTC functionality when ready
- Add elapsed time display
- Add battery level indicator
- Add location accuracy indicator
- Add SMS notification status
- Add emergency contact call buttons
- Consider 4-button layout if WebRTC restored

### Performance:
- Animation runs continuously when visible
- Firestore updates trigger status text changes
- No known performance issues

---

## Testing Checklist

### Core Functionality:
- [ ] Strip appears immediately when SOS activates
- [ ] Strip disappears when SOS session ends
- [ ] Status updates reflect Firestore changes in real-time
- [ ] Pulsing animation runs smoothly
- [ ] Strip persists across app restarts (if session active)
- [ ] Strip respects single source of truth (_isSOSActive only)

### Primary Buttons:
- [ ] Emergency call button shows correct local number (GPS-based)
- [ ] Emergency call menu displays correctly
- [ ] Emergency services call works
- [ ] Emergency contacts list displays with priority sorting
- [ ] Individual contact calls work
- [ ] Chat button opens real-time SAR chat
- [ ] Chat messages send and receive correctly
- [ ] Send button opens quick message menu
- [ ] All predefined messages work
- [ ] Custom message dialog accepts input

### Secondary Buttons:
- [ ] Contacts button opens emergency contact list
- [ ] Empty contacts shows "Add Contacts" prompt
- [ ] Contact call buttons work
- [ ] Location button opens share menu
- [ ] "Send to SAR Chat" shares location link
- [ ] "Send via SMS" broadcasts to all contacts
- [ ] "Open in Maps" launches Google Maps
- [ ] GPS coordinates display correctly
- [ ] Medical button displays medical information

### Integration:
- [ ] Call attempts logged to Firestore
- [ ] SMS service integrates correctly
- [ ] Location updates are real-time
- [ ] Emergency contacts sync from profile
- [ ] Three primary buttons have equal width (Expanded layout)
- [ ] Three secondary buttons have compact layout
- [ ] All tooltips display correctly
- [ ] All animations and transitions smooth

### Error Handling:
- [ ] Graceful handling when no emergency contacts configured
- [ ] Location unavailable message shows correctly
- [ ] Failed calls show error messages
- [ ] Failed SMS shows error messages
- [ ] Network errors handled gracefully

---

## Related Documentation

- `SOS_RULES_AND_ENFORCEMENT.md` - SOS session rules and state management
- `webrtc_integration_summary.md` - WebRTC call integration
- `STATUS_INDICATOR_TROUBLESHOOTING.md` - Status update debugging

---

## Summary of Changes (November 13, 2025)

### Major Enhancements:
1. **Comprehensive Call System**
   - Emergency services call menu
   - Priority-sorted emergency contacts
   - One-tap contact calling
   - Call activity logging

2. **Enhanced Messaging**
   - Quick message templates
   - Custom message option
   - Real-time SAR chat integration
   - SMS broadcast to all contacts

3. **Location Sharing**
   - Multiple sharing methods (Chat, SMS, Maps)
   - GPS coordinates display
   - Real-time location updates
   - Google Maps integration

4. **Secondary Action Row**
   - Emergency contacts quick access
   - Location sharing button
   - Medical information button
   - Compact, space-efficient design

5. **WebRTC Disabled**
   - Removed WebRTC call button
   - Isolated WebRTC code for future restoration
   - Focus on proven SMS/call/chat methods

---

**Last Updated**: November 13, 2025  
**Status**: Comprehensive call & messaging system active  
**Layout**: 3 primary buttons + 3 secondary buttons  
**Change**: Enhanced from basic 3-button to full communication suite
