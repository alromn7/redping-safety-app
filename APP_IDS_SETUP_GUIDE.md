# App IDs Setup — Emergency and SAR (Planning)

## Android (applicationId)
- Emergency: `com.redping.emergency`
- SAR: `com.redping.sar`

Update `app/build.gradle.kts` in each app:
```kotlin
android {
  defaultConfig {
    applicationId = "com.redping.emergency" // or com.redping.sar
  }
  // add productFlavors if needed
}
```

## iOS (bundle identifiers)
- Emergency: `com.redping.emergency`
- SAR: `com.redping.sar`

Update `Runner.xcodeproj` target bundle identifiers or `Info.plist` display names. Ensure separate provisioning/signing.

## Assets & Names
- App name strings and icons distinct per app.
- Splash screens tailored to each product.

## Firebase Configs
- Option A: single project using separate collections.
- Option B: separate `google-services.json` / `GoogleService-Info.plist` per app.

## Next Steps
- Confirm IDs with your store listings.
- Prepare signing keys and CI secrets per app.
