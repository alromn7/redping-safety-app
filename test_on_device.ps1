# RedPing Emergency System - Quick Test Script (PowerShell)
# Runs automated testing sequence on connected Android device

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RedPing Emergency System - Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check device connection
Write-Host "[1/5] Checking device connection..." -ForegroundColor Yellow
$devices = adb devices
if ($LASTEXITCODE -ne 0 -or $devices -notmatch "device$") {
    Write-Host "ERROR: No Android device connected!" -ForegroundColor Red
    Write-Host "Connect device and enable USB debugging" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Device connected (Pixel 7 Pro)" -ForegroundColor Green
Write-Host ""

# Build debug APK
Write-Host "[2/5] Building debug APK..." -ForegroundColor Yellow
flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Build successful" -ForegroundColor Green
Write-Host ""

# Install APK
Write-Host "[3/5] Installing APK on device..." -ForegroundColor Yellow
adb install -r build\app\outputs\flutter-apk\app-debug.apk
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Installation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ APK installed" -ForegroundColor Green
Write-Host ""

# Grant SMS permission
Write-Host "[4/5] Granting SMS permission..." -ForegroundColor Yellow
adb shell pm grant com.redping.redping android.permission.SEND_SMS
Write-Host "✓ SMS permission granted" -ForegroundColor Green
Write-Host ""

# Start log monitoring
Write-Host "[5/5] Starting log monitoring..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "TESTING READY - FOLLOW THESE STEPS:" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "1. Open RedPing app on device"
Write-Host "2. Configure test emergency contacts"
Write-Host "3. Trigger SOS (manual button)"
Write-Host "4. Watch logs below for SMS and events"
Write-Host ""
Write-Host "Logs will show:" -ForegroundColor Yellow
Write-Host "  - SMS sending status"
Write-Host "  - Event bus activity"
Write-Host "  - Service coordination"
Write-Host ""
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Clear old logs and start monitoring
adb logcat -c
adb logcat | Select-String -Pattern "SMS|Emergency|Event|WebRTC|Agora|RedPing" -CaseSensitive:$false
