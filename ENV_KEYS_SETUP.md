# Env Keys Setup — Emergency and SAR (Planning)

## Purpose
Define `--dart-define` keys and values used across apps; align with `lib/config/env.dart` in the main system.

## Keys
- `APP_ENV` (EnvKeys.appEnv): `dev` | `staging` | `prod`
- `BASE_URL` (EnvKeys.baseUrl): e.g., `https://api.redping.app/v1`
- `WEBSOCKET_URL` (EnvKeys.websocketUrl): e.g., `wss://api.redping.app/ws`
- `REGION` (EnvKeys.region): e.g., `global` | `au` | `us`
- `FEATURE_FLAGS` (EnvKeys.featureFlags): JSON string with flags
- `PROJECT_ID` (EnvKeys.projectId): Firebase project ID
- `API_KEY` (EnvKeys.apiKey): optional external API key
- `CLIENT_ID` (EnvKeys.clientId): optional client ID
- `OPENAI_BASE_URL`, `OPENAI_MODEL`, `OPENAI_API_KEY`
- `GEMINI_API_KEY`, `GEMINI_MODEL`
- `MAGIC_LINK_CONTINUE_URL`
- `ANDROID_PACKAGE_NAME`, `IOS_BUNDLE_ID`

## Feature Flags Examples
```json
{
  "acfd": true,
  "hazardAlertsEnabled": true,
  "sarParticipationEnabled": true,
  "sarTeamManagementEnabled": false,
  "batterySaverMode": true
}
```

## Sample Run (Planning only; do not run yet)
```bash
flutter run -t lib/main.dart \
  --dart-define=APP_ENV=dev \
  --dart-define=BASE_URL=https://api.redping.app/v1 \
  --dart-define=FEATURE_FLAGS={"acfd":true}
```

## Next Steps
- Mirror `env.dart` in each app or consume a shared core package.
- Decide per-app values (Emergency/SAR may use separate Firebase projects).
