#!/usr/bin/env python3
"""
Xiaomi BLE Temperature/Humidity Sensor to MQTT Bridge
Reads data from Xiaomi LYWSD03MMC (or similar) sensor via Bluetooth
and publishes to MQTT for Home Assistant integration.
"""

import asyncio
import json
import logging
import sys
import time
from datetime import datetime
from typing import Optional

try:
    from bleak import BleakClient, BleakScanner
    import paho.mqtt.client as mqtt
except ImportError:
    print("Missing required packages. Install with:")
    print("pip3 install bleak paho-mqtt")
    sys.exit(1)

# ==================== CONFIGURATION ====================
# Xiaomi Sensor Configuration
SENSOR_MAC = "A4:C1:38:XX:XX:XX"  # Replace with your sensor's MAC address
SENSOR_NAME = "bedroom_sensor"     # Friendly name for MQTT topics

# MQTT Configuration
MQTT_BROKER = "192.168.1.XXX"      # IP of your Home Assistant Pi
MQTT_PORT = 1883
MQTT_USERNAME = "mqtt_user"         # Optional: MQTT username
MQTT_PASSWORD = "mqtt_password"     # Optional: MQTT password
MQTT_CLIENT_ID = "xiaomi_ble_bridge"

# MQTT Topics
MQTT_BASE_TOPIC = f"homeassistant/sensor/{SENSOR_NAME}"
MQTT_TEMPERATURE_TOPIC = f"{MQTT_BASE_TOPIC}/temperature"
MQTT_HUMIDITY_TOPIC = f"{MQTT_BASE_TOPIC}/humidity"
MQTT_BATTERY_TOPIC = f"{MQTT_BASE_TOPIC}/battery"
MQTT_STATE_TOPIC = f"{MQTT_BASE_TOPIC}/state"

# Home Assistant Discovery Topics (for auto-discovery)
MQTT_DISCOVERY_PREFIX = "homeassistant"

# Scan and Update Intervals
SCAN_TIMEOUT = 10.0                # Seconds to scan for device
UPDATE_INTERVAL = 60               # Seconds between readings
RECONNECT_DELAY = 30               # Seconds to wait before reconnecting

# Logging
LOG_LEVEL = logging.INFO
# ======================================================

