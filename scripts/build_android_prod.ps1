Param(
  [string]$flavor = 'prod'
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
  "--dart-define=EXPECTED_ANDROID_SIG_SHA256=4A6ADAB5CD9AD2FA5670CD0222D470A1666B821F49D5266F4B1397AD57B500A9"
)

$cmd = @('flutter','build','apk','--release') + $defines
Write-Host "Building Android APK (prod) with defines: $($defines -join ' ')"
& $cmd

