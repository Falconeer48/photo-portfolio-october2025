#!/bin/bash

# Connect to Pi5 VNC via Mac Mini
# This script helps you SSH from Windows 11 to Mac Mini and connect to Pi5 VNC

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_header "Connect to Pi5 VNC via Mac Mini"
echo ""

# Configuration - Update these with your Mac Mini details
MAC_MINI_HOST="192.168.50.XXX"  # Replace with your Mac Mini IP
MAC_MINI_USER="your_username"   # Replace with your Mac Mini username
PI5_HOST="192.168.50.243"
PI5_VNC_PORT="5901"  # Updated to use display :1

print_status "$YELLOW" "Before running this script, please update:"
print_status "$YELLOW" "1. MAC_MINI_HOST with your Mac Mini IP address"
print_status "$YELLOW" "2. MAC_MINI_USER with your Mac Mini username"
echo ""

read -p "Have you updated the configuration? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "$RED" "Please update the configuration first"
    print_status "$BLUE" "Edit this script and update:"
    print_status "$BLUE" "  MAC_MINI_HOST=\"192.168.50.XXX\""
    print_status "$BLUE" "  MAC_MINI_USER=\"your_username\""
    exit 1
fi

print_header "Step 1: Test SSH Connection to Mac Mini"
print_status "$BLUE" "Testing SSH connection to Mac Mini..."

if ssh -o ConnectTimeout=10 "$MAC_MINI_USER@$MAC_MINI_HOST" "echo 'SSH connection successful'"; then
    print_status "$GREEN" "✅ SSH connection to Mac Mini successful"
else
    print_status "$RED" "❌ SSH connection to Mac Mini failed"
    print_status "$YELLOW" "Please check:"
    print_status "$YELLOW" "• Mac Mini IP address: $MAC_MINI_HOST"
    print_status "$YELLOW" "• Username: $MAC_MINI_USER"
    print_status "$YELLOW" "• SSH is enabled on Mac Mini (System Preferences > Sharing > Remote Login)"
    print_status "$YELLOW" "• SSH key authentication or password"
    exit 1
fi

print_header "Step 2: Check VNC Client on Mac Mini"
print_status "$BLUE" "Checking available VNC clients on Mac Mini..."

VNC_CLIENTS=$(ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
    if command -v vncviewer >/dev/null 2>&1; then
        echo 'TigerVNC: Available'
    fi
    if [ -d '/Applications/VNC Viewer.app' ]; then
        echo 'RealVNC: Available'
    fi
    if [ -d '/System/Library/CoreServices/Screen Sharing.app' ]; then
        echo 'Screen Sharing: Available'
    fi
")

if [ -n "$VNC_CLIENTS" ]; then
    print_status "$GREEN" "✅ Available VNC clients on Mac Mini:"
    echo "$VNC_CLIENTS" | while read -r client; do
        print_status "$GREEN" "   📱 $client"
    done
else
    print_status "$YELLOW" "⚠️  No VNC clients found on Mac Mini"
    print_status "$YELLOW" "Installing TigerVNC..."
    ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "brew install tigervnc"
fi

print_header "Step 3: Connect to Pi5 VNC"
print_status "$BLUE" "Connecting to Pi5 VNC from Mac Mini..."
print_status "$BLUE" "Pi5 VNC: $PI5_HOST:$PI5_VNC_PORT"
echo ""

print_status "$GREEN" "Choose connection method:"
print_status "$GREEN" "1. TigerVNC (recommended)"
print_status "$GREEN" "2. Screen Sharing (built-in)"
print_status "$GREEN" "3. RealVNC Viewer"
echo ""

read -p "Choose method (1-3): " -n 1 -r
echo ""

case $REPLY in
    1)
        print_status "$BLUE" "Using TigerVNC..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
            vncviewer \
                -FullScreen=0 \
                -Scaling=FitToWindow \
                -PreferredEncoding=Tight \
                -CompressLevel=6 \
                -QualityLevel=6 \
                $PI5_HOST:$PI5_VNC_PORT
        "
        ;;
    2)
        print_status "$BLUE" "Using Screen Sharing..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
            open \"vnc://$PI5_HOST:$PI5_VNC_PORT\"
        "
        ;;
    3)
        print_status "$BLUE" "Using RealVNC Viewer..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
            open -a \"VNC Viewer\" \"vnc://$PI5_HOST:$PI5_VNC_PORT\"
        "
        ;;
    *)
        print_status "$RED" "Invalid choice. Using TigerVNC as default..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
            vncviewer \
                -FullScreen=0 \
                -Scaling=FitToWindow \
                $PI5_HOST:$PI5_VNC_PORT
        "
        ;;
esac

print_header "Step 4: Quick Commands for Future Use"
print_status "$GREEN" "✅ Connection completed!"
echo ""

print_status "$BLUE" "Quick commands for future connections:"
echo ""

print_status "$GREEN" "1. SSH to Mac Mini:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST"
echo ""

print_status "$GREEN" "2. Connect to Pi5 VNC (TigerVNC):"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:$PI5_VNC_PORT'"
echo ""

print_status "$GREEN" "3. Connect to Pi5 VNC (Screen Sharing):"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'open \"vnc://$PI5_HOST:$PI5_VNC_PORT\"'"
echo ""

print_status "$GREEN" "4. One-liner from Windows 11:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:$PI5_VNC_PORT'"
echo ""

print_status "$YELLOW" "Key parameters that fix Mac Mini VNC issues:"
print_status "$YELLOW" "• -FullScreen=0 (prevents fullscreen)"
print_status "$YELLOW" "• -Scaling=FitToWindow (fixes large text)"
print_status "$YELLOW" "• -PreferredEncoding=Tight (better performance)"
echo ""

print_header "Setup Complete"
print_status "$GREEN" "✅ You can now connect to Pi5 VNC from Mac Mini!"
print_status "$GREEN" "✅ The cursor fix and resolution settings will be preserved"
print_status "$GREEN" "✅ Use the quick commands above for future connections"
echo ""

