#!/bin/bash

# Check Photo Portfolio Web App Status on Pi5
# Usage: ./check-photo-portfolio.sh [IP_ADDRESS] [PORT]

PI5_IP=${1:-"192.168.50.243"}
PHOTO_PORT=${2:-"3000"}  # Default port for Node.js apps

echo "📸 Checking Photo Portfolio Web App Status on Pi5 ($PI5_IP)"
echo "=========================================================="

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
        echo "✅ Photo Portfolio web app is accessible"
        echo "📱 You can access the app at: $url"
        return 0
    elif [ "$response" = "404" ]; then
        echo "⚠️  Server is running but app may not be deployed (HTTP 404)"
        return 1
    else
        echo "❌ Photo Portfolio web app not accessible (HTTP $response)"
        return 1
    fi
}

# Function to check common web app ports
check_common_ports() {
    echo "🔍 Checking common web app ports..."
    
    local ports=("3000" "3001" "8080" "8000" "5000" "4000")
    local found_port=""
    
    for port in "${ports[@]}"; do
        if nc -z -w3 "$PI5_IP" "$port" 2>/dev/null; then
            echo "✅ Found service running on port $port"
            found_port="$port"
        fi
    done
    
    if [ -n "$found_port" ]; then
        echo "🌐 Checking if port $found_port is the photo portfolio app..."
        check_http "$PI5_IP" "$found_port"
        return 0
    else
        echo "❌ No web services found on common ports"
        return 1
    fi
}

# Function to check photo portfolio service status via SSH
check_photo_service() {
    echo "🔧 Checking photo portfolio service status..."
    
    # Try to check if photo portfolio service is running via SSH
    if command -v ssh >/dev/null 2>&1; then
        echo "Attempting to check photo portfolio service via SSH..."
        
        # Check for common process names
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "ps aux | grep -E '(node|npm|photo|portfolio)' | grep -v grep" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Found photo portfolio related processes"
        else
            echo "⚠️  No photo portfolio processes found"
        fi
        
        # Check if there's a systemd service
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "systemctl list-units --type=service | grep -i photo" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Found photo portfolio systemd service"
        else
            echo "⚠️  No photo portfolio systemd service found"
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
echo "2. Checking photo portfolio port ($PHOTO_PORT)..."
photo_running=false
if check_port "$PI5_IP" "$PHOTO_PORT" "Photo Portfolio"; then
    photo_running=true
fi

echo ""
echo "3. Checking photo portfolio web interface..."
if check_http "$PI5_IP" "$PHOTO_PORT"; then
    photo_running=true
fi

echo ""
echo "4. Checking other common web app ports..."
if [ "$photo_running" = false ]; then
    if check_common_ports; then
        photo_running=true
    fi
fi

echo ""
echo "5. Additional service check..."
check_photo_service

echo ""
echo "📸 Photo Portfolio Access Information:"
echo "====================================="
if [ "$photo_running" = true ]; then
    echo "✅ Photo Portfolio web app appears to be running"
    echo "🌐 Web interface: http://$PI5_IP:$PHOTO_PORT"
    echo ""
    echo "💡 Access instructions:"
    echo "   - Open your web browser"
    echo "   - Navigate to: http://$PI5_IP:$PHOTO_PORT"
    echo "   - The photo portfolio should load automatically"
else
    echo "❌ Photo Portfolio web app does not appear to be running"
    echo ""
    echo "🔧 To start Photo Portfolio on Pi5:"
    echo "   ssh ian@$PI5_IP"
    echo "   cd /path/to/photo-portfolio"
    echo "   npm start"
    echo "   # or if using PM2:"
    echo "   pm2 start photo-portfolio"
    echo "   # or if using systemd:"
    echo "   sudo systemctl start photo-portfolio"
fi

echo ""
echo "🔍 Additional Network Information:"
echo "=================================="
echo "Pi5 IP: $PI5_IP"
echo "Photo Portfolio Port: $PHOTO_PORT"
echo "Network: $(route -n get default | grep gateway | awk '{print $2}' | head -1)/24"

echo ""
echo "🛠️  Troubleshooting Commands:"
echo "============================="
echo "Check all listening ports:"
echo "  nmap -p 1-65535 $PI5_IP"
echo ""
echo "SSH into Pi5:"
echo "  ssh ian@$PI5_IP"
echo ""
echo "Check running processes:"
echo "  ssh ian@$PI5_IP 'ps aux | grep node'"
echo ""
echo "Check systemd services:"
echo "  ssh ian@$PI5_IP 'systemctl list-units --type=service | grep photo'"
