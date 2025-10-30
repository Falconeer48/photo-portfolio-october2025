#!/bin/bash

# VNC Resolution Changer for Pi5
# Usage: ./change-vnc-resolution.sh [resolution]
# Examples: ./change-vnc-resolution.sh 1920x1080
#           ./change-vnc-resolution.sh 4K
#           ./change-vnc-resolution.sh 8K

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SSH_KEY="$HOME/.ssh/id_ed25519"
VNC_DISPLAY=":0"
SSH_OPTS="-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new"

print_status() {
    echo -e "${GREEN}[STATUS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to run command on Pi5 with error handling
run_on_pi5() {
    local cmd="$1"
    local output
    output=$(ssh -i "$SSH_KEY" $SSH_OPTS "$PI5_HOST" "$cmd" 2>&1)
    local status=$?
    if [ $status -ne 0 ]; then
        print_error "SSH command failed: $output"
        return $status
    fi
    echo "$output"
    return 0
}

# Predefined resolutions
get_resolution() {
    case "$1" in
        "4K")   echo "3840x2160" ;;
        "8K")   echo "7680x4320" ;;
        "1080p") echo "1920x1080" ;;
        "720p")  echo "1280x720" ;;
        *)      echo "$1" ;;
    esac
}

# Get available display outputs
get_display_outputs() {
    run_on_pi5 "DISPLAY=$VNC_DISPLAY xrandr --query | grep ' connected' | cut -d' ' -f1" || return 1
}

# Function to show current resolution
show_current_resolution() {
    print_header "Current Resolution"
    
    # Check SSH connectivity first
    if ! run_on_pi5 "echo 'SSH connection successful'" > /dev/null; then
        print_error "Cannot connect to Pi5"
        return 1
    }

    # Get current resolution for each connected output
    local outputs
    outputs=$(get_display_outputs)
    if [ $? -ne 0 ]; then
        print_error "Failed to get display outputs"
        return 1
    }

    while IFS= read -r output; do
        local current
        current=$(run_on_pi5 "DISPLAY=$VNC_DISPLAY xrandr | grep -A1 '^$output' | grep '*'")
        echo -e "${YELLOW}$output${NC}: $current"
    done <<< "$outputs"

    # Show VNC server status
    print_header "VNC Server Status"
    run_on_pi5 "systemctl status vncserver-x11-serviced.service | grep -E 'Active|running'"
}

# Function to change resolution
change_resolution() {
    local requested="$1"
    local resolution
    resolution=$(get_resolution "$requested")
    
    print_header "Changing Resolution to $resolution"
    
    # Check SSH connectivity
    if ! run_on_pi5 "echo 'SSH connection successful'" > /dev/null; then
        print_error "Cannot connect to Pi5"
        return 1
    }
    
    # Get available outputs
    local outputs
    outputs=$(get_display_outputs)
    if [ $? -ne 0 ]; then
        print_error "Failed to get display outputs"
        return 1
    }
    
    local success=0
    while IFS= read -r output; do
        print_status "Attempting to set $resolution on $output..."
        if run_on_pi5 "DISPLAY=$VNC_DISPLAY xrandr --output $output --mode $resolution" > /dev/null 2>&1; then
            print_status "Successfully set resolution on $output"
            success=1
        else
            print_error "Failed to set resolution on $output"
        fi
    done <<< "$outputs"
    
    if [ $success -eq 1 ]; then
        show_current_resolution
    else
        print_error "Failed to set resolution on any output"
        return 1
    fi
}

# Show available resolutions
show_available_resolutions() {
    print_header "Available Resolutions"
    echo "4K    (3840x2160)"
    echo "8K    (7680x4320)"
    echo "1080p (1920x1080)"
    echo "720p  (1280x720)"
    echo "Custom (WIDTHxHEIGHT)"
}

# Show connection info
show_connection_info() {
    print_header "Connection Information"
    echo "Host: $PI5_HOST"
    echo "SSH Key: $SSH_KEY"
    echo "Display: $VNC_DISPLAY"
}

# Main script
if [ $# -eq 0 ]; then
    show_current_resolution
    echo
    show_available_resolutions
    echo
    show_connection_info
else
    change_resolution "$1"
fi