# 🚀 RedPing Subscription Quick Start Guide

## For Developers Who Need to Get Started NOW

### What You Have
✅ Complete subscription system (5 tiers)
✅ Payment UI (credit card entry)
✅ Subscription management pages
✅ Mock payment service (works in dev)
✅ Production Stripe integration (ready to enable)
✅ Cloud Functions (ready to deploy)

---

## Option 1: Test in Development (5 Minutes)

### Just Want to See It Work?

**Step 1: Run the App**
```bash
cd c:\flutterapps\redping_14v
flutter run
```

**Step 2: Navigate to Subscription**
1. Open app → Go to Profile
2. Tap subscription card → "View Plans"
3. Select any paid tier → Tap "Subscribe"
4. Enter test card: `4242 4242 4242 4242`
5. Expiry: `12/25`, CVC: `123`, Name: `Test User`
6. Tap "Pay"

**Step 3: Watch the Magic**
- Payment processes (2 second delay for mock)
- Success dialog appears
- Subscription activated
- Features unlock immediately

**That's it!** You're using the mock payment service. No Stripe setup needed for development.

---

## Option 2: Enable Production Stripe (2 Hours)

### Want Real Payments? Follow These Steps:

#### A. Create Stripe Account (30 min)
1. Go to https://stripe.com
2. Sign up → Complete verification
3. Go to **Products** → Create 4 products:
   - Essential+ ($4.99/mo, $49.99/yr)
   - Pro ($9.99/mo, $99.99/yr)
   - Ultra ($29.99/mo, $299.99/yr)
   - Family ($19.99/mo, $199.99/yr)
4. Copy all 8 Price IDs (4 products × 2 billing periods)

#### B. Get API Keys (5 min)
1. **Developers** → **API Keys**
2. Copy:
   - Test Publishable Key: `pk_test_...`
   - Test Secret Key: `sk_test_...`
3. Copy:
   - Live Publishable Key: `pk_live_...`
   - Live Secret Key: `sk_live_...`

#### C. Update Your Code (10 min)
```dart
// lib/core/config/app_environment.dart
// Line 15-30, replace with YOUR keys:

static String get stripePublishableKey {
  switch (environment) {
    case Environment.development:
      return 'pk_test_YOUR_KEY_HERE'; // ← Your test key
    case Environment.production:
      return 'pk_live_YOUR_KEY_HERE'; // ← Your live key
  }
}
```

```javascript
// functions/src/subscriptionPayments.js
// Line 35-51, replace with YOUR Price IDs:

const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_YOUR_ID_HERE', // ← Your Price ID
    yearly: 'price_YOUR_ID_HERE',
  },
  // ... repeat for all tiers
};
```

#### D. Deploy Cloud Functions (30 min)
```bash
cd functions
npm install

# Set Stripe keys
firebase functions:config:set \
  stripe.secret_key="sk_test_YOUR_KEY" \
  stripe.webhook_secret="whsec_YOUR_SECRET"

# Deploy
firebase deploy --only functions
```

#### E. Update App to Use Production Service (15 min)
```dart
// lib/main.dart
// Add at top:
import 'core/services/stripe_initializer.dart';

// In main(), before runApp():
await StripeInitializer.initialize();
```

```bash
flutter pub get
flutter run
```

#### F. Test Real Payment (10 min)
1. Run app → Go to subscription plans
2. Use test card: `4242 4242 4242 4242`
3. Complete payment
4. Check Stripe Dashboard → Payments
5. Verify subscription created

**Done!** You're now using real Stripe payments (in test mode).

---

## Option 3: Production Deployment (4 Hours)

### Ready to Launch? Complete Checklist:

#### 1. Switch to Live Keys (30 min)
- [ ] Update `app_environment.dart` with live publishable key
- [ ] Set live secret key in Firebase config
- [ ] Update webhook signing secret
- [ ] Verify all Price IDs are live (start with `price_live_`)

#### 2. Configure Webhooks (15 min)
- [ ] Stripe Dashboard → Webhooks → Add Endpoint
- [ ] URL: `https://us-central1-YOUR-PROJECT.cloudfunctions.net/stripeWebhook`
- [ ] Events: `invoice.*`, `customer.subscription.*`
- [ ] Copy signing secret → Update Firebase config

#### 3. iOS Setup (1 hour)
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Add Apple Pay capability
- [ ] Create merchant ID: `merchant.com.redping.redping`
- [ ] Update Info.plist
- [ ] Test on physical device

#### 4. Android Setup (30 min)
- [ ] Update `android/app/build.gradle` (minSdk 21)
- [ ] Add 3D Secure activity to AndroidManifest.xml
- [ ] Test on physical device

