# RedPing Live Stripe Release - Deployment Guide

**Build Date:** November 30, 2025 00:24:08  
**APK Size:** 95.34 MB  
**SHA256:** `0D69CFD07CB4A1B2EDA07E520637BC5ACB8AA37C228330F8A1C32EA26BAD6F72`

---

## ⚠️ CRITICAL: LIVE MODE ACTIVE

This APK contains **LIVE Stripe payment keys** and will process **REAL credit card charges**.

### Embedded Configuration
- **Publishable Key:** `pk_live_51SVNMiPlurWsomXv...` (embedded in APK)
- **Backend Secret:** `sk_live_51SVNMiPlurWsomXv...` (functions/.env)
- **Price IDs:** All 8 LIVE recurring prices configured
- **Mode:** Release with code obfuscation enabled

---

## 📋 Pre-Installation Checklist

### Backend Verification
- [ ] Verify Firebase Functions deployed with LIVE keys
  ```powershell
  firebase deploy --only functions:processSubscriptionPayment
  ```

- [ ] Check functions environment config
  ```powershell
  firebase functions:config:get stripe
  ```

- [ ] Verify webhook endpoint active
  - URL: `https://us-central1-redping-a2e37.cloudfunctions.net/stripeWebhook`
  - Events: invoice.payment_succeeded, customer.subscription.*

### Stripe Dashboard Verification
- [ ] Confirm in LIVE mode (toggle in left sidebar)
- [ ] Verify all 8 products active:
  - Essential Plus (Monthly + Yearly)
  - Pro (Monthly + Yearly)
  - Ultra (Monthly + Yearly)
  - Family (Monthly + Yearly)
- [ ] Check webhook endpoint receiving events

---

## 🚀 Installation Steps

### 1. Install APK on Test Device

```powershell
# Connect device via USB with debugging enabled
adb devices

# Install the release APK
adb install build\app\outputs\flutter-apk\app-release.apk

# Or reinstall if already present
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### 2. Launch Application

```powershell
# Launch the app
adb shell am start -n com.redping.redping/.MainActivity

