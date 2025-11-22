# SOS Rules and Enforcement

## Overview
This document defines the comprehensive rules for SOS session management in the RedPing safety app, ensuring only one active emergency at a time per user and proper resolution workflows.

---

## 📋 Core SOS Rules

### Rule 1: Single Active Session Per User
**Principle**: A user can only have **ONE** active SOS session at any given time.

**Enforcement Mechanisms**:
1. **Frontend Check** (sos_service.dart):
   - Before creating new session, check `hasActiveSession`
   - Prevent duplicate SOS activations while countdown or active session exists

2. **Backend Check** (Cloud Function - `onSosSessionCreated`):
   - Transaction-based check on `users/{uid}/meta/state.activeSessionId`
   - If pointer exists and doesn't match new session → auto-resolve duplicate
   - Located in: `functions/src/triggers/sosSessions.ts` (lines 85-115)

3. **State Pointer Management**:
   - **Clear before activation**: Remove stale pointer before creating session
   - **Set after persistence**: Update pointer after successful Firestore write
   - **Clear on resolution**: Remove pointer when session ends
   - Implementation in: `lib/repositories/sos_repository.dart` and `lib/services/sos_service.dart`

**Status States that Block New SOS**:
- `countdown` - SOS activation timer running (10 seconds)
- `active` - Emergency session in progress
- `assigned` - SAR team assigned to session
- `inProgress` - Rescue operation underway

**Status States that Allow New SOS**:
- `resolved` - Session successfully completed
- `cancelled` - User cancelled false alarm
- `false_alarm` - Marked as false alarm
- No active session (clean state)

---

## 🔄 Session Resolution Methods

A user's active SOS session can be resolved through **four authorized methods**:

### Method 1: SAR Admin Resolution
**Who**: Search and Rescue (SAR) team members with coordinator/admin roles

**How**:
1. SAR admin views session on Professional SAR Dashboard
2. Clicks "Mark as Resolved" button on session card
3. Optionally adds resolution notes
4. System updates session status to `resolved`
5. Clears `activeSessionId` pointer for user
6. Notifies user of resolution

**Authorization**:
- ✅ SAR admin/coordinator can update ANY session status
- ✅ Assigned SAR team members can update THEIR assigned session status
- ❌ Regular users CANNOT update status via SAR dashboard
- ❌ Unassigned users CANNOT update any session status

**Implementation**:
- Dashboard: `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`
- Service: `lib/services/sos_service.dart` → `resolveSession()`
- Firestore rules: Coordinators can update session status

### Method 2: User 5-Second Reset Button
**Who**: The user who activated the SOS (session owner ONLY)

**How**:
1. User holds RedPing button (green activated state) for 5 seconds
2. Red progress indicator shows countdown
3. At completion, triggers `_onSOSReset()` callback
4. Calls `_serviceManager.sosService.resolveSession()`
5. Button returns to red normal state
6. Session marked as `resolved`
7. Active session pointer cleared

**User Permissions**:
- ✅ User CAN reset their OWN SOS via 5-second button hold
- ✅ Session automatically marked as `resolved` when reset
- ❌ User CANNOT update status via SAR dashboard
- ❌ User CANNOT update other users' sessions
- ❌ User CANNOT manually change status indicators

**Implementation**:
- Button: `lib/features/sos/presentation/widgets/enhanced_sos_button.dart`
- Page: `lib/features/sos/presentation/pages/sos_page.dart` → `_onSOSReset()`
- Service: `lib/services/sos_service.dart` → `resolveSession()`

**UX Flow**:
```
Green Button (SOS Active)
    ↓
Hold 5 seconds
    ↓
Red progress indicator appears
    ↓
Completion at 5 seconds
    ↓
Button turns red
    ↓
Session automatically marked as resolved
    ↓
Inline SOS Active strip disappears
```

### Method 3: Immediate Emergency Contact Resolution
**Who**: User's designated immediate emergency contacts

