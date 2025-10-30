#!/bin/bash

# Persistent VNC Resolution Setup for Pi5
# This script makes the VNC resolution persistent across reboots

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SSH_KEY="~/.ssh/id_ed25519"
DEFAULT_RESOLUTION="3840x2160"

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

# Function to create persistent resolution script
create_resolution_script() {
    local resolution=${1:-$DEFAULT_RESOLUTION}
    
    print_header "Creating Persistent Resolution Script"
    
    # Extract width and height
    WIDTH=$(echo "$resolution" | cut -d'x' -f1)
    HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
    
    # Create the resolution script
    cat > /tmp/set-vnc-resolution.sh << EOF
#!/bin/bash
# Auto-generated VNC resolution script
# This script sets the VNC resolution on startup

# Wait for X server to be ready
sleep 10

# Set resolution to $resolution
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
        echo "Unsupported resolution: $resolution"
        exit 1
        ;;
esac

# Set the resolution
export DISPLAY=:0
xrandr --newmode "$resolution" \$MODELINE 2>/dev/null || true
xrandr --addmode HDMI-1 "$resolution" 2>/dev/null || true
xrandr --output HDMI-1 --mode "$resolution" 2>/dev/null || true

echo "VNC resolution set to $resolution"
EOF

    # Copy script to Pi5
    scp -i "$SSH_KEY" /tmp/set-vnc-resolution.sh "$PI5_HOST:/tmp/"
    
    # Make it executable and move to system location
    run_on_pi5 "sudo mv /tmp/set-vnc-resolution.sh /usr/local/bin/"
    run_on_pi5 "sudo chmod +x /usr/local/bin/set-vnc-resolution.sh"
    
    print_status "$GREEN" "✅ Resolution script created: /usr/local/bin/set-vnc-resolution.sh"
}

# Function to create systemd service
create_systemd_service() {
    print_header "Creating Systemd Service"
    
    # Create the systemd service file
    cat > /tmp/vnc-resolution.service << EOF
[Unit]
Description=Set VNC Resolution
After=graphical.target
After=vncserver-x11-serviced.service
Wants=vncserver-x11-serviced.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-vnc-resolution.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Copy service file to Pi5
    scp -i "$SSH_KEY" /tmp/vnc-resolution.service "$PI5_HOST:/tmp/"
    
    # Install the service
    run_on_pi5 "sudo mv /tmp/vnc-resolution.service /etc/systemd/system/"
    run_on_pi5 "sudo systemctl daemon-reload"
    run_on_pi5 "sudo systemctl enable vnc-resolution.service"
    
    print_status "$GREEN" "✅ Systemd service created and enabled"
}

# Function to test the setup
test_setup() {
    print_header "Testing Setup"
    
    # Test the resolution script
    print_status "$BLUE" "Testing resolution script..."
    run_on_pi5 "sudo /usr/local/bin/set-vnc-resolution.sh"
    
    # Check if service is enabled
    SERVICE_STATUS=$(run_on_pi5 "systemctl is-enabled vnc-resolution.service")
    if [ "$SERVICE_STATUS" = "enabled" ]; then
        print_status "$GREEN" "✅ Service is enabled"
    else
        print_status "$RED" "❌ Service is not enabled"
    fi
    
    # Check current resolution
    CURRENT_RES=$(run_on_pi5 "DISPLAY=:0 xrandr 2>/dev/null | grep 'current' | head -1")
    if [ -n "$CURRENT_RES" ]; then
        print_status "$GREEN" "✅ Current resolution: $CURRENT_RES"
    else
        print_status "$YELLOW" "⚠️  Could not verify resolution"
    fi
}

# Function to show status
show_status() {
    print_header "Persistent Resolution Status"
    
    # Check if script exists
    if run_on_pi5 "test -f /usr/local/bin/set-vnc-resolution.sh"; then
        print_status "$GREEN" "✅ Resolution script exists"
    else
        print_status "$RED" "❌ Resolution script not found"
    fi
    
    # Check if service exists
    if run_on_pi5 "systemctl list-unit-files | grep -q vnc-resolution"; then
        print_status "$GREEN" "✅ Systemd service exists"
        SERVICE_STATUS=$(run_on_pi5 "systemctl is-enabled vnc-resolution.service")
        print_status "$BLUE" "   Service status: $SERVICE_STATUS"
    else
        print_status "$RED" "❌ Systemd service not found"
    fi
    
    # Show current resolution
    CURRENT_RES=$(run_on_pi5 "DISPLAY=:0 xrandr 2>/dev/null | grep 'current' | head -1")
    if [ -n "$CURRENT_RES" ]; then
        print_status "$GREEN" "✅ Current resolution: $CURRENT_RES"
    else
        print_status "$YELLOW" "⚠️  Could not determine current resolution"
    fi
}

# Main execution
print_header "Persistent VNC Resolution Setup"

# Check Pi5 connectivity
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Connected'" >/dev/null 2>&1; then
    print_status "$RED" "❌ Cannot connect to Pi5"
    exit 1
fi

if [ $# -eq 0 ]; then
    show_status
    echo ""
    print_status "$YELLOW" "Usage: $0 [resolution]"
    print_status "$YELLOW" "Examples:"
    print_status "$YELLOW" "  $0 1920x1080"
    print_status "$YELLOW" "  $0 2560x1440"
    print_status "$YELLOW" "  $0 3840x2160"
    exit 0
fi

# Setup persistent resolution
create_resolution_script "$1"
create_systemd_service
test_setup

print_header "Setup Complete"
print_status "$GREEN" "✅ VNC resolution will now persist across reboots!"
print_status "$BLUE" "The Pi5 will automatically set resolution to $1 on startup."







