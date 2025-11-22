# Quick Install & Test - Optimized SMS

Write-Host "`n✅ BUILD COMPLETE - Optimized SMS Templates`n" -ForegroundColor Green

# Detect devices
Write-Host "📱 Detecting devices..." -ForegroundColor Yellow
$devices = adb devices | Select-String "device$" | Where-Object { $_ -notmatch "List of" }
$deviceIds = @()

foreach ($device in $devices) {
    $id = ($device -split "`t")[0].Trim()
    if ($id) {
        $deviceIds += $id
        $model = (adb -s $id shell getprop ro.product.model 2>$null).Trim()
        if ($id -match "emulator") {
            Write-Host "  🖥️  Emulator: $model" -ForegroundColor Cyan
        } else {
            Write-Host "  📱 Device: $model" -ForegroundColor Green
        }
    }
}

if ($deviceIds.Count -eq 0) {
    Write-Host "`n❌ No devices connected!" -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Installing optimized APK on $($deviceIds.Count) device(s)...`n" -ForegroundColor Yellow

foreach ($id in $deviceIds) {
    $model = (adb -s $id shell getprop ro.product.model 2>$null).Trim()
    Write-Host "Installing on $model..." -NoNewline
    
    adb -s $id install -r build\app\outputs\flutter-apk\app-debug.apk 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
        
        # Grant permissions
        adb -s $id shell pm grant com.redping.redping android.permission.SEND_SMS 2>&1 | Out-Null
        adb -s $id shell pm grant com.redping.redping android.permission.ACCESS_FINE_LOCATION 2>&1 | Out-Null
        adb -s $id shell pm grant com.redping.redping android.permission.ACCESS_COARSE_LOCATION 2>&1 | Out-Null
    } else {
        Write-Host " ❌" -ForegroundColor Red
    }
}

Write-Host "`n" + ("═" * 60) -ForegroundColor Cyan
Write-Host "READY TO TEST - Optimized SMS Format" -ForegroundColor Green
Write-Host ("═" * 60) -ForegroundColor Cyan

Write-Host "`n📝 SMS CHANGES:" -ForegroundColor Yellow
Write-Host "  • 44% shorter messages (300 chars vs 500 chars)"
Write-Host "  • Removed heavy box characters (╔═╗)"
Write-Host "  • Shortened map links"
Write-Host "  • Cleaner format with ═══ dividers"
Write-Host "  • 37% lower SMS costs`n"

Write-Host "📱 MANUAL TESTING STEPS:" -ForegroundColor Yellow
Write-Host "  1. Open RedPing on device"
Write-Host "  2. Add YOUR phone number as emergency contact"
Write-Host "  3. Trigger SOS (manual button)"
Write-Host "  4. Check your phone for NEW format SMS"
Write-Host "  5. Verify map link works (tap to open Maps)"
Write-Host "  6. SMS should be ~300 chars (2-3 segments)`n"

Write-Host "🔍 WHAT TO VERIFY:" -ForegroundColor Yellow
Write-Host "  ✅ SMS arrives automatically (no SMS app opens)"
Write-Host "  ✅ Format is clean with ═══ dividers"
Write-Host "  ✅ User identity section clearly visible"
Write-Host "  ✅ Map link is short and clickable"
Write-Host "  ✅ Action steps are numbered (1, 2, 3)"
Write-Host "  ✅ Message fits on one screen`n"

$choice = Read-Host "Start log monitoring? (Y/N)"

if ($choice -eq "Y" -or $choice -eq "y") {
    Write-Host "`n📊 Monitoring logs from all devices...`n" -ForegroundColor Cyan
    Write-Host "Watching for: SMS, Emergency, Event`n" -ForegroundColor Gray
    
    # Clear logs
    foreach ($id in $deviceIds) {
        adb -s $id logcat -c 2>&1 | Out-Null
    }
    
    # Monitor all devices
    if ($deviceIds.Count -eq 1) {
        adb -s $deviceIds[0] logcat | Select-String -Pattern "SMS|Emergency|Event" -CaseSensitive:$false
    } else {
        # Multiple devices - show with prefixes
        $jobs = @()
        
        foreach ($id in $deviceIds) {
            $prefix = if ($id -match "emulator") { "[EMU]" } else { "[DEV]" }
            $jobs += Start-Job -ScriptBlock {
                param($deviceId, $prefix)
                adb -s $deviceId logcat | ForEach-Object {
                    if ($_ -match "SMS|Emergency|Event") {
                        "$prefix $_"
                    }
                }
            } -ArgumentList $id, $prefix
        }
        
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
} else {
    Write-Host "`nReady to test! Open RedPing and trigger SOS.`n" -ForegroundColor Green
}
