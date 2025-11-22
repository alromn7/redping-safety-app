# 🚁 Two Emulator Testing Guide

## 📱 **Quick Setup for Different Users**

### **Method 1: Quick Setup (Recommended)**

#### **Step 1: Run Regular User (Emulator 1)**
```bash
flutter run -d emulator-5554
```
- **Login**: `user@example.com` / `password123`
- **Role**: Regular SOS user
- **Features**: Send SOS, use E-message widget

#### **Step 2: Run SAR Team Member (Emulator 2)**
```bash
flutter run -d emulator-5556
```
- **Login**: `sar@example.com` / `sar123456`
- **Role**: SAR Team Member (auto-created)
- **Features**: Receive SOS alerts, send SAR responses

### **Method 2: Clear App Data**

If you need to reset one emulator:

```bash
# Clear app data on emulator-5556
adb -s emulator-5556 shell pm clear com.example.redping_14v

# Then run the app
flutter run -d emulator-5556
```

## 🔧 **What Happens Automatically**

### **For SAR Email (`sar@example.com`):**
- ✅ **Auto-creates SAR identity** with verified status
- ✅ **Professional rescuer** type with full credentials
- ✅ **Ready to receive SOS alerts** and respond
- ✅ **Messages section** available on SAR page

### **For Regular Email (`user@example.com`):**
- ✅ **Regular user** with SOS capabilities
- ✅ **E-message widget** for emergency communication
- ✅ **Can send SOS** and receive SAR responses

## 🧪 **Testing Workflow**

### **1. Send SOS from Regular User (Emulator 1)**
1. Go to **SOS Dashboard**
2. Press **SOS Button** (or use Test SOS)
3. Check if alert appears in SAR emulator

### **2. Respond from SAR Team (Emulator 2)**
1. Go to **SAR Page**
2. Check **Messages section**
3. Use **Test Send** button or compose custom message
4. Verify message appears in regular user's E-message

### **3. Test Bidirectional Communication**
- **User → SAR**: Send emergency message from E-message widget
- **SAR → User**: Send response from SAR Messages section
- **Reply System**: Click on messages to reply

## 🎯 **Key Features to Test**

### **SOS Integration**
- [ ] SOS alert appears in SAR page
- [ ] SAR can see user details and location
- [ ] Weather conditions and incident details displayed

### **Messaging System**
- [ ] SAR receives messages from users
- [ ] Users receive SAR responses
- [ ] Message counters update correctly
- [ ] Reply functionality works both ways

### **Message Correlation**
- [ ] Messages are grouped by SOS session
- [ ] Each SOS ticket has separate conversation
- [ ] Message metadata includes session information

## 🐛 **Troubleshooting**

### **Messages Not Appearing**
1. Check debug logs for message flow
2. Verify both emulators are running
3. Check if SAR identity is verified
4. Restart both emulators if needed

### **SAR Identity Issues**
1. Login with `sar@example.com` to auto-create identity
2. Check SAR page for verification status
3. Use Test Send button to verify messaging works

### **Connection Issues**
1. Both emulators should be on same network
2. Check if app data is cleared properly
3. Restart Flutter app on both emulators

## 📋 **Test Scenarios**

### **Scenario 1: Emergency SOS**
1. **User**: Activate SOS with message "Need help, injured"
2. **SAR**: Check SAR page for alert
3. **SAR**: Send response "Help is on the way"
4. **User**: Check E-message for SAR response

### **Scenario 2: Regular Communication**
1. **User**: Send message via E-message widget
2. **SAR**: Check Messages section
3. **SAR**: Reply with status update
4. **User**: Verify reply appears in E-message

### **Scenario 3: Multiple SOS Sessions**
1. **User**: Send multiple SOS alerts
2. **SAR**: Verify each has separate conversation
3. **SAR**: Respond to specific SOS session
4. **User**: Check message correlation

## 🚀 **Quick Commands**

```bash
# Run both emulators
flutter run -d emulator-5554  # Regular user
flutter run -d emulator-5556  # SAR member

# Clear app data if needed
adb -s emulator-5556 shell pm clear com.example.redping_14v

# Check device status
flutter devices
```

## 📱 **User Credentials Summary**

| Emulator | Email | Password | Role | Auto-Features |
|----------|-------|----------|------|---------------|
| 5554 | `user@example.com` | `password123` | Regular User | SOS, E-message |
| 5556 | `sar@example.com` | `sar123456` | SAR Team | Verified SAR identity, Messages |

## 🎉 **Success Indicators**

- ✅ SAR page shows SOS alerts
- ✅ Messages section displays conversations
- ✅ E-message widget shows SAR responses
- ✅ Message counters update correctly
- ✅ Reply functionality works both ways
- ✅ Messages are correlated by SOS session

---

**Happy Testing! 🚁📱**













