#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
APP_NAME="DisableCtrlClick"
APP_BUNDLE="$APP_NAME.app"
DMG_VOLUME_NAME="$APP_NAME"
DMG_BACKGROUND_IMG="dmg_background.png"
FINAL_DMG_NAME="${APP_NAME}.dmg"

# --- Main Script ---
echo "▶ Creating DMG for $APP_NAME..."

# 0. Build the app
./build.sh

# --- Pre-flight Checks ---
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle '$APP_BUNDLE' not found."
    echo "Please run build.sh first."
    exit 1
fi

# 1. Create a temporary read-write disk image
TEMP_DMG="temp_${FINAL_DMG_NAME}"
rm -f "$TEMP_DMG" "$FINAL_DMG_NAME"
hdiutil create -size 20m -fs HFS+ -volname "$DMG_VOLUME_NAME" "$TEMP_DMG"

# 2. Mount the temporary image
MOUNT_POINT=$(hdiutil attach -nobrowse -noverify -noautofsck "$TEMP_DMG" | grep '/Volumes/' | sed 's/.*\/Volumes\///' | head -n 1)
MOUNT_PATH="/Volumes/$MOUNT_POINT"
sleep 2 # Give a moment for the volume to appear on the system

# 3. Copy files and customize the appearance
echo "▶ Customizing DMG layout... Please wait for 10 seconds..."
cp -R "$APP_BUNDLE" "$MOUNT_PATH/"
ln -s /Applications "$MOUNT_PATH/Applications"

if [ -f "$DMG_BACKGROUND_IMG" ]; then
    echo "Found '$DMG_BACKGROUND_IMG'. Setting as background."
    mkdir "$MOUNT_PATH/.background"
    cp "$DMG_BACKGROUND_IMG" "$MOUNT_PATH/.background/"
    SET_BACKGROUND_COMMAND="set background picture of viewOptions to file \".background:$DMG_BACKGROUND_IMG\""
else
    echo "No background image found. Creating DMG with a standard white background."
    SET_BACKGROUND_COMMAND=""
fi

# Use AppleScript to set the DMG window properties
osascript <<APPLESCRIPT
tell application "Finder"
  -- Use the direct path for reliability
  tell (disk POSIX file "$MOUNT_PATH")
    open
    
    -- **THE DEFINITIVE FIX**
    -- Wait in a loop until Finder can actually see the items.
    -- This prevents the "object not found" race condition.
    with timeout of 10 seconds
        repeat until (exists item "Applications" of container window)
            delay 0.5
        end repeat
    end timeout
    
    -- Now that we know the items exist, we can safely customize the window.
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {400, 100, 800, 320}
    
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    
    $SET_BACKGROUND_COMMAND

    close
    
  end tell
end tell
APPLESCRIPT

# 4. Unmount the temporary image
echo "▶ Unmounting temporary volume..."
hdiutil detach "$MOUNT_PATH" -force

# 5. Convert to a compressed, read-only final DMG
echo "▶ Creating final compressed DMG..."
hdiutil convert "./$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "./$FINAL_DMG_NAME"

# 6. Clean up temporary files
rm -f "./$TEMP_DMG"

echo "✅  Successfully created $FINAL_DMG_NAME"

