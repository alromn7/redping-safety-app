# Set Admin Account to Ultra Subscription

## Manual Update via Firebase Console

1. Go to Firebase Console: https://console.firebase.google.com/project/redping-a2e37/firestore

2. Navigate to Firestore Database → `users` collection

3. Find your user document by filtering or searching for email: `alromn7@gmail.com`

4. Update/Add the `subscription` field with this data:

```json
{
  "tier": "ultra",
  "status": "active",
  "isActive": true,
  "autoRenew": true,
  "isYearlyBilling": false,
  "currentPeriodStart": "<current_timestamp>",
  "currentPeriodEnd": "<1_year_from_now_timestamp>",
  "nextBillingDate": "<1_year_from_now_timestamp>",
  "updatedAt": "<current_timestamp>",
  "stripeCustomerId": "admin_test_customer",
  "stripeSubscriptionId": "admin_test_subscription",
  "additionalMembers": 0,
  "totalMembers": 1
}
```

5. Update/Add the `entitlements` field with this data:

```json
{
  "features": [
    "feature_sos_call",
    "feature_hazard_alerts",
    "feature_ai_assistant",
    "feature_gadgets",
    "feature_redping_mode",
    "feature_sar_basic",
    "feature_sar_advanced"
  ],
  "updatedAt": "<current_timestamp>"
}
```

## Alternative: Use Firebase Console UI

### Step-by-Step:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/project/redping-a2e37/firestore/databases/-default-/data/~2Fusers

2. **Find Your User Document**
   - Look for the document with your UID (should have email field = alromn7@gmail.com)
   - Or use Filter: `email == alromn7@gmail.com`

3. **Add/Update `subscription` Map Field:**
   - Click "Add field" or edit existing `subscription` field
   - Field name: `subscription`
   - Field type: `map`
   - Add these sub-fields:
     * `tier` (string): `"ultra"`
     * `status` (string): `"active"`
     * `isActive` (boolean): `true`
     * `autoRenew` (boolean): `true`
     * `isYearlyBilling` (boolean): `false`
     * `currentPeriodStart` (timestamp): Click "Set to current time"
     * `currentPeriodEnd` (timestamp): Set to 1 year from now
     * `nextBillingDate` (timestamp): Set to 1 year from now
     * `updatedAt` (timestamp): Click "Set to current time"
     * `stripeCustomerId` (string): `"admin_test_customer"`
     * `stripeSubscriptionId` (string): `"admin_test_subscription"`
     * `additionalMembers` (number): `0`
     * `totalMembers` (number): `1`

4. **Add/Update `entitlements` Map Field:**
   - Click "Add field" or edit existing `entitlements` field
   - Field name: `entitlements`
   - Field type: `map`
   - Add these sub-fields:
     * `features` (array): Add these strings one by one:
       - `feature_sos_call`
       - `feature_hazard_alerts`
       - `feature_ai_assistant`
       - `feature_gadgets`
       - `feature_redping_mode`
       - `feature_sar_basic`
       - `feature_sar_advanced`
     * `updatedAt` (timestamp): Click "Set to current time"

5. **Save Changes**

6. **Restart the RedPing App**
   - Force close the app
   - Reopen it
   - `EntitlementService` will automatically load the new entitlements
   - You should now have full Ultra access!

## What You'll Get with Ultra:

✅ All Pro features
✅ SAR Dashboard (Full Access - View + Write)
✅ SAR Admin Management
✅ Organization Management
✅ Team Management
✅ Advanced Analytics
✅ No "Upgrade" buttons on SAR Dashboard
✅ All action buttons visible (Acknowledge, Assign, Resolve, etc.)

## Verification:

After updating, check in the app:
1. Profile page should show "Ultra" tier
2. SAR Dashboard should load without permission errors
3. SOS card action buttons should be visible (not showing "Upgrade to Pro")
4. No subscription prompts anywhere