**How**:
1. Emergency contact receives SOS alert notification
2. Opens RedPing app (must have app installed)
3. Views active session for their contact
4. Can mark session as "Safe" or "False Alarm"
5. System updates session status
6. Clears active session pointer
7. Notifies user and SAR team

**Authorization**:
- ✅ Immediate emergency contacts can update their contact's session status
- ✅ Must be registered as immediate emergency contact in user's profile
- ❌ Regular emergency contacts CANNOT update status
- ❌ Other users CANNOT update status

**Implementation**:
- Widget: `lib/features/sos/presentation/widgets/help_communication_widget.dart`
- Repository: `lib/repositories/sos_repository.dart` → `updateStatus()`
- Emergency contacts must have immediate contact designation

**Note**: Only IMMEDIATE emergency contacts have status update permissions. Regular contacts receive notifications but cannot change status.

### Method 4: Assigned SAR Team Member Resolution
**Who**: SAR team members assigned to the specific SOS case

**How**:
1. SAR admin assigns team member to SOS case
2. Assigned team member views case in their dashboard
3. Can update status as case progresses:
   - `assigned` → SAR team assigned
   - `enRoute` → Help is on the way
   - `onScene` → Help has arrived
   - `inProgress` → Rescue operation underway
   - `resolved` → Case completed successfully
4. System updates session status
5. Notifies user of status changes
6. Clears active session pointer on resolution

**Authorization**:
- ✅ Assigned SAR team member can update THEIR assigned case status
- ✅ Can progress case through all status stages
- ❌ Cannot update cases assigned to other team members
- ❌ Cannot update unassigned cases (unless SAR admin)

**Implementation**:
- Dashboard: `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`
- Service: `lib/services/sos_service.dart` → `updateSessionStatus()`
- Repository: `lib/repositories/sos_repository.dart`

**Note**: Assignment is permanent for the session lifecycle. Only SAR admins can reassign cases.

---

## 🔐 Status Update Authorization Matrix

### Who Can Update Status Indicators

| User Type | Own Session | Other User's Session | Via Dashboard | Via 5-Sec Button |
|-----------|-------------|---------------------|---------------|------------------|
| **Regular User (SOS Owner)** | ❌ Dashboard<br>✅ Button Only | ❌ Never | ❌ No Access | ✅ Own SOS Only |
| **Other Regular Users** | ❌ Never | ❌ Never | ❌ No Access | ❌ Never |
| **SAR Admin/Coordinator** | ✅ Any Status | ✅ Any Status | ✅ Full Access | N/A |
| **Assigned SAR Team Member** | ✅ If Assigned | ✅ Only Assigned Cases | ✅ Assigned Only | N/A |
| **Unassigned SAR Team Member** | ❌ Dashboard | ❌ Unless Assigned | ❌ View Only | N/A |
| **Immediate Emergency Contact** | N/A | ✅ Contact's Session Only | ✅ Limited Access | N/A |
| **Regular Emergency Contact** | N/A | ❌ View Only | ❌ View Only | N/A |

### Key Permissions

**✅ Allowed Actions**:
- **User**: Can activate SOS, can reset own SOS via 5-second button hold (auto-resolves)
- **SAR Admin**: Can update any session status, can assign team members, full dashboard access
- **Assigned SAR Team**: Can update their assigned case status, can progress case through stages
- **Immediate Emergency Contact**: Can mark contact's session as safe/false alarm
- **Developer/Owner** (alromn7@gmail.com): Full unrestricted access for testing and management

**❌ Prohibited Actions**:
- **User**: CANNOT update status via SAR dashboard, CANNOT update other users' sessions
- **Other Users**: CANNOT update ANY status indicators in SAR dashboard
- **Unassigned SAR Team**: CANNOT update cases not assigned to them
- **Regular Emergency Contact**: CANNOT update status, notification-only access

**🔓 Developer Exemption**:
- Account `alromn7@gmail.com` has full permissions to:
  - Update any session status via dashboard
  - Test all workflows without restrictions
  - Manage sessions for any user
  - Bypass permission checks for development/testing purposes

### Status Update Rules

