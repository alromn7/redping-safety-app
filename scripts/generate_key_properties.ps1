param(
    [string]$KeystorePath = "android/keystore/redping-release.jks",
    [int]$PasswordLength = 24,
    [switch]$GeneratePasswords,
    [switch]$Overwrite,
    [switch]$OnlyFromEnv
)

$keyPropFile = "android/key.properties"

if (Test-Path $keyPropFile -and -not $Overwrite -and -not $OnlyFromEnv) {
    Write-Host "key.properties already exists. Use -Overwrite to regenerate or -OnlyFromEnv to create from existing env vars." -ForegroundColor Yellow
    return
}

$storePass = $Env:ANDROID_KEYSTORE_PASSWORD
$keyPass = $Env:ANDROID_KEY_PASSWORD
$keyAlias = $Env:ANDROID_KEY_ALIAS

if ($GeneratePasswords) {
    $chars = (('a'..'z') + ('A'..'Z') + (0..9) + '!@#$%^&*-_=+').ToCharArray()
    function New-RandomPassword($len) {
        -join (1..$len | ForEach-Object { $chars[(Get-Random -Max $chars.Count)] })
    }
    if (-not $storePass) { $storePass = New-RandomPassword $PasswordLength }
    if (-not $keyPass) { $keyPass = New-RandomPassword $PasswordLength }
    if (-not $keyAlias) { $keyAlias = 'redping-key' }
    Write-Host "Generated store/key passwords (record securely)." -ForegroundColor Green
}

if ($OnlyFromEnv -and ($storePass -and $keyPass -and $keyAlias)) {
    Write-Host "Writing key.properties from environment variables." -ForegroundColor Cyan
} elseif ($OnlyFromEnv -and -not ($storePass -and $keyPass -and $keyAlias)) {
    Write-Host "Missing required env vars (ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD / ANDROID_KEY_ALIAS). Aborting." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $KeystorePath)) {
    Write-Host "Keystore path '$KeystorePath' does not exist. You may need to generate or place the JKS file first." -ForegroundColor Yellow
}

if (-not $storePass -or -not $keyPass -or -not $keyAlias) {
    Write-Host "Store/key password or alias missing. Provide env vars or use -GeneratePasswords." -ForegroundColor Red
    exit 1
}

"storePassword=$storePass" | Out-File $keyPropFile -Encoding UTF8
"keyPassword=$keyPass" | Out-File $keyPropFile -Append -Encoding UTF8
"keyAlias=$keyAlias" | Out-File $keyPropFile -Append -Encoding UTF8
"storeFile=$KeystorePath" | Out-File $keyPropFile -Append -Encoding UTF8

Write-Host "key.properties written to $keyPropFile" -ForegroundColor Green
Write-Host "Add these to your secrets manager; DO NOT COMMIT actual passwords." -ForegroundColor Yellow
