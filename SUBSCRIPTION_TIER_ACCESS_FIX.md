# 🎯 RedPing Subscription Tier Access & Limits Optimization

## Problem Identified

**Issue**: Pro plan user cannot access SAR Dashboard despite having active subscription

**Root Cause**: Missing `feature_sar_basic` entitlement in user document

**Your Account**: 
- User ID: `l9NlaE1c66MueSvPd2Fj4QhBUNs2`
- Plan: Pro Monthly ($9.99 AUD)
- Status: Active (paid via Stripe)
- Problem: SAR Dashboard showing upgrade prompt instead of dashboard

---

## Architecture Overview

### Entitlement System Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    Stripe Payment                             │
│                    (Pro - $9.99/mo)                          │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│            Cloud Function: processSubscriptionPayment         │
│   - Creates/updates Firestore subscription                   │
│   - Maps tier → features                                     │
│   - Writes entitlements to user document                     │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│              Firestore: users/{userId}                        │
│   {                                                          │
│     subscription: { tier: 'pro', ... },                      │
│     entitlements: {                                          │
│       features: [                                            │
│         'feature_sos_call',                                  │
│         'feature_hazard_alerts',                             │
│         'feature_ai_assistant',                              │
│         'feature_gadgets',                                   │
│         'feature_redping_mode',                              │
│         'feature_sar_basic'  ← CRITICAL                      │
│       ]                                                      │
│     }                                                        │
│   }                                                          │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│         Flutter App: EntitlementService                      │
│   - Listens to user document                                │
│   - Reads entitlements.features array                       │
│   - Provides hasFeature('feature_sar_basic')                │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│      SAR Dashboard: professional_sar_dashboard.dart          │
│   if (!EntitlementService.instance.hasFeature(              │
│        'feature_sar_basic')) {                               │
│     return UpgradeScreen();  ← YOU ARE HERE                  │
│   }                                                          │
│   return SARDashboard();                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## Subscription Tier Feature Matrix

| Feature | Free | Essential+ | Pro | Ultra | Family |
|---------|------|------------|-----|-------|--------|
| `feature_sos_call` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `feature_hazard_alerts` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `feature_ai_assistant` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `feature_gadgets` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `feature_redping_mode` | ❌ | ❌ | ✅ | ✅ | ❌ |
| `feature_sar_basic` | ❌ | ❌ | **✅** | ✅ | ❌ |
| `feature_sar_advanced` | ❌ | ❌ | ❌ | ✅ | ❌ |
| `feature_family_check_in` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `feature_find_my_gadget` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `feature_family_dashboard` | ❌ | ❌ | ❌ | ❌ | ✅ |

### Pro Plan Features ($9.99/month)

**Should include:**
1. ✅ `feature_sos_call` - Basic SOS functionality
2. ✅ `feature_hazard_alerts` - Weather/disaster alerts
3. ✅ `feature_ai_assistant` - AI Safety Assistant (24 commands)
4. ✅ `feature_gadgets` - Smartwatch/IoT integration
5. ✅ `feature_redping_mode` - All 16 activity modes
6. ✅ `feature_sar_basic` - **SAR Dashboard** (THIS IS MISSING!)

---

## Diagnosis Steps

### Check Your Current Entitlements

1. **Firebase Console Method:**
   - Go to https://console.firebase.google.com
   - Navigate to Firestore Database
   - Find document: `users/l9NlaE1c66MueSvPd2Fj4QhBUNs2`
   - Check `entitlements.features` array
   - Verify `feature_sar_basic` is present

2. **Expected Result:**
   ```javascript
   {
     subscription: {
       tier: 'pro',
       status: 'active',
       subscriptionId: 'sub_xxx...'
     },
     entitlements: {
       features: [
         'feature_sos_call',
         'feature_hazard_alerts',
         'feature_ai_assistant',
         'feature_gadgets',
         'feature_redping_mode',
         'feature_sar_basic'  // ← MUST BE HERE
       ],
       updatedAt: <timestamp>
     }
   }
   ```

3. **If Missing:**
   The Cloud Function didn't write entitlements correctly during payment processing

