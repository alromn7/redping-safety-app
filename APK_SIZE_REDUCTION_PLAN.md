# APK Size Reduction Plan: 97MB → 50MB

**Current Size:** 96.96 MB  
**Target Size:** 50 MB  
**Reduction Needed:** 47 MB (48% reduction)  
**Priority:** HIGH - Google Play recommends <100MB, ideal <50MB

---

## 🎯 Quick Wins (Immediate Impact)

### 1. Enable App Bundle (AAB) Instead of APK ⚡
**Potential Savings:** 20-40%

**Why:** AAB allows Google Play to deliver optimized APKs per device (splits by architecture, screen density, language)

**Action:**
```powershell
# Build AAB instead of APK
flutter build appbundle --release

# Result: Users download only what their device needs
# arm64-v8a devices get ~30-40MB instead of 97MB
```

**Implementation:**
- Upload AAB to Play Store (not APK)
- Google Play handles device-specific optimization
- No code changes needed

**Expected Result:** 97MB → 40-50MB for end users

---

### 2. Remove Unused Dependencies 📦
**Potential Savings:** 10-15 MB

**Current Heavy Dependencies:**
```yaml
# Check which packages are largest
flutter_stripe: ^11.5.0              # ~8-10 MB (native SDKs)
firebase_crashlytics: ^4.1.3         # ~3-5 MB
mobile_scanner: ^5.0.0               # ~2-3 MB (ML Kit)
speech_to_text: ^7.0.0               # ~2-3 MB
flutter_tts: ^4.2.0                  # ~2-3 MB
printing: ^5.13.0                    # ~3-4 MB (PDF rendering)
pdf: ^3.11.0                         # ~2-3 MB
```

**Actions:**
1. **Remove PDF generation** (if not actively used):
   - Remove `printing: ^5.13.0`
   - Remove `pdf: ^3.11.0`
   - **Savings: 5-7 MB**

2. **Lazy-load Stripe SDK:**
   - Load only when user accesses subscription page
   - **Savings: 3-5 MB**

3. **Remove unused Firebase features:**
   ```yaml
   # If not using Data Connect, remove:
   firebase_data_connect: ^0.1.5     # ~2 MB
   ```

4. **Check for duplicate/unused packages:**
   ```powershell
   flutter pub deps | Select-String "transitive"
   ```

---

### 3. Compress Native Libraries 🗜️
**Potential Savings:** 8-12 MB

**Action - Add to `android/app/build.gradle`:**
```gradle
android {
    buildTypes {
        release {
            // Existing config...
            
            // Enable library compression
            ndk {
                abiFilters 'arm64-v8a', 'armeabi-v7a'  // Remove x86 if not needed
            }
            
            // Enable resource shrinking
            shrinkResources true
            minifyEnabled true
        }
    }
    
    // Compress native libraries
    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}
```

**Result:** Native .so files compressed in APK

---

### 4. Enable R8 Full Mode (Aggressive Optimization) 🚀
**Potential Savings:** 3-5 MB

**Action - Add to `gradle.properties`:**
```properties
# Enable R8 full mode
android.enableR8.fullMode=true

# Additional optimizations
org.gradle.jvmargs=-Xmx4096m -XX:+UseParallelGC
android.enableDexingArtifactTransform.desugaring=true
```

**Update ProGuard rules for aggressive shrinking:**
```proguard
# Add to proguard-rules.pro
-optimizationpasses 5
-repackageclasses ''
-allowaccessmodification
-flattenpackagehierarchy
```

---

### 5. Optimize Images & Assets 🖼️
**Potential Savings:** 2-5 MB

**Current Assets:**
```
assets/images/REDP!NG.png
assets/images/REDP!NGtrans.png
assets/images/RedPing logo.png
assets/sounds/
assets/docs/
```

**Actions:**
1. **Compress PNG images:**
   ```powershell
   # Install pngquant
   # Compress all PNGs
   pngquant --quality 65-80 assets/images/*.png --ext .png --force
   ```

2. **Convert to WebP** (better compression):
   ```powershell
   # Convert PNG to WebP
   cwebp -q 80 assets/images/REDP!NG.png -o assets/images/REDP!NG.webp
   ```

