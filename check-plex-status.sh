#!/bin/bash

# Check Plex Server Status on Pi5
# Usage: ./check-plex-status.sh [IP_ADDRESS]

PI5_IP=${1:-"192.168.50.243"}
PLEX_PORT="32400"
PLEX_WEB_PORT="32400"

echo "🔍 Checking Plex Server Status on Pi5 ($PI5_IP)"
echo "=================================================="

# Function to check if port is open
check_port() {
    local ip=$1
    local port=$2
    local service=$3
    
    if nc -z -w5 "$ip" "$port" 2>/dev/null; then
        echo "✅ $service is running on $ip:$port"
        return 0
    else
        echo "❌ $service is NOT running on $ip:$port"
        return 1
    fi
}

# Function to check HTTP response
check_http() {
    local ip=$1
    local port=$2
    local url="http://$ip:$port"
    
    echo "🌐 Checking HTTP response from $url"
    
    # Try to get HTTP response
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "✅ Plex web interface is accessible"
        echo "📱 You can access Plex at: $url"
        return 0
    elif [ "$response" = "401" ] || [ "$response" = "403" ]; then
        echo "✅ Plex server is running (authentication required)"
        echo "📱 You can access Plex at: $url"
        return 0
    else
        echo "❌ Plex web interface not accessible (HTTP $response)"
        return 1
    fi
}

# Function to check Plex service status via SSH
check_plex_service() {
    echo "🔧 Checking Plex service status..."
    
    # Try to check if Plex service is running via SSH
    if command -v ssh >/dev/null 2>&1; then
        echo "Attempting to check Plex service via SSH..."
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "systemctl is-active plexmediaserver" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Plex service is active"
        else
            echo "⚠️  Could not check Plex service via SSH (SSH may not be enabled or configured)"
        fi
    else
        echo "⚠️  SSH client not available for service check"
    fi
}

# Main checks
echo "1. Checking if Pi5 is reachable..."
if ping -c 1 -W 5000 "$PI5_IP" >/dev/null 2>&1; then
    echo "✅ Pi5 ($PI5_IP) is reachable"
else
    echo "❌ Pi5 ($PI5_IP) is NOT reachable"
    echo "   Check your network connection and Pi5 power status"
    exit 1
fi

echo ""
echo "2. Checking Plex server port ($PLEX_PORT)..."
plex_running=false
if check_port "$PI5_IP" "$PLEX_PORT" "Plex Server"; then
    plex_running=true
fi

echo ""
echo "3. Checking Plex web interface..."
if check_http "$PI5_IP" "$PLEX_WEB_PORT"; then
    plex_running=true
fi

echo ""
echo "4. Additional service check..."
check_plex_service

echo ""
echo "📺 TV Discovery Information:"
echo "============================"
if [ "$plex_running" = true ]; then
    echo "✅ Plex server appears to be running"
    echo "📡 Your TV should be able to discover the Plex server"
    echo "🌐 Plex web interface: http://$PI5_IP:$PLEX_WEB_PORT"
    echo ""
    echo "💡 Troubleshooting tips:"
    echo "   - Make sure your TV and Pi5 are on the same network"
    echo "   - Check if UPnP/DLNA is enabled on your TV"
    echo "   - Try refreshing the network discovery on your TV"
    echo "   - Some TVs may need to manually add the server at: $PI5_IP:$PLEX_PORT"
else
    echo "❌ Plex server does not appear to be running"
    echo ""
    echo "🔧 To start Plex server on Pi5:"
    echo "   ssh ian@$PI5_IP"
    echo "   sudo systemctl start plexmediaserver"
    echo "   sudo systemctl enable plexmediaserver"
fi

echo ""
echo "🔍 Additional Network Information:"
echo "=================================="
echo "Pi5 IP: $PI5_IP"
echo "Plex Port: $PLEX_PORT"
echo "Network: $(route -n get default | grep gateway | awk '{print $2}' | head -1)/24"
