#!/bin/bash
# Configure MQTT credentials for Xiaomi BLE Bridge

BRIDGE_PI="ian@192.168.50.243"
HA_IP="192.168.50.231"
CONFIG_FILE="/opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py"

echo "=== MQTT Credentials Configuration ==="
echo ""
echo "This script will help you configure the correct MQTT credentials"
echo "for your Xiaomi BLE to MQTT Bridge."
echo ""
echo "Home Assistant: $HA_IP"
echo "Bridge Pi: $BRIDGE_PI"
echo ""

# First, try anonymous access
echo "1. Testing anonymous MQTT access..."
ANON_TEST=$(ssh $BRIDGE_PI "mosquitto_pub -h $HA_IP -p 1883 -t 'test/anon' -m 'test' 2>&1 && echo 'SUCCESS' || echo 'FAILED'")

if echo "$ANON_TEST" | grep -q "SUCCESS"; then
    echo "   ✓ Anonymous access works!"
    echo ""
    read -p "Do you want to use anonymous access (no username/password)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Configuring for anonymous access..."
        ssh $BRIDGE_PI "sudo sed -i '138,139s/^/#/' $CONFIG_FILE"
        echo "Done! Service will use anonymous MQTT access"
        ssh $BRIDGE_PI "sudo systemctl restart xiaomi-ble-bridge.service"
        echo "Service restarted. Checking logs..."
        sleep 3
        ssh $BRIDGE_PI "sudo journalctl -u xiaomi-ble-bridge.service -n 10 --no-pager"
        exit 0
    fi
fi

echo ""
echo "2. Testing with credentials..."
echo ""
echo "Please enter your MQTT credentials from Home Assistant:"
echo "(Settings → Add-ons → Mosquitto broker → Configuration)"
echo ""
read -p "MQTT Username: " mqtt_user
read -s -p "MQTT Password: " mqtt_pass
echo ""
echo ""

# Test credentials
echo "Testing credentials..."
TEST_RESULT=$(ssh $BRIDGE_PI "mosquitto_pub -h $HA_IP -p 1883 -u '$mqtt_user' -P '$mqtt_pass' -t 'test/creds' -m 'test' 2>&1 && echo 'SUCCESS' || echo 'FAILED'")

if echo "$TEST_RESULT" | grep -q "SUCCESS"; then
    echo "✓ Credentials work!"
    echo ""
    echo "Updating configuration file..."
    
    # Update username
    ssh $BRIDGE_PI "sudo sed -i '32s/.*/MQTT_USERNAME = \"$mqtt_user\"         # MQTT username/' $CONFIG_FILE"
    
    # Update password
    ssh $BRIDGE_PI "sudo sed -i '33s/.*/MQTT_PASSWORD = \"$mqtt_pass\"     # MQTT password/' $CONFIG_FILE"
    
    echo "✓ Configuration updated"
    echo ""
    echo "Restarting service..."
    ssh $BRIDGE_PI "sudo systemctl restart xiaomi-ble-bridge.service"
    
    echo ""
    echo "Waiting for service to start..."
    sleep 5
    
    echo ""
    echo "=== Service Status ==="
    ssh $BRIDGE_PI "sudo systemctl status xiaomi-ble-bridge.service --no-pager -l | head -15"
    
    echo ""
    echo "=== Recent Logs ==="
    ssh $BRIDGE_PI "sudo journalctl -u xiaomi-ble-bridge.service -n 15 --no-pager"
    
else
    echo "✗ Credentials failed!"
    echo "Error: $TEST_RESULT"
    echo ""
    echo "Please check your Home Assistant Mosquitto configuration:"
    echo "1. Open Home Assistant web interface"
    echo "2. Go to Settings → Add-ons → Mosquitto broker"
    echo "3. Check the Configuration tab for the username/password"
    echo ""
    echo "Make sure the user is added in the 'logins' section:"
    echo "logins:"
    echo "  - username: your_username"
    echo "    password: your_password"
    exit 1
fi