logging.basicConfig(
    level=LOG_LEVEL,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class XiaomiSensor:
    """Handle Xiaomi BLE sensor data reading."""
    
    # LYWSD03MMC Characteristic UUIDs
    TEMPERATURE_HUMIDITY_UUID = "ebe0ccc1-7a0a-4b0c-8a1a-6ff2997da3a6"
    BATTERY_UUID = "00002a19-0000-1000-8000-00805f9b34fb"
    
    def __init__(self, mac_address: str):
        self.mac_address = mac_address
        self.temperature: Optional[float] = None
        self.humidity: Optional[float] = None
        self.battery: Optional[int] = None
        
    async def find_device(self) -> bool:
        """Scan for the device to ensure it's available."""
        logger.info(f"Scanning for device {self.mac_address}...")
        try:
            device = await BleakScanner.find_device_by_address(
                self.mac_address, 
                timeout=SCAN_TIMEOUT
            )
            if device:
                logger.info(f"Found device: {device.name} ({device.address})")
                return True
            else:
                logger.warning(f"Device {self.mac_address} not found")
                return False
        except Exception as e:
            logger.error(f"Error scanning for device: {e}")
            return False
    
    async def read_data(self) -> bool:
        """Connect to sensor and read temperature, humidity, and battery."""
        try:
            async with BleakClient(self.mac_address, timeout=30.0) as client:
                if not client.is_connected:
                    logger.error("Failed to connect to device")
                    return False
                
                logger.info(f"Connected to {self.mac_address}")
                
                # Read temperature and humidity
                try:
                    data = await client.read_gatt_char(self.TEMPERATURE_HUMIDITY_UUID)
                    self.temperature = int.from_bytes(data[0:2], byteorder='little', signed=True) / 100.0
                    self.humidity = int.from_bytes(data[2:3], byteorder='little')
                    logger.info(f"Temperature: {self.temperature}°C, Humidity: {self.humidity}%")
                except Exception as e:
                    logger.error(f"Error reading temperature/humidity: {e}")
                    return False
                
                # Read battery level
                try:
                    battery_data = await client.read_gatt_char(self.BATTERY_UUID)
                    self.battery = int.from_bytes(battery_data, byteorder='little')
                    logger.info(f"Battery: {self.battery}%")
                except Exception as e:
                    logger.warning(f"Error reading battery (non-critical): {e}")
                    self.battery = None
                
                return True
                
        except Exception as e:
            logger.error(f"Error reading sensor data: {e}", exc_info=True)
            return False


class MQTTPublisher:
    """Handle MQTT publishing to Home Assistant."""
    
    def __init__(self):
        # Use callback_api_version to fix deprecation warning
        self.client = mqtt.Client(
            client_id=MQTT_CLIENT_ID,
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2
        )
        if MQTT_USERNAME and MQTT_PASSWORD:
            self.client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.connected = False
    
    def _on_connect(self, client, userdata, flags, rc, properties=None):
        """Callback for when connected to MQTT broker."""
        if rc == 0:
            logger.info("Connected to MQTT broker")
            self.connected = True
            self.publish_discovery_config()
        else:
            logger.error(f"Failed to connect to MQTT broker, return code {rc}")
            self.connected = False
    
    def _on_disconnect(self, client, userdata, disconnect_flags, reason_code, properties=None):
        """Callback for when disconnected from MQTT broker."""
        logger.warning(f"Disconnected from MQTT broker, reason code {reason_code}")
        self.connected = False
    
    def connect(self) -> bool:
        """Connect to MQTT broker."""
        try:
            logger.info(f"Connecting to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
            self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
            self.client.loop_start()
            
            # Wait for connection
            timeout = 10
            while not self.connected and timeout > 0:
                time.sleep(1)
                timeout -= 1
            
            return self.connected
        except Exception as e:
            logger.error(f"Error connecting to MQTT broker: {e}")
            return False
    
    def publish_discovery_config(self):
        """Publish Home Assistant MQTT discovery configuration."""
        # Temperature sensor discovery
        temp_config = {
            "name": f"{SENSOR_NAME} Temperature",
            "unique_id": f"{SENSOR_NAME}_temperature",
            "state_topic": MQTT_TEMPERATURE_TOPIC,
            "unit_of_measurement": "°C",
            "device_class": "temperature",
            "state_class": "measurement",
            "value_template": "{{ value_json.temperature }}",
            "device": {
                "identifiers": [SENSOR_NAME],
                "name": SENSOR_NAME.replace("_", " ").title(),
                "model": "Xiaomi LYWSD03MMC",
                "manufacturer": "Xiaomi"
            }
        }
        
        # Humidity sensor discovery
        humidity_config = {
            "name": f"{SENSOR_NAME} Humidity",
            "unique_id": f"{SENSOR_NAME}_humidity",
            "state_topic": MQTT_HUMIDITY_TOPIC,
            "unit_of_measurement": "%",
            "device_class": "humidity",
            "state_class": "measurement",
            "value_template": "{{ value_json.humidity }}",
            "device": {
                "identifiers": [SENSOR_NAME],
                "name": SENSOR_NAME.replace("_", " ").title(),
                "model": "Xiaomi LYWSD03MMC",
                "manufacturer": "Xiaomi"
            }
        }
        
        # Battery sensor discovery
        battery_config = {
            "name": f"{SENSOR_NAME} Battery",
            "unique_id": f"{SENSOR_NAME}_battery",
            "state_topic": MQTT_BATTERY_TOPIC,
            "unit_of_measurement": "%",
            "device_class": "battery",
            "state_class": "measurement",
            "value_template": "{{ value_json.battery }}",
            "device": {
                "identifiers": [SENSOR_NAME],
                "name": SENSOR_NAME.replace("_", " ").title(),
                "model": "Xiaomi LYWSD03MMC",
                "manufacturer": "Xiaomi"
            }
        }
        
        # Publish discovery configs
        self.client.publish(
            f"{MQTT_DISCOVERY_PREFIX}/sensor/{SENSOR_NAME}_temperature/config",
            json.dumps(temp_config),
            retain=True
        )
        self.client.publish(
            f"{MQTT_DISCOVERY_PREFIX}/sensor/{SENSOR_NAME}_humidity/config",
            json.dumps(humidity_config),
            retain=True
        )
        self.client.publish(
            f"{MQTT_DISCOVERY_PREFIX}/sensor/{SENSOR_NAME}_battery/config",
            json.dumps(battery_config),
            retain=True
        )
        logger.info("Published Home Assistant discovery configuration")
    
    def publish_sensor_data(self, sensor: XiaomiSensor):
        """Publish sensor readings to MQTT."""
        if not self.connected:
            logger.warning("Not connected to MQTT broker, skipping publish")
            return
        
        timestamp = datetime.now().isoformat()
        
        # Publish temperature
        if sensor.temperature is not None:
            temp_payload = {
                "temperature": sensor.temperature,
                "timestamp": timestamp
            }
            self.client.publish(MQTT_TEMPERATURE_TOPIC, json.dumps(temp_payload))
            logger.debug(f"Published temperature: {sensor.temperature}°C")
        
        # Publish humidity
        if sensor.humidity is not None:
            humidity_payload = {
                "humidity": sensor.humidity,
                "timestamp": timestamp
            }
            self.client.publish(MQTT_HUMIDITY_TOPIC, json.dumps(humidity_payload))
            logger.debug(f"Published humidity: {sensor.humidity}%")
        
        # Publish battery
        if sensor.battery is not None:
            battery_payload = {
                "battery": sensor.battery,
                "timestamp": timestamp
            }
            self.client.publish(MQTT_BATTERY_TOPIC, json.dumps(battery_payload))
            logger.debug(f"Published battery: {sensor.battery}%")
        
        # Publish combined state
        state_payload = {
            "temperature": sensor.temperature,
            "humidity": sensor.humidity,
            "battery": sensor.battery,
            "timestamp": timestamp
        }
        self.client.publish(MQTT_STATE_TOPIC, json.dumps(state_payload))
    
    def disconnect(self):
        """Disconnect from MQTT broker."""
        self.client.loop_stop()
        self.client.disconnect()


async def main():
    """Main loop to read sensor and publish to MQTT."""
    logger.info("Starting Xiaomi BLE to MQTT Bridge")
    
    # Initialize sensor and MQTT
    sensor = XiaomiSensor(SENSOR_MAC)
    mqtt_publisher = MQTTPublisher()
    
    # Connect to MQTT broker
    if not mqtt_publisher.connect():
        logger.error("Failed to connect to MQTT broker. Exiting.")
        sys.exit(1)
    
    try:
        while True:
            try:
                # Find and read sensor
                if await sensor.find_device():
                    if await sensor.read_data():
                        mqtt_publisher.publish_sensor_data(sensor)
                        logger.info(f"Successfully updated sensor data. Next update in {UPDATE_INTERVAL}s")
                    else:
                        logger.error(f"Failed to read sensor data. Retrying in {RECONNECT_DELAY}s")
                        await asyncio.sleep(RECONNECT_DELAY)
                        continue
                else:
                    logger.error(f"Device not found. Retrying in {RECONNECT_DELAY}s")
                    await asyncio.sleep(RECONNECT_DELAY)
                    continue
                
                # Wait for next update
                await asyncio.sleep(UPDATE_INTERVAL)
                
            except Exception as e:
                logger.error(f"Error in main loop: {e}", exc_info=True)
                await asyncio.sleep(RECONNECT_DELAY)
    
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        mqtt_publisher.disconnect()


if __name__ == "__main__":
    asyncio.run(main())

