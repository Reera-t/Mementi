#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "🔨 Building Mementi (Release)..."
swift build -c release --product Mementi

APP_DIR="$DIR/Mementi.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating macOS Application Bundle ($APP_DIR)..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy binary
cp "$DIR/.build/release/Mementi" "$MACOS_DIR/Mementi"
chmod +x "$MACOS_DIR/Mementi"

# Generate Info.plist with LSUIElement = true (Menu Bar only, no Dock icon)
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Mementi</string>
    <key>CFBundleIdentifier</key>
    <string>com.mementi.clipboard</string>
    <key>CFBundleName</key>
    <string>Mementi</string>
    <key>CFBundleDisplayName</key>
    <string>Mementi</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "✅ Successfully built Mementi.app!"
echo "📍 Location: $APP_DIR"
echo "🚀 To run: open \"$APP_DIR\""
