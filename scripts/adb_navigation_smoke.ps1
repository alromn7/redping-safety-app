<#!
ADB Navigation Smoke Script
Simulates basic UI interactions post-launch to exercise navigation stack.
Requires: device connected (adb), app installed & launched.
Usage:
  powershell -ExecutionPolicy Bypass -File scripts\adb_navigation_smoke.ps1 -PackageId com.redping.redping -Delay 800
Options:
  -PackageId <string>   Application id (default com.redping.redping)
  -Delay <int>          Milliseconds between input events (default 600)
  -Iterations <int>     Repeat navigation cycle count (default 1)
  -Verbose              Print each action.
#>
param(
  [string] $PackageId = 'com.redping.redping',
  [int] $Delay = 600,
  [int] $Iterations = 1,
  [switch] $Verbose
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Pause() { Start-Sleep -Milliseconds $Delay }
function Log($m) { if ($Verbose) { Write-Host "[nav] $m" -ForegroundColor Cyan } }

# Basic actions: tap coordinates (placeholder), back, open overview? Provide adjustable coordinates.
# Suggest customizing coordinates for actual UI hotspots:
$Taps = @(
  @{x=120; y=220; name='MenuOrTab1'},
  @{x=360; y=220; name='MenuOrTab2'},
  @{x=600; y=220; name='MenuOrTab3'}
)

for ($i=1; $i -le $Iterations; $i++) {
  Log "Cycle $i start"
  foreach ($t in $Taps) {
    Log "Tap $($t.name) at ($($t.x),$($t.y))"
    & adb shell input tap $t.x $t.y
    Pause
  }
  Log 'Send BACK'
  & adb shell input keyevent 4
  Pause
}

Write-Host '[nav] Navigation smoke completed.' -ForegroundColor Green
