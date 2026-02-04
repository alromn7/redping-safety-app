# 🚀 Ultra Tier Member Billing Guide

## Overview
Ultra tier uses **base + per-member pricing**:
- **Base**: $29.99/month ($299.99/year)
- **Additional Members**: $5/month ($50/year) per member
- **Includes**: 1 admin account (you)

## How It Works

### Pricing Examples
```
1 member (admin only):     $29.99/month
2 members (admin + 1):     $34.99/month ($29.99 + $5)
5 members (admin + 4):     $49.99/month ($29.99 + $20)
10 members (admin + 9):    $74.99/month ($29.99 + $45)
```

### Stripe Configuration

**Step 1: Create Member Add-on Price**

1. Go to: https://dashboard.stripe.com/products
2. Click **"Add product"**
3. Configure:
   ```
   Name: RedPing Ultra - Additional Member
   Description: Additional SAR team member for Ultra tier
   ```
4. Add **Monthly Price**:
   ```
   Amount: $5.00
   Billing: Recurring - Monthly
   Currency: USD
   ```
   Copy price ID: `price_xxxxxxxxxxxxx`

5. Add **Yearly Price**:
   ```
   Amount: $50.00
   Billing: Recurring - Yearly
   Currency: USD
   ```
   Copy price ID: `price_yyyyyyyyyyyyyyy`

**Step 2: Update Cloud Function**

Replace in `functions/src/subscriptionPayments.js`:
```javascript
ultra: {
  monthly: 'price_1SViolPlurWsomXvXqNUtkzt', // Base: $29.99/month
  yearly: 'price_1SXB31PlurWsomXvfmQaoq7R',  // Base: $299.99/year
  memberMonthly: 'REPLACE_WITH_YOUR_MONTHLY_PRICE_ID', // $5/month
  memberYearly: 'REPLACE_WITH_YOUR_YEARLY_PRICE_ID',   // $50/year
},
```

**Step 3: Deploy**
```bash
cd functions
firebase deploy --only functions:processSubscriptionPayment,functions:updateUltraMemberCount
```

## Usage

### Initial Subscription (Client-side)

```dart
// When user subscribes to Ultra tier
final result = await FirebaseFunctions.instance
  .httpsCallable('processSubscriptionPayment')
  .call({
    'userId': user.uid,
    'paymentMethodId': paymentMethodId,
    'tier': 'ultra',
    'isYearlyBilling': false, // or true
    'additionalMembers': 0, // Start with just admin
    'savePaymentMethod': true,
  });
```

### Adding/Removing Members

```dart
// When SAR admin adds/removes team members
final result = await FirebaseFunctions.instance
  .httpsCallable('updateUltraMemberCount')
  .call({
    'userId': user.uid,
    'memberCount': 5, // Total members including admin
  });

// Response:
// {
//   'success': true,
//   'memberCount': 5,
//   'additionalMembers': 4, // Billed members (5 - 1 admin)
//   'monthlyTotal': '49.99' // $29.99 + ($5 × 4)
// }
```

### Example Integration in SAR Organization Service

```dart
class SAROrganizationService {
  Future<void> addMember(SARMember member) async {
    // Add member to Firestore
    await _firestore
      .collection('sar_organizations')
      .doc(organizationId)
      .collection('members')
      .doc(member.id)
      .set(member.toJson());

    // Get total member count
    final membersSnapshot = await _firestore
      .collection('sar_organizations')
      .doc(organizationId)
      .collection('members')
      .get();
    
    final memberCount = membersSnapshot.docs.length;

    // Update Stripe billing
    await FirebaseFunctions.instance
      .httpsCallable('updateUltraMemberCount')
      .call({
        'userId': currentUser.uid,
        'memberCount': memberCount,
      });

    print('Member added. New billing: ${memberCount} members');
  }

  Future<void> removeMember(String memberId) async {
    // Remove from Firestore
    await _firestore
      .collection('sar_organizations')
      .doc(organizationId)
      .collection('members')
      .doc(memberId)
      .delete();

    // Get updated count
    final membersSnapshot = await _firestore
      .collection('sar_organizations')
      .doc(organizationId)
      .collection('members')
      .get();
    
    final memberCount = membersSnapshot.docs.length;

    // Update billing (will be prorated)
    await FirebaseFunctions.instance
      .httpsCallable('updateUltraMemberCount')
      .call({
        'userId': currentUser.uid,
        'memberCount': memberCount,
      });

    print('Member removed. New billing: ${memberCount} members');
  }
}
```

