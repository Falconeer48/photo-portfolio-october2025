#!/bin/bash

# VNC Diagnostic Script for Pi 5
# This script diagnoses VNC connection and screen resolution issues between Mac Mini and Pi 5

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
VNC_PORT="5900"
VNC_DISPLAY=":0"

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

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_status "$GREEN" "✅ $1"
    else
        print_status "$RED" "❌ $1"
    fi
}

print_header "VNC Diagnostic for Pi 5"
echo ""

# 1. Check Pi5 connectivity
print_header "1. Pi5 Connectivity Check"
print_status "$BLUE" "Testing connection to Pi5..."

if ping -c 1 -W 3 "192.168.50.243" >/dev/null 2>&1; then
    print_status "$GREEN" "✅ Pi5 is reachable via ping"
else
    print_status "$RED" "❌ Cannot ping Pi5"
    exit 1
fi

if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$PI5_HOST" "echo 'SSH test successful'" >/dev/null 2>&1; then
    print_status "$GREEN" "✅ SSH connection to Pi5 successful"
else
    print_status "$RED" "❌ SSH connection to Pi5 failed"
    exit 1
fi

# 2. Check VNC server status
print_header "2. VNC Server Status"
print_status "$BLUE" "Checking VNC server status..."

VNC_STATUS=$(run_on_pi5 "systemctl is-active vncserver@:0" 2>/dev/null)
if [ "$VNC_STATUS" = "active" ]; then
    print_status "$GREEN" "✅ VNC server is running"
else
    print_status "$RED" "❌ VNC server is not running (status: $VNC_STATUS)"
    print_status "$YELLOW" "💡 Try: ssh $PI5_HOST 'sudo systemctl start vncserver@:0'"
fi

VNC_ENABLED=$(run_on_pi5 "systemctl is-enabled vncserver@:0" 2>/dev/null)
if [ "$VNC_ENABLED" = "enabled" ]; then
    print_status "$GREEN" "✅ VNC server is enabled for auto-start"
else
    print_status "$YELLOW" "⚠️  VNC server is not enabled for auto-start"
    print_status "$YELLOW" "💡 Try: ssh $PI5_HOST 'sudo systemctl enable vncserver@:0'"
fi

# 3. Check VNC processes
print_header "3. VNC Processes"
print_status "$BLUE" "Checking running VNC processes..."

VNC_PROCESSES=$(run_on_pi5 "ps aux | grep vnc | grep -v grep")
if [ -n "$VNC_PROCESSES" ]; then
    print_status "$GREEN" "✅ VNC processes found:"
    echo "$VNC_PROCESSES"
else
    print_status "$RED" "❌ No VNC processes found"
fi

# 4. Check VNC port status
print_header "4. VNC Port Status"
print_status "$BLUE" "Checking VNC port $VNC_PORT..."

if run_on_pi5 "netstat -tlnp | grep :$VNC_PORT" >/dev/null 2>&1; then
    print_status "$GREEN" "✅ VNC port $VNC_PORT is listening"
    PORT_INFO=$(run_on_pi5 "netstat -tlnp | grep :$VNC_PORT")
    print_status "$BLUE" "   Port info: $PORT_INFO"
else
    print_status "$RED" "❌ VNC port $VNC_PORT is not listening"
fi

# 5. Check display configuration
print_header "5. Display Configuration"
print_status "$BLUE" "Checking display configuration..."

# Check current resolution
CURRENT_RES=$(run_on_pi5 "xrandr --current 2>/dev/null | grep '*' | head -1")
if [ -n "$CURRENT_RES" ]; then
    print_status "$GREEN" "✅ Current resolution: $CURRENT_RES"
else
    print_status "$RED" "❌ Cannot determine current resolution"
fi

# Check available resolutions
print_status "$BLUE" "Available resolutions:"
AVAILABLE_RES=$(run_on_pi5 "xrandr 2>/dev/null | grep -E '[0-9]+x[0-9]+'")
if [ -n "$AVAILABLE_RES" ]; then
    echo "$AVAILABLE_RES" | while read -r line; do
        if [[ $line == *"*"* ]]; then
            print_status "$GREEN" "   📺 $line (current)"
        else
            print_status "$BLUE" "   📺 $line"
        fi
    done
else
    print_status "$RED" "❌ Cannot get available resolutions"
fi

# 6. Check VNC configuration files
print_header "6. VNC Configuration Files"
print_status "$BLUE" "Checking VNC configuration..."

# Check vncserver config
VNC_CONFIG=$(run_on_pi5 "ls -la ~/.vnc/ 2>/dev/null")
if [ -n "$VNC_CONFIG" ]; then
    print_status "$GREEN" "✅ VNC config directory exists:"
    echo "$VNC_CONFIG"
else
    print_status "$RED" "❌ VNC config directory not found"
