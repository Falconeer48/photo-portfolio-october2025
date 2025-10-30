#!/bin/bash

# RealVNC Resolution Changer for Pi5
# This script properly changes RealVNC server resolution

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SSH_KEY="~/.ssh/id_ed25519"

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

# Function to run command on Pi5
run_on_pi5() {
    ssh -i "$SSH_KEY" "$PI5_HOST" "$1"
}

# Function to change RealVNC resolution
change_realvnc_resolution() {
    local resolution=$1
    
    print_header "Changing RealVNC Resolution to $resolution"
    
    # Check Pi5 connectivity
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Connected'" >/dev/null 2>&1; then
        print_status "$RED" "❌ Cannot connect to Pi5"
        exit 1
    fi
    
    # Change resolution using xrandr (works with existing X server)
    print_status "$BLUE" "Changing resolution to $resolution using xrandr..."
    
    # Extract width and height from resolution (e.g., 2560x1440)
    WIDTH=$(echo "$resolution" | cut -d'x' -f1)
    HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
    
    # Use predefined modelines for common resolutions
    case "$resolution" in
        "1920x1080")
            MODELINE="173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync"
            ;;
        "2560x1440")
            MODELINE="241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync +vsync"
            ;;
        "3840x2160")
            MODELINE="533.25 3840 3888 3920 4000 2160 2163 2168 2222 +hsync +vsync"
            ;;
        *)
            print_status "$YELLOW" "⚠️  Using default modeline for $resolution"
            MODELINE="$(echo "$WIDTH * $HEIGHT * 60 / 1000000" | bc) $WIDTH $(($WIDTH + 80)) $(($WIDTH + 160)) $(($WIDTH + 240)) $HEIGHT $(($HEIGHT + 3)) $(($HEIGHT + 8)) $(($HEIGHT + 40)) +hsync +vsync"
            ;;
    esac
    
    print_status "$BLUE" "Creating new mode: $resolution"
    run_on_pi5 "DISPLAY=:0 xrandr --newmode '$resolution' $MODELINE"
    
    print_status "$BLUE" "Adding mode to HDMI-1 output..."
    run_on_pi5 "DISPLAY=:0 xrandr --addmode HDMI-1 '$resolution'"
    
    print_status "$BLUE" "Setting resolution..."
    run_on_pi5 "DISPLAY=:0 xrandr --output HDMI-1 --mode '$resolution'"
    
    print_status "$GREEN" "✅ Resolution changed successfully!"
    
    # Verify the resolution change
    sleep 2
    CURRENT_RES=$(run_on_pi5 "DISPLAY=:0 xrandr 2>/dev/null | grep 'current' | head -1")
    if [ -n "$CURRENT_RES" ]; then
        print_status "$GREEN" "✅ Resolution verified: $CURRENT_RES"
    else
        print_status "$YELLOW" "⚠️  Could not verify resolution"
    fi
    
    # Check if RealVNC service is running
    SERVICE_STATUS=$(run_on_pi5 "systemctl is-active vncserver-x11-serviced")
    if [ "$SERVICE_STATUS" = "active" ]; then
        print_status "$GREEN" "✅ RealVNC service is running"
    else
        print_status "$YELLOW" "⚠️  RealVNC service status: $SERVICE_STATUS"
    fi
}

# Function to show current resolution
show_current_resolution() {
    print_header "Current RealVNC Resolution"
    
    SERVICE_STATUS=$(run_on_pi5 "systemctl is-active vncserver-x11-serviced")
    if [ "$SERVICE_STATUS" = "active" ]; then
        CURRENT_RES=$(run_on_pi5 "DISPLAY=:0 xrandr 2>/dev/null | grep 'current' | head -1")
        if [ -n "$CURRENT_RES" ]; then
            print_status "$GREEN" "✅ Current resolution: $CURRENT_RES"
        else
            print_status "$YELLOW" "⚠️  Could not determine resolution"
        fi
        
        print_status "$BLUE" "RealVNC Service Status:"
        run_on_pi5 "systemctl status vncserver-x11-serviced --no-pager -l | head -5"
    else
        print_status "$RED" "❌ RealVNC service is not running"
    fi
}

# Function to show connection info
show_connection_info() {
    print_header "RealVNC Connection Information"
    print_status "$GREEN" "✅ RealVNC Server: $PI5_HOST:0"
    print_status "$BLUE" ""
    print_status "$BLUE" "Connect with:"
    print_status "$YELLOW" "  vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5900"
    print_status "$YELLOW" "  open \"vnc://$PI5_HOST:5900\""
}

# Main execution
print_header "RealVNC Resolution Changer"

if [ $# -eq 0 ]; then
    show_current_resolution
    echo ""
    show_connection_info
    echo ""
    print_status "$YELLOW" "Usage: $0 [resolution]"
    print_status "$YELLOW" "Examples:"
    print_status "$YELLOW" "  $0 1920x1080"
    print_status "$YELLOW" "  $0 2560x1440"
    print_status "$YELLOW" "  $0 3840x2160"
    exit 0
fi

# Change resolution
change_realvnc_resolution "$1"
echo ""
show_connection_info

print_header "Resolution Change Complete"
print_status "$GREEN" "✅ RealVNC resolution changed successfully!"
