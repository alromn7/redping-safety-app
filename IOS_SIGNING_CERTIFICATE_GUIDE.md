# iOS Signing Certificate Guide

## Configuration Summary

**Date Updated:** November 25, 2025  
**Bundle ID:** `com.redping.redping`  
**Display Name:** REDP!NG Safety  
**Signing Method:** Automatic (CODE_SIGN_STYLE = Automatic)

## Current Configuration

### Project Settings (project.pbxproj)

All build configurations now use:
- **Bundle Identifier:** `com.redping.redping`
- **Signing Style:** Automatic
- **Configurations:** Debug, Release, Profile

### Xcode Configuration Steps

#### 1. Open Project in Xcode
```bash
open ios/Runner.xcodeproj
```

#### 2. Verify Team & Signing
1. Select **Runner** target in the project navigator
2. Go to **Signing & Capabilities** tab
3. Ensure **"Automatically manage signing"** is checked
4. Select your **Team** from dropdown (Apple Developer account)
5. Verify **Bundle Identifier** shows `com.redping.redping`

#### 3. Check Provisioning Profiles
Navigate to **Xcode → Settings → Accounts**:
- Select your Apple ID
- Click **Manage Certificates**
- Verify certificates are valid (not expired)
- Look for:
  - **Apple Development** certificate (for Debug builds)
  - **Apple Distribution** certificate (for Release/App Store)

#### 4. Verify Certificate Expiration
```bash
# List all certificates in keychain
security find-identity -v -p codesigning

# Check certificate expiration
security find-certificate -c "Apple Development" -p | openssl x509 -text | grep "Not After"
security find-certificate -c "Apple Distribution" -p | openssl x509 -text | grep "Not After"
```

## App Store Connect Setup

### Requirements for Production

1. **Apple Developer Program Membership**
   - Annual fee: $99 USD
   - Required for App Store distribution
   - Provides signing certificates and provisioning profiles

2. **App Store Connect Account**
   - Create app listing at: https://appstoreconnect.apple.com
   - Set Bundle ID to: `com.redping.redping`
   - App Name: "REDP!NG Safety"

3. **Provisioning Profiles**
   - **Development:** For testing on physical devices
   - **Ad Hoc:** For internal testing (TestFlight beta)
   - **App Store:** For final production release

### Creating Certificates

#### Development Certificate
```bash
# Generate Certificate Signing Request (CSR)
# Xcode → Preferences → Accounts → Manage Certificates → + → Apple Development

# Or via command line:
openssl req -new -newkey rsa:2048 -nodes -keyout ios_development.key -out ios_development.csr
```

#### Distribution Certificate
```bash
# Generate via Xcode:
# Xcode → Preferences → Accounts → Manage Certificates → + → Apple Distribution

# Or manually at:
# https://developer.apple.com/account/resources/certificates
```

## Troubleshooting

### Common Issues

#### "No Signing Certificate Found"
**Solution:**
1. Go to Xcode → Settings → Accounts
2. Click **Download Manual Profiles**
3. Restart Xcode
4. Clean build folder: `flutter clean`

#### "Bundle ID Already Exists"
**Solution:**
1. Log into https://developer.apple.com/account
2. Go to **Identifiers**
3. Check if `com.redping.redping` exists
4. If not, create new App ID with this identifier

#### "Provisioning Profile Expired"
**Solution:**
1. Delete expired profile: `rm ~/Library/MobileDevice/Provisioning\ Profiles/*`
2. Xcode → Settings → Accounts → Download Manual Profiles
3. Rebuild project

#### "Code Signing Error"
**Solution:**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean Flutter build
cd ios
flutter clean
pod deintegrate
pod install
cd ..

# Rebuild
flutter build ios --release
```

## Testing Configuration

### Validate Bundle ID Match
```bash
# Check Android bundle ID
grep "applicationId" android/app/build.gradle.kts

# Check iOS bundle ID (should match)
grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

### Build iOS for Testing
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for iOS simulator
flutter build ios --debug --simulator

# Build for iOS device (requires signing)
flutter build ios --release

# Or run directly on connected device
flutter run --release
```

## App Store Submission Checklist

### Pre-submission Requirements

- [ ] Valid Apple Developer account ($99/year)
- [ ] App created in App Store Connect
- [ ] Bundle ID: `com.redping.redping` registered
- [ ] App name: "REDP!NG Safety" reserved
- [ ] Screenshots prepared (6.7", 6.5", 5.5" displays)
- [ ] App icon (1024x1024px) uploaded
- [ ] Privacy policy URL provided
- [ ] App description and keywords finalized
- [ ] Distribution certificate valid
- [ ] App Store provisioning profile created
- [ ] All required permissions documented (Location, Motion, Camera, etc.)

### Build Archive for Submission
```bash
# 1. Update version in pubspec.yaml
# version: 1.0.1+3

# 2. Build iOS archive
flutter build ipa --release

# 3. Validate archive
xcrun altool --validate-app -f build/ios/ipa/*.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD

# 4. Upload to App Store Connect
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD

# Or use Xcode:
# Open ios/Runner.xcworkspace
# Product → Archive
# Distribute App → App Store Connect
```

## Deep Linking Configuration

The iOS app now supports deep linking via the `redping://` URL scheme.

### Test Deep Links
```bash
# On simulator
xcrun simctl openurl booted "redping://emergency/sos?lat=-33.8688&lng=151.2093"

# On device (via Safari or Notes app)
redping://profile
redping://emergency/create
redping://subscription/upgrade
```

### Universal Links Setup (Optional)

For production, consider adding Universal Links:

1. Add Associated Domains capability in Xcode
2. Create `apple-app-site-association` file
3. Host at: `https://redping.app/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.redping.redping",
        "paths": ["/emergency/*", "/profile", "/subscription/*"]
      }
    ]
  }
}
```

## Security Best Practices

### Certificate Management

1. **Never commit certificates to Git**
   - Already in `.gitignore`: `*.cer`, `*.p12`, `*.mobileprovision`

2. **Use Automatic Signing for Development**
   - Xcode manages certificates automatically
   - Reduces manual configuration errors

3. **Manual Signing for CI/CD**
   - Store certificates in secure CI secrets
   - Use Fastlane Match for team certificate sharing
   - Rotate certificates before expiration (yearly)

4. **Keychain Access**
   - Certificates stored in: `Keychain Access.app → My Certificates`
   - Private keys must remain secure
   - Back up certificates before reinstalling macOS

## Next Steps

1. ✅ Bundle ID updated to `com.redping.redping`
2. ✅ Display name changed to "REDP!NG Safety"
3. ✅ URL scheme `redping://` added
4. ✅ Info.plist permissions configured
5. ⏳ **Test build on macOS with Xcode**
6. ⏳ Create App Store Connect listing
7. ⏳ Generate distribution certificates
8. ⏳ Submit for TestFlight beta testing
9. ⏳ Final App Store submission

## Support Resources

- **Apple Developer Portal:** https://developer.apple.com/account
- **App Store Connect:** https://appstoreconnect.apple.com
- **Certificate Management:** https://developer.apple.com/account/resources/certificates
- **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **Flutter iOS Deployment:** https://docs.flutter.dev/deployment/ios

---

**Last Updated:** November 25, 2025  
**Status:** Configuration complete, ready for Xcode testing
