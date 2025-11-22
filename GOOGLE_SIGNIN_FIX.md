# Google Sign-In Configuration Fix

## Problem
Google Sign-In is failing with error:
```
This android application is not registered to use OAuth2.0, please confirm the package name and SHA-1 certificate fingerprint match what you registered in Google Developer Console.
```

## Root Cause
The release APK is signed with a different certificate than what's registered in Firebase Console. Currently only the debug certificate is registered.

## Current Configuration
- **Package Name**: `com.redping.redping`
- **Debug SHA-1**: `DF:30:43:A5:F6:29:5B:ED:6C:F3:B7:B2:75:3D:C5:D9:76:26:B8:8A` ✅ (already registered)
- **Release SHA-1**: `5C:E2:B5:ED:EF:F4:7F:BC:08:15:E3:22:79:FE:84:AD:97:8C:01:61` ❌ (needs to be added)

## Solution Steps

### Option 1: Add Release SHA-1 to Firebase (Recommended)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select project: **redping-a2e37**

2. **Navigate to Project Settings**
   - Click the gear icon (⚙️) next to "Project Overview"
   - Select "Project settings"

3. **Add SHA-1 Fingerprint**
   - Scroll down to "Your apps" section
   - Find the Android app: **com.redping.redping**
   - Under "SHA certificate fingerprints", click **Add fingerprint**
   - Paste: `5CE2B5EDEFF47FBC0815E32279FE84AD978C0161`
   - Click **Save**

4. **Download Updated google-services.json**
   - After adding the fingerprint, download the updated `google-services.json`
   - Replace `android/app/google-services.json` with the new file

5. **Rebuild and Install**
   ```powershell
   flutter build apk --release
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```

6. **Test Google Sign-In**
   - Open the app
   - Try signing in with Google
   - Should work without errors

### Option 2: Configure Google Cloud Console OAuth (If Firebase method doesn't work)

1. **Open Google Cloud Console**
   - Go to: https://console.cloud.google.com/
   - Select project: **redping-a2e37**

2. **Navigate to APIs & Services > Credentials**
   - Click on "APIs & Services" in the left menu
   - Click "Credentials"

3. **Find or Create OAuth 2.0 Client ID**
   - Look for existing Android OAuth client
   - If exists, edit it; otherwise create new "OAuth 2.0 Client ID"
   - Application type: **Android**

4. **Add SHA-1 Fingerprint**
   - Package name: `com.redping.redping`
   - SHA-1 certificate fingerprint: `5CE2B5EDEFF47FBC0815E32279FE84AD978C0161`
   - Click **Save**

5. **Rebuild and Test** (same as Option 1, steps 5-6)

## Verification

After adding the SHA-1 and rebuilding, verify the configuration:

```powershell
# Check installed app signature
adb shell pm dump com.redping.redping | Select-String "signatures"

# Check logcat for errors (should not show OAuth2 registration error)
adb logcat -d | Select-String "Auth.*Server returned error"
```

## Notes

- **Debug builds**: Use debug SHA-1 (DF:30:43:A5:F6:29:5B:ED:6C:F3:B7:B2:75:3D:C5:D9:76:26:B8:8A)
- **Release builds**: Use release SHA-1 (5C:E2:B5:ED:EF:F4:7F:BC:08:15:E3:22:79:FE:84:AD:97:8C:01:61)
- **Both SHA-1 fingerprints should be added to Firebase** to support both debug and release builds

## Current Signing Configuration

The app is using a **release keystore** with these details:
- **Certificate DN**: CN=REDPING Safety, OU=Development, O=REDPING Safety, L=San Francisco, ST=CA, C=US
- **Keystore location**: Check `android/key.properties` or using debug keystore as fallback
- **SHA-256**: b0fed69a6e8c247b202b674a5e32345dcb610ec5d23719a1b870b7f5e21cd5bb

## Commands Reference

```powershell
# Get SHA-1 from debug keystore
keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Get SHA-1 from APK
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```
