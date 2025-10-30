#!/bin/bash

# VNC Client Test Script for Mac Mini
# This script tests VNC connection to Pi 5 and provides connection options

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="192.168.50.243"
VNC_PORT="5900"
VNC_DISPLAY=":0"

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_status "$BLUE" "=========================================="
    print_status "$BLUE" "$1"
    print_status "$BLUE" "=========================================="
}

print_header "VNC Client Test for Mac Mini"
echo ""

# 1. Check Pi5 connectivity
print_header "1. Testing Pi5 Connectivity"
print_status "$BLUE" "Pinging Pi5..."

if ping -c 1 -W 3 "$PI5_HOST" >/dev/null 2>&1; then
    print_status "$GREEN" "✅ Pi5 is reachable"
else
    print_status "$RED" "❌ Cannot ping Pi5"
    exit 1
fi

# 2. Check VNC port
print_header "2. Testing VNC Port"
print_status "$BLUE" "Testing VNC port $VNC_PORT..."

if nc -z -w 3 "$PI5_HOST" "$VNC_PORT" 2>/dev/null; then
    print_status "$GREEN" "✅ VNC port $VNC_PORT is open"
else
    print_status "$RED" "❌ VNC port $VNC_PORT is not accessible"
    print_status "$YELLOW" "💡 Make sure VNC server is running on Pi5"
    exit 1
fi

# 3. Check VNC client availability
print_header "3. Checking VNC Client Availability"
print_status "$BLUE" "Checking for VNC clients..."

# Check for TigerVNC
if command -v vncviewer >/dev/null 2>&1; then
    print_status "$GREEN" "✅ TigerVNC viewer is installed"
    VNCVIEWER_VERSION=$(vncviewer -version 2>&1 | head -1)
    print_status "$BLUE" "   Version: $VNCVIEWER_VERSION"
else
    print_status "$YELLOW" "⚠️  TigerVNC viewer not found"
    print_status "$YELLOW" "💡 Install with: brew install tigervnc"
fi

# Check for built-in Screen Sharing
if [ -d "/System/Library/CoreServices/Screen Sharing.app" ]; then
    print_status "$GREEN" "✅ Built-in Screen Sharing is available"
else
    print_status "$YELLOW" "⚠️  Built-in Screen Sharing not found"
fi

# Check for RealVNC Viewer
if [ -d "/Applications/VNC Viewer.app" ]; then
    print_status "$GREEN" "✅ RealVNC Viewer is installed"
else
    print_status "$BLUE" "ℹ️  RealVNC Viewer not installed (optional)"
fi

# 4. Test VNC connection
print_header "4. Testing VNC Connection"
print_status "$BLUE" "Testing VNC connection..."

if command -v vncviewer >/dev/null 2>&1; then
    print_status "$BLUE" "Testing with TigerVNC viewer..."
    
    # Test connection (non-interactive)
    if timeout 10 vncviewer -list "$PI5_HOST:$VNC_PORT" >/dev/null 2>&1; then
        print_status "$GREEN" "✅ VNC connection test successful"
    else
        print_status "$RED" "❌ VNC connection test failed"
    fi
else
    print_status "$YELLOW" "⚠️  Cannot test connection - VNC viewer not available"
fi

# 5. Display connection options
print_header "5. VNC Connection Options"
print_status "$GREEN" "✅ VNC server is accessible!"
echo ""
print_status "$BLUE" "Choose your preferred connection method:"
echo ""

# Option 1: TigerVNC command line
if command -v vncviewer >/dev/null 2>&1; then
    print_status "$GREEN" "1. TigerVNC Command Line:"
    print_status "$BLUE" "   vncviewer $PI5_HOST:$VNC_PORT"
    echo ""
fi

# Option 2: Built-in Screen Sharing
if [ -d "/System/Library/CoreServices/Screen Sharing.app" ]; then
    print_status "$GREEN" "2. Built-in Screen Sharing:"
    print_status "$BLUE" "   open vnc://$PI5_HOST:$VNC_PORT"
    print_status "$BLUE" "   Or use Finder → Go → Connect to Server → vnc://$PI5_HOST:$VNC_PORT"
    echo ""
fi

# Option 3: RealVNC Viewer
if [ -d "/Applications/VNC Viewer.app" ]; then
    print_status "$GREEN" "3. RealVNC Viewer:"
    print_status "$BLUE" "   Open VNC Viewer app and connect to: $PI5_HOST:$VNC_PORT"
    echo ""
fi

# Option 4: Manual connection
print_status "$GREEN" "4. Manual Connection:"
print_status "$BLUE" "   Server: $PI5_HOST"
print_status "$BLUE" "   Port: $VNC_PORT"
print_status "$BLUE" "   Display: $VNC_DISPLAY"
echo ""

# 6. Resolution troubleshooting
print_header "6. Resolution Troubleshooting"
print_status "$BLUE" "If you experience resolution issues:"
echo ""
print_status "$YELLOW" "Common solutions:"
print_status "$YELLOW" "1. Use fullscreen mode in VNC client"
print_status "$YELLOW" "2. Set specific resolution: ssh ian@$PI5_HOST 'xrandr --output HDMI-1 --mode 1920x1080'"
print_status "$YELLOW" "3. Restart VNC server: ssh ian@$PI5_HOST 'sudo systemctl restart vncserver@:0'"
print_status "$YELLOW" "4. Check Pi5 display settings: ssh ian@$PI5_HOST 'xrandr'"
echo ""

# 7. Performance tips
print_header "7. Performance Tips"
print_status "$BLUE" "For better VNC performance:"
echo ""
print_status "$YELLOW" "• Use wired Ethernet connection when possible"
print_status "$YELLOW" "• Close unnecessary applications on Pi5"
print_status "$YELLOW" "• Use lower color depth if needed"
print_status "$YELLOW" "• Consider using SSH tunneling for security"
echo ""

# 8. Quick connect function
print_header "8. Quick Connect"
print_status "$GREEN" "Ready to connect!"
echo ""
print_status "$BLUE" "Quick connect commands:"
echo ""

# Create quick connect commands
if command -v vncviewer >/dev/null 2>&1; then
    print_status "$GREEN" "TigerVNC:"
    print_status "$BLUE" "vncviewer $PI5_HOST:$VNC_PORT"
    echo ""
fi

if [ -d "/System/Library/CoreServices/Screen Sharing.app" ]; then
    print_status "$GREEN" "Screen Sharing:"
    print_status "$BLUE" "open vnc://$PI5_HOST:$VNC_PORT"
    echo ""
fi

# 9. Interactive connection option
print_header "9. Interactive Connection"
echo ""
read -p "Would you like to connect now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "$BLUE" "Starting VNC connection..."
    
    if command -v vncviewer >/dev/null 2>&1; then
        print_status "$GREEN" "Connecting with TigerVNC..."
        vncviewer "$PI5_HOST:$VNC_PORT"
    elif [ -d "/System/Library/CoreServices/Screen Sharing.app" ]; then
        print_status "$GREEN" "Connecting with Screen Sharing..."
        open "vnc://$PI5_HOST:$VNC_PORT"
    else
        print_status "$RED" "❌ No VNC client available"
        print_status "$YELLOW" "Please install a VNC client first"
    fi
else
    print_status "$BLUE" "Connection cancelled"
fi

print_header "VNC Client Test Complete"
print_status "$GREEN" "✅ VNC client test completed!"
echo ""







