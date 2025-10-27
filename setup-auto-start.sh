#!/bin/bash

# Setup script to make PDF printer monitor start automatically on iMac boot
# This creates a LaunchAgent that starts the monitor when iMac boots

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🚀 Setting up auto-start for PDF printer monitor..."

# Create LaunchAgent plist file
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.ian.pdf-printer-monitor.plist"
SCRIPT_PATH="$HOME/Scripts/print-pdf-manual.sh"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENT_DIR"

# Create the LaunchAgent plist
cat > "$LAUNCH_AGENT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ian.pdf-printer-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_PATH</string>
        <string>--background</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/IncomingPrints/printer-monitor.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/IncomingPrints/printer-monitor-error.log</string>
    <key>WorkingDirectory</key>
    <string>$HOME/IncomingPrints</string>
</dict>
</plist>
EOF

print_status $GREEN "✅ LaunchAgent created: $LAUNCH_AGENT_FILE"

# Load the LaunchAgent
launchctl load "$LAUNCH_AGENT_FILE"

print_status $GREEN "✅ LaunchAgent loaded successfully"

# Check if it's running
if launchctl list | grep -q "com.ian.pdf-printer-monitor"; then
    print_status $GREEN "✅ PDF printer monitor is now running"
else
    print_status $YELLOW "⚠️  PDF printer monitor may not be running yet"
fi

print_status $BLUE "📋 Auto-start setup completed!"
print_status $YELLOW "💡 The PDF printer monitor will now start automatically when you boot your iMac"
print_status $YELLOW "💡 To stop it: launchctl unload $LAUNCH_AGENT_FILE"
print_status $YELLOW "💡 To start it: launchctl load $LAUNCH_AGENT_FILE"
print_status $YELLOW "💡 To check status: launchctl list | grep pdf-printer"
