<#!
Archive mapping.txt with versioned naming.
Usage:
  powershell -ExecutionPolicy Bypass -File scripts\archive_mapping.ps1 -Version v1.0.1-rc1
Creates: mapping_archive/mapping-v1.0.1-rc1.txt
#>
param(
  [string] $Version,
  [string] $Source = 'android/app/build/outputs/mapping/release/mapping.txt',
  [string] $DestDir = 'mapping_archive'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $Version) { throw 'Version tag required via -Version.' }
if (-not (Test-Path $Source)) { throw "mapping file not found: $Source (build with minify enabled)" }
if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir | Out-Null }
$dest = Join-Path $DestDir "mapping-$Version.txt"
Copy-Item $Source $dest -Force
Write-Host "[mapping] Archived to $dest" -ForegroundColor Green
