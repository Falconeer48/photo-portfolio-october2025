#!/bin/bash

# SSH to Mac Mini and Run VNC Scripts
# This script helps you SSH from Windows 11 to Mac Mini and run VNC scripts

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

print_header "SSH to Mac Mini VNC Setup"
echo ""

print_status "$BLUE" "This script will help you SSH from Windows 11 to Mac Mini"
print_status "$BLUE" "and run VNC scripts to fix the scaling issues."
echo ""

# Configuration - Update these with your Mac Mini details
MAC_MINI_HOST="192.168.50.XXX"  # Replace with your Mac Mini IP
MAC_MINI_USER="your_username"   # Replace with your Mac Mini username
PI5_HOST="192.168.50.243"

print_status "$YELLOW" "Before running this script, please update:"
print_status "$YELLOW" "1. MAC_MINI_HOST with your Mac Mini IP address"
print_status "$YELLOW" "2. MAC_MINI_USER with your Mac Mini username"
echo ""

read -p "Have you updated the configuration? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "$RED" "Please update the configuration first"
    exit 1
fi

print_header "Step 1: Test SSH Connection to Mac Mini"
print_status "$BLUE" "Testing SSH connection to Mac Mini..."

if ssh -o ConnectTimeout=10 "$MAC_MINI_USER@$MAC_MINI_HOST" "echo 'SSH connection successful'"; then
    print_status "$GREEN" "✅ SSH connection to Mac Mini successful"
else
    print_status "$RED" "❌ SSH connection to Mac Mini failed"
    print_status "$YELLOW" "Please check:"
    print_status "$YELLOW" "• Mac Mini IP address"
    print_status "$YELLOW" "• Username"
    print_status "$YELLOW" "• SSH is enabled on Mac Mini"
    print_status "$YELLOW" "• SSH key authentication"
    exit 1
fi

print_header "Step 2: Copy VNC Scripts to Mac Mini"
print_status "$BLUE" "Copying VNC scripts to Mac Mini..."

# Copy the VNC fix script to Mac Mini
if scp fix-mac-mini-vnc.sh "$MAC_MINI_USER@$MAC_MINI_HOST:~/"; then
    print_status "$GREEN" "✅ VNC fix script copied to Mac Mini"
else
    print_status "$RED" "❌ Failed to copy VNC fix script"
fi

# Copy the VNC connection script to Mac Mini
if scp connect-vnc-pi5-mac-mini.sh "$MAC_MINI_USER@$MAC_MINI_HOST:~/"; then
    print_status "$GREEN" "✅ VNC connection script copied to Mac Mini"
else
    print_status "$RED" "❌ Failed to copy VNC connection script"
fi

print_header "Step 3: Run VNC Setup on Mac Mini"
print_status "$BLUE" "Running VNC setup on Mac Mini..."

ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
    echo 'Making scripts executable...'
    chmod +x fix-mac-mini-vnc.sh connect-vnc-pi5-mac-mini.sh
    
    echo 'Running VNC setup...'
    ./fix-mac-mini-vnc.sh
"

if [ $? -eq 0 ]; then
    print_status "$GREEN" "✅ VNC setup completed on Mac Mini"
else
    print_status "$RED" "❌ VNC setup failed on Mac Mini"
fi

print_header "Step 4: Test VNC Connection"
print_status "$BLUE" "Testing VNC connection from Mac Mini to Pi5..."

ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "
    echo 'Testing VNC connection...'
    ./connect-vnc-pi5-mac-mini.sh
"

print_header "Step 5: Manual VNC Connection Commands"
print_status "$GREEN" "✅ Setup completed!"
echo ""

print_status "$BLUE" "To connect to Pi5 from Mac Mini, use these commands:"
echo ""

print_status "$GREEN" "Method 1 - SSH to Mac Mini and run script:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST"
print_status "$BLUE" "./connect-vnc-pi5-mac-mini.sh"
echo ""

print_status "$GREEN" "Method 2 - Direct VNC command from Mac Mini:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5900'"
echo ""

print_status "$GREEN" "Method 3 - One-liner from Windows 11:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5900'"
echo ""

print_status "$YELLOW" "Key parameters that fix the Mac Mini VNC issues:"
print_status "$YELLOW" "• -FullScreen=0 (prevents fullscreen)"
print_status "$YELLOW" "• -Scaling=FitToWindow (fixes large text)"
print_status "$YELLOW" "• -Geometry=1024x768 (sets window size)"
echo ""

print_header "Quick Commands"
print_status "$PURPLE" "Copy and paste these commands:"
echo ""

print_status "$GREEN" "1. SSH to Mac Mini:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST"
echo ""

print_status "$GREEN" "2. Run VNC connection script:"
print_status "$BLUE" "./connect-vnc-pi5-mac-mini.sh"
echo ""

print_status "$GREEN" "3. Or direct VNC command:"
print_status "$BLUE" "vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5900"
echo ""

print_status "$GREEN" "4. One-liner from Windows 11:"
print_status "$BLUE" "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:5900'"
echo ""

print_header "Setup Complete"
print_status "$GREEN" "✅ Mac Mini VNC setup completed!"
print_status "$GREEN" "✅ You can now SSH from Windows 11 to Mac Mini"
print_status "$GREEN" "✅ VNC scripts are ready to use"
echo ""

