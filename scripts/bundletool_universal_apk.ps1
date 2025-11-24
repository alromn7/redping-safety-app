<#!
Generate and optionally install a universal APK from an AAB using bundletool.
Pre-req: bundletool.jar placed in tools\bundletool.jar OR BUNDLETOOL_JAR env var set.
Usage:
  powershell -ExecutionPolicy Bypass -File scripts\bundletool_universal_apk.ps1 -AabPath build\app\outputs\bundle\release\app-release.aab -Out universal.apk -Install
#>
param(
  [string] $AabPath = 'build\app\outputs\bundle\release\app-release.aab',
  [string] $Out = 'universal.apk',
  [switch] $Install,
  [string] $BundletoolJar = $Env:BUNDLETOOL_JAR
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $AabPath)) { throw "AAB not found: $AabPath" }
if (-not $BundletoolJar) { $BundletoolJar = 'tools/bundletool.jar' }
if (-not (Test-Path $BundletoolJar)) { throw "bundletool.jar not found at $BundletoolJar (set BUNDLETOOL_JAR or place in tools)." }

Write-Host "[bundletool] Using JAR: $BundletoolJar" -ForegroundColor Cyan

# Build universal APK set (single output)
& java -jar $BundletoolJar build-apks --mode=universal --bundle=$AabPath --output=temp.apks | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'bundletool build-apks failed.' }

# Extract universal.apk from archive
Expand-Archive -Path temp.apks -DestinationPath temp_apks_extract -Force
$universal = Get-ChildItem temp_apks_extract -Recurse -Filter '*.apk' | Select-Object -First 1
if (-not $universal) { throw 'Universal APK not found after extraction.' }
Copy-Item $universal.FullName $Out -Force
Remove-Item temp.apks -Force
Remove-Item temp_apks_extract -Recurse -Force
Write-Host "[bundletool] Universal APK created: $Out" -ForegroundColor Green

if ($Install) {
  if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { Write-Warning 'adb not found; skipping install.' } else {
    Write-Host "[install] adb install -r $Out" -ForegroundColor Cyan
    & adb install -r $Out
  }
}
