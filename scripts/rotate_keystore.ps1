<#!
.SYNOPSIS
    Rotates the Android release keystore by generating a new JKS with strong random passwords,
    updating key.properties, backing up the old keystore, and producing a base64 string for CI secrets.

.DESCRIPTION
    1. Backs up existing keystore (if present) with timestamp suffix.
    2. Generates strong random store/key passwords (or uses provided env vars).
    3. Creates new JKS using keytool (RSA 4096, validity 10 years).
    4. Writes android/key.properties (overwriting) with new credentials.
    5. Emits base64 keystore content for CI secret ANDROID_KEYSTORE_BASE64.
    6. Prints SHA-256 and SHA1 fingerprints.

.PARAMETER Alias
    Alias for the key inside the keystore (default: redping-key)

.PARAMETER KeystorePath
    Target keystore path (default: android/keystore/redping-release.jks)

.PARAMETER PasswordLength
    Length of generated passwords (default: 24)

.PARAMETER UseEnv
    If set, will use existing ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD / ANDROID_KEY_ALIAS env vars (generate missing ones).

.PARAMETER NoBase64
    Skip writing the base64 file.

.PARAMETER Overwrite
    Allow overwriting existing key.properties without prompt.

.NOTES
    key.properties and keystore files are ignored via .gitignore; do NOT commit printed passwords.
#>
param(
    [string]$Alias = 'redping-key',
    [string]$KeystorePath = 'android/keystore/redping-release.jks',
    [int]$PasswordLength = 24,
    [switch]$UseEnv,
    [switch]$NoBase64,
    [switch]$Overwrite
)

function New-StrongPassword([int]$len) {
    if ($len -le 0) { throw "Password length must be > 0" }
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*-_=+' .ToCharArray()
    -join (1..$len | ForEach-Object { $chars[(Get-Random -Min 0 -Max $chars.Length)] })
}

$keystoreFile = Get-Item -ErrorAction SilentlyContinue $KeystorePath
if (-not (Test-Path (Split-Path $KeystorePath))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $KeystorePath) | Out-Null
}

# Backup existing keystore
if ($keystoreFile) {
    $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
    $backup = "$KeystorePath.$stamp.bak"
    Copy-Item $keystoreFile.FullName $backup -Force
    Write-Host "Backed up existing keystore to $backup" -ForegroundColor Yellow
}

$storePass = if ($UseEnv) { $Env:ANDROID_KEYSTORE_PASSWORD } else { $null }
$keyPass   = if ($UseEnv) { $Env:ANDROID_KEY_PASSWORD } else { $null }
$aliasEnv  = if ($UseEnv -and $Env:ANDROID_KEY_ALIAS) { $Env:ANDROID_KEY_ALIAS } else { $Alias }

if (-not $storePass) { $storePass = New-StrongPassword $PasswordLength }
if (-not $keyPass)   { $keyPass   = New-StrongPassword $PasswordLength }
$Alias = $aliasEnv

Write-Host "Generated passwords (store/key) - record securely NOW." -ForegroundColor Green
Write-Host "STORE_PASSWORD: $storePass" -ForegroundColor Cyan
Write-Host "KEY_PASSWORD:   $keyPass" -ForegroundColor Cyan
Write-Host "ALIAS:          $Alias" -ForegroundColor Cyan

# Generate new keystore
if (Test-Path $KeystorePath) { Remove-Item $KeystorePath -Force }

${null} # placeholder to maintain diff context
$keytool = if ($Env:JAVA_HOME) { Join-Path $Env:JAVA_HOME 'bin\keytool.exe' } else { 'keytool' }
if (-not (Get-Command $keytool -ErrorAction SilentlyContinue)) {
        Write-Host "keytool not found on PATH or JAVA_HOME is not set." -ForegroundColor Red
        exit 1
}

& $keytool -genkeypair -v `
    -storetype JKS `
    -keystore $KeystorePath `
    -alias $Alias -keyalg RSA -keysize 4096 -validity 3650 `
    -dname "CN=Redping,O=Redping,L=City,S=State,C=US" `
    -storepass $storePass -keypass $keyPass
if ($LASTEXITCODE -ne 0) { Write-Host "Keystore generation failed." -ForegroundColor Red; exit 1 }

# Write key.properties
$keyPropFile = 'android/key.properties'
if ((Test-Path $keyPropFile) -and -not $Overwrite) {
    Write-Host "key.properties exists; use -Overwrite to replace." -ForegroundColor Yellow
} else {
    "storePassword=$storePass" | Out-File $keyPropFile -Encoding UTF8
    "keyPassword=$keyPass"    | Out-File $keyPropFile -Append -Encoding UTF8
    "keyAlias=$Alias"         | Out-File $keyPropFile -Append -Encoding UTF8
    $relativeStore = if ($KeystorePath -like 'android/*') { $KeystorePath.Substring($KeystorePath.IndexOf('android/') + 8) } else { $KeystorePath }
    "storeFile=$relativeStore" | Out-File $keyPropFile -Append -Encoding UTF8
    Write-Host "Updated $keyPropFile" -ForegroundColor Green
}

# Fingerprints
Write-Host "Fingerprints:" -ForegroundColor Magenta
& $keytool -list -v -keystore $KeystorePath -storepass $storePass -alias $Alias | ForEach-Object {
    if ($_ -match 'SHA1:' -or $_ -match 'SHA256:') { Write-Host $_ }
}

# Base64 output for CI
if (-not $NoBase64) {
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeystorePath))
    $b64File = "$KeystorePath.b64"
    $b64 | Set-Content $b64File
    Write-Host "Base64 keystore written: $b64File" -ForegroundColor Green
    Write-Host "Set GitHub secret ANDROID_KEYSTORE_BASE64 to its content." -ForegroundColor Yellow
}

Write-Host "Rotation complete. Replace CI secrets with new values and trigger a build." -ForegroundColor Green
