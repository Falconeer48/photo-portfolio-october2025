#!/bin/bash

# Simple speedtest cron wrapper with log rotation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/speedtest.log"
MAX_LINES=500

# Set environment for cron (ensures Python can find user-installed packages)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"

# Run the speedtest
/usr/bin/python3 "${SCRIPT_DIR}/speedtest_simple.py" >> "$LOG_FILE" 2>&1

# Keep only the last 500 lines
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
        tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
fi













