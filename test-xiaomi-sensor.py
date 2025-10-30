#!/usr/bin/env python3
"""Test script to diagnose Xiaomi sensor connection issues"""

import asyncio
import sys
from bleak import BleakClient, BleakScanner

SENSOR_MAC = "A4:C1:38:D9:37:E6"

# Common UUIDs for Xiaomi sensors
TEMP_HUM_UUID = "ebe0ccc1-7a0a-4b0c-8a1a-6ff2997da3a6"  # LYWSD03MMC
BATTERY_UUID = "00002a19-0000-1000-8000-00805f9b34fb"

async def test_sensor():
    print(f"Testing Xiaomi sensor: {SENSOR_MAC}")
    print("=" * 50)
    
    # Step 1: Find device
    print("\n1. Scanning for device...")
    device = await BleakScanner.find_device_by_address(SENSOR_MAC, timeout=10.0)
    if device:
        print(f"   ✓ Found: {device.name} ({device.address})")
    else:
        print(f"   ✗ Device not found")
        return
    
    # Step 2: Connect
    print("\n2. Connecting to device...")
    try:
        async with BleakClient(SENSOR_MAC, timeout=30.0) as client:
            if client.is_connected:
                print(f"   ✓ Connected!")
            else:
                print(f"   ✗ Connection failed")
                return
            
            # Step 3: List all services and characteristics
            print("\n3. Listing all services and characteristics...")
            for service in client.services:
                print(f"\n   Service: {service.uuid}")
                for char in service.characteristics:
                    props = ", ".join(char.properties)
                    print(f"      Char: {char.uuid} ({props})")
            
            # Step 4: Try to read temperature/humidity
            print(f"\n4. Attempting to read temperature/humidity UUID: {TEMP_HUM_UUID}")
            try:
                data = await client.read_gatt_char(TEMP_HUM_UUID)
                temp = int.from_bytes(data[0:2], byteorder='little', signed=True) / 100.0
                humidity = int.from_bytes(data[2:3], byteorder='little')
                print(f"   ✓ Temperature: {temp}°C")
                print(f"   ✓ Humidity: {humidity}%")
            except Exception as e:
                print(f"   ✗ Error reading temp/humidity: {e}")
                print(f"   Error type: {type(e).__name__}")
            
            # Step 5: Try to read battery
            print(f"\n5. Attempting to read battery UUID: {BATTERY_UUID}")
            try:
                battery_data = await client.read_gatt_char(BATTERY_UUID)
                battery = int.from_bytes(battery_data, byteorder='little')
                print(f"   ✓ Battery: {battery}%")
            except Exception as e:
                print(f"   ✗ Error reading battery: {e}")
            
    except Exception as e:
        print(f"\n   ✗ Connection error: {e}")
        print(f"   Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_sensor())

