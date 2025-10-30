#!/bin/bash
# Fix VNC clipboard synchronization between Mac and Pi5

PI5="ian@192.168.50.243"

echo "=== VNC Clipboard Fix for Pi5 ==="
echo ""

echo "1. Checking if autocutsel is installed..."
if ssh $PI5 "command -v autocutsel >/dev/null 2>&1"; then
    echo "   ✓ autocutsel is installed"
else
    echo "   Installing autocutsel..."
    ssh $PI5 "sudo apt-get update -qq && sudo apt-get install -y autocutsel"
fi
echo ""

echo "2. Creating clipboard sync startup script..."
ssh $PI5 "cat > /tmp/start-clipboard.sh << 'EOF'
#!/bin/bash
# Start clipboard synchronization for VNC
export DISPLAY=:1
autocutsel -fork -selection PRIMARY
autocutsel -fork -selection CLIPBOARD
EOF
chmod +x /tmp/start-clipboard.sh
sudo mv /tmp/start-clipboard.sh /usr/local/bin/start-vnc-clipboard.sh"
echo "   ✓ Script created"
echo ""

echo "3. Creating autostart entry..."
ssh $PI5 "mkdir -p ~/.config/autostart && cat > ~/.config/autostart/vnc-clipboard.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=VNC Clipboard Sync
Comment=Synchronize clipboard between VNC client and server
Exec=/usr/local/bin/start-vnc-clipboard.sh
Terminal=false
StartupNotify=false
EOF"
echo "   ✓ Autostart configured"
echo ""

echo "4. Starting clipboard sync now..."
ssh $PI5 "DISPLAY=:1 autocutsel -fork -selection PRIMARY >/dev/null 2>&1; DISPLAY=:1 autocutsel -fork -selection CLIPBOARD >/dev/null 2>&1"
echo "   ✓ Clipboard sync started"
echo ""

echo "5. Restarting VNC server..."
ssh $PI5 "sudo systemctl restart vncserver-x11-serviced"
echo "   ✓ VNC server restarted"
echo ""

echo "=== Setup Complete! ==="
echo ""
echo "Clipboard sync should now work and will auto-start after reboots."
echo ""
echo "If it still doesn't work after reconnecting VNC:"
echo "1. Close VNC Viewer completely on your Mac"
echo "2. Reopen and reconnect"
echo ""
echo "Or run this anytime:"
echo "  ssh $PI5 'DISPLAY=:1 autocutsel -fork -selection PRIMARY; DISPLAY=:1 autocutsel -fork -selection CLIPBOARD'"








