#!/bin/bash

# Time Machine Diagnostic and Repair Script
# This script provides comprehensive diagnostics and repair options

set -e

echo "=== Time Machine Diagnostic and Repair Tool ==="
echo ""

# Function to check Time Machine status
check_tm_status() {
    echo "📊 Time Machine Status:"
    tmutil status
    echo ""
}

# Function to check destinations
check_destinations() {
    echo "🎯 Time Machine Destinations:"
    tmutil destinationinfo
    echo ""
}

# Function to check sparsebundle integrity
check_sparsebundle() {
    echo "🔍 Checking Sparsebundle Integrity:"
    
    TIMEMACHINE_VOLUME="/Volumes/TimeMachine"
    if [ -d "$TIMEMACHINE_VOLUME" ]; then
        echo "TimeMachine volume mounted at: $TIMEMACHINE_VOLUME"
        
        for sparsebundle in "$TIMEMACHINE_VOLUME"/*.sparsebundle; do
            if [ -d "$sparsebundle" ]; then
                echo ""
                echo "Sparsebundle: $(basename "$sparsebundle")"
                echo "  Path: $sparsebundle"
                echo "  Size: $(du -sh "$sparsebundle" | cut -f1)"
                
                # Check Info.plist
                if [ -f "$sparsebundle/Info.plist" ]; then
                    echo "  Info.plist: ✅ Present"
                    # Check for UUID
                    if grep -q "uuid" "$sparsebundle/Info.plist"; then
                        echo "  UUID: ✅ Present"
                    else
                        echo "  UUID: ❌ Missing (This is likely the cause of your error)"
                    fi
                else
                    echo "  Info.plist: ❌ Missing"
                fi
                
                # Check MachineID
                if [ -f "$sparsebundle/com.apple.TimeMachine.MachineID.plist" ]; then
                    echo "  MachineID: ✅ Present"
                else
                    echo "  MachineID: ❌ Missing"
                fi
            fi
        done
    else
        echo "❌ TimeMachine volume not mounted"
    fi
    echo ""
}

# Function to check network connectivity
check_network() {
    echo "🌐 Network Connectivity:"
    
    # Check if we can reach the Pi
    if ping -c 1 MYPI5._smb._tcp.local. >/dev/null 2>&1; then
        echo "✅ Can reach Raspberry Pi (MYPI5._smb._tcp.local.)"
    else
        echo "❌ Cannot reach Raspberry Pi"
    fi
    
    # Check SMB mount
    if mount | grep -q "TimeMachine"; then
        echo "✅ TimeMachine SMB share is mounted"
    else
        echo "❌ TimeMachine SMB share not mounted"
    fi
    echo ""
}

# Function to show recent Time Machine logs
show_logs() {
    echo "📋 Recent Time Machine Logs:"
    echo "Running: log stream --predicate 'subsystem == \"com.apple.TimeMachine\"' --last 5m"
    echo "(Press Ctrl+C to stop)"
    echo ""
    log stream --predicate 'subsystem == "com.apple.TimeMachine"' --last 5m
}

# Function to repair permissions
repair_permissions() {
    echo "🔧 Repairing Sparsebundle Permissions:"
    
    TIMEMACHINE_VOLUME="/Volumes/TimeMachine"
    if [ -d "$TIMEMACHINE_VOLUME" ]; then
        for sparsebundle in "$TIMEMACHINE_VOLUME"/*.sparsebundle; do
            if [ -d "$sparsebundle" ]; then
                echo "Repairing permissions for: $(basename "$sparsebundle")"
                chmod -R 755 "$sparsebundle"
                chown -R $(whoami):staff "$sparsebundle"
            fi
        done
        echo "✅ Permissions repaired"
    else
        echo "❌ TimeMachine volume not mounted"
    fi
    echo ""
}

# Main menu
show_menu() {
    echo "Please select an option:"
    echo "1. Check Time Machine Status"
    echo "2. Check Destinations"
    echo "3. Check Sparsebundle Integrity"
    echo "4. Check Network Connectivity"
    echo "5. Show Recent Logs"
    echo "6. Repair Permissions"
    echo "7. Run All Diagnostics"
    echo "8. Exit"
    echo ""
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1) check_tm_status ;;
        2) check_destinations ;;
        3) check_sparsebundle ;;
        4) check_network ;;
        5) show_logs ;;
        6) repair_permissions ;;
        7) 
            check_tm_status
            check_destinations
            check_sparsebundle
            check_network
            ;;
        8) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_menu
}

# Run initial diagnostics
echo "Running initial diagnostics..."
check_tm_status
check_destinations
check_sparsebundle
check_network

echo "=== Recommendations ==="
echo "Based on the diagnostics above:"
echo "1. If UUID is missing from sparsebundle, run: ./fix-timemachine-sparsebundle.sh"
echo "2. If sparsebundle is severely corrupted, run: ./recreate-timemachine-sparsebundle.sh"
echo "3. If network issues, check your Raspberry Pi SMB configuration"
echo ""

show_menu
