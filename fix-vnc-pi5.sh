#!/bin/bash

# VNC Fix Script for Pi 5
# This script fixes common VNC issues and configures proper screen resolution

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SSH_KEY="~/.ssh/id_ed25519"
VNC_DISPLAY=":0"
DEFAULT_RESOLUTION="1920x1080"

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

print_header "VNC Fix Script for Pi 5"
echo ""

# 1. Check connectivity
print_header "1. Checking Pi5 Connectivity"
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Connected'" >/dev/null 2>&1; then
    print_status "$RED" "❌ Cannot connect to Pi5"
    exit 1
fi
print_status "$GREEN" "✅ Connected to Pi5"

# 2. Stop VNC server
print_header "2. Stopping VNC Server"
print_status "$BLUE" "Stopping VNC server..."
run_on_pi5 "sudo systemctl stop vncserver@:0" 2>/dev/null
print_status "$GREEN" "✅ VNC server stopped"

# 3. Kill any remaining VNC processes
print_header "3. Cleaning Up VNC Processes"
print_status "$BLUE" "Killing remaining VNC processes..."
run_on_pi5 "sudo pkill -f vnc" 2>/dev/null
run_on_pi5 "sudo pkill -f Xvnc" 2>/dev/null
sleep 2
print_status "$GREEN" "✅ VNC processes cleaned up"

# 4. Configure VNC settings
print_header "4. Configuring VNC Settings"
print_status "$BLUE" "Setting up VNC configuration..."

# Create VNC config directory if it doesn't exist
run_on_pi5 "mkdir -p ~/.vnc"

# Create xstartup file with proper desktop environment
print_status "$BLUE" "Creating xstartup file..."
run_on_pi5 "cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=\"GNOME-Flashback:GNOME\"
export XDG_MENU_PREFIX=\"gnome-flashback-\"
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
gnome-session --session=gnome-flashback-metacity --disable-acceleration-check &
EOF"

# Make xstartup executable
run_on_pi5 "chmod +x ~/.vnc/xstartup"

# Create VNC config file with resolution settings
print_status "$BLUE" "Creating VNC config file..."
run_on_pi5 "cat > ~/.vnc/config << 'EOF'
# VNC Configuration
geometry=$DEFAULT_RESOLUTION
depth=24
dpi=96
EOF"

print_status "$GREEN" "✅ VNC configuration created"

# 5. Set up display resolution
print_header "5. Configuring Display Resolution"
print_status "$BLUE" "Setting up display resolution..."

# Create a script to set resolution
run_on_pi5 "cat > ~/set_resolution.sh << 'EOF'
#!/bin/bash
# Wait for X server to start
sleep 5

# Set resolution
export DISPLAY=:0
xrandr --output HDMI-1 --mode $DEFAULT_RESOLUTION 2>/dev/null || \
xrandr --output HDMI-A-1 --mode $DEFAULT_RESOLUTION 2>/dev/null || \
xrandr --output HDMI-1-1 --mode $DEFAULT_RESOLUTION 2>/dev/null || \
echo \"Could not set resolution automatically\"

# List available outputs for debugging
echo \"Available outputs:\"
xrandr | grep \" connected\"
EOF"

run_on_pi5 "chmod +x ~/set_resolution.sh"

print_status "$GREEN" "✅ Resolution script created"

# 6. Enable VNC service
print_header "6. Enabling VNC Service"
print_status "$BLUE" "Enabling VNC service..."
run_on_pi5 "sudo systemctl enable vncserver@:0"
print_status "$GREEN" "✅ VNC service enabled"

# 7. Start VNC server
print_header "7. Starting VNC Server"
print_status "$BLUE" "Starting VNC server..."
run_on_pi5 "sudo systemctl start vncserver@:0"
sleep 5

# Check if VNC is running
VNC_STATUS=$(run_on_pi5 "systemctl is-active vncserver@:0" 2>/dev/null)
if [ "$VNC_STATUS" = "active" ]; then
    print_status "$GREEN" "✅ VNC server started successfully"
else
    print_status "$RED" "❌ VNC server failed to start"
    print_status "$YELLOW" "Checking logs..."
    run_on_pi5 "journalctl -u vncserver@:0 --no-pager -l"
fi

# 8. Set resolution after VNC starts
print_header "8. Setting Display Resolution"
print_status "$BLUE" "Setting display resolution..."
run_on_pi5 "~/set_resolution.sh &"

# Wait a moment and check resolution
sleep 3
CURRENT_RES=$(run_on_pi5 "export DISPLAY=:0 && xrandr --current 2>/dev/null | grep '*' | head -1")
if [ -n "$CURRENT_RES" ]; then
    print_status "$GREEN" "✅ Current resolution: $CURRENT_RES"
else
    print_status "$YELLOW" "⚠️  Could not determine resolution"
fi

# 9. Configure firewall (if needed)
print_header "9. Configuring Firewall"
print_status "$BLUE" "Checking firewall status..."
UFW_STATUS=$(run_on_pi5 "sudo ufw status" 2>/dev/null)
if echo "$UFW_STATUS" | grep -q "Status: active"; then
    print_status "$YELLOW" "⚠️  Firewall is active"
    print_status "$BLUE" "Allowing VNC port..."
    run_on_pi5 "sudo ufw allow 5900/tcp" 2>/dev/null
    print_status "$GREEN" "✅ VNC port allowed through firewall"
else
    print_status "$GREEN" "✅ Firewall is not active"
fi

# 10. Test VNC connection
print_header "10. Testing VNC Connection"
print_status "$BLUE" "Testing VNC connection..."

# Check if VNC port is listening
if run_on_pi5 "netstat -tlnp | grep :5900" >/dev/null 2>&1; then
    print_status "$GREEN" "✅ VNC port 5900 is listening"
else
    print_status "$RED" "❌ VNC port 5900 is not listening"
fi

# 11. Final status check
print_header "11. Final Status Check"
print_status "$BLUE" "Checking final VNC status..."

VNC_FINAL_STATUS=$(run_on_pi5 "systemctl is-active vncserver@:0" 2>/dev/null)
if [ "$VNC_FINAL_STATUS" = "active" ]; then
    print_status "$GREEN" "✅ VNC server is running"
else
    print_status "$RED" "❌ VNC server is not running"
fi

VNC_PROCESSES=$(run_on_pi5 "ps aux | grep vnc | grep -v grep")
if [ -n "$VNC_PROCESSES" ]; then
    print_status "$GREEN" "✅ VNC processes are running"
else
    print_status "$RED" "❌ No VNC processes found"
fi

# 12. Connection instructions
print_header "12. Connection Instructions"
print_status "$GREEN" "✅ VNC setup completed!"
echo ""
print_status "$BLUE" "To connect from your Mac Mini:"
print_status "$BLUE" "1. Install VNC viewer: brew install tigervnc"
print_status "$BLUE" "2. Connect with: vncviewer $PI5_HOST:5900"
print_status "$BLUE" "3. Or use Screen Sharing app: vnc://$PI5_HOST:5900"
echo ""
print_status "$YELLOW" "If you still have resolution issues:"
print_status "$YELLOW" "1. SSH to Pi5: ssh $PI5_HOST"
print_status "$YELLOW" "2. Check available resolutions: xrandr"
print_status "$YELLOW" "3. Set specific resolution: xrandr --output HDMI-1 --mode 1920x1080"
print_status "$YELLOW" "4. Restart VNC: sudo systemctl restart vncserver@:0"
echo ""
print_status "$PURPLE" "VNC Fix Script Complete!"