#### 5. Build Release (1 hour)
```bash
flutter build appbundle --release  # Android
flutter build ipa --release         # iOS
```

#### 6. Deploy (1 hour)
- [ ] Upload to Play Console
- [ ] Upload to App Store Connect
- [ ] Submit for review
- [ ] Monitor first transactions

---

## Testing Cheat Sheet

### Test Cards (Stripe Test Mode)

**Success:**
```
Card: 4242 4242 4242 4242
Exp: 12/25
CVC: 123
Result: ✅ Payment succeeds
```

**3D Secure (requires authentication):**
```
Card: 4000 0027 6000 3184
Exp: 12/25
CVC: 123
Result: ✅ Auth challenge → Success
```

**Declined:**
```
Card: 4000 0000 0000 0002
Exp: 12/25
CVC: 123
Result: ❌ Card declined
```

**Insufficient Funds:**
```
Card: 4000 0000 0000 9995
Exp: 12/25
CVC: 123
Result: ❌ Insufficient funds
```

---

## Quick Navigation

### Where to Find Things

**Payment UI:**
```
Profile → Subscription Card → View Plans → Select Tier
  → Payment Page (lib/features/subscription/presentation/pages/payment_page.dart)
```

**Manage Subscription:**
```
Profile → Subscription Card (if subscribed)
  → Management Page (lib/features/subscription/presentation/pages/subscription_management_page.dart)
```

**Payment Methods:**
```
Management Page → Manage Payment Methods
  → Payment Methods Page (lib/features/subscription/presentation/pages/payment_methods_page.dart)
```

**Billing History:**
```
Management Page → View All
  → Billing History (lib/features/subscription/presentation/pages/billing_history_page.dart)
```

---

## Common Issues & Fixes

### "Payment Failed - Unknown Error"
**Fix:** Check Cloud Functions logs
```bash
firebase functions:log --only processSubscriptionPayment
```

### "Stripe not initialized"
**Fix:** Add initialization to main.dart
```dart
await StripeInitializer.initialize();
```

### "Invalid API Key"
**Fix:** Verify Firebase config
```bash
firebase functions:config:get
```

### "Webhook signature verification failed"
**Fix:** Update webhook secret in Firebase
```bash
firebase functions:config:set stripe.webhook_secret="whsec_..."
```

### "3D Secure not working"
**Fix:** Check URL scheme in AndroidManifest.xml / Info.plist

---

## Resources

### Documentation (Start Here)
- **Full Guide:** [SUBSCRIPTION_SYSTEM_COMPLETE.md](./SUBSCRIPTION_SYSTEM_COMPLETE.md)
- **Setup Steps:** [STRIPE_PRODUCTION_SETUP.md](./STRIPE_PRODUCTION_SETUP.md)
- **Testing:** [SUBSCRIPTION_TESTING_GUIDE.md](./SUBSCRIPTION_TESTING_GUIDE.md)
- **Deployment:** [PRODUCTION_DEPLOYMENT_CHECKLIST.md](./PRODUCTION_DEPLOYMENT_CHECKLIST.md)

### External Docs
- **Stripe:** https://stripe.com/docs
- **Flutter Stripe:** https://pub.dev/packages/flutter_stripe
- **Firebase Functions:** https://firebase.google.com/docs/functions

### Get Help
- **Stripe Support:** https://support.stripe.com
- **Firebase Support:** https://firebase.google.com/support
- **Stack Overflow:** Tags: [flutter], [stripe], [firebase]

---

## What's Next?

### Development → Staging
1. ✅ Test in dev with mock payments (done)
2. → Deploy Cloud Functions to dev
3. → Test with Stripe test cards
4. → Deploy to staging
5. → Full integration testing

### Staging → Production
1. → Switch to live Stripe keys
2. → Deploy Cloud Functions to prod
3. → Configure production webhooks
4. → Build release versions
5. → Deploy to stores
6. → Monitor first transactions

---

## Need Help?

### In Development?
- Use mock payment service (it's already working!)
- Test cards work in development mode
- No Stripe account needed

### Ready for Production?
- Follow **Option 2** above (2 hours)
- Complete **Option 3** checklist (4 hours)
- Read full docs in project root

### Stuck?
- Check Cloud Functions logs: `firebase functions:log`
- Check Stripe Dashboard: https://dashboard.stripe.com
- Review error messages in app logs
- Consult documentation files

---

**Remember:** The system works out-of-the-box with mock payments. Real Stripe integration is optional for development!

*Quick Start Guide v1.0 - November 16, 2025*
