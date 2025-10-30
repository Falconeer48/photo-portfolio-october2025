#!/bin/bash

# Cursor Performance Debug Script for Mac Mini
# Run this script to diagnose Cursor performance issues

echo "=========================================="
echo "Cursor Performance Debug Script"
echo "=========================================="
echo ""

# Create output directory
mkdir -p ~/cursor_debug_output
cd ~/cursor_debug_output

echo "1. SYSTEM INFORMATION"
echo "===================="
echo "Date: $(date)" > system_info.txt
echo "Uptime: $(uptime)" >> system_info.txt
echo "" >> system_info.txt

echo "macOS Version:" >> system_info.txt
sw_vers >> system_info.txt
echo "" >> system_info.txt

echo "Hardware Information:" >> system_info.txt
system_profiler SPHardwareDataType >> system_info.txt
echo "" >> system_info.txt

echo "Memory Usage:" >> system_info.txt
vm_stat >> system_info.txt
echo "" >> system_info.txt

echo "Disk Usage:" >> system_info.txt
df -h >> system_info.txt
echo "" >> system_info.txt

echo "CPU Load:" >> system_info.txt
top -l 1 -n 10 >> system_info.txt
echo "" >> system_info.txt

echo "✓ System information saved to system_info.txt"
echo ""

echo "2. NETWORK CONNECTIVITY TEST"
echo "============================"
echo "Testing network connectivity to Cursor services..." > network_test.txt
echo "Date: $(date)" >> network_test.txt
echo "" >> network_test.txt

echo "Ping test to api.cursor.sh:" >> network_test.txt
ping -c 4 api.cursor.sh >> network_test.txt 2>&1
echo "" >> network_test.txt

echo "Ping test to api.openai.com:" >> network_test.txt
ping -c 4 api.openai.com >> network_test.txt 2>&1
echo "" >> network_test.txt

echo "DNS resolution test:" >> network_test.txt
nslookup api.cursor.sh >> network_test.txt 2>&1
echo "" >> network_test.txt

echo "Network interfaces:" >> network_test.txt
ifconfig >> network_test.txt
echo "" >> network_test.txt

echo "✓ Network tests saved to network_test.txt"
echo ""

echo "3. CURSOR PROCESS ANALYSIS"
echo "========================="
echo "Checking Cursor processes..." > cursor_processes.txt
echo "Date: $(date)" >> cursor_processes.txt
echo "" >> cursor_processes.txt

echo "Cursor processes:" >> cursor_processes.txt
ps aux | grep -i cursor >> cursor_processes.txt
echo "" >> cursor_processes.txt

echo "Process tree for Cursor:" >> cursor_processes.txt
pstree -p $(pgrep -f cursor) >> cursor_processes.txt 2>&1
echo "" >> cursor_processes.txt

echo "Memory usage by Cursor:" >> cursor_processes.txt
ps -o pid,ppid,pmem,pcpu,comm -p $(pgrep -f cursor) >> cursor_processes.txt 2>&1
echo "" >> cursor_processes.txt

echo "✓ Cursor process analysis saved to cursor_processes.txt"
echo ""

echo "4. CURSOR LOGS ANALYSIS"
echo "======================="
echo "Checking Cursor logs..." > cursor_logs.txt
echo "Date: $(date)" >> cursor_logs.txt
echo "" >> cursor_logs.txt

if [ -f ~/Library/Logs/Cursor/Cursor.log ]; then
    echo "Last 50 lines of Cursor.log:" >> cursor_logs.txt
    tail -50 ~/Library/Logs/Cursor/Cursor.log >> cursor_logs.txt
    echo "" >> cursor_logs.txt
    
    echo "Error patterns in Cursor.log:" >> cursor_logs.txt
    grep -i "error\|fail\|timeout\|slow" ~/Library/Logs/Cursor/Cursor.log | tail -20 >> cursor_logs.txt
    echo "" >> cursor_logs.txt
else
    echo "Cursor.log not found at ~/Library/Logs/Cursor/Cursor.log" >> cursor_logs.txt
fi

echo "✓ Cursor logs analysis saved to cursor_logs.txt"
echo ""

echo "5. CURSOR DATA DIRECTORY ANALYSIS"
echo "================================="
echo "Analyzing Cursor data directories..." > cursor_data.txt
echo "Date: $(date)" >> cursor_data.txt
echo "" >> cursor_data.txt

