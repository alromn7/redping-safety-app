# Real-time SAR Dashboard Sync - Quick Test Guide

## 🚀 Quick Testing Steps

### Test Real-time Sync (2 devices needed):

#### Setup:
1. **Mobile Device**: Open RedPing app, login
2. **Computer**: Open website SAR dashboard in browser

#### Test Flow:

**Step 1: Activate SOS**
- Mobile: Press SOS button → Wait 10 seconds
- Expected: SOS activates, status shows "Active"
- Mobile: Status indicator appears below "EMERGENCY SOS" title

**Step 2: SAR Acknowledges**
- Computer: SAR dashboard shows new alert
- Computer: Click "Acknowledge" button
- Mobile: Watch status indicator
- ✅ Expected: Within 1-2 seconds, shows "SAR Notified" (orange)
- ✅ Expected: SnackBar notification: "🚨 SAR Team has acknowledged your emergency"

**Step 3: SAR En Route**
- Computer: Click "En Route" button
- Mobile: Watch status indicator
- ✅ Expected: Within 1-2 seconds, shows "Help En Route" (blue)
- ✅ Expected: SnackBar: "🚁 SAR Team is en route to your location"

**Step 4: SAR On Scene**
- Computer: Click "On Scene" button
- Mobile: Watch status indicator
- ✅ Expected: Within 1-2 seconds, shows "Help On Scene" (green)
- ✅ Expected: SnackBar: "✅ SAR Team has arrived at your location"

**Step 5: Responder Assignment**
- Computer: Assign specific SAR member
- Mobile: Watch status indicator
- ✅ Expected: Shows "Responder Assigned • [Name]"
- ✅ Expected: SnackBar: "👤 Responder assigned: [Name]"

**Step 6: Resolve**
- Computer: Click "Resolve" button
- Mobile: Watch app
- ✅ Expected: Session ends gracefully

## 🎯 What to Look For

### Status Indicator Colors:
- 🔴 **Red** = Active (no SAR response yet)
- 🟠 **Orange** = SAR Notified / Acknowledged
- 🔵 **Blue** = Help En Route / Responder Assigned
- 🟢 **Green** = Help On Scene / Completed

### Notification Behavior:
- Appears at bottom of screen
- Colored background matches status
- Auto-dismisses after 4-5 seconds
- Clear, actionable message

### Performance Checks:
- ⚡ Updates appear within **1-2 seconds**
- 🔋 No excessive battery drain
- 📱 No UI freezing or lag
- 🌐 Works even with slow network

## 🐛 Troubleshooting

### "No status indicator visible"
→ Make sure SOS is actually **active**, not just countdown
→ Status indicator only appears when session is active

### "Updates take 30+ seconds"
→ Check Firebase connection (requires internet)
→ Check Firestore security rules allow real-time reads
→ Restart app and try again

### "No notifications shown"
→ Notifications are disabled in app settings
→ Check if SnackBar overlaps with existing dialog

### "Status stays 'Active' even after SAR clicks"
→ Check website actually saved the status change
→ Check Firebase Console for `sos_alerts` collection updates
→ Check app logs for "Real-time update from website SAR dashboard"

## 📊 Debug Logging

### Look for these logs in console:

**When SOS starts:**
```
SOS Page: Started real-time Firebase listener for session [sessionId]
```

**When website updates status:**
```
SOS Page: Real-time update from website SAR dashboard
```

**When session ends:**
```
SOS Page: Stopped Firebase listener
```

**If errors occur:**
```
SOS Page: Error parsing Firebase session update - [error]
SOS Page: Firebase listener error - [error]
```

## ✅ Success Criteria

All these should work:
- [x] Status indicator shows immediately when SOS active
- [x] SAR acknowledgment appears in < 2 seconds
- [x] Each status change shows notification
- [x] Colors match status severity
- [x] No errors in console
- [x] No battery drain warnings
- [x] Works consistently across multiple tests

## 🔄 Repeat Testing

Run the test flow **3 times** to ensure:
1. First activation works
2. Subsequent activations work
3. No memory leaks or degradation

## 📞 Production Validation

Before shipping to users:
- [ ] Test with real SAR team member
- [ ] Test on slow 3G network
- [ ] Test with airplane mode toggle
- [ ] Test with app in background
- [ ] Test with phone locked
- [ ] Verify Firebase costs are acceptable

---

**Expected Result**: Real-time bidirectional sync between mobile app and website SAR dashboard with sub-2-second latency for all status updates.
