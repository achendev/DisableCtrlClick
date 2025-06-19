#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DisableCtrlClick"
PNG="DisableCtrlClick.png"
APP="$APP_NAME.app"

#–– 1. Generate multi-resolution .icns file from the .png –––––––––––––––
ICONSET="$APP_NAME.iconset"; ICNS="$APP_NAME.icns"
rm -rf "$ICONSET" "$ICNS"; mkdir "$ICONSET"
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
iconutil -c icns "$ICONSET" -o "$ICNS"; rm -rf "$ICONSET"

#–– 2. Compile the Swift source code –––––––––––––––––––––––––––––––––––––
# **FIX:** Added -framework ServiceManagement to link the necessary library.
xcrun swiftc -O -framework Cocoa -framework ServiceManagement -o "$APP_NAME" main.swift

#–– 3. Create the .app bundle structure –––––––––––––––––––––––––––––––––
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv "$APP_NAME" "$APP/Contents/MacOS/"
mv "$ICNS"     "$APP/Contents/Resources/"

#–– 4. Create the Info.plist file ––––––––––––––––––––––––––––––––––––––––
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key>  <string>com.usr.DisableCtrlClick</string>
  <key>CFBundleName</key>        <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key> <string>APPL</string>
  <key>CFBundleVersion</key>     <string>1.0</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundleIconFile</key>    <string>$APP_NAME</string>
  <key>LSUIElement</key>         <true/>
</dict></plist>
PLIST

#–– 5. Ad-hoc sign the application bundle ––––––––––––––––––––––––––––––
codesign --force --deep --sign - "$APP"

echo "✅  $APP built successfully."
echo "Drag to /Applications, launch it. It will be added to 'Open at Login' automatically."
echo "Grant Accessibility and Input Monitoring prompts in System Settings."
