# SAR Dashboard Workflow Status Fix

## Issue
The SAR Dashboard was allowing SAR admins to skip workflow steps (e.g., clicking "Assign" without first clicking "Acknowledge"). The status updates from SAR dashboard were not properly reflecting in the user's SOS page and RedPing help request status indicators.

## Solution Implemented

### 1. Enforced Sequential Workflow in SAR Dashboard

#### SOS Emergency Workflow

**File**: `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`

Added workflow enforcement to ensure proper sequence:

```dart
// Acknowledge button - Always available for active sessions
if (status == 'active') {
  -> Show "Acknowledge" button
}

// Assign button - ONLY enabled after acknowledged
if (status == 'acknowledged') {
  -> Show "Assign" button (enabled)
} else {
  -> Show "Assign" button (disabled with tooltip "Acknowledge first")
}

// En Route button - ONLY enabled after assigned
if (status == 'assigned') {
  -> Show "En Route" button (enabled)
} else {
  -> Show "En Route" button (disabled with tooltip "Assign first")
}

// On Scene button - ONLY enabled after en_route
if (status == 'en_route') {
  -> Show "On Scene" button (enabled)
} else {
  -> Show "On Scene" button (disabled with tooltip "Team must be en route first")
}

// Resolve button - Always available
-> Show "Resolve" button (always enabled)
```

### 2. Added Disabled Button Widget

**New Method**: `_disabledButton()`

```dart
Widget _disabledButton(String label, IconData icon, String tooltip) {
  return Tooltip(
    message: tooltip,
    child: OutlinedButton.icon(
      onPressed: null, // Disabled
      icon: Icon(icon, size: 14, color: AppTheme.secondaryText),
      label: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppTheme.secondaryText.withOpacity(0.3), width: 1),
        ...
      ),
    ),
  );
}
```

### 3. Fixed Firebase Status Sync

**File**: `lib/services/sos_service.dart`

Updated `_startFirestoreListener()` to:
- Accept new status values: `acknowledged`, `assigned`, `en_route`, `on_scene`
- Store raw status in session metadata as `rawStatus`
- Map all in-progress statuses to `SOSStatus.active` while preserving raw value

```dart
case 'acknowledged':
case 'assigned':
case 'en_route':
case 'on_scene':
  newStatus = SOSStatus.active; // Keep as active but preserve raw status
  break;

// Store raw status in metadata
_currentSession = _currentSession!.copyWith(
  status: newStatus,
  metadata: {
    ..._currentSession!.metadata,
    'rawStatus': firestoreStatus, // For UI display
  },
);
```

### 4. Status Indicator Already Configured

**File**: `lib/features/sos/presentation/pages/sos_page.dart`

The `_buildActiveStatusBar()` method was already correctly reading from `session.metadata['rawStatus']` and displaying the appropriate text and color for each status.

## Correct Workflow Sequence

### SOS Emergency Workflow

1. **User activates SOS** → Status: `active` → Display: "ALERT SENT" (red)
2. **SAR admin clicks "Acknowledge"** → Status: `acknowledged` → Display: "SAR REVIEWING" (orange)
3. **SAR admin clicks "Assign"** → Status: `assigned` → Display: "TEAM ASSIGNED" (blue)
4. **SAR admin clicks "En Route"** → Status: `en_route` → Display: "HELP EN ROUTE" (blue)
5. **SAR admin clicks "On Scene"** → Status: `on_scene` → Display: "HELP ON SCENE" (green)
6. **SAR admin clicks "Resolve"** → Status: `resolved` → Display: "RESOLVED" (green)

### RedPing Help Request Workflow

1. **User activates RedPing help** → Status: `active` → Display: "HELP REQUESTED" (orange)
2. **SAR admin clicks "Acknowledge"** → Status: `acknowledged` → Display: "HELP ACKNOWLEDGED" (blue)
3. **SAR admin clicks "Assign"** → Status: `assigned` → Display: "HELPER ASSIGNED" (blue)
4. **SAR admin clicks "In Progress"** → Status: `inProgress` → Display: "HELP IN PROGRESS" (green)
5. **SAR admin clicks "Resolve"** → Status: `resolved` → Display: "HELP COMPLETED" (green)

## Benefits

✅ **Enforced Workflow**: SAR admins must follow the correct sequence
✅ **Clear Visual Feedback**: Disabled buttons show tooltips explaining why they're disabled
✅ **Real-time Updates**: User's SOS page updates immediately when SAR admin changes status
✅ **Consistent Status**: Raw status preserved and synced between SAR dashboard and user app
✅ **Better UX**: Users can track rescue progress in real-time

## Testing

To test the complete workflow:

1. **User Side**: Activate SOS from user app
2. **SAR Dashboard**: 
   - Verify "Acknowledge" button is enabled, others disabled
   - Click "Acknowledge"
   - Verify "Assign" button is now enabled
   - Click "Assign" and enter responder details
   - Verify "En Route" button is now enabled
   - Click "En Route"
   - Verify "On Scene" button is now enabled
   - Click "On Scene"
   - Click "Resolve"
3. **User Side**: Verify status indicator updates at each step

## Files Modified

1. `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`
   - Added `_disabledButton()` method
   - Enforced sequential workflow in button visibility logic
   
2. `lib/services/sos_service.dart`
   - Updated Firebase listener to handle new status values
   - Store raw status in metadata for UI display

## Date
October 27, 2025
