#!/bin/bash

# Simple network share setup using macOS built-in sharing
# This creates a symbolic link to the watched folder in the Public folder

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

print_status $BLUE "🌐 Setting up simple network share..."

WATCHED_FOLDER="$HOME/IncomingPrints"
PUBLIC_FOLDER="$HOME/Public"
SHARE_LINK="$PUBLIC_FOLDER/IncomingPrints"

# Create Public folder if it doesn't exist
mkdir -p "$PUBLIC_FOLDER"

# Remove existing link if it exists
if [ -L "$SHARE_LINK" ] || [ -e "$SHARE_LINK" ]; then
    rm -rf "$SHARE_LINK"
    print_status $YELLOW "Removed existing link"
fi

# Create symbolic link
ln -s "$WATCHED_FOLDER" "$SHARE_LINK"

print_status $GREEN "✅ Symbolic link created: $SHARE_LINK"

# Get the IP address
IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

print_status $BLUE "📋 To connect from Mac Mini:"
print_status $YELLOW "1. In Finder: Go → Connect to Server"
print_status $YELLOW "2. Enter: smb://$IP_ADDRESS/Public/IncomingPrints"
print_status $YELLOW "3. Or: smb://$(hostname).local/Public/IncomingPrints"
print_status $YELLOW "4. Enter your iMac username and password"
print_status $YELLOW "5. The folder will appear in Finder sidebar"
echo ""
print_status $BLUE "💡 Usage:"
print_status $YELLOW "- Save PDFs directly to the mounted network folder"
print_status $YELLOW "- Files will print automatically on iMac"
print_status $YELLOW "- No Quick Actions needed!"
echo ""
print_status $GREEN "🎉 Simple network share setup completed!"
