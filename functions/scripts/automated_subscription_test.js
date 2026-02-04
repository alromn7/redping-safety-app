#!/usr/bin/env node
/**
 * Automated subscription test orchestrator.
 *
 * Steps:
 * 1. Acquire Firebase ID token (from FIREBASE_ID_TOKEN env OR mint custom token + exchange using FIREBASE_WEB_API_KEY).
 * 2. Invoke processSubscriptionPayment callable function with test payment method.
 * 3. Export snapshot of subscription state.
 * 4. Validate entitlements against expected tier feature set.
 * 5. Print PASS/FAIL summary JSON.
 *
 * Usage examples:
 *   # Using existing ID token
 *   set FIREBASE_ID_TOKEN=eyJhbGciOi... && node functions/scripts/automated_subscription_test.js --user UID123 --tier pro
 *
 *   # Using custom token flow (requires service account credentials + FIREBASE_WEB_API_KEY)
 *   set FIREBASE_WEB_API_KEY=AIzaSy... && node functions/scripts/automated_subscription_test.js --user UID123 --tier pro
 *
 * Options:
 *   --user <firebaseUid>   (required)
 *   --tier <tier>          (default: pro)
 *   --yearly true|false    (default: false)
 *   --pm <paymentMethodId> (default: pm_card_visa)
 *   --members <n>          (Ultra additional members quantity; default: 0)
 *   --output <file>        (write final JSON summary to file)
 */

const { URL } = require('url');
const fs = require('fs');
const admin = require('firebase-admin');
try { admin.app(); } catch { admin.initializeApp(); }
// https imported once above

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

const EXPECTED_FEATURES = {
  free: ['feature_sos_call'],
  essentialPlus: ['feature_sos_call','feature_hazard_alerts'],
  pro: ['feature_sos_call','feature_hazard_alerts','feature_ai_assistant','feature_gadgets','feature_redping_mode','feature_sar_basic'],
  ultra: ['feature_sos_call','feature_hazard_alerts','feature_ai_assistant','feature_gadgets','feature_redping_mode','feature_sar_basic','feature_sar_advanced'],
  family: ['feature_sos_call','feature_hazard_alerts','feature_ai_assistant','feature_gadgets','feature_redping_mode','feature_family_check_in','feature_find_my_gadget','feature_family_dashboard']
};

