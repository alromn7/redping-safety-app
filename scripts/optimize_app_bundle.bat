@echo off
REM REDP!NG App Bundle Optimization Script for Windows
REM Optimizes the app for Google Play Console App Bundle requirements

echo 🚀 Starting REDP!NG App Bundle Optimization...

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Analyze dependencies
echo 📊 Analyzing dependencies...
flutter pub deps

REM Run code analysis
echo 🔍 Running code analysis...
flutter analyze

REM Build App Bundle with optimizations
echo 📦 Building optimized App Bundle...
flutter build appbundle ^
    --release ^
    --target-platform android-arm,android-arm64,android-x64 ^
    --split-per-abi ^
    --obfuscate ^
    --split-debug-info=build/app/outputs/symbols ^
    --tree-shake-icons

echo ✅ App Bundle optimization complete!
echo 📁 Output files:
echo    - App Bundle: build/app/outputs/bundle/release/app-release.aab
echo    - Symbols: build/app/outputs/symbols/

REM Display bundle size
echo 📏 Bundle size analysis:
dir build\app\outputs\bundle\release\app-release.aab

