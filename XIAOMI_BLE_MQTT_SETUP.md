# Xiaomi BLE to MQTT Bridge Setup Guide

This guide helps you connect a Xiaomi temperature/humidity sensor via Bluetooth to your Raspberry Pi 5, then relay the data via MQTT to Home Assistant running on another Pi.

## Architecture

```
Xiaomi Sensor (BLE) → Pi 5 #1 (Bridge) → MQTT → Pi 5 #2 (Home Assistant)
```

## Prerequisites

### Hardware
- Xiaomi LYWSD03MMC (or compatible) temperature/humidity sensor
- Raspberry Pi 5 #1 (BLE Bridge) - the one you'll run the bridge script on
- Raspberry Pi 5 #2 (Home Assistant OS) - running Home Assistant
- Both Pis on the same network

### Software on Home Assistant Pi
- Home Assistant OS installed
- MQTT broker (Mosquitto) installed via Add-ons

## Step 1: Set Up MQTT Broker on Home Assistant

1. Open Home Assistant web interface
2. Go to **Settings** → **Add-ons** → **Add-on Store**
3. Install **Mosquitto broker**
4. Configure the add-on:
   ```yaml
   logins:
     - username: mqtt_user
       password: your_secure_password
   require_certificate: false
   ```
5. Start the Mosquitto broker add-on
6. Enable "Start on boot"

## Step 2: Enable MQTT Integration in Home Assistant

1. Go to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for **MQTT**
4. Configure:
   - Broker: `localhost` (or IP if on different machine)
   - Port: `1883`
   - Username: `mqtt_user`
   - Password: `your_secure_password`
5. Enable **Enable discovery**

## Step 3: Find Your Xiaomi Sensor's MAC Address

