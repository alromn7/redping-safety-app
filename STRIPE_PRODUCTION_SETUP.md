# RedPing Stripe Integration - Production Setup Guide

## Prerequisites

1. **Stripe Account**
   - Create account at https://stripe.com
   - Complete business verification
   - Activate your account

2. **Firebase Project**
   - Firebase project with Blaze plan (required for Cloud Functions)
   - Firebase CLI installed: `npm install -g firebase-tools`

3. **Development Environment**
   - Node.js 18+ installed
   - Flutter SDK 3.9.2+
   - Stripe CLI (for webhook testing)

---

## Step 1: Stripe Dashboard Setup

### 1.1 Create Products and Prices

Navigate to **Products** → **Add Product** in Stripe Dashboard:

#### Essential+ Plan
```
Product Name: RedPing Essential+ Subscription
Description: Advanced emergency detection and medical profile
Monthly Price: $4.99 USD (recurring monthly)
  → Copy Price ID: price_xxxxx_essential_monthly
Yearly Price: $49.99 USD (recurring yearly)
  → Copy Price ID: price_xxxxx_essential_yearly
```

#### Pro Plan
```
Product Name: RedPing Pro Subscription
Description: SMS broadcasting and AI-powered safety assistant
Monthly Price: $9.99 USD (recurring monthly)
  → Copy Price ID: price_xxxxx_pro_monthly
Yearly Price: $99.99 USD (recurring yearly)
  → Copy Price ID: price_xxxxx_pro_yearly
```

#### Ultra Plan
```
Product Name: RedPing Ultra Subscription
Description: Gadget integration and satellite communication
Monthly Price: $29.99 USD (recurring monthly)
  → Copy Price ID: price_xxxxx_ultra_monthly
Yearly Price: $299.99 USD (recurring yearly)
  → Copy Price ID: price_xxxxx_ultra_yearly
```

#### Family Plan
```
Product Name: RedPing Family Subscription
Description: Pro features for up to 5 family members
Monthly Price: $19.99 USD (recurring monthly)
  → Copy Price ID: price_xxxxx_family_monthly
Yearly Price: $199.99 USD (recurring yearly)
  → Copy Price ID: price_xxxxx_family_yearly
```

### 1.2 Get API Keys

Navigate to **Developers** → **API Keys**:

**Test Mode Keys:**
- Publishable key: `pk_test_51...`
- Secret key: `sk_test_51...` (NEVER commit to Git!)

**Live Mode Keys:**
- Publishable key: `pk_live_51...`
- Secret key: `sk_live_51...` (NEVER commit to Git!)

### 1.3 Configure Webhooks

Navigate to **Developers** → **Webhooks** → **Add Endpoint**:

**Development Endpoint:**
```
URL: Use Stripe CLI forwarding (see Step 3)
Events to send:
  - invoice.payment_succeeded
  - invoice.payment_failed
  - customer.subscription.deleted
  - customer.subscription.updated
```

**Production Endpoint:**
```
URL: https://us-central1-redping-prod.cloudfunctions.net/stripeWebhook
Events to send:
  - invoice.payment_succeeded
  - invoice.payment_failed
  - customer.subscription.deleted
  - customer.subscription.updated
```

Copy webhook signing secret: `whsec_...`

---

## Step 2: Firebase Configuration

### 2.1 Set Firebase Environment Variables

```bash
cd functions

# Set Stripe keys for development
firebase functions:config:set \
  stripe.secret_key="sk_test_51..." \
  stripe.webhook_secret="whsec_..."

# For production (switch to live keys)
firebase use production
firebase functions:config:set \
  stripe.secret_key="sk_live_51..." \
  stripe.webhook_secret="whsec_..."
```

### 2.2 Update Price IDs in Cloud Functions

Edit `functions/src/subscriptionPayments.js`:

```javascript
const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_xxxxx_essential_monthly', // Replace with your Price IDs
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

### 2.3 Install Dependencies

```bash
cd functions
npm install
```

### 2.4 Deploy Cloud Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:processSubscriptionPayment,functions:stripeWebhook
```

---

## Step 3: Flutter App Configuration

### 3.1 Add Stripe Dependency

Already added in `pubspec.yaml`:
```yaml
dependencies:
  flutter_stripe: ^11.1.0
```

Run:
```bash
flutter pub get
```

### 3.2 Set Environment Variables

Create `.env` files (add to `.gitignore`):

**`.env.development`**
```
STRIPE_PUBLISHABLE_KEY_DEV=pk_test_51...
```

