# ⚠️ STRIPE PRODUCTION KEYS SETUP REQUIRED

**Status:** MANUAL CONFIGURATION NEEDED  
**Date:** November 20, 2025  
**Priority:** CRITICAL for payment processing

---

## Required Actions Before Production Launch

### 1. Obtain Stripe Production Keys

1. **Log in to Stripe Dashboard:** https://dashboard.stripe.com
2. **Switch to Live Mode** (toggle in top-right)
3. **Navigate to:** Developers → API Keys
4. **Copy the following keys:**
   ```
   Publishable Key: pk_live_51...
   Secret Key: sk_live_51... (KEEP SECURE - NEVER COMMIT!)
   ```

### 2. Configure Stripe Products & Prices

Navigate to **Products** in Stripe Dashboard and create:

#### Essential+ Plan
- **Name:** RedPing Essential+ Subscription
- **Monthly:** $4.99 USD → Copy Price ID: `price_xxxxx_essential_monthly`
- **Yearly:** $49.99 USD → Copy Price ID: `price_xxxxx_essential_yearly`

#### Pro Plan
- **Name:** RedPing Pro Subscription
- **Monthly:** $9.99 USD → Copy Price ID: `price_xxxxx_pro_monthly`
- **Yearly:** $99.99 USD → Copy Price ID: `price_xxxxx_pro_yearly`

#### Ultra Plan
- **Name:** RedPing Ultra Subscription
- **Monthly:** $29.99 USD → Copy Price ID: `price_xxxxx_ultra_monthly`
- **Yearly:** $299.99 USD → Copy Price ID: `price_xxxxx_ultra_yearly`

#### Family Plan
- **Name:** RedPing Family Subscription
- **Monthly:** $19.99 USD → Copy Price ID: `price_xxxxx_family_monthly`
- **Yearly:** $199.99 USD → Copy Price ID: `price_xxxxx_family_yearly`

### 3. Setup Stripe Webhook

1. **Navigate to:** Developers → Webhooks → Add Endpoint
2. **Endpoint URL:** `https://us-central1-redping-a2e37.cloudfunctions.net/stripeWebhook`
3. **Events to send:**
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `customer.subscription.deleted`
   - `customer.subscription.updated`
4. **Copy Webhook Signing Secret:** `whsec_...`

### 4. Configure Firebase Functions

Run these commands to set Stripe keys in Firebase:

```powershell
# Set Stripe production keys
firebase functions:config:set `
  stripe.secret_key="sk_live_51..." `
  stripe.publishable_key="pk_live_51..." `
  stripe.webhook_secret="whsec_..."

# Verify configuration
firebase functions:config:get
```

### 5. Update Price IDs in Cloud Functions

Edit `functions/src/subscriptionPayments.js`:

```javascript
const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_1234_essential_monthly',  // Replace with actual IDs
    yearly: 'price_1234_essential_yearly',
  },
  pro: {
    monthly: 'price_1234_pro_monthly',
    yearly: 'price_1234_pro_yearly',
  },
  ultra: {
    monthly: 'price_1234_ultra_monthly',
    yearly: 'price_1234_ultra_yearly',
  },
  family: {
    monthly: 'price_1234_family_monthly',
    yearly: 'price_1234_family_yearly',
  },
};
```

### 6. Update Flutter App Config

Edit `lib/core/config/stripe_config.dart`:

```dart
class StripeConfig {
  static const publishableKey = 'pk_live_51...'; // Replace with actual key
}
```

### 7. Deploy Updated Functions

```powershell
cd functions
npm install
firebase deploy --only functions
```

---

## Security Checklist

- [ ] Secret key stored ONLY in Firebase Functions config (not in code)
- [ ] Publishable key hardcoded in Flutter app (safe for client)
- [ ] Webhook secret configured in Firebase
- [ ] Test mode disabled in production
- [ ] Stripe account fully activated
- [ ] Business verification completed

---

## Testing Production Setup

After configuration, test with Stripe test cards:

```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
```

Then verify in Stripe Dashboard:
- Payment intents created
- Subscriptions activated
- Webhooks receiving events

---

## Next Steps After Configuration

1. ✅ Configure Stripe (this document)
2. Deploy Cloud Functions
3. Update Flutter app with production keys
4. Build production APK
5. Test end-to-end payment flow
6. Launch! 🚀

**Reference:** See `STRIPE_PRODUCTION_SETUP.md` for detailed instructions
