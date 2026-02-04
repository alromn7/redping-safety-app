# Add Release SHA-1 to Firebase Console

## Current Release SHA-1 (needs to be added)
```
40:6F:C2:89:D3:79:CD:0A:22:D7:32:9A:60:7A:BC:7E:91:73:3B:8A
```

## Steps to Add SHA-1

1. **Go to Firebase Console**
   - URL: https://console.firebase.google.com/project/redping-a2e37/settings/general
   
2. **Scroll to "Your apps" → Android app**
   - Package: `com.redping.redping`
   
3. **Click "Add fingerprint"**
   - Paste: `40:6F:C2:89:D3:79:CD:0A:22:D7:32:9A:60:7A:BC:7E:91:73:3B:8A`
   - Click Save

4. **Download Updated Config**
   - Click "Download google-services.json"
   - Save it to: `android/app/google-services.json` (replace existing)

5. **Rebuild App**
   ```powershell
   flutter clean
   flutter build apk --release
   adb uninstall com.redping.redping
   adb install build\app\outputs\flutter-apk\app-release.apk
   ```

## After Adding SHA-1

The new `google-services.json` will contain an additional OAuth client entry like:
```json
{
  "client_id": "...",
  "client_type": 1,
  "android_info": {
    "package_name": "com.redping.redping",
    "certificate_hash": "406fc289d379cd0a22d7329a607abc7e91733b8a"
  }
}
```

## Verification

Test Google Sign-In - it should work without the "not registered" error.
