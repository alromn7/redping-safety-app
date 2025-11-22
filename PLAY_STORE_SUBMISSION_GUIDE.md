# Google Play Store Submission Checklist

**App Name:** REDP!NG  
**Version:** 1.0.0 (Build 1)  
**Status:** Pre-Submission Preparation  
**Target Launch:** December 5, 2025

---

## 1. App Store Listing Requirements

### App Information

**Title:** REDP!NG - Safety Ecosystem  
**Short Description (80 chars):**  
"Emergency SOS, crash detection, SAR coordination, and community safety network"

**Full Description (4000 chars max):**
```
REDP!NG is your comprehensive personal safety ecosystem, combining advanced technology with community support to keep you protected anywhere, anytime.

🚨 CORE SAFETY FEATURES:
• Automatic crash detection with AI-powered analysis
• One-tap SOS alerts to emergency contacts
• Real-time location sharing during emergencies
• Medical profile with critical health information
• Emergency card accessible via SMS/web link

👨‍⚕️ SEARCH & RESCUE COORDINATION:
• Professional SAR team coordination platform
• Real-time incident management dashboard
• Live location tracking for responders
• Secure team communication
• Incident escalation workflows

🤝 COMMUNITY SUPPORT:
• REDP!NG Mode for community-wide alerts
• Help request system for non-emergencies
• Local responder network
• Community safety notifications

🔒 SECURITY & PRIVACY:
• End-to-end encryption for sensitive data
• Play Integrity API protection
• Secure authentication with Firebase
• Privacy-first design principles

💎 SUBSCRIPTION TIERS:

FREE FOREVER:
✓ Basic SOS alerts
✓ Manual location sharing
✓ Emergency contacts (up to 3)
✓ Community chat access

ESSENTIAL+ ($4.99/month):
✓ All Free features
✓ Automatic crash detection
✓ Medical profile & digital card
✓ Unlimited emergency contacts
✓ Priority response

PRO ($9.99/month):
✓ All Essential+ features
✓ SMS broadcasting to contacts
✓ AI Safety Assistant (coming soon)
✓ Advanced analytics
✓ REDP!NG Mode access

ULTRA ($29.99/month):
✓ All Pro features
✓ Gadget integration (smartwatches, trackers)
✓ Satellite communication support
✓ Premium SAR coordination
✓ Custom workflows

FAMILY ($19.99/month):
✓ Pro features for up to 5 members
✓ Family dashboard
✓ Shared emergency contacts
✓ Group location tracking

🎉 14-DAY FREE TRIAL
Try any paid plan free for 14 days. No credit card required until trial ends.

📱 PERFECT FOR:
• Outdoor enthusiasts & adventurers
• Solo travelers & hikers
• Elderly care & medical conditions
• Parents monitoring children
• Professional first responders
• Community safety organizations

🌟 WHY CHOOSE REDP!NG?
Unlike basic safety apps, REDP!NG combines personal emergency response with professional SAR coordination and community support. Our system is trusted by emergency responders and everyday users alike.

Download REDP!NG today and join thousands protected by our safety ecosystem.

Privacy Policy: https://redping-a2e37.web.app/privacy
Terms of Service: https://redping-a2e37.web.app/terms
Support: support@redping.app
```

### App Category
**Primary Category:** Lifestyle  
**Secondary Category:** Health & Fitness

### Content Rating
**Target Audience:** 13+  
**Content Descriptors:**
- Digital Purchases
- Shares Location
- Unrestricted Internet Access

### Contact Information
**Developer Name:** REDP!NG Team  
**Email:** support@redping.app  
**Website:** https://redping-a2e37.web.app  
**Privacy Policy:** https://redping-a2e37.web.app/privacy

---

## 2. Required Graphics & Assets

### App Icon
- **Size:** 512x512 px (32-bit PNG with alpha)
- **Format:** PNG
- **Requirements:** 
  - No transparency
  - Full square (will be masked by Google)
  - High-quality REDP!NG logo on gradient background