---

## Solution Options

### Option 1: Re-process Subscription (Recommended)

**Trigger payment webhook again:**

1. Go to Stripe Dashboard: https://dashboard.stripe.com
2. Find your subscription: `sub_xxx...`
3. Click "Send test webhook"
4. Select `customer.subscription.updated`
5. This will re-trigger the Cloud Function
6. Cloud Function will re-write entitlements

### Option 2: Manual Firestore Update

**Directly update entitlements in Firebase Console:**

1. Go to Firestore: `users/l9NlaE1c66MueSvPd2Fj4QhBUNs2`
2. Edit document
3. Add/Update `entitlements` field:
   ```json
   {
     "features": [
       "feature_sos_call",
       "feature_hazard_alerts",
       "feature_ai_assistant",
       "feature_gadgets",
       "feature_redping_mode",
       "feature_sar_basic"
     ],
     "updatedAt": <server_timestamp>
   }
   ```
4. Save
5. **Restart RedPing app** to reload entitlements

### Option 3: Use Firebase CLI

**Run from terminal:**

```bash
firebase firestore:update users/l9NlaE1c66MueSvPd2Fj4QhBUNs2 \
  --data '{
    "entitlements.features": [
      "feature_sos_call",
      "feature_hazard_alerts", 
      "feature_ai_assistant",
      "feature_gadgets",
      "feature_redping_mode",
      "feature_sar_basic"
    ]
  }'
```

### Option 4: Cloud Function Fix

**Check Cloud Function logs:**

```bash
cd functions
firebase functions:log --only processSubscriptionPayment
```

**Look for errors like:**
- "Failed to write entitlements"
- "TIER_FEATURES undefined"
- "User document update failed"

---

## Implementation Code Locations

### Cloud Function: `functions/src/subscriptionPayments.js`

**Line 194-198: Tier → Features Mapping**
```javascript
const TIER_FEATURES = {
  free: [FEATURES.sosCall],
  essentialPlus: [FEATURES.sosCall, FEATURES.hazardAlerts],
  pro: [
    FEATURES.sosCall,
    FEATURES.hazardAlerts,
    FEATURES.aiAssistant,
    FEATURES.gadgets,
    FEATURES.redpingMode,
    FEATURES.sarBasic  // ← Pro gets SAR access
  ],
  ultra: [..., FEATURES.sarBasic, FEATURES.sarAdvanced],
  // ...
};
```

**This mapping is CORRECT** ✅

### App: `lib/core/entitlements/entitlement_service.dart`

**Reads from Firestore:**
```dart
void start(String userId) {
  _subscription = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .listen((doc) {
    final data = doc.data();
    final List<dynamic>? list = 
        data?['entitlements']?['features'] as List<dynamic>?;
    _features = list == null
        ? const {}
        : list.whereType<String>().toSet();
    _featuresController.add(_features);
  });
}

bool hasFeature(String featureId) => _features.contains(featureId);
```

### SAR Dashboard: `lib/features/sar/presentation/pages/professional_sar_dashboard.dart`

**Line 99: Feature Gate**
```dart
final hasSarBasic = EntitlementService.instance
    .hasFeature('feature_sar_basic');

if (!hasSarBasic) {
  return _buildUpgradeScreen();  // ← Shows upgrade prompt
}

return _buildDashboard();  // ← Actual SAR dashboard
```

---

## Quick Fix Checklist

### Immediate Actions:

- [ ] **1. Open Firebase Console**
      → Firestore → `users/l9NlaE1c66MueSvPd2Fj4QhBUNs2`

- [ ] **2. Check entitlements.features array**
      → Should contain: `feature_sar_basic`

- [ ] **3. If missing, add manually:**
      ```
      entitlements.features = [
        "feature_sos_call",
        "feature_hazard_alerts",
        "feature_ai_assistant",
        "feature_gadgets",
        "feature_redping_mode",
        "feature_sar_basic"
      ]
      ```

- [ ] **4. Restart RedPing app**
      → Force close and reopen

- [ ] **5. Navigate to SAR Dashboard**
      → Should now show full dashboard instead of upgrade screen

