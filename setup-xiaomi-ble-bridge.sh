#!/bin/bash
# Setup script for Xiaomi BLE to MQTT Bridge on Raspberry Pi 5

set -e

echo "=== Xiaomi BLE to MQTT Bridge Setup ==="
echo ""

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "Warning: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    bluetooth \
    bluez \
    libbluetooth-dev

# Enable and start Bluetooth service
echo "Enabling Bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Create directory for the bridge service
INSTALL_DIR="/opt/xiaomi-ble-bridge"
echo "Creating installation directory: $INSTALL_DIR"
sudo mkdir -p $INSTALL_DIR

# Copy the Python script
echo "Installing bridge script..."
sudo cp xiaomi_ble_mqtt_bridge.py $INSTALL_DIR/
sudo chmod +x $INSTALL_DIR/xiaomi_ble_mqtt_bridge.py

# Create virtual environment
echo "Creating Python virtual environment..."
sudo python3 -m venv $INSTALL_DIR/venv

# Install Python dependencies
echo "Installing Python packages (bleak, paho-mqtt)..."
sudo $INSTALL_DIR/venv/bin/pip install --upgrade pip
sudo $INSTALL_DIR/venv/bin/pip install bleak paho-mqtt

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/xiaomi-ble-bridge.service > /dev/null <<EOF
[Unit]
Description=Xiaomi BLE to MQTT Bridge
After=network.target bluetooth.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python3 $INSTALL_DIR/xiaomi_ble_mqtt_bridge.py
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Find your Xiaomi sensor's MAC address:"
echo "   sudo bluetoothctl"
echo "   scan on"
echo "   (Look for your device, note the MAC address)"
echo "   scan off"
echo "   exit"
echo ""
echo "2. Edit the configuration in $INSTALL_DIR/xiaomi_ble_mqtt_bridge.py:"
echo "   sudo nano $INSTALL_DIR/xiaomi_ble_mqtt_bridge.py"
echo "   - Set SENSOR_MAC to your sensor's MAC address"
echo "   - Set MQTT_BROKER to your Home Assistant Pi's IP"
echo "   - Set MQTT_USERNAME and MQTT_PASSWORD if needed"
echo "   - Adjust SENSOR_NAME and UPDATE_INTERVAL as desired"
echo ""
echo "3. Enable and start the service:"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable xiaomi-ble-bridge.service"
echo "   sudo systemctl start xiaomi-ble-bridge.service"
echo ""
echo "4. Check the service status:"
echo "   sudo systemctl status xiaomi-ble-bridge.service"
echo "   sudo journalctl -u xiaomi-ble-bridge.service -f"
echo ""
echo "5. In Home Assistant, enable MQTT integration and the sensors should"
echo "   auto-discover via MQTT Discovery protocol!"