1. **User Self-Resolution**:
   - Method: Hold RedPing button for 5 seconds
   - Result: Session automatically marked as `resolved`
   - No manual status selection - always resolves

2. **SAR Dashboard Updates**:
   - Only SAR admin/coordinators have unrestricted access
   - Assigned team members can only update their cases
   - Regular users have NO update permissions

3. **Emergency Contact Updates**:
   - Only IMMEDIATE contacts can update status
   - Can only update their designated contact's session
   - Cannot update other sessions

---

## 🎯 SOS Lifecycle States

### State Diagram
```
          startSOSCountdown()
               ↓
          [countdown] (10 seconds)
               ↓
        _activateSOS()
               ↓
          [active] ← → [assigned] ← → [inProgress]
               ↓            ↓              ↓
               ↓            ↓              ↓
          [resolved] ← ← ← ← ← ← ← ← ← ← ←
               ↓
        Clear pointer
               ↓
         Ready for new SOS
```

### State Transitions
1. **Normal → Countdown**:
   - Trigger: User holds RedPing button for 10 seconds
   - Creates session with status `countdown`
   - Does NOT set active session pointer yet

2. **Countdown → Active**:
   - Trigger: Countdown timer completes OR immediate activation
   - Clears any stale pointers
   - Updates session to `active`
   - Sets active session pointer
   - Sends SOS ping to SAR dashboard
   - Starts location tracking

3. **Active → Assigned**:
   - Trigger: SAR admin assigns team to session
   - Updates by: SAR dashboard
   - Session remains active, prevents duplicate SOS

4. **Assigned → In Progress**:
   - Trigger: SAR team marks as responding/on-site
   - Updates by: SAR team member
   - Session remains active, prevents duplicate SOS

5. **Any Active State → Resolved**:
   - Trigger: Any of the 4 resolution methods
   - Clears active session pointer
   - Stops location tracking
   - Allows new SOS creation

6. **Countdown → Cancelled**:
   - Trigger: User cancels during countdown
   - Special case: No pointer was set, so no cleanup needed
   - Session marked `cancelled`
   - Allows immediate new SOS

---

## 🛡️ Duplicate Prevention Architecture

### Frontend Prevention
**File**: `lib/services/sos_service.dart`

```dart
// Check before starting countdown
bool get hasActiveSession => 
    _currentSession != null && 
    (_currentSession!.status == SOSStatus.countdown ||
     _currentSession!.status == SOSStatus.active);

// Block duplicate activation
if (hasActiveSession) {
  debugPrint('SOSService: Already have active session');
  return _currentSession!;
}
```

### Backend Prevention
**File**: `functions/src/triggers/sosSessions.ts`

```typescript
export const onSosSessionCreated = onDocumentCreated(
  { document: "sos_sessions/{sessionId}", region: REGION },
  async (event: any) => {
    const data = event.data?.data();
    const sessionId = event.params.sessionId;
    const uid = data.userId;
    
    const stateRef = admin.firestore().doc(`users/${uid}/meta/state`);
    
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(stateRef);
      const activeSessionId = snap.data()?.activeSessionId;
      
      // If pointer exists and doesn't match this session
      if (activeSessionId && activeSessionId !== sessionId) {
        // Auto-resolve this duplicate
        tx.set(
          admin.firestore().doc(`sos_sessions/${sessionId}`),
          { 
            status: "resolved", 
            updatedAt: admin.firestore.FieldValue.serverTimestamp() 
          },
          { merge: true }
        );
      } else if (!activeSessionId) {
        // Set pointer for first active session
        tx.set(stateRef, { activeSessionId: sessionId }, { merge: true });
      }
    });
  }
);
```

### Pointer Management
**Clear Timing**: Before activation
**Set Timing**: After persistence
**Clear Again**: On resolution

**File**: `lib/services/sos_service.dart` → `_activateSOS()`

