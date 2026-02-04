#!/usr/bin/env node
/**
 * Inspect subscription status, entitlements, transactions, and correlation records for a user.
 *
 * Usage:
 *   node functions/scripts/check_subscription_status.js --user <uid>
 *
 * Requires application default credentials OR GOOGLE_APPLICATION_CREDENTIALS pointing
 * to a service account JSON with Firestore read access.
 */
const admin = require('firebase-admin');
const {Firestore} = require('@google-cloud/firestore');

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

async function init() {
  try { admin.app(); } catch { admin.initializeApp(); }
  return admin.firestore();
}

function tsToDate(ts) { return ts && ts.toDate ? ts.toDate().toISOString() : ts; }

async function main() {
  const { user: userId } = parseArgs();
  if (!userId) {
    console.error('Missing --user <uid>');
    process.exit(1);
  }
  const db = await init();
  const userRef = db.collection('users').doc(userId);
  const snap = await userRef.get();
  if (!snap.exists) {
    console.error('User not found:', userId);
    process.exit(1);
  }
  const data = snap.data();
  console.log('=== Subscription Overview ===');
  console.log(JSON.stringify({
    tier: data.subscription?.tier,
    status: data.subscription?.status,
    stripeSubscriptionId: data.subscription?.stripeSubscriptionId,
    stripeCustomerId: data.subscription?.stripeCustomerId,
    currentPeriodEnd: tsToDate(data.subscription?.currentPeriodEnd),
    isYearlyBilling: data.subscription?.isYearlyBilling,
    requestId: data.subscription?.requestId,
    additionalMembers: data.subscription?.additionalMembers,
    totalMembers: data.subscription?.totalMembers,
  }, null, 2));

  console.log('\n=== Entitlements ===');
  console.log(JSON.stringify({ features: data.entitlements?.features || [] }, null, 2));

  // Transactions
  console.log('\n=== Transactions (latest 10) ===');
  const txSnap = await userRef.collection('transactions').orderBy('createdAt', 'desc').limit(10).get();
  const transactions = txSnap.docs.map(d => ({ id: d.id, ...d.data(), createdAt: tsToDate(d.data().createdAt) }));
  console.log(JSON.stringify(transactions, null, 2));

  // Correlation chain
  console.log('\n=== Subscription Requests (latest 10) ===');
  const reqSnap = await userRef.collection('subscriptionRequests').orderBy('createdAt', 'desc').limit(10).get().catch(()=>({docs:[]}));
  const requests = reqSnap.docs.map(d => ({ id: d.id, ...d.data(), createdAt: tsToDate(d.data().createdAt), completedAt: tsToDate(d.data().completedAt), failedAt: tsToDate(d.data().failedAt) }));
  console.log(JSON.stringify(requests, null, 2));

  const activeRequestId = data.subscription?.requestId;
  if (activeRequestId) {
    const chain = requests.filter(r => r.requestId === activeRequestId);
    console.log(`\n=== Correlation Chain for requestId=${activeRequestId} ===`);
    console.log(JSON.stringify(chain, null, 2));
    if (!chain.length) {
      console.warn('No correlation records found for current subscription requestId (may have been pruned or logging failed).');
    }
  }
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
