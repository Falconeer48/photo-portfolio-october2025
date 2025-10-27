#!/bin/bash

# Setup network share for watched folder
# This makes the watched folder accessible from Mac Mini

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🌐 Setting up network share for watched folder..."

WATCHED_FOLDER="$HOME/IncomingPrints"

# Create the watched folder if it doesn't exist
mkdir -p "$WATCHED_FOLDER"

# Enable file sharing if not already enabled
print_status $BLUE "🔧 Enabling file sharing..."
sudo sharing -a "$WATCHED_FOLDER" -S "IncomingPrints" -g 000 -w

# Get the IP address
IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

print_status $GREEN "✅ Network share enabled!"
echo ""
print_status $BLUE "📋 To connect from Mac Mini:"
print_status $YELLOW "1. In Finder: Go → Connect to Server"
print_status $YELLOW "2. Enter: smb://$IP_ADDRESS/IncomingPrints"
print_status $YELLOW "3. Or: smb://$(hostname).local/IncomingPrints"
print_status $YELLOW "4. Enter your iMac username and password"
print_status $YELLOW "5. The folder will appear in Finder sidebar"
echo ""
print_status $BLUE "💡 Usage:"
print_status $YELLOW "- Save PDFs directly to the mounted network folder"
print_status $YELLOW "- Files will print automatically on iMac"
print_status $YELLOW "- No Quick Actions needed!"
echo ""
print_status $GREEN "🎉 Network share setup completed!"
