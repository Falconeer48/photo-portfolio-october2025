#!/bin/bash

# Script to rename mount point from /mnt/Externaldrive to /mnt/Data
# This script safely unmounts, creates new mount point, and remounts

set -e

OLD_MOUNT="/mnt/Externaldrive"
NEW_MOUNT="/mnt/Data"

echo "=== Mount Point Rename Script ==="
echo "Renaming: $OLD_MOUNT -> $NEW_MOUNT"
echo ""

# Check if old mount exists
if [ ! -d "$OLD_MOUNT" ]; then
    echo "❌ Old mount point $OLD_MOUNT does not exist"
    exit 1
fi

# Check if old mount is actually mounted
if ! mount | grep -q "$OLD_MOUNT"; then
    echo "⚠️  $OLD_MOUNT exists but is not mounted"
    echo "You can simply rename it:"
    echo "sudo mv $OLD_MOUNT $NEW_MOUNT"
    exit 0
fi

# Get the device information
DEVICE_INFO=$(mount | grep "$OLD_MOUNT" | head -1)
if [ -z "$DEVICE_INFO" ]; then
    echo "❌ Could not find mount information for $OLD_MOUNT"
    exit 1
fi

echo "📋 Current mount information:"
echo "$DEVICE_INFO"
echo ""

# Extract device and filesystem type
DEVICE=$(echo "$DEVICE_INFO" | awk '{print $1}')
FSTYPE=$(echo "$DEVICE_INFO" | awk '{print $5}')
OPTIONS=$(echo "$DEVICE_INFO" | awk '{print $6}' | sed 's/(//g' | sed 's/)//g')

echo "🔍 Detected:"
echo "  Device: $DEVICE"
echo "  Filesystem: $FSTYPE"
echo "  Options: $OPTIONS"
echo ""

# Check if new mount point already exists
if [ -d "$NEW_MOUNT" ]; then
    echo "⚠️  $NEW_MOUNT already exists"
    if mount | grep -q "$NEW_MOUNT"; then
        echo "❌ $NEW_MOUNT is already mounted. Please unmount it first."
        exit 1
    else
        echo "✅ $NEW_MOUNT exists but is not mounted. Proceeding..."
    fi
else
    echo "📁 Creating new mount point: $NEW_MOUNT"
    sudo mkdir -p "$NEW_MOUNT"
fi

# Check for processes using the old mount
echo "🔍 Checking for processes using $OLD_MOUNT..."
PROCESSES=$(lsof +D "$OLD_MOUNT" 2>/dev/null | wc -l)
if [ "$PROCESSES" -gt 1 ]; then
    echo "⚠️  Found processes using $OLD_MOUNT:"
    lsof +D "$OLD_MOUNT" 2>/dev/null | head -10
    echo ""
    read -p "Continue anyway? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Operation cancelled."
        exit 0
    fi
else
    echo "✅ No processes found using $OLD_MOUNT"
fi

echo ""
echo "🚀 Proceeding with mount point rename..."

# Unmount the old mount point
echo "📤 Unmounting $OLD_MOUNT..."
sudo umount "$OLD_MOUNT"

# Mount to new location
echo "📥 Mounting $DEVICE to $NEW_MOUNT..."
if [ -n "$OPTIONS" ] && [ "$OPTIONS" != "rw" ]; then
    sudo mount -t "$FSTYPE" -o "$OPTIONS" "$DEVICE" "$NEW_MOUNT"
else
    sudo mount -t "$FSTYPE" "$DEVICE" "$NEW_MOUNT"
fi

# Remove old mount point
echo "🗑️  Removing old mount point..."
sudo rmdir "$OLD_MOUNT"

# Verify the new mount
echo ""
echo "✅ Mount point rename completed!"
echo "📋 New mount information:"
mount | grep "$NEW_MOUNT"

echo ""
echo "📁 Contents of $NEW_MOUNT:"
ls -la "$NEW_MOUNT" | head -10

echo ""
echo "💡 To make this permanent, update your /etc/fstab:"
echo "   Change any references from $OLD_MOUNT to $NEW_MOUNT"
