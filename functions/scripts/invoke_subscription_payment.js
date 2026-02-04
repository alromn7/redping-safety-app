#!/usr/bin/env node
/**
 * Manual invocation helper for callable Cloud Function processSubscriptionPayment.
 *
 * Usage examples:
 *   set FIREBASE_ID_TOKEN=eyJhbGci... && node invoke_subscription_payment.js --user <uid> --tier pro --pm pm_card_visa --yearly false
 *
 * Requirements:
 * - Obtain a Firebase ID token for the target user (auth context). You can:
 *   a) Use the running app (add temporary debug print of currentUser.getIdToken())
 *   b) Use a custom token mint + exchange flow
 * - Ensure STRIPE payment method ID (pm_...) is attached or use a test card such as pm_card_visa.
 * - For test mode, run after deploying functions with test Stripe secret key.
 */

const https = require('https');
const { URL } = require('url');

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

async function main() {
  const { user: userId, tier = 'pro', pm: paymentMethodId = 'pm_card_visa', yearly = 'false', members } = parseArgs();
  if (!userId) {
    console.error('Missing --user <uid>');
    process.exit(1);
  }
  const idToken = process.env.FIREBASE_ID_TOKEN;
  if (!idToken) {
    console.error('Set FIREBASE_ID_TOKEN env var containing a valid Firebase ID token.');
    process.exit(1);
  }

  const isYearlyBilling = yearly === 'true';
  const additionalMembers = members ? parseInt(members, 10) : 0;

  const endpoint = `https://us-central1-redping-a2e37.cloudfunctions.net/processSubscriptionPayment`;
  const url = new URL(endpoint);

  const payload = {
    data: {
      userId,
      tier,
      paymentMethodId,
      savePaymentMethod: true,
      isYearlyBilling,
      additionalMembers,
    }
  };

  const body = JSON.stringify(payload);
  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${idToken}`,
    }
  };

  const req = https.request(url, options, (res) => {
    let raw = '';
    res.on('data', d => raw += d);
    res.on('end', () => {
      console.log('Status:', res.statusCode);
      console.log('Response:', raw);
      try {
        const json = JSON.parse(raw);
        console.log('Parsed:', JSON.stringify(json, null, 2));
      } catch (e) {
        // ignore
      }
    });
  });

  req.on('error', (e) => {
    console.error('Request error:', e.message);
  });

  req.write(body);
  req.end();
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
