#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DisableCtrlClick"
PNG="DisableCtrlClick.png"
APP="$APP_NAME.app"
MACOS_TARGET="10.15"

#–– 1. Generate multi-resolution .icns file from the .png –––––––––––––––
ICONSET="$APP_NAME.iconset"; ICNS="$APP_NAME.icns"

# Clean up previous iconset directory and file
if [ -d "$ICONSET" ]; then
    rm -f "$ICONSET"/*.png
    rmdir "$ICONSET"
fi
rm -f "$ICNS"
mkdir "$ICONSET"

sips -z 16 16     "$PNG" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$PNG" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$PNG" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$PNG" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$PNG" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$PNG" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$PNG" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$PNG" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$ICNS"

# Clean up temporary iconset directory
rm -f "$ICONSET"/*.png
rmdir "$ICONSET"

#–– 2. Create the .app bundle structure –––––––––––––––––––––––––––––––––
# Clean up previous build if it exists, without using rm -rf
if [ -d "$APP" ]; then
    rm -f "$APP/Contents/_CodeSignature/CodeResources"
    rmdir "$APP/Contents/_CodeSignature" 2>/dev/null || true
    rm -f "$APP/Contents/MacOS/$APP_NAME"
    rmdir "$APP/Contents/MacOS" 2>/dev/null || true
    rm -f "$APP/Contents/Resources/$ICNS"
    rmdir "$APP/Contents/Resources" 2>/dev/null || true
    rm -f "$APP/Contents/Info.plist"
    rmdir "$APP/Contents" 2>/dev/null || true
    rmdir "$APP" 2>/dev/null || true
fi
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv "$ICNS" "$APP/Contents/Resources/"

#–– 3. Compile Swift source for each architecture –––––––––––––––––––––––
echo "▶ Compiling for Intel (x86_64)..."
APP_NAME_X86_64="${APP_NAME}_x86_64"
xcrun swiftc -O -target "x86_64-apple-macosx${MACOS_TARGET}" \
  -framework Cocoa -framework ServiceManagement \
  -o "$APP_NAME_X86_64" main.swift

echo "▶ Compiling for Apple Silicon (arm64)..."
APP_NAME_ARM64="${APP_NAME}_arm64"
xcrun swiftc -O -target "arm64-apple-macosx${MACOS_TARGET}" \
  -framework Cocoa -framework ServiceManagement \
  -o "$APP_NAME_ARM64" main.swift

#–– 4. Create Universal Binary with lipo –––––––––––––––––––––––––––––––
echo "▶ Creating Universal Binary..."
lipo -create "$APP_NAME_X86_64" "$APP_NAME_ARM64" \
  -output "$APP/Contents/MacOS/$APP_NAME"
rm -f "$APP_NAME_X86_64" "$APP_NAME_ARM64"

#–– 5. Create the Info.plist file ––––––––––––––––––––––––––––––––––––––––
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key>  <string>com.usr.DisableCtrlClick</string>
  <key>CFBundleName</key>        <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key> <string>APPL</string>
  <key>CFBundleVersion</key>     <string>1.2</string>
  <key>CFBundleShortVersionString</key> <string>1.2</string>
  <key>LSMinimumSystemVersion</key><string>$MACOS_TARGET</string>
  <key>CFBundleIconFile</key>    <string>$APP_NAME</string>
  <key>LSUIElement</key>         <true/>
</dict></plist>
PLIST

#–– 6. Ad-hoc sign the application bundle ––––––––––––––––––––––––––––––
codesign --force --deep --sign - "$APP"

echo "✅  $APP built successfully for macOS $MACOS_TARGET+ (Universal)."
echo "Drag to /Applications, launch it. It will be added to 'Open at Login' automatically."
echo "Grant Accessibility and Input Monitoring prompts in System Settings."