```dart
// BEFORE activation - clear stale pointer
try {
  await _sosRepository.clearActiveSessionPointer(authUser.id);
  debugPrint('SOSService: Cleared stale active session pointer');
} catch (e) {
  debugPrint('SOSService: Failed to clear pointer - $e');
}

// ... create and persist session ...

// AFTER persistence - set current pointer
try {
  await _sosRepository.setActiveSessionPointer(authUser.id, _currentSession!.id);
  debugPrint('SOSService: Set activeSessionId pointer');
} catch (e) {
  debugPrint('SOSService: Failed to set pointer - $e');
}
```

---

## 🔍 Troubleshooting

### Issue: SOS Active Strip Disappears Immediately

**Symptoms**:
- User activates SOS successfully
- Inline "SOS Active" strip appears briefly
- Strip disappears after 1-2 seconds
- Session shows as `resolved` in Firestore

**Root Cause**:
- Stale `activeSessionId` pointer in `users/{uid}/meta/state`
- Cloud Function detects "duplicate" and auto-resolves new session

**Solution**:
1. Run cleanup script: `dart run mark_sos_sessions_resolved.dart`
2. Script clears all stale pointers
3. Hot reload app
4. Test SOS activation again

**Prevention**:
- Ensure `clearActiveSessionPointer()` runs BEFORE activation
- Ensure `setActiveSessionPointer()` runs AFTER persistence
- Proper sequencing prevents stale pointer races

### Issue: Cannot Create New SOS After Resolving Previous

**Symptoms**:
- User resolved previous SOS
- Button stays green
- Cannot activate new SOS

**Root Cause**:
- Active session pointer not cleared on resolution
- Frontend state not reset properly

**Solution**:
1. Check `resolveSession()` in `sos_service.dart`
2. Verify `clearActiveSessionPointer()` is called
3. Verify `_currentSession = null` is set
4. Check `_isSOSActive = false` in UI layer

### Issue: Multiple Active Sessions Visible in Dashboard

**Symptoms**:
- User has multiple sessions showing as `active`
- Cloud Function should have prevented this

**Root Cause**:
- Cloud Function not deployed or failed
- Transaction race condition
- Firestore rules not enforcing properly

**Solution**:
1. Redeploy Cloud Functions: `firebase deploy --only functions`
2. Run cleanup script to resolve all active sessions
3. Verify Cloud Function logs in Firebase Console
4. Check Firestore indexes for transaction performance

---

## 🚀 Testing Checklist

### Test 1: Normal SOS Activation
- [ ] Hold RedPing button for 10 seconds
- [ ] Countdown shows progress
- [ ] Button turns green at completion
- [ ] Inline "SOS Active" strip appears
- [ ] Strip stays visible (does NOT disappear)
- [ ] SOS ping appears in SAR dashboard
- [ ] Check Firestore: session status = `active`
- [ ] Check Firestore: `users/{uid}/meta/state.activeSessionId` set

### Test 2: Prevent Duplicate SOS
- [ ] Start SOS activation (green button)
- [ ] Try to activate another SOS
- [ ] System blocks duplicate activation
- [ ] Shows message "Already have active session"
- [ ] Only one session visible in dashboard

### Test 3: User 5-Second Reset
- [ ] With green activated button, hold for 5 seconds
- [ ] Red progress indicator shows countdown
- [ ] Button turns red at completion
- [ ] Inline SOS Active strip disappears
- [ ] Session automatically marked as `resolved` in Firestore
- [ ] Active session pointer cleared
- [ ] Can activate new SOS immediately
- [ ] User CANNOT update status via SAR dashboard

### Test 4: SAR Admin Resolution
- [ ] SAR admin opens dashboard
- [ ] Finds active SOS session
- [ ] Clicks "Mark as Resolved"
- [ ] Adds resolution notes
- [ ] User's app updates (strip disappears)
- [ ] Button returns to red
- [ ] Session marked `resolved`
- [ ] Regular users CANNOT access this function

### Test 5: Assigned Team Member Updates
- [ ] SAR admin assigns team member to case
- [ ] Assigned team member opens dashboard
- [ ] Can update status of THEIR assigned case
- [ ] Status updates: assigned → enRoute → onScene → resolved
- [ ] User sees status updates in SOS Active strip
- [ ] Team member CANNOT update other cases
- [ ] Unassigned team members have view-only access

