Param(
  [string]$device = ''
)

$defines = @(
  "--dart-define=APP_ENV=prod",
  "--dart-define=BASE_URL=https://australia-southeast1-redping-a2e37.cloudfunctions.net/api",
  "--dart-define=WEBSOCKET_URL=wss://redping-api-2024.run.app/ws",
  "--dart-define=PROJECT_ID=redping-a2e37",
  "--dart-define=ALLOW_CLIENT_SOS_PING_WRITES=false",
  "--dart-define=ENABLE_REQUEST_SIGNING=true",
  "--dart-define=ENABLE_TLS_PINNING=true",
  "--dart-define=ENABLE_PLAY_INTEGRITY_HEADER=true",
  "--dart-define=REQUIRE_PLAY_INTEGRITY_FOR_WRITES=true",
  "--dart-define=REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES=true",
  # Production feature flags: heartbeat on, no auto ping, sign health, AI enabled
  '--dart-define=FEATURE_FLAGS={"enableHeartbeat":true,"autoProtectedPingOnStartup":false,"skipSigningOnHealth":false,"showBarIndicator":true,"enableLegacyRedPingAIScreen":true,"enableSystemAI":true,"enableInAppVoiceAI":false,"enableCompanionAI":false}',
  "--dart-define=EXPECTED_ANDROID_SIG_SHA256=4A6ADAB5CD9AD2FA5670CD0222D470A1666B821F49D5266F4B1397AD57B500A9"
)

# Add Gemini API key if set in environment
if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY.Trim().Length -gt 0) {
  $defines += "--dart-define=GEMINI_API_KEY=$($env:GEMINI_API_KEY)"
  $defines += "--dart-define=GEMINI_MODEL=gemini-1.5-flash"
  Write-Host "✓ Gemini API configured for AI Assistant" -ForegroundColor Green
} else {
  Write-Warning "GEMINI_API_KEY not set. AI Assistant will use fallback responses."
}

# Inject Stripe live publishable key if provided (preferred over baked default)
if ($env:STRIPE_PUBLISHABLE_KEY_LIVE -and $env:STRIPE_PUBLISHABLE_KEY_LIVE.Trim().Length -gt 0) {
  $defines += "--dart-define=STRIPE_PUBLISHABLE_KEY=$($env:STRIPE_PUBLISHABLE_KEY_LIVE)"
} else {
  Write-Warning "STRIPE_PUBLISHABLE_KEY_LIVE not set. Using embedded fallback; ensure it is current and not revoked."
}

$cmd = @('flutter','run','--release') + $defines
if ($device -ne '') { $cmd += @('-d', $device) }

Write-Host "Running prod build with defines: $($defines -join ' ')"
$exe = $cmd[0]
$args = @()
if ($cmd.Count -gt 1) { $args = $cmd[1..($cmd.Count-1)] }
& $exe @args

