# Login Bypass - User Guide

## What is Login Bypass?

Login Bypass is a smart authentication feature that automatically skips the login screen for trusted users on their personal device, while maintaining security through periodic re-authentication.

## How It Works

### For New Users

**First 3 Logins:**
- You must enter your credentials for the first 3 times you use the app
- Each successful login is tracked on your device
- This builds trust between the app and your device

**After 3 Logins:**
- On your 4th app launch and beyond, you'll skip the login screen entirely
- The app will open directly to your main dashboard
- No need to enter email/password each time

### Weekly Re-Authentication

For security purposes, you must re-authenticate at least once per week:
- If 7 days pass since your last login, the next launch will require login
- After re-authenticating, bypass is re-enabled for another 7 days
- This ensures your account remains secure even if your device is lost or stolen

## Device-Specific

Login bypass is tied to your specific device:
- Login count and history are stored locally on your phone
- If you switch to a new device, you'll need to login 3 times again
- This prevents unauthorized access from other devices

## Security Features

✅ **Device-Bound**: Only works on the device where logins occurred
✅ **Time-Limited**: Requires re-authentication every 7 days
✅ **Logout Protection**: Manual logout clears bypass and requires fresh logins
✅ **Session Required**: Must have valid authenticated session first

## Example Scenarios

### Scenario 1: Daily User
**Day 1**: Install app → Login (1/3)
**Day 2**: Open app → Login (2/3)
**Day 3**: Open app → Login (3/3)
**Day 4**: Open app → ✅ **BYPASS** - Goes straight to dashboard
**Day 5-10**: Open app → ✅ **BYPASS** - Goes straight to dashboard
**Day 11** (7+ days later): Open app → Login required (weekly re-auth)
**Day 12+**: Open app → ✅ **BYPASS** - Goes straight to dashboard

### Scenario 2: New Device
**Old Phone**: Have 10 logins, bypass working ✅
**New Phone**: Install app → Login required (1/3)
**New Phone**: Next open → Login required (2/3)
**New Phone**: Next open → Login required (3/3)
**New Phone**: After that → ✅ **BYPASS** activated

### Scenario 3: Logout
**Current**: Have 5 logins, bypass working ✅
**Action**: Manually sign out from settings
**Result**: Login history cleared
**Next Launch**: Must login 3 times again to re-enable bypass

## Frequently Asked Questions

**Q: Why do I need to login 3 times first?**
A: This builds progressive trust. It ensures you're the legitimate owner of the device before enabling auto-login.

**Q: Can I disable bypass and always require login?**
A: Currently no, but you can sign out which clears bypass. Future versions may add this option.

**Q: What happens if someone steals my phone?**
A: They would have 7 days maximum before re-authentication is required. However, they would need to unlock your phone first (device PIN/biometrics).

**Q: Does this work with Google Sign-In?**
A: Yes! Google Sign-In counts toward your 3-login requirement.

**Q: Will I lose bypass if I uninstall the app?**
A: Yes. Uninstalling clears all app data including login history. You'll need to login 3 times again after reinstalling.

**Q: Can I see how many logins I've completed?**
A: Not currently visible in the UI, but it's tracked in the background. After your 3rd successful login, bypass will automatically activate.

**Q: What if I change my password?**
A: Login bypass is independent of your password. Changing your password won't affect bypass status.

## Developer Notes

To adjust bypass behavior, modify constants in `lib/services/auth_service.dart`:

```dart
// Number of successful logins required before bypass activates
static const int _requiredLoginsForBypass = 3;

// Number of days until re-authentication is required
static const int _weeklyReauthDays = 7;
```

**Suggested Configurations:**

- **Maximum Security**: `_requiredLoginsForBypass = 5`, `_weeklyReauthDays = 3`
- **Balanced** (default): `_requiredLoginsForBypass = 3`, `_weeklyReauthDays = 7`
- **Maximum Convenience**: `_requiredLoginsForBypass = 2`, `_weeklyReauthDays = 30`

## Technical Details

**Storage Location**: SharedPreferences (local device storage)

**Stored Data**:
- `login_success_count` - Number of successful logins
- `last_login_timestamp` - ISO8601 timestamp of last login
- `first_login_timestamp` - ISO8601 timestamp of first login
- `device_id` - Unique device identifier

**Privacy**: All data is stored locally on your device and is never sent to servers.

## Troubleshooting

**Problem**: Bypass not working after 3+ logins
- **Solution**: Check that you're authenticated (have valid session)
- **Solution**: Verify less than 7 days have passed since last login
- **Solution**: Check debug logs for bypass rejection reason

**Problem**: Bypass stopped working suddenly
- **Solution**: Check if 7 days have passed (weekly re-auth required)
- **Solution**: Verify you haven't switched devices
- **Solution**: Check if app data was cleared

**Problem**: Want to reset login count for testing
- **Solution**: Sign out from settings
- **Solution**: Or clear app data from Android/iOS settings
- **Solution**: Or delete SharedPreferences data via developer tools

## Version History

- **v1.0** (December 2024): Initial implementation with 3-login threshold and weekly re-auth
