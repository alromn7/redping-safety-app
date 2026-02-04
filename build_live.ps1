# RedPing Live Stripe Build Script
Write-Host "🚀 Building Release APK with LIVE Stripe..." -ForegroundColor Green
Write-Host "⚠️  This will embed LIVE payment keys!" -ForegroundColor Yellow
Write-Host ""

$env:STRIPE_PUBLISHABLE_KEY = "pk_live_51SVNMiPlurWsomXvjlPBOzpskjBW3hKF5aLKrapO23AVUAhBRZ1Ch8zOZl5UlxtQmf0HKJq0hoad3jzr148tpiXa00pDQw8lwi"
$env:FORCE_LIVE_STRIPE = "true"

Write-Host "Building APK..." -ForegroundColor Cyan

$defines = @(
  "--dart-define=STRIPE_PUBLISHABLE_KEY=$env:STRIPE_PUBLISHABLE_KEY",
  "--dart-define=FORCE_LIVE_STRIPE=true",
  '--dart-define=FEATURE_FLAGS={"enableHeartbeat":true,"autoProtectedPingOnStartup":false,"skipSigningOnHealth":false,"showBarIndicator":true,"enableLegacyRedPingAIScreen":true,"enableSystemAI":true,"enableInAppVoiceAI":false,"enableCompanionAI":false}'
)

# Add Gemini API key if set in environment
if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY.Trim().Length -gt 0) {
  $defines += "--dart-define=GEMINI_API_KEY=$($env:GEMINI_API_KEY)"
  $defines += "--dart-define=GEMINI_MODEL=gemini-1.5-flash"
  Write-Host "Gemini API configured" -ForegroundColor Green
} else {
  Write-Warning "GEMINI_API_KEY not set. AI features will use fallback responses."
}

& flutter build apk --release @defines

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "BUILD SUCCESS" -ForegroundColor Green
    
    if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
        $apk = Get-Item "build\app\outputs\flutter-apk\app-release.apk"
        $sizeMB = [math]::Round($apk.Length/1MB, 2)
        
        Write-Host ""
        Write-Host "APK Details:" -ForegroundColor Cyan
        Write-Host "   Path: $($apk.FullName)"
        Write-Host "   Size: $sizeMB MB"
        Write-Host "   Date: $($apk.LastWriteTime)"
        Write-Host ""
        Write-Host "LIVE MODE ACTIVE - Test carefully before distribution!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Install command:" -ForegroundColor Cyan
        Write-Host "   adb install build\app\outputs\flutter-apk\app-release.apk"
    }
} else {
    Write-Host ""
    Write-Host "BUILD FAILED" -ForegroundColor Red
    Write-Host "   Exit code: $LASTEXITCODE"
}
