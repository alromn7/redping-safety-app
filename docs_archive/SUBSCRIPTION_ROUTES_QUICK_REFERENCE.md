# RedPing Subscription Routes - Quick Reference

## All Subscription & Payment Routes

### Main Subscription Routes
```dart
// View and select subscription plans
context.push('/subscription/plans');
context.go('/subscription/plans');

// View family dashboard (family plan members only)
context.push('/subscription/family-dashboard');
```

### Payment & Management Routes (NEW)
```dart
// Process payment for subscription
// Requires: tier (SubscriptionTier), isYearlyBilling (bool)
context.push('/subscription/payment', extra: {
  'tier': SubscriptionTier.pro,
  'isYearlyBilling': false,
});

// Manage current subscription (view/change/cancel)
context.push('/subscription/manage');
context.go('/subscription/manage');

// Manage payment methods (add/remove/set default)
context.push('/subscription/payment-methods');

// View billing history and transactions
context.push('/subscription/billing-history');
```

## Navigation Examples

### From Profile Page
```dart
// User taps subscription card
onTap: () {
  if (hasActiveSubscription) {
    context.push('/subscription/manage');      // Go to management
  } else {
    context.push('/subscription/plans');       // Go to plans
  }
}
```

### From Subscription Plans Page
```dart
// User selects a plan
void _subscribeToPlan(SubscriptionTier tier, bool isYearly) {
  context.push('/subscription/payment', extra: {
    'tier': tier,
    'isYearlyBilling': isYearly,
  });
}
```

### From Subscription Management Page
```dart
// User wants to manage payment methods
TextButton(
  onPressed: () => context.push('/subscription/payment-methods'),
  child: const Text('Manage'),
)

// User wants to view all transactions
TextButton(
  onPressed: () => context.push('/subscription/billing-history'),
  child: const Text('View All'),
)

// User wants to change plan
ElevatedButton(
  onPressed: () => context.go('/subscription/plans'),
  child: const Text('Change Plan'),
)
```

### From Payment Page
```dart
// After successful payment
if (mounted) {
  Navigator.pop(context);  // Close success dialog
  context.go('/main');     // Return to main page
}

// On cancel
TextButton(
  onPressed: () => context.pop(),
  child: const Text('Cancel'),
)
```

### From Feature Gate Dialogs
```dart
// User blocked from feature, show upgrade
ElevatedButton(
  onPressed: () {
    Navigator.pop(context);
    context.push('/subscription/plans');
  },
  child: const Text('View Plans'),
)
```

## Route Parameters

### Payment Route
```dart
// REQUIRED parameters passed via extra
Map<String, dynamic> extra = {
  'tier': SubscriptionTier,           // Required: The tier to subscribe to
  'isYearlyBilling': bool,            // Required: true for yearly, false for monthly
};

// Usage
context.push('/subscription/payment', extra: extra);
```

### Payment Page Constructor
```dart
class PaymentPage extends StatefulWidget {
  final SubscriptionTier tier;
  final bool isYearlyBilling;
  
  const PaymentPage({
    super.key,
    required this.tier,
    required this.isYearlyBilling,
  });
}
```

## Complete User Journeys

### 1. New Subscription Flow
```
User Journey:
Profile → Tap Subscription Card → Plans Page → Select Tier → Payment Page → Success → Main

Navigation Code:
context.push('/subscription/plans')
↓
context.push('/subscription/payment', extra: {...})
↓
context.go('/main')
```

### 2. Manage Subscription Flow
```
User Journey:
Profile → Tap Subscription Card → Management → Change Plan → Plans → Payment → Main

Navigation Code:
context.push('/subscription/manage')
↓
context.go('/subscription/plans')
↓
context.push('/subscription/payment', extra: {...})
↓
context.go('/main')
```

### 3. Update Payment Method Flow
```
User Journey:
Profile → Subscription → Management → Manage Payment Methods → Add/Remove

Navigation Code:
context.push('/subscription/manage')
↓
context.push('/subscription/payment-methods')
```

### 4. View Billing History Flow
```
User Journey:
Profile → Subscription → Management → View All → Billing History → Details

Navigation Code:
context.push('/subscription/manage')
↓
context.push('/subscription/billing-history')
```

### 5. Cancel Subscription Flow
```
User Journey:
Profile → Subscription → Management → Danger Zone → Cancel → Confirm → Stay on Management

Navigation Code:
context.push('/subscription/manage')
// (No navigation, stays on same page after cancel)
```

### 6. Feature Gate → Upgrade Flow
```
User Journey:
Attempt Feature → Blocked Dialog → View Plans → Payment → Success → Retry Feature

Navigation Code:
showDialog(...) // Feature gate
↓
context.push('/subscription/plans')
↓
context.push('/subscription/payment', extra: {...})
↓
context.go('/main')
```

