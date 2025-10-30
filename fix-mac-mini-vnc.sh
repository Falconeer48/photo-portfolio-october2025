#!/bin/bash

# Mac Mini VNC Configuration Fix
# This script fixes VNC scaling and fullscreen issues on Mac Mini

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="192.168.50.243"
VNC_PORT="5900"

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

print_header "Mac Mini VNC Configuration Fix"
echo ""

print_status "$BLUE" "This script will help fix VNC scaling and fullscreen issues on your Mac Mini"
echo ""

# 1. Check current VNC client
print_header "1. Checking VNC Client"
print_status "$BLUE" "Checking which VNC client you're using..."

if command -v vncviewer >/dev/null 2>&1; then
    print_status "$GREEN" "✅ TigerVNC viewer found"
    VNC_CLIENT="tigervnc"
elif [ -d "/Applications/VNC Viewer.app" ]; then
    print_status "$GREEN" "✅ RealVNC Viewer found"
    VNC_CLIENT="realvnc"
elif [ -d "/System/Library/CoreServices/Screen Sharing.app" ]; then
    print_status "$GREEN" "✅ Built-in Screen Sharing found"
    VNC_CLIENT="screensharing"
else
    print_status "$RED" "❌ No VNC client found"
    exit 1
fi

print_status "$BLUE" "Using: $VNC_CLIENT"

# 2. Create VNC connection scripts with proper settings
print_header "2. Creating VNC Connection Scripts"

# Create TigerVNC connection script
if [ "$VNC_CLIENT" = "tigervnc" ]; then
    print_status "$BLUE" "Creating TigerVNC connection script..."
    
    cat > ~/connect-vnc-pi5.sh << 'EOF'
#!/bin/bash
# TigerVNC connection to Pi5 with proper scaling

PI5_HOST="192.168.50.243"
VNC_PORT="5900"

echo "Connecting to Pi5 with TigerVNC..."
echo "Host: $PI5_HOST:$VNC_PORT"
echo ""

# Connect with proper scaling settings
vncviewer \
    -FullScreen=0 \
    -Scaling=FitToWindow \
    -PreferredEncoding=Tight \
    -CompressLevel=6 \
    -QualityLevel=6 \
    "$PI5_HOST:$VNC_PORT"
EOF

    chmod +x ~/connect-vnc-pi5.sh
    print_status "$GREEN" "✅ TigerVNC script created: ~/connect-vnc-pi5.sh"
fi

# Create RealVNC connection script
if [ "$VNC_CLIENT" = "realvnc" ]; then
    print_status "$BLUE" "Creating RealVNC connection script..."
    
    cat > ~/connect-vnc-pi5-realvnc.sh << 'EOF'
#!/bin/bash
# RealVNC connection to Pi5 with proper settings

PI5_HOST="192.168.50.243"
VNC_PORT="5900"

echo "Connecting to Pi5 with RealVNC Viewer..."
echo "Host: $PI5_HOST:$VNC_PORT"
echo ""

# Open RealVNC Viewer with specific settings
open -a "VNC Viewer" "vnc://$PI5_HOST:$VNC_PORT"
EOF

    chmod +x ~/connect-vnc-pi5-realvnc.sh
    print_status "$GREEN" "✅ RealVNC script created: ~/connect-vnc-pi5-realvnc.sh"
fi

# Create Screen Sharing connection script
if [ "$VNC_CLIENT" = "screensharing" ]; then
    print_status "$BLUE" "Creating Screen Sharing connection script..."
    
    cat > ~/connect-vnc-pi5-screensharing.sh << 'EOF'
#!/bin/bash
# Screen Sharing connection to Pi5

PI5_HOST="192.168.50.243"
VNC_PORT="5900"

echo "Connecting to Pi5 with Screen Sharing..."
echo "Host: $PI5_HOST:$VNC_PORT"
echo ""

# Open Screen Sharing
open "vnc://$PI5_HOST:$VNC_PORT"
EOF

    chmod +x ~/connect-vnc-pi5-screensharing.sh
    print_status "$GREEN" "✅ Screen Sharing script created: ~/connect-vnc-pi5-screensharing.sh"
fi

# 3. Create VNC configuration file
print_header "3. Creating VNC Configuration"

# Create TigerVNC config directory
mkdir -p ~/.vnc

# Create TigerVNC config file
cat > ~/.vnc/vncviewerrc << 'EOF'
# TigerVNC Viewer Configuration
# This file contains default settings for VNC connections

# Display settings
FullScreen=0
Scaling=FitToWindow
PreferredEncoding=Tight
CompressLevel=6
QualityLevel=6

# Window settings
Geometry=1024x768
FullScreen=0

