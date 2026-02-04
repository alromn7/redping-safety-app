#!/usr/bin/env node
const admin = require('firebase-admin');
const path = require('path');

// Initialize with service account
try {
  const serviceAccount = require(path.join(__dirname, '..', 'secure_credentials', 'firebase-adminsdk.json'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (e) {
  // Try initializing without explicit credentials (uses default)
  try {
    admin.initializeApp();
  } catch (e2) {
    // Already initialized
  }
}

const db = admin.firestore();
const userId = process.argv[2];

if (!userId) {
  console.error('Usage: node check_user_subscription.js <userId>');
  process.exit(1);
}

async function checkSubscription() {
  try {
    const doc = await db.collection('users').doc(userId).get();
    
    if (!doc.exists) {
      console.log('❌ User not found');
      process.exit(1);
    }

    const data = doc.data();
    console.log('\n✅ USER SUBSCRIPTION STATUS');
    console.log('='.repeat(50));
    console.log('\n📋 Subscription:');
    console.log('   Tier:', data.subscription?.tier || 'None');
    console.log('   Status:', data.subscription?.status || 'None');
    console.log('   Stripe Sub ID:', data.subscription?.stripeSubscriptionId || 'None');
    console.log('   Billing:', data.subscription?.isYearlyBilling ? 'Yearly' : 'Monthly');
    console.log('   Is Active:', data.subscription?.isActive ? 'Yes' : 'No');
    console.log('   Auto Renew:', data.subscription?.autoRenew ? 'Yes' : 'No');
    
    if (data.subscription?.currentPeriodEnd) {
      const endDate = data.subscription.currentPeriodEnd.toDate();
      console.log('   Period End:', endDate.toLocaleString());
    }

    console.log('\n🎫 Entitlements:');
    if (data.entitlements?.features && data.entitlements.features.length > 0) {
      data.entitlements.features.forEach(feature => {
        console.log('   ✓', feature);
      });
      console.log(`\n   Total: ${data.entitlements.features.length} features`);
    } else {
      console.log('   No features unlocked');
    }

    // Check recent transactions
    const txSnapshot = await db.collection('users').doc(userId)
      .collection('transactions')
      .orderBy('createdAt', 'desc')
      .limit(3)
      .get();

    if (!txSnapshot.empty) {
      console.log('\n💳 Recent Transactions:');
      txSnapshot.docs.forEach(doc => {
        const tx = doc.data();
        const date = tx.createdAt?.toDate?.() || new Date();
        console.log(`   ${tx.type || 'payment'}: $${tx.amount || 0} ${tx.currency || ''} - ${tx.status || 'N/A'} (${date.toLocaleString()})`);
      });
    }

    console.log('\n' + '='.repeat(50) + '\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkSubscription();
