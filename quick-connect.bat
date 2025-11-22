@echo off
REM Quick WiFi Debug Connect - Double-click to connect your Android device

echo.
echo ========================================
echo   Android WiFi Debug Quick Connect
echo ========================================
echo.

REM Configuration - Update with your device IP
set DEVICE_IP=10.177.98.199
set DEVICE_PORT=5555

echo Connecting to %DEVICE_IP%:%DEVICE_PORT%...
echo.

REM Kill and restart ADB server
adb kill-server >nul 2>&1
timeout /t 1 /nobreak >nul
adb start-server >nul 2>&1
timeout /t 2 /nobreak >nul

REM Connect to device
adb connect %DEVICE_IP%:%DEVICE_PORT%

echo.
echo Connected devices:
adb devices
echo.
echo ========================================
echo.
echo Press any key to close...
pause >nul
