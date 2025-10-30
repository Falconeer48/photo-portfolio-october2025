#!/bin/bash

# Pi5 Cursor Theme Fixer
# Changes mouse pointer from X to normal arrow pointer
# Usage: ./fix-pi5-cursor-theme.sh

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

# Function to check Pi5 connectivity
check_connectivity() {
    print_header "Checking Pi5 Connectivity"
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Connected'" >/dev/null 2>&1; then
        print_status "$RED" "❌ Cannot connect to Pi5"
        exit 1
    fi
    print_status "$GREEN" "✅ Connected to Pi5"
}

# Function to check current cursor theme
check_current_cursor() {
    print_header "Current Cursor Theme"
    CURRENT_THEME=$(run_on_pi5 "DISPLAY=$VNC_DISPLAY gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'Not set'")
    print_status "$BLUE" "Current cursor theme: $CURRENT_THEME"
}

# Function to install cursor themes
install_cursor_themes() {
    print_header "Installing Cursor Themes"
    
    print_status "$BLUE" "Updating package list..."
    run_on_pi5 "sudo apt update"
    
    print_status "$BLUE" "Installing cursor themes..."
    run_on_pi5 "sudo apt install -y adwaita-icon-theme dmz-cursor-theme"
    
    print_status "$GREEN" "✅ Cursor themes installed"
}

# Function to set cursor theme
set_cursor_theme() {
    local theme=$1
    print_header "Setting Cursor Theme to $theme"
    
    # Set the cursor theme
    run_on_pi5 "DISPLAY=$VNC_DISPLAY gsettings set org.gnome.desktop.interface cursor-theme '$theme'"
    
    # Verify the change
    NEW_THEME=$(run_on_pi5 "DISPLAY=$VNC_DISPLAY gsettings get org.gnome.desktop.interface cursor-theme")
    if [ "$NEW_THEME" = "'$theme'" ]; then
        print_status "$GREEN" "✅ Cursor theme set to $theme"
    else
        print_status "$RED" "❌ Failed to set cursor theme"
        return 1
    fi
}

# Function to restart desktop environment
restart_desktop() {
    print_header "Restarting Desktop Environment"
    
    print_status "$BLUE" "Restarting VNC server to apply changes..."
    run_on_pi5 "vncserver-virtual -kill $VNC_DISPLAY" 2>/dev/null
    sleep 2
    
    # Get current resolution to maintain it
    CURRENT_RES=$(run_on_pi5 "DISPLAY=$VNC_DISPLAY xrandr 2>/dev/null | grep '*' | head -1 | awk '{print \$1}'" 2>/dev/null || echo "1920x1080")
    
    print_status "$BLUE" "Starting VNC server with resolution $CURRENT_RES..."
    VNC_OUTPUT=$(run_on_pi5 "vncserver-virtual $VNC_DISPLAY -geometry $CURRENT_RES" 2>&1)
    
    if echo "$VNC_OUTPUT" | grep -q "New desktop"; then
        print_status "$GREEN" "✅ VNC server restarted successfully"
        sleep 3
    else
        print_status "$RED" "❌ Failed to restart VNC server"
        echo "$VNC_OUTPUT"
        return 1
    fi
}

# Function to show available cursor themes
show_available_themes() {
    print_header "Available Cursor Themes"
    
    print_status "$BLUE" "Checking installed cursor themes..."
    THEMES=$(run_on_pi5 "ls /usr/share/icons/*/cursors/ 2>/dev/null | grep -E '^(Adwaita|DMZ)' | head -10")
    
    if [ -n "$THEMES" ]; then
        print_status "$GREEN" "Available themes:"
        echo "$THEMES" | while read theme; do
            print_status "$YELLOW" "  - $theme"
        done
    else
        print_status "$YELLOW" "No cursor themes found. Installing default themes..."
        install_cursor_themes
    fi
}

# Function to test cursor theme
test_cursor_theme() {
    print_header "Testing Cursor Theme"
    
    print_status "$BLUE" "Opening a test application to verify cursor..."
    run_on_pi5 "DISPLAY=$VNC_DISPLAY gnome-terminal --version" 2>/dev/null || run_on_pi5 "DISPLAY=$VNC_DISPLAY xterm -version" 2>/dev/null
    
    print_status "$GREEN" "✅ Cursor theme test completed"
    print_status "$BLUE" "Connect to VNC to see the new cursor theme"
}

# Function to show connection info
show_connection_info() {
    print_header "VNC Connection Information"
    print_status "$GREEN" "✅ VNC Server is running on: $PI5_HOST:1"
    print_status "$BLUE" ""
    print_status "$BLUE" "To connect from your Mac:"
    print_status "$BLUE" "1. Using TigerVNC:"
    print_status "$YELLOW" "   vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5901"
    print_status "$BLUE" "2. Using Screen Sharing:"
    print_status "$YELLOW" "   open \"vnc://$PI5_HOST:5901\""
    print_status "$BLUE" "3. Using RealVNC Viewer:"
    print_status "$YELLOW" "   Connect to: $PI5_HOST:1"
}

# Main script logic
print_header "Pi5 Cursor Theme Fixer"

# Check connectivity
check_connectivity

# Check current cursor theme
check_current_cursor

# Show available themes
show_available_themes

# Install cursor themes if needed
print_status "$BLUE" "Installing cursor themes..."
install_cursor_themes

# Set cursor theme to Adwaita (normal arrow)
print_status "$BLUE" "Setting cursor theme to Adwaita (normal arrow)..."
set_cursor_theme "Adwaita"

# Restart desktop environment
restart_desktop

# Test the cursor theme
test_cursor_theme

# Show connection info
show_connection_info

print_header "Cursor Theme Fix Complete"
print_status "$GREEN" "✅ Cursor theme changed from X to normal arrow pointer!"
print_status "$BLUE" "Connect to your Pi5 VNC to see the new cursor theme."
print_status "$YELLOW" "💡 If the cursor still shows as X, try logging out and back in to the VNC session."







