# SOS Status Indicator Troubleshooting Guide

## 📱 Expected Behavior

The SOS status indicator should appear on the homepage **only when an SOS session is active**.

### Visual Location:
```
┌─────────────────────────────────────┐
│  ⚠ Emergency Use Only  [Status Badge] │  ← Status indicator here
├─────────────────────────────────────┤
│                                     │
│         (SOS Button)                │
│                                     │
└─────────────────────────────────────┘
```

## 🔍 When Status Indicator Shows

The status indicator will show **ONLY** when:
1. ✅ User presses SOS button for 10 seconds (countdown complete)
2. ✅ SOS becomes **ACTIVE** (not just countdown)
3. ✅ `_currentSession != null`
4. ✅ Session has valid `id`, `status`, `rescueTeamResponses`, or `metadata`

### Status Indicator Does NOT Show:
- ❌ During countdown (first 10 seconds)
- ❌ When no SOS is active
- ❌ After SOS is resolved/ended
- ❌ When `_currentSession == null`

## 🎯 Test Steps to See Status Indicator

### Step 1: Activate SOS
```
1. Open RedPing app
2. Go to SOS page (homepage)
3. Press and HOLD the red SOS button
4. Wait for 10-second countdown
5. SOS activates
```

### Step 2: Verify Status Indicator Appears
```
Expected after countdown:
┌─────────────────────────────────────┐
│  ⚠ Emergency Use Only  🔴 Active │  ← Status indicator visible!
├─────────────────────────────────────┤
```

### Step 3: Test Real-time Updates
```
1. Keep mobile app open
2. Open SAR dashboard on computer
3. Click "Acknowledge" → Mobile shows "🚨 SAR Notified"
4. Click "En Route" → Mobile shows "🚁 Help En Route"
5. Click "On Scene" → Mobile shows "✅ Help On Scene"
```

## 🐛 Troubleshooting: Status Indicator Not Showing

### Issue 1: Status Indicator Never Appears

**Symptom**: No status badge even after SOS activates

**Diagnosis**:
```dart
// Check these in logs:
- "SOS Page: Started real-time Firebase listener" ← Should appear
- "_currentSession != null" ← Should be true
- "SOS Service Callbacks: _onSOSSessionStarted" ← Should fire
```

**Possible Causes**:
1. ❌ SOS didn't actually activate (check countdown completion)
2. ❌ `_currentSession` is null (session not created)
3. ❌ Layout overflow hiding the indicator
4. ❌ Session ID is empty string

**Solution**:
- Verify SOS countdown completes fully (10 seconds)
- Check terminal for "SOS Page: Started real-time Firebase listener for session [id]"
- If no Firebase listener message, session wasn't created properly

### Issue 2: Status Shows "Active" But Doesn't Update

**Symptom**: Shows "🔴 Active" but never changes when SAR team acts

**Diagnosis**:
```
Check Firebase Console:
1. Open Firestore
2. Navigate to sos_alerts collection
3. Find your session document
4. Check "rescueTeamResponses" array
5. Check "metadata" object
```

**Possible Causes**:
1. ❌ Firebase listener not started
2. ❌ SAR dashboard update failed
3. ❌ Firestore security rules blocking reads
4. ❌ Network connectivity issue

**Solution**:
- Check terminal for: "SOS Page: Real-time update from website SAR dashboard"
- Verify SAR dashboard shows no errors when clicking status buttons
- Test network: Toggle airplane mode off
- Check Firebase Console for actual updates

### Issue 3: Status Indicator Disappears Immediately

**Symptom**: Appears for 1 second then vanishes

**Possible Causes**:
1. ❌ Session ended prematurely
2. ❌ `_currentSession` set to null
3. ❌ SOS service crashed
4. ❌ State rebuild cleared session

