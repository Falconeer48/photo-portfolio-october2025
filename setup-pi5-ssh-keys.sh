#!/bin/bash

# SSH Key Setup for Pi5 Passwordless Access
# This script generates SSH keys and copies them to Pi5 for passwordless login

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_ed25519.pub"

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

# Function to check if SSH key exists
check_ssh_key() {
    if [ -f "$SSH_KEY_PATH" ]; then
        print_status "$GREEN" "✅ SSH key already exists: $SSH_KEY_PATH"
        return 0
    else
        print_status "$YELLOW" "⚠️  SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
}

# Function to generate SSH key
generate_ssh_key() {
    print_header "Generating SSH Key"
    
    if check_ssh_key; then
        print_status "$YELLOW" "SSH key already exists. Do you want to generate a new one? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "$BLUE" "Using existing SSH key"
            return 0
        fi
    fi
    
    print_status "$BLUE" "Generating new SSH key..."
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "ian@mac-mini-to-pi5"
    
    if [ $? -eq 0 ]; then
        print_status "$GREEN" "✅ SSH key generated successfully"
    else
        print_status "$RED" "❌ Failed to generate SSH key"
        exit 1
    fi
}

# Function to copy SSH key to Pi5
copy_ssh_key() {
    print_header "Copying SSH Key to Pi5"
    
    if [ ! -f "$SSH_PUBLIC_KEY_PATH" ]; then
        print_status "$RED" "❌ Public key not found: $SSH_PUBLIC_KEY_PATH"
        exit 1
    fi
    
    print_status "$BLUE" "Copying public key to Pi5..."
    print_status "$YELLOW" "You will be prompted for your Pi5 password one last time"
    
    # Copy the public key to Pi5
    ssh-copy-id -i "$SSH_PUBLIC_KEY_PATH" "$PI5_HOST"
    
    if [ $? -eq 0 ]; then
        print_status "$GREEN" "✅ SSH key copied successfully to Pi5"
    else
        print_status "$RED" "❌ Failed to copy SSH key to Pi5"
        print_status "$YELLOW" "💡 Make sure Pi5 is accessible and SSH is enabled"
        exit 1
    fi
}

# Function to test passwordless connection
test_connection() {
    print_header "Testing Passwordless Connection"
    
    print_status "$BLUE" "Testing SSH connection to Pi5..."
    if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'Passwordless SSH connection successful!'" 2>/dev/null; then
        print_status "$GREEN" "✅ Passwordless SSH connection working!"
        return 0
    else
        print_status "$RED" "❌ Passwordless SSH connection failed"
        return 1
    fi
}

# Function to show SSH key fingerprint
show_key_info() {
    print_header "SSH Key Information"
    
    if [ -f "$SSH_PUBLIC_KEY_PATH" ]; then
        print_status "$BLUE" "Public Key:"
        cat "$SSH_PUBLIC_KEY_PATH"
        echo ""
        print_status "$BLUE" "Key Fingerprint:"
        ssh-keygen -lf "$SSH_PUBLIC_KEY_PATH"
    fi
}

# Function to show connection instructions
show_connection_instructions() {
    print_header "Connection Instructions"
    print_status "$GREEN" "✅ SSH key setup complete!"
    print_status "$BLUE" ""
    print_status "$BLUE" "You can now connect to Pi5 without a password:"
    print_status "$YELLOW" "  ssh -i $SSH_KEY_PATH $PI5_HOST"
    print_status "$BLUE" ""
    print_status "$BLUE" "Or simply:"
    print_status "$YELLOW" "  ssh $PI5_HOST"
    print_status "$BLUE" ""
    print_status "$BLUE" "Your VNC resolution script will now work without password prompts!"
}

# Main execution
print_header "Pi5 SSH Key Setup"

# Check if ssh-copy-id is available
if ! command -v ssh-copy-id &> /dev/null; then
    print_status "$RED" "❌ ssh-copy-id not found"
    print_status "$YELLOW" "💡 Install it with: brew install ssh-copy-id"
    exit 1
fi

# Generate SSH key if needed
generate_ssh_key

# Copy SSH key to Pi5
copy_ssh_key

# Test the connection
if test_connection; then
    show_key_info
    show_connection_instructions
else
    print_status "$RED" "❌ Setup incomplete - passwordless connection not working"
    print_status "$YELLOW" "💡 Try running the script again or check Pi5 SSH configuration"
fi

print_header "Setup Complete"







