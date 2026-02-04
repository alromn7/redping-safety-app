# Stripe Payment Integration - Manual Setup Steps

## Status: ✅ Cloud Functions Deployed Successfully

All payment Cloud Functions have been deployed and are operational:
- ✅ `processSubscriptionPayment` - Creates/updates Stripe subscriptions
- ✅ `cancelSubscription` - Cancels subscriptions at period end
- ✅ `updatePaymentMethod` - Updates customer payment methods
- ✅ `getSubscriptionStatus` - Retrieves subscription details
- ✅ `stripeWebhook` - Handles Stripe webhook events

**Webhook URL**: `https://stripewebhook-24nj73cvwq-uc.a.run.app`

---

## Summary of Changes Made

### PaymentService Implementation (✅ Complete)
- **Replaced MOCK implementation** with real Stripe SDK integration
- **Added Cloud Functions integration** for secure server-side payment processing
- **Real payment method creation** using `Stripe.instance.createPaymentMethod()`
- **Real subscription processing** via `processSubscriptionPayment` Cloud Function
- **Real cancellation** via `cancelSubscription` Cloud Function
- **Currency updated** from USD to AUD (Australian Dollar)
- **All lint errors resolved** - code compiles successfully

### Cloud Functions (✅ Deployed)
- **Lazy Stripe initialization** - Fixed container healthcheck timeout issues
- **All 5 functions healthy** with 256MB memory allocation
- **Webhook endpoint live** at: https://stripewebhook-24nj73cvwq-uc.a.run.app

---

## Required Manual Steps (User Action Needed)

### 1. Create Yearly Price IDs in Stripe Dashboard ⚠️ REQUIRED

You need to create 4 yearly subscription prices in your Stripe Dashboard.

**Steps:**
1. Go to https://dashboard.stripe.com/products
2. For each existing monthly product (Essential Plus, Pro, Ultra, Family):
   - Click on the product
   - Click "Add another price"
   - Set billing period to "Yearly"
   - Set the appropriate yearly price (typically monthly × 12 with discount)
   - Save the price
   - **Copy the Price ID** (format: `price_xxxxxxxxxxxxx`)

3. Update `functions/src/subscriptionPayments.js` with the new Price IDs:
   ```javascript
   const PRICE_IDS = {
     essentialPlus: {
       monthly: 'price_1SVjOcPlurWsomXvo3cJ8YO9',
       yearly: 'price_PASTE_HERE', // Replace this
     },
     pro: {
       monthly: 'price_1SVjOIPlurWsomXvOvgWfPFK',
       yearly: 'price_PASTE_HERE', // Replace this
     },
     ultra: {
       monthly: 'price_1SVjNIPlurWsomXvMAxQouxd',
       yearly: 'price_PASTE_HERE', // Replace this
     },
     family: {
       monthly: 'price_1SVjO7PlurWsomXv9CCcDrGF',
       yearly: 'price_PASTE_HERE', // Replace this
     },
   };
   ```

4. After updating, redeploy functions:
   ```bash
   cd functions
   Copy-Item "src\subscriptionPayments.js" -Destination "lib\subscriptionPayments.js" -Force
   cd ..
   firebase deploy --only functions:processSubscriptionPayment,functions:getSubscriptionStatus
   ```

---

### 2. Configure Stripe Webhook ⚠️ REQUIRED

The webhook handles subscription lifecycle events (payments, cancellations, updates).

**Steps:**
1. Go to https://dashboard.stripe.com/webhooks
2. Click "Add endpoint"
3. Enter endpoint URL: `https://stripewebhook-24nj73cvwq-uc.a.run.app`
4. Select events to listen to:
   - ✅ `invoice.payment_succeeded`
   - ✅ `invoice.payment_failed`
   - ✅ `customer.subscription.deleted`
   - ✅ `customer.subscription.updated`
5. Click "Add endpoint"
6. **Verify webhook secret matches** your Firebase config (already configured):
   ```
   Webhook signing secret: whsec_px0oHv5bmGEMx1oSCi8hhnRN3ME0Ldx8
   ```

---

### 3. Test Payment Flow (Recommended)

Before going live, test the complete payment flow:

