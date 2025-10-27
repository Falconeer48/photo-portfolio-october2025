#!/bin/bash

# Alternative Solution: Recreate Time Machine sparsebundle
# This script removes the corrupted sparsebundle and recreates it

set -e

TIMEMACHINE_VOLUME="/Volumes/TimeMachine"
SPARSEBUNDLE_NAME="Ian's iMac.sparsebundle"
SPARSEBUNDLE_PATH="$TIMEMACHINE_VOLUME/$SPARSEBUNDLE_NAME"

echo "=== Time Machine Sparsebundle Recreation ==="
echo "⚠️  WARNING: This will remove your existing backup data!"
echo "Make sure you have another backup before proceeding."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Stopping Time Machine..."
sudo tmutil stopbackup

echo "Removing corrupted sparsebundle..."
if [ -d "$SPARSEBUNDLE_PATH" ]; then
    # Create a backup directory with timestamp
    BACKUP_DIR="$TIMEMACHINE_VOLUME/backup_$(date +%Y%m%d_%H%M%S)"
    echo "Moving sparsebundle to backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mv "$SPARSEBUNDLE_PATH" "$BACKUP_DIR/"
else
    echo "Sparsebundle not found at $SPARSEBUNDLE_PATH"
fi

echo "Removing Time Machine destination..."
sudo tmutil removedestination "$(tmutil destinationinfo | grep "ID" | awk '{print $3}')"

echo "Re-adding Time Machine destination..."
sudo tmutil setdestination -a "$TIMEMACHINE_VOLUME"

echo "Starting Time Machine backup..."
sudo tmutil startbackup

echo "✅ Time Machine sparsebundle recreation completed!"
echo "Your backup will start fresh. This may take several hours for the initial backup."
echo ""
echo "Monitor progress with:"
echo "tmutil status"
echo "log stream --predicate 'subsystem == \"com.apple.TimeMachine\"'"