### Test 6: Permission Restrictions
- [ ] Regular user opens SAR dashboard (if accessible)
- [ ] User CANNOT see status update buttons
- [ ] User CANNOT change any status indicators
- [ ] Other users CANNOT update any sessions
- [ ] Only authorized roles can modify status

### Test 7: Session Persistence
- [ ] Activate SOS (green button)
- [ ] Close app completely
- [ ] Reopen app
- [ ] SOS Active strip still visible
- [ ] Button still green
- [ ] Can still use inline actions (call/chat/messaging)

---

## 📚 Related Documentation

- **Tiny Server Contract**: `docs/tiny_server_contract.md` - Backend API contract
- **SOS Button Implementation**: `docs/enhanced_sos_button_implementation.md` - UI behavior
- **SOS Button Ping Fix**: `docs/sos_button_ping_functionality_fix.md` - Emergency ping flow
- **Unified Communication**: `docs/redping_unified_communication_blueprint.md` - Session rules
- **Admin Guide**: `ADMIN_SETUP_GUIDE.md` - Manual session management

---

## 🔧 Implementation Files

### Core Service
- `lib/services/sos_service.dart` - Main SOS lifecycle management
- `lib/repositories/sos_repository.dart` - Firestore persistence layer

### UI Components
- `lib/features/sos/presentation/pages/sos_page.dart` - Main SOS page
- `lib/features/sos/presentation/widgets/enhanced_sos_button.dart` - RedPing button

### Backend
- `functions/src/triggers/sosSessions.ts` - Cloud Function duplicate prevention

### Scripts
- `mark_sos_sessions_resolved.dart` - Cleanup all active sessions
- `mark_help_requests_resolved.dart` - Cleanup help requests

---

## 📊 Firestore Schema

### Session Document
**Collection**: `sos_sessions/{sessionId}`

```typescript
{
  id: string,
  userId: string,              // Owner of session
  type: "manual" | "crash" | "fall" | "automatic",
  status: "countdown" | "active" | "assigned" | "inProgress" | "resolved" | "cancelled" | "false_alarm",
  startTime: Timestamp,
  endTime?: Timestamp,
  location: {
    latitude: number,
    longitude: number,
    accuracy: number,
    address?: string,
    timestamp: Timestamp
  },
  userMessage?: string,
  updatedAt: Timestamp,
  resolvedBy?: string,        // Who resolved it
  resolutionNotes?: string    // Why resolved
}
```

### State Pointer
**Document**: `users/{uid}/meta/state`

```typescript
{
  activeSessionId?: string,   // Current active session ID
  updatedAt: Timestamp
}
```

### Dashboard Feed
**Collection**: `sos_pings/{sessionId}`

```typescript
{
  sessionId: string,
  userId: string,
  userName: string,
  userPhone: string,
  type: string,
  status: string,
  priority: "low" | "medium" | "high" | "critical",
  riskLevel: "low" | "medium" | "high",
  location: {
    latitude: number,
    longitude: number,
    accuracy: number,
    address: string
  },
  lastUpdate: string          // ISO 8601 timestamp
}
```

---

## 🎯 Future Enhancements

### Planned Features
1. **Automatic Timeout Resolution**:
   - If session active for X hours with no SAR response
   - Auto-resolve and notify user
   - Configurable timeout per session type

2. **Family Contact SMS Resolution**:
   - Emergency contact replies "SAFE" via SMS
   - System marks session as resolved
   - Requires SMS gateway integration

3. **Voice Call Verification**:
   - Automated voice call to emergency contacts
   - Contact confirms user safety via keypress
   - Session auto-resolved on confirmation

4. **Multi-SAR Coordination**:
   - Multiple SAR teams can view same session
   - First team to accept gets assignment
   - Others notified of assignment

5. **Session Escalation**:
   - If no SAR response in X minutes
   - Auto-escalate to regional SAR coordinator
   - Increase priority level

---

**Last Updated**: November 6, 2025  
**Version**: 1.0  
**Maintained By**: RedPing Development Team