## Integration with Other Pages

### Profile Page
```dart
// subscription_card in profile_page.dart
InkWell(
  onTap: () {
    if (_currentSubscription != null) {
      context.push('/subscription/manage');  // Has subscription
    } else {
      context.push('/subscription/plans');   // No subscription
    }
  },
)
```

### Settings Page
```dart
// Subscription settings option
ListTile(
  title: const Text('Subscription'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () => context.push('/subscription/manage'),
)
```

### Feature Access Dialogs
```dart
// When feature is blocked by tier
void _showUpgradeDialog(String featureName, SubscriptionTier requiredTier) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$featureName Locked'),
      content: Text('Requires ${requiredTier.name} or higher'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/subscription/plans');
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}
```

## Route Guards & Auth

All subscription routes require authentication:
```dart
// In app_router.dart
redirect: (context, state) {
  final isAuthed = _auth.isAuthenticated;
  final isAuthRoute = state.matchedLocation == login || 
                      state.matchedLocation == signup;

  if (!isAuthed && !isSplash && !isAuthRoute) {
    return login;  // Redirect to login
  }
  
  return null;  // Allow navigation
}
```

## Deep Linking Support

### Subscription Deep Links
```
// Direct to plans
redping://subscription/plans

// Direct to management (requires auth)
redping://subscription/manage

// Direct to payment methods (requires auth)
redping://subscription/payment-methods

// Direct to billing (requires auth)
redping://subscription/billing-history
```

### Implementation
```dart
// In AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="redping" android:host="subscription" />
</intent-filter>

// In Info.plist (iOS)
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

## Error Handling

### Invalid Route
```dart
// Handled by GoRouter errorBuilder
errorBuilder: (context, state) => Scaffold(
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Page Not Found'),
        ElevatedButton(
          onPressed: () => context.go('/main'),
          child: const Text('Go Home'),
        ),
      ],
    ),
  ),
),
```

### Missing Parameters
```dart
// Payment route with null tier (shouldn't happen, but handled)
GoRoute(
  path: '/subscription/payment',
  name: 'payment',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    if (extra == null || extra['tier'] == null) {
      // Fallback: redirect to plans
      Future.microtask(() => context.go('/subscription/plans'));
      return const SizedBox(); // Temporary empty widget
    }
    return PaymentPage(
      tier: extra['tier'],
      isYearlyBilling: extra['isYearlyBilling'] ?? false,
    );
  },
),
```

## Testing Routes

### Test Navigation
```dart
// In widget tests
testWidgets('Navigate to subscription plans', (tester) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: AppRouter.router,
    ),
  );
  
  // Tap subscription card
  await tester.tap(find.byKey(const Key('subscription_card')));
  await tester.pumpAndSettle();
  
  // Verify plans page loaded
  expect(find.text('Choose Your Plan'), findsOneWidget);
});
```

### Test Payment Flow
```dart
testWidgets('Complete payment flow', (tester) async {
  // Navigate to payment
  await tester.tap(find.text('Subscribe'));
  await tester.pumpAndSettle();
  
  // Fill payment form
  await tester.enterText(find.byKey(const Key('card_number')), '4242424242424242');
  await tester.enterText(find.byKey(const Key('cardholder_name')), 'John Doe');
  await tester.enterText(find.byKey(const Key('exp_month')), '12');
  await tester.enterText(find.byKey(const Key('exp_year')), '25');
  await tester.enterText(find.byKey(const Key('cvc')), '123');
  
  // Submit payment
  await tester.tap(find.text('Pay'));
  await tester.pumpAndSettle();
  
  // Verify success
  expect(find.text('Payment Successful!'), findsOneWidget);
});
```

## Performance Considerations

### Route Preloading
```dart
// Preload payment page when user views plans
class SubscriptionPlansPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Warm up payment service
    Future.microtask(() async {
      await PaymentService.instance.initialize();
    });
  }
}
```

### Route Caching
```dart
// Use ShellRoute for persistent state
ShellRoute(
  builder: (context, state, child) {
    return SubscriptionShell(child: child);
  },
  routes: [
    // Subscription routes here
  ],
)
```

## Summary

Total Routes Added: **4 new routes**
- `/subscription/payment` - Payment processing
- `/subscription/manage` - Subscription management
- `/subscription/payment-methods` - Payment methods
- `/subscription/billing-history` - Billing history

Total Navigation Points: **15+ locations**
- Profile page
- Plans page
- Management page
- Payment methods page
- Billing history page
- Feature gate dialogs (6+ locations)
- Settings page
- Deep links

All routes are fully integrated with go_router and authentication guards.
