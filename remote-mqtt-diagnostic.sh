#!/bin/bash
# Remote MQTT Diagnostic - Run from Mac to test Pi5 MQTT connection

set -e

# Configuration
BRIDGE_PI="ian@192.168.50.243"  # Your Bridge Pi5
HA_PI_IP="192.168.1.231"        # Your Home Assistant Pi
MQTT_PORT="1883"
MQTT_USER="mqtt_user"           # Update if different
MQTT_PASS="mqtt_password"       # Update if different

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Remote MQTT Connection Diagnostics ===${NC}"
echo -e "Bridge Pi5: ${YELLOW}$BRIDGE_PI${NC}"
echo -e "Home Assistant: ${YELLOW}$HA_PI_IP:$MQTT_PORT${NC}"
echo ""

# Test SSH connection to Bridge Pi
echo -e "${BLUE}1. Testing SSH connection to Bridge Pi...${NC}"
if ssh -o ConnectTimeout=10 "$BRIDGE_PI" "echo 'Connected'" >/dev/null 2>&1; then
    echo -e "   ${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "   ${RED}✗ FAILED - Cannot SSH to $BRIDGE_PI${NC}"
    exit 1
fi
echo ""

# Check network connectivity from Pi5 to HA
echo -e "${BLUE}2. Testing network connectivity from Pi5 to Home Assistant...${NC}"
if ssh "$BRIDGE_PI" "ping -c 3 $HA_PI_IP" >/dev/null 2>&1; then
    echo -e "   ${GREEN}✓ Network connectivity OK${NC}"
else
    echo -e "   ${RED}✗ Cannot ping Home Assistant from Bridge Pi${NC}"
    echo -e "   Check network configuration"
    exit 1
fi
echo ""

# Check port connectivity
echo -e "${BLUE}3. Testing MQTT port $MQTT_PORT connectivity...${NC}"
PORT_TEST=$(ssh "$BRIDGE_PI" "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/$HA_PI_IP/$MQTT_PORT' 2>&1 && echo 'SUCCESS' || echo 'FAILED'")
if echo "$PORT_TEST" | grep -q "SUCCESS"; then
    echo -e "   ${GREEN}✓ Port $MQTT_PORT is open and accessible${NC}"
else
    echo -e "   ${RED}✗ Cannot connect to port $MQTT_PORT${NC}"
    echo -e "   ${YELLOW}Possible issues:${NC}"
    echo -e "   - Mosquitto MQTT broker not running on Home Assistant"
    echo -e "   - Firewall blocking port 1883"
    echo -e "   - Mosquitto listening on localhost only (127.0.0.1)"
    echo ""
    echo -e "   ${YELLOW}Check on Home Assistant:${NC}"
    echo -e "   - Settings → Add-ons → Mosquitto broker (is it running?)"
    exit 1
fi
echo ""

# Install mosquitto-clients if needed
echo -e "${BLUE}4. Installing MQTT client tools on Bridge Pi (if needed)...${NC}"
ssh "$BRIDGE_PI" "command -v mosquitto_pub >/dev/null 2>&1 || sudo apt-get update -qq && sudo apt-get install -y mosquitto-clients >/dev/null 2>&1"
if ssh "$BRIDGE_PI" "command -v mosquitto_pub >/dev/null 2>&1"; then
    echo -e "   ${GREEN}✓ MQTT client tools ready${NC}"
else
    echo -e "   ${RED}✗ Failed to install mosquitto-clients${NC}"
    exit 1
fi
echo ""

# Test MQTT publish
echo -e "${BLUE}5. Testing MQTT authentication and publish...${NC}"
MQTT_TEST=$(ssh "$BRIDGE_PI" "mosquitto_pub -h $HA_PI_IP -p $MQTT_PORT -u '$MQTT_USER' -P '$MQTT_PASS' -t 'test/diagnostic' -m 'test from $(hostname)' 2>&1 && echo 'SUCCESS' || echo 'FAILED'")

if echo "$MQTT_TEST" | grep -q "SUCCESS"; then
    echo -e "   ${GREEN}✓ MQTT publish successful!${NC}"
    echo -e "   ${GREEN}✓ Authentication working${NC}"
else
    echo -e "   ${RED}✗ MQTT publish failed${NC}"
    echo -e "   Error output: ${YELLOW}$MQTT_TEST${NC}"
    echo ""
    echo -e "   ${YELLOW}Possible issues:${NC}"
    echo -e "   - Incorrect username/password"
    echo -e "   - Mosquitto authentication not configured"
    echo -e "   - ACL restrictions"
    echo ""
    echo -e "   ${YELLOW}Check Mosquitto config in Home Assistant:${NC}"
    echo -e "   Settings → Add-ons → Mosquitto broker → Configuration"
    exit 1
