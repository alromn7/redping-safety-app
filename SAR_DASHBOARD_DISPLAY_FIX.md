# SAR Dashboard Display Fix

## Issue Summary
**Problem**: SOS ping tickets stored in Firestore were not appearing in the SAR Dashboard's "Active SOS" screen.

**Root Cause**: SAR Dashboard has dual-mode architecture:
- **Website Feed Mode** (was default): Queries external API at `SARDashboardApiService.fetchAllDashboardData()`
- **Firestore Mode**: Queries Firestore directly with real-time streaming

The dashboard was defaulting to Website Feed mode, but user SOS sessions were stored in Firestore and not included in the website API response.

## Fix Applied

### 1. Changed Default Mode (Line 36)
```dart
// BEFORE
bool _useWebsiteFeed = true; // Website feed by default

// AFTER
bool _useWebsiteFeed = false; // Firestore mode by default - shows real-time SOS sessions
```

### 2. Updated Preferences Default (Line 75)
```dart
// BEFORE
_useWebsiteFeed = prefs.getBool('sar_useWebsiteFeed') ?? true;

// AFTER
_useWebsiteFeed = prefs.getBool('sar_useWebsiteFeed') ?? false; // Default to Firestore
```

### 3. Added Debug Logging (Lines 77, 663-672)
```dart
debugPrint('SAR Dashboard: Using ${_useWebsiteFeed ? "Website Feed" : "Firestore"} mode');

// Debug: Log first SOS session received
if (docs.isNotEmpty) {
  debugPrint('🔍 First SOS session:');
  final firstData = docs.first.data();
  debugPrint('  ID: ${docs.first.id}');
  debugPrint('  Status: ${firstData['status']}');
  debugPrint('  User: ${firstData['userName'] ?? firstData['userId']}');
  debugPrint('  CreatedAt: ${firstData['createdAt']}');
}
```

### 4. Added Visual Mode Toggle (Lines 235-247)
**NEW FEATURE**: Dashboard header now shows a toggle button to switch between modes:
- **⚡ Bolt Icon (Orange)**: Firestore mode (real-time)
- **☁️ Cloud Icon (Blue)**: Website Feed mode

**Location**: Top-right corner, left of Settings gear icon

**Tooltip**: 
- Firestore mode: "Using Firestore (Switch to Website)"
- Website mode: "Using Website Feed (Switch to Firestore)"

## Technical Details

### Firestore Query
```dart
_firebase
  .collection('sos_sessions')
  .orderBy('createdAt', descending: true)
  .limit(500)
  .snapshots()
```

### Client-Side Filtering
Active SOS tab excludes:
- `status == 'resolved'`
- `status == 'cancelled'`
- `status == 'false_alarm'`

### Data Structure Expected
```json
{
  "id": "session_id",
  "status": "active",
  "userName": "User Name",
  "userId": "user_id",
  "createdAt": "2025-01-23T10:30:00Z",
  "message": "Emergency message",
  "location": { "lat": -27.4705, "lng": 153.0260 }
}
```

## Testing Instructions

### Test 1: Verify Mode Change
1. **Hot reload** the app: `r` in terminal
2. Navigate to SAR Dashboard
3. Check debug logs:
   ```
   SAR Dashboard: Using Firestore mode
   📊 Active SOS Tab: Received X total SOS sessions from Firebase
   🔍 First SOS session:
     ID: abc123
     Status: active
     User: John Doe
     CreatedAt: ...
   ```

### Test 2: Verify SOS Sessions Display
1. Open SAR Dashboard
2. Go to **Active SOS** tab
3. Should see SOS ping tickets in real-time
4. Each card shows:
   - Status chip (Active/Responding/etc.)
   - User name
   - Message
   - Timestamp
   - Location details

### Test 3: Test Mode Toggle
1. Tap the **⚡ bolt icon** (top-right, orange)
2. Should switch to **☁️ cloud icon** (blue)
3. Dashboard re-renders using Website Feed
4. Tap again to switch back to Firestore mode
5. Check debug log: "SAR Dashboard: Switched to [mode] mode"

### Test 4: Verify Preferences Persistence
1. Switch to Website Feed mode (cloud icon)
2. Force quit app
3. Relaunch app → Open SAR Dashboard
4. Should still be in Website Feed mode
5. Switch back to Firestore mode
6. Force quit and relaunch
7. Should remember Firestore mode

## Verification Checklist

- [ ] Dashboard defaults to Firestore mode (⚡ orange bolt icon shown)
- [ ] Active SOS tab shows SOS sessions from Firestore
- [ ] Debug logs show session data being received
- [ ] Mode toggle button works (switches between ⚡ and ☁️)
- [ ] Mode preference persists across app restarts
- [ ] No crashes or errors when switching modes

## Related Issues Fixed

This fix also resolves:
1. **Real-time updates**: Firestore mode uses `snapshots()` for live streaming
2. **Missing SOS tickets**: Website API didn't include user sessions
3. **Mode confusion**: Visual toggle makes it clear which data source is active

## Dependencies

No new packages required. Uses existing:
- `cloud_firestore` (already configured)
- `shared_preferences` (already in use)
- `firebase_auth` (current user context)

## Deployment Notes

**File Modified**: `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`
- Lines changed: 36, 75-77, 235-247, 663-672
- **Breaking changes**: None
- **Migration needed**: None (preferences default gracefully)

**Backward Compatibility**: ✅ Full
- Users with existing `sar_useWebsiteFeed` preference: Respected
- New users: Default to Firestore mode
- Mode toggle allows switching back to Website Feed if needed

## Next Steps

1. ✅ **COMPLETED**: Changed default to Firestore mode
2. ✅ **COMPLETED**: Added visual mode toggle
3. ✅ **COMPLETED**: Enhanced debug logging
4. **PENDING**: Hot reload app to test
5. **PENDING**: Verify SOS sessions appear in Active SOS tab
6. **PENDING**: Test mode toggle functionality
7. **OPTIONAL**: Consider removing Website Feed mode if not needed

## Notes

- **Website Feed Mode**: May still be useful for aggregated stats/KPIs from backend
- **Firestore Mode**: Best for real-time incident monitoring
- **Recommendation**: Use Firestore mode for Active SOS, Website mode for analytics
- **Future Enhancement**: Hybrid mode - Firestore for incidents, Website for stats

---

**Fix Applied**: 2025-01-23  
**File**: `professional_sar_dashboard.dart`  
**Status**: ✅ Ready for testing
