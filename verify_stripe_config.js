// Verify Stripe Price IDs Configuration
const ids = {
  essentialPlus: {
    monthly: 'price_1SYSJdPlurWsomXvLHqo1BQV',
    yearly: 'price_1SYSKIPlurWsomXva4VUJL3b',
  },
  pro: {
    monthly: 'price_1SYSHUPlurWsomXvpIkKf7IZ',
    yearly: 'price_1SYSI6PlurWsomXvJdn44f5k',
  },
  ultra: {
    monthly: 'price_1SYSAgPlurWsomXv5gYXx038',
    yearly: 'price_1SYSDGPlurWsomXvpfBoxNmo',
  },
  family: {
    monthly: 'price_1SYSEzPlurWsomXva7HWAETB',
    yearly: 'price_1SYSGBPlurWsomXvzv7yrZat',
  },
};

console.log('Stripe LIVE Price IDs Configuration\n');
console.log('=' .repeat(60));

let count = 0;
Object.entries(ids).forEach(([tier, periods]) => {
  Object.entries(periods).forEach(([period, id]) => {
    count++;
    const valid = id.startsWith('price_1') && id.length > 20;
    const status = valid ? '✓' : '✗';
    console.log(`${status} ${tier.padEnd(15)} ${period.padEnd(8)} ${id}`);
  });
});

console.log('=' .repeat(60));
console.log(`Total: ${count}/8 price IDs configured`);
console.log(`Status: ${count === 8 ? '✓ READY' : '✗ INCOMPLETE'}`);