**`.env.production`**
```
STRIPE_PUBLISHABLE_KEY_PROD=pk_live_51...
```

### 3.3 Update App Environment

Edit `lib/core/config/app_environment.dart` with your keys:

```dart
static String get stripePublishableKey {
  switch (environment) {
    case Environment.development:
      return 'pk_test_51...'; // Your test key
    case Environment.production:
      return 'pk_live_51...'; // Your live key
  }
}
```

### 3.4 Initialize Stripe in main.dart

Add to `lib/main.dart`:

```dart
import 'core/services/stripe_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Stripe
  await StripeInitializer.initialize();
  
  runApp(const MyApp());
}
```

### 3.5 Update Payment Service

Edit `lib/services/payment_service.dart` to use production service:

```dart
// Replace mock implementation with:
import 'stripe_payment_service.dart';

class PaymentService {
  static final StripePaymentService instance = StripePaymentService.instance;
}
```

---

## Step 4: iOS Setup (Apple Pay)

### 4.1 Configure Capabilities

In Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Apple Pay**
6. Add merchant ID: `merchant.com.redping.redping`

### 4.2 Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to secure your payment information</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>redping</string>
    </array>
  </dict>
</array>
```

### 4.3 Create Merchant ID in Apple Developer

1. Go to https://developer.apple.com/account
2. **Certificates, IDs & Profiles** → **Identifiers**
3. Click **+** → **Merchant IDs**
4. Create: `merchant.com.redping.redping`
5. Download certificate and add to Xcode

---

## Step 5: Android Setup (Google Pay)

### 5.1 Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
  <application>
    <!-- Stripe 3D Secure -->
    <activity
      android:name="com.stripe.android.view.PaymentAuthWebViewActivity"
      android:theme="@style/Theme.AppCompat.NoActionBar"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="redping" />
      </intent-filter>
    </activity>
  </application>
</manifest>
```

### 5.2 Update build.gradle

Add to `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21 // Required by Stripe
    }
}
```

---

## Step 6: Testing

### 6.1 Test Cards (Stripe Test Mode)

**Success:**
- `4242 4242 4242 4242` (Visa)
- `5555 5555 5555 4444` (Mastercard)
- Expiry: Any future date
- CVC: Any 3 digits

**3D Secure:**
- `4000 0027 6000 3184` (Requires authentication)

**Declined:**
- `4000 0000 0000 0002` (Card declined)
- `4000 0000 0000 9995` (Insufficient funds)

### 6.2 Test Payment Flow

```bash
# Run app in test mode
flutter run

# Steps:
1. Navigate to Plans page
2. Select a plan
3. Enter test card: 4242 4242 4242 4242
4. Complete payment
5. Verify subscription created in Firestore
6. Check transaction in Stripe Dashboard
```

### 6.3 Test Webhooks Locally

```bash
# Install Stripe CLI
# https://stripe.com/docs/stripe-cli

# Login
stripe login

# Forward webhooks to local Cloud Functions
stripe listen --forward-to http://localhost:5001/redping-dev/us-central1/stripeWebhook

# Trigger test events
stripe trigger invoice.payment_succeeded
stripe trigger invoice.payment_failed
```

### 6.4 Monitor Cloud Functions

```bash
# View logs
firebase functions:log

# View specific function logs
firebase functions:log --only processSubscriptionPayment
```

---

## Step 7: Production Deployment

### 7.1 Switch to Live Mode

```bash
# Update Firebase config with live keys
firebase use production
firebase functions:config:set \
  stripe.secret_key="sk_live_51..." \
  stripe.webhook_secret="whsec_..."

# Deploy functions
firebase deploy --only functions
```

### 7.2 Update Flutter App

1. Update `app_environment.dart` with live publishable key
2. Set `Environment.production` mode
3. Build release version:

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

### 7.3 Configure Production Webhook

In Stripe Dashboard:
1. **Developers** → **Webhooks** → **Add Endpoint**
2. URL: `https://us-central1-redping-prod.cloudfunctions.net/stripeWebhook`
3. Select events (same as development)
4. Copy signing secret and update Firebase config

### 7.4 Security Checklist

- [ ] Live Stripe keys stored in Firebase Functions config (not in code)
- [ ] Webhook signing secret configured
- [ ] PCI compliance reviewed
- [ ] HTTPS enforced on all endpoints
- [ ] Rate limiting enabled on Cloud Functions
- [ ] Error logging configured
- [ ] Customer data encrypted in Firestore
- [ ] Payment method details never stored in app
- [ ] 3D Secure enabled for EU cards
- [ ] Fraud detection rules configured in Stripe