**Solution**:
- Check for "SOS Page: Stopped Firebase listener" (shouldn't appear immediately)
- Look for any errors in terminal about session ending
- Verify SOS service is initialized

## 📊 Debug Logs to Check

### Successful SOS Activation:
```
I/flutter: SOSService: Starting SOS session...
I/flutter: SOSService: Session created with ID: [session_id]
I/flutter: SOS Page: Started real-time Firebase listener for session [session_id]
```

### Successful SAR Update:
```
I/flutter: SOS Page: Real-time update from website SAR dashboard
I/flutter: SOS Page: Status updated - acknowledged
```

### Session End:
```
I/flutter: SOS Page: Stopped Firebase listener
I/flutter: SOSService: Session ended
```

## 🔧 Manual Verification

### Check Firebase Console:

1. Open Firebase Console
2. Go to Firestore Database
3. Find collection: `sos_alerts`
4. Look for recent document with your user ID

### Expected Document Structure:
```json
{
  "id": "session_12345",
  "userId": "7PiSckg4viT88gut1NiZFtfzlmJ2",
  "status": "active",
  "metadata": {
    "responderId": null,
    "responderName": null
  },
  "rescueTeamResponses": [],
  "startTime": "2025-10-25T10:00:00Z"
}
```

### After SAR Acknowledges:
```json
{
  "rescueTeamResponses": [
    {
      "status": "acknowledged",
      "timestamp": "2025-10-25T10:05:00Z",
      "teamMember": {
        "id": "sar_user_123",
        "name": "John Smith"
      }
    }
  ]
}
```

## ✅ Verification Checklist

- [ ] SOS countdown completes (10 seconds)
- [ ] Terminal shows "Started real-time Firebase listener"
- [ ] Firebase Console shows document in `sos_alerts`
- [ ] Status indicator appears on mobile app
- [ ] Status shows "🔴 Active" initially
- [ ] SAR dashboard can see the alert
- [ ] Clicking "Acknowledge" on SAR dashboard → No errors
- [ ] Mobile app shows "🚨 SAR Notified" within 2 seconds
- [ ] Terminal shows "Real-time update from website"
- [ ] Status indicator updates color and text

## 🎨 Status Indicator Appearance

### Status Colors and Icons:

| SAR Action | Badge Text | Color | Icon | Implementation |
|-----------|-----------|-------|------|----------------|
| None | "Active" | 🔴 Red | emergency | ✅ Implemented |
| Acknowledged | "SAR Notified" | 🟠 Orange | notifications_active | ✅ Implemented |
| En Route | "Help En Route" | 🔵 Blue | directions_run | ✅ Implemented |
| On Scene | "Help On Scene" | 🟢 Green | local_hospital | ✅ Implemented |
| Completed | "Completed" | 🟢 Green | check_circle | ✅ Implemented |
| Responder Assigned | "Responder Assigned • Name" | 🔵 Blue | support_agent | ✅ Implemented |
| In Progress | "In Progress" | 🟢 Green | medical_services | ✅ Implemented |

### Status Update Priority Logic:

The status indicator follows this priority order:

1. **Responder Assignment** (Highest Priority)
   - If `metadata.responderName` exists → Show "Responder Assigned • [Name]"
   
2. **Rescue Team Responses**
   - If `rescueTeamResponses` array has entries → Show latest response status
   - Checks: acknowledged, en_route, on_scene, completed
   
3. **Session Status** (Fallback)
   - Uses `session.status` enum value
   - active, acknowledged, assigned, enRoute, onScene, inProgress

### Visual Style:
```
┌─────────────────────────────┐
│ [Icon] SOS Active           │  ← Dynamic color based on status
│                             │  ← Rounded corners (12px)
│   [Icon] Status Text        │  ← Status chip with icon
│   ━━━━━━━━━━━━━━━━━━━      │  ← Colored border (2px, 40% alpha)
│                             │  ← Colored background (20% alpha)
│   [Call] [Message SAR]      │  ← Shadow effect (8px blur, 15% alpha)
└─────────────────────────────┘
```

### Status Chip Enhancements:
- Border width: **2px** (increased from 1px)
- Border opacity: **40%** (increased from 30%)
- Background opacity: **20%** (increased from 15%)
- Icon size: **16px** (increased from 8px dot)
- Font weight: **700** (bold, increased from 600)
- Padding: **10px horizontal, 6px vertical**
- Shadow: **8px blur, 2px offset**

## 🚀 Quick Test Command

### Test Full Flow:
```
1. flutter run --hot
2. Wait for app to launch
3. Press SOS button (hold 10 seconds)
4. Wait for countdown
5. Check for status indicator appearance
6. Open SAR dashboard in browser
7. Click "Acknowledge"
8. Check mobile app for status update
```

### Expected Timeline:
```
0:00 - Press SOS button
0:10 - Countdown complete → SOS ACTIVE
0:11 - Status indicator appears: "🔴 Active"
0:15 - SAR team clicks "Acknowledge"
0:16 - Mobile shows: "🚨 SAR Notified" (< 2 seconds)
0:20 - SAR team clicks "En Route"
0:21 - Mobile shows: "🚁 Help En Route" (< 2 seconds)
```

## 📱 Screenshot Reference

### Before SOS Activation:
```
┌─────────────────────────────────────┐
│  ⚠ Emergency Use Only               │  ← No status indicator
├─────────────────────────────────────┤
│         (Red SOS Button)            │
└─────────────────────────────────────┘
```

### After SOS Activation:
```
┌──────────────────────────────────────────┐
│  ⚠ Emergency Use Only  🔴 Active        │  ← Status indicator visible
├──────────────────────────────────────────┤
│         (Red SOS Button - Active)        │
└──────────────────────────────────────────┘
```

### After SAR Acknowledges:
```
┌────────────────────────────────────────────────┐
│  ⚠ Emergency Use Only  🚨 SAR Notified        │  ← Updated status
├────────────────────────────────────────────────┤
│         (Red SOS Button - Active)              │
└────────────────────────────────────────────────┘
```

---

## 📞 Support

If status indicator still not showing after following this guide:

1. **Check Firebase FieldValue fix is applied** (see FIREBASE_FIELDVALUE_FIX.md)
2. **Verify real-time sync is enabled** (see REALTIME_SAR_SYNC_IMPLEMENTATION.md)
3. **Test with SAR dashboard** (see REALTIME_SYNC_TESTING_GUIDE.md)
4. **Check terminal output** for specific error messages
5. **Verify Firestore security rules** allow reads for authenticated users

**Status**: ✅ **Implementation Complete with Enhanced Status Logic**  
**Testing**: 🧪 **Ready for validation**  
**Last Updated**: November 6, 2025

### Recent Updates:
- ✅ Fixed SOS active strip disappearing on status changes
- ✅ Enhanced status indicator with dynamic icons
- ✅ Improved visual design (borders, shadows, colors)
- ✅ Added priority-based status display logic
- ✅ Debug logging for status transitions
- ✅ Matches all documented status indicators

### Implementation Details:
The SOS active strip now:
- Uses `rescueTeamResponses` array for latest SAR actions
- Falls back to `session.status` if no responses
- Shows responder name when assigned
- Updates color, icon, and text dynamically
- Stays visible for all active statuses (active, acknowledged, assigned, enRoute, onScene, inProgress)
- Enhanced visual design matching documentation specs