### Verify Fix:

- [ ] SAR Dashboard loads without upgrade prompt
- [ ] Can see active SOS sessions
- [ ] Can see Help Requests
- [ ] Can respond to emergencies
- [ ] KPI metrics display correctly

---

## Prevention for Future Users

### Cloud Function Enhancement

**Add logging to verify entitlement writes:**

```javascript
// In processSubscriptionPayment function
const features = getFeaturesForTier(tier);
console.log(`Writing entitlements for tier ${tier}:`, features);

await userRef.update({
  'entitlements.features': features,
  'entitlements.updatedAt': admin.firestore.FieldValue.serverTimestamp()
});

console.log(`✅ Entitlements written successfully for user ${userId}`);
```

### Add Entitlement Verification

**Create verification endpoint:**

```javascript
exports.verifyEntitlements = onCall(async (request) => {
  const userId = request.auth.uid;
  const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
  
  const subscription = userDoc.data()?.subscription;
  const entitlements = userDoc.data()?.entitlements;
  
  const expectedFeatures = getFeaturesForTier(subscription.tier);
  const actualFeatures = entitlements?.features || [];
  
  const missing = expectedFeatures.filter(f => !actualFeatures.includes(f));
  
  if (missing.length > 0) {
    console.warn(`⚠️ Missing entitlements for ${userId}:`, missing);
    
    // Auto-fix
    await admin.firestore().collection('users').doc(userId).update({
      'entitlements.features': expectedFeatures
    });
    
    return { fixed: true, addedFeatures: missing };
  }
  
  return { verified: true };
});
```

---

## Testing After Fix

### Verification Steps:

1. **Open RedPing App**
2. **Navigate: SOS → SAR Dashboard**
3. **Expected: Full dashboard loads**
4. **Test actions:**
   - View active SOS sessions
   - View Help Requests
   - Click "Acknowledge" on a ping
   - Click "Respond" button

### If Still Not Working:

**Check EntitlementService initialization:**

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Make sure this runs after sign-in:
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    EntitlementService.instance.start(user.uid);
  }
  
  runApp(MyApp());
}
```

---

## Subscription Limits Reference

### Pro Plan Limits:

| Feature | Limit |
|---------|-------|
| SOS Alerts | Unlimited |
| Emergency Contacts | Unlimited |
| RedPing Help | Unlimited |
| Community Chat | Full access |
| Quick Call | ✅ Enabled |
| Map Access | ✅ Enabled |
| Medical Profile | ✅ Enabled |
| ACFD | ✅ Auto + Manual |
| RedPing Mode | ✅ All 16 modes |
| Hazard Alerts | ✅ Enabled |
| AI Assistant | ✅ 24 commands |
| SOS SMS | ✅ Enabled |
| Gadget Integration | ✅ All devices |
| **SAR Dashboard** | **✅ Full access** |
| SAR Admin | ❌ Requires Ultra |
| Satellite Messages | 100/month |
| SAR Participation | ✅ Volunteer missions |
| Organization Management | ❌ Requires Ultra |

---

## Contact & Support

### Firebase Console:
- Project: redping-safety-app
- User ID: `l9NlaE1c66MueSvPd2Fj4QhBUNs2`
- Collection: `users`

### Stripe Dashboard:
- Subscription ID: Check Firebase → `users/{uid}/subscription/subscriptionId`
- Plan: Pro Monthly ($9.99 AUD)

### Next Steps:

1. **Verify entitlements in Firebase Console** (5 minutes)
2. **Add missing `feature_sar_basic` if needed** (1 minute)
3. **Restart app** (1 minute)
4. **Test SAR Dashboard access** (2 minutes)

**Total fix time: ~10 minutes** ⏱️

---

## Summary

**Problem**: Pro subscription not granting SAR Dashboard access  
**Cause**: Missing `feature_sar_basic` in user entitlements  
**Solution**: Add feature manually in Firebase or re-trigger subscription webhook  
**Prevention**: Enhanced Cloud Function logging + auto-verification  

**Your subscription IS valid** - this is purely an entitlement sync issue! ✅
