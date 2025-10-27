#!/bin/bash

# Raspberry Pi 5 Mount Point Fix Script
# This script resolves the busy directory issue on the Pi

set -e

echo "=== Raspberry Pi 5 Mount Point Fix ==="
echo "Fixing busy directory issue for /mnt/Externaldrive"
echo ""

# Function to check current state
check_state() {
    echo "📊 Current Mount Status:"
    mount | grep -E "(Externaldrive|Data|sda1)"
    echo ""
    
    echo "📁 Directory Status:"
    ls -la /mnt/ | grep -E "(Externaldrive|Data)"
    echo ""
    
    echo "🔍 Process Check:"
    fuser -v /mnt/Externaldrive 2>/dev/null || echo "No processes found"
    echo ""
}

# Function to fix the issue
fix_mount_issue() {
    echo "🔧 Starting fix process..."
    
    # Step 1: Check for stale mount entries
    echo "Step 1: Checking /proc/mounts..."
    if grep -q "Externaldrive" /proc/mounts; then
        echo "Found stale mount entry in /proc/mounts"
        grep "Externaldrive" /proc/mounts
    else
        echo "No stale mount entries found"
    fi
    echo ""
    
    # Step 2: Try lazy unmount
    echo "Step 2: Attempting lazy unmount..."
    if mount | grep -q "Externaldrive"; then
        sudo umount -l /mnt/Externaldrive
        echo "Lazy unmount completed"
        sleep 2
    else
        echo "No mount found at /mnt/Externaldrive"
    fi
    echo ""
    
    # Step 3: Check findmnt
    echo "Step 3: Checking findmnt..."
    findmnt /mnt/Externaldrive 2>/dev/null || echo "No mount found by findmnt"
    echo ""
    
    # Step 4: Try to remove directory
    echo "Step 4: Attempting to remove directory..."
    if [ -d "/mnt/Externaldrive" ]; then
        if sudo rmdir /mnt/Externaldrive 2>/dev/null; then
            echo "✅ Directory removed successfully with rmdir"
        else
            echo "rmdir failed, trying force removal..."
            sudo rm -rf /mnt/Externaldrive
            echo "✅ Directory removed with force removal"
        fi
    else
        echo "Directory doesn't exist"
    fi
    echo ""
    
    # Step 5: Verify final state
    echo "Step 5: Verifying final state..."
    if [ -d "/mnt/Externaldrive" ]; then
        echo "❌ Directory still exists"
        echo "Final attempt with different approach..."
        
        # Try to find what's keeping it busy
        echo "Checking for any remaining processes..."
        fuser -v /mnt/Externaldrive 2>/dev/null || echo "No processes found"
        
        # Try to kill any processes
        echo "Attempting to kill any processes using the directory..."
        sudo fuser -k /mnt/Externaldrive 2>/dev/null || echo "No processes to kill"
        
        # Wait and try again
        sleep 3
        sudo rm -rf /mnt/Externaldrive
        echo "✅ Final removal attempt completed"
    else
        echo "✅ Directory successfully removed"
    fi
}

# Function to verify the fix
verify_fix() {
    echo ""
    echo "=== Verification ==="
    echo "📊 Final Mount Status:"
    mount | grep -E "(Externaldrive|Data|sda1)"
    echo ""
    
    echo "📁 Final Directory Status:"
    ls -la /mnt/ | grep -E "(Externaldrive|Data)" || echo "No Externaldrive directory found"
    echo ""
    
    echo "🎯 Expected Result:"
    echo "  - /dev/sda1 should only be mounted at /mnt/Data"
    echo "  - /mnt/Externaldrive should not exist"
    echo ""
}

# Main execution
main() {
    echo "Starting mount point fix..."
    echo ""
    
    # Show initial state
    check_state
    
    # Ask for confirmation
    read -p "Do you want to proceed with the fix? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Operation cancelled."
        exit 0
    fi
    
    # Run the fix
    fix_mount_issue
    
    # Verify the fix
    verify_fix
    
    echo "✅ Mount point fix completed!"
    echo ""
    echo "If the issue persists, you may need to reboot the system:"
    echo "sudo reboot"
}

# Run the main function
main
