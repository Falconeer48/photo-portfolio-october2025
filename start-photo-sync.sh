#!/bin/bash

# Photo Sync Startup Script with Delete After Sync
# This script starts the photo sync in watch mode and deletes images from Mac after successful sync

# Set the working directory
cd /Users/ian/Scripts

# Start the sync script in watch mode (with delete after sync)
# The script will run continuously and monitor for changes
/Users/ian/Scripts/sync-to-pi5-delete.sh watch

# Keep the script running
while true; do
    sleep 10
done 