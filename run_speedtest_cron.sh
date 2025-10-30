#!/bin/bash

# Speedtest cron wrapper with log rotation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/speedtest_cron.log"
MAX_LINES=500

# Set environment for cron (ensures Python can find user-installed packages)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PYTHONPATH="$HOME/.local/lib/python3.12/site-packages:$PYTHONPATH"

# Run the speedtest with full paths
/usr/bin/python3 "${SCRIPT_DIR}/robust_speedtest_fixed.py" >> "$LOG_FILE" 2>&1

# Keep only the last 500 lines of the log
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
        tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
fi