async function acquireIdToken(userId) {
  if (process.env.FIREBASE_ID_TOKEN) {
    return process.env.FIREBASE_ID_TOKEN.trim();
  }
  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  if (!apiKey) {
    throw new Error('FIREBASE_ID_TOKEN or FIREBASE_WEB_API_KEY must be set to obtain ID token');
  }
  // Mint custom token
  const customToken = await admin.auth().createCustomToken(userId);
  // Exchange custom token for ID token
  const body = JSON.stringify({ token: customToken, returnSecureToken: true });
  const url = new URL(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`);
  const resp = await httpPostJson(url, body);
  if (!resp.idToken) throw new Error('Failed to exchange custom token for ID token');
  return resp.idToken;
}

function httpPostJson(url, body, headersExtra = {}) {
  return new Promise((resolve, reject) => {
    const opts = { method: 'POST', headers: { 'Content-Type': 'application/json', ...headersExtra } };
    const req = https.request(url, opts, res => {
      let raw='';
      res.on('data', d => raw += d);
      res.on('end', () => {
        try { resolve(JSON.parse(raw)); } catch (e) { reject(new Error('Invalid JSON response: '+raw)); }
      });
    });
    req.on('error', reject);
    req.write(body); req.end();
  });
}

async function invokeSubscription({ idToken, userId, tier, paymentMethodId, isYearlyBilling, additionalMembers }) {
  const endpoint = `https://us-central1-redping-a2e37.cloudfunctions.net/processSubscriptionPayment`;
  const url = new URL(endpoint);
  const payload = { data: { userId, tier, paymentMethodId, savePaymentMethod: true, isYearlyBilling, additionalMembers } };
  return httpPostJson(url, JSON.stringify(payload), { Authorization: `Bearer ${idToken}` });
}

async function exportSnapshot(userId) {
  // Reuse existing snapshot logic by reading Firestore directly
  const db = admin.firestore();
  const userRef = db.collection('users').doc(userId);
  const snap = await userRef.get();
  if (!snap.exists) throw new Error('User not found for snapshot');
  const data = snap.data();
  // Load transactions (limit 10)
  const txSnap = await userRef.collection('transactions').orderBy('createdAt','desc').limit(10).get();
  const transactions = txSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  const reqSnap = await userRef.collection('subscriptionRequests').orderBy('createdAt','desc').limit(10).get().catch(()=>({docs:[]}));
  const corr = reqSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  return { subscription: data.subscription || null, entitlements: data.entitlements || {}, transactions, correlation: corr };
}

function compareFeatures(tier, entitlements) {
  const expected = EXPECTED_FEATURES[tier] || [];
  const actual = entitlements.features || [];
  const missing = expected.filter(f => !actual.includes(f));
  const extra = actual.filter(f => !expected.includes(f));
  return { expected, actual, missing, extra, match: missing.length===0 && extra.length===0 };
}

async function main() {
  const args = parseArgs();
  const userId = args.user;
  if (!userId) throw new Error('Missing --user <firebaseUid>');
  const tier = args.tier || 'pro';
  const paymentMethodId = args.pm || 'pm_card_visa';
  const isYearlyBilling = (args.yearly === 'true');
  const additionalMembers = args.members ? parseInt(args.members,10) : 0;
  const outFile = args.output;

  const startedAt = Date.now();
  const summary = { userId, tier, steps: [], success: false, startedAtISO: new Date(startedAt).toISOString() };

  try {
    summary.steps.push('Acquire ID token');
    const idToken = await acquireIdToken(userId);

    summary.steps.push('Invoke subscription function');
    const invokeResp = await invokeSubscription({ idToken, userId, tier, paymentMethodId, isYearlyBilling, additionalMembers });
    summary.invokeResponse = invokeResp;

    if (!invokeResp.success) throw new Error('Subscription invocation did not return success');

    // Small delay to allow Firestore writes
    await new Promise(r => setTimeout(r, 1500));

    summary.steps.push('Export snapshot');
    const snapshot = await exportSnapshot(userId);
    summary.snapshot = snapshot;

    summary.steps.push('Validate entitlements');
    const featureCheck = compareFeatures(tier, snapshot.entitlements);
    summary.featureValidation = featureCheck;

    const subStatus = snapshot.subscription?.status;
    const statusOk = subStatus && !['incomplete','canceled','unpaid'].includes(subStatus);
    summary.statusOk = statusOk;
    summary.success = featureCheck.match && statusOk;
    summary.pass = summary.success;
    summary.reason = summary.success ? 'All validations passed' : (!statusOk ? `Subscription status ${subStatus} not OK` : 'Feature mismatch');
    summary.failureDetails = summary.success ? null : {
      subscriptionStatus: subStatus,
      missingFeatures: featureCheck.missing,
      extraFeatures: featureCheck.extra,
      invokeResponse: !invokeResp.success ? invokeResp : undefined,
    };
  } catch (e) {
    summary.error = e.message;
    summary.reason = 'Failure during automation';
    summary.success = false;
  }

  summary.durationMs = Date.now() - startedAt;
  const outputJson = JSON.stringify(summary, null, 2);

  // Optional Slack alert on failure
  if (!summary.success && process.env.SLACK_WEBHOOK_URL) {
    try {
      const webhookUrl = process.env.SLACK_WEBHOOK_URL;
      const url = new URL(webhookUrl);
      const payload = JSON.stringify({
        text: `Subscription Test FAILED for user=${userId} tier=${tier}\nReason: ${summary.reason}\nError: ${summary.error || 'N/A'}\nStatus: ${summary.snapshot?.subscription?.status}`,
      });
      const req = https.request(url, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) } });
      req.on('error', err => console.warn('Slack alert error:', err.message));
      req.write(payload); req.end();
    } catch (alertErr) {
      console.warn('Failed sending Slack alert:', alertErr.message);
    }
  }
  if (outFile) {
    fs.writeFileSync(outFile, outputJson, 'utf8');
    console.log('Result written to', outFile);
  } else {
    console.log(outputJson);
  }
  if (!summary.success) process.exitCode = 1;
}

main().catch(e => { console.error('Fatal error:', e); process.exit(1); });
