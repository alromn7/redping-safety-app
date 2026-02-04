import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Quick script to update subscription tier for a user
/// Run: dart run update_subscription.dart
void main() async {
  print('🔧 Updating subscription for alromn@yahoo.com...');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // Find user by email
  final usersQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: 'alromn@yahoo.com')
      .limit(1)
      .get();

  if (usersQuery.docs.isEmpty) {
    print('❌ User not found with email: alromn@yahoo.com');
    print('💡 Make sure the user has signed up in the app first');
    return;
  }

  final userDoc = usersQuery.docs.first;
  final userId = userDoc.id;

  print('✅ Found user: ${userDoc.data()['displayName']} (ID: $userId)');

  // Update subscription to Pro tier
  final now = DateTime.now();
  final trialEnd = now.add(const Duration(days: 14));
  final nextBilling = now.add(const Duration(days: 30));

  await firestore.collection('users').doc(userId).update({
    'subscription': {
      'tier': 'pro',
      'status': 'active',
      'startDate': Timestamp.fromDate(now),
      'trialEndDate': Timestamp.fromDate(trialEnd),
      'nextBillingDate': Timestamp.fromDate(nextBilling),
      'billingCycle': 'monthly',
      'stripeCustomerId': 'test_customer_$userId',
      'stripeSubscriptionId': 'test_sub_$userId',
      'cancelAtPeriodEnd': false,
      'updatedAt': Timestamp.now(),
    },
  });

  print('✅ Successfully updated subscription!');
  print('📊 New subscription details:');
  print('   Tier: Pro');
  print('   Status: Active');
  print('   Trial End: ${trialEnd.toLocal()}');
  print('   Next Billing: ${nextBilling.toLocal()}');
  print('');
  print('🎉 alromn@yahoo.com now has Pro access!');
  print('💡 Restart the app to see the changes');
}
