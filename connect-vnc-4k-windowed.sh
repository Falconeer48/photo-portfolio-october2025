#!/bin/bash

# VNC 4K Windowed Connection Script
# Connects to Pi5 VNC in 4K resolution with windowed mode

# Configuration
PI5_HOST="ian@192.168.50.243"
VNC_PORT="5900"

echo "🖥️  Connecting to Pi5 VNC in windowed mode..."
echo "📍 Host: $PI5_HOST"
echo "🔌 Port: $VNC_PORT"
echo ""

# Check if TigerVNC is available
if command -v vncviewer &> /dev/null; then
    echo "✅ Using TigerVNC for optimal windowed experience"
    echo "🚀 Starting VNC connection..."
    vncviewer -FullScreen=0 -Scaling=FitToWindow "$PI5_HOST:$VNC_PORT"
elif command -v open &> /dev/null; then
    echo "✅ Using macOS Screen Sharing"
    echo "🚀 Starting VNC connection..."
    open "vnc://$PI5_HOST:$VNC_PORT"
else
    echo "❌ No VNC client found. Please install TigerVNC or use RealVNC Viewer"
    echo "💡 Install TigerVNC: brew install tigervnc"
    exit 1
fi

echo ""
echo "🎯 Connection started! The VNC window should open shortly."
echo "📏 Resolution: Current Pi5 VNC resolution"
echo "🪟 Mode: Windowed (not full screen)"
