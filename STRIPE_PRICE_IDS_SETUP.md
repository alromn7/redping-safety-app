# 🎯 STRIPE PRICE IDS CONFIGURATION GUIDE

**After creating products in Stripe Dashboard, follow these steps to complete integration.**

---

## 📋 Step 1: Copy Price IDs from Stripe Dashboard

After creating each product in Stripe, you'll see **Price IDs** like `price_1A2B3C4D5E6F...`

### Where to find them:
1. Go to https://dashboard.stripe.com/products
2. Click on each product you created
3. Under "Pricing" section, you'll see the Price ID
4. Copy each Price ID

### Example Price IDs (yours will be different):
```
Essential+ Monthly: price_1Q2W3E4R5T6Y7U8I9O0P
Essential+ Yearly: price_0P9O8I7U6Y5T4R3E2W1Q
Pro Monthly: price_1A2S3D4F5G6H7J8K9L0Z
Pro Yearly: price_0Z9L8K7J6H5G4F3D2S1A
Ultra Monthly: price_1X2C3V4B5N6M7Q8W9E0R
Ultra Yearly: price_0R9E8W7Q6M5N4B3V2C1X
Family Monthly: price_1Z2X3C4V5B6N7M8A9S0D
Family Yearly: price_0D9S8A7M6N5B4V3C2X1Z
```

---

## 🔧 Step 2: Update Firebase Functions

### File: `functions/src/subscriptionPayments.js`

**Current configuration (lines 27-43):**
```javascript
const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_xxxxx_essential_monthly',
    yearly: 'price_xxxxx_essential_yearly',
  },
  pro: {
    monthly: 'price_xxxxx_pro_monthly',
    yearly: 'price_xxxxx_pro_yearly',
  },
  ultra: {
    monthly: 'price_xxxxx_ultra_monthly',
    yearly: 'price_xxxxx_ultra_yearly',
  },
  family: {
    monthly: 'price_xxxxx_family_monthly',
    yearly: 'price_xxxxx_family_yearly',
  },
};
```

**Replace with your actual Price IDs:**
```javascript
const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_1Q2W3E4R5T6Y7U8I9O0P',  // ← Your Essential+ monthly Price ID
    yearly: 'price_0P9O8I7U6Y5T4R3E2W1Q',   // ← Your Essential+ yearly Price ID
  },
  pro: {
    monthly: 'price_1A2S3D4F5G6H7J8K9L0Z',  // ← Your Pro monthly Price ID
    yearly: 'price_0Z9L8K7J6H5G4F3D2S1A',   // ← Your Pro yearly Price ID
  },
  ultra: {
    monthly: 'price_1X2C3V4B5N6M7Q8W9E0R',  // ← Your Ultra monthly Price ID
    yearly: 'price_0R9E8W7Q6M5N4B3V2C1X',   // ← Your Ultra yearly Price ID
  },
  family: {
    monthly: 'price_1Z2X3C4V5B6N7M8A9S0D',  // ← Your Family monthly Price ID
    yearly: 'price_0D9S8A7M6N5B4V3C2X1Z',   // ← Your Family yearly Price ID
  },
};
```

---

## 📱 Step 3: Update Flutter App

### File: `lib/core/config/app_environment.dart`

**Current configuration (lines 89-105):**
```dart
case Environment.production:
  return {
    'essentialPlus': {
      'monthly': 'price_live_essential_monthly',
      'yearly': 'price_live_essential_yearly',
    },
    'pro': {
      'monthly': 'price_live_pro_monthly',
      'yearly': 'price_live_pro_yearly',
    },
    'ultra': {
      'monthly': 'price_live_ultra_monthly',
      'yearly': 'price_live_ultra_yearly',
    },
    'family': {
      'monthly': 'price_live_family_monthly',
      'yearly': 'price_live_family_yearly',
    },
  };
```

**Replace with your actual Price IDs:**
```dart
case Environment.production:
  return {
    'essentialPlus': {
      'monthly': 'price_1Q2W3E4R5T6Y7U8I9O0P',  // ← Your Essential+ monthly
      'yearly': 'price_0P9O8I7U6Y5T4R3E2W1Q',   // ← Your Essential+ yearly
    },
    'pro': {
      'monthly': 'price_1A2S3D4F5G6H7J8K9L0Z',  // ← Your Pro monthly
      'yearly': 'price_0Z9L8K7J6H5G4F3D2S1A',   // ← Your Pro yearly
    },
    'ultra': {
      'monthly': 'price_1X2C3V4B5N6M7Q8W9E0R',  // ← Your Ultra monthly
      'yearly': 'price_0R9E8W7Q6M5N4B3V2C1X',   // ← Your Ultra yearly
    },
    'family': {
      'monthly': 'price_1Z2X3C4V5B6N7M8A9S0D',  // ← Your Family monthly
      'yearly': 'price_0D9S8A7M6N5B4V3C2X1Z',   // ← Your Family yearly
    },
  };
```

