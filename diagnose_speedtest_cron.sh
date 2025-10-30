#!/bin/bash

# Speedtest Cron Diagnostic Script
# This will help identify why the cron job might not be working properly

echo "=========================================="
echo "Speedtest Cron Diagnostic Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

echo "1. Checking Current Crontab..."
echo "-------------------------------"
if crontab -l >/dev/null 2>&1; then
    print_status 0 "Crontab is accessible"
    echo "Current crontab entries:"
    crontab -l | sed 's/^/   /'
    echo ""
    
    # Check for speedtest entries
    SPEEDTEST_ENTRIES=$(crontab -l | grep -i speedtest)
    if [ -n "$SPEEDTEST_ENTRIES" ]; then
        print_status 0 "Speedtest crontab entries found"
        echo "$SPEEDTEST_ENTRIES" | sed 's/^/   /'
    else
        print_status 1 "No speedtest crontab entries found"
    fi
else
    print_status 1 "Cannot access crontab"
fi

echo ""
echo "2. Checking Script Files..."
echo "---------------------------"
SCRIPT_PATH="/home/ian/speedtest/robust_speedtest.py"
SHELL_SCRIPT_PATH="/home/ian/speedtest/robust_speedtest.sh"

if [ -f "$SCRIPT_PATH" ]; then
    print_status 0 "Python script exists: $SCRIPT_PATH"
    
    # Check permissions
    PERMS=$(ls -la "$SCRIPT_PATH" | awk '{print $1}')
    echo "   Permissions: $PERMS"
    
    # Check if executable
    if [ -x "$SCRIPT_PATH" ]; then
        print_status 0 "Python script is executable"
    else
        print_warning "Python script is NOT executable"
        echo "   To fix: chmod +x $SCRIPT_PATH"
    fi
    
    # Check shebang
    SHEBANG=$(head -1 "$SCRIPT_PATH")
    echo "   Shebang: $SHEBANG"
    if echo "$SHEBANG" | grep -q "#!/usr/bin/env python3"; then
        print_status 0 "Correct shebang found"
    else
        print_warning "Incorrect or missing shebang"
    fi
else
    print_status 1 "Python script does NOT exist: $SCRIPT_PATH"
fi

if [ -f "$SHELL_SCRIPT_PATH" ]; then
    print_status 0 "Shell script exists: $SHELL_SCRIPT_PATH"
    print_warning "This might be causing confusion in crontab"
else
    print_info "Shell script does NOT exist: $SHELL_SCRIPT_PATH"
    print_warning "This explains the 'not found' errors in your log"
fi

echo ""
echo "3. Testing Script Execution..."
echo "------------------------------"
if [ -f "$SCRIPT_PATH" ]; then
    echo "Testing Python script execution..."
    cd /home/ian/speedtest 2>/dev/null || echo "Cannot cd to /home/ian/speedtest"
    
    # Test with python3 explicitly
    echo "Testing: python3 $SCRIPT_PATH"
    timeout 30 python3 "$SCRIPT_PATH" >/dev/null 2>&1
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        print_status 0 "Python script executed successfully with 'python3'"
    elif [ $EXIT_CODE -eq 124 ]; then
        print_warning "Python script timed out (may be normal for speedtest)"
    else
        print_status 1 "Python script failed with exit code: $EXIT_CODE"
    fi
    
    # Test direct execution
    if [ -x "$SCRIPT_PATH" ]; then
        echo "Testing: $SCRIPT_PATH (direct execution)"
        timeout 30 "$SCRIPT_PATH" >/dev/null 2>&1
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            print_status 0 "Python script executed successfully with direct execution"
        elif [ $EXIT_CODE -eq 124 ]; then
            print_warning "Python script timed out (may be normal for speedtest)"
        else
            print_status 1 "Python script failed with exit code: $EXIT_CODE"
        fi
    fi
else
    print_status 1 "Cannot test script execution (file not found)"
fi

echo ""
echo "4. Checking Cron Service..."
echo "---------------------------"
# Check different cron service names
if systemctl is-active --quiet cron 2>/dev/null; then
    print_status 0 "Cron service is running (systemd)"
elif systemctl is-active --quiet crond 2>/dev/null; then
    print_status 0 "Crond service is running (systemd)"
elif pgrep cron >/dev/null 2>&1; then
    print_status 0 "Cron process is running"
else
    print_status 1 "Cron service appears to be stopped"
    echo "   Try: sudo systemctl start cron"
fi

echo ""
echo "5. Checking Recent Cron Logs..."
echo "-------------------------------"
# Check system logs for cron activity
echo "Recent cron activity:"
if [ -f "/var/log/syslog" ]; then
    sudo tail -10 /var/log/syslog | grep -i cron | tail -5 | sed 's/^/   /' || echo "   No recent cron activity found"
elif [ -f "/var/log/cron" ]; then
    sudo tail -10 /var/log/cron | tail -5 | sed 's/^/   /' || echo "   No recent cron activity found"
else
    print_warning "Cannot find cron log files"
fi

echo ""
echo "6. Checking Environment Variables..."
echo "-----------------------------------"
echo "PATH in cron environment:"
echo "   (Cron typically has limited PATH)"
echo "   Current PATH: $PATH"
echo ""
echo "Python location:"
PYTHON_PATH=$(which python3)
if [ -n "$PYTHON_PATH" ]; then
    print_status 0 "Python3 found at: $PYTHON_PATH"
else
    print_status 1 "Python3 not found in PATH"
fi

echo ""
echo "7. Recommendations..."
echo "--------------------"
echo "Based on the analysis above:"
echo ""
echo "1. Fix the crontab entry to use the correct path:"
echo "   */30 * * * * /usr/bin/python3 /home/ian/speedtest/robust_speedtest.py >> /home/ian/speedtest/speedtest.log 2>&1"
echo ""
echo "2. Make sure the script is executable:"
echo "   chmod +x /home/ian/speedtest/robust_speedtest.py"
echo ""
echo "3. Test the script manually:"
echo "   cd /home/ian/speedtest && python3 robust_speedtest.py"
echo ""
echo "4. Monitor cron logs:"
echo "   sudo tail -f /var/log/syslog | grep CRON"
echo ""
echo "5. Check if there are any old shell script references causing confusion"

echo ""
echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="