### Feature Graphic
- **Size:** 1024x500 px
- **Format:** JPG or 24-bit PNG (no alpha)
- **Content:** "REDP!NG - Your Safety Ecosystem" with emergency icon overlay

### Screenshots (Required: minimum 2, maximum 8 per device type)

**Phone Screenshots (portrait 16:9 or taller):**
1. **Home Screen** - Show SOS button and status
2. **Emergency Alert** - Active SOS session with map
3. **SAR Dashboard** - Real-time incident coordination
4. **Subscription Plans** - Show 14-day trial banner
5. **Medical Profile** - Digital emergency card
6. **Community Chat** - REDP!NG Mode interface
7. **Gadgets Integration** - Connected devices screen
8. **Analytics Dashboard** - Safety insights

**Tablet Screenshots (optional):**
- Same content, optimized for 7" and 10" tablet layouts

**Screenshot Specs:**
- Dimensions: 1080x1920 px minimum (9:16 aspect ratio)
- Format: PNG or JPG
- Max file size: 8 MB each
- No borders or decorative frames

### Promotional Video (Optional but Recommended)
- **Length:** 30 seconds - 2 minutes
- **Content:** Quick demo of SOS alert, crash detection, SAR coordination
- **YouTube URL:** Upload to YouTube and link

---

## 3. App Content & Policies

### Privacy Policy (REQUIRED)
**URL:** https://redping-a2e37.web.app/privacy

**Must include:**
- What data is collected (location, contacts, health info)
- How data is used (emergency response, SAR coordination)
- Data retention policies
- User rights (access, deletion)
- Third-party services (Firebase, Stripe, Google Maps)

### Data Safety Section

**Location:**
- ✅ Approximate location
- ✅ Precise location
- **Purpose:** Emergency response, location sharing
- **Data sharing:** With emergency contacts & SAR teams only
- **Optional:** Yes (can be disabled except during SOS)
- **Data encrypted in transit:** Yes
- **User can request deletion:** Yes

**Personal Info:**
- ✅ Name
- ✅ Email address
- ✅ Phone number
- ✅ Medical information
- **Purpose:** Emergency profile, contact identification
- **Data encrypted in transit & at rest:** Yes
- **User can request deletion:** Yes

**Health Info:**
- ✅ Medical conditions
- ✅ Allergies
- ✅ Medications
- **Purpose:** Emergency responder information
- **Data encrypted in transit & at rest:** Yes

**Financial Info:**
- ✅ Payment info (via Stripe)
- **Purpose:** Subscription management
- **Handled by:** Third-party payment processor (Stripe)
- **Data encrypted in transit:** Yes

---

## 4. Technical Requirements

### App Bundle (.aab)
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Signed with production keystore
- [ ] Version: 1.0.0 (Build 1)
- [ ] Target SDK: 34 (Android 14)
- [ ] Minimum SDK: 21 (Android 5.0)

### Build Command:
```powershell
flutter build appbundle --release
```

**Output location:** `build/app/outputs/bundle/release/app-release.aab`