3. **Remove unused assets:**
   - Check if all files in `assets/docs/`, `assets/sounds/` are needed
   - Remove debug/test files

4. **Optimize app icon:**
   - Current launcher icon might be high-res
   - Ensure icon is optimized for Android (512x512 max)

---

## 📊 Medium-Term Optimizations

### 6. Split APKs by ABI Architecture
**Potential Savings:** 30-35 MB per split

**Action - Update `android/app/build.gradle`:**
```gradle
android {
    splits {
        abi {
            enable true
            reset()
            include 'arm64-v8a', 'armeabi-v7a'  // Modern devices only
            universalApk false  // Don't create fat APK
        }
    }
}
```

**Result:**
- arm64-v8a APK: ~35-40 MB (64-bit devices, most modern phones)
- armeabi-v7a APK: ~35-40 MB (32-bit devices, older phones)
- No universal APK

**Note:** This works with direct APK distribution, but AAB does this automatically

---

### 7. Font Subsetting (Tree-Shaking)
**Potential Savings:** 1-2 MB

**Already enabled** (from build output):
```
Font asset "CupertinoIcons.ttf" was tree-shaken, reducing from 257KB to 848 bytes (99.7%)
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing from 1.6MB to 49KB (97.0%)
```

**Verify enabled in `pubspec.yaml`:**
```yaml
flutter:
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
  
  # Enable tree-shaking (default, but verify)
  uses-material-design: true
```

---

### 8. Deferred Loading / Code Splitting
**Potential Savings:** 5-10 MB

**Strategy:** Load heavy features on-demand

**Example - Lazy load Stripe:**
```dart
// Don't import at top level
// import 'package:flutter_stripe/flutter_stripe.dart';

// Load only when needed
Future<void> initializeStripe() async {
  final stripe = await import('package:flutter_stripe/flutter_stripe.dart');
  await stripe.Stripe.instance.initialize(...);
}
```

**Features to defer:**
- Payment processing (Stripe)
- PDF generation
- Advanced AI features
- Rarely-used screens

---

### 9. Remove Debug/Development Code
**Potential Savings:** 1-2 MB

**Check for:**
- Debug print statements
- Development-only imports
- Test data/fixtures
- Unused example code

**Add to ProGuard:**
```proguard
# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
```

---

## 🔧 Advanced Optimizations

### 10. Analyze APK Contents
**Action:**
```powershell
# Build APK
flutter build apk --release --analyze-size

# Or use Android Studio APK Analyzer
# Build > Analyze APK > Select app-release.apk
```

**Look for:**
- Largest .so files (native libraries)
- Largest .dex files (Dart/Java code)
- Asset sizes
- Resource duplicates

---

### 11. Consider Dynamic Feature Modules
**Potential Savings:** 15-25 MB (delivered on-demand)

**Strategy:** Split app into modules

**Core Module (~40 MB):**
- SOS alerts
- Location tracking
- Emergency contacts
- Basic UI

**Optional Modules (downloaded on-demand):**
- **Gadgets Module (~8 MB):** Bluetooth, QR scanning
- **SAR Module (~5 MB):** SAR team features
- **Analytics Module (~3 MB):** Advanced reporting
- **AI Module (~10 MB):** AI safety assistant

**Implementation:**
```yaml
# In pubspec.yaml
flutter:
  deferred-components:
    - name: gadgets
      libraries:
        - package:redping/features/gadgets
    - name: sar_dashboard
      libraries:
        - package:redping/features/sar
```

---

### 12. Native Library Optimization
**Check current libraries:**
```powershell
# Extract APK
Expand-Archive build\app\outputs\flutter-apk\app-release.apk -DestinationPath temp_apk

# List .so files
Get-ChildItem -Recurse temp_apk\lib -Filter *.so | 
  Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB,2)}} | 
  Sort-Object 'Size(MB)' -Descending
```

**Likely culprits:**
- libflutter.so (~20-25 MB)
- Stripe native libs (~8-10 MB)
- Firebase libs (~5-8 MB)
- ML Kit (from mobile_scanner) (~3-5 MB)