## Billing Behavior

### Prorations
- **Adding members**: User is charged immediately for the prorated amount
- **Removing members**: User receives credit on next invoice
- Example: Add 2 members mid-month → Charge: ~$5 (2 members × ~$2.50 for half month)

### Invoice Line Items
```
Ultra Base Plan (Monthly)          $29.99
Additional Members × 4              $20.00
--------------------------------
Total                              $49.99
```

### Subscription Updates
- Changes take effect **immediately**
- Prorated charges/credits applied to current billing period
- No interruption to service

## Firestore Data Structure

```javascript
users/{userId}
  subscription: {
    tier: 'ultra',
    stripeSubscriptionId: 'sub_...',
    stripeCustomerId: 'cus_...',
    status: 'active',
    isYearlyBilling: false,
    additionalMembers: 4,      // Members beyond admin
    totalMembers: 5,            // Including admin
    currentPeriodEnd: Timestamp,
    updatedAt: Timestamp
  }
```

## Testing

### Test Scenario 1: Subscribe with 0 Additional Members
```dart
// Should charge: $29.99 (base only)
await processSubscriptionPayment({
  tier: 'ultra',
  isYearlyBilling: false,
  additionalMembers: 0,
});
```

### Test Scenario 2: Add 3 Members
```dart
// Should charge: $29.99 + ($5 × 3) = $44.99
await updateUltraMemberCount({
  memberCount: 4, // Admin + 3 members
});
```

### Test Scenario 3: Remove 1 Member
```dart
// Should credit: ~$5 on next invoice
await updateUltraMemberCount({
  memberCount: 3, // Admin + 2 members
});
// New monthly: $39.99
```

### Test Scenario 4: Yearly Billing
```dart
// Should charge: $299.99 + ($50 × 3) = $449.99/year
await processSubscriptionPayment({
  tier: 'ultra',
  isYearlyBilling: true,
  additionalMembers: 3,
});
```

## Error Handling

```dart
try {
  final result = await FirebaseFunctions.instance
    .httpsCallable('updateUltraMemberCount')
    .call({'userId': user.uid, 'memberCount': 10});
    
  print('Success: ${result.data['monthlyTotal']}');
} on FirebaseFunctionsException catch (e) {
  switch (e.code) {
    case 'unauthenticated':
      print('User must be signed in');
      break;
    case 'permission-denied':
      print('Only organization admin can update members');
      break;
    case 'failed-precondition':
      print('Must have Ultra tier subscription');
      break;
    default:
      print('Error: ${e.message}');
  }
}
```

## Webhook Handling

The subscription webhook automatically tracks changes:
```javascript
// Stripe webhook detects subscription.updated event
// Automatically updates Firestore with new billing amounts
// No additional code needed in client app
```

## Security Rules

Ensure only organization admins can modify member count:
```javascript
// firestore.rules
match /sar_organizations/{orgId}/members/{memberId} {
  allow write: if request.auth != null 
    && get(/databases/$(database)/documents/sar_organizations/$(orgId)).data.adminUserId == request.auth.uid;
}
```

## Next Steps

1. ✅ Create member add-on prices in Stripe Dashboard
2. ✅ Update price IDs in Cloud Function
3. ✅ Deploy Cloud Function
4. ⏳ Integrate `updateUltraMemberCount` in SAR Organization Service
5. ⏳ Add member count display in UI
6. ⏳ Test adding/removing members with live billing

## FAQ

**Q: What if I don't configure member prices?**
A: Ultra tier will work as a flat $29.99/month subscription without per-member billing.

**Q: Can I change from monthly to yearly billing?**
A: Yes, update subscription with `isYearlyBilling: true` - will prorate the change.

**Q: Is there a member limit?**
A: No limit, but consider performance with 50+ members.

**Q: What happens if payment fails?**
A: Stripe retries automatically. User retains access until retry period expires (usually 7-14 days).

**Q: Can members see billing details?**
A: Only the organization admin (subscription owner) can see/modify billing.

---

**Status**: ✅ Code implemented, ready to configure Stripe prices and deploy
