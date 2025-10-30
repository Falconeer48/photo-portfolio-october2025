#!/bin/bash

# Create Quick Action for macOS Sequoia
# This creates a proper Automator workflow that works with Sequoia

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

print_status "$BLUE" "🔧 Creating Quick Action for macOS Sequoia..."

QUICK_ACTION_PATH="$HOME/Library/Services/Send to iMac Printer.workflow"

# Create the workflow directory
mkdir -p "$QUICK_ACTION_PATH/Contents"

# Create the Info.plist
cat > "$QUICK_ACTION_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Send to iMac Printer</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSApplicationIdentifier</key>
                <string>com.apple.finder</string>
            </dict>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.pdf</string>
                <string>public.image</string>
                <string>public.jpeg</string>
                <string>public.png</string>
                <string>public.tiff</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create the workflow document
cat > "$QUICK_ACTION_PATH/Contents/document.wflow" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>476</string>
    <key>AMApplicationName</key>
    <string>Automator</string>
    <key>AMApplicationVersion</key>
    <string>2.11</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>actionClass</key>
                <string>AMRunShellScriptAction</string>
                <key>actionWithBundle</key>
                <string>com.apple.Automator.RunShellScript</string>
                <key>isViewVisible</key>
                <integer>0</integer>
                <key>location</key>
                <string>0.000000:0.000000</string>
                <key>nibPath</key>
                <string>AMRunShellScriptAction.nib</string>
            </dict>
            <key>actionBundlePath</key>
            <string>/System/Library/Automator/Run Shell Script.action/Contents/MacOS/Run Shell Script</string>
            <key>actionName</key>
            <string>Run Shell Script</string>
            <key>actionParameters</key>
            <dict>
                <key>COMMAND_STRING</key>
                <string>for f in "$@"; do
    /Users/ian/Scripts/send-to-imac-printer.sh "$f"
done</string>
                <key>CheckedForUserDefaultShell</key>
                <true/>
                <key>COMMAND_STDIN</key>
                <string></string>
                <key>COMMAND_STDOUT</key>
                <string></string>
                <key>COMMAND_STDERR</key>
                <string></string>
                <key>COMMAND_WORKING_DIR</key>
                <string></string>
                <key>COMMAND_SHELL</key>
                <string>/bin/zsh</string>
                <key>COMMAND_AS</key>
                <string>0</string>
                <key>COMMAND_INPUT_METHOD</key>
                <integer>1</integer>
                <key>COMMAND_INPUT_SEPARATOR</key>
                <string></string>
                <key>COMMAND_INPUT_STDIN</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_AS</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_TYPE</key>
                <integer>0</integer>
                <key>COMMAND_INPUT_ARGUMENTS_VALUE</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_CUSTOM_SPEC</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_PASTEBOARD</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_SHELL</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_TEXT</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_URL</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC</key>
                <string></string>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS</key>
                <array/>
            </dict>
            <key>isViewVisible</key>
            <integer>0</integer>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowType</key>
    <string>Service</string>
</dict>
</plist>
EOF

print_status "$GREEN" "✅ Quick Action created for macOS Sequoia"

# Refresh the Services database
print_status "$BLUE" "🔄 Refreshing Services database..."
/System/Library/CoreServices/pbs -flush

print_status "$BLUE" "📋 Next steps:"
print_status "$YELLOW" "1. Wait 30 seconds for macOS to recognize the new service"
print_status "$YELLOW" "2. Go to System Settings → Keyboard → Keyboard Shortcuts → Services"
print_status "$YELLOW" "3. Look for 'Send to iMac Printer' under 'Files and Folders'"
print_status "$YELLOW" "4. Check the box to enable it"
print_status "$YELLOW" "5. Test by right-clicking a PDF file in Finder"

print_status "$GREEN" "✅ Quick Action setup completed for macOS Sequoia!"




