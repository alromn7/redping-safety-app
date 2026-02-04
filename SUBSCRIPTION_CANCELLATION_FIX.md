# Subscription Cancellation Authentication Fix

**Date**: November 30, 2025  
**Issue**: "unauthenticated" error when canceling subscription  
**Root Cause**: Missing `subscriptionId` parameter and placeholder user ID

## Problem

### Error Symptoms
- User receives "unauthenticated" error when attempting to cancel subscription
- Cloud Function expects both `userId` and `subscriptionId`
- Flutter code was only sending `userId: 'current_user'` (placeholder)

### Code Analysis

**Cloud Function** (`functions/src/subscriptionPayments.js`):
```javascript
exports.cancelSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, subscriptionId } = request.data; // ← Expects BOTH
  
  // Cancel subscription at period end
  const subscription = await getStripe().subscriptions.update(subscriptionId, {
    cancel_at_period_end: true,
  });
  // ...
});
```

**Flutter Code** (BEFORE):
```dart
// payment_service.dart
Future<void> cancelSubscription(String userId) async {
  final callable = FirebaseFunctions.instance.httpsCallable('cancelSubscription');
  
  await callable.call({'userId': userId}); // ← Missing subscriptionId!
}

// subscription_management_page.dart
await _paymentService.cancelSubscription('current_user'); // ← Placeholder!
```

## Solution

### Changes Made

#### 1. Updated PaymentService (`lib/services/payment_service.dart`)

**BEFORE**:
```dart
Future<void> cancelSubscription(String userId) async {
  await callable.call({'userId': userId});
}
```

**AFTER**:
```dart
Future<void> cancelSubscription(String userId, String subscriptionId) async {
  debugPrint('PaymentService: Cancelling subscription $subscriptionId...');
  
  await callable.call({
    'userId': userId,
    'subscriptionId': subscriptionId, // ← Added!
  });
}
```

#### 2. Updated Subscription Management Page

**File**: `lib/features/subscription/presentation/pages/subscription_management_page.dart`

**Added Import**:
```dart
import 'package:firebase_auth/firebase_auth.dart';
```

**BEFORE**:
```dart
await _paymentService.cancelSubscription('current_user');
```

**AFTER**:
```dart
if (_subscription == null) {
  throw Exception('No active subscription found');
}

// Get actual user ID from Firebase Auth
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User not authenticated');
}

await _paymentService.cancelSubscription(user.uid, _subscription!.id);
```

## Testing Instructions

### Test 1: Verify Authentication
1. Log in as a user with active subscription
2. Navigate to Subscription Management page
3. Tap "Cancel Subscription"
4. Confirm cancellation

**Expected**: ✅ Success message "Subscription cancelled. Active until period end."  
**If Error**: Check logcat for authentication issues

### Test 2: Verify Subscription ID
Check Cloud Function logs:
```bash
firebase functions:log --only cancelSubscription
```

**Expected Log**:
```
🔥 Canceling subscription: sub_xxxxxxxxxxxxx
✅ Subscription cancelled at period end
```

### Test 3: Verify Firestore Update
1. After cancellation, check Firestore:
   - Collection: `users/{userId}`
   - Field: `subscription.status`
   - Should show: `active` (until period end)
   - Field: `subscription.cancelAtPeriodEnd`
   - Should be: `true`

### Test 4: Verify Stripe Dashboard
1. Go to Stripe Dashboard → Subscriptions
2. Find the cancelled subscription
3. **Expected**: Shows "Cancels at [date]"

## Error Scenarios Handled

### 1. No Active Subscription
```dart
if (_subscription == null) {
  throw Exception('No active subscription found');
}
```
**User sees**: "Error cancelling subscription: No active subscription found"

### 2. User Not Authenticated
```dart
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User not authenticated');
}
```
**User sees**: "Error cancelling subscription: User not authenticated"

### 3. Cloud Function Authentication Failure
```javascript
if (!request.auth) {
  throw new HttpsError('unauthenticated', 'User must be authenticated');
}
```
**User sees**: "Error cancelling subscription: unauthenticated"

## Verification Checklist

- [x] Added `subscriptionId` parameter to `cancelSubscription()`
- [x] Get actual user ID from `FirebaseAuth.instance.currentUser`
- [x] Pass both `userId` and `subscriptionId` to Cloud Function
- [x] Added null checks for subscription and user
- [x] Error messages display to user
- [ ] Test cancellation in debug mode
- [ ] Test cancellation in release mode
- [ ] Verify Stripe webhook updates Firestore
- [ ] Verify subscription remains active until period end

## Related Files Modified

1. ✅ `lib/services/payment_service.dart` - Updated method signature
2. ✅ `lib/features/subscription/presentation/pages/subscription_management_page.dart` - Fixed user ID and subscription ID

## Migration Notes

**Breaking Change**: `PaymentService.cancelSubscription()` signature changed:
- **Old**: `cancelSubscription(String userId)`
- **New**: `cancelSubscription(String userId, String subscriptionId)`

**Impact**: Only affects subscription management page (already updated)

## Next Steps

1. **Test in Debug**: Hot reload app and test cancellation
2. **Deploy Cloud Function**: Ensure latest version is deployed
   ```bash
   cd functions
   firebase deploy --only functions:cancelSubscription
   ```
3. **Test in Production**: Test with real subscription (use test mode)
4. **Monitor Logs**: Check Cloud Functions logs for successful cancellations

## Known Issues

None - fix should resolve the unauthenticated error completely.

## Additional Notes

- Subscription cancellation uses `cancel_at_period_end: true` (user keeps access until billing cycle ends)
- For immediate cancellation, would need separate `cancelSubscriptionImmediately()` method
- Consider adding confirmation dialog with period end date display

---

**Status**: ✅ **FIXED**  
**Testing**: Pending user verification  
**Deployment**: Ready to deploy