fi
echo ""

# Check if Python venv exists
echo -e "${BLUE}6. Checking Python environment on Bridge Pi...${NC}"
if ssh "$BRIDGE_PI" "test -d /opt/xiaomi-ble-bridge/venv"; then
    echo -e "   ${GREEN}✓ Python virtual environment exists${NC}"
else
    echo -e "   ${YELLOW}⚠ Virtual environment not found at /opt/xiaomi-ble-bridge/venv${NC}"
    echo -e "   The service may not be installed yet"
fi
echo ""

# Test Python MQTT connection
echo -e "${BLUE}7. Testing Python MQTT library connection...${NC}"
PYTHON_TEST=$(ssh "$BRIDGE_PI" "sudo /opt/xiaomi-ble-bridge/venv/bin/python3 << 'PYEOF'
import paho.mqtt.client as mqtt
import sys
import time

try:
    connected = False
    
    def on_connect(client, userdata, flags, rc, properties=None):
        global connected
        if rc == 0:
            connected = True
            print('MQTT_CONNECTED')
        else:
            print(f'MQTT_ERROR_RC_{rc}')
    
    client = mqtt.Client(
        client_id='diagnostic_test',
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2
    )
    client.username_pw_set('$MQTT_USER', '$MQTT_PASS')
    client.on_connect = on_connect
    
    client.connect('$HA_PI_IP', $MQTT_PORT, 60)
    client.loop_start()
    
    # Wait for connection
    for i in range(10):
        if connected:
            client.loop_stop()
            client.disconnect()
            sys.exit(0)
        time.sleep(1)
    
    print('MQTT_TIMEOUT')
    client.loop_stop()
    sys.exit(1)
    
except Exception as e:
    print(f'PYTHON_ERROR: {e}')
    sys.exit(1)
PYEOF
" 2>&1)

if echo "$PYTHON_TEST" | grep -q "MQTT_CONNECTED"; then
    echo -e "   ${GREEN}✓ Python MQTT connection successful!${NC}"
    echo ""
    echo -e "${GREEN}=== All diagnostics passed! ===${NC}"
    echo -e "Your MQTT connection is working correctly from the Bridge Pi."
else
    echo -e "   ${RED}✗ Python MQTT connection failed${NC}"
    echo -e "   Output: ${YELLOW}$PYTHON_TEST${NC}"
    echo ""
    if echo "$PYTHON_TEST" | grep -q "MQTT_TIMEOUT"; then
        echo -e "   ${YELLOW}Connection timed out - same issue as the service${NC}"
    fi
fi
echo ""

# Check service status
echo -e "${BLUE}8. Checking xiaomi-ble-bridge service status...${NC}"
SERVICE_STATUS=$(ssh "$BRIDGE_PI" "systemctl is-active xiaomi-ble-bridge.service 2>&1 || echo 'inactive'")
if [ "$SERVICE_STATUS" = "active" ]; then
    echo -e "   ${GREEN}✓ Service is running${NC}"
else
    echo -e "   ${YELLOW}⚠ Service is $SERVICE_STATUS${NC}"
fi

# Show recent logs
echo ""
echo -e "${BLUE}9. Recent service logs (last 10 lines):${NC}"
ssh "$BRIDGE_PI" "sudo journalctl -u xiaomi-ble-bridge.service -n 10 --no-pager" 2>/dev/null || echo "Service not found"
echo ""

# Show current configuration
echo -e "${BLUE}=== Current Configuration ===${NC}"
CONFIG_CHECK=$(ssh "$BRIDGE_PI" "sudo grep -E '(MQTT_BROKER|MQTT_PORT|MQTT_USERNAME|SENSOR_MAC)' /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py 2>/dev/null | grep -v '^#' | head -5" || echo "Configuration file not found")
echo "$CONFIG_CHECK"
echo ""

echo -e "${BLUE}=== Summary ===${NC}"
echo -e "Bridge Pi5: $BRIDGE_PI"
echo -e "Home Assistant: $HA_PI_IP:$MQTT_PORT"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Verify MQTT credentials in config file match Home Assistant"
echo -e "2. If tests passed but service fails, update the script on Pi5"
echo -e "3. Check service logs: ssh $BRIDGE_PI 'sudo journalctl -u xiaomi-ble-bridge.service -f'"









