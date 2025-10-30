#!/bin/bash

# Cursor Idle Resource Check
# Checks if Cursor is using excessive resources when it SHOULD be idle
# Run this when you're NOT actively using Cursor AI

echo "=========================================="
echo "Cursor Idle Resource Check"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT: Only run this when you're NOT actively using Cursor AI"
echo "   (Wait 30 seconds after your last AI request)"
echo ""
read -p "Press Enter to continue, or Ctrl+C to cancel..."
echo ""

# Thresholds for IDLE state (stricter than active use)
IDLE_MAX_CPU=20
IDLE_MAX_MEMORY=10
MAX_RUNTIME_HOURS=72  # 3 days

echo "Waiting 10 seconds to get a stable reading..."
sleep 10

echo "Checking Cursor processes..."
echo ""

PROBLEM_FOUND=0

while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $2}')
    CPU=$(echo "$line" | awk '{print $3}' | cut -d'.' -f1)
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
    
    # Check for problems during IDLE
    if [ "$CPU" -gt "$IDLE_MAX_CPU" ]; then
        echo "⚠️  PROBLEM: High CPU while idle"
        echo "   PID $PID: $PROCESS_NAME"
        echo "   CPU: ${CPU}% (threshold: ${IDLE_MAX_CPU}%)"
        echo ""
        PROBLEM_FOUND=1
    fi
    
    if [ "$MEM" -gt "$IDLE_MAX_MEMORY" ]; then
        echo "⚠️  PROBLEM: High memory usage"
        echo "   PID $PID: $PROCESS_NAME"
        echo "   Memory: ${MEM}% (threshold: ${IDLE_MAX_MEMORY}%)"
        echo ""
        PROBLEM_FOUND=1
    fi
    
    if [ "$TOTAL_HOURS" -gt "$MAX_RUNTIME_HOURS" ]; then
        echo "⚠️  PROBLEM: Process running too long"
        echo "   PID $PID: $PROCESS_NAME"
        echo "   Runtime: ${TOTAL_HOURS} hours (threshold: ${MAX_RUNTIME_HOURS}h)"
        echo ""
        PROBLEM_FOUND=1
    fi
    
done < <(ps aux | grep -i "[C]ursor" | grep -v grep)

echo "=========================================="
if [ "$PROBLEM_FOUND" -eq 1 ]; then
    echo "❌ CURSOR NEEDS RESTART"
    echo ""
    echo "Cursor is consuming excessive resources while idle."
    echo "This indicates a problem that will cause slowness."
    echo ""
    echo "To restart Cursor:"
    echo "  killall Cursor"
    echo ""
else
    echo "✅ Cursor is healthy while idle"
    echo ""
    echo "All processes are within normal idle thresholds."
fi
echo "=========================================="

exit $PROBLEM_FOUND








