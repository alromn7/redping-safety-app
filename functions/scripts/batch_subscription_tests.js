#!/usr/bin/env node
/**
 * Batch run automated subscription tests across tiers.
 *
 * Usage:
 *   set FIREBASE_ID_TOKEN=eyJ...   # or set FIREBASE_WEB_API_KEY=...
 *   node functions/scripts/batch_subscription_tests.js --user UID123 --tiers pro,ultra,family --output batch_results.json
 *
 * Notes:
 * - Uses automated_subscription_test.js logic via child process for isolation.
 * - Resets subscription by cancelling existing one before next tier test (optional enhancement placeholder).
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const https = require('https');
const admin = require('firebase-admin');
try { admin.app(); } catch { admin.initializeApp(); }

function parseArgs() {
  const args = process.argv.slice(2); const out={};
  for (let i=0;i<args.length;i++){ if(args[i].startsWith('--')){ const k=args[i].replace(/^--/,''); const v=args[i+1] && !args[i+1].startsWith('--') ? args[i+1] : true; out[k]=v; }}
  return out;
}

function runTest(userId, tier, yearly=false, members=0) {
  const params = ['functions/scripts/automated_subscription_test.js','--user',userId,'--tier',tier,'--yearly',String(yearly),'--members',String(members)];
  const res = spawnSync('node', params, { encoding:'utf8' });
  let parsed; let raw = res.stdout.trim();
  try { parsed = JSON.parse(raw); } catch(e){ parsed = { parseError: e.message, raw }; }
  return { tier, yearly, members, exitCode: res.status, result: parsed, stderr: res.stderr.trim() };
}

async function acquireIdToken(userId) {
  if (process.env.FIREBASE_ID_TOKEN) return process.env.FIREBASE_ID_TOKEN.trim();
  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  if (!apiKey) throw new Error('FIREBASE_ID_TOKEN or FIREBASE_WEB_API_KEY required for cleanup');
  const customToken = await admin.auth().createCustomToken(userId);
  const body = JSON.stringify({ token: customToken, returnSecureToken: true });
  return await new Promise((resolve, reject) => {
    const url = new URL(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`);
    const req = https.request(url, { method:'POST', headers:{'Content-Type':'application/json'}}, res => {
      let raw=''; res.on('data',d=>raw+=d); res.on('end',()=>{ try { resolve(JSON.parse(raw).idToken); } catch(e){ reject(e); } });
    });
    req.on('error', reject); req.write(body); req.end();
  });
}

async function cancelExistingSubscription(userId, idToken) {
  const db = admin.firestore();
  const snap = await db.collection('users').doc(userId).get();
  if (!snap.exists) return false;
  const sub = snap.data().subscription;
  if (!sub?.stripeSubscriptionId) return false;
  const payload = JSON.stringify({ data: { userId, subscriptionId: sub.stripeSubscriptionId } });
  const url = new URL('https://us-central1-redping-a2e37.cloudfunctions.net/cancelSubscription');
  return await new Promise((resolve) => {
    const req = https.request(url, { method:'POST', headers:{'Content-Type':'application/json','Authorization':`Bearer ${idToken}`}}, res => { let raw=''; res.on('data',d=>raw+=d); res.on('end',()=>{ resolve(true); }); });
    req.on('error', err => { console.warn('Cancel error:', err.message); resolve(false); });
    req.write(payload); req.end();
  });
}

async function main(){
  const args = parseArgs();
  const userId = args.user;
  if(!userId){ console.error('Missing --user'); process.exit(1); }
  const tiers = (args.tiers || 'pro,ultra,family').split(',').map(s=>s.trim()).filter(Boolean);
  const yearly = args.yearly === 'true';
  const includeYearly = args.includeYearly === 'true';
  const outFile = args.output;
  const cleanup = args.cleanup !== 'false'; // default true
  const idToken = await acquireIdToken(userId).catch(e=>{ console.warn('ID token acquisition failed for cleanup:', e.message); return null; });

  const batch = [];
  function pushRecord(tier, yFlag) {
    console.log(`Running test for tier=${tier} yearly=${yFlag}`);
    const record = runTest(userId, tier, yFlag, tier==='ultra'?2:0);
    batch.push(record);
  }

  for (const tier of tiers){
    if (cleanup && idToken) {
      console.log(`Pre-test cleanup: cancelling existing subscription (tier=${tier})`);
      await cancelExistingSubscription(userId, idToken);
      // brief wait for Firestore update
      await new Promise(r => setTimeout(r, 800));
    }
    pushRecord(tier, yearly);
    if (includeYearly && !yearly) {
      if (cleanup && idToken) {
        console.log(`Pre-test cleanup (yearly variant): cancelling existing subscription`);
        await cancelExistingSubscription(userId, idToken);
        await new Promise(r => setTimeout(r, 800));
      }
      pushRecord(tier, true);
    }
  }

  const tiersSummary = batch.map(b=>({
    tier: b.tier,
    yearly: b.yearly,
    pass: b.result?.pass,
    status: b.result?.snapshot?.subscription?.status,
    retryAttempts: b.result?.snapshot?.subscription?.retryAttempts,
    durationMs: b.result?.durationMs,
    missing: b.result?.featureValidation?.missing,
    extra: b.result?.featureValidation?.extra,
  }));
  const total = tiersSummary.length;
  const passed = tiersSummary.filter(t=>t.pass).length;
  const passRate = total ? (passed/total) : 0;
  const summary = {
    userId,
    baseYearlyFlag: yearly,
    includeYearly,
    totalTests: total,
    passedTests: passed,
    passRate,
    tiers: tiersSummary,
    failures: tiersSummary.filter(t=>!t.pass),
    generatedAt: new Date().toISOString(),
  };

  const json = JSON.stringify(summary, null, 2);
  if(outFile){ fs.writeFileSync(outFile, json, 'utf8'); console.log('Batch results written to', outFile); } else { console.log(json); }

  const anyFail = summary.tiers.some(t=>!t.pass);
  if (anyFail && process.env.SLACK_WEBHOOK_URL) {
    try {
      const url = new URL(process.env.SLACK_WEBHOOK_URL);
      const failedLines = summary.failures.map(f=>`• tier=${f.tier} yearly=${f.yearly} status=${f.status} missing=${(f.missing||[]).join(',')}`).join('\n');
      const text = `Batch Subscription Tests FAILED (passRate=${(summary.passRate*100).toFixed(1)}%) for user=${userId}\n${failedLines}`;
      const payload = JSON.stringify({ text });
      const req = https.request(url, { method:'POST', headers:{'Content-Type':'application/json','Content-Length': Buffer.byteLength(payload)} });
      req.on('error', e=>console.warn('Batch Slack alert error:', e.message));
      req.write(payload); req.end();
    } catch (e) {
      console.warn('Failed sending batch Slack alert:', e.message);
    }
  }
  process.exitCode = anyFail ? 1 : 0;
}

main().catch(e=>{ console.error('Fatal:', e); process.exit(1); });
