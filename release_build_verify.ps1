<#!
release_build_verify.ps1
Automates: keystore/key.properties validation, Flutter clean build (AAB + APK), fingerprint extraction, optional APK signature verification.
Use from project root.
#>

param(
    [switch] $SkipClean,
    [switch] $SkipAAB,
    [switch] $SkipAPK,
    [ValidateSet('sos','sar')] [string] $Flavor = 'sos',
    [string] $Target,
    [string] $FlutterPath = "flutter"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Required command '$name' not found in PATH."
    }
}

function Read-KeyProperties {
    # Environment variable override for CI (preferred)
    $envStoreFile = $env:STORE_FILE
    $envStorePassword = $env:STORE_PASSWORD
    $envKeyAlias = $env:KEY_ALIAS
    $envKeyPassword = $env:KEY_PASSWORD
    $usingEnv = $envStoreFile -and $envStorePassword -and $envKeyAlias -and $envKeyPassword
    if ($usingEnv) {
        if (-not (Test-Path $envStoreFile)) { throw "Keystore file from STORE_FILE not found: $envStoreFile" }
        return [pscustomobject]@{
            StoreFile    = (Resolve-Path $envStoreFile).Path
            StorePassword= $envStorePassword
            KeyAlias     = $envKeyAlias
            KeyPassword  = $envKeyPassword
        }
    }
    # Fallback to key.properties on developer machines
    $file = Join-Path $PSScriptRoot 'key.properties'
    if (-not (Test-Path $file)) { throw "key.properties missing and env vars not set (STORE_FILE, STORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD)." }
    $map = @{}
    Get-Content $file | ForEach-Object {
        if ($_ -match '^(\s*#|\s*$)') { return }
        $parts = $_.Split('=')
        if ($parts.Count -ge 2) {
            $k = $parts[0].Trim(); $v = ($parts[1..($parts.Count-1)] -join '=').Trim()
            $map[$k] = $v
        }
    }
    $required = 'storeFile','storePassword','keyAlias','keyPassword'
    foreach ($r in $required) { if (-not $map.ContainsKey($r)) { throw "key.properties missing required key '$r'" } }
    $storePath = (Resolve-Path $map['storeFile']).Path
    if (-not (Test-Path $storePath)) { throw "Keystore file not found: $storePath" }
    return [pscustomobject]@{
        StoreFile    = $storePath
        StorePassword= $map['storePassword']
        KeyAlias     = $map['keyAlias']
        KeyPassword  = $map['keyPassword']
    }
}

function Build-Artifacts($flutter) {
    if (-not $SkipClean) { & $flutter clean }
    if (-not $SkipAAB) {
        & $flutter build appbundle --release --flavor $Flavor -t $Target
    }
    if (-not $SkipAPK) {
        & $flutter build apk --release --flavor $Flavor -t $Target
    }
}

function Get-Fingerprints($keystoreInfo) {
    Assert-Command 'keytool'
    # keytool sometimes writes warnings to stderr; PowerShell may treat them as errors.
    # We capture combined output and rely on exit code for success/failure.
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = (
            keytool -list -v -keystore $keystoreInfo.StoreFile -storepass $keystoreInfo.StorePassword -alias $keystoreInfo.KeyAlias 2>&1 |
                ForEach-Object { $_.ToString() }
        )
    } finally {
        $ErrorActionPreference = $oldEap
    }

    if ($LASTEXITCODE -ne 0) { throw "keytool list failed: $($output -join [Environment]::NewLine)" }
    $sha1Match = $output | Select-String -Pattern 'SHA1:' | Select-Object -First 1
    $sha256Match = $output | Select-String -Pattern 'SHA-256:|SHA256:' | Select-Object -First 1
    $sha1 = if ($sha1Match) { $sha1Match.Line.Trim() } else { '' }
    $sha256 = if ($sha256Match) { $sha256Match.Line.Trim() } else { '' }
    return [pscustomobject]@{ SHA1=$sha1; SHA256=$sha256 }
}

function Verify-ApkSignature {
    param(
        [string] $ApkPath
    )
    if (-not (Test-Path $ApkPath)) { Write-Warning "APK not found: $ApkPath"; return }
    $apksigner = Get-Command apksigner -ErrorAction SilentlyContinue
    if (-not $apksigner) { Write-Warning 'apksigner not found; skipping signature verification.'; return }
    & apksigner verify --print-certs $ApkPath
}

function Main {
    Write-Host "[1/5] Reading key.properties..." -ForegroundColor Cyan
    $keyInfo = Read-KeyProperties
    Write-Host "Keystore: $($keyInfo.StoreFile) Alias: $($keyInfo.KeyAlias)" -ForegroundColor Green

    if (-not $Target -or $Target.Trim().Length -eq 0) {
        $Target = switch ($Flavor) {
            'sos' { 'lib/main_sos.dart' }
            'sar' { 'lib/main_sar.dart' }
        }
    }
    if (-not (Test-Path (Join-Path $PSScriptRoot $Target))) {
        throw "Target file not found: $Target"
    }
    Write-Host "Flavor: $Flavor Target: $Target" -ForegroundColor Green

    Write-Host "[2/5] Building artifacts..." -ForegroundColor Cyan
    Build-Artifacts $FlutterPath

    $aab = Join-Path $PSScriptRoot ("build\app\outputs\bundle\{0}Release\app-{0}-release.aab" -f $Flavor)
    $apk = Join-Path $PSScriptRoot ("build\app\outputs\flutter-apk\app-{0}-release.apk" -f $Flavor)
    Write-Host "AAB: $(if (Test-Path $aab) {(Get-Item $aab).Length/1MB -as [int]}) MB" -ForegroundColor Yellow
    Write-Host "APK: $(if (Test-Path $apk) {(Get-Item $apk).Length/1MB -as [int]}) MB" -ForegroundColor Yellow

    Write-Host "[3/5] Extracting fingerprints..." -ForegroundColor Cyan
    $fp = Get-Fingerprints $keyInfo
    Write-Host "Fingerprint SHA1:  $($fp.SHA1)" -ForegroundColor Magenta
    Write-Host "Fingerprint SHA256: $($fp.SHA256)" -ForegroundColor Magenta

    Write-Host "[4/5] Verifying APK signature (if apksigner present)..." -ForegroundColor Cyan
    Verify-ApkSignature -ApkPath $apk

    Write-Host "[5/5] Complete." -ForegroundColor Green
}

try {
    Main
} catch {
    Write-Host "❌ release_build_verify failed" -ForegroundColor Red
    if ($_.Exception -and $_.Exception.Message) {
        Write-Host ("Message: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
    if ($_.ScriptStackTrace) {
        Write-Host "Script stack:" -ForegroundColor DarkRed
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }
    Write-Host "Details:" -ForegroundColor DarkRed
    Write-Host (($_ | Format-List -Force | Out-String).Trim()) -ForegroundColor DarkRed
    exit 1
}