@echo off
setlocal

cd /d %~dp0

echo Running: flutter run --flavor sar -t lib/main_sar.dart %*
flutter run --flavor sar -t lib/main_sar.dart %*
