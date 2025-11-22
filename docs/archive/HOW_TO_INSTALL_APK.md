# How to Install APK on Android Phone

**Quick Guide** - Updated: October 19, 2025

---

## 📱 Method 1: USB Cable Transfer (Recommended)

### Step 1: Enable Developer Options & USB Debugging

On your Android phone:

1. **Open Settings**
2. **Go to "About phone"** (or "About device")
3. **Find "Build number"** (usually at the bottom)
4. **Tap "Build number" 7 times** rapidly
   - You'll see: "You are now a developer!"
5. **Go back to Settings**
6. **Open "Developer options"** (usually under "System" or "Additional settings")
7. **Enable "USB debugging"**
   - Toggle it ON
   - Confirm the popup

---

### Step 2: Connect Phone to PC

1. **Connect your phone** to PC using USB cable
2. **On your phone**, you'll see a popup: "Allow USB debugging?"
   - Check "Always allow from this computer"
   - Tap **"Allow"** or **"OK"**
3. **Swipe down** notification panel on phone
4. **Tap the USB notification**
5. **Select "File transfer" (MTP)** or "Transfer files"

---

### Step 3: Copy APK to Phone

On your PC:

```powershell
# Method A: Using File Explorer (Easiest)
# 1. Open File Explorer
# 2. Navigate to your phone (should appear in "This PC")
# 3. Open "Internal storage" or "Phone"
# 4. Create folder "APK" or use "Download" folder
# 5. Copy the APK file

# Your APK location:
C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\app-release.apk

# Copy to phone's Download folder
```

**Using File Explorer GUI:**
1. Press `Win + E` to open File Explorer
2. Navigate to: `C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\`
3. Find `app-release.apk` (66.6 MB)
4. Right-click → **Copy**
5. In left sidebar, find your phone name (e.g., "Galaxy S23")
6. Open: **Internal storage → Download**
7. Right-click → **Paste**

---

### Step 4: Install APK on Phone

On your Android phone:

1. **Open "Files" app** (or "My Files")
   - Or use "Downloads" app
2. **Navigate to Download folder**
3. **Tap on `app-release.apk`**
4. **You may see**: "Install unknown apps"
   - Tap **"Settings"**
   - Enable **"Allow from this source"** (for Files app)
   - Go back
5. **Tap the APK again**
6. **Tap "Install"**
7. **Wait for installation** (few seconds)
8. **Tap "Open"** to launch the app
   - Or tap "Done" and find app in app drawer

---

## 📱 Method 2: Google Drive / Cloud Upload

### Step 1: Upload APK to Google Drive

On your PC:

1. **Go to**: https://drive.google.com
2. **Click "New" → "File upload"**
3. **Navigate to**: `C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\`
4. **Select**: `app-release.apk`
5. **Wait for upload** (may take 1-2 minutes for 66.6 MB)

---

### Step 2: Download on Phone

On your Android phone:

1. **Open Google Drive app**
2. **Find `app-release.apk`** file
3. **Tap the file**
4. **Tap the 3 dots menu** (⋮)
5. **Select "Download"**
6. **Wait for download**
7. **Notification will appear**: "Download complete"
8. **Tap notification** or go to Downloads

---

### Step 3: Install APK

1. **Open Downloads** (swipe down notification, tap "Open")
   - Or open "Files" app → Downloads
2. **Tap `app-release.apk`**
3. **Allow installation from Google Drive** if prompted
4. **Tap "Install"**
5. **Tap "Open"** when done

---

## 📱 Method 3: ADB Command (Advanced)

### Prerequisites:
- USB Debugging enabled (see Method 1, Step 1)
- Phone connected to PC via USB

On your PC PowerShell:

```powershell
# Check if phone is connected
adb devices
# Should show your device ID

# If not recognized, you may need to install ADB:
# Download: https://developer.android.com/studio/releases/platform-tools
# Or install via winget:
winget install Google.PlatformTools

# Install APK directly via ADB
adb install "C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\app-release.apk"

# If app is already installed, use -r to reinstall:
adb install -r "C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\app-release.apk"

