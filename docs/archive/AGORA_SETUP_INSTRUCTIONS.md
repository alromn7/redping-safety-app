# Agora WebRTC Setup Instructions

## ⚠️ CRITICAL: Fix "Invalid Token" Error

If you see this error:
```
⛔ WebRTC: Error ErrorCodeType.errInvalidToken
```

You MUST disable the App Certificate in your Agora project.

## Step-by-Step Fix

### 1. Login to Agora Console
- Go to: https://console.agora.io/
- Login with your account

### 2. Find Your Project
- Click on **"Project Management"** in the left sidebar
- Locate your project (App ID: `a4d1ae536fb44710aa2c19d825f79ddb`)

### 3. Disable App Certificate
- Click **"Config"** or **"Edit"** button next to your project
- Scroll down to find **"Primary Certificate"** or **"App Certificate"** section
- You'll see a toggle switch labeled **"Enabled"**
- **Turn it OFF** (set to disabled/grey)
- Click **"Save"** or **"Update"**

### 4. Restart Your App
- Stop the Flutter app completely
- Run `flutter run --hot` again
- The WebRTC calls should now work without the token error

## Why This Is Needed

- **Testing Mode**: Empty token (`''`) only works when App Certificate is DISABLED
- **Production Mode**: When App Certificate is ENABLED, you need a valid token from a token server
- **Current Setup**: We're using testing mode (no token server) so certificate must be disabled

## For Production Deployment

When ready for production:

1. **Enable App Certificate** in Agora Console
2. **Implement Token Server**:
   - Backend service to generate Agora tokens
   - Tokens should expire after reasonable time (e.g., 24 hours)
   - Generate token per call/channel
3. **Update Code**:
   ```dart
   await _engine!.joinChannel(
     token: await _fetchTokenFromServer(channelName, userId),
     channelId: channelName,
     // ... rest of options
   );
   ```

## Additional Resources

- [Agora Token Authentication Guide](https://docs.agora.io/en/video-calling/develop/authentication-workflow)
- [Agora Token Generator](https://github.com/AgoraIO/Tools/tree/master/DynamicKey/AgoraDynamicKey)
- [Token Server Examples](https://github.com/AgoraIO-Community/agora-token-service)

## Current App ID

```
App ID: a4d1ae536fb44710aa2c19d825f79ddb
```

Make sure this matches the App ID in Agora Console where you're disabling the certificate.

## Verification

After disabling App Certificate:
1. Open SOS page in app
2. Scroll to "Test WebRTC Emergency Call" card (blue card)
3. Tap "Test Call"
4. You should see success dialog with channel name
5. No "invalid token" error in logs

If still seeing errors, verify:
- Correct App ID is being used
- App Certificate is truly disabled (not just hidden)
- App was fully restarted after change
- Internet connection is working
