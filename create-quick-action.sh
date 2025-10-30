#!/bin/bash

# Create Quick Action for Finder integration
# This creates an Automator Quick Action that can be used from Finder

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

print_status "$BLUE" "🔧 Creating Quick Action for Finder integration..."

# Create the Quick Action workflow
QUICK_ACTION_PATH="$HOME/Library/Services/Send to iMac Printer.workflow"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$QUICK_ACTION_PATH")"

# Create the Automator workflow XML
cat > "/tmp/Send to iMac Printer.workflow" << 'EOF'
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

# Create the workflow directory structure
mkdir -p "$QUICK_ACTION_PATH/Contents"
cp "/tmp/Send to iMac Printer.workflow" "$QUICK_ACTION_PATH/Contents/Info.plist"
rm "/tmp/Send to iMac Printer.workflow"

# Create the main script
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
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_0</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_1</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_2</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_3</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_4</key>
                    <dict>
                        <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                        <string></string>
                        <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                        <string></string>
                    </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_5</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_6</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_7</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_8</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
                <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPECS_9</key>
                <dict>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_NAME</key>
                    <string></string>
                    <key>COMMAND_INPUT_ARGUMENTS_VARIABLE_SPEC_VALUE</key>
                    <string></string>
                </dict>
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

print_status "$GREEN" "✅ Quick Action created: $QUICK_ACTION_PATH"

print_status "$BLUE" "📋 To use the Quick Action:"
print_status "$YELLOW" "1. Right-click any PDF or image file in Finder"
print_status "$YELLOW" "2. Select 'Quick Actions' → 'Send to iMac Printer'"
print_status "$YELLOW" "3. The file will be sent to iMac and printed automatically"

print_status "$GREEN" "✅ Quick Action setup completed!"