# Success message: "Success"
```

---

## 📱 Method 4: Email (Simple but Slow)

### On Your PC:

1. **Open Gmail** (or any email)
2. **Compose new email** to yourself
3. **Attach**: `app-release.apk` (66.6 MB)
   - Location: `C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\app-release.apk`
4. **Send email**

### On Your Phone:

1. **Open Gmail** on phone
2. **Open the email** you sent
3. **Tap the APK attachment**
4. **Download the file**
5. **Tap notification** → "Open"
6. **Allow installation**
7. **Install**

⚠️ **Note**: Gmail has 25 MB attachment limit. APK is 66.6 MB, so use Google Drive link instead.

---

## ⚠️ Important: Allow Unknown Sources

### Android 8+ (Oreo and newer):

When you try to install APK, Android will ask:
- **"Do you want to allow [App Name] to install unknown apps?"**
- Tap **"Settings"**
- Enable **"Allow from this source"**
- This is per-app permission (safer)

### Android 7 and older:

1. **Settings → Security**
2. **Enable "Unknown sources"**
3. **Confirm the warning**

---

## 🎯 Recommended Method

**For you, I recommend Method 1 (USB Cable):**

✅ **Fastest** - Direct transfer  
✅ **Most reliable** - No internet needed  
✅ **Easiest** - Just copy and paste  

---

## 📋 Quick Step-by-Step (USB Method)

```
1. Enable USB Debugging on phone:
   Settings → About phone → Tap "Build number" 7 times
   Settings → Developer options → Enable USB debugging

2. Connect phone to PC with USB cable
   Allow USB debugging popup on phone

3. Copy APK:
   PC: C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\app-release.apk
   To: Phone → Internal storage → Download

4. Install on phone:
   Open Files app → Download → Tap app-release.apk → Install

5. Done! App installed.
```

---

## 🔍 After Installation - Testing

### Step 1: Launch App
- Find "RedPing" app in app drawer
- Tap to open

### Step 2: Grant Permissions
The app will ask for:
- ✅ **Location** - Allow (Required for SOS)
- ✅ **Phone/SMS** - Allow (For emergency calls)
- ✅ **Notifications** - Allow (For SOS alerts)
- ✅ **Contacts** - Allow (For emergency contacts)

### Step 3: Login/Register
- Create account or login
- Add your phone number to profile

### Step 4: Test SOS
1. **Add phone number** in profile settings
2. **Activate SOS** 
3. **Check**:
   - No crash ✅ (Android 14+ fix applied)
   - Notification appears ✅
   - Foreground service runs ✅
   - Location tracking works ✅

### Step 5: Verify in Firebase
- Go to: https://console.firebase.google.com/project/redping-a2e37/firestore
- Check `sos_sessions` collection
- Verify your session has phone number fields

### Step 6: Check Website
- Visit: https://redping-website-4hof1yrwf-alfredo-jr-romanas-projects.vercel.app/sar-dashboard
- See if your SOS appears
- Check if Call/SMS buttons show

---

## 🆘 Troubleshooting

### Issue: Can't find APK file
**Solution**: Make sure you built the release APK:
```powershell
cd C:\flutterapps\redping_14v
flutter build apk --release
```

### Issue: Phone not recognized by PC
**Solution**:
1. Try different USB cable
2. Enable USB debugging again
3. Try "File transfer" mode in USB options
4. Install phone manufacturer's USB drivers

### Issue: "App not installed" error
**Solution**:
1. Uninstall old version first (if exists)
2. Clear cache: Settings → Apps → RedPing → Clear cache
3. Try reinstalling

### Issue: "Parse error" when installing
**Solution**:
- APK may be corrupted during transfer
- Re-copy the APK file
- Or rebuild: `flutter build apk --release`

### Issue: App crashes on launch
**Solution**:
1. Check Android version (minimum supported?)
2. Check app permissions
3. Check logcat: `adb logcat | findstr "flutter"`

---

## ✅ Success Checklist

After installation:
- [ ] App icon appears in app drawer
- [ ] App launches without crash
- [ ] Permissions granted
- [ ] Can login/register
- [ ] Can add phone number
- [ ] SOS button works
- [ ] No crash after sending SOS (Android 14+ fix)
- [ ] Notification appears during SOS
- [ ] Location tracking works

---

## 📞 Need Help?

If you get stuck:
1. Check which method you're using
2. Note the exact error message
3. Check Android version (Settings → About phone)
4. Let me know and I can help troubleshoot!

---

**APK Location:**  
`C:\flutterapps\redping_14v\build\app\outputs\flutter-apk\app-release.apk`

**APK Size:** 66.6 MB  
**Android Version:** 14+ (with foreground service fix)  
**Ready for Testing:** ✅ YES

**Good luck with testing!** 🚀📱