**Test Card Numbers** (Stripe Test Mode):
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- 3D Secure: `4000 0027 6000 3184`

**Test Steps:**
1. Launch app in test mode
2. Navigate to subscription upgrade screen
3. Select a subscription tier (Essential Plus, Pro, Ultra, or Family)
4. Enter test card: `4242 4242 4242 4242`
5. Use any future expiry date (e.g., 12/28)
6. Use any 3-digit CVC (e.g., 123)
7. Complete payment
8. Verify subscription activated in app
9. Check Stripe Dashboard → Subscriptions for new subscription

**Webhook Testing:**
1. Go to Stripe Dashboard → Webhooks
2. Click on your webhook endpoint
3. Go to "Send test webhook" tab
4. Send test events to verify webhook is receiving and processing correctly

---

## What's Already Completed ✅

### Stripe Configuration
- ✅ Publishable key configured: `pk_live_51SVNMi...`
- ✅ Secret key configured in Firebase Functions
- ✅ Webhook secret configured: `whsec_px0oHv5bmGEMx1oSCi8hhnRN3ME0Ldx8`
- ✅ Merchant settings: Australia (AU), Currency: AUD

### Cloud Functions
- ✅ All 5 payment functions deployed and healthy (Memory: 256MB)
- ✅ Region: us-central1
- ✅ Runtime: Node.js 22
- ✅ Lazy Stripe initialization (fixes container startup)

### Flutter App
- ✅ Stripe SDK initialized in `payment_service.dart`
- ✅ Real payment processing (replaced MOCK implementation)
- ✅ Cloud Functions integration via `cloud_functions` package
- ✅ Payment method creation using Stripe SDK
- ✅ Subscription payment processing
- ✅ Subscription cancellation

### Monthly Subscription Prices
- ✅ Essential Plus: `price_1SVjOcPlurWsomXvo3cJ8YO9`
- ✅ Pro: `price_1SVjOIPlurWsomXvOvgWfPFK`
- ✅ Ultra: `price_1SVjNIPlurWsomXvMAxQouxd`
- ✅ Family: `price_1SVjO7PlurWsomXv9CCcDrGF`

---

## Going Live Checklist

Before enabling payments in production:

- [ ] Yearly Price IDs created and configured
- [ ] Webhook endpoint configured and tested
- [ ] Test payment flow completed successfully
- [ ] Webhook events verified in Stripe Dashboard
- [ ] Switch from test mode to live mode in Stripe Dashboard
- [ ] Verify all subscription tiers have correct pricing
- [ ] Test subscription upgrade/downgrade flows
- [ ] Test subscription cancellation flow
- [ ] Verify subscription status syncs correctly
- [ ] Test payment failure handling
- [ ] Verify invoice generation
- [ ] Test 3D Secure authentication (if applicable)

---

## Support Resources

- **Stripe Dashboard**: https://dashboard.stripe.com
- **Stripe API Docs**: https://stripe.com/docs/api
- **Stripe Webhooks Guide**: https://stripe.com/docs/webhooks
- **Firebase Functions Logs**: https://console.firebase.google.com/project/redping-a2e37/functions/logs
- **Cloud Run Logs**: https://console.cloud.google.com/run?project=redping-a2e37

---

## Troubleshooting

### Payment fails with "No payment method available"
- Ensure user has added a payment method via `addPaymentMethod()`
- Check that payment method was created successfully in Stripe

### Webhook not receiving events
- Verify webhook URL is correct: `https://stripewebhook-24nj73cvwq-uc.a.run.app`
- Check that webhook secret matches Firebase config
- Verify webhook is enabled in Stripe Dashboard
- Check Cloud Run logs for webhook errors

### Subscription not activating after payment
- Check Firebase Functions logs for errors
- Verify webhook events are being received
- Check Firestore `users/{userId}` document for subscription data
- Verify Cloud Functions have proper Firestore permissions

### "Price not found" error
- Ensure Price IDs in `subscriptionPayments.js` match Stripe Dashboard
- Verify prices are active (not archived) in Stripe
- Check that tier name mapping is correct

---

**Last Updated**: November 24, 2025
**Functions Deployment**: Successful ✅
**Payment Integration**: Active (pending manual steps)
