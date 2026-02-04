/**
 * Set admin account (alromn7@gmail.com) to Ultra subscription
 * 
 * Usage:
 *   node set_admin_ultra.js
 */

const admin = require('firebase-admin');

// Initialize with project ID from .firebaserc
admin.initializeApp({
  projectId: 'redping-a2e37'
});

const db = admin.firestore();

async function setAdminToUltra() {
  try {
    // Find user by email
    const userRecord = await admin.auth().getUserByEmail('alromn7@gmail.com');
    const userId = userRecord.uid;
    
    console.log('✅ Found admin user:', userId);

    const now = admin.firestore.Timestamp.now();
    const oneYearFromNow = new Date();
    oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1);

    // Set Ultra subscription
    const subscriptionData = {
      tier: 'ultra',
      status: 'active',
      isActive: true,
      autoRenew: true,
      isYearlyBilling: false,
      currentPeriodStart: now,
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(oneYearFromNow),
      nextBillingDate: admin.firestore.Timestamp.fromDate(oneYearFromNow),
      updatedAt: now,
      stripeCustomerId: 'admin_test_customer',
      stripeSubscriptionId: 'admin_test_subscription',
      additionalMembers: 0,
      totalMembers: 1,
    };

    // Set Ultra entitlements
    const entitlements = {
      features: [
        'feature_sos_call',
        'feature_hazard_alerts',
        'feature_ai_assistant',
        'feature_gadgets',
        'feature_redping_mode',
        'feature_sar_basic',
        'feature_sar_advanced',
      ],
      updatedAt: now,
    };

    // Update Firestore
    await db.collection('users').doc(userId).set({
      subscription: subscriptionData,
      entitlements: entitlements,
    }, { merge: true });

    console.log('✅ Successfully set admin account to Ultra subscription!');
    console.log('\nSubscription Details:');
    console.log('  - Tier: Ultra');
    console.log('  - Status: Active');
    console.log('  - Features:', entitlements.features.join(', '));
    console.log('\n🎉 Admin account is now Ultra! Restart the app to see changes.');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error setting admin to Ultra:', error);
    process.exit(1);
  }
}

setAdminToUltra();
