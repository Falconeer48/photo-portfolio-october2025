#!/usr/bin/python3

import speedtest
import requests
from datetime import datetime

# Log everything
print(f"[{datetime.now()}] === Starting Speedtest ===")

try:
    # Initialize speedtest
    print(f"[{datetime.now()}] Initializing speedtest...")
    st = speedtest.Speedtest()
    
    # Get best server
    print(f"[{datetime.now()}] Getting best server...")
    st.get_best_server()
    print(f"[{datetime.now()}] Server: {st.results.server['name']} ({st.results.server['country']})")
    
    # Run tests
    print(f"[{datetime.now()}] Running download test...")
    download = round(st.download() / 1000000, 2)
    
    print(f"[{datetime.now()}] Running upload test...")
    upload = round(st.upload() / 1000000, 2)
    
    ping = round(st.results.ping, 2)
    
    print(f"[{datetime.now()}] Results: {download} Mbps down, {upload} Mbps up, {ping} ms ping")
    
    # Prepare payload
    payload = {
        'Download': download,
        'Upload': upload,
        'Ping': ping
    }
    
    # Send to Ubidots
    print(f"[{datetime.now()}] Sending to Ubidots...")
    r = requests.post(
        'http://industrial.api.ubidots.com/api/v1.6/devices/raspberry-pi/?token=BBFF-lJ6UBSIbrGd1qSNf0q7gxYOAcqUl9U',
        json=payload
    )
    
    print(f"[{datetime.now()}] Response ({r.status_code}): {r.text}")
    
    if r.status_code == 200:
        print(f"[{datetime.now()}] ✓ SUCCESS")
    else:
        print(f"[{datetime.now()}] ✗ FAILED - Status {r.status_code}")

except Exception as e:
    print(f"[{datetime.now()}] ✗ ERROR: {e}")
    import traceback
    traceback.print_exc()













