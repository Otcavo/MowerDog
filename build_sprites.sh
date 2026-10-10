#!/bin/bash
# Builds MowerDog.saver from the Sources and Sprites folders,
# then installs it. Requires Apple's Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

NAME="MowerDog"
BUNDLE="$NAME.saver"

# 1. Create the bundle folder structure
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

# 2. Compile every Swift file in the Sources folder together
swiftc -emit-library -module-name "$NAME" -O \
  -framework ScreenSaver -framework AppKit -framework SpriteKit \
  -o "$BUNDLE/Contents/MacOS/$NAME" \
  Sources/*.swift

# 3. Copy your sprite images (PNG files in the Sprites folder)
if [ -d Sprites ]; then
  cp Sprites/*.png "$BUNDLE/Contents/Resources/" 2>/dev/null || true
fi

# 4. Write the Info.plist
cat > "$BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$NAME</string>
    <key>CFBundleIdentifier</key>
    <string>io.github.otcavo.$NAME</string>
    <key>CFBundleName</key>
    <string>$NAME</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>SpriteSaverView</string>
</dict>
</plist>
EOF

# 5. Sign it locally so macOS will load it
codesign --force --sign - "$BUNDLE"

# 6. Install into your user's Screen Savers folder
mkdir -p "$HOME/Library/Screen Savers"
rm -rf "$HOME/Library/Screen Savers/$BUNDLE"
cp -R "$BUNDLE" "$HOME/Library/Screen Savers/"

# Make macOS reload screensavers in case an older version was cached
killall legacyScreenSaver 2>/dev/null || true

echo "Installed $BUNDLE. Quit and reopen System Settings, then choose it under Screen Saver."