echo "Cursor Application Support directory size:" >> cursor_data.txt
if [ -d ~/Library/Application\ Support/Cursor ]; then
    du -sh ~/Library/Application\ Support/Cursor >> cursor_data.txt
    echo "" >> cursor_data.txt
    
    echo "Subdirectory sizes:" >> cursor_data.txt
    du -sh ~/Library/Application\ Support/Cursor/* >> cursor_data.txt 2>&1
    echo "" >> cursor_data.txt
    
    echo "Cache directory contents:" >> cursor_data.txt
    ls -la ~/Library/Application\ Support/Cursor/CachedData >> cursor_data.txt 2>&1
    echo "" >> cursor_data.txt
else
    echo "Cursor Application Support directory not found" >> cursor_data.txt
fi

echo "✓ Cursor data analysis saved to cursor_data.txt"
echo ""

echo "6. SYSTEM PERFORMANCE MONITORING"
echo "==============================="
echo "Monitoring system performance for 30 seconds..." > performance_monitor.txt
echo "Date: $(date)" >> performance_monitor.txt
echo "" >> performance_monitor.txt

echo "Starting 30-second performance monitoring..." >> performance_monitor.txt
echo "This will monitor CPU, memory, and disk usage..." >> performance_monitor.txt
echo "" >> performance_monitor.txt

# Monitor for 30 seconds
for i in {1..6}; do
    echo "Sample $i (5-second interval):" >> performance_monitor.txt
    top -l 1 -n 5 >> performance_monitor.txt
    echo "---" >> performance_monitor.txt
    sleep 5
done

echo "✓ Performance monitoring completed and saved to performance_monitor.txt"
echo ""

echo "7. THERMAL STATUS CHECK"
echo "======================="
echo "Checking thermal status..." > thermal_status.txt
echo "Date: $(date)" >> thermal_status.txt
echo "" >> thermal_status.txt

echo "Thermal sensors:" >> thermal_status.txt
sudo powermetrics --samplers smc -n 1 >> thermal_status.txt 2>&1
echo "" >> thermal_status.txt

echo "Fan status:" >> thermal_status.txt
sudo powermetrics --samplers smc -n 1 | grep -i fan >> thermal_status.txt 2>&1
echo "" >> thermal_status.txt

echo "✓ Thermal status saved to thermal_status.txt"
echo ""

echo "8. GENERATING SUMMARY REPORT"
echo "==========================="
echo "Generating summary report..." > summary_report.txt
echo "Date: $(date)" >> summary_report.txt
echo "" >> summary_report.txt

echo "SYSTEM SUMMARY:" >> summary_report.txt
echo "===============" >> summary_report.txt
echo "macOS Version: $(sw_vers -productVersion)" >> summary_report.txt
echo "Model: $(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)" >> summary_report.txt
echo "Memory: $(system_profiler SPHardwareDataType | grep "Memory" | cut -d: -f2 | xargs)" >> summary_report.txt
echo "Processor: $(system_profiler SPHardwareDataType | grep "Processor" | cut -d: -f2 | xargs)" >> summary_report.txt
echo "" >> summary_report.txt

echo "DISK SPACE:" >> summary_report.txt
echo "===========" >> summary_report.txt
df -h / | tail -1 >> summary_report.txt
echo "" >> summary_report.txt

echo "MEMORY PRESSURE:" >> summary_report.txt
echo "================" >> summary_report.txt
vm_stat | grep -E "(free|inactive|active|wired|compressed)" >> summary_report.txt
echo "" >> summary_report.txt

echo "CURSOR PROCESSES:" >> summary_report.txt
echo "=================" >> summary_report.txt
ps aux | grep -i cursor | grep -v grep >> summary_report.txt
echo "" >> summary_report.txt

echo "NETWORK CONNECTIVITY:" >> summary_report.txt
echo "====================" >> summary_report.txt
ping -c 1 api.cursor.sh > /dev/null 2>&1 && echo "✓ api.cursor.sh reachable" >> summary_report.txt || echo "✗ api.cursor.sh unreachable" >> summary_report.txt
ping -c 1 api.openai.com > /dev/null 2>&1 && echo "✓ api.openai.com reachable" >> summary_report.txt || echo "✗ api.openai.com unreachable" >> summary_report.txt
echo "" >> summary_report.txt

echo "✓ Summary report saved to summary_report.txt"
echo ""

echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
echo ""
echo "All diagnostic files have been saved to: ~/cursor_debug_output/"
echo ""
echo "Files created:"
echo "- system_info.txt (System hardware and OS info)"
echo "- network_test.txt (Network connectivity tests)"
echo "- cursor_processes.txt (Cursor process analysis)"
echo "- cursor_logs.txt (Cursor log analysis)"
echo "- cursor_data.txt (Cursor data directory analysis)"
echo "- performance_monitor.txt (30-second performance monitoring)"
echo "- thermal_status.txt (Thermal and fan status)"
echo "- summary_report.txt (Quick summary of key findings)"
echo ""
echo "Next steps:"
echo "1. Review summary_report.txt for quick overview"
echo "2. Check cursor_logs.txt for error messages"
echo "3. Look at performance_monitor.txt for resource usage patterns"
echo "4. If issues found, try clearing Cursor cache:"
echo "   rm -rf ~/Library/Application\\ Support/Cursor/CachedData"
echo "   rm -rf ~/Library/Application\\ Support/Cursor/logs"
echo ""
echo "To view the summary report:"
echo "cat ~/cursor_debug_output/summary_report.txt"
echo ""
echo "To view all files:"
echo "ls -la ~/cursor_debug_output/"
echo ""








