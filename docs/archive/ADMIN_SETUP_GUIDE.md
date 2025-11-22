# RedPing Administrator Setup Guide

## Quick Setup Checklist

- [ ] Firebase Project Created
- [ ] Firestore Database Initialized
- [ ] Firebase Environment Variables Added to Vercel
- [ ] Mobile App Built and Tested
- [ ] Website Deployed to Vercel
- [ ] Test User Profile Created
- [ ] Test SOS Session Sent
- [ ] Test Help Request Sent
- [ ] Call/SMS Buttons Verified
- [ ] SAR Teams Onboarded

---

## 1. Firebase Setup

### Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click **"Add Project"**
3. Project Name: `redping` (or your choice)
4. Enable Google Analytics (optional)
5. Click **"Create Project"**

### Enable Firestore Database

1. In Firebase Console, navigate to **Firestore Database**
2. Click **"Create Database"**
3. Choose **Production Mode** (or Test Mode for development)
4. Select your region (closest to users)
5. Click **"Enable"**

### Create Collections

Create these collections manually or let the app create them:

```
users/
  └── user_{timestamp}/
      ├── id: string
      ├── name: string
      ├── email: string
      ├── phone: string
      ├── phoneNumber: string
      ├── createdAt: timestamp
      └── updatedAt: timestamp

sos_sessions/
  └── sos_{timestamp}/
      ├── id: string
      ├── userId: string
      ├── userName: string
      ├── userPhone: string
      ├── status: string (active|acknowledged|responding|resolved)
      ├── location: geopoint
      ├── timestamp: timestamp
      └── communicationHistory: array

help_requests/
  └── help_{timestamp}/
      ├── id: string
      ├── userId: string
      ├── userName: string
      ├── userPhone: string
      ├── categoryId: string
      ├── subCategoryId: string
      ├── description: string
      ├── status: string
      └── communicationHistory: array
```

### Configure Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read: if true; // Allow SAR teams to read user profiles
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // SOS sessions - anyone can create, SAR teams can update
    match /sos_sessions/{sosId} {
      allow read: if true; // Public read for SAR dashboard
      allow create: if request.auth != null;
      allow update: if true; // Allow SAR teams to update status
      allow delete: if false; // Never delete SOS sessions
    }
    
    // Help requests - anyone can create, SAR teams can update
    match /help_requests/{helpId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if true;
      allow delete: if false;
    }
    
    // SAR teams collection (optional)
    match /sar_teams/{teamId} {
      allow read: if true;
      allow write: if request.auth != null; // Only authenticated users
    }
  }
}
```

### Get Firebase Config

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll to **"Your apps"**
3. Click **Web** icon (</>) to add web app
4. Register app with nickname: "RedPing Web"
5. Copy the config values:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "redping-a2e37.firebaseapp.com",
  projectId: "redping-a2e37",
  storageBucket: "redping-a2e37.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123"
};
```

---

## 2. Mobile App Setup (Flutter)

### Prerequisites

```bash
flutter --version  # Should be 3.x or higher
dart --version     # Should be 3.x or higher
```

### Configure Firebase in App

1. **Add google-services.json** (Android)
   ```
   redping_14v/android/app/google-services.json
   ```

2. **Update Firebase Config**
   Edit `lib/config/firebase_config.dart`:
   ```dart
   static const String apiKey = 'YOUR_API_KEY';
   static const String projectId = 'redping-a2e37';
   static const String authDomain = 'redping-a2e37.firebaseapp.com';
   // ... other config
   ```

### Build APK

```powershell
# Navigate to project
cd c:\flutterapps\redping_14v

# Get dependencies
flutter pub get

# Clean previous builds
flutter clean

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install on Test Device

```powershell
# List connected devices
adb devices

# Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or install to specific device
adb -s DEVICE_ID install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 3. Website Setup (Next.js + Vercel)

### Prerequisites

