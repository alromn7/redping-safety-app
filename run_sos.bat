@echo off
setlocal

cd /d %~dp0

echo Running: flutter run --flavor sos -t lib/main_sos.dart %*
flutter run --flavor sos -t lib/main_sos.dart %*
