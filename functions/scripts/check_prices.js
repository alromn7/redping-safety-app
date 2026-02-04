// Quick Stripe price verifier for configured PRICE_IDS
// - Reads functions/.env to get STRIPE_SECRET_KEY
// - Parses src/subscriptionPayments.js to extract all price_ IDs
// - Retrieves each price from Stripe and prints id, type, recurring, livemode

const fs = require('fs');
const path = require('path');

function loadEnvDotenv(envPath) {
  try {
    const raw = fs.readFileSync(envPath, 'utf8');
    for (const line of raw.split(/\r?\n/)) {
      if (!line || line.trim().startsWith('#')) continue;
      const idx = line.indexOf('=');
      if (idx === -1) continue;
      const key = line.slice(0, idx).trim();
      const value = line.slice(idx + 1).trim().replace(/^"|"$/g, '');
      if (!(key in process.env)) process.env[key] = value;
    }
  } catch (e) {
    // ignore if .env missing
  }
}

async function main() {
  const root = path.resolve(__dirname, '..');
  loadEnvDotenv(path.join(root, '.env'));

  const sk = process.env.STRIPE_SECRET_KEY;
  if (!sk) {
    console.error('ERROR: STRIPE_SECRET_KEY not found in environment or .env');
    process.exit(2);
  }

  const stripe = require('stripe')(sk);

  const srcFile = path.join(root, 'src', 'subscriptionPayments.js');
  const src = fs.readFileSync(srcFile, 'utf8');
  const priceIds = Array.from(new Set((src.match(/price_[A-Za-z0-9_]+/g) || [])));

  if (priceIds.length === 0) {
    console.error('No price_ IDs found in subscriptionPayments.js');
    process.exit(3);
  }

  console.log(`Found ${priceIds.length} price IDs in code. Verifying with Stripe (live mode depends on key) ...`);

  const results = [];
  let nonRecurring = 0;
  for (const id of priceIds) {
    try {
      const p = await stripe.prices.retrieve(id);
      const info = {
        id: p.id,
        type: p.type,
        livemode: !!p.livemode,
        active: !!p.active,
        currency: p.currency,
        recurring: p.recurring,
        product: p.product,
        nickname: p.nickname,
      };
      results.push(info);
      if (p.type !== 'recurring') nonRecurring++;
    } catch (e) {
      results.push({ id, error: e.message });
    }
  }

  // Pretty print
  for (const r of results) {
    if (r.error) {
      console.log(`- ${r.id}: ERROR - ${r.error}`);
    } else {
      console.log(`- ${r.id}: type=${r.type}, livemode=${r.livemode}, active=${r.active}, currency=${r.currency}, interval=${r.recurring?.interval || 'n/a'}`);
    }
  }

  if (nonRecurring > 0) {
    console.error(`\n${nonRecurring} price(s) are not recurring. Update PRICE_IDS to use recurring price IDs.`);
    process.exit(4);
  }

  console.log('\nAll configured price IDs are recurring.');
}

main().catch((e) => {
  console.error('Unexpected error:', e);
  process.exit(1);
});
