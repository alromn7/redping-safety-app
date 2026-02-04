#!/usr/bin/env node
/**
 * Export a unified JSON snapshot for a user's subscription state.
 *
 * Output JSON structure:
 * {
 *   userId: string,
 *   subscription: { ... },
 *   entitlements: { features: [] },
 *   transactions: [ { ... } ],
 *   correlation: [ { ... } ],
 *   activeCorrelationChain: [ { ... } ]
 * }
 *
 * Usage:
 *   node functions/scripts/export_subscription_snapshot.js --user <uid> > snapshot.json
 *
 * Auth: Uses Application Default Credentials (service account) or GOOGLE_APPLICATION_CREDENTIALS.
 */
const admin = require('firebase-admin');

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

function tsToDate(ts) {
  return ts && ts.toDate ? ts.toDate().toISOString() : ts || null;
}

async function init() {
  try { admin.app(); } catch { admin.initializeApp(); }
  return admin.firestore();
}

async function main() {
  const { user: userId } = parseArgs();
  if (!userId) {
    console.error('Missing --user <uid>');
    process.exit(1);
  }
  const db = await init();
  const userRef = db.collection('users').doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.error('User not found:', userId);
    process.exit(1);
  }
  const data = userSnap.data();

  const subscription = data.subscription ? {
    ...data.subscription,
    currentPeriodStart: tsToDate(data.subscription.currentPeriodStart),
    currentPeriodEnd: tsToDate(data.subscription.currentPeriodEnd),
    updatedAt: tsToDate(data.subscription.updatedAt),
    cancelledAt: tsToDate(data.subscription.cancelledAt),
  } : null;

  // Transactions (limit 25)
  const txSnap = await userRef.collection('transactions').orderBy('createdAt', 'desc').limit(25).get();
  const transactions = txSnap.docs.map(d => {
    const t = d.data();
    return { id: d.id, ...t, createdAt: tsToDate(t.createdAt) };
  });

  // Correlation records (limit 25)
  let correlation = [];
  try {
    const corrSnap = await userRef.collection('subscriptionRequests').orderBy('createdAt', 'desc').limit(25).get();
    correlation = corrSnap.docs.map(d => {
      const c = d.data();
      return {
        id: d.id,
        ...c,
        createdAt: tsToDate(c.createdAt),
        completedAt: tsToDate(c.completedAt),
        failedAt: tsToDate(c.failedAt),
      };
    });
  } catch (e) {
    // collection may not exist yet
  }

  const activeRequestId = subscription?.requestId;
  const activeCorrelationChain = activeRequestId ? correlation.filter(r => r.requestId === activeRequestId) : [];

  const snapshot = {
    userId,
    subscription,
    entitlements: data.entitlements || {},
    transactions,
    correlation,
    activeCorrelationChain,
    generatedAt: new Date().toISOString(),
  };

  process.stdout.write(JSON.stringify(snapshot, null, 2));
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
