#!/bin/bash
echo "Building..."
cd PumpCheck.swiftpm

# Run xcodebuild and capture the exit status. We don't hide errors anymore.
xcodebuild -scheme PumpCheck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath ../build
BUILD_STATUS=$?

cd ..

if [ $BUILD_STATUS -ne 0 ]; then
    echo "❌ Build failed! Not installing to simulator."
    exit 1
fi

echo "✅ Build successful! Installing to simulator..."
APP_PATH=$(find build/Build/Products -name "*.app" | head -n 1)

if [ -n "$APP_PATH" ]; then
    # Forcefully kill the running app
    xcrun simctl terminate booted com.pumpcheck.app 2>/dev/null
    
    # Uninstall the old app to ensure a 100% fresh cache
    xcrun simctl uninstall booted com.pumpcheck.app 2>/dev/null
    
    # Install the fresh build
    xcrun simctl install booted "$APP_PATH"
    
    # Launch it!
    xcrun simctl launch booted com.pumpcheck.app
    echo "🚀 Successfully launched on Simulator!"
else
    echo "❌ App not found in build directory!"
    exit 1
fi