### Code Obfuscation (Recommended)
```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

### App Signing
- [ ] Upload keystore to Play Console (first release)
- [ ] Enable Google Play App Signing
- [ ] Keep backup of upload key in secure location

---

## 5. Testing Requirements

### Pre-Launch Report (Automated by Google)
Google will automatically test on ~20 devices. Ensure:
- [ ] App launches without crashes
- [ ] No critical accessibility issues
- [ ] No security vulnerabilities
- [ ] Permissions properly requested

### Internal Testing Track
1. Upload AAB to Internal Testing
2. Add test users (emails)
3. Test on multiple devices:
   - Samsung Galaxy S21 (Android 14)
   - Google Pixel 7 (Android 14)
   - OnePlus 9 (Android 13)
4. Verify:
   - [ ] SOS alerts work
   - [ ] Crash detection triggers
   - [ ] Subscription flow (with test Stripe cards)
   - [ ] Location sharing accurate
   - [ ] SAR dashboard loads

---

## 6. Compliance & Legal

### Sensitive Permissions Justification

**Location (Fine & Coarse):**
"Required for emergency SOS alerts and real-time location sharing during incidents"

**SMS Send & Receive:**
"Sends emergency SMS alerts to contacts and receives replies for two-way communication"

**Phone State:**
"Detects phone crashes/drops to trigger automatic emergency alerts"

**Contacts:**
"Allows users to select emergency contacts for SOS alerts"

**Camera:**
"Scans QR codes for gadget pairing and takes photos for incident documentation"

### Advertising ID Declaration
- **Uses Advertising ID:** No
- **Ad Networks:** None

### Target Audience & Content
- **Age Rating:** PEGI 3, ESRB Everyone
- **Contains Ads:** No
- **In-App Purchases:** Yes (subscriptions)

---

## 7. Submission Checklist

### Before Upload
- [ ] Update version to 1.0.0+1 (pubspec.yaml) ✅
- [ ] Build production AAB
- [ ] Test on physical devices (3+ devices)
- [ ] Verify Stripe test payments work
- [ ] Confirm Firebase production rules deployed ✅
- [ ] Test emergency SMS sending
- [ ] Verify crash detection works

### Play Console Setup
- [ ] Create app in Play Console
- [ ] Complete Data Safety section
- [ ] Upload all graphics (icon, feature graphic, screenshots)
- [ ] Write store listing (title, description)
- [ ] Set content rating
- [ ] Add contact information
- [ ] Upload privacy policy URL
- [ ] Configure pricing (free with in-app purchases)
- [ ] Select countries (start with Australia, expand later)

### Upload & Release
- [ ] Upload AAB to Internal Testing
- [ ] Invite 5-10 testers
- [ ] Test for 3-5 days
- [ ] Fix any critical issues
- [ ] Promote to Production (or Closed Testing first)
- [ ] Submit for review
- [ ] Monitor review status (typically 1-3 days)

---

## 8. Post-Submission

### Launch Day (Dec 5, 2025)
- [ ] Monitor Play Console for crashes
- [ ] Check Firebase Analytics for installs
- [ ] Respond to user reviews within 24 hours
- [ ] Monitor Stripe Dashboard for subscriptions
- [ ] Check error logs in Firebase Crashlytics

### Week 1 Monitoring
- [ ] Daily crash rate < 0.1%
- [ ] ANR (App Not Responding) rate < 0.05%
- [ ] Review rating target: 4.5+ stars
- [ ] Subscription conversion: Track trial → paid rate

---

## 9. Marketing Assets (Optional)

### Social Media Graphics
- **Twitter/X Card:** 1200x628 px
- **Facebook Share:** 1200x630 px
- **Instagram Post:** 1080x1080 px
- **LinkedIn Banner:** 1584x396 px

### Press Kit
- App icon (multiple sizes)
- Feature graphic
- Screenshots
- Demo video
- Fact sheet (features, pricing)
- Founder bio/company info

---

## 10. Important Notes

⚠️ **Before Going Live:**
1. Disable trial mode after Dec 4: Set `enableTrialForAllPlans = false`
2. Ensure Stripe production keys configured (see STRIPE_KEYS_SETUP_REQUIRED.md)
3. Test end-to-end payment flow with real credit card
4. Verify webhook receiving events in Stripe Dashboard

🎯 **Success Metrics:**
- 1,000 installs in first week
- 100 trial signups
- 20% trial → paid conversion
- 4.5+ star rating
- < 1% crash rate

📧 **Support Email:**
Set up support@redping.app for user inquiries and Play Console communications

---

**Next Steps:**
1. ✅ Build production AAB
2. Create screenshots (use Android emulator or real device)
3. Design app icon and feature graphic
4. Write privacy policy
5. Set up Play Console account
6. Upload and submit for review

**Timeline:**
- Nov 20-27: Create graphics and test
- Nov 28-Dec 1: Upload to Internal Testing
- Dec 2-4: Testing and fixes
- Dec 4: Submit for Production review
- Dec 5: Public launch (pending approval)
