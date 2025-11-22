Param(
  [string]$device = ''
)

$defines = @(
  "--dart-define=APP_ENV=staging",
  "--dart-define=BASE_URL=https://australia-southeast1-redping-a2e37.cloudfunctions.net/api",
  "--dart-define=WEBSOCKET_URL=wss://staging.redping-api.run.app/ws",
  "--dart-define=PROJECT_ID=redping-a2e37",
  "--dart-define=ALLOW_CLIENT_SOS_PING_WRITES=false",
  "--dart-define=ENABLE_REQUEST_SIGNING=true",
  "--dart-define=ENABLE_TLS_PINNING=true",
  "--dart-define=ENABLE_PLAY_INTEGRITY_HEADER=true",
  "--dart-define=REQUIRE_PLAY_INTEGRITY_FOR_WRITES=true",
  "--dart-define=REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES=false",
  # Staging feature flags: heartbeat on, no auto ping, sign health
  '--dart-define=FEATURE_FLAGS={"enableHeartbeat":true,"autoProtectedPingOnStartup":false,"skipSigningOnHealth":false,"showBarIndicator":true,"enableInAppVoiceAI":false,"enableCompanionAI":false,"enableSystemAI":false}',
  "--dart-define=EXPECTED_ANDROID_SIG_SHA256=4A6ADAB5CD9AD2FA5670CD0222D470A1666B821F49D5266F4B1397AD57B500A9"
)

$cmd = @('flutter','run') + $defines
if ($device -ne '') { $cmd += @('-d', $device) }

Write-Host "Running staging build with defines: $($defines -join ' ')"
$exe = $cmd[0]
$args = @()
if ($cmd.Count -gt 1) { $args = $cmd[1..($cmd.Count-1)] }
& $exe @args

