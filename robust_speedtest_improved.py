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
        # Try multiple reliable services for better connectivity check
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

def get_speed_from_speedtest_cli():
    """Try using speedtest-cli command line tool with retry logic"""
    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            print(f"[{datetime.now()}] Trying speedtest-cli command (attempt {attempt + 1}/{max_retries})...")
            
            # Run speedtest-cli with specific server to avoid 403
            cmd = [
                "python3", "-m", "speedtest", 
                "--json", 
                "--timeout", "30"
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
                print(f"[{datetime.now()}] Speedtest-cli attempt {attempt + 1} failed: {result.stderr}")
                if attempt < max_retries - 1:
                    wait_time = random.randint(10, 30)
                    print(f"[{datetime.now()}] Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
                
        except Exception as e:
            print(f"[{datetime.now()}] Speedtest-cli attempt {attempt + 1} error: {e}")
            if attempt < max_retries - 1:
                wait_time = random.randint(10, 30)
                print(f"[{datetime.now()}] Waiting {wait_time} seconds before retry...")
                time.sleep(wait_time)
    
    print(f"[{datetime.now()}] Speedtest-cli failed after {max_retries} attempts")
    return None, None, None

def get_ping():
    """Get ping to multiple reliable servers"""
    ping_servers = ['8.8.8.8', '1.1.1.1', '208.67.222.222']  # Google, Cloudflare, OpenDNS
    
    for server in ping_servers:
        try:
            print(f"[{datetime.now()}] Testing ping to {server}...")
            
            result = subprocess.run([
                "ping", "-c", "3", "-W", "5", server
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
                            print(f"[{datetime.now()}] Ping to {server}: {ping_value} ms")
                            return ping_value
        except Exception as e:
            print(f"[{datetime.now()}] Ping test to {server} failed: {e}")
            continue
    
    print(f"[{datetime.now()}] All ping tests failed")
    return None

def run_robust_speedtest():
    """Run robust speed test with improved error handling"""
    try:
        print(f"[{datetime.now()}] === Robust Speedtest Script (Improved) ===")
        
        # Check internet connectivity
        if not check_internet_connectivity():
            print(f"[{datetime.now()}] ❌ No internet connectivity")
            return False
        
        print(f"[{datetime.now()}] ✅ Internet connectivity confirmed")
        
        # Try speedtest-cli with retry logic
        download_speed, upload_speed, ping = get_speed_from_speedtest_cli()
        
        # If speedtest-cli completely failed, don't fall back to inaccurate curl method
        if download_speed is None:
            print(f"[{datetime.now()}] ❌ Speedtest-cli failed completely - no accurate fallback available")
            print(f"[{datetime.now()}] Skipping inaccurate curl method to avoid false readings")
            return False
        
        # Get ping if not provided by speedtest-cli
        if ping is None:
            ping = get_ping()
        
        # Use default values only for ping if still None
        if ping is None:
            ping = 0
            print(f"[{datetime.now()}] ⚠️ Using default ping value (0) - ping test failed")
        
        payload = {
            'Download': download_speed,
            'Upload': upload_speed,
            'Ping': ping
        }
        
        print(f"[{datetime.now()}] Final payload: {payload}")
        
        url = "http://industrial.api.ubidots.com/api/v1.6/devices/raspberry-pi/?token=BBFF-lJ6UBSIbrGd1qSNf0q7gxYOAcqUl9U"
        headers = {
            'Content-Type': 'application/json'
        }
        
        print(f"[{datetime.now()}] Sending data to Ubidots...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        print(f"[{datetime.now()}] Response status code: {response.status_code}")
        print(f"[{datetime.now()}] Response body: {response.text}")
        
        if response.status_code == 200:
            print(f"[{datetime.now()}] ✅ Successfully sent data to Ubidots!")
            return True
        else:
            print(f"[{datetime.now()}] ❌ Failed to send data to Ubidots")
            return False
            
    except Exception as e:
        print(f"[{datetime.now()}] ❌ Error occurred: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = run_robust_speedtest()
    if success:
        print(f"[{datetime.now()}] ✅ Robust script completed successfully!")
        sys.exit(0)
    else:
        print(f"[{datetime.now()}] ❌ Robust script failed!")
        sys.exit(1)