# Performance settings
Shared=0
SendCutText=1
AcceptCutText=1
EOF

print_status "$GREEN" "✅ VNC configuration file created: ~/.vnc/vncviewerrc"

# 4. Create desktop shortcut
print_header "4. Creating Desktop Shortcut"

# Create a desktop shortcut
cat > ~/Desktop/Connect-to-Pi5.command << 'EOF'
#!/bin/bash
# Desktop shortcut to connect to Pi5

cd ~
./connect-vnc-pi5.sh
EOF

chmod +x ~/Desktop/Connect-to-Pi5.command
print_status "$GREEN" "✅ Desktop shortcut created: ~/Desktop/Connect-to-Pi5.command"

# 5. Create alternative connection methods
print_header "5. Alternative Connection Methods"

print_status "$BLUE" "Creating alternative connection methods..."

# Method 1: Windowed connection
cat > ~/connect-vnc-windowed.sh << 'EOF'
#!/bin/bash
# Windowed VNC connection to Pi5

PI5_HOST="192.168.50.243"
VNC_PORT="5900"

echo "Connecting to Pi5 in windowed mode..."
echo "Host: $PI5_HOST:$VNC_PORT"
echo ""

# Connect in windowed mode with specific geometry
vncviewer \
    -FullScreen=0 \
    -Geometry=1024x768 \
    -Scaling=FitToWindow \
    "$PI5_HOST:$VNC_PORT"
EOF

chmod +x ~/connect-vnc-windowed.sh

# Method 2: Custom resolution connection
cat > ~/connect-vnc-custom.sh << 'EOF'
#!/bin/bash
# Custom resolution VNC connection to Pi5

PI5_HOST="192.168.50.243"
VNC_PORT="5900"

echo "Connecting to Pi5 with custom resolution..."
echo "Host: $PI5_HOST:$VNC_PORT"
echo ""

# Connect with custom resolution
vncviewer \
    -FullScreen=0 \
    -Geometry=1280x720 \
    -Scaling=FitToWindow \
    -PreferredEncoding=Tight \
    "$PI5_HOST:$VNC_PORT"
EOF

chmod +x ~/connect-vnc-custom.sh

print_status "$GREEN" "✅ Alternative connection methods created"

# 6. Instructions
print_header "6. Usage Instructions"
print_status "$GREEN" "✅ VNC configuration completed!"
echo ""

print_status "$BLUE" "To connect to Pi5 from your Mac Mini:"
echo ""

if [ "$VNC_CLIENT" = "tigervnc" ]; then
    print_status "$GREEN" "Method 1 - Use the connection script:"
    print_status "$BLUE" "   ~/connect-vnc-pi5.sh"
    echo ""
    print_status "$GREEN" "Method 2 - Use windowed mode:"
    print_status "$BLUE" "   ~/connect-vnc-windowed.sh"
    echo ""
    print_status "$GREEN" "Method 3 - Use custom resolution:"
    print_status "$BLUE" "   ~/connect-vnc-custom.sh"
    echo ""
    print_status "$GREEN" "Method 4 - Manual command:"
    print_status "$BLUE" "   vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST:$VNC_PORT"
fi

if [ "$VNC_CLIENT" = "realvnc" ]; then
    print_status "$GREEN" "Method 1 - Use the connection script:"
    print_status "$BLUE" "   ~/connect-vnc-pi5-realvnc.sh"
    echo ""
    print_status "$GREEN" "Method 2 - Manual command:"
    print_status "$BLUE" "   open -a \"VNC Viewer\" \"vnc://$PI5_HOST:$VNC_PORT\""
fi

if [ "$VNC_CLIENT" = "screensharing" ]; then
    print_status "$GREEN" "Method 1 - Use the connection script:"
    print_status "$BLUE" "   ~/connect-vnc-pi5-screensharing.sh"
    echo ""
    print_status "$GREEN" "Method 2 - Manual command:"
    print_status "$BLUE" "   open \"vnc://$PI5_HOST:$VNC_PORT\""
fi

echo ""
print_status "$YELLOW" "Key settings to prevent fullscreen and scaling issues:"
print_status "$YELLOW" "• -FullScreen=0 (prevents fullscreen)"
print_status "$YELLOW" "• -Scaling=FitToWindow (scales to fit window)"
print_status "$YELLOW" "• -Geometry=1024x768 (sets window size)"
echo ""

print_status "$PURPLE" "Desktop shortcut created: ~/Desktop/Connect-to-Pi5.command"
print_status "$PURPLE" "Double-click the desktop shortcut to connect!"
echo ""

print_header "Mac Mini VNC Fix Complete"
print_status "$GREEN" "✅ Mac Mini VNC configuration completed!"
echo ""