On your Bridge Pi (Pi #1), run:

```bash
sudo bluetoothctl
scan on
# Wait for devices to appear, look for "LYWSD03MMC" or similar
# Note the MAC address (e.g., A4:C1:38:XX:XX:XX)
scan off
exit
```

## Step 4: Install the Bridge on Raspberry Pi #1

1. Copy the setup script and bridge script to your Pi:
   ```bash
   scp xiaomi_ble_mqtt_bridge.py setup-xiaomi-ble-bridge.sh pi@<PI_IP>:~/
   ```

2. SSH into your Bridge Pi:
   ```bash
   ssh pi@<PI_IP>
   ```

3. Run the setup script:
   ```bash
   chmod +x setup-xiaomi-ble-bridge.sh
   ./setup-xiaomi-ble-bridge.sh
   ```

## Step 5: Configure the Bridge

Edit the configuration file:
```bash
sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py
```

Update these settings:
```python
# Xiaomi Sensor Configuration
SENSOR_MAC = "A4:C1:38:XX:XX:XX"  # Your sensor's MAC address
SENSOR_NAME = "bedroom_sensor"     # Friendly name

# MQTT Configuration
MQTT_BROKER = "192.168.1.XXX"      # Home Assistant Pi IP
MQTT_PORT = 1883
MQTT_USERNAME = "mqtt_user"         # From Step 1
MQTT_PASSWORD = "your_secure_password"  # From Step 1

# Update interval (seconds)
UPDATE_INTERVAL = 60  # Read sensor every 60 seconds
```

Save and exit (Ctrl+X, Y, Enter)

## Step 6: Start the Bridge Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable xiaomi-ble-bridge.service

# Start the service
sudo systemctl start xiaomi-ble-bridge.service

# Check status
sudo systemctl status xiaomi-ble-bridge.service
```

## Step 7: Monitor and Verify

### Check the service logs:
```bash
sudo journalctl -u xiaomi-ble-bridge.service -f
```

You should see output like:
```
Connected to MQTT broker
Found device: LYWSD03MMC (A4:C1:38:XX:XX:XX)
Connected to A4:C1:38:XX:XX:XX
Temperature: 23.45°C, Humidity: 55%
Battery: 89%
Published Home Assistant discovery configuration
Successfully updated sensor data
```

### In Home Assistant:
1. Go to **Settings** → **Devices & Services** → **MQTT**
2. You should see your sensor auto-discovered
3. Go to **Developer Tools** → **States**
4. Search for `sensor.bedroom_sensor_temperature` (or your sensor name)
5. You should see the temperature value updating

## Troubleshooting

### Bluetooth connection issues:
```bash
# Restart Bluetooth
sudo systemctl restart bluetooth

# Check if device is visible
sudo hcitool lescan

# Check Bluetooth status
sudo systemctl status bluetooth
```

### MQTT connection issues:
```bash
# Test MQTT connection from Bridge Pi
sudo apt-get install mosquitto-clients
mosquitto_sub -h 192.168.1.XXX -p 1883 -u mqtt_user -P your_password -t 'homeassistant/#' -v
```

### Permission issues:
The service runs as root to access Bluetooth. If you want to run as pi user:
```bash
sudo usermod -a -G bluetooth pi
sudo setcap cap_net_raw+ep $(eval readlink -f `which python3`)
```
Then edit the service file to use `User=pi`

### Sensor not found:
- Ensure sensor has fresh batteries (>20%)
- Sensor should be within 10m of the Pi
- Some sensors require pairing first (use `bluetoothctl`)
- Try removing and reinserting batteries in sensor

### Home Assistant not discovering:
- Check MQTT integration is enabled with discovery
- Verify MQTT broker is running
- Check the MQTT discovery topic:
  ```bash
  mosquitto_sub -h localhost -p 1883 -u mqtt_user -P your_password -t 'homeassistant/#' -v
  ```

## Adding Multiple Sensors

To add more sensors:

1. Copy the script with a new name:
   ```bash
   sudo cp /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py \
          /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge_living_room.py
   ```

2. Edit the new script with different MAC and sensor name

3. Create another systemd service pointing to the new script

4. Start the new service

## Commands Reference

```bash
# Start service
sudo systemctl start xiaomi-ble-bridge.service

# Stop service
sudo systemctl stop xiaomi-ble-bridge.service

# Restart service
sudo systemctl restart xiaomi-ble-bridge.service

# View logs (live)
sudo journalctl -u xiaomi-ble-bridge.service -f

# View logs (last 100 lines)
sudo journalctl -u xiaomi-ble-bridge.service -n 100

# Check service status
sudo systemctl status xiaomi-ble-bridge.service

# Disable auto-start
sudo systemctl disable xiaomi-ble-bridge.service
```

## MQTT Topics

The bridge publishes to these topics:

- `homeassistant/sensor/{SENSOR_NAME}/temperature` - Temperature data
- `homeassistant/sensor/{SENSOR_NAME}/humidity` - Humidity data
- `homeassistant/sensor/{SENSOR_NAME}/battery` - Battery level
- `homeassistant/sensor/{SENSOR_NAME}/state` - Combined state

Discovery topics:
- `homeassistant/sensor/{SENSOR_NAME}_temperature/config`
- `homeassistant/sensor/{SENSOR_NAME}_humidity/config`
- `homeassistant/sensor/{SENSOR_NAME}_battery/config`

## Advanced Configuration

### Custom Update Intervals
Edit the script and change:
```python
UPDATE_INTERVAL = 60  # Seconds between readings
```

Recommendations:
- Minimum: 30 seconds (to preserve battery)
- Default: 60 seconds (good balance)
- Maximum: 600 seconds (10 minutes for battery saving)

### Logging Levels
```python
LOG_LEVEL = logging.INFO   # Standard logging
LOG_LEVEL = logging.DEBUG  # Verbose logging for troubleshooting
LOG_LEVEL = logging.WARNING  # Minimal logging
```

## Compatible Sensors

This script works with:
- Xiaomi LYWSD03MMC (Tested)
- Xiaomi LYWSDCGQ
- Xiaomi MHO-C401
- Other Xiaomi/Mijia sensors using similar BLE characteristics

For other sensors, you may need to adjust the UUIDs in the script.

## Resources

- [Bleak Documentation](https://bleak.readthedocs.io/)
- [Paho MQTT Documentation](https://www.eclipse.org/paho/index.php?page=clients/python/index.php)
- [Home Assistant MQTT Discovery](https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery)


