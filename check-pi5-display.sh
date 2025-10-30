#!/bin/bash

# Pi5 Display Information Checker
# Shows current VNC display resolution and system information

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SSH_KEY="~/.ssh/id_ed25519"
VNC_DISPLAY=":1"

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

# Function to check VNC display resolution
check_vnc_resolution() {
    print_header "VNC Display Resolution"
    
    CURRENT_RES=$(run_on_pi5 "DISPLAY=$VNC_DISPLAY xrandr 2>/dev/null | grep '*' | head -1")
    if [ -n "$CURRENT_RES" ]; then
        print_status "$GREEN" "✅ Current VNC resolution: $CURRENT_RES"
    else
        print_status "$RED" "❌ Cannot determine VNC resolution"
        print_status "$YELLOW" "💡 VNC server might not be running"
    fi
}

# Function to check system display info
check_system_display() {
    print_header "System Display Information"
    
    print_status "$BLUE" "Available displays:"
    run_on_pi5 "ls /sys/class/drm/ | grep -E '^card[0-9]+' | head -5"
    
    print_status "$BLUE" ""
    print_status "$BLUE" "Display modes (if any physical display):"
    run_on_pi5 "for card in /sys/class/drm/card*; do echo \"Card: \$card\"; cat \$card/status 2>/dev/null || echo 'No status'; done"
}

# Function to check VNC server status
check_vnc_status() {
    print_header "VNC Server Status"
    
    VNC_PROCESS=$(run_on_pi5 "ps aux | grep vnc | grep -v grep")
    if [ -n "$VNC_PROCESS" ]; then
        print_status "$GREEN" "✅ VNC server is running:"
        echo "$VNC_PROCESS"
    else
        print_status "$RED" "❌ VNC server is not running"
    fi
    
    print_status "$BLUE" ""
    print_status "$BLUE" "VNC server ports:"
    run_on_pi5 "netstat -tlnp | grep vnc || echo 'No VNC ports found'"
}

# Function to show display capabilities
show_display_capabilities() {
    print_header "Display Capabilities"
    
    print_status "$BLUE" "Maximum supported resolution:"
    run_on_pi5 "DISPLAY=$VNC_DISPLAY xrandr --query 2>/dev/null | head -10"
    
    print_status "$BLUE" ""
    print_status "$BLUE" "Graphics information:"
    run_on_pi5 "lspci | grep -i vga || lspci | grep -i display"
}

# Function to show connection info
show_connection_info() {
    print_header "Connection Information"
    print_status "$GREEN" "✅ Pi5 Host: $PI5_HOST"
    print_status "$GREEN" "✅ VNC Display: $VNC_DISPLAY"
    print_status "$BLUE" ""
    print_status "$BLUE" "Connect with:"
    print_status "$YELLOW" "  vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5901"
    print_status "$YELLOW" "  open \"vnc://$PI5_HOST:5901\""
}

# Main execution
print_header "Pi5 Display Information"

# Check Pi5 connectivity
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Connected'" >/dev/null 2>&1; then
    print_status "$RED" "❌ Cannot connect to Pi5"
    exit 1
fi

# Run all checks
check_vnc_resolution
check_system_display
check_vnc_status
show_display_capabilities
show_connection_info

print_header "Display Check Complete"
