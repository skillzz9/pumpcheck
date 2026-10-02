echo "Building..."
cd PumpCheck.swiftpm
xcodebuild -scheme PumpCheck -destination 'platform=iOS Simulator,id=E8522386-D9C4-49CE-A6D1-BD717AD8A14E' -derivedDataPath ../build > /dev/null
cd ..
echo "Installing to simulator..."
APP_PATH=$(find build/Build/Products -name "*.app" | head -n 1)
if [ -n "$APP_PATH" ]; then
    xcrun simctl install booted "$APP_PATH"
    xcrun simctl launch booted com.pumpcheck.app
    echo "Launched!"
else
    echo "App not found! Build failed?"
fi
