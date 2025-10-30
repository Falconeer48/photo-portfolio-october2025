# Fix MQTT Connection Timeout to Home Assistant

Your bridge is timing out when connecting to the MQTT broker. Here's how to fix it:

## Quick Diagnosis

Run this on your **Bridge Pi** (the one running the xiaomi-ble-bridge service):

```bash
# Transfer and run the diagnostic script
chmod +x test-mqtt-connection.sh
./test-mqtt-connection.sh
```

## Common Issue: Mosquitto Listening on localhost Only

The most common problem is that Mosquitto in Home Assistant is configured to listen only on `localhost` (127.0.0.1) instead of all network interfaces (0.0.0.0).

### Fix on Home Assistant Pi:

1. **Open Home Assistant Web Interface**

2. **Go to Settings → Add-ons → Mosquitto broker**

3. **Check the Configuration tab** and ensure it looks like this:

```yaml
logins:
  - username: mqtt_user
    password: your_secure_password
anonymous: false
customize:
  active: false
  folder: mosquitto
certfile: fullchain.pem
keyfile: privkey.pem
require_certificate: false
```

4. **Go to the Configuration tab at the top (YAML editor)**

5. **If you see a `network` section limiting the listener, you may need to add:**

Click on the three dots (⋮) → "Edit in YAML"

Add or modify the listener configuration:

```yaml
logins:
  - username: mqtt_user
    password: your_secure_password
anonymous: false
```

6. **Save and restart the Mosquitto add-on**

### Verify Mosquitto is Listening on All Interfaces

SSH into your **Home Assistant Pi** (if possible) and run:

```bash
# Check if Mosquitto is listening
netstat -tlnp | grep 1883

# OR use ss if netstat isn't available
ss -tlnp | grep 1883
```

**Good output** (listening on all interfaces):
```
tcp        0      0 0.0.0.0:1883            0.0.0.0:*               LISTEN
```

**Bad output** (listening on localhost only):
```
tcp        0      0 127.0.0.1:1883          0.0.0.0:*               LISTEN
```

### If Running Home Assistant OS (Can't SSH)

If you can't SSH into the Home Assistant Pi, try these steps:

1. **Enable SSH Add-on in Home Assistant:**
   - Settings → Add-ons → Add-on Store
   - Install "Terminal & SSH"
   - Configure and start it

2. **Check Mosquitto Logs:**
   - Settings → Add-ons → Mosquitto broker → Logs
   - Look for errors about authentication or connection attempts

3. **Test from Bridge Pi:**
```bash
# Try to connect to MQTT from your Bridge Pi
mosquitto_pub -h 192.168.1.231 -p 1883 -u mqtt_user -P your_password -t test/topic -m "hello"
```

## Other Common Issues

### 1. Firewall Blocking Port 1883

On **Home Assistant Pi**, ensure port 1883 isn't blocked:

```bash
# If using ufw
sudo ufw allow 1883/tcp

# If using firewalld
sudo firewall-cmd --permanent --add-port=1883/tcp
sudo firewall-cmd --reload
```

### 2. Wrong IP Address

Double-check the IP address of your Home Assistant Pi:

On Home Assistant Pi:
```bash
hostname -I
# or
ip addr show
```

Update the bridge script with the correct IP:
```bash
sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py
# Change MQTT_BROKER to the correct IP
```

### 3. MQTT Broker Not Running

In Home Assistant:
- Settings → Add-ons → Mosquitto broker
- Ensure it's **Started** and **Start on boot** is enabled

### 4. Authentication Issues

Verify credentials match:

In `/opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py`:
```python
MQTT_USERNAME = "mqtt_user"
MQTT_PASSWORD = "your_password"  # Must match Home Assistant config
```

In Home Assistant Mosquitto configuration:
```yaml
logins:
  - username: mqtt_user
    password: your_password
```

## After Fixing

1. **Update the bridge script** on your Bridge Pi with the fixed version (updated API):

```bash
# Stop the service
sudo systemctl stop xiaomi-ble-bridge.service

# Update the script (copy the new version)
# Then restart
sudo systemctl start xiaomi-ble-bridge.service

# Check logs
sudo journalctl -u xiaomi-ble-bridge.service -f
```

2. **You should see:**
```
Connected to MQTT broker
Published Home Assistant discovery configuration
```

3. **Check Home Assistant:**
   - Settings → Devices & Services → MQTT
   - You should see your sensor appear

## Quick Test Commands

### From Bridge Pi:

```bash
# Test basic connectivity
ping 192.168.1.231

# Test port is open
telnet 192.168.1.231 1883
# (Press Ctrl+] then type 'quit' to exit)

# Or using nc
nc -zv 192.168.1.231 1883

# Test MQTT publish
mosquitto_pub -h 192.168.1.231 -p 1883 -u mqtt_user -P your_password -t test/topic -m "hello"

# Test MQTT subscribe (Ctrl+C to exit)
mosquitto_sub -h 192.168.1.231 -p 1883 -u mqtt_user -P your_password -t 'test/#' -v
```

## Update Configuration

Here's what to change in `/opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py`:

```python
# Around line 20-30, update these:
SENSOR_MAC = "A4:C1:38:XX:XX:XX"  # Your actual sensor MAC
SENSOR_NAME = "bedroom_sensor"     # Your preferred name

# MQTT Configuration
MQTT_BROKER = "192.168.1.231"      # Verify this IP!
MQTT_PORT = 1883
MQTT_USERNAME = "mqtt_user"         # Verify username
MQTT_PASSWORD = "your_password"     # Verify password
```

After editing, restart:
```bash
sudo systemctl restart xiaomi-ble-bridge.service
```









