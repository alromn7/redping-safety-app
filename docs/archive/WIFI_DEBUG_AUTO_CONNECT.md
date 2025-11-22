# 📱 WiFi Debugging Auto-Connect Setup

Automatically connect to your Android device via WiFi debugging when on the same network.

---

## 🚀 Quick Start (Easiest Method)

### Option 1: Double-Click Batch File (Simplest)

**Just double-click**: `quick-connect.bat`

This will:
- Restart ADB server
- Connect to your device at `10.177.98.199:5555`
- Show connected devices

**✏️ To customize**: Edit `quick-connect.bat` and change the IP/port if needed.

---

## ⚙️ Automatic Connection Setup

### Option 2: Auto-Connect on Login (Recommended)

**Run once as Administrator**:

1. Right-click **PowerShell** → **Run as Administrator**
2. Navigate to this folder:
   ```powershell
   cd C:\flutterapps\redping_14v
   ```
3. Run setup:
   ```powershell
   .\setup-wifi-auto-connect.ps1
   ```

This creates a scheduled task that automatically connects your device when you log in to Windows.

---

## 🔧 Manual Connection (PowerShell)

### Option 3: Manual Script Execution

Run whenever you want to connect:

```powershell
.\auto-connect-wifi-debug.ps1
```

---

## 📝 Initial Setup on Android Device

### Step 1: Enable Developer Options
1. Settings → About Phone
2. Tap **Build Number** 7 times
3. Enter your PIN/password

### Step 2: Enable WiFi Debugging
1. Settings → **Developer Options**
2. Enable **Wireless debugging**
3. Tap on **Wireless debugging** to open settings
4. Note the **IP address & Port** (e.g., `10.177.98.199:5555`)

### Step 3: First-Time Pairing (If Required)

If you see "Pair device with pairing code":

1. On your phone: Tap **"Pair device with pairing code"**
2. Note the **6-digit code** and **IP:PORT** shown
3. On your PC, run:
   ```powershell
   adb pair <IP:PORT>
   # Example: adb pair 10.177.98.199:37852
   ```
4. Enter the 6-digit code when prompted
5. After pairing succeeds, run the quick-connect script

---

## 🔄 Updating Device IP Address

If your device IP changes (different WiFi network, router DHCP):

### Update quick-connect.bat:
```batch
set DEVICE_IP=10.177.98.199    ← Change this
set DEVICE_PORT=5555           ← Change this if needed
```

### Update auto-connect-wifi-debug.ps1:
```powershell
$DEVICE_IP = "10.177.98.199"   ← Change this
$DEVICE_PORT = "5555"          ← Change this if needed
```

---

## 🐛 Troubleshooting

### "Cannot connect" error

**Check these**:
1. ✅ WiFi debugging is **ON** on your phone
2. ✅ Phone and PC are on the **same WiFi network**
3. ✅ Firewall is not blocking ADB (port 5555)
4. ✅ IP address is correct (check on phone)

### Connection keeps dropping

**Solutions**:
- Disable WiFi power saving on phone
- Assign static IP to phone in router settings
- Use USB connection for stable debugging

### "ADB not found" error

**Install Android SDK Platform Tools**:
1. Download from: https://developer.android.com/studio/releases/platform-tools
2. Extract to: `C:\platform-tools`
3. Add to PATH:
   - Settings → System → About → Advanced system settings
   - Environment Variables → System variables → Path → Edit
   - Add: `C:\platform-tools`
4. Restart PowerShell/Command Prompt

---

## 📁 Files Overview

| File | Purpose | When to Use |
|------|---------|-------------|
| **quick-connect.bat** | Quick double-click connect | Daily use |
| **auto-connect-wifi-debug.ps1** | Manual PowerShell connect | When needed |
| **setup-wifi-auto-connect.ps1** | Install auto-connect task | One-time setup |
| **WIFI_DEBUG_AUTO_CONNECT.md** | This documentation | Reference |

---

## ✅ Verification

After connecting, verify with:

```powershell
adb devices
```

You should see:
```
List of devices attached
10.177.98.199:5555    device
```

If you see:
- **`offline`** - Restart WiFi debugging on phone
- **`unauthorized`** - Check phone for authorization prompt
- **Nothing** - Connection failed, check WiFi and IP

---

## 🚀 Using with Flutter

Once connected, run your Flutter app:

```powershell
# Check available devices
flutter devices

# Run on WiFi-connected device
flutter run -d 10.177.98.199:5555

# Or if it's the only device
flutter run
```

---

## 🔒 Security Notes

- WiFi debugging only works on **trusted WiFi networks**
- Don't enable WiFi debugging on public WiFi
- Device must **authorize each connection** (check phone for prompt)
- Pairing codes expire after use (need new code each time)

---

## 💡 Pro Tips

### Create Desktop Shortcut (Windows)

1. Right-click Desktop → New → Shortcut
2. Location: 
   ```
   C:\flutterapps\redping_14v\quick-connect.bat
   ```
3. Name: **Connect Android WiFi**
4. Change icon (optional):
   - Right-click shortcut → Properties → Change Icon
   - Browse to: `%SystemRoot%\System32\shell32.dll`
   - Choose an icon

### Add to Windows Terminal

Add to `settings.json`:
```json
{
  "name": "Connect Android WiFi",
  "commandline": "powershell.exe -ExecutionPolicy Bypass -File C:/flutterapps/redping_14v/auto-connect-wifi-debug.ps1",
  "icon": "📱"
}
```

---

## 🎯 Current Configuration

**Device IP**: `10.177.98.199`  
**Port**: `5555`  
**Full Address**: `10.177.98.199:5555`

✏️ Edit the script files if your device uses different values.

---

**Last Updated**: October 27, 2025  
**Tested On**: Windows 11, Android 14, ADB v34+
