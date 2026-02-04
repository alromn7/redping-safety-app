# 🎯 Stripe Features Setup Guide for RedPing

Set up monetizable features in Stripe that can be linked to subscription products.

---

## 📋 Step 1: Create Features in Stripe

Go to: **Stripe Dashboard → Products → Features** (or https://dashboard.stripe.com/test/products/features)

Create the following features:

---

### Feature 1: Medical Profile Storage
**Feature Name**: `Medical Profile`  
**Lookup Key**: `medical_profile`  
**Description**: Store medical information including allergies, medications, blood type, and conditions for emergency responders.

---

### Feature 2: Auto Crash/Fall Detection (ACFD)
**Feature Name**: `Auto Crash & Fall Detection`  
**Lookup Key**: `auto_crash_fall_detection`  
**Description**: Automatic detection of vehicle crashes (60+ km/h) and falls with AI verification and emergency alerts.

---

### Feature 3: Hazard Alerts
**Feature Name**: `Hazard Alerts`  
**Lookup Key**: `hazard_alerts`  
**Description**: Real-time weather alerts, natural disaster warnings, and environmental hazard notifications.

---

### Feature 4: SOS SMS Alerts
**Feature Name**: `SOS SMS Alerts`  
**Lookup Key**: `sos_sms_alerts`  
**Description**: Automated emergency SMS messages sent to emergency contacts with GPS location.

---

### Feature 5: RedPing Mode
**Feature Name**: `RedPing Mode`  
**Lookup Key**: `redping_mode`  
**Description**: Activity-based safety modes (Hiking, Driving, Running, Biking, Emergency, Custom) with optimized detection.

---

### Feature 6: AI Safety Assistant
**Feature Name**: `AI Safety Assistant`  
**Lookup Key**: `ai_safety_assistant`  
**Description**: Full AI assistant with 24 intelligent commands across emergency, safety monitoring, SAR, medical, and predictive analytics.

---

### Feature 7: Gadget Integration
**Feature Name**: `Gadget Integration`  
**Lookup Key**: `gadget_integration`  
**Description**: Connect smartwatches (Apple Watch, Galaxy Watch, Fitbit), car devices (OBD-II), and wearable sensors.

---

### Feature 8: SAR Dashboard Access
**Feature Name**: `SAR Dashboard - Full Access`  
**Lookup Key**: `sar_dashboard_full`  
**Description**: View, respond to, and manage SOS alerts. Update status, assign missions, and participate in rescue operations.

---

### Feature 9: SAR Admin Management
**Feature Name**: `SAR Admin Management`  
**Lookup Key**: `sar_admin_management`  
**Description**: Create and manage SAR organizations, unlimited teams, member roles, and enterprise analytics.

---

### Feature 10: Unlimited Emergency Contacts
**Feature Name**: `Unlimited Emergency Contacts`  
**Lookup Key**: `unlimited_emergency_contacts`  
**Description**: Add unlimited emergency contacts (Free tier limited to 2, Essential+ limited to 5).

---

### Feature 11: Satellite Messaging
**Feature Name**: `Satellite Messaging`  
**Lookup Key**: `satellite_messaging`  
**Metadata**: 
- `essential_quota`: `5`
- `pro_quota`: `100`
- `ultra_quota`: `unlimited`
- `family_quota`: `150`

**Description**: Send emergency messages via satellite when cellular network is unavailable.

---

### Feature 12: Priority Response
**Feature Name**: `Priority Response`  
**Lookup Key**: `priority_response`  
**Description**: Higher priority in emergency response queue with faster notification to SAR teams.

---

### Feature 13: Family Dashboard
**Feature Name**: `Family Dashboard`  
**Lookup Key**: `family_dashboard`  
**Description**: Centralized family safety monitoring with shared contacts, location tracking, and coordinated emergency response.

---

### Feature 14: Enterprise Analytics
**Feature Name**: `Enterprise Analytics`  
**Lookup Key**: `enterprise_analytics`  
**Description**: Advanced metrics, team performance tracking, compliance tools, and organization-wide reporting.

---

### Feature 15: Custom API Access
**Feature Name**: `Custom API Access`  
**Lookup Key**: `custom_api_access`  
**Description**: Integration APIs for custom enterprise systems and white-label implementations.

---

## 📋 Step 2: Link Features to Products

After creating all features, link them to each product:

### Essential+ Product Features
Link these features:
- ✅ Medical Profile
- ✅ Auto Crash & Fall Detection
- ✅ Hazard Alerts
- ✅ SOS SMS Alerts
- ✅ Satellite Messaging (5 messages/month)

### Pro Product Features
Link these features (includes all Essential+ features):
- ✅ Medical Profile
- ✅ Auto Crash & Fall Detection
- ✅ Hazard Alerts
- ✅ SOS SMS Alerts
- ✅ RedPing Mode
- ✅ AI Safety Assistant
- ✅ Gadget Integration
- ✅ SAR Dashboard - Full Access
- ✅ Unlimited Emergency Contacts
- ✅ Satellite Messaging (100 messages/month)
- ✅ Priority Response

### Ultra Product Features
Link these features (includes all Pro features):
- ✅ Medical Profile
- ✅ Auto Crash & Fall Detection
- ✅ Hazard Alerts
- ✅ SOS SMS Alerts
- ✅ RedPing Mode
- ✅ AI Safety Assistant
- ✅ Gadget Integration
- ✅ SAR Dashboard - Full Access
- ✅ Unlimited Emergency Contacts
- ✅ Satellite Messaging (unlimited)
- ✅ Priority Response
- ✅ SAR Admin Management
- ✅ Enterprise Analytics
- ✅ Custom API Access

### Family Product Features
Link these features:
- ✅ Medical Profile (all 4 accounts)
- ✅ Auto Crash & Fall Detection (all 4 accounts)
- ✅ Hazard Alerts (all 4 accounts)
- ✅ SOS SMS Alerts (all 4 accounts)
- ✅ RedPing Mode (Pro account only)
- ✅ AI Safety Assistant (Pro account only)
- ✅ Gadget Integration (Pro account only)
- ✅ SAR Dashboard - Full Access (Pro account only)
- ✅ Unlimited Emergency Contacts (shared)
- ✅ Satellite Messaging (150 messages/month shared)
- ✅ Family Dashboard

---

## 📋 Step 3: Create Products with Linked Features

Now create each product in Stripe and link the features:

### Product 1: RedPing Essential+
1. Go to **Products → Add product**
2. **Name**: `RedPing Essential+`
3. **Description**: `Complete protection with automatic detection. Medical profile, auto crash/fall detection, hazard alerts, and SOS SMS to emergency contacts.`
4. **Add pricing**:
   - Monthly: $4.99 USD (Recurring)
   - Yearly: $49.99 USD (Recurring)
5. **Link features** (click "Add feature"):
   - Medical Profile
   - Auto Crash & Fall Detection
   - Hazard Alerts
   - SOS SMS Alerts
   - Satellite Messaging
6. Save product
7. **Copy Price IDs**

### Product 2: RedPing Pro
1. **Name**: `RedPing Pro`
2. **Description**: `Advanced safety with AI & gadgets. Everything from Essential+ plus activity modes, AI assistant (24 commands), smartwatch/car integration, and full SAR dashboard access.`
3. **Add pricing**:
   - Monthly: $9.99 USD (Recurring)
   - Yearly: $99.99 USD (Recurring)
4. **Link features**:
   - All Essential+ features
   - RedPing Mode
   - AI Safety Assistant
   - Gadget Integration
   - SAR Dashboard - Full Access
   - Unlimited Emergency Contacts
   - Priority Response
5. Save product
6. **Copy Price IDs**

### Product 3: RedPing Ultra
1. **Name**: `RedPing Ultra`
2. **Description**: `Enterprise safety management. Everything from Pro plus SAR admin tools, unlimited teams, member management, and enterprise analytics. Base + $5/month per additional member.`
3. **Add pricing**:
   - Monthly: $29.99 USD (Recurring)
   - Yearly: $299.99 USD (Recurring)
4. **Link features**:
   - All Pro features
   - SAR Admin Management
   - Enterprise Analytics
   - Custom API Access
5. Save product
6. **Copy Price IDs**

### Product 4: RedPing Family Plan
1. **Name**: `RedPing Family Plan`
2. **Description**: `4 accounts for $19.99/month. Includes 1 Pro account and 3 Essential+ accounts with family dashboard, shared contacts, and coordinated safety monitoring. Save 50%!`
3. **Add pricing**:
   - Monthly: $19.99 USD (Recurring)
   - Yearly: $199.99 USD (Recurring)
4. **Link features**:
   - Medical Profile
   - Auto Crash & Fall Detection
   - Hazard Alerts
   - SOS SMS Alerts
   - RedPing Mode
   - AI Safety Assistant
   - Gadget Integration
   - SAR Dashboard - Full Access
   - Unlimited Emergency Contacts
   - Family Dashboard
5. Save product
6. **Copy Price IDs**

---

## 📋 Step 4: Update Price IDs in Cloud Function

After creating all products, update `functions/src/subscriptionPayments.js`:

```javascript
const PRICE_IDS = {
  essentialPlus: {
    monthly: 'price_________________', // Your Essential+ monthly
    yearly: 'price_________________',  // Your Essential+ yearly
  },
  pro: {
    monthly: 'price_________________', // Your Pro monthly
    yearly: 'price_________________',  // Your Pro yearly
  },
  ultra: {
    monthly: 'price_________________', // Your Ultra monthly
    yearly: 'price_________________',  // Your Ultra yearly
  },
  family: {
    monthly: 'price_________________', // Your Family monthly
    yearly: 'price_________________',  // Your Family yearly
  },
};
```

Deploy:
```bash
cd functions
firebase deploy --only functions:processSubscriptionPayment
```

---

## 📋 Step 5: Verify Feature Entitlements

After a user subscribes, you can check their entitlements via Stripe API:

```javascript
// In your Cloud Function or backend
const subscription = await stripe.subscriptions.retrieve(subscriptionId, {
  expand: ['items.data.price.product.features']
});

// Check if user has specific feature
const hasFeature = subscription.items.data[0].price.product.features.some(
  feature => feature.lookup_key === 'ai_safety_assistant'
);
```

---

## ✅ Quick Setup Checklist

### Features Setup (Do this first):
- [ ] Create Medical Profile feature
- [ ] Create Auto Crash & Fall Detection feature
- [ ] Create Hazard Alerts feature
- [ ] Create SOS SMS Alerts feature
- [ ] Create RedPing Mode feature
- [ ] Create AI Safety Assistant feature
- [ ] Create Gadget Integration feature
- [ ] Create SAR Dashboard - Full Access feature
- [ ] Create SAR Admin Management feature
- [ ] Create Unlimited Emergency Contacts feature
- [ ] Create Satellite Messaging feature
- [ ] Create Priority Response feature
- [ ] Create Family Dashboard feature
- [ ] Create Enterprise Analytics feature
- [ ] Create Custom API Access feature

### Products Setup (Do this second):
- [ ] Create Essential+ product with 5 linked features
- [ ] Create Pro product with 11 linked features
- [ ] Create Ultra product with 14 linked features
- [ ] Create Family product with 10 linked features
- [ ] Add monthly + yearly pricing to each product
- [ ] Copy all 8 price IDs
- [ ] Update subscriptionPayments.js with price IDs
- [ ] Deploy Cloud Function

### Testing:
- [ ] Test Essential+ subscription
- [ ] Test Pro subscription
- [ ] Test Ultra subscription
- [ ] Test Family subscription
- [ ] Verify feature entitlements in Stripe Dashboard
- [ ] Test feature access in app

---

## 🎯 Benefits of Using Stripe Features

✅ **Clear Entitlements**: Easy to see what features a customer has access to  
✅ **Flexible Product Changes**: Modify feature sets without changing code  
✅ **Better Reporting**: Track feature adoption and usage  
✅ **A/B Testing**: Test different feature combinations  
✅ **Compliance**: Clear audit trail of feature access  

---

**Document Created**: November 28, 2025  
**Purpose**: Set up Stripe Features for RedPing subscription entitlements  
**Status**: Ready for implementation
