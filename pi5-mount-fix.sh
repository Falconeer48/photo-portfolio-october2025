#!/bin/bash

# Mount Fix Script for Pi5
# Run this script on the Pi to fix the busy directory issue

echo "=== Pi5 Mount Fix Script ==="
echo "Fixing /mnt/Externaldrive busy directory issue"
echo ""

# Check current mount status
echo "📊 Current Mount Status:"
mount | grep -E "(Externaldrive|Data|sda1)"
echo ""

# Check directory status
echo "📁 Directory Status:"
ls -la /mnt/ | grep -E "(Externaldrive|Data)"
echo ""

# Check for processes using the directory
echo "🔍 Process Check:"
fuser -v /mnt/Externaldrive 2>/dev/null || echo "No processes found"
echo ""

# Try lazy unmount
echo "🔧 Attempting lazy unmount..."
if mount | grep -q "Externaldrive"; then
    sudo umount -l /mnt/Externaldrive
    echo "Lazy unmount completed"
    sleep 3
else
    echo "No mount found at /mnt/Externaldrive"
fi
echo ""

# Try to remove directory
echo "🗑️ Attempting to remove directory..."
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

# Verify final state
echo "✅ Final Verification:"
echo "📊 Mount Status:"
mount | grep -E "(Externaldrive|Data|sda1)"
echo ""
echo "📁 Directory Status:"
ls -la /mnt/ | grep -E "(Externaldrive|Data)" || echo "No Externaldrive directory found"
echo ""

echo "🎯 Expected Result:"
echo "  - /dev/sda1 should only be mounted at /mnt/Data"
echo "  - /mnt/Externaldrive should not exist"
echo ""

if [ ! -d "/mnt/Externaldrive" ] && mount | grep -q "sda1.*Data"; then
    echo "✅ SUCCESS: Mount fix completed!"
else
    echo "❌ Issue may still exist. Try rebooting: sudo reboot"
fi