---

## Step 8: Monitoring & Maintenance

### 8.1 Set Up Alerts

**Firebase Alerts:**
```bash
# Monitor function errors
firebase projects:addalerts functions:processSubscriptionPayment

# Monitor function performance
firebase projects:addalerts functions:processSubscriptionPayment --metric execution_time
```

**Stripe Alerts:**
- Dashboard → **Developers** → **Webhooks** → Configure alerts
- Email notifications for failed payments
- Slack integration for critical events

### 8.2 Monitor Metrics

**Key Metrics to Track:**
- Payment success rate (target: >95%)
- Webhook delivery success (target: >99%)
- Function execution time (target: <2s)
- Subscription churn rate
- Failed payment recovery rate

**Stripe Dashboard:**
- Daily revenue
- New subscriptions
- Cancellations
- Failed payments

**Firebase Console:**
- Function invocations
- Function errors
- Database reads/writes
- Authentication usage

### 8.3 Regular Maintenance Tasks

**Weekly:**
- Review failed payments
- Check webhook delivery logs
- Monitor function errors

**Monthly:**
- Analyze churn rate
- Review pricing strategy
- Update fraud rules
- Check for Stripe API updates

**Quarterly:**
- Security audit
- PCI compliance review
- Performance optimization
- User feedback analysis

---

## Troubleshooting

### Payment Fails with "Invalid API Key"
- Verify `stripe.secret_key` is set in Firebase config
- Check key format starts with `sk_test_` or `sk_live_`
- Ensure using correct project (dev vs prod)

### Webhook Not Receiving Events
- Verify endpoint URL is correct
- Check webhook signing secret matches
- Test with Stripe CLI: `stripe trigger invoice.payment_succeeded`
- Check Cloud Functions logs for errors

### 3D Secure Not Working
- Verify URL scheme configured in iOS/Android
- Check `stripeUrlScheme` in app_environment.dart
- Test with 3D Secure test card: `4000 0027 6000 3184`

### Subscription Not Created in Firestore
- Check Cloud Functions logs
- Verify user ID matches authenticated user
- Check Firestore security rules allow writes
- Confirm subscription webhook received

### Apple Pay Not Available
- Verify merchant ID created in Apple Developer
- Check capabilities added in Xcode
- Confirm device supports Apple Pay
- Test on physical device (not simulator)

---

## Cost Estimates

### Stripe Fees
- **Online Card Payments:** 2.9% + $0.30 per transaction
- **International Cards:** +1.5% extra
- **Currency Conversion:** +1% extra

**Example Monthly Revenue ($10k):**
- Transactions: ~500 subscriptions
- Stripe fees: ~$440 (2.9% + $0.30 * 500)
- Net revenue: ~$9,560

### Firebase Costs (Blaze Plan)
- **Cloud Functions:** $0.40 per million invocations
- **Firestore:** $0.06 per 100k reads, $0.18 per 100k writes
- **Estimated monthly cost:** $20-50 for moderate usage

### Total Platform Costs
- Stripe: 2.9% + $0.30 per transaction
- Firebase: ~$20-50/month
- **Effective cost per $100 subscription:** ~$3.50

---

## Support Resources

### Documentation
- **Stripe API:** https://stripe.com/docs/api
- **Flutter Stripe:** https://pub.dev/packages/flutter_stripe
- **Firebase Functions:** https://firebase.google.com/docs/functions
- **Stripe Webhooks:** https://stripe.com/docs/webhooks

### Community
- **Stripe Discord:** https://discord.gg/stripe
- **Flutter Discord:** https://discord.gg/flutter
- **Stack Overflow:** Tag: [flutter], [stripe], [firebase]

### Support Channels
- **Stripe Support:** https://support.stripe.com
- **Firebase Support:** https://firebase.google.com/support
- **RedPing Support:** support@redping.com

---

## Next Steps

1. ✅ Complete Stripe account verification
2. ✅ Create products and prices in Stripe Dashboard
3. ✅ Deploy Cloud Functions with correct API keys
4. ✅ Test payment flow with test cards
5. ✅ Configure webhooks and test events
6. ✅ Set up monitoring and alerts
7. ✅ Complete security checklist
8. ✅ Deploy to production
9. ✅ Monitor first transactions
10. ✅ Iterate based on user feedback

**Status:** Ready for production deployment after completing setup steps above.
