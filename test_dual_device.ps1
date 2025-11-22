#!/usr/bin/env pwsh
# RedPing Dual Device Testing
# Tests on both physical device (Pixel 7 Pro) and emulator simultaneously

Write-Host "`n" + ("═" * 60) -ForegroundColor Cyan
Write-Host "  RedPing Emergency System - Dual Device Testing" -ForegroundColor Cyan
Write-Host ("═" * 60) -ForegroundColor Cyan
Write-Host ""

# Detect connected devices
$devices = adb devices | Select-String "device$" | Where-Object { $_ -notmatch "List of" }
$deviceList = @()

foreach ($device in $devices) {
    $deviceId = ($device -split "`t")[0].Trim()
    if ($deviceId) {
        $deviceList += $deviceId
    }
}

if ($deviceList.Count -eq 0) {
    Write-Host "❌ No devices connected!" -ForegroundColor Red
    exit 1
}

Write-Host "📱 Connected Devices:" -ForegroundColor Yellow
foreach ($device in $deviceList) {
    $model = (adb -s $device shell getprop ro.product.model).Trim()
    $android = (adb -s $device shell getprop ro.build.version.release).Trim()
    
    if ($device -match "emulator") {
        Write-Host "  🖥️  Emulator: $device ($model, Android $android)" -ForegroundColor Cyan
    } else {
        Write-Host "  📱 Physical: $device ($model, Android $android)" -ForegroundColor Green
    }
}

Write-Host ""

# Check if APK exists
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (!(Test-Path $apkPath)) {
    Write-Host "❌ APK not found at $apkPath" -ForegroundColor Red
    Write-Host "Building APK..." -ForegroundColor Yellow
    flutter build apk --debug
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ APK found: $apkPath`n" -ForegroundColor Green

# Install on all devices
Write-Host ("─" * 60) -ForegroundColor Cyan
Write-Host "📦 Installing on all devices..." -ForegroundColor Yellow
Write-Host ("─" * 60) -ForegroundColor Cyan

foreach ($device in $deviceList) {
    $model = (adb -s $device shell getprop ro.product.model).Trim()
    Write-Host "`nInstalling on $model ($device)..." -NoNewline
    
    adb -s $device install -r $apkPath 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
        
        # Grant SMS permission
        Write-Host "  Granting SMS permission..." -NoNewline
        adb -s $device shell pm grant com.redping.redping android.permission.SEND_SMS 2>&1 | Out-Null
        Write-Host " ✅" -ForegroundColor Green
        
        # Grant location permission
        Write-Host "  Granting location permissions..." -NoNewline
        adb -s $device shell pm grant com.redping.redping android.permission.ACCESS_FINE_LOCATION 2>&1 | Out-Null
        adb -s $device shell pm grant com.redping.redping android.permission.ACCESS_COARSE_LOCATION 2>&1 | Out-Null
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ❌" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("═" * 60) -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE - Ready to Test!" -ForegroundColor Green
Write-Host ("═" * 60) -ForegroundColor Cyan
Write-Host ""

# Show test instructions
Write-Host "🧪 TEST OPTIONS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Monitor BOTH devices (recommended)" -ForegroundColor Cyan
Write-Host "  This will show logs from both devices in real-time" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Monitor PHYSICAL device only" -ForegroundColor Cyan
Write-Host "  Logs from Pixel 7 Pro only" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Monitor EMULATOR only" -ForegroundColor Cyan
Write-Host "  Logs from Android Emulator only" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Choose option (1/2/3 or Q to quit)"

switch ($choice.ToUpper()) {
    "1" {
        Write-Host "`n📊 Monitoring BOTH devices..." -ForegroundColor Cyan
        Write-Host "Physical device logs will be prefixed with [DEVICE]" -ForegroundColor Gray
        Write-Host "Emulator logs will be prefixed with [EMULATOR]" -ForegroundColor Gray
        Write-Host ""
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host "📱 Manual Steps (on BOTH devices):" -ForegroundColor Yellow
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host "1. Open RedPing app on each device"
        Write-Host "2. Add test emergency contact (your phone number)"
        Write-Host "3. Trigger SOS on one or both devices"
        Write-Host "4. Watch logs below for SMS and event activity"
        Write-Host "5. Check your phone for SMS delivery"
        Write-Host ""
        Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host ""
        
        # Clear logs
        foreach ($device in $deviceList) {
            adb -s $device logcat -c 2>&1 | Out-Null
        }
        
        # Monitor both devices with prefixes
        $jobs = @()
        
        # Physical device
        $physicalDevice = $deviceList | Where-Object { $_ -notmatch "emulator" } | Select-Object -First 1
        if ($physicalDevice) {
            $jobs += Start-Job -ScriptBlock {
                param($device)
                adb -s $device logcat | ForEach-Object {
                    if ($_ -match "SMS|Emergency|Event|WebRTC|Agora|RedPing") {
                        "[DEVICE] $_"
                    }
                }
            } -ArgumentList $physicalDevice
        }
        
        # Emulator
        $emulatorDevice = $deviceList | Where-Object { $_ -match "emulator" } | Select-Object -First 1
        if ($emulatorDevice) {
            $jobs += Start-Job -ScriptBlock {
                param($device)
                adb -s $device logcat | ForEach-Object {
                    if ($_ -match "SMS|Emergency|Event|WebRTC|Agora|RedPing") {
                        "[EMULATOR] $_"
                    }
                }
            } -ArgumentList $emulatorDevice
        }
        
        # Display output from both jobs
        try {
            while ($true) {
                foreach ($job in $jobs) {
                    Receive-Job $job | Write-Host
                }
                Start-Sleep -Milliseconds 100
            }
        } finally {
            $jobs | Stop-Job
            $jobs | Remove-Job
        }
    }
    
    "2" {
        $physicalDevice = $deviceList | Where-Object { $_ -notmatch "emulator" } | Select-Object -First 1
        if (!$physicalDevice) {
            Write-Host "❌ No physical device found!" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n📊 Monitoring Physical Device ($physicalDevice)..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host "📱 Manual Steps:" -ForegroundColor Yellow
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host "1. Open RedPing app on Pixel 7 Pro"
        Write-Host "2. Add test emergency contact"
        Write-Host "3. Trigger SOS"
        Write-Host "4. Watch logs below"
        Write-Host ""
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host ""
        
        adb -s $physicalDevice logcat -c
        adb -s $physicalDevice logcat | Select-String -Pattern "SMS|Emergency|Event|WebRTC|Agora|RedPing" -CaseSensitive:$false
    }
    
    "3" {
        $emulatorDevice = $deviceList | Where-Object { $_ -match "emulator" } | Select-Object -First 1
        if (!$emulatorDevice) {
            Write-Host "❌ No emulator found!" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n📊 Monitoring Emulator ($emulatorDevice)..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host "🖥️  Manual Steps:" -ForegroundColor Yellow
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host "1. Open RedPing app on Emulator"
        Write-Host "2. Add test emergency contact"
        Write-Host "3. Trigger SOS"
        Write-Host "4. Watch logs below"
        Write-Host ""
        Write-Host "⚠️  Note: Emulator may not send real SMS" -ForegroundColor Yellow
        Write-Host "   Check logs for 'SMS sent' messages" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
        Write-Host ("─" * 60) -ForegroundColor Cyan
        Write-Host ""
        
        adb -s $emulatorDevice logcat -c
        adb -s $emulatorDevice logcat | Select-String -Pattern "SMS|Emergency|Event|WebRTC|Agora|RedPing" -CaseSensitive:$false
    }
    
    default {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit 0
    }
}
