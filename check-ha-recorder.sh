#!/bin/bash
# Check Home Assistant recorder configuration

HA_PI="ian@192.168.50.231"

echo "=== Checking Home Assistant Recorder Configuration ==="
echo ""

# Try to find configuration.yaml
echo "Looking for configuration.yaml..."
CONFIG_PATHS=(
    "/config/configuration.yaml"
    "/root/config/configuration.yaml"
    "/usr/share/hassio/homeassistant/configuration.yaml"
    "~/.homeassistant/configuration.yaml"
)

for path in "${CONFIG_PATHS[@]}"; do
    if ssh $HA_PI "test -f $path 2>/dev/null"; then
        echo "✓ Found at: $path"
        echo ""
        echo "Checking for recorder configuration..."
        RECORDER_CONFIG=$(ssh $HA_PI "grep -A 20 '^recorder:' $path 2>/dev/null || echo 'NOT_FOUND'")
        
        if [ "$RECORDER_CONFIG" != "NOT_FOUND" ]; then
            echo "Found recorder configuration:"
            echo "----------------------------------------"
            echo "$RECORDER_CONFIG"
            echo "----------------------------------------"
            echo ""
            
            if echo "$RECORDER_CONFIG" | grep -q "include:"; then
                echo "⚠️  You have an 'include:' section in your recorder config."
                echo "   You SHOULD add your sensors to the include list."
                echo ""
                echo "Add these lines to your recorder: include: section:"
                echo ""
                echo "  domains:"
                echo "    - sensor"
                echo "  entity_globs:"
                echo "    - sensor.pi5_sensor_*"
                echo ""
            else
                echo "✓ No 'include:' restrictions found."
                echo "  Your sensors should be automatically recorded!"
            fi
        else
            echo "✓ No custom recorder configuration found."
            echo "  Using Home Assistant defaults - your sensors will be recorded automatically!"
        fi
        exit 0
    fi
done

echo "⚠️  Could not access Home Assistant configuration file."
echo ""
echo "To check manually:"
echo "1. Open Home Assistant"
echo "2. Go to Developer Tools → States"
echo "3. Search for: sensor.pi5_sensor_temperature"
echo "4. If you see the sensor, it's being recorded!"
echo ""
echo "Or check the configuration file directly:"
echo "ssh $HA_PI 'cat /config/configuration.yaml | grep -A 20 recorder'"








