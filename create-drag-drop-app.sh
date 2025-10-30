#!/bin/bash

# Create a drag & drop app for printing to iMac

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status "$BLUE" "🔧 Creating drag & drop app for printing to iMac..."

APP_PATH="$HOME/Applications/Print to iMac.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the app bundle
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>print-to-imac</string>
    <key>CFBundleIdentifier</key>
    <string>com.ian.print-to-imac</string>
    <key>CFBundleName</key>
    <string>Print to iMac</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>PDF and Images</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.pdf</string>
                <string>public.image</string>
                <string>public.jpeg</string>
                <string>public.png</string>
                <string>public.tiff</string>
            </array>
            <key>LSRoleHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create the executable script
cat > "$APP_PATH/Contents/MacOS/print-to-imac" << EOF
#!/bin/bash

# Print to iMac drag & drop app
SCRIPT_DIR="$SCRIPT_DIR"

# If no arguments, show usage
if [ \$# -eq 0 ]; then
    osascript -e 'display dialog "Drag and drop PDF files onto this app to print them on your iMac printer!" buttons {"OK"} default button "OK"'
    exit 0
fi

# Process each dropped file
for file in "\$@"; do
    if [ -f "\$file" ]; then
        filename=\$(basename "\$file")
        osascript -e "display dialog \"Printing \$filename on iMac...\" buttons {\"OK\"} default button \"OK\" giving up after 2"
        "\$SCRIPT_DIR/send-to-imac-printer.sh" "\$file"
    fi
done

osascript -e 'display dialog "Print job(s) sent to iMac!" buttons {"OK"} default button "OK"'
EOF

# Make executable
chmod +x "$APP_PATH/Contents/MacOS/print-to-imac"

print_status "$GREEN" "✅ Drag & drop app created: $APP_PATH"
print_status "$BLUE" "📋 Usage:"
print_status "$YELLOW" "1. Drag any PDF file onto the 'Print to iMac' app"
print_status "$YELLOW" "2. The file will be sent to iMac and printed automatically"
print_status "$YELLOW" "3. You'll see a confirmation dialog"

print_status "$GREEN" "✅ Drag & drop app setup completed!"



