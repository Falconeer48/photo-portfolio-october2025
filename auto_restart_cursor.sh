#!/bin/bash

# Auto Restart Cursor Script
# Automatically restarts Cursor if resource usage is too high

# Thresholds
MAX_MEMORY_PERCENT=15
MAX_RUNTIME_HOURS=72  # 3 days

echo "Checking Cursor health..."

# Check if Cursor is running
if ! ps aux | grep -i "[C]ursor" | grep -v grep > /dev/null; then
    echo "Cursor is not running"
    exit 0
fi

# Check for high memory or long runtime
NEEDS_RESTART=0

while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $2}')
    MEM=$(echo "$line" | awk '{print $4}' | cut -d'.' -f1)
    ELAPSED=$(echo "$line" | awk '{print $10}')
    PROCESS_NAME=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    
    # Convert elapsed time to hours
    if [[ $ELAPSED == *-* ]]; then
        DAYS=$(echo "$ELAPSED" | cut -d'-' -f1)
        HOURS=$(echo "$ELAPSED" | cut -d'-' -f2 | cut -d':' -f1)
        TOTAL_HOURS=$((DAYS * 24 + HOURS))
    elif [[ $ELAPSED == *:*:* ]]; then
        HOURS=$(echo "$ELAPSED" | cut -d':' -f1)
        TOTAL_HOURS=$HOURS
    else
        TOTAL_HOURS=0
    fi
    
    # Check thresholds
    if [ "$MEM" -gt "$MAX_MEMORY_PERCENT" ]; then
        echo "⚠ High memory usage detected: PID $PID using ${MEM}% memory"
        echo "  Process: $PROCESS_NAME"
        NEEDS_RESTART=1
    fi
    
    if [ "$TOTAL_HOURS" -gt "$MAX_RUNTIME_HOURS" ]; then
        echo "⚠ Long runtime detected: PID $PID running for ${TOTAL_HOURS} hours"
        echo "  Process: $PROCESS_NAME"
        NEEDS_RESTART=1
    fi
    
done < <(ps aux | grep -i "[C]ursor" | grep -v grep)

if [ "$NEEDS_RESTART" -eq 1 ]; then
    echo ""
    echo "Restarting Cursor..."
    killall Cursor
    sleep 2
    echo "✓ Cursor has been restarted"
    echo ""
    echo "You can reopen Cursor from your Applications folder"
else
    echo "✓ Cursor is healthy - no restart needed"
fi

exit 0








