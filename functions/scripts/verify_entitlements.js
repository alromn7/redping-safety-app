#!/usr/bin/env node
/**
 * Quick entitlement verifier script.
 * Usage: node scripts/verify_entitlements.js <firebaseUserId>
 * Requires: GOOGLE_APPLICATION_CREDENTIALS pointing to a service account with Firestore access
 */
const admin = require('firebase-admin');

async function main() {
  const userId = process.argv[2];
  if (!userId) {
    console.error('Usage: node scripts/verify_entitlements.js <firebaseUserId>');
    process.exit(1);
  }
  if (!admin.apps.length) {
    try {
      admin.initializeApp();
    } catch (e) {}
  }
  const db = admin.firestore();
  const snap = await db.collection('users').doc(userId).get();
  if (!snap.exists) {
    console.error('User not found:', userId);
    process.exit(2);
  }
  const data = snap.data();
  const ent = data.entitlements || {};
  console.log(JSON.stringify({
    userId,
    subscriptionTier: data.subscription?.tier || 'none',
    features: ent.features || [],
    updatedAt: ent.updatedAt || null,
  }, null, 2));
}
main().catch(e => { console.error('Error:', e); process.exit(99); });
