#!/bin/bash

# Fix VNC Cursor Script for Pi5
# This script fixes the "X" cursor issue in VNC sessions

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

print_header "Pi5 VNC Cursor Fix"

# 1. Check Pi5 connectivity
print_header "1. Checking Pi5 Connectivity"
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Connected'" >/dev/null 2>&1; then
    print_status "$RED" "❌ Cannot connect to Pi5"
    exit 1
fi
print_status "$GREEN" "✅ Connected to Pi5"

# 2. Check current VNC status
print_header "2. Checking VNC Status"
VNC_STATUS=$(run_on_pi5 "ps aux | grep vncserver-virtual | grep -v grep")
if [ -n "$VNC_STATUS" ]; then
    print_status "$GREEN" "✅ VNC server is running"
else
    print_status "$RED" "❌ VNC server is not running"
    print_status "$YELLOW" "💡 Starting VNC server..."
    run_on_pi5 "vncserver-virtual :1 -geometry 1920x1080"
    sleep 3
fi

# 3. Fix cursor immediately
print_header "3. Fixing Cursor Immediately"
print_status "$BLUE" "Setting cursor to normal arrow..."

# Try multiple cursor fixes
run_on_pi5 "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name left_ptr" 2>/dev/null
run_on_pi5 "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name arrow" 2>/dev/null
run_on_pi5 "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name default" 2>/dev/null

# Set cursor theme environment variables
run_on_pi5 "DISPLAY=$VNC_DISPLAY export XCURSOR_THEME=Adwaita"
run_on_pi5 "DISPLAY=$VNC_DISPLAY export XCURSOR_SIZE=24"

print_status "$GREEN" "✅ Cursor fixes applied"

# 4. Update xstartup file for permanent fix
print_header "4. Updating xstartup for Permanent Fix"
print_status "$BLUE" "Creating improved xstartup file..."

run_on_pi5 'cat > ~/.vnc/xstartup << "EOF"
#!/bin/bash
# Uncomment the following two lines for normal desktop:
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="LXDE"
export XDG_MENU_PREFIX="lxde-"
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
# Fix cursor - set proper cursor theme and size
export XCURSOR_THEME="Adwaita"
export XCURSOR_SIZE="24"
xsetroot -solid grey -cursor_name left_ptr
vncconfig -iconic &
# Start desktop environment
lxsession -s LXDE-pi -e LXDE &
EOF'

run_on_pi5 "chmod +x ~/.vnc/xstartup"
print_status "$GREEN" "✅ xstartup file updated"

# 5. Install cursor themes if missing
print_header "5. Checking Cursor Themes"
CURSOR_THEMES=$(run_on_pi5 "ls /usr/share/icons/ | grep -E '(Adwaita|default|gnome)'")
if [ -n "$CURSOR_THEMES" ]; then
    print_status "$GREEN" "✅ Cursor themes available:"
    echo "$CURSOR_THEMES" | while read -r theme; do
        print_status "$GREEN" "   📁 $theme"
    done
else
    print_status "$YELLOW" "⚠️  Installing additional cursor themes..."
    run_on_pi5 "sudo apt update && sudo apt install -y adwaita-icon-theme"
fi

# 6. Test cursor fix
print_header "6. Testing Cursor Fix"
print_status "$BLUE" "Testing cursor commands..."

# Test various cursor commands
run_on_pi5 "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name left_ptr" 2>/dev/null && print_status "$GREEN" "✅ left_ptr cursor set"
run_on_pi5 "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name arrow" 2>/dev/null && print_status "$GREEN" "✅ arrow cursor set"
run_on_pi5 "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name default" 2>/dev/null && print_status "$GREEN" "✅ default cursor set"

# 7. Create cursor fix script for future use
print_header "7. Creating Cursor Fix Script"
run_on_pi5 'cat > ~/fix-cursor.sh << "EOF"
#!/bin/bash
# Quick cursor fix script
export DISPLAY=:1
export XCURSOR_THEME="Adwaita"
export XCURSOR_SIZE="24"
xsetroot -cursor_name left_ptr
echo "Cursor fixed!"
EOF'

run_on_pi5 "chmod +x ~/fix-cursor.sh"
print_status "$GREEN" "✅ Cursor fix script created: ~/fix-cursor.sh"

# 8. Final status
print_header "8. Final Status"
print_status "$GREEN" "✅ Cursor fix completed!"
echo ""
print_status "$BLUE" "Cursor fixes applied:"
print_status "$GREEN" "  ✅ Immediate cursor fix"
print_status "$GREEN" "  ✅ Updated xstartup file"
print_status "$GREEN" "  ✅ Set cursor theme to Adwaita"
print_status "$GREEN" "  ✅ Created fix-cursor.sh script"
echo ""
print_status "$YELLOW" "If cursor is still showing as 'X':"
print_status "$YELLOW" "  1. Reconnect to VNC"
print_status "$YELLOW" "  2. Run: ssh $PI5_HOST '~/fix-cursor.sh'"
print_status "$YELLOW" "  3. Restart VNC: ssh $PI5_HOST 'vncserver-virtual -kill :1 && vncserver-virtual :1'"
echo ""
print_status "$PURPLE" "VNC Cursor Fix Complete!"

