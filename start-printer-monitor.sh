#!/bin/bash

# Simple startup script for printer monitoring
# This script starts the printer monitor in background mode

SCRIPT_DIR="/Users/iancook/Scripts"
MONITOR_SCRIPT="$SCRIPT_DIR/print-pdf-manual.sh"

# Start the monitor in background
"$MONITOR_SCRIPT" --background

echo "Printer monitor startup completed"

