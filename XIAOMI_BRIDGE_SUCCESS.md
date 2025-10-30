# 🎉 Xiaomi BLE to MQTT Bridge - FULLY OPERATIONAL!

## System Status: ✅ WORKING PERFECTLY

Your Xiaomi temperature and humidity sensor is now successfully bridged to Home Assistant via MQTT!

### Current Configuration

**Bridge Pi5:** `192.168.50.243` (mypi5)  
**Home Assistant:** `192.168.50.231:8123`  
**MQTT Broker:** `192.168.50.231:1883`  
**Sensor Model:** LYWSD03MMC (Xiaomi Mi Temperature & Humidity Monitor 2)  
**Sensor MAC:** `A4:C1:38:D9:37:E6`  
**Update Interval:** 60 seconds

### Latest Readings

- 🌡️ **Temperature:** 23.63°C
- 💧 **Humidity:** 50%
- 🔋 **Battery:** 99%

### Home Assistant Integration

Your sensors should now appear in Home Assistant at:

**Check these locations:**
1. **Settings → Devices & Services → MQTT**
   - You should see "bedroom_sensor" device
   
2. **Developer Tools → States**
   - Search for: `sensor.bedroom_sensor_temperature`
   - Search for: `sensor.bedroom_sensor_humidity`
   - Search for: `sensor.bedroom_sensor_battery`

3. **Add to Dashboard:**
   - Go to your dashboard
   - Click "Edit Dashboard"
   - Click "+ Add Card"
   - Search for your sensors and add them!

### Service Management

**Check status:**
```bash
ssh ian@192.168.50.243 'sudo systemctl status xiaomi-ble-bridge.service'
```

**View live updates:**
```bash
ssh ian@192.168.50.243 'sudo journalctl -u xiaomi-ble-bridge.service -f'
```

**Restart service:**
```bash
ssh ian@192.168.50.243 'sudo systemctl restart xiaomi-ble-bridge.service'
```

**Stop service:**
```bash
ssh ian@192.168.50.243 'sudo systemctl stop xiaomi-ble-bridge.service'
```

### What's Happening Behind the Scenes

Every 60 seconds, your Bridge Pi5:
1. ✅ Scans for your Xiaomi sensor via Bluetooth
2. ✅ Connects to the sensor
3. ✅ Reads temperature, humidity, and battery level
4. ✅ Publishes the data to MQTT broker
5. ✅ Home Assistant receives the update automatically

### MQTT Topics

Your sensor data is published to:
- `homeassistant/sensor/bedroom_sensor/temperature`
- `homeassistant/sensor/bedroom_sensor/humidity`
- `homeassistant/sensor/bedroom_sensor/battery`
- `homeassistant/sensor/bedroom_sensor/state` (combined)

### Security Recommendation (Optional)

Currently using your main MQTT account (`ian`). For better security, consider creating a dedicated MQTT user:

**In Home Assistant Mosquitto Configuration:**
```yaml
logins:
  - username: ian
    password: Falcon1959
  - username: xiaomi_bridge    # Add this
    password: bridge_password123  # Add this
```

Then update on your Bridge Pi:
```bash
ssh ian@192.168.50.243
sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py
# Change lines 32-33 to new credentials
sudo systemctl restart xiaomi-ble-bridge.service
```

### Adding More Sensors

To add another Xiaomi sensor:

1. **Find the new sensor's MAC address:**
   ```bash
   ssh ian@192.168.50.243
   sudo bluetoothctl
   scan on
   # Note the MAC address
   scan off
   exit
   ```

2. **Create a new bridge instance:**
   ```bash
   ssh ian@192.168.50.243
   sudo cp /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py \
          /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge_living_room.py
   sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge_living_room.py
   # Change SENSOR_MAC and SENSOR_NAME (e.g., "living_room_sensor")
   ```

3. **Create new systemd service:**
   ```bash
   sudo cp /etc/systemd/system/xiaomi-ble-bridge.service \
          /etc/systemd/system/xiaomi-ble-bridge-living-room.service
   sudo nano /etc/systemd/system/xiaomi-ble-bridge-living-room.service
   # Update ExecStart path to point to new script
   sudo systemctl daemon-reload
   sudo systemctl enable xiaomi-ble-bridge-living-room.service
   sudo systemctl start xiaomi-ble-bridge-living-room.service
   ```

### Troubleshooting

**Service not running?**
```bash
ssh ian@192.168.50.243 'sudo journalctl -u xiaomi-ble-bridge.service -n 50'
```

**Sensor not found?**
- Make sure sensor has fresh batteries (>20%)
- Keep sensor within 10m of the Pi5
- Press the button on the sensor to wake it up

**MQTT connection issues?**
```bash
ssh ian@192.168.50.243 'mosquitto_pub -h 192.168.50.231 -p 1883 -u ian -P Falcon1959 -t test/topic -m "test"'
```

### Files and Locations

**On Bridge Pi5 (192.168.50.243):**
- Config: `/opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py`
- Service: `/etc/systemd/system/xiaomi-ble-bridge.service`
- Python env: `/opt/xiaomi-ble-bridge/venv/`

**On your Mac (/Users/ian/Scripts/):**
- Main script: `xiaomi_ble_mqtt_bridge.py`
- Setup guide: `XIAOMI_BLE_MQTT_SETUP.md`
- Diagnostics: `remote-mqtt-diagnostic.sh`
- Testing: `test-xiaomi-sensor.py`

### Auto-Start on Boot

✅ **Already configured!** The service will start automatically when your Pi5 boots.

---

## 🎊 Congratulations!

You now have a fully functional Bluetooth-to-MQTT bridge running on your Raspberry Pi5!

Your Xiaomi sensor data is flowing:
**Sensor (BLE) → Pi5 Bridge (BLE→MQTT) → Home Assistant (MQTT) → Dashboard**

Enjoy your automated home monitoring! 🏠📊

---

**Date Configured:** October 9, 2025  
**Bridge Pi:** mypi5 (192.168.50.243)  
**Sensor:** LYWSD03MMC (A4:C1:38:D9:37:E6)  
**Status:** ✅ OPERATIONAL