fi

# Check xstartup file
XSTARTUP=$(run_on_pi5 "cat ~/.vnc/xstartup 2>/dev/null")
if [ -n "$XSTARTUP" ]; then
    print_status "$GREEN" "✅ xstartup file found:"
    echo "$XSTARTUP"
else
    print_status "$RED" "❌ xstartup file not found"
fi

# 7. Check desktop environment
print_header "7. Desktop Environment"
print_status "$BLUE" "Checking desktop environment..."

DESKTOP_ENV=$(run_on_pi5 "echo \$XDG_CURRENT_DESKTOP 2>/dev/null")
if [ -n "$DESKTOP_ENV" ]; then
    print_status "$GREEN" "✅ Desktop environment: $DESKTOP_ENV"
else
    print_status "$YELLOW" "⚠️  Desktop environment not set"
fi

# Check if X server is running
X_SERVER=$(run_on_pi5 "ps aux | grep X | grep -v grep")
if [ -n "$X_SERVER" ]; then
    print_status "$GREEN" "✅ X server is running"
else
    print_status "$RED" "❌ X server is not running"
fi

# 8. Test VNC connection from Mac
print_header "8. VNC Connection Test"
print_status "$BLUE" "Testing VNC connection from Mac..."

# Check if VNC client is available
if command -v vncviewer >/dev/null 2>&1; then
    print_status "$GREEN" "✅ VNC viewer is available"
    
    # Test connection (non-interactive)
    print_status "$BLUE" "Testing connection to $PI5_HOST:$VNC_PORT..."
    if timeout 10 vncviewer -list "$PI5_HOST:$VNC_PORT" >/dev/null 2>&1; then
        print_status "$GREEN" "✅ VNC connection test successful"
    else
        print_status "$RED" "❌ VNC connection test failed"
    fi
else
    print_status "$YELLOW" "⚠️  VNC viewer not found"
    print_status "$YELLOW" "💡 Install with: brew install tigervnc"
fi

# 9. Check system resources
print_header "9. System Resources"
print_status "$BLUE" "Checking Pi5 system resources..."

# CPU usage
CPU_USAGE=$(run_on_pi5 "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1")
print_status "$BLUE" "CPU usage: ${CPU_USAGE}%"

# Memory usage
MEMORY_USAGE=$(run_on_pi5 "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'")
print_status "$BLUE" "Memory usage: ${MEMORY_USAGE}%"

# Disk usage
DISK_USAGE=$(run_on_pi5 "df -h / | awk 'NR==2{printf \"%s\", \$5}'")
print_status "$BLUE" "Disk usage: $DISK_USAGE"

# 10. Recommendations
print_header "10. VNC Troubleshooting Recommendations"

print_status "$BLUE" "Based on the diagnostic results:"

if [ "$VNC_STATUS" != "active" ]; then
    print_status "$YELLOW" "🔧 Start VNC server:"
    print_status "$YELLOW" "   ssh $PI5_HOST 'sudo systemctl start vncserver@:0'"
fi

if [ "$VNC_ENABLED" != "enabled" ]; then
    print_status "$YELLOW" "🔧 Enable VNC server:"
    print_status "$YELLOW" "   ssh $PI5_HOST 'sudo systemctl enable vncserver@:0'"
fi

print_status "$YELLOW" "🔧 For screen resolution issues:"
print_status "$YELLOW" "   1. Set resolution: ssh $PI5_HOST 'xrandr --output HDMI-1 --mode 1920x1080'"
print_status "$YELLOW" "   2. Check HDMI connection and monitor"
print_status "$YELLOW" "   3. Restart VNC: ssh $PI5_HOST 'sudo systemctl restart vncserver@:0'"

print_status "$YELLOW" "🔧 For connection issues:"
print_status "$YELLOW" "   1. Check firewall: ssh $PI5_HOST 'sudo ufw status'"
print_status "$YELLOW" "   2. Test with: vncviewer $PI5_HOST:$VNC_PORT"
print_status "$YELLOW" "   3. Check VNC logs: ssh $PI5_HOST 'journalctl -u vncserver@:0 -f'"

print_status "$BLUE" "🔧 Common VNC commands:"
print_status "$BLUE" "   - Connect: vncviewer $PI5_HOST:$VNC_PORT"
print_status "$BLUE" "   - Set resolution: ssh $PI5_HOST 'xrandr --output HDMI-1 --mode 1920x1080'"
print_status "$BLUE" "   - Restart VNC: ssh $PI5_HOST 'sudo systemctl restart vncserver@:0'"
print_status "$BLUE" "   - View logs: ssh $PI5_HOST 'journalctl -u vncserver@:0 -f'"

print_header "VNC Diagnostic Complete"
print_status "$GREEN" "✅ VNC diagnostic completed!"
echo ""







