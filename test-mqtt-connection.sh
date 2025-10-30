#!/bin/bash
# Diagnostic script to test MQTT connectivity
# Run this on your Bridge Pi to troubleshoot MQTT connection issues

MQTT_BROKER="192.168.1.231"  # Update with your Home Assistant IP
MQTT_PORT="1883"
MQTT_USER="mqtt_user"        # Update with your MQTT username
MQTT_PASS="mqtt_password"    # Update with your MQTT password

echo "=== MQTT Connection Diagnostics ==="
echo ""

# Check if running on the Bridge Pi
echo "1. Network connectivity check..."
echo "   Testing if MQTT broker is reachable at $MQTT_BROKER..."
if ping -c 3 $MQTT_BROKER > /dev/null 2>&1; then
    echo "   ✓ Ping successful - network is reachable"
else
    echo "   ✗ FAILED - Cannot ping $MQTT_BROKER"
    echo "   Check if the IP address is correct and both Pis are on the same network"
    exit 1
fi
echo ""

# Check port connectivity
echo "2. Port connectivity check..."
echo "   Testing if port $MQTT_PORT is open..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$MQTT_BROKER/$MQTT_PORT" 2>/dev/null; then
    echo "   ✓ Port $MQTT_PORT is open and accepting connections"
else
    echo "   ✗ FAILED - Cannot connect to port $MQTT_PORT"
    echo ""
    echo "   Possible causes:"
    echo "   - Mosquitto MQTT broker is not running on the Home Assistant Pi"
    echo "   - Firewall is blocking port 1883"
    echo "   - MQTT broker is configured to listen on localhost only"
    echo ""
    echo "   On your Home Assistant Pi, check:"
    echo "   - Is Mosquitto add-on running?"
    echo "   - Run: sudo netstat -tlnp | grep 1883"
    echo "     (Should show: 0.0.0.0:1883 not 127.0.0.1:1883)"
    exit 1
fi
echo ""

# Check if mosquitto_pub/sub are installed
echo "3. Checking for MQTT client tools..."
if ! command -v mosquitto_pub &> /dev/null; then
    echo "   mosquitto_pub not found. Installing mosquitto-clients..."
    sudo apt-get update && sudo apt-get install -y mosquitto-clients
fi

if command -v mosquitto_pub &> /dev/null; then
    echo "   ✓ MQTT client tools available"
else
    echo "   ✗ FAILED - Could not install mosquitto-clients"
    exit 1
fi
echo ""

# Test MQTT publish
echo "4. Testing MQTT authentication and publish..."
echo "   Attempting to publish test message..."

PUBLISH_RESULT=$(mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT \
    -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "test/connection" -m "test from $(hostname)" \
    2>&1)

if [ $? -eq 0 ]; then
    echo "   ✓ Successfully published to MQTT broker!"
    echo "   Authentication is working correctly"
else
    echo "   ✗ FAILED - Could not publish to MQTT broker"
    echo ""
    echo "   Error: $PUBLISH_RESULT"
    echo ""
    echo "   Possible causes:"
    echo "   - Incorrect username/password"
    echo "   - Anonymous access disabled (check Mosquitto config)"
    echo "   - ACL (Access Control List) restrictions"
    echo ""
    echo "   On your Home Assistant Pi:"
    echo "   - Check Mosquitto add-on configuration"
    echo "   - Verify username/password are correct"
    echo "   - Check logs: Home Assistant > Settings > Add-ons > Mosquitto > Logs"
    exit 1
fi
echo ""

# Test MQTT subscribe (in background)
echo "5. Testing MQTT subscribe..."
echo "   Subscribing to test topic (will timeout after 5 seconds)..."

timeout 5 mosquitto_sub -h $MQTT_BROKER -p $MQTT_PORT \
    -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "test/#" -C 1 &> /dev/null &

sleep 1

# Publish while subscribed
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT \
    -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "test/subscribe" -m "subscribe test" &> /dev/null

sleep 1

if [ $? -eq 0 ]; then
    echo "   ✓ Subscribe/publish test successful!"
else
    echo "   ⚠ Subscribe test had issues (may not be critical)"
fi
echo ""

# Check Python MQTT library
echo "6. Checking Python MQTT library..."
PYTHON_TEST=$(/opt/xiaomi-ble-bridge/venv/bin/python3 -c "
import paho.mqtt.client as mqtt
import sys

try:
    client = mqtt.Client(client_id='test_client', callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.username_pw_set('$MQTT_USER', '$MQTT_PASS')
    
    connected = False
    def on_connect(client, userdata, flags, rc, properties=None):
        global connected
        connected = True
    
    client.on_connect = on_connect
    client.connect('$MQTT_BROKER', $MQTT_PORT, 60)
    client.loop_start()
    
    import time
    for i in range(10):
        if connected:
            print('SUCCESS')
            client.loop_stop()
            client.disconnect()
            sys.exit(0)
        time.sleep(1)
    
    print('TIMEOUT')
    client.loop_stop()
    sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)

if echo "$PYTHON_TEST" | grep -q "SUCCESS"; then
    echo "   ✓ Python MQTT connection successful!"
    echo ""
    echo "=== All tests passed! ==="
    echo "Your MQTT connection is working correctly."
    echo ""
    echo "If the service still fails, check:"
    echo "  sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py"
    echo "  - Verify MQTT_BROKER matches: $MQTT_BROKER"
    echo "  - Verify MQTT_USERNAME matches: $MQTT_USER"
    echo "  - Verify MQTT_PASSWORD is correct"
else
    echo "   ✗ Python MQTT connection failed!"
    echo "   Result: $PYTHON_TEST"
    echo ""
    echo "   Try updating the script on your Bridge Pi:"
    echo "   The script may have a bug or incompatible MQTT library version"
fi
echo ""

# Show current configuration
echo "=== Current Configuration ==="
echo "Bridge Pi hostname: $(hostname)"
echo "MQTT Broker IP: $MQTT_BROKER"
echo "MQTT Port: $MQTT_PORT"
echo "MQTT Username: $MQTT_USER"
echo ""
echo "Check your configuration file at:"
echo "/opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py"









