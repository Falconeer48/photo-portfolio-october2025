#!/bin/bash

# Mac Mini VNC Connection Script
# This script connects to Pi5 with proper windowed mode and scaling

# Configuration
PI5_HOST="192.168.50.243"
VNC_PORT="5900"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header "Mac Mini VNC Connection to Pi5"
echo ""

print_status "$BLUE" "Connecting to Pi5 with proper windowed mode..."
print_status "$BLUE" "Host: $PI5_HOST:$VNC_PORT"
echo ""

# Check if TigerVNC is available
if command -v vncviewer >/dev/null 2>&1; then
    print_status "$GREEN" "✅ Using TigerVNC viewer"
    echo ""
    
    print_status "$YELLOW" "Connection settings:"
    print_status "$YELLOW" "• Windowed mode (not fullscreen)"
    print_status "$YELLOW" "• Fit to window scaling"
    print_status "$YELLOW" "• Optimized compression"
    echo ""
    
    # Connect with proper settings
    vncviewer \
        -FullScreen=0 \
        -Scaling=FitToWindow \
        -PreferredEncoding=Tight \
        -CompressLevel=6 \
        -QualityLevel=6 \
        -Geometry=1024x768 \
        "$PI5_HOST:$VNC_PORT"
        
elif [ -d "/Applications/VNC Viewer.app" ]; then
    print_status "$GREEN" "✅ Using RealVNC Viewer"
    echo ""
    
    print_status "$YELLOW" "Opening RealVNC Viewer..."
    print_status "$YELLOW" "Note: You may need to adjust settings in the VNC Viewer app"
    echo ""
    
    # Open RealVNC Viewer
    open -a "VNC Viewer" "vnc://$PI5_HOST:$VNC_PORT"
    
elif [ -d "/System/Library/CoreServices/Screen Sharing.app" ]; then
    print_status "$GREEN" "✅ Using built-in Screen Sharing"
    echo ""
    
    print_status "$YELLOW" "Opening Screen Sharing..."
    print_status "$YELLOW" "Note: You may need to adjust scaling in Screen Sharing preferences"
    echo ""
    
    # Open Screen Sharing
    open "vnc://$PI5_HOST:$VNC_PORT"
    
else
    print_status "$RED" "❌ No VNC client found"
    echo ""
    print_status "$YELLOW" "Please install a VNC client:"
    print_status "$YELLOW" "• TigerVNC: brew install tigervnc"
    print_status "$YELLOW" "• RealVNC: Download from https://www.realvnc.com/"
    exit 1
fi

echo ""
print_status "$GREEN" "✅ VNC connection initiated!"
echo ""

print_status "$BLUE" "If you still experience scaling issues:"
print_status "$BLUE" "1. Try the windowed connection script: ~/connect-vnc-windowed.sh"
print_status "$BLUE" "2. Try the custom resolution script: ~/connect-vnc-custom.sh"
print_status "$BLUE" "3. Check VNC client preferences for scaling options"
echo ""

