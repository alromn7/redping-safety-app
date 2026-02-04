#!/usr/bin/env node
/**
 * Live Payment Test Monitor
 * Watches Firebase logs and Stripe events during live payment testing
 */

const admin = require('firebase-admin');
const https = require('https');

// Initialize Firebase Admin
try {
  const serviceAccount = require('../secure_credentials/firebase-adminsdk.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (e) {
  console.error('Failed to initialize Firebase Admin:', e.message);
  process.exit(1);
}

const db = admin.firestore();

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      const key = args[i].replace(/^--/, '');
      const val = args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true;
      out[key] = val;
    }
  }
  return out;
}

async function monitorUser(userId) {
  console.log('🔍 Live Payment Test Monitor');
  console.log('============================\n');
  console.log(`Monitoring user: ${userId}`);
  console.log('Watching for subscription changes...\n');

  // Listen to subscription changes
  const unsubscribe = db.collection('users').doc(userId)
    .onSnapshot(async (snapshot) => {
      if (!snapshot.exists) {
        console.log('⚠️  User not found');
        return;
      }

      const data = snapshot.data();
      const subscription = data.subscription;
      const entitlements = data.entitlements;

      console.clear();
      console.log('🔍 Live Payment Test Monitor');
      console.log('============================\n');
      console.log(`User: ${userId}`);
      console.log(`Time: ${new Date().toLocaleTimeString()}\n`);

      // Subscription status
      if (subscription) {
        console.log('📋 Subscription Status:');
        console.log(`   Status: ${subscription.status || 'N/A'}`);
        console.log(`   Tier: ${subscription.tier || 'N/A'}`);
        console.log(`   Stripe ID: ${subscription.stripeSubscriptionId || 'N/A'}`);
        console.log(`   Customer ID: ${subscription.stripeCustomerId || 'N/A'}`);
        console.log(`   Billing: ${subscription.isYearlyBilling ? 'Yearly' : 'Monthly'}`);
        if (subscription.currentPeriodEnd) {
          const endDate = subscription.currentPeriodEnd.toDate();
          console.log(`   Period End: ${endDate.toLocaleString()}`);
        }
        console.log('');
      } else {
        console.log('📋 Subscription Status: None\n');
      }

      // Entitlements
      if (entitlements && entitlements.features) {
        console.log('🎫 Active Entitlements:');
        entitlements.features.forEach(feature => {
          console.log(`   ✓ ${feature}`);
        });
        console.log(`   Total: ${entitlements.features.length} features\n`);
      } else {
        console.log('🎫 Active Entitlements: None\n');
      }

      // Recent transactions
      try {
        const txSnapshot = await db.collection('users').doc(userId)
          .collection('transactions')
          .orderBy('createdAt', 'desc')
          .limit(3)
          .get();

        if (!txSnapshot.empty) {
          console.log('💳 Recent Transactions:');
          txSnapshot.docs.forEach(doc => {
            const tx = doc.data();
            console.log(`   ${tx.type || 'payment'}: ${tx.amount ? '$' + tx.amount : 'N/A'} - ${tx.status || 'N/A'}`);
          });
          console.log('');
        }
      } catch (e) {
        // Transactions collection may not exist yet
      }

      console.log('─'.repeat(50));
      console.log('Watching for changes... (Ctrl+C to exit)');
    }, (error) => {
      console.error('Error monitoring user:', error.message);
    });

  // Keep process alive
  process.on('SIGINT', () => {
    console.log('\n\n👋 Stopping monitor...');
    unsubscribe();
    process.exit(0);
  });
}

async function main() {
  const args = parseArgs();
  const userId = args.user;

  if (!userId) {
    console.error('Usage: node live_payment_monitor.js --user <userId>');
    process.exit(1);
  }

  await monitorUser(userId);
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