---

## 🚀 Step 4: Deploy Changes

### 4.1 Build and Deploy Firebase Functions
```powershell
# Navigate to functions directory
cd functions

# Install dependencies (if needed)
npm install

# Build TypeScript
npm run build

# Return to root
cd ..

# Deploy functions
firebase deploy --only functions
```

Expected output:
```
✔  functions: Finished running predeploy script.
i  functions: updating Node.js 18 function processSubscriptionPayment(us-central1)...
i  functions: updating Node.js 18 function stripeWebhook(us-central1)...
✔  functions[processSubscriptionPayment(us-central1)] Successful update operation.
✔  functions[stripeWebhook(us-central1)] Successful update operation.

✔  Deploy complete!
```

### 4.2 Rebuild Flutter App
```powershell
# Clean build cache
flutter clean

# Build release APK
flutter build apk --release

# Install on device (if testing)
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

---

## ✅ Step 5: Verify Configuration

### Check Firebase Functions Logs
```powershell
firebase functions:log --only processSubscriptionPayment
```

Look for:
- ✅ No "Invalid Price ID" errors
- ✅ Successful subscription creation logs

### Test in App
1. Open app on device
2. Navigate to subscription page
3. Select Essential+ tier
4. Use Stripe test card: **4242 4242 4242 4242**
5. Verify payment processes successfully
6. Check Firebase Console → Firestore → `users` → `subscriptions`

---

## 🎯 Quick Commands Summary

```powershell
# 1. Update Firebase Functions code
# Edit: functions/src/subscriptionPayments.js (lines 27-43)

# 2. Update Flutter app code
# Edit: lib/core/config/app_environment.dart (lines 89-105)

# 3. Deploy Firebase Functions
cd functions; npm run build; cd ..; firebase deploy --only functions

# 4. Rebuild Flutter app
flutter clean; flutter build apk --release

# 5. Install on device
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

---

## 📝 Price ID Checklist

Use this checklist when copying Price IDs:

```
☐ Essential+ Monthly Price ID: price_________________
☐ Essential+ Yearly Price ID: price_________________
☐ Pro Monthly Price ID: price_________________
☐ Pro Yearly Price ID: price_________________
☐ Ultra Monthly Price ID: price_________________
☐ Ultra Yearly Price ID: price_________________
☐ Family Monthly Price ID: price_________________
☐ Family Yearly Price ID: price_________________

☐ Updated functions/src/subscriptionPayments.js
☐ Updated lib/core/config/app_environment.dart
☐ Deployed Firebase Functions
☐ Rebuilt Flutter app
☐ Tested subscription flow
```

---

## 🔍 Files to Edit

### 1. Firebase Functions
**Path:** `c:\flutterapps\redping_14v\functions\src\subscriptionPayments.js`
**Lines:** 27-43
**What to change:** Replace placeholder Price IDs with real ones

### 2. Flutter App
**Path:** `c:\flutterapps\redping_14v\lib\core\config\app_environment.dart`
**Lines:** 89-105 (production section)
**What to change:** Replace placeholder Price IDs with real ones

---

## ⚠️ Important Notes

1. **Use LIVE Price IDs** - Make sure you're using live mode Price IDs (start with `price_live_` or similar)
2. **Match exactly** - Copy-paste Price IDs exactly as shown in Stripe Dashboard
3. **Monthly vs Yearly** - Ensure you're using the correct Price ID for monthly vs yearly billing
4. **Test Mode** - For development/testing, keep test Price IDs in development section (lines 68-87)

---

## 🆘 Troubleshooting

### "Invalid Price ID" Error
- Double-check Price ID in Stripe Dashboard
- Ensure you're using the correct mode (test vs live)
- Verify no extra spaces or typos

### Subscription Not Creating
- Check Firebase Functions logs: `firebase functions:log`
- Verify Stripe webhook is receiving events
- Check Firestore for error logs in `errors` collection

### Payment Fails
- Ensure Stripe secret key is configured: `firebase functions:config:get`
- Verify webhook secret is correct
- Check Stripe Dashboard → Events for errors

---

**Next Step:** Once you have your Price IDs from Stripe, provide them and I'll help you update the code files!

**Document Created:** November 21, 2025  
**Status:** Ready to configure after Stripe product creation
