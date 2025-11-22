# RedPing User Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Profile Setup](#profile-setup)
3. [SOS Emergency System](#sos-emergency-system)
4. [Help Request System](#help-request-system)
5. [SAR Dashboard (Web)](#sar-dashboard-web)
6. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Installation

#### Mobile App (Android)
1. Download the latest APK from your distribution source
2. Enable "Install from Unknown Sources" in Android Settings
3. Install the APK
4. Grant required permissions:
   - Location (GPS)
   - Phone
   - SMS
   - Camera (for profile photo)
   - Notifications

#### Web Dashboard (SAR Teams)
- Access URL: `https://redping-website-[deployment].vercel.app/sar-dashboard`
- Compatible with:
  - Mobile browsers (Chrome, Safari, Firefox)
  - Desktop browsers (Chrome, Edge, Firefox)
  - Tablets (iPad, Android tablets)

---

## Profile Setup

### Initial Account Creation

1. **Launch the App**
   - Open RedPing on your device
   - You'll see the sign-up screen

2. **Create Your Account**
   ```
   Email: your-email@example.com
   Password: [Choose a strong password]
   Confirm Password: [Re-enter password]
   ```

3. **Complete Your Profile** (CRITICAL for SOS/Help)
   
   **Required Information:**
   - **Full Name**: Your real name (e.g., "John Smith")
   - **Phone Number**: With country code (e.g., "+61473054208")
   - **Email**: Valid email address
   - **Emergency Contact**: Family/friend contact info
   
   **Optional but Recommended:**
   - Profile Photo
   - Home Address
   - Medical Information
   - Blood Type
   - Allergies

### Why Profile Setup is Important

✅ **WITH Complete Profile:**
- SOS alerts show your name and phone
- SAR teams can call/text you immediately
- Help requests include contact details
- Faster emergency response

❌ **WITHOUT Profile:**
- Shows as "Anonymous User"
- No Call/SMS buttons on dashboard
- SAR teams can't contact you
- Delayed response times

### Updating Your Profile

1. Open RedPing app
2. Tap **Menu** → **Profile**
3. Edit any field
4. Tap **Save Changes**
5. Changes sync to Firebase immediately

---

## SOS Emergency System

### When to Use SOS

**Use for LIFE-THREATENING emergencies:**
- Medical emergencies (heart attack, severe injury)
- Natural disasters (earthquake, flood, fire)
- Physical assault or violence
- Kidnapping or abduction
- Lost in wilderness/remote area
- Vehicle accident with injuries

**✅ Emergency Response Mechanism:**
- ✅ **Enhanced SMS alerts to emergency contacts are sent automatically** (primary safety feature)
- ✅ **Smart contact selection**: Top priority contacts notified first, escalation to secondary contacts if no response
- ✅ **Two-way SMS**: Contacts can reply with HELP/FALSE to confirm or cancel
- ✅ **Manual call buttons**: You can call emergency services or contacts anytime via in-app buttons
- ❌ **No auto-dial**: App will NOT automatically call anyone (requires your manual tap for safety/privacy)
- 📌 Ensure your **emergency contacts** are configured in your profile

**DO NOT use for:**
- Minor inconveniences
- Non-urgent help (use Help Request instead)
- Testing (contact admin for test mode)

### Activating SOS

#### Method 1: Standard Activation
1. Open RedPing app
2. Tap the large red **"SOS"** button
3. **Hold for 3 seconds** (countdown appears)
4. SOS activates automatically

#### Method 2: Quick Activation (Emergency Mode)
1. Tap SOS button
2. Confirm emergency type
3. SOS activates immediately

### What Happens After SOS Activation

1. **Immediate Actions:**
   - GPS location captured
   - SOS session created in Firebase
   - ✅ **Enhanced automatic SMS alerts sent** (smart priority selection, no user action required)
     - Initial alert to top 3 priority contacts
     - Follow-up messages every 2 minutes
     - Escalation to secondary contacts at 5 minutes if no response
     - Contacts can reply HELP/FALSE to confirm/cancel
   - All nearby SAR teams notified via Firebase
   - Your profile data attached (name, phone, location)
   - 📱 **Manual call buttons available**: Use in-app buttons to call emergency services or contacts

2. **On SAR Dashboard:**
   - Red alert appears in "Live SOS Sessions"
   - Shows your location on map
   - Displays: Name, Phone, Time, Status
   - Call/SMS buttons enabled

3. **SAR Team Response:**
   - Nearest team acknowledges alert
   - Team changes status to "Responding"
   - Team can call/text you directly
   - Live location tracking begins

### SOS Session Lifecycle

```
Active → Acknowledged → Responding → Arrived → Resolved
```

**Status Definitions:**
- **Active**: SOS just sent, awaiting response
- **Acknowledged**: SAR team received alert
- **Responding**: Team en route to your location
- **Arrived**: Team on scene
- **Resolved**: Emergency handled, session closed

### Canceling SOS (False Alarm)

1. Open app during active SOS
2. Tap **"Cancel SOS"**
3. Confirm cancellation
4. Session status changes to "Cancelled"
5. SAR teams notified of cancellation

---

## Help Request System

### When to Use Help Requests

**Use for NON-EMERGENCY situations:**
- Vehicle breakdown (flat tire, dead battery)
- Lost pet or missing item
- Minor home issues (locked out, minor leak)
- Community support needs
- Local assistance requests

### Sending a Help Request

1. **Open Help System**
   - Tap the **RedPingLogoButton** (smaller button below SOS)
   - This opens "Comprehensive RedPing Help"

2. **Select Main Category**
   Choose from:
   - **Vehicle Breakdown** (car, truck, motorcycle issues)
   - **Boat Breakdown** (marine vessel issues)
   - **Lost Pet** (missing animals)
   - **Home Break-In** (security issues)
   - **Domestic Violence** (safety concerns)
   - **Drug Abuse** (substance issues)
   - **Criminal Activity** (witnessed crimes)
   - **Community Support** (general assistance)

3. **Select Specific Subcategory**
   
   Example for **Lost Pet**:
   - Lost Dog
   - Lost Cat
   - Lost Bird
   - Injured Pet Found
   - Stray Animal
   
   Example for **Vehicle Breakdown**:
   - Tire Issues
   - Battery Problems
   - Fuel Issues
   - Accident Damage
   - Engine Problems
   - Towing Required

4. **Fill in Details**
   ```
   Description: [Detailed explanation of your situation]
   Location: [Current location - auto-filled or manual]
   Additional Info: [Any extra relevant details]
   Hazards: [Safety concerns, if any]
   Number of People: [How many need help]
   Priority: Low / Medium / High
   ```

5. **Submit Request**
   - Tap **"Send Help Request"** (red button)
   - Request sent to Firebase
   - Profile data automatically attached
   - SAR dashboard updated in real-time

### Help Request Features

**Automatic Profile Enrichment:**
- Your name added automatically
- Phone number attached (from profile)
- Email included
- Location from GPS

**Requirements:**
- ✅ Must select main category
- ✅ Must select subcategory
- ⚠️ "Send" button stays gray until subcategory selected

### Tracking Your Help Request

1. **In App:**
   - Navigate to "My Requests"
   - See status: Active → Acknowledged → Assigned → In Progress → Resolved

2. **On Web Dashboard:**
   - Appears in "Live Help Requests"
   - Shows your contact info
   - SAR can respond via Call/SMS

---

## SAR Dashboard (Web)

### Accessing the Dashboard

**URL:** `https://redping-website-[your-deployment].vercel.app/sar-dashboard`

**Compatible Devices:**
- ✅ Mobile phones (recommended)
- ✅ Tablets
- ✅ Desktop computers

### Dashboard Sections

#### 1. Live SOS Sessions
- **Red background** for critical alerts
- Shows active emergencies
- Real-time updates
- Action buttons:
  - **Call**: Opens device dialer
  - **SMS**: Opens messaging app
  - **Acknowledge**: Mark as received
  - **Respond**: Change to responding status
  - **Resolve**: Close the session

#### 2. Live Help Requests
- **Blue/neutral background** for non-emergencies
- Shows active help requests
- Categories and descriptions
- Same action buttons as SOS

### Using Call/SMS Buttons

#### On Mobile Device (SAR Team in Field)
1. **Call Button:**
   - Tap green **"Call"** button
   - Phone app opens immediately
   - Number pre-filled (e.g., +61473054208)
   - Tap dial to call

2. **SMS Button:**
   - Tap blue **"SMS"** button
   - Messages app opens immediately
   - Number pre-filled
   - Type message and send

#### On Desktop Computer (SAR Coordinator)
1. **Call Button:**
   - Click green **"Call"** button
   - System shows app selection popup:
     - **Phone Link**: Routes call to your connected phone
     - **Microsoft Teams**: VoIP call
     - **Chrome/Edge**: Web-based calling (if configured)
   - Select your preferred app

2. **SMS Button:**
   - Click blue **"SMS"** button
   - Same app selection process
   - Choose SMS-capable app

**Note:** Desktop shows app selection because computers don't have native phone/messaging apps. This is normal behavior.

### Communication Logging

Every Call/SMS action is logged to Firebase:
```json
{
  "type": "call" or "sms",
  "timestamp": "2025-10-20T10:30:00Z",
  "senderId": "sar_web_team",
  "recipientPhone": "+61473054208",
  "recipientName": "John Smith",
  "status": "initiated"
}
```

**Logged Data:**
- Communication type (voice call or SMS)
- Timestamp
- SAR team member ID
- Recipient details
- Associated SOS/Help Request ID

### Status Updates

**SAR Team Actions:**
1. **Acknowledge**: "We received your alert"
2. **Respond**: "We're on our way"
3. **Arrive**: "We're at your location"
4. **Resolve**: "Situation handled"

**User Visibility:**
- Users see status updates in real-time
- Estimated arrival time (if provided)
- Assigned team information

---

## Troubleshooting

### Profile Issues

**Problem:** SOS/Help requests show "Anonymous User"

**Solution:**
1. Open app → Profile
2. Verify **Name** field is filled
3. Verify **Phone Number** has country code (+61...)
4. Tap **Save Changes**
5. Wait 5 seconds for sync
6. Send new SOS/Help request

**Problem:** Phone number not showing on dashboard

**Solution:**
1. Check Firebase Console → `users` collection
2. Find your user document (user_[timestamp])
3. Verify fields exist:
   - `phoneNumber`: "+61473054208"
   - `phone`: "+61473054208"
4. Update in app if missing

### SOS Issues

**Problem:** SOS not appearing on dashboard

**Solution:**
1. Check internet connection
2. Verify Firebase environment variables in Vercel:
   - `NEXT_PUBLIC_FIREBASE_API_KEY`
   - `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
   - `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
   - `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
   - `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
   - `NEXT_PUBLIC_FIREBASE_APP_ID`
3. Check Firestore rules allow read/write
4. Verify SOS session in Firebase Console → `sos_sessions`

**Problem:** Can't cancel SOS

**Solution:**
1. Force close app
2. Reopen app
3. Try cancel again
4. If still stuck, contact admin to manually update status

### Help Request Issues

**Problem:** "Send" button stays gray

**Solution:**
1. Make sure you selected a **main category** (e.g., Lost Pet)
2. Make sure you selected a **subcategory** (e.g., Lost Dog)
3. Both must be selected for button to activate
4. Button turns red when ready

**Problem:** Help request missing contact info

**Solution:**
1. This means profile enrichment failed
2. Update your profile (see Profile Issues above)
3. Send new help request
4. Check Firebase Console → `help_requests` → verify `userName`, `userPhone` fields

### Call/SMS Button Issues

**Problem:** "Failed to record SMS/Call transaction" error

**Solution:**
- **OLD VERSION**: Shows error popup
- **NEW VERSION** (deployed): SMS/Call opens immediately, logging happens in background
- Update to latest website deployment: `https://redping-website-n701686q1-alfredo-jr-romanas-projects.vercel.app`

**Problem:** Desktop shows "Select an app" popup

**Solution:**
- This is **normal behavior** on desktop
- Select **Phone Link** if you have Android phone connected
- Select **Microsoft Teams** for VoIP calling
- For production use, SAR teams should use **mobile devices**

**Problem:** No Call/SMS buttons visible

**Solution:**
1. Verify SOS/Help request has phone number
2. Check dashboard shows name (not "Anonymous")
3. Look for green "Call" and blue "SMS" buttons
4. If missing, profile enrichment failed (see Profile Issues)

### Website Errors (Can Ignore)

**WebSocket Connection Failed:**
```
WebSocket connection to 'wss://...socket.io' failed
```
- **Impact**: None - website uses Firestore real-time listeners instead
- **Why**: Vercel doesn't support persistent WebSocket connections
- **Solution**: No action needed, this is expected

**Manifest/Favicon Errors:**
```
manifest.json: 401
favicon.ico: 404
```
- **Impact**: Only affects "Add to Home Screen" and browser icon
- **Why**: These files not configured yet
- **Solution**: Can be added later if needed

### Firebase Console Access

**URL:** https://console.firebase.google.com/project/redping-a2e37

**Collections:**
- `users` - User profiles
- `sos_sessions` - Active/historical SOS alerts
- `help_requests` - Help request submissions
- `sar_teams` - SAR team information

**Checking Data:**
1. Navigate to Firestore Database
2. Select collection
3. Find document by ID
4. Verify fields are populated
5. Check timestamps for recent activity

---

## Best Practices

### For Users

1. **Complete your profile BEFORE any emergency**
2. **Test the app** in safe conditions (use Help Request for testing)
3. **Keep location services ON** for accurate GPS
4. **Keep app updated** to latest version
5. **Add emergency contacts** in your profile
6. **Verify phone number** has correct country code

### For SAR Teams

1. **Use mobile devices** for field operations (better Call/SMS integration)
2. **Keep dashboard open** during active operations
3. **Acknowledge alerts immediately** to reassure users
4. **Update status regularly** so users know help is coming
5. **Use Call before SMS** for urgent situations
6. **Log all communications** (automatic when using buttons)
7. **Close resolved sessions** to keep dashboard clean

### For Administrators

1. **Monitor Firebase usage** and quotas
2. **Review Firestore rules** for security
3. **Keep environment variables** updated in Vercel
4. **Check error logs** in Vercel dashboard
5. **Backup Firebase data** regularly
6. **Test deployments** before production release
7. **Clean up old test data** from Firebase collections

---

## System Architecture Overview

### Mobile App (Flutter)
```
User → Profile Setup → Firebase Auth + Firestore
     → SOS Activation → SOSService → Firestore (sos_sessions)
     → Help Request → HelpService → FirebaseHelpService → Firestore (help_requests)
```

### Web Dashboard (Next.js)
```
SAR Team → Dashboard → Firestore Listener → Real-time Updates
         → Call/SMS Buttons → tel:/sms: protocols → Native Apps
         → Status Updates → Firestore Write → App Notified
```

### Data Flow
```
App Profile → Firestore users/{userId}
SOS Alert → Firestore sos_sessions/{sosId} → Dashboard
Help Request → Firestore help_requests/{helpId} → Dashboard
Profile Enrichment → HelpService fetches users/{userId} → Adds to request
Call/SMS → Dashboard logs to communicationHistory → Audit trail
```

---

## Contact & Support

**Technical Issues:** Report to development team
**Emergency Issues:** Contact local emergency services (911, 000, etc.)
**Feature Requests:** Submit via feedback form

**Current Deployment:**
- Website: `https://redping-website-n701686q1-alfredo-jr-romanas-projects.vercel.app`
- Firebase Project: `redping-a2e37`
- App Version: 14v (Build date: 2025-10-20)

---

*Last Updated: October 20, 2025*
*Version: 1.0.0*
