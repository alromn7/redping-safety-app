#!/usr/bin/env pwsh
# Quick SMS Test - Isolated test for native SMS functionality
# Run after app is installed on device

Write-Host "`n🧪 RedPing - Quick SMS Test`n" -ForegroundColor Cyan
Write-Host "Testing native SMS sending without opening SMS app`n" -ForegroundColor Yellow

# Check device
Write-Host "Checking device..." -NoNewline
$devices = adb devices | Select-String "device$"
if ($devices.Count -eq 0) {
    Write-Host " ❌ No device connected" -ForegroundColor Red
    exit 1
}
Write-Host " ✅" -ForegroundColor Green

# Check app installed
Write-Host "Checking app installed..." -NoNewline
$installed = adb shell pm list packages | Select-String "com.redping.redping"
if (!$installed) {
    Write-Host " ❌ App not installed" -ForegroundColor Red
    Write-Host "Run: flutter install" -ForegroundColor Yellow
    exit 1
}
Write-Host " ✅" -ForegroundColor Green

# Grant SMS permission
Write-Host "Granting SMS permission..." -NoNewline
adb shell pm grant com.redping.redping android.permission.SEND_SMS 2>$null
Write-Host " ✅" -ForegroundColor Green

Write-Host "`n" + ("─" * 50) -ForegroundColor Cyan
Write-Host "READY TO TEST" -ForegroundColor Green
Write-Host ("─" * 50) -ForegroundColor Cyan

Write-Host "`n📱 Manual Steps:" -ForegroundColor Yellow
Write-Host "  1. Open RedPing app on Pixel 7 Pro"
Write-Host "  2. Go to Emergency Contacts"
Write-Host "  3. Add YOUR phone number as a test contact"
Write-Host "  4. Go back to home screen"
Write-Host "  5. Press SOS button (manual trigger)"
Write-Host "  6. Watch for SMS on your phone (within 10 sec)"
Write-Host ""
Write-Host "✅ SUCCESS: SMS arrives without SMS app opening" -ForegroundColor Green
Write-Host "❌ FAILURE: SMS app opens OR no SMS received" -ForegroundColor Red
Write-Host ""

# Prompt to start monitoring
$ready = Read-Host "Press ENTER when ready to monitor logs (or Ctrl+C to exit)"

Write-Host "`n📊 Monitoring logs..." -ForegroundColor Cyan
Write-Host "Watching for SMS activity...`n" -ForegroundColor Yellow

# Clear logs and monitor
adb logcat -c
adb logcat | Select-String -Pattern "SMS|Emergency|PlatformSMS|SMSPlugin|sendSMS" -CaseSensitive:$false
