# RedPing Subscription Tier Templates for Stripe

This folder contains professional HTML templates for each subscription tier. Use these to create screenshots for your Stripe product images.

## 📁 Files Included

### Main Pricing Page
- **`subscription_tiers.html`** - Complete pricing page with all tiers and monthly/yearly toggle

### Individual Tier Cards (Optimized for Screenshots)
- **`essential_plus_tier.html`** - Essential+ tier ($4.99/month or $49.99/year)
- **`pro_tier.html`** - Pro tier ($9.99/month or $99.99/year) - MOST POPULAR
- **`ultra_tier.html`** - Ultra tier ($29.99/month + $5/member)
- **`family_plan.html`** - Family plan ($19.99/month for 4 accounts) - BEST VALUE

## 🎨 How to Use

### Step 1: Open HTML Files
1. Navigate to `c:\flutterapps\redping_14v\stripe_images\`
2. Open any tier HTML file in your web browser (Chrome, Firefox, Edge, Safari)

### Step 2: Toggle Monthly/Yearly Pricing
- Each card has a toggle at the top
- Click "Monthly" to show monthly pricing
- Click "Yearly" to show yearly pricing with savings badge

### Step 3: Take Screenshots

#### For Windows (using Snipping Tool):
1. Press `Windows + Shift + S`
2. Select the tier card area
3. Screenshot is copied to clipboard
4. Paste into image editor or directly into Stripe

#### For Mac (using built-in screenshot):
1. Press `Command + Shift + 4`
2. Select the tier card area
3. Screenshot saved to desktop

#### For High-Quality Screenshots:
1. Use browser's developer tools (F12)
2. Set device toolbar to 1200px width
3. Zoom to 100% or 125% for crisp images
4. Right-click on card → Inspect → Screenshot Node

### Step 4: Upload to Stripe

#### In Stripe Dashboard:
1. Go to **Products** → https://dashboard.stripe.com/products
2. For each product (Essential+, Pro, Ultra, Family):
   - Click the product name
   - Click **"Add images"**
   - Upload the corresponding screenshot
   - You can upload both monthly and yearly versions

## 📸 Recommended Screenshot Sizes

- **Width**: 800-1200px (optimal: 1000px)
- **Height**: 600-1000px (optimal: 800px)
- **Format**: PNG or JPG
- **Quality**: High (PNG recommended for crisp text)

## 🎨 Design Features

Each tier card includes:
- ✨ Gradient background matching tier personality
- 💳 Clear pricing display (monthly/yearly toggle)
- ✅ Feature list with checkmarks
- 🏷️ "NEW" badges for premium features
- 🎯 Clear call-to-action button
- 📊 Savings badge for yearly pricing

### Tier Colors:
- **Essential+**: Purple gradient (#667eea → #764ba2)
- **Pro**: Purple gradient with "MOST POPULAR" badge
- **Ultra**: Pink gradient (#f093fb → #f5576c) for enterprise feel
- **Family**: Green gradient (#43e97b → #38f9d7) for family warmth

## 💰 Pricing Summary

| Tier | Monthly | Yearly | Savings |
|------|---------|--------|---------|
| **Essential+** | $4.99 | $49.99 | $9.89 (17%) |
| **Pro** | $9.99 | $99.99 | $19.89 (17%) |
| **Ultra** | $29.99 + $5/member | $299.99 + $50/member | $59.89 (17%) |
| **Family** | $19.99 (4 accounts) | $199.99 (4 accounts) | $39.89 (17%) |

## 🔧 Customization

If you need to edit the templates:

1. Open the HTML file in a text editor
2. Look for the pricing section:
   ```html
   <div class="price-display">
       <span class="price-currency">$</span>4.99<span class="price-period">/mo</span>
   </div>
   ```
3. Update prices, features, or colors as needed
4. Save and refresh in browser

## 📋 Stripe Product Setup Checklist

For each tier, in Stripe Dashboard:

### Essential+ ($4.99/month)
- [ ] Create product "RedPing Essential+"
- [ ] Add monthly price: $4.99
- [ ] Add yearly price: $49.99
- [ ] Upload screenshot (monthly view)
- [ ] Upload screenshot (yearly view)
- [ ] Copy Price ID for monthly to `subscriptionPayments.js` line 38
- [ ] Copy Price ID for yearly to `subscriptionPayments.js` line 39

### Pro ($9.99/month)
- [ ] Create product "RedPing Pro"
- [ ] Add monthly price: $9.99
- [ ] Add yearly price: $99.99
- [ ] Upload screenshot (monthly view)
- [ ] Upload screenshot (yearly view)
- [ ] Monthly Price ID already set: `price_1SVjOIPlurWsomXvOvgWfPFK`
- [ ] Copy Price ID for yearly to `subscriptionPayments.js` line 43

### Ultra ($29.99/month + $5/member)
- [ ] Create product "RedPing Ultra"
- [ ] Add monthly price: $29.99
- [ ] Add yearly price: $299.99
- [ ] Upload screenshot (monthly view)
- [ ] Upload screenshot (yearly view)
- [ ] Monthly Price ID already set: `price_1SVjNIPlurWsomXvMAxQouxd`
- [ ] Copy Price ID for yearly to `subscriptionPayments.js` line 47
- [ ] Create additional product "Ultra Member Add-on" ($5/month, $50/year)

### Family ($19.99/month for 4 accounts)
- [ ] Create product "RedPing Family Plan"
- [ ] Add monthly price: $19.99
- [ ] Add yearly price: $199.99
- [ ] Upload screenshot (monthly view)
- [ ] Upload screenshot (yearly view)
- [ ] Monthly Price ID already set: `price_1SVjO7PlurWsomXv9CCcDrGF`
- [ ] Copy Price ID for yearly to `subscriptionPayments.js` line 51

## 🚀 Next Steps

After creating screenshots:

1. ✅ Upload to Stripe products
2. ✅ Copy Price IDs to `functions/src/subscriptionPayments.js`
3. ✅ Configure webhook (see `STRIPE_MANUAL_STEPS.md`)
4. ✅ Test payment flow with test cards
5. ✅ Go live!

## 📝 Notes

- All templates are **responsive** and look good on all screen sizes
- The **interactive toggle** works in the browser (monthly/yearly switch)
- Templates use **modern CSS** with gradients and shadows
- **No external dependencies** - pure HTML/CSS/JS
- Templates are optimized for **screenshot quality**

## 🎯 Pro Tips

1. **Take both monthly and yearly screenshots** for each tier
2. **Use consistent zoom level** across all screenshots (100%)
3. **Ensure text is crisp** - use PNG format
4. **Capture the entire card** including shadows for professional look
5. **Use the toggle** to show savings badge in yearly screenshots

---

**Created**: November 25, 2025  
**Purpose**: Stripe product image creation  
**Status**: Ready to use
