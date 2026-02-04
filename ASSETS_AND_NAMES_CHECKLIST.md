# Assets & Names Checklist (Emergency vs SAR)

## Display Names
- Emergency (iOS `CFBundleDisplayName`, Android `app_name`):
  - Proposed: "RedPing Emergency"
- SAR (iOS `CFBundleDisplayName`, Android `app_name`):
  - Proposed: "RedPing SAR"

## Icons
- Android: `android/app/src/main/res/mipmap-*` per density
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- Guidelines: high-contrast, consistent brand; distinct color accents for Emergency vs SAR

## Splash / Launch Screen
- Android: `launch_background.xml` / drawable assets
- iOS: `LaunchScreen.storyboard` / images in Assets
- Keep lightweight and brand-consistent

## Strings & Localization
- Android: `res/values/strings.xml` for `app_name`
- iOS: `Info.plist` for `CFBundleDisplayName`
- Localize strings if needed (EN-first, expand later)

## Asset Tasks
- [ ] Confirm final display names
- [ ] Provide icon sets for both apps
- [ ] Provide splash assets for both apps
- [ ] Update Android `strings.xml` and iOS `Info.plist`
- [ ] Verify scaling and dark/light variants

## Notes
- Keep Emergency visuals safety-oriented; SAR visuals operational/neutral.
