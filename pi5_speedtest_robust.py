#!/usr/bin/env python3

import speedtest
import requests
import sys
import os
import time
import random
from datetime import datetime

def check_internet_connectivity():
    """Check if internet is available before running speedtest"""
    try:
        # Try multiple reliable services
        test_urls = [
            'http://www.google.com',
            'http://www.cloudflare.com',
            'http://www.github.com'
        ]
        
        for url in test_urls:
            try:
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    return True
            except:
                continue
        return False
    except:
        return False

def get_speedtest_config():
    """Get speedtest configuration with retry logic"""
    max_retries = 5
    for attempt in range(max_retries):
        try:
            print(f"[{datetime.now()}] Getting speedtest config (attempt {attempt + 1}/{max_retries})...")
            st = speedtest.Speedtest()
            st.timeout = 30
            return st
        except Exception as e:
            print(f"[{datetime.now()}] Config attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                wait_time = random.randint(5, 15)
                print(f"[{datetime.now()}] Waiting {wait_time} seconds before retry...")
                time.sleep(wait_time)
            else:
                raise e

def run_speedtest():
    try:
        print(f"[{datetime.now()}] === Pi5 Speedtest Script ===")
        
        # Check internet connectivity first
        print(f"[{datetime.now()}] Checking internet connectivity...")
        if not check_internet_connectivity():
            print(f"[{datetime.now()}] ❌ No internet connectivity detected")
            return False
        
        print(f"[{datetime.now()}] ✅ Internet connectivity confirmed")
        print(f"[{datetime.now()}] Initializing speedtest...")
        
        # Get speedtest configuration with retry logic
        st = get_speedtest_config()
        
        # Get best server with retry logic
        max_retries = 3
        for attempt in range(max_retries):
            try:
                print(f"[{datetime.now()}] Getting best server (attempt {attempt + 1}/{max_retries})...")
                st.get_best_server()
                print(f"[{datetime.now()}] Best server selected:", st.results.server['name'])
                break
            except Exception as e:
                print(f"[{datetime.now()}] Server attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    wait_time = random.randint(10, 30)
                    print(f"[{datetime.now()}] Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
                else:
                    print(f"[{datetime.now()}] ❌ Failed to get best server after {max_retries} attempts")
                    return False

        print(f"[{datetime.now()}] Running download test...")
        download_speed = round(st.download() / 1_000_000, 2)
        print(f"[{datetime.now()}] Download speed:", download_speed, "Mbps")

        print(f"[{datetime.now()}] Running upload test...")
        upload_speed = round(st.upload() / 1_000_000, 2)
        print(f"[{datetime.now()}] Upload speed:", upload_speed, "Mbps")

        ping = round(st.results.ping, 2)
        print(f"[{datetime.now()}] Ping:", ping, "ms")

        payload = {
            'Download': download_speed,
            'Upload': upload_speed,
            'Ping': ping
        }

        print(f"[{datetime.now()}] Payload to send:", payload)

        url = "http://industrial.api.ubidots.com/api/v1.6/devices/raspberry-pi/?token=BBFF-lJ6UBSIbrGd1qSNf0q7gxYOAcqUl9U"
        headers = {
            'Content-Type': 'application/json'
        }

        print(f"[{datetime.now()}] Sending data to Ubidots...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)

        print(f"[{datetime.now()}] Response status code:", response.status_code)
        print(f"[{datetime.now()}] Response body:", response.text)
        
        if response.status_code == 200:
            print(f"[{datetime.now()}] ✅ Successfully sent data to Ubidots!")
            return True
        else:
            print(f"[{datetime.now()}] ❌ Failed to send data to Ubidots")
            return False

    except Exception as e:
        print(f"[{datetime.now()}] ❌ Error occurred: {e}")
        import traceback
        print(f"[{datetime.now()}] Full error details:")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = run_speedtest()
    if success:
        print(f"[{datetime.now()}] ✅ Script completed successfully!")
        sys.exit(0)
    else:
        print(f"[{datetime.now()}] ❌ Script failed!")
        sys.exit(1)
