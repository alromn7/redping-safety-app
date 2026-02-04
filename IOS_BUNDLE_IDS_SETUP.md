# iOS Bundle IDs Setup for RedPing Apps

This workspace uses separate bundle identifiers per app:

- Emergency: `com.redping.emergency`
- SAR: `com.redping.sar`

Both are configured directly in the Xcode project files for Debug/Release/Profile build configurations and surfaced via `Info.plist` using `$(PRODUCT_BUNDLE_IDENTIFIER)`.

Paths:
- Emergency iOS project: redping_emergency_app/ios/Runner.xcodeproj/project.pbxproj
- SAR iOS project: redping_sar_app/ios/Runner.xcodeproj/project.pbxproj

Display names in `Info.plist` are set to:
- Emergency: `RedPing Emergency`
- SAR: `RedPing SAR`

If you need to change IDs:
1. Open each app’s `Runner.xcodeproj/project.pbxproj`.
2. Update `PRODUCT_BUNDLE_IDENTIFIER` for `Runner` target in `Debug`, `Release`, and `Profile`.
3. Ensure tests target identifiers (RunnerTests) remain distinct.
4. Keep `CFBundleIdentifier` in `Info.plist` as `$(PRODUCT_BUNDLE_IDENTIFIER)`.

After changes, run:
```
flutter clean
flutter pub get
flutter build ios
```
