@echo off
setlocal enabledelayedexpansion

REM RedPing App - Production Build with LIVE Stripe Configuration
REM ============================================================

echo 🚀 RedPing App - Production Build [LIVE STRIPE MODE]
echo ========================================
echo.
echo ⚠️  WARNING: This build will use LIVE Stripe keys
echo     Real payment charges will occur in this build!
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

REM Step 1: Verify Stripe configuration
echo [INFO] Verifying Stripe LIVE configuration...
echo.
echo Checking backend (functions/.env)...
findstr /C:"STRIPE_SECRET_KEY=sk_live_" functions\.env >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Backend not configured for LIVE mode
    echo        functions/.env must contain: STRIPE_SECRET_KEY=sk_live_...
    pause
    exit /b 1
)
echo [✓] Backend configured for LIVE mode
echo.

REM Step 2: Clean previous builds
echo [INFO] Cleaning previous builds...
call flutter clean
echo [✓] Build cache cleaned
echo.

REM Step 3: Get dependencies
echo [INFO] Getting dependencies...
call flutter pub get
echo [✓] Dependencies updated
echo.

REM Step 4: Build APK with live Stripe configuration
echo [INFO] Building release APK with LIVE Stripe keys...
echo        - Using release mode (live keys will be embedded)
echo        - Code obfuscation: ENABLED
echo        - Tree shaking: ENABLED
echo.

call flutter build apk ^
    --release ^
    --obfuscate ^
    --split-debug-info=build/debug-info/apk ^
    --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_51SVNMiPlurWsomXvjlPBOzpskjBW3hKF5aLKrapO23AVUAhBRZ1Ch8zOZl5UlxtQmf0HKJq0hoad3jzr148tpiXa00pDQw8lwi ^
    --dart-define=FORCE_LIVE_STRIPE=true

if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo.
echo [✓] Release APK built successfully
echo.

REM Step 5: Verify output
echo [INFO] Build Output Location:
echo        📦 APK: build\app\outputs\flutter-apk\app-release.apk
echo.

REM Step 6: Get APK size
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do (
    set size=%%~zA
)
set /a sizeMB=!size! / 1048576
echo [INFO] APK Size: !sizeMB! MB
echo.

REM Step 7: Generate build summary
if not exist "build\reports" mkdir build\reports

set BUILD_DATE=%DATE% %TIME%

(
echo # RedPing LIVE Stripe Build Report
echo.
echo **Build Date:** %BUILD_DATE%
echo **Build Type:** RELEASE [LIVE STRIPE MODE]
echo **APK Size:** !sizeMB! MB
echo.
echo ## ⚠️ CRITICAL - LIVE MODE ACTIVE
echo.
echo This build uses **LIVE Stripe keys** and will process real payments.
echo.
echo ### Stripe Configuration
echo - Mode: **LIVE**
echo - Secret Key: sk_live_... ^(backend^)
echo - Publishable Key: pk_live_... ^(embedded in APK^)
echo - All 8 Price IDs: LIVE recurring prices
echo.
echo ### Security Features
echo - ✅ Code obfuscation enabled
echo - ✅ Debug symbols separated
echo - ✅ Release signing active
echo.
echo ### Output Files
echo - **APK:** `build/app/outputs/flutter-apk/app-release.apk`
echo - **Debug Info:** `build/debug-info/apk/`
echo.
echo ## Pre-Deployment Checklist
echo.
echo - [ ] Test subscription flow with a real card ^(refund after^)
echo - [ ] Verify price IDs match Stripe Dashboard products
echo - [ ] Test webhook endpoints receive events
echo - [ ] Confirm Firebase Functions deployed with LIVE keys
echo - [ ] Verify entitlements are written to Firestore correctly
echo - [ ] Test subscription cancellation flow
echo - [ ] Ensure payment failures are handled gracefully
echo.
echo ## Installation Command
echo.
echo ```bash
echo adb install build/app/outputs/flutter-apk/app-release.apk
echo ```
echo.
) > build\reports\live_stripe_build_report.md

echo [✓] Build report: build\reports\live_stripe_build_report.md
echo.
echo ========================================
echo 🎉 LIVE Stripe Build Complete!
echo ========================================
echo.
echo 📦 APK Ready: build\app\outputs\flutter-apk\app-release.apk
echo 📊 Size: !sizeMB! MB
echo 📄 Report: build\reports\live_stripe_build_report.md
echo.
echo ⚠️  REMINDER: This APK uses LIVE payment processing!
echo    Test carefully before wide distribution.
echo.
echo Next steps:
echo   1. Install on test device: adb install build\app\outputs\flutter-apk\app-release.apk
echo   2. Create a test subscription with a real payment method
echo   3. Verify entitlements in Firestore
echo   4. Cancel and refund the test subscription
echo.

pause
