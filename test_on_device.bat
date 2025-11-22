@echo off
REM RedPing Emergency System - Quick Test Script
REM Runs automated testing sequence on connected Android device

echo ========================================
echo RedPing Emergency System - Test Runner
echo ========================================
echo.

REM Check device connection
echo [1/5] Checking device connection...
adb devices
if errorlevel 1 (
    echo ERROR: No Android device connected!
    echo Connect device and enable USB debugging
    exit /b 1
)
echo ✓ Device connected
echo.

REM Build debug APK
echo [2/5] Building debug APK...
call flutter build apk --debug
if errorlevel 1 (
    echo ERROR: Build failed!
    exit /b 1
)
echo ✓ Build successful
echo.

REM Install APK
echo [3/5] Installing APK on device...
adb install -r build\app\outputs\flutter-apk\app-debug.apk
if errorlevel 1 (
    echo ERROR: Installation failed!
    exit /b 1
)
echo ✓ APK installed
echo.

REM Grant SMS permission
echo [4/5] Granting SMS permission...
adb shell pm grant com.redping.redping android.permission.SEND_SMS
echo ✓ SMS permission granted
echo.

REM Start log monitoring
echo [5/5] Starting log monitoring...
echo.
echo ============================================
echo TESTING READY - FOLLOW THESE STEPS:
echo ============================================
echo 1. Open RedPing app on device
echo 2. Configure test emergency contacts
echo 3. Trigger SOS (manual button)
echo 4. Watch logs below for SMS and events
echo.
echo Logs will show:
echo   - SMS sending status
echo   - Event bus activity
echo   - Service coordination
echo.
echo Press Ctrl+C to stop monitoring
echo ============================================
echo.

REM Monitor logs with filters
adb logcat -c
adb logcat | findstr /I "SMS Emergency Event WebRTC Agora RedPing"

pause