```bash
node --version  # Should be 18.x or higher
npm --version   # Should be 9.x or higher
```

### Install Vercel CLI

```powershell
npm install -g vercel
```

### Configure Environment Variables

Create `.env.local` file:

```env
# Firebase Client Config (NEXT_PUBLIC_ prefix for client-side access)
NEXT_PUBLIC_FIREBASE_API_KEY=AIza...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=redping-a2e37.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=redping-a2e37
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=redping-a2e37.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abc123

# Google Maps API (Optional)
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=AIza...

# App URL
NEXT_PUBLIC_APP_URL=https://redping-website.vercel.app
```

### Build Locally

```powershell
cd c:\flutterapps\redping_website2

# Install dependencies
npm install

# Build for production
npm run build

# Test locally
npm run start
```

### Deploy to Vercel

```powershell
# Login to Vercel
vercel login

# Deploy to production
vercel --prod
```

### Add Environment Variables in Vercel Dashboard

1. Go to https://vercel.com/dashboard
2. Select your project
3. Go to **Settings** → **Environment Variables**
4. Add each variable:
   - Name: `NEXT_PUBLIC_FIREBASE_API_KEY`
   - Value: `AIza...`
   - Environment: **Production** ✓
5. Repeat for all 6 Firebase variables
6. **Redeploy** after adding variables

---

## 4. Testing the Complete System

### Test 1: User Profile Setup

1. **Install app** on test device
2. **Create account** with email/password
3. **Fill profile**:
   - Name: Test User
   - Phone: +1234567890 (with country code!)
   - Email: test@example.com
4. **Verify in Firebase**:
   - Open Firebase Console
   - Navigate to Firestore → `users`
   - Find your user document
   - Verify `name`, `phone`, `phoneNumber` fields exist

### Test 2: SOS Session

1. **Send SOS** from app
   - Open app
   - Tap SOS button (hold 3 seconds)
   - Wait for confirmation

2. **Verify in Firebase**:
   - Firestore → `sos_sessions`
   - Find latest document (sos_{timestamp})
   - Check fields:
     ```json
     {
       "userName": "Test User",
       "userPhone": "+1234567890",
       "phoneNumber": "+1234567890",
       "status": "active"
     }
     ```

3. **Check Dashboard**:
   - Open `https://your-deployment.vercel.app/sar-dashboard`
   - See SOS in "Live SOS Sessions"
   - Verify shows: Name, Phone, Call/SMS buttons

### Test 3: Help Request

1. **Send Help Request** from app
   - Tap RedPingLogoButton (below SOS)
   - Select category: "Lost Pet"
   - Select subcategory: "Lost Dog"
   - Fill description
   - Tap "Send Help Request"

2. **Verify in Firebase**:
   - Firestore → `help_requests`
   - Find latest document
   - Check enrichment:
     ```json
     {
       "userName": "Test User",
       "userPhone": "+1234567890",
       "phoneNumber": "+1234567890",
       "categoryId": "lost_pet",
       "subCategoryId": "lost_dog"
     }
     ```

3. **Check Dashboard**:
   - Refresh SAR dashboard
   - See request in "Live Help Requests"
   - Verify Call/SMS buttons appear

### Test 4: Call/SMS Buttons

**On Mobile Device:**
1. Open dashboard on phone/tablet
2. Click **Call** button → Should open Phone app
3. Click **SMS** button → Should open Messages app

**On Desktop:**
1. Open dashboard on computer
2. Click **Call** → Shows app selection popup (normal)
3. Select "Phone Link" if phone connected
4. Verify opens dialer/messaging app

---

## 5. Production Deployment

### Pre-Launch Checklist

#### Security
- [ ] Firestore rules configured correctly
- [ ] Firebase Auth enabled
- [ ] API keys restricted to specific domains
- [ ] Environment variables not committed to git
- [ ] HTTPS enforced on website