# Monitor logs (optional)
adb logcat -s flutter
```

---

## 🧪 Live Payment Testing Protocol

### Test Scenario 1: Pro Monthly Subscription

**CRITICAL:** Use a REAL payment method - test cards won't work in live mode!

1. **Sign In**
   - Use email/password (not anonymous)
   - Verify user authenticated in Firebase Console

2. **Navigate to Subscription**
   - Open Settings → Subscription Plans
   - Select "Pro" tier
   - Choose "Monthly" billing

3. **Enter Payment Details**
   - Use a REAL credit card you can refund
   - Recommended: Use your own card for testing
   - Amount: $9.99 AUD/month

4. **Complete Purchase**
   - Confirm payment
   - Wait for processing (5-10 seconds)

5. **Verify Entitlements**
   ```powershell
   # Check Firestore entitlements
   node functions/scripts/verify_entitlements.js --user YOUR_UID
   ```

   Expected features for Pro:
   - feature_sos_call
   - feature_hazard_alerts
   - feature_ai_assistant
   - feature_gadgets
   - feature_redping_mode
   - feature_sar_basic

6. **Test Feature Access**
   - Navigate to AI Assistant (should be unlocked)
   - Navigate to Gadgets Management (should be unlocked)
   - Navigate to SAR Dashboard (should show basic features)

7. **Verify Stripe Dashboard**
   - Check subscription created
   - Verify payment succeeded
   - Note subscription ID

### Test Scenario 2: Subscription Cancellation

1. **Cancel in App**
   - Settings → Manage Subscription → Cancel
   - Verify cancellation effective at period end

2. **Verify Cancellation**
   ```powershell
   node functions/scripts/check_subscription_status.js --user YOUR_UID
   ```

3. **Check Stripe Dashboard**
   - Subscription status: "Canceled" (active until period end)

### Test Scenario 3: Immediate Refund

⚠️ **IMPORTANT:** Issue refund immediately after test!

1. **In Stripe Dashboard**
   - Go to Payments → Recent payments
   - Find the test payment
   - Click "Refund" → Full refund
   - Add reason: "Test transaction"

2. **Cancel Subscription**
   - Go to Subscriptions
   - Find test subscription
   - Cancel immediately (don't wait for period end)

---

## 📊 Monitoring & Verification

### Firebase Console Checks

1. **Authentication**
   ```
   Firebase Console → Authentication → Users
   Verify test user exists
   ```

2. **Firestore Data**
   ```
   Firebase Console → Firestore → users/{uid}
   Check:
   - subscription.stripeSubscriptionId
   - subscription.status: "active"
   - entitlements.features: [array of features]
   ```

3. **Functions Logs**
   ```powershell
   # View recent function logs
   firebase functions:log --only processSubscriptionPayment --limit 50
   ```

### Stripe Dashboard Monitoring

1. **Payment Verification**
   - Payments → Recent → Check successful charge
   - Amount matches tier price
   - Currency: AUD

2. **Subscription Status**
   - Subscriptions → Active
   - Verify correct price ID
   - Check next billing date

3. **Webhook Events**
   - Developers → Webhooks → Recent deliveries
   - Verify events delivered successfully
   - Check for any failures

---

## 🔍 Troubleshooting

### Payment Fails with "Invalid Key"

**Cause:** Mismatch between publishable and secret keys

**Fix:**
1. Verify keys match in Stripe Dashboard
2. Ensure both are LIVE mode keys
3. Redeploy functions with correct `.env`

### Entitlements Not Updated

**Cause:** Webhook not firing or function error

**Fix:**
1. Check Functions logs for errors
2. Verify webhook endpoint in Stripe
3. Manually trigger webhook test event

### "Authentication Required" Error

**Cause:** User not properly authenticated

**Fix:**
1. Sign out and sign in with email/password
2. Verify user has email verified
3. Check Firebase Auth token is valid

---

## 🎯 Success Criteria

Before proceeding to production distribution:

- [x] APK builds successfully with LIVE keys
- [ ] Test subscription completes successfully
- [ ] Entitlements write to Firestore correctly
- [ ] Feature gates unlock appropriately
- [ ] Subscription cancellation works
- [ ] Test payment refunded successfully
- [ ] Webhook events deliver consistently
- [ ] No errors in Firebase logs
- [ ] Stripe Dashboard shows correct data

---

## 📝 Post-Test Actions

After successful testing:

1. **Refund Test Charge**
   - Process full refund in Stripe Dashboard
   - Verify refund completes

2. **Clean Test Data**
   ```powershell
   # Optional: Clear test subscription data
   node functions/scripts/cancel_subscription.js --user YOUR_UID
   ```

3. **Document Issues**
   - Note any bugs encountered
   - Record error messages
   - Screenshot problematic flows

4. **Production Checklist**
   - Update privacy policy with payment terms
   - Add subscription terms to app
   - Prepare App Store/Play Store listing
   - Set up production monitoring/alerts

---

## 🚨 Emergency Rollback

If critical issues discovered:

1. **Remove from Distribution**
   - Unpublish from stores immediately
   - Disable download links

2. **Switch to Test Mode**
   ```powershell
   # Redeploy functions with test keys
   firebase functions:config:set stripe.secret_key="sk_test_..."
   firebase deploy --only functions
   ```

3. **Issue Refunds**
   - Refund all affected customers
   - Send notification email

---

## 📞 Support Contacts

- **Stripe Support:** https://support.stripe.com
- **Firebase Support:** https://firebase.google.com/support
- **Emergency:** Review Firebase Functions logs immediately

---

## 🎉 Ready for Testing

APK Location: `build\app\outputs\flutter-apk\app-release.apk`

Install command:
```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

**Remember:** This is LIVE mode - all transactions are real!
