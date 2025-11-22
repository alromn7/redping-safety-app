#!/bin/bash

# REDP!NG App Bundle Optimization Script
# Optimizes the app for Google Play Console App Bundle requirements

echo "🚀 Starting REDP!NG App Bundle Optimization..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Analyze dependencies
echo "📊 Analyzing dependencies..."
flutter pub deps

# Run code analysis
echo "🔍 Running code analysis..."
flutter analyze

# Build App Bundle with optimizations
echo "📦 Building optimized App Bundle..."
flutter build appbundle \
    --release \
    --target-platform android-arm,android-arm64,android-x64 \
    --split-per-abi \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols \
    --tree-shake-icons

# Generate App Bundle report
echo "📋 Generating App Bundle report..."
bundletool build-apks \
    --bundle=build/app/outputs/bundle/release/app-release.aab \
    --output=build/app/outputs/bundle/release/app-release.apks \
    --mode=universal

echo "✅ App Bundle optimization complete!"
echo "📁 Output files:"
echo "   - App Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "   - APKs: build/app/outputs/bundle/release/app-release.apks"
echo "   - Symbols: build/app/outputs/symbols/"

# Display bundle size
echo "📏 Bundle size analysis:"
du -h build/app/outputs/bundle/release/app-release.aab

