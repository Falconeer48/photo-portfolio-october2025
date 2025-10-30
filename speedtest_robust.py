#!/usr/bin/python3

import speedtest
import requests
import sys
from datetime import datetime

# Log everything
print(f"[{datetime.now()}] === Starting Speedtest ===")

try:
    # Initialize speedtest
    print(f"[{datetime.now()}] Initializing speedtest...")
    st = speedtest.Speedtest(secure=True)
    st.timeout = 30
    
    # Get best server with retry
    print(f"[{datetime.now()}] Getting best server...")
    try:
        best = st.get_best_server()
        print(f"[{datetime.now()}] Server: {best['sponsor']} ({best['country']})")
    except Exception as e:
        print(f"[{datetime.now()}] Warning: Could not get best server: {e}")
        print(f"[{datetime.now()}] Trying to get server list...")
        servers = st.get_servers()
        if not servers:
            raise Exception("No servers available")
        st.get_best_server()
        print(f"[{datetime.now()}] Server selected successfully")
    
    # Run download test
    print(f"[{datetime.now()}] Running download test...")
    download = round(st.download() / 1000000, 2)
    
    # Run upload test
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
        json=payload,
        timeout=30
    )
    
    print(f"[{datetime.now()}] Response ({r.status_code}): {r.text}")
    
    if r.status_code == 200:
        print(f"[{datetime.now()}] ✓ SUCCESS")
        sys.exit(0)
    else:
        print(f"[{datetime.now()}] ✗ FAILED - Status {r.status_code}")
        sys.exit(1)

except Exception as e:
    print(f"[{datetime.now()}] ✗ ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)












