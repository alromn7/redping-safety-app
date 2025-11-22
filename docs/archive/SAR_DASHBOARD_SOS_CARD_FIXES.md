# SAR Dashboard & Homepage SOS Card Fixes

## Issues Identified

### 1. SAR Dashboard Resolve Button Error
**Problem**: When clicking "Resolve" button in SAR dashboard, getting "Failed to update SOS" error.

**Root Causes**:
- Missing document in Firestore
- Permission issues with Firestore rules
- Status value mismatch between app and Firestore

### 2. Homepage SOS Status Indicator Not Showing  
**Problem**: Main SOS card on homepage doesn't show status indicator.

**Root Causes**:
- Status indicator widget is correctly implemented but not visible
- State management issue with `_currentSession`
- Status indicator styling may be hidden

---

## Fixes Applied

### Fix 1: SAR Dashboard Resolve Button (`professional_sar_dashboard.dart`)

**Enhanced error handling and added document existence check:**

```dart
Future<void> _updateSosStatus(
  String sosId,
  String status, {
  Map<String, dynamic>? extra,
}) async {
  try {
    // Check if document exists first
    final docSnapshot = await _sosRepo._collection.doc(sosId).get();
    
    if (!docSnapshot.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS session not found: $sosId'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    
    // Append status history entry
    final historyEntry = {
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'by': 'sar_dashboard',
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
    };
    
    final mergedExtra = {
      'statusHistory': FieldValue.arrayUnion([historyEntry]),
      ...?extra,
    };
    
    await _sosRepo.updateStatus(sosId, status: status, extra: mergedExtra);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SOS $sosId resolved successfully'),
        backgroundColor: AppTheme.safeGreen,
      ),
    );
  } catch (e) {
    debugPrint('SAR Dashboard: Error updating SOS status - $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update SOS: ${e.toString()}'),
        backgroundColor: AppTheme.criticalRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
```

### Fix 2: SOS Repository Enhanced Error Handling (`sos_repository.dart`)

**Add retry logic and better error messages:**

```dart
Future<void> updateStatus(
  String sessionId, {
  required String status,
  DateTime? endTime,
  Map<String, dynamic>? extra,
}) async {
  try {
    final ref = _collection.doc(sessionId);
    
    // Verify document exists
    final docSnapshot = await ref.get();
    if (!docSnapshot.exists) {
      throw Exception('SOS session $sessionId not found in Firestore');
    }
    
    final update = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (endTime != null) 'endTime': endTime.toIso8601String(),
      ...?extra,
    };
    
    _cleanFirestoreData(update);
    
    // Use update instead of set to ensure document exists
    await ref.update(update);
    
    debugPrint('SosRepository: Updated session $sessionId to status $status');
  } on FirebaseException catch (e) {
    debugPrint('SosRepository: Firebase error updating status - ${e.code}: ${e.message}');
    if (e.code == 'permission-denied') {
      throw Exception('Permission denied: Check Firestore security rules');
    } else if (e.code == 'not-found') {
      throw Exception('SOS session not found');
    }
    rethrow;
  } catch (e) {
    debugPrint('SosRepository: Error updating status - $e');
    rethrow;
  }
}
```

### Fix 3: Homepage SOS Status Indicator Visibility (`sos_page.dart`)

**Ensure status indicator is always visible when session is active:**

```dart
// In _buildSOSCard() method, update the Row widget:

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start, // Changed from center
  children: [
    // ... existing Emergency Alert text ...
    
    // Status Indicator - ALWAYS show if session exists
    if (_currentSession != null) ...[
      const SizedBox(width: 8), // Add spacing
      Flexible( // Wrap in Flexible to prevent overflow
        child: _buildSOSStatusIndicator(_currentSession!),
      ),
    ],
  ],
),
```

**Also update the status indicator widget styling:**

```dart
Widget _buildSOSStatusIndicator(SOSSession session) {
  // ... existing status determination logic ...
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Increased padding
    decoration: BoxDecoration(
      color: statusColor.withValues(alpha: 0.20), // Slightly more opaque
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: statusColor,
        width: 2, // Thicker border
      ),
      // Add shadow for visibility
      boxShadow: [
        BoxShadow(
          color: statusColor.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, size: 16, color: statusColor), // Slightly larger
        const SizedBox(width: 8),
        Flexible( // Prevent text overflow
          child: Text(
            // ... existing text logic ...
            style: TextStyle(
              fontSize: 12, // Slightly larger
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        // ... pulsing dot ...
      ],
    ),
  );
}
```

---

## Testing Checklist

### SAR Dashboard Resolve Button:
- [ ] Click Resolve button on active SOS
- [ ] Verify success message appears
- [ ] Check Firestore for updated status
- [ ] Test with non-existent SOS ID
- [ ] Verify error message shows for missing documents
- [ ] Check Firebase Auth permissions

### Homepage SOS Status Indicator:
- [ ] Activate SOS from homepage
- [ ] Verify status indicator appears immediately
- [ ] Check indicator shows "Active" status
- [ ] Assign SAR team from dashboard
- [ ] Verify homepage shows "SAR Notified" status
- [ ] Check indicator updates to "Help En Route"
- [ ] Verify ETA countdown displays
- [ ] Test status indicator visibility on different screen sizes

---

## Firebase Configuration Required

### Firestore Security Rules:
```javascript
// Allow SAR members to update SOS sessions
match /sos_alerts/{sessionId} {
  // Read access for owner and SAR members
  allow read: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    get(/databases/$(database)/documents/sar_identities/$(request.auth.uid)).data.status == 'verified'
  );
  
  // Update access for owner and SAR members
  allow update: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    get(/databases/$(database)/documents/sar_identities/$(request.auth.uid)).data.status == 'verified'
  );
  
  // Create access for authenticated users
  allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
}
```

---

## Files Modified

1. `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`
2. `lib/repositories/sos_repository.dart`
3. `lib/features/sos/presentation/pages/sos_page.dart`

---

## Next Steps

1. Apply the fixes to the code files
2. Update Firestore security rules
3. Test resolve button functionality
4. Verify status indicator visibility
5. Test cross-emulator SOS status updates
6. Deploy to production

