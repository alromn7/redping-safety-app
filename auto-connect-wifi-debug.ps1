# Auto-connect to Android device via WiFi debugging
# Usage: .\auto-connect-wifi-debug.ps1

Write-Host "🔌 Android WiFi Debugging Auto-Connect Script" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration - Update these with your device's IP and port
$DEVICE_IP = "10.177.98.199"
$DEVICE_PORT = "5555"
$DEVICE_ADDRESS = "${DEVICE_IP}:${DEVICE_PORT}"

# Check if ADB is available
try {
    $adbVersion = adb version 2>&1
    Write-Host "✅ ADB found" -ForegroundColor Green
} catch {
    Write-Host "❌ ADB not found. Please install Android SDK Platform Tools" -ForegroundColor Red
    exit 1
}

# Function to check if device is connected
function Test-DeviceConnected {
    $devices = adb devices | Select-String -Pattern $DEVICE_ADDRESS
    return $devices -ne $null
}

# Check current connection status
Write-Host "📱 Checking device connection status..." -ForegroundColor Yellow

if (Test-DeviceConnected) {
    Write-Host "✅ Device already connected: $DEVICE_ADDRESS" -ForegroundColor Green
    adb devices
    exit 0
}

Write-Host "⚠️  Device not connected. Attempting to connect..." -ForegroundColor Yellow
Write-Host ""

# Kill and restart ADB server for clean connection
Write-Host "🔄 Restarting ADB server..." -ForegroundColor Cyan
adb kill-server | Out-Null
Start-Sleep -Seconds 1
adb start-server | Out-Null
Start-Sleep -Seconds 2

# Attempt to connect
Write-Host "🔌 Connecting to $DEVICE_ADDRESS..." -ForegroundColor Cyan
$connectResult = adb connect $DEVICE_ADDRESS 2>&1

if ($LASTEXITCODE -eq 0 -and $connectResult -like "*connected*") {
    Write-Host "✅ Successfully connected to $DEVICE_ADDRESS" -ForegroundColor Green
    Write-Host ""
    Write-Host "Connected devices:" -ForegroundColor Cyan
    adb devices
    Write-Host ""
    Write-Host "🎉 Ready for development!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Failed to connect to $DEVICE_ADDRESS" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check that WiFi debugging is enabled on your device" -ForegroundColor White
    Write-Host "   Settings → Developer Options → Wireless debugging → ON" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Verify the IP address and port match your device" -ForegroundColor White
    Write-Host "   Current config: $DEVICE_ADDRESS" -ForegroundColor Gray
    Write-Host "   Update this script if your device uses a different IP/port" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Ensure phone and PC are on the same WiFi network" -ForegroundColor White
    Write-Host ""
    Write-Host "4. If first time connecting, you may need to pair:" -ForegroundColor White
    Write-Host "   a. Tap 'Pair device with pairing code' on your phone" -ForegroundColor Gray
    Write-Host "   b. Run: adb pair <IP:PORT>" -ForegroundColor Gray
    Write-Host "   c. Enter the 6-digit code shown on your phone" -ForegroundColor Gray
    Write-Host "   d. Then run this script again" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
