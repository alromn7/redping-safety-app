# Stripe Live Payment Error Fix

## Issue Identified
**Error**: `Firebase error: internal - Value for argument "data" is not a valid Firestore document. Cannot use "undefined" as a Firestore value (found in field "subscription.isYearlyBilling")`

**Root Cause**: The Cloud Function `processSubscriptionPayment` was receiving `undefined` values for `isYearlyBilling` parameter, which Firestore rejects when writing documents.

## Technical Analysis

### Problem Location
**File**: `functions/src/subscriptionPayments.js`
**Function**: `processSubscriptionPayment`
**Lines**: 230-232, 385

### Code Flow
1. Client sends payment request with `isYearlyBilling` parameter
2. Backend extracts parameter: `const { isYearlyBilling, isYearly, ... } = request.data`
3. Fallback logic: `const isYearlyParam = isYearly !== undefined ? isYearly : isYearlyBilling`
4. **Issue**: If both are `undefined`, `isYearlyParam` becomes `undefined`
5. Firestore write fails when `subscriptionData.isYearlyBilling: isYearlyParam` is `undefined`

### Why This Happened
- Legacy code supported both `isYearly` and `isYearlyBilling` parameter names
- Fallback didn't handle case where both are `undefined`
- Firestore strictly rejects `undefined` values (must use `null` or omit field)

## Fix Applied

### Change 1: Parameter Extraction with Safe Default
```javascript
// BEFORE
const isYearlyParam = isYearly !== undefined ? isYearly : isYearlyBilling;

// AFTER
const isYearlyParam = isYearly !== undefined ? isYearly : (isYearlyBilling !== undefined ? isYearlyBilling : false);
```

**Impact**: Ensures `isYearlyParam` always has a boolean value (defaults to `false` for monthly billing)

### Change 2: Firestore Write Safety
```javascript
// BEFORE
const subscriptionData = {
  // ...
  isYearlyBilling: isYearlyParam,
  // ...
  requestId,
  retryAttempts: (createResult.attempt - 1),
};

// AFTER
const subscriptionData = {
  // ...
  isYearlyBilling: isYearlyParam || false, // Ensure boolean, never undefined
  // ...
  requestId: requestId || '',
  retryAttempts: (createResult.attempt - 1) || 0,
};
```

**Impact**: Double-safety to prevent any `undefined` values in Firestore writes

## Testing Recommendations

### Test Case 1: Monthly Billing (Default)
```javascript
// Request with isYearlyBilling = false
{
  userId: 'test_user_id',
  tier: 'pro',
  paymentMethodId: 'pm_test_...',
  isYearlyBilling: false,  // Explicit false
}
// Expected: Works ✓
```

### Test Case 2: Yearly Billing
```javascript
// Request with isYearlyBilling = true
{
  userId: 'test_user_id',
  tier: 'pro',
  paymentMethodId: 'pm_test_...',
  isYearlyBilling: true,  // Explicit true
}
// Expected: Works ✓
```

### Test Case 3: Missing Parameter (Edge Case)
```javascript
// Request without isYearlyBilling
{
  userId: 'test_user_id',
  tier: 'pro',
  paymentMethodId: 'pm_test_...',
  // isYearlyBilling omitted
}
// Expected: Defaults to false (monthly) ✓
```

## Deployment Status

**Deployed**: November 30, 2025
**Region**: us-central1
**Function**: `processSubscriptionPayment`
**Status**: ✅ Successfully deployed

### Deployment Log
```
+  functions[processSubscriptionPayment(us-central1)] Successful update operation.
```

## Prevention Measures

### Code Review Checklist
- ✅ All Firestore writes use explicit values (no `undefined`)
- ✅ Function parameters have safe defaults
- ✅ Boolean fields explicitly coerced with `|| false`
- ✅ String fields explicitly coerced with `|| ''`
- ✅ Number fields explicitly coerced with `|| 0`

### Future Improvements
1. Add TypeScript to Cloud Functions for compile-time type checking
2. Add input validation middleware to reject `undefined` parameters early
3. Create Firestore write wrapper that auto-sanitizes `undefined` values
4. Add integration tests covering edge cases with missing parameters

## Related Files
- `functions/src/subscriptionPayments.js` - Fixed function
- `lib/services/payment_service.dart` - Client that calls function
- `LIVE_STRIPE_DEPLOYMENT_GUIDE.md` - Testing protocol

## Next Steps
1. ✅ Fix deployed to production
2. ⏳ Test live payment with Pro monthly subscription
3. ⏳ Verify entitlements in Firestore
4. ⏳ Refund test charge immediately

---
**Resolution Time**: ~5 minutes from error to deployment
**Impact**: Critical - Blocked all live payments
**Risk Level**: High (production payment system)
**Fix Confidence**: High (defensive coding + double-safety)
