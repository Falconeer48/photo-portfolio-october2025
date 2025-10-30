# MQTT Setup Summary - Almost There! 🎉

## What We Fixed

✅ **Network Issue Resolved!** 
- Problem: Bridge Pi (`192.168.50.243`) couldn't reach Home Assistant at `192.168.1.231`
- Solution: Updated to correct IP `192.168.50.231` (both on same network)

✅ **MQTT Connection Working!**
- Port 1883 is accessible
- Bridge can connect to MQTT broker
- Fixed MQTT API deprecation warnings

✅ **Service Configured and Running**
- Script installed at `/opt/xiaomi-ble-bridge/`
- Systemd service created and enabled
- Auto-starts on boot

## What's Left: MQTT Credentials

The service is now getting **"Not authorized"** error, which means you need to update the MQTT username and password.

### Option 1: Quick Manual Update (Recommended)

1. **Get your MQTT credentials from Home Assistant:**
   - Open Home Assistant web interface at: `http://192.168.50.231:8123`
   - Go to: **Settings → Add-ons → Mosquitto broker → Configuration**
   - Note the username and password from the `logins` section

2. **Update the configuration on your Bridge Pi:**
   ```bash
   ssh ian@192.168.50.243
   sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py
   ```

3. **Find and edit lines 32-33:**
   ```python
   MQTT_USERNAME = "your_actual_username"    # Change this
   MQTT_PASSWORD = "your_actual_password"    # Change this
   ```

4. **Also update line 26 with your sensor's MAC address:**
   ```python
   SENSOR_MAC = "A4:C1:38:XX:XX:XX"  # Change to your Xiaomi sensor's MAC
   ```

5. **Save (Ctrl+X, Y, Enter) and restart:**
   ```bash
   sudo systemctl restart xiaomi-ble-bridge.service
   sudo journalctl -u xiaomi-ble-bridge.service -f
   ```

### Option 2: Use Interactive Configuration Script

From your Mac, run:
```bash
./configure-mqtt-credentials.sh
```

This will test your credentials and configure everything automatically.

## Finding Your Xiaomi Sensor's MAC Address

If you haven't found your sensor's MAC address yet:

```bash
ssh ian@192.168.50.243
sudo bluetoothctl
scan on
# Wait for your sensor to appear (usually shows as "LYWSD03MMC")
# Note the MAC address (format: A4:C1:38:XX:XX:XX)
scan off
exit
```

## Testing the Complete Setup

Once credentials are updated, you should see in the logs:

```
✓ Connected to MQTT broker
✓ Published Home Assistant discovery configuration
✓ Scanning for device A4:C1:38:XX:XX:XX...
✓ Found device: LYWSD03MMC
✓ Temperature: 23.4°C, Humidity: 55%
✓ Successfully updated sensor data
```

## Home Assistant Integration

Once working, sensors will auto-appear in Home Assistant:
- `sensor.bedroom_sensor_temperature`
- `sensor.bedroom_sensor_humidity`
- `sensor.bedroom_sensor_battery`

Check: **Settings → Devices & Services → MQTT**

## Useful Commands

### Check service status:
```bash
ssh ian@192.168.50.243 'sudo systemctl status xiaomi-ble-bridge.service'
```

### View live logs:
```bash
ssh ian@192.168.50.243 'sudo journalctl -u xiaomi-ble-bridge.service -f'
```

### Restart service:
```bash
ssh ian@192.168.50.243 'sudo systemctl restart xiaomi-ble-bridge.service'
```

### Stop service:
```bash
ssh ian@192.168.50.243 'sudo systemctl stop xiaomi-ble-bridge.service'
```

## Files Created

On your Mac (in `/Users/ian/Scripts/`):
- `xiaomi_ble_mqtt_bridge.py` - Main bridge script
- `setup-xiaomi-ble-bridge.sh` - Installation script
- `xiaomi-ble-bridge-control.sh` - Remote control commands
- `remote-mqtt-diagnostic.sh` - Network diagnostics
- `configure-mqtt-credentials.sh` - Credential configuration helper
- `test-mqtt-connection.sh` - MQTT connection tester
- `XIAOMI_BLE_MQTT_SETUP.md` - Complete documentation
- `fix-mqtt-homeassistant.md` - Troubleshooting guide

On your Bridge Pi (`192.168.50.243`):
- `/opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py` - Running script
- `/opt/xiaomi-ble-bridge/venv/` - Python virtual environment
- `/etc/systemd/system/xiaomi-ble-bridge.service` - Service file

## Current Status

```
Network:         ✅ Working (192.168.50.243 → 192.168.50.231:1883)
MQTT Connection: ✅ Working (port accessible, connecting)
Authentication:  ❌ Needs credentials
BLE Sensor:      ⏸️  Pending (need MAC address)
```

## Next Steps

1. Update MQTT username/password (see Option 1 or 2 above)
2. Find and update your Xiaomi sensor's MAC address
3. Restart the service
4. Check Home Assistant for auto-discovered sensors!

---

**You're almost done!** Just need those credentials and you'll be up and running! 🚀









