#!/bin/bash

# Cursor Health Check Script
# Monitors Cursor processes for excessive resource usage and runtime

echo "=========================================="
echo "Cursor Health Check"
echo "=========================================="
echo ""

# Thresholds (adjust as needed)
MAX_CPU_PERCENT=50
MAX_MEMORY_PERCENT=15
MAX_RUNTIME_HOURS=48

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if Cursor is running
if ! ps aux | grep -i "[C]ursor" | grep -v grep > /dev/null; then
    echo "✓ Cursor is not currently running"
    exit 0
fi

echo "Checking Cursor processes..."
echo ""

# Initialize flags
ISSUES_FOUND=0
RESTART_RECOMMENDED=0

# Get all Cursor processes
while IFS= read -r line; do
    # Parse process info
    PID=$(echo "$line" | awk '{print $2}')
    CPU=$(echo "$line" | awk '{print $3}' | cut -d'.' -f1)
    MEM=$(echo "$line" | awk '{print $4}' | cut -d'.' -f1)
    ELAPSED=$(echo "$line" | awk '{print $10}')
    PROCESS_NAME=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    
    # Convert elapsed time to hours
    if [[ $ELAPSED == *-* ]]; then
        # Format: days-HH:MM:SS
        DAYS=$(echo "$ELAPSED" | cut -d'-' -f1)
        HOURS=$(echo "$ELAPSED" | cut -d'-' -f2 | cut -d':' -f1)
        TOTAL_HOURS=$((DAYS * 24 + HOURS))
    elif [[ $ELAPSED == *:*:* ]]; then
        # Format: HH:MM:SS or HHH:MM:SS
        HOURS=$(echo "$ELAPSED" | cut -d':' -f1)
        TOTAL_HOURS=$HOURS
    else
        TOTAL_HOURS=0
    fi
    
    # Check for issues
    ISSUE=""
    
    if [ "$CPU" -gt "$MAX_CPU_PERCENT" ]; then
        ISSUE="${ISSUE}High CPU (${CPU}%) "
        ISSUES_FOUND=1
    fi
    
    if [ "$MEM" -gt "$MAX_MEMORY_PERCENT" ]; then
        ISSUE="${ISSUE}High Memory (${MEM}%) "
        ISSUES_FOUND=1
        RESTART_RECOMMENDED=1
    fi
    
    if [ "$TOTAL_HOURS" -gt "$MAX_RUNTIME_HOURS" ]; then
        ISSUE="${ISSUE}Long Runtime (${TOTAL_HOURS}h) "
        ISSUES_FOUND=1
        RESTART_RECOMMENDED=1
    fi
    
    # Print process info with color coding
    if [ -n "$ISSUE" ]; then
        echo -e "${RED}⚠ ISSUE:${NC} PID $PID - $PROCESS_NAME"
        echo -e "  ${YELLOW}${ISSUE}${NC}"
        echo "  CPU: ${CPU}% | Memory: ${MEM}% | Runtime: ${TOTAL_HOURS}h"
        echo ""
    fi
    
done < <(ps aux | grep -i "[C]ursor" | grep -v "grep")

# Summary
echo "=========================================="
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✓ All Cursor processes are healthy${NC}"
else
    echo -e "${YELLOW}⚠ Issues detected with Cursor processes${NC}"
    echo ""
    
    if [ "$RESTART_RECOMMENDED" -eq 1 ]; then
        echo -e "${RED}RECOMMENDATION: Restart Cursor${NC}"
        echo ""
        echo "To restart Cursor, run:"
        echo "  killall Cursor"
        echo ""
        echo "Or use the menu: Cursor > Quit Cursor"
    fi
fi

echo "=========================================="
echo ""

# Show current resource summary
echo "Current Resource Summary:"
echo "-------------------------"
TOTAL_CPU=$(ps aux | grep -i "[C]ursor" | awk '{sum+=$3} END {print sum}')
TOTAL_MEM=$(ps aux | grep -i "[C]ursor" | awk '{sum+=$4} END {print sum}')
PROCESS_COUNT=$(ps aux | grep -i "[C]ursor" | wc -l | tr -d ' ')

echo "Total Cursor processes: $PROCESS_COUNT"
echo "Total CPU usage: ${TOTAL_CPU}%"
echo "Total Memory usage: ${TOTAL_MEM}%"
echo ""

# Show longest running process
echo "Longest running process:"
LONGEST=$(ps aux | grep -i "[C]ursor" | grep -v grep | sort -k10 -r | head -1)
if [ -n "$LONGEST" ]; then
    ELAPSED=$(echo "$LONGEST" | awk '{print $10}')
    PROCESS_NAME=$(echo "$LONGEST" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    echo "  $PROCESS_NAME - Runtime: $ELAPSED"
fi

echo ""
echo "Thresholds used:"
echo "  Max CPU: ${MAX_CPU_PERCENT}%"
echo "  Max Memory: ${MAX_MEMORY_PERCENT}%"
echo "  Max Runtime: ${MAX_RUNTIME_HOURS} hours"

exit $ISSUES_FOUND

