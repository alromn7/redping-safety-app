# Stripe Payment Integration - Setup Guide

## ✅ Completed Steps

1. **Stripe Publishable Key** - Added to `lib/config/stripe_config.dart`
   - Using: `pk_live_51SVNMiPlurWsomXvjlPBW...` (LIVE mode)
   - ⚠️ **WARNING**: You're using LIVE mode keys - real charges will occur!

2. **Flutter Integration** - Updated `payment_service.dart`
   - Stripe SDK initialization enabled
   - Package already installed: `flutter_stripe: ^11.1.0`

3. **Cloud Functions** - Added exports to `functions/src/index.ts`
   - `processSubscriptionPayment`
   - `cancelSubscription`
   - `updatePaymentMethod`
   - `getSubscriptionStatus`
   - `stripeWebhook`

---

## 🔴 Required Steps to Complete Integration

### 1. Configure Firebase Functions with Stripe Secret Key

⚠️ **CRITICAL**: Your SECRET key must be configured in Firebase (DO NOT put it in code!)

```bash
# Set your Stripe secret key (get from https://dashboard.stripe.com/apikeys)
firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET_KEY_HERE"

# Set webhook secret (get after creating webhook endpoint)
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"

# Verify configuration
firebase functions:config:get
```

---

### 2. Create Stripe Products & Prices

Go to https://dashboard.stripe.com/products and create:

#### **Product 1: Essential Plus**
- Name: "REDP!NG Essential Plus"
- Create 2 prices:
  - Monthly: Record the Price ID (e.g., `price_abc123...`)
  - Yearly: Record the Price ID

#### **Product 2: Pro**
- Name: "REDP!NG Pro"
- Create 2 prices:
  - Monthly: Record Price ID
  - Yearly: Record Price ID

#### **Product 3: Ultra**
- Name: "REDP!NG Ultra"
- Create 2 prices:
  - Monthly: Record Price ID
  - Yearly: Record Price ID

#### **Product 4: Family**
- Name: "REDP!NG Family"
- Create 2 prices:
  - Monthly: Record Price ID
  - Yearly: Record Price ID

---

### 3. Supply Stripe Price IDs (Recommended: Environment Override)

Current implementation uses `PRICE_IDS_LIVE` / `PRICE_IDS_TEST` plus optional JSON override `STRIPE_PRICE_IDS_JSON` inside `functions/src/subscriptionPayments.js`.

Preferred approach (no code edits each time):

```bash
# Example (TEST mode) JSON (escape quotes carefully on Windows)
firebase functions:config:set stripe.price_ids_json='{"essentialPlus":{"monthly":"price_test_essential_m","yearly":"price_test_essential_y"},"pro":{"monthly":"price_test_pro_m","yearly":"price_test_pro_y"},"ultra":{"monthly":"price_test_ultra_m","yearly":"price_test_ultra_y","memberMonthly":"price_test_ultra_member_m","memberYearly":"price_test_ultra_member_y"},"family":{"monthly":"price_test_family_m","yearly":"price_test_family_y"}}'

firebase deploy --only functions:processSubscriptionPayment
```

If editing code directly, update the maps rather than legacy single `PRICE_IDS` blocks referenced in older documentation. Do NOT modify compiled artifacts under `functions/lib/`.

---

### 4. Set Up Stripe Webhook

1. Go to https://dashboard.stripe.com/webhooks
2. Click **"Add endpoint"**
3. Enter endpoint URL:
   ```
   https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook
   ```
   Replace `YOUR_PROJECT_ID` with your Firebase project ID (e.g., `redping-a2e37`)

4. Select these events:
   - ✅ `invoice.payment_succeeded`
   - ✅ `invoice.payment_failed`
   - ✅ `customer.subscription.deleted`
   - ✅ `customer.subscription.updated`

5. Click **"Add endpoint"**
6. Copy the **Signing secret** (starts with `whsec_`)
7. Configure it in Firebase:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"
   ```

---

### 5. Deploy Cloud Functions

```bash
# Build TypeScript
cd functions
npm run build

# Deploy payment functions
cd ..
firebase deploy --only functions:processSubscriptionPayment,functions:cancelSubscription,functions:updatePaymentMethod,functions:getSubscriptionStatus,functions:stripeWebhook
```

---

### 6. Update Payment Service Implementation

The `lib/services/payment_service.dart` is currently MOCK. You need to:

**Key methods to implement:**

1. **`addPaymentMethod()`** - Replace mock with:
   ```dart
   // Create payment method using Stripe SDK
   final paymentMethod = await Stripe.instance.createPaymentMethod(
     params: PaymentMethodParams.card(
       paymentMethodData: PaymentMethodData(
         billingDetails: BillingDetails(/* ... */),
       ),
     ),
   );
   ```

2. **`processSubscriptionPayment()`** - Replace mock with:
   ```dart
   // Call Firebase Cloud Function
   final callable = FirebaseFunctions.instance.httpsCallable(
     'processSubscriptionPayment',
   );
   
   final result = await callable.call({
     'userId': userId,
     'tier': tier.name,
     'isYearly': isYearlyBilling,
     'paymentMethodId': paymentMethod.id,
     'savePaymentMethod': true,
   });
   ```

3. Handle 3D Secure authentication if required
4. Listen to Firestore for subscription status updates

---

## 🧪 Testing Checklist

### Test Cards (Stripe Test Mode)
- ✅ Success: `4242 4242 4242 4242`
- ❌ Decline: `4000 0000 0000 0002`
- 🔐 3D Secure: `4000 0025 0000 3155`

### Testing Steps
1. Switch to test keys first:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_test_..."
   ```
2. Update `StripeConfig.publishableKey` to `pk_test_...`
3. Create subscription with test card
4. Verify webhook events received
5. Check Firestore for subscription data
6. Test cancellation flow
7. Test payment failure handling

---

## 🚀 Go Live Checklist

Before accepting real payments:

- [ ] All 8 Stripe Price IDs supplied (via STRIPE_PRICE_IDS_JSON or updated maps) including Ultra member prices if used
- [ ] Secret key configured in Firebase Functions
- [ ] Webhook endpoint created and secret configured
- [ ] Payment functions deployed successfully
- [ ] Tested with Stripe test cards
- [ ] Verified webhooks working
- [ ] `PaymentService` mock code replaced with real implementation
- [ ] Privacy policy updated with payment processing info
- [ ] Terms of service include subscription terms
- [ ] Tested on real device (not just emulator)
- [ ] App Store/Play Store payment compliance verified

---

## ⚠️ Current Status

**PARTIALLY CONFIGURED** - ⚠️ Hybrid mock/local transaction handling persists; live key defaults in test path.

✅ Stripe SDK initialized
✅ Publishable key configured (LIVE mode)
✅ Cloud Functions code ready
✅ Cloud Functions exported

❌ Secret key not confirmed in Firebase (verify with `firebase functions:config:get stripe.secret_key`)
❌ Test Price IDs not provided (placeholders remain) or Ultra member IDs missing
❌ Payment functions not redeployed after config changes
❌ Webhook not configured
❌ PaymentService still using local mock transaction list
⚠️ Live publishable key present in test mode; override with `--dart-define STRIPE_PUBLISHABLE_KEY_TEST=pk_test_...`

**DO NOT enable payments in production until all steps complete!**

---

## 📞 Support Resources

- Stripe Dashboard: https://dashboard.stripe.com
- Stripe API Docs: https://stripe.com/docs/api
- Firebase Functions Config: https://firebase.google.com/docs/functions/config-env
- flutter_stripe Package: https://pub.dev/packages/flutter_stripe