#### Functionality
- [ ] User registration working
- [ ] Profile updates syncing to Firebase
- [ ] SOS sessions appearing on dashboard
- [ ] Help requests appearing on dashboard
- [ ] Call/SMS buttons working on mobile
- [ ] Status updates reflecting in real-time

#### Performance
- [ ] Firebase quotas sufficient for expected load
- [ ] Vercel bandwidth limits checked
- [ ] App load time acceptable (<3s)
- [ ] Dashboard real-time updates working

#### Documentation
- [ ] User guide distributed to end users
- [ ] SAR team training completed
- [ ] Admin documentation available
- [ ] Support contact information provided

### Launch Steps

1. **Final Testing**
   - Run through all test scenarios
   - Test with multiple devices simultaneously
   - Verify real-time updates work
   - Test under poor network conditions

2. **Deploy Production Build**
   ```powershell
   # Website
   cd c:\flutterapps\redping_website2
   npm run build
   vercel --prod
   
   # Mobile App
   cd c:\flutterapps\redping_14v
   flutter build apk --release
   ```

3. **Distribute App**
   - Upload APK to distribution platform
   - Send download link to users
   - Provide installation instructions

4. **Monitor Initial Launch**
   - Watch Firebase Console for activity
   - Check Vercel logs for errors
   - Monitor dashboard for real-time updates
   - Respond to user feedback quickly

---

## 6. Maintenance & Monitoring

### Daily Checks

- [ ] Check Firebase quota usage
- [ ] Review Vercel deployment logs
- [ ] Monitor active SOS sessions
- [ ] Verify dashboard accessibility

### Weekly Tasks

- [ ] Review and archive old SOS sessions
- [ ] Clean up test data from Firebase
- [ ] Check for app crashes in Firebase Crashlytics
- [ ] Update documentation if features changed

### Monthly Tasks

- [ ] Review Firebase billing
- [ ] Update dependencies (npm, Flutter packages)
- [ ] Security audit of Firestore rules
- [ ] Performance optimization review

### Firebase Monitoring

**Console:** https://console.firebase.google.com/project/redping-a2e37

**Check:**
- **Authentication**: Active users, new signups
- **Firestore**: Read/write operations, storage size
- **Analytics**: User engagement, feature usage
- **Crashlytics**: App crashes, error rates

### Vercel Monitoring

**Dashboard:** https://vercel.com/dashboard

**Check:**
- **Deployments**: Success/failure rate
- **Analytics**: Page views, load times
- **Logs**: Runtime errors, warnings
- **Bandwidth**: Usage vs. limits

---

## 7. Common Admin Tasks

### Add New SAR Team Member

1. Create user in Firebase Authentication
2. Add to `sar_teams` collection:
   ```json
   {
     "id": "team_member_001",
     "name": "John Smith",
     "role": "coordinator",
     "phone": "+1234567890",
     "email": "john@sarteam.org",
     "certifications": ["EMT", "Search & Rescue"],
     "status": "active"
   }
   ```

### Reset User Password

1. Firebase Console → Authentication
2. Find user by email
3. Click **⋮** → **Reset Password**
4. User receives email with reset link

### Manually Close SOS Session

1. Firestore → `sos_sessions` → Find session
2. Edit document
3. Change `status` to `"resolved"`
4. Add `resolvedAt: [timestamp]`
5. Dashboard will update automatically

### Clean Up Old Data

```javascript
// Run in Firebase Console (Firestore Rules Playground)
// Delete SOS sessions older than 30 days

const cutoffDate = new Date();
cutoffDate.setDate(cutoffDate.getDate() - 30);

db.collection('sos_sessions')
  .where('timestamp', '<', cutoffDate)
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      doc.ref.delete();
    });
  });
```

### Export Data for Reports

1. Firebase Console → Firestore
2. Select collection
3. Click **Export** (requires billing account)
4. Choose Cloud Storage bucket
5. Download exported data

---

## 8. Troubleshooting Admin Issues

