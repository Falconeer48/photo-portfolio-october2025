#!/bin/bash

# Robust speedtest cron wrapper with network checks and log rotation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/speedtest.log"
MAX_LINES=500

# Explicitly set HOME (important for cron)
export HOME=/home/ian

# Set environment for cron (ensures Python can find user-installed packages)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"

# Wait for network to be ready
wait_for_network() {
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Network ready" >> "$LOG_FILE"
            return 0
        fi
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for network... (attempt $attempt/$max_attempts)" >> "$LOG_FILE"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Network not available after $max_attempts attempts" >> "$LOG_FILE"
    return 1
}

# Wait for network
if ! wait_for_network; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aborting - no network connectivity" >> "$LOG_FILE"
    exit 1
fi

# Run the speedtest with retries
max_retries=3
retry=1

while [ $retry -le $max_retries ]; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Speedtest attempt $retry/$max_retries" >> "$LOG_FILE"
    
    /usr/bin/python3 "${SCRIPT_DIR}/speedtest_robust.py" >> "$LOG_FILE" 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Speedtest completed successfully" >> "$LOG_FILE"
        break
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Speedtest failed with exit code $exit_code" >> "$LOG_FILE"
        if [ $retry -lt $max_retries ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Retrying in 30 seconds..." >> "$LOG_FILE"
            sleep 30
        fi
    fi
    
    retry=$((retry + 1))
done

# Keep only the last 500 lines
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
        tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
fi

