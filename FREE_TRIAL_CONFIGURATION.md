# Free Trial Period Configuration
**Public Trial Period:** November 20 - December 4, 2025 (14 days)  
**Status:** ✅ ACTIVE

---

## Overview

REDP!NG is offering a **14-day FREE trial** for all paid subscription plans (Essential+, Pro, Ultra, Family). Users can access all premium features without any charge for 2 weeks. After the trial ends, billing begins automatically.

## How It Works

### 1. **Free Trial Flow**
```
User signs up for paid plan
    ↓
Payment method collected (required)
    ↓
14-day trial begins (no charge)
    ↓
Full access to all features
    ↓
[Day 14] Trial ends
    ↓
First billing occurs (automatic)
```

### 2. **Technical Implementation**

**Backend (SubscriptionService):**
```dart
// Configuration constants
static const int defaultTrialDays = 14;
static const bool enableTrialForAllPlans = true;

// Trial fields added to UserSubscription model:
- isTrialPeriod: bool
- trialEndDate: DateTime?
- trialDays: int

// Helper methods:
- isInTrial: Check if currently in trial
- daysRemainingInTrial: Days left in trial
```

**Subscription Creation:**
```dart
await SubscriptionService.instance.subscribeToPlan(
  userId: userId,
  tier: SubscriptionTier.pro,
  paymentMethod: PaymentMethod.creditCard,
  isYearlyBilling: false,
  // trialDays: 14 (optional - uses default)
  // skipTrial: false (optional - for returning customers)
);
```

### 3. **Billing Schedule**

**With Trial:**
- **Sign-up date:** November 20, 2025
- **Trial ends:** December 4, 2025
- **First billing:** December 4, 2025
- **Next billing:** January 4, 2026 (monthly) or December 4, 2026 (yearly)

**Without Trial (Free plan):**
- Immediate access
- No billing ever (unless upgraded)

## User Experience

### Subscription Plans UI

**Trial Banner (on all paid plans):**
```
┌─────────────────────────────────────────────────┐
│ 🎉 14-day FREE trial • No charge until Dec 4   │
└─────────────────────────────────────────────────┘
```

**Pricing Display:**
```
FREE for 14 days
Then $9.99/month
```

**Button Text:**
- Paid plans: "START FREE TRIAL"
- Family plan: "START 14-DAY FREE TRIAL"
- Free plan: "GET STARTED FREE"

### Trial Messaging

**Key Messages:**
1. ✅ "14-day free trial"
2. ✅ "No charge until December 4, 2025"
3. ✅ "Cancel anytime during trial"
4. ✅ "Full access to all features"
5. ✅ "Payment method required"

## Configuration

### Enable/Disable Trial

**To disable trial after public trial ends:**

```dart
// In lib/services/subscription_service.dart (line ~43)
static const bool enableTrialForAllPlans = false; // Set to false
```

**To change trial duration:**

```dart
// In lib/services/subscription_service.dart (line ~42)
static const int defaultTrialDays = 14; // Change number of days
```

### Per-User Trial Control

**Skip trial for returning customers:**
```dart
await SubscriptionService.instance.subscribeToPlan(
  userId: userId,
  tier: tier,
  paymentMethod: paymentMethod,
  skipTrial: true, // ← Skip trial
);
```

**Custom trial length:**
```dart
await SubscriptionService.instance.subscribeToPlan(
  userId: userId,
  tier: tier,
  paymentMethod: paymentMethod,
  trialDays: 7, // ← Override default (7 days instead of 14)
);
```

## Trial Period Status

### Current Configuration
- **Trial enabled:** ✅ YES
- **Default duration:** 14 days
- **Applies to:** Essential+, Pro, Ultra, Family
- **Excludes:** Free plan
- **Start date:** November 20, 2025
- **End date:** December 4, 2025

### Subscription Tiers with Trial

| Plan | Monthly Price | Trial Period | First Billing |
|------|--------------|--------------|---------------|
| Free | $0.00 | ❌ No trial (always free) | Never |
| Essential+ | $4.99 | ✅ 14 days free | Dec 4, 2025 |
| Pro | $9.99 | ✅ 14 days free | Dec 4, 2025 |
| Ultra | $19.99 | ✅ 14 days free | Dec 4, 2025 |
| Family | $14.99 | ✅ 14 days free | Dec 4, 2025 |

## Stripe Configuration

### Required Setup

**1. Configure Trial in Stripe Products:**
```
Stripe Dashboard → Products → [Select Product]
→ Pricing → Trial period: 14 days
```

**2. Update Stripe API Calls:**
```dart
// In Firebase Functions (when integrating with Stripe)
const subscription = await stripe.subscriptions.create({
  customer: customerId,
  items: [{ price: priceId }],
  trial_period_days: 14, // ← Add trial
  payment_behavior: 'default_incomplete',
  expand: ['latest_invoice.payment_intent'],
});
```

**3. Webhook Events to Handle:**
- `customer.subscription.trial_will_end` (3 days before trial ends)
- `customer.subscription.updated` (when trial converts to paid)
- `invoice.payment_succeeded` (first billing after trial)
- `invoice.payment_failed` (if first payment fails)

### Trial Notifications

