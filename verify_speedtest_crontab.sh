#!/bin/bash

# Speedtest Crontab Verification Script
# Run this on your Pi5 to verify everything is set up correctly

echo "=========================================="
echo "Speedtest Crontab Verification Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

echo "1. Checking Cron Service Status..."
echo "-----------------------------------"
if systemctl is-active --quiet cron; then
    print_status 0 "Cron service is running"
else
    print_status 1 "Cron service is NOT running"
    echo "   To fix: sudo systemctl start cron && sudo systemctl enable cron"
fi

echo ""
echo "2. Checking Crontab Configuration..."
echo "------------------------------------"
if crontab -l >/dev/null 2>&1; then
    CRON_ENTRY=$(crontab -l | grep -v '^#' | grep speedtest)
    if [ -n "$CRON_ENTRY" ]; then
        print_status 0 "Crontab entry found"
        echo "   Entry: $CRON_ENTRY"
    else
        print_status 1 "No speedtest crontab entry found"
        echo "   To fix: Add crontab entry for speedtest script"
    fi
else
    print_status 1 "No crontab configured"
fi

echo ""
echo "3. Checking Script File..."
echo "--------------------------"
SCRIPT_PATH="/home/ian/speedtest/robust_speedtest.py"
if [ -f "$SCRIPT_PATH" ]; then
    print_status 0 "Script file exists: $SCRIPT_PATH"
    
    # Check if executable
    if [ -x "$SCRIPT_PATH" ]; then
        print_status 0 "Script is executable"
    else
        print_status 1 "Script is NOT executable"
        echo "   To fix: chmod +x $SCRIPT_PATH"
    fi
    
    # Check shebang
    if head -1 "$SCRIPT_PATH" | grep -q "#!/usr/bin/env python3"; then
        print_status 0 "Script has correct shebang"
    else
        print_warning "Script may not have correct shebang"
    fi
else
    print_status 1 "Script file does NOT exist: $SCRIPT_PATH"
fi

echo ""
echo "4. Checking Python Dependencies..."
echo "---------------------------------"
# Check if speedtest-cli is installed
if command -v speedtest-cli >/dev/null 2>&1; then
    print_status 0 "speedtest-cli is installed"
    SPEEDTEST_VERSION=$(speedtest-cli --version 2>/dev/null | head -1)
    echo "   Version: $SPEEDTEST_VERSION"
else
    print_status 1 "speedtest-cli is NOT installed"
    echo "   To fix: pip install speedtest-cli"
fi

# Check if requests module is available
if python3 -c "import requests" >/dev/null 2>&1; then
    print_status 0 "Python requests module is available"
else
    print_status 1 "Python requests module is NOT available"
    echo "   To fix: pip install requests"
fi

echo ""
echo "5. Checking Log Directory..."
echo "----------------------------"
LOG_DIR="/home/ian/speedtest"
if [ -d "$LOG_DIR" ]; then
    print_status 0 "Log directory exists: $LOG_DIR"
    
    # Check if writable
    if [ -w "$LOG_DIR" ]; then
        print_status 0 "Log directory is writable"
    else
        print_status 1 "Log directory is NOT writable"
        echo "   To fix: chmod 755 $LOG_DIR"
    fi
else
    print_status 1 "Log directory does NOT exist: $LOG_DIR"
    echo "   To fix: mkdir -p $LOG_DIR"
fi

echo ""
echo "6. Checking Network Connectivity..."
echo "----------------------------------"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    print_status 0 "Network connectivity is working"
else
    print_status 1 "Network connectivity issues detected"
fi

echo ""
echo "7. Testing Script Execution..."
echo "-----------------------------"
if [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
    echo "Running test execution (this may take a moment)..."
    cd /home/ian/speedtest
    timeout 60 python3 "$SCRIPT_PATH" >/dev/null 2>&1
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        print_status 0 "Script executed successfully"
    elif [ $EXIT_CODE -eq 124 ]; then
        print_warning "Script timed out (may be normal for speedtest)"
    else
        print_status 1 "Script execution failed (exit code: $EXIT_CODE)"
        echo "   Check the script for errors"
    fi
else
    print_status 1 "Cannot test script execution (file not found or not executable)"
fi

echo ""
echo "8. Checking Recent Log Entries..."
echo "---------------------------------"
LOG_FILE="/home/ian/speedtest/speedtest.log"
if [ -f "$LOG_FILE" ]; then
    print_status 0 "Log file exists: $LOG_FILE"
    echo "   Recent entries:"
    tail -5 "$LOG_FILE" | sed 's/^/   /'
else
    print_warning "Log file does not exist yet: $LOG_FILE"
    echo "   This is normal if the script hasn't run yet"
fi

echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Fix any ❌ issues shown above"
echo "2. Wait for next cron run (every 30 minutes)"
echo "3. Monitor log: tail -f $LOG_FILE"
echo "4. Check cron logs: sudo tail -f /var/log/syslog | grep CRON"
echo ""
echo "To manually test: cd /home/ian/speedtest && python3 robust_speedtest.py"







