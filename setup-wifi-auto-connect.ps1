# Setup Auto-Connect for WiFi Debugging
# This creates a scheduled task that runs when you connect to WiFi

Write-Host "🔧 Setting up WiFi Debugging Auto-Connect" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  This script needs to run as Administrator to create a scheduled task" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please:" -ForegroundColor White
    Write-Host "1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "3. Run this script again" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OR use manual method (see below)" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# Configuration
$scriptPath = Join-Path $PSScriptRoot "auto-connect-wifi-debug.ps1"
$taskName = "Android WiFi Debug Auto-Connect"

Write-Host "📝 Creating scheduled task: $taskName" -ForegroundColor Cyan
Write-Host "Script location: $scriptPath" -ForegroundColor Gray
Write-Host ""

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "⚠️  Task already exists. Removing old version..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Trigger: Run when network connection is established
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Principal: Run as current user
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

# Register the task
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automatically connects to Android device via WiFi debugging when on the same network" | Out-Null
    
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The task will run automatically when you log in." -ForegroundColor White
    Write-Host "You can also run it manually at any time:" -ForegroundColor White
    Write-Host "  .\auto-connect-wifi-debug.ps1" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual setup instructions below..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Manual Connection Method:" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host ""
Write-Host "If you prefer manual connection, just run:" -ForegroundColor White
Write-Host "  .\auto-connect-wifi-debug.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or create a desktop shortcut:" -ForegroundColor White
Write-Host "1. Right-click Desktop → New → Shortcut" -ForegroundColor Gray
Write-Host "2. Location: PowerShell.exe -ExecutionPolicy Bypass -File `"$scriptPath`"" -ForegroundColor Gray
Write-Host "3. Name: Connect Android WiFi Debug" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
pause