**Recommended notification schedule:**
1. **Day 1:** Welcome email - trial started
2. **Day 7:** Reminder - 7 days remaining
3. **Day 11:** Warning - 3 days remaining
4. **Day 14:** Trial ended - first billing
5. **Day 15:** Payment confirmation

## Testing the Trial

### Test Scenarios

**1. Sign up with trial:**
```
1. Navigate to subscription plans
2. Select Essential+/Pro/Ultra/Family
3. Enter payment method
4. Verify trial banner shows "14-day FREE trial"
5. Complete sign-up
6. Check subscription status: isInTrial = true
7. Verify nextBillingDate = 14 days from now
```

**2. Check trial status:**
```dart
final subscription = SubscriptionService.instance.currentSubscription;
print('In trial: ${subscription?.isInTrial}');
print('Days remaining: ${subscription?.daysRemainingInTrial}');
print('Trial ends: ${subscription?.trialEndDate}');
```

**3. Test billing after trial:**
```dart
// Mock time travel to test
final subscription = SubscriptionService.instance.currentSubscription;
if (subscription != null) {
  // Check if trial has ended
  final hasEnded = DateTime.now().isAfter(subscription.trialEndDate!);
  print('Trial ended: $hasEnded');
}
```

## Cancellation During Trial

### User Actions

**If user cancels during trial:**
1. Subscription status → `cancelled`
2. Access continues until trial end date
3. No billing occurs
4. Features locked after trial expires

**Implementation:**
```dart
Future<void> cancelSubscription() async {
  final subscription = _currentSubscription;
  if (subscription == null) return;
  
  // Update status
  final updated = UserSubscription(
    ...subscription fields,
    status: SubscriptionStatus.cancelled,
    autoRenew: false,
  );
  
  await _saveSubscription(updated);
  
  // If in trial, access continues until trial end
  if (subscription.isInTrial) {
    debugPrint('Trial cancelled - access until ${subscription.trialEndDate}');
  }
}
```

## After Trial Period Ends

### December 4, 2025 - Disable Trial

**Steps to disable:**

1. **Update configuration:**
```dart
// lib/services/subscription_service.dart
static const bool enableTrialForAllPlans = false;
```

2. **Update UI messaging:**
- Remove trial banners from subscription plan cards
- Change button text back to "SUBSCRIBE NOW"
- Update pricing display to normal

3. **Optional: Keep trial for specific users**
```dart
// Add user whitelist
static const List<String> trialWhitelist = [
  'beta_tester_id_1',
  'beta_tester_id_2',
];

final shouldHaveTrial = trialWhitelist.contains(userId) || enableTrialForAllPlans;
```

## Monitoring & Analytics

### Key Metrics to Track

**Trial Metrics:**
- Trial sign-ups per plan
- Trial-to-paid conversion rate
- Trial cancellation rate
- Average days before cancellation
- Payment failures after trial

**Target Conversion Rates:**
- Essential+: 40-50%
- Pro: 50-60%
- Ultra: 30-40%
- Family: 60-70%

### Firebase Analytics Events

**Track these events:**
```dart
// Trial started
FirebaseAnalytics.instance.logEvent(
  name: 'trial_started',
  parameters: {'plan': tier.name, 'duration': 14},
);

// Trial converted
FirebaseAnalytics.instance.logEvent(
  name: 'trial_converted',
  parameters: {'plan': tier.name, 'revenue': price},
);

// Trial cancelled
FirebaseAnalytics.instance.logEvent(
  name: 'trial_cancelled',
  parameters: {'plan': tier.name, 'days_active': daysActive},
);
```

## Troubleshooting

### Common Issues

**1. User charged immediately**
- Check `isTrialPeriod = true`
- Verify `trialEndDate` is set correctly
- Check `enableTrialForAllPlans = true`

**2. Trial not showing in UI**
- Verify plan tier is not `SubscriptionTier.free`
- Check subscription plan card widget updated
- Clear app cache and rebuild

**3. Billing date wrong**
- Verify `nextBillingDate = trialEndDate`
- Check timezone handling
- Confirm trial calculation logic

## Support Information

### User FAQ

**Q: When will I be charged?**
A: Your first charge will occur on December 4, 2025 (after 14-day trial).

**Q: Can I cancel during trial?**
A: Yes! You can cancel anytime. If you cancel during the trial, you won't be charged.

**Q: Do I need to enter payment info?**
A: Yes, payment method is required to start the trial (prevents abuse).

**Q: What happens after trial ends?**
A: Automatic billing begins. You'll be charged the full subscription price.

**Q: Can I change plans during trial?**
A: Yes! Your trial period transfers to the new plan.

## Summary

✅ **Implementation Complete**
- Trial period model updated
- Service layer configured
- UI displays trial messaging
- JSON serialization handles trial fields
- Default: 14 days for all paid plans

✅ **Configuration**
- Enabled: `enableTrialForAllPlans = true`
- Duration: `defaultTrialDays = 14`
- Billing delayed until trial ends

✅ **Next Steps**
1. Test trial flow with test users
2. Configure Stripe webhooks for trial events
3. Set up notification emails
4. Monitor conversion metrics
5. Disable trial after December 4, 2025

**Public trial runs from November 20 to December 4, 2025. All features available for free during this period!**