### Website Not Showing SOS/Help Requests

**Check:**
1. Vercel environment variables are set
2. Firebase Firestore rules allow read
3. Browser console for errors (F12)
4. Network tab shows Firestore connection

**Fix:**
```powershell
# Verify env vars
vercel env ls

# Add missing vars
vercel env add NEXT_PUBLIC_FIREBASE_API_KEY production

# Redeploy
vercel --prod
```

### App Can't Connect to Firebase

**Check:**
1. `google-services.json` is correct
2. Firebase project ID matches
3. Internet connection on device
4. Firestore rules allow write

**Fix:**
```dart
// lib/config/firebase_config.dart
// Verify project ID
static const String projectId = 'redping-a2e37'; // Must match Firebase
```

### Profile Enrichment Not Working

**Check:**
1. User profile has `phone` and `phoneNumber` fields
2. `FirebaseHelpService._enrichWithUserProfile()` is being called
3. UserId format matches between services

**Fix:**
```dart
// Verify enrichment logs in console
debugPrint('Enriched with profile - Name: $name, Phone: $phone');
```

### Call/SMS Buttons Missing

**Check:**
1. SOS/Help request has phone number
2. Profile was complete when request sent
3. Dashboard code checking correct field names

**Fix:**
```typescript
// Check multiple phone field names
const phone = r.userPhone || r.phoneNumber || r.contactNumber || r.phone;
```

---

## 9. Backup & Recovery

### Automated Firestore Backups

1. Firebase Console → Firestore → **Backups**
2. Click **Schedule Backup**
3. Choose frequency: Daily/Weekly
4. Select Cloud Storage bucket
5. Enable automatic backups

### Manual Backup

```bash
# Export Firestore data
gcloud firestore export gs://redping-backups/$(date +%Y%m%d)

# Restore from backup
gcloud firestore import gs://redping-backups/20251020
```

### Recovery Procedures

**User Data Lost:**
1. Check Firestore backups
2. Restore specific collection
3. Notify affected users
4. Re-sync app data

**Website Down:**
1. Check Vercel status: https://vercel-status.com
2. Review deployment logs
3. Rollback to previous deployment if needed
4. Fix issues and redeploy

**Firebase Outage:**
1. Check Firebase status: https://status.firebase.google.com
2. Wait for Google to resolve
3. Communicate with users via alternative channels
4. Resume normal operations when restored

---

## 10. Scaling Considerations

### Firebase Quotas (Free Tier)

- Firestore Reads: 50,000/day
- Firestore Writes: 20,000/day
- Storage: 1 GB
- Bandwidth: 10 GB/month

**Upgrade to Blaze (Pay-as-you-go) when:**
- Exceeding free tier limits
- Need more than 100 concurrent connections
- Require guaranteed uptime SLA

### Vercel Limits (Hobby Plan)

- Bandwidth: 100 GB/month
- Serverless Function Executions: 100 GB-hours
- Builds: Unlimited

**Upgrade to Pro when:**
- Traffic exceeds 100 GB/month
- Need team collaboration features
- Require advanced analytics

### Performance Optimization

**App:**
- Use Firebase offline persistence
- Implement caching for user profiles
- Lazy load help categories
- Optimize image sizes

**Website:**
- Enable Vercel Edge caching
- Implement service workers (PWA)
- Use Firebase connection pooling
- Minimize real-time listeners

---

## Contact Information

**Project:** RedPing Emergency Response System
**Firebase Project:** redping-a2e37
**Website:** https://redping-website-n701686q1-alfredo-jr-romanas-projects.vercel.app
**Version:** 14v
**Last Updated:** October 20, 2025

**Support:**
- Technical Issues: [your-email@example.com]
- Emergency Issues: Contact local emergency services
- Firebase Support: https://firebase.google.com/support
- Vercel Support: https://vercel.com/support

---

*This guide should be kept up-to-date as the system evolves.*
