<#!
Device Installation & Verification Script
Automates: APK signature check, hash, device detection, install/update, launch, minimal smoke, optional log capture.
Usage (PowerShell):
  powershell -ExecutionPolicy Bypass -File scripts\device_install_verify.ps1 -ApkPath build\app\outputs\flutter-apk\app-release.apk -PackageId com.redping.redping
Parameters:
  -ApkPath <string>         Path to APK (default: build\app\outputs\flutter-apk\app-release.apk)
  -PackageId <string>       ApplicationId (default: com.redping.redping)
  -Events <int>             Monkey launch events after start (default: 1)
  -CaptureSeconds <int>     Seconds of logcat capture after launch (default: 10)
  -SkipSignature            Skip apksigner signature verification
  -SkipHash                 Skip SHA256 hash output
  -SkipInstall              Skip install step (only verify + logs)
  -ForceReinstall           Use adb install -r even if app already present (default: true)
  -VerboseLogs              Show broader logcat categories
#>
param(
  [string] $ApkPath = 'build\app\outputs\flutter-apk\app-release.apk',
  [string] $PackageId = 'com.redping.redping',
  [int] $Events = 1,
  [int] $CaptureSeconds = 10,
  [switch] $SkipSignature,
  [switch] $SkipHash,
  [switch] $SkipInstall,
  [switch] $ForceReinstall,
  [switch] $VerboseLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Required command '$name' not found in PATH." }
}

function Get-ApkSignerPath {
  $apksigner = Get-Command apksigner -ErrorAction SilentlyContinue
  if ($apksigner) { return $apksigner.Path }
  $sdkRoot = $Env:ANDROID_HOME
  if (-not $sdkRoot) { $sdkRoot = "$Env:LOCALAPPDATA\Android\Sdk" }
  if (Test-Path $sdkRoot) {
    $candidate = Get-ChildItem "$sdkRoot\build-tools" -Filter apksigner.bat -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
    return $candidate?.FullName
  }
  return $null
}

function Verify-Signature($apk) {
  param([string] $apk)
  $path = Get-ApkSignerPath
  if (-not $path) { Write-Warning 'apksigner not found; skipping signature verification.'; return }
  Write-Host "[sig] Using apksigner: $path" -ForegroundColor Cyan
  & $path verify --print-certs $apk | Tee-Object -Variable sigOut
  if ($LASTEXITCODE -ne 0) { throw "APK signature verification failed." }
  if ($sigOut -match 'Android Debug') { throw "APK signed with debug certificate (Android Debug)." }
  Write-Host '[sig] Signature OK (non-debug).' -ForegroundColor Green
}

function Get-Hash($apk) {
  param([string] $apk)
  $hash = (Get-FileHash -Algorithm SHA256 -Path $apk).Hash
  Write-Host "[hash] SHA256: $hash" -ForegroundColor Magenta
}

function Ensure-Device {
  $devices = & adb devices | Select-String 'device$'
  if (-not $devices) { throw 'No connected device in "device" state. Run: adb devices and enable USB debugging on phone.' }
  Write-Host "[device] Connected: $($devices -join ', ')" -ForegroundColor Green
}

function Install-Apk($apk,$pkg) {
  if (-not (Test-Path $apk)) { throw "APK not found: $apk" }
  if ($SkipInstall) { Write-Host '[install] Skipped by flag.' -ForegroundColor Yellow; return }
  $cmd = 'adb install'
  if ($ForceReinstall) { $cmd += ' -r' }
  Write-Host "[install] $cmd $apk" -ForegroundColor Cyan
  & adb install -r $apk | Tee-Object -Variable installOut
  if ($installOut -match 'Failure') { throw "Install failed: $installOut" }
  Write-Host '[install] Success.' -ForegroundColor Green
}

function Launch-App($pkg,$events) {
  Write-Host "[launch] Starting $pkg" -ForegroundColor Cyan
  & adb shell monkey -p $pkg -c android.intent.category.LAUNCHER $events | Out-Null
  Start-Sleep -Seconds 2
}

function Capture-Logs($pkg,$seconds,$verbose) {
  Write-Host "[logs] Capturing ${seconds}s of filtered logcat..." -ForegroundColor Cyan
  $filter = if ($verbose) { '' } else { "-s flutter ActivityManager System.err" }
  $p = Start-Process adb -ArgumentList "logcat $filter" -NoNewWindow -PassThru -RedirectStandardOutput logcat_temp.txt
  Start-Sleep -Seconds $seconds
  $p | Stop-Process
  $lines = Get-Content logcat_temp.txt | Select-String -Pattern $pkg,'E/flutter','Exception' -SimpleMatch
  Write-Host "[logs] Relevant lines:" -ForegroundColor Yellow
  $lines | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
  Remove-Item logcat_temp.txt -Force
}

function Main {
  Assert-Command 'adb'
  if (-not $SkipSignature) { Assert-Command 'java' } # keytool comes with JDK; apksigner separate
  Ensure-Device
  if (-not $SkipSignature) { Verify-Signature $ApkPath }
  if (-not $SkipHash) { Get-Hash $ApkPath }
  Install-Apk $ApkPath $PackageId
  Launch-App $PackageId $Events
  Capture-Logs $PackageId $CaptureSeconds $VerboseLogs
  Write-Host '[done] Device install & verification complete.' -ForegroundColor Green
}

try { Main } catch { Write-Error $_; exit 1 }
