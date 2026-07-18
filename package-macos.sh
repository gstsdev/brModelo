#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$SCRIPT_DIR/brModelo.app"
JAR="$SCRIPT_DIR/dist/brModelo.jar"

# Resolve java binary: prefer JAVA_HOME if set, otherwise fall back to PATH.
# This allows users with multiple JDKs to control which one gets baked into the launcher.
JAVA_BIN="${JAVA_HOME:+$JAVA_HOME/bin/}java"

if [ ! -f "$JAR" ]; then
    echo "Error: dist/brModelo.jar not found. Run 'ant jar' first."
    exit 1
fi

if ! command -v "$JAVA_BIN" &>/dev/null; then
    echo "Error: java not found. Set JAVA_HOME or add java to your PATH."
    exit 1
fi

# Resolve to an absolute path so the launcher script works regardless of cwd.
JAVA_BIN="$(command -v "$JAVA_BIN")"
echo "Using Java: $JAVA_BIN"
echo "Creating brModelo.app..."

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
mkdir -p "$APP/Contents/Java"

cp "$JAR" "$APP/Contents/Java/"
# These data files are seeded into ~/Library/Application Support/brModelo on
# first launch so the app can write to them (the bundle itself is read-only
# once installed in /Applications).
cp "$SCRIPT_DIR/Template.brMt" "$APP/Contents/Java/"
cp "$SCRIPT_DIR/Ajuda.brMh" "$APP/Contents/Java/"

# The java binary path is baked in at package time via the outer heredoc (no 'EOF quoting).
# -Xdock:* are macOS-only JVM flags that set the Dock icon and name,
# overriding the default Java coffee-cup icon.
# -Duser.dir redirects System.getProperty("user.dir") away from "/" (the
# default working directory for .app bundles) to a writable location.
cat > "$APP/Contents/MacOS/brModelo" << EOF
#!/bin/bash
SCRIPT_DIR="\$(dirname "\$0")"
APP_DATA="\$HOME/Library/Application Support/brModelo"

mkdir -p "\$APP_DATA"
for f in Template.brMt Ajuda.brMh; do
    [ ! -f "\$APP_DATA/\$f" ] && cp "\$SCRIPT_DIR/../Java/\$f" "\$APP_DATA/\$f" 2>/dev/null
done

"$JAVA_BIN" \\
    -Xdock:icon="\$SCRIPT_DIR/../Resources/brModelo.icns" \\
    -Xdock:name="brModelo" \\
    -Duser.dir="\$APP_DATA" \\
    -jar "\$SCRIPT_DIR/../Java/brModelo.jar"
EOF
chmod +x "$APP/Contents/MacOS/brModelo"

cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>brModelo</string>
    <key>CFBundleDisplayName</key>
    <string>brModelo</string>
    <key>CFBundleIdentifier</key>
    <string>com.sis4.brmodelo</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>brModelo</string>
    <key>CFBundleIconFile</key>
    <string>brModelo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>brModelo Diagram</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>brM3</string>
            </array>
            <key>CFBundleTypeIconFile</key>
            <string>brModelo</string>
            <!-- Owner = this app created the format; macOS will default to it when opening .brM3 files -->
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# sips + iconutil is the macOS-native pipeline for producing .icns files.
# iconutil requires a specifically named iconset directory with exact pixel sizes.
ICON_SRC="$SCRIPT_DIR/src/imagens/icone.png"
ICONSET="/tmp/brModelo.iconset"
mkdir -p "$ICONSET"
for size in 16 32 64 128 256 512; do
    sips -z $size $size "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}.png" &>/dev/null
    double=$((size * 2))
    sips -z $double $double "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}@2x.png" &>/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/brModelo.icns"
rm -rf "$ICONSET"

echo ""
echo "Done! brModelo.app is ready in the project folder."
echo "Drag it to /Applications to install."