**Actions:**
- Remove unused ABIs (x86, x86_64 if not needed)
- Use AAB for automatic optimization
- Consider Flutter's `--split-debug-info` for smaller binaries

---

## 📋 Implementation Checklist

### Phase 1: Immediate (Today) - Target: 60-70 MB
- [ ] Build AAB instead of APK
- [ ] Enable ABI splits
- [ ] Add library compression
- [ ] Enable R8 full mode
- [ ] Compress image assets
- [ ] Remove unused packages (PDF, Data Connect)

**Estimated result:** 97 MB → 60-70 MB

### Phase 2: Short-term (This week) - Target: 50-55 MB
- [ ] Analyze APK with Android Studio
- [ ] Implement deferred loading for Stripe
- [ ] Optimize native libraries
- [ ] Remove debug code
- [ ] Font subsetting verification

**Estimated result:** 60 MB → 50-55 MB

### Phase 3: Medium-term (Next sprint) - Target: <50 MB
- [ ] Dynamic feature modules
- [ ] Code splitting for heavy features
- [ ] Further dependency optimization
- [ ] Asset optimization (WebP conversion)

**Estimated result:** 50 MB → 40-45 MB

---

## 🎯 Quick Start: Execute Phase 1 Now

### Step-by-step commands:

```powershell
# 1. Remove unused packages
# Edit pubspec.yaml - remove:
# - printing: ^5.13.0
# - pdf: ^3.11.0
# - firebase_data_connect: ^0.1.5 (if not used)

flutter pub get

# 2. Update android/app/build.gradle
# Add compression and ABI filters (see code above)

# 3. Enable R8 full mode in gradle.properties
echo "android.enableR8.fullMode=true" >> android/gradle.properties

# 4. Compress images
# (Install pngquant first)
# pngquant --quality 65-80 assets/images/*.png --ext .png --force

# 5. Build optimized AAB
flutter build appbundle --release --analyze-size

# 6. Check new size
Get-Item build\app\outputs\bundle\release\app-release.aab | 
  Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB,2)}}
```

---

## 📊 Expected Results

| Action | Size Before | Size After | Savings |
|--------|-------------|------------|---------|
| **Current APK** | 97 MB | - | - |
| Enable AAB | 97 MB | 60-70 MB | 27-37 MB |
| Remove PDFs | 70 MB | 63-65 MB | 5-7 MB |
| Compress natives | 65 MB | 57-60 MB | 5-8 MB |
| R8 full mode | 60 MB | 55-58 MB | 2-5 MB |
| Optimize assets | 58 MB | 53-56 MB | 2-5 MB |
| **Final target** | 97 MB | **50-55 MB** | **42-47 MB** |

---

## ⚠️ Important Notes

### AAB vs APK
- **APK:** One file for all devices (97 MB)
- **AAB:** Google Play creates device-specific APKs (30-50 MB per device)
- **For Play Store:** Always use AAB
- **For direct installation:** Use split APKs or accept larger size

### Trade-offs
- Removing features reduces size but limits functionality
- Dynamic modules add complexity
- Aggressive optimization may increase build time

### Testing
After each optimization:
```powershell
# Build
flutter build appbundle --release

# Test on device
bundletool build-apks --bundle=app-release.aab --output=app.apks
bundletool install-apks --apks=app.apks
```

---

## 🚀 Next Steps

1. **Start with AAB:** Immediate 30-40% reduction
2. **Remove PDFs:** Easy 5-7 MB win if not critical
3. **Analyze APK:** See what's actually large
4. **Iterate:** Measure after each change

**Goal:** Submit to Play Store with AAB at 50-60 MB (users download 30-40 MB)

---

**Priority Actions for TODAY:**
1. ✅ Build AAB instead of APK → Instant 30%+ savings
2. ✅ Remove `printing` and `pdf` packages → 5-7 MB savings
3. ✅ Add native library compression → 8-12 MB savings
4. ✅ Enable R8 full mode → 3-5 MB savings

**Total expected savings:** 46-54 MB ✨

Run Phase 1 checklist above to achieve 50-60 MB target today!
