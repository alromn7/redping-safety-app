#!/usr/bin/env node
/**
 * Create or patch a minimal Firestore user document for subscription tests.
 * Usage:
 *   node functions/scripts/create_test_user.js --user automatedTestUser --email test@example.com --name "Automated User"
 */
const admin = require('firebase-admin');
try {
  admin.app();
} catch {
  // Explicitly load service account to avoid ADC issues in local execution.
  try {
    const serviceAccount = require('../../secure_credentials/firebase-adminsdk.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    console.log('Initialized firebase-admin for project:', serviceAccount.project_id);
  } catch (e) {
    console.error('Failed to initialize firebase-admin with service account:', e.message);
    process.exit(1);
  }
}

function parseArgs() {
  const args = process.argv.slice(2); const out={};
  for (let i=0;i<args.length;i++){ if(args[i].startsWith('--')){ const k=args[i].replace(/^--/,''); const v=args[i+1] && !args[i+1].startsWith('--') ? args[i+1] : true; out[k]=v; }}
  return out;
}

async function main() {
  const { user: userId, email, name } = parseArgs();
  if (!userId) throw new Error('Missing --user');
  const db = admin.firestore();
  const userRef = db.collection('users').doc(userId);
  console.log('Attempting Firestore write with projectId:', admin.app().options.projectId);
  const payload = {
    email: email || `test+${Date.now()}@example.com`,
    displayName: name || 'Automated Test User',
    updatedAt: admin.firestore.Timestamp.now(),
  };
  await userRef.set(payload, { merge: true });
  console.log(JSON.stringify({ created: true, userId, payload }, null, 2));
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
