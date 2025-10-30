#!/usr/bin/env python3

import json
import requests
import sys
import os
import time
import random
import subprocess
from datetime import datetime

def check_internet_connectivity():
    """Check if internet is available"""
    try:
        response = requests.get('http://www.google.com', timeout=10)
        return response.status_code == 200
    except:
        return False

def get_speed_from_speedtest_cli():
    """Try using speedtest-cli command line tool"""
    try:
        print(f"[{datetime.now()}] Trying speedtest-cli command...")
        
        # Run speedtest-cli with specific server to avoid 403
        cmd = [
            "speedtest-cli", 
            "--json", 
            "--timeout", "30",
            "--secure"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        
        if result.returncode == 0:
            data = json.loads(result.stdout)
            download_speed = round(data.get('download', 0) / 1_000_000, 2)
            upload_speed = round(data.get('upload', 0) / 1_000_000, 2)
            ping = round(data.get('ping', 0), 2)
            
            print(f"[{datetime.now()}] Speedtest-cli results: {download_speed} Mbps down, {upload_speed} Mbps up, {ping} ms ping")
            return download_speed, upload_speed, ping
        else:
            print(f"[{datetime.now()}] Speedtest-cli failed: {result.stderr}")
            return None, None, None
            
    except Exception as e:
        print(f"[{datetime.now()}] Speedtest-cli error: {e}")
        return None, None, None

def get_ping():
    """Get ping to a reliable server"""
    try:
        print(f"[{datetime.now()}] Testing ping...")
        
        result = subprocess.run([
            "ping", "-c", "3", "-W", "5", "8.8.8.8"
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            # Parse ping output to get average
            lines = result.stdout.split('\n')
            for line in lines:
                if 'avg' in line:
                    parts = line.split('=')
                    if len(parts) > 1:
                        avg_part = parts[1].strip()
                        ping_value = float(avg_part.split('/')[1])
                        print(f"[{datetime.now()}] Ping: {ping_value} ms")
                        return ping_value
    except Exception as e:
        print(f"[{datetime.now()}] Ping test failed: {e}")
    
    return None

def run_robust_speedtest():
    """Run speed test using only speedtest-cli"""
    try:
        print(f"[{datetime.now()}] === Speedtest Script (speedtest-cli only) ===")
        
        # Check internet connectivity
        if not check_internet_connectivity():
            print(f"[{datetime.now()}] [ERROR] No internet connectivity")
            return False
        
        print(f"[{datetime.now()}] [SUCCESS] Internet connectivity confirmed")
        
        # Try speedtest-cli
        download_speed, upload_speed, ping = get_speed_from_speedtest_cli()
        
        # If speedtest-cli fails, we don't have a fallback
        if download_speed is None:
            print(f"[{datetime.now()}] [ERROR] Speedtest-cli failed and no fallback available")
            return False
        
        # If ping is None from speedtest-cli, try separate ping test
        if ping is None:
            ping = get_ping()
            if ping is None:
                ping = 0
        
        payload = {
            'Download': download_speed,
            'Upload': upload_speed,
            'Ping': ping
        }
        
        print(f"[{datetime.now()}] Final payload:", payload)
        
        url = "http://industrial.api.ubidots.com/api/v1.6/devices/raspberry-pi/?token=BBFF-lJ6UBSIbrGd1qSNf0q7gxYOAcqUl9U"
        headers = {
            'Content-Type': 'application/json'
        }
        
        print(f"[{datetime.now()}] Sending data to Ubidots...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        print(f"[{datetime.now()}] Response status code:", response.status_code)
        print(f"[{datetime.now()}] Response body:", response.text)
        
        if response.status_code == 200:
            print(f"[{datetime.now()}] [SUCCESS] Successfully sent data to Ubidots!")
            return True
        else:
            print(f"[{datetime.now()}] [ERROR] Failed to send data to Ubidots")
            return False
            
    except Exception as e:
        print(f"[{datetime.now()}] [ERROR] Error occurred: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = run_robust_speedtest()
    if success:
        print(f"[{datetime.now()}] [SUCCESS] Speedtest completed successfully!")
        sys.exit(0)
    else:
        print(f"[{datetime.now()}] [ERROR] Speedtest failed!")
        sys.exit(1)

