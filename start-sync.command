#!/bin/bash

# Photo Portfolio Sync Launcher
# This script can be double-clicked or run from terminal

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Signal handler for clean exit
cleanup() {
    echo "Received interrupt signal, cleaning up..."
    
    # Kill the sync script if it's running
    if [ -n "$SYNC_PID" ] && kill -0 "$SYNC_PID" 2>/dev/null; then
        echo "Stopping sync process..."
        kill "$SYNC_PID" 2>/dev/null
        wait "$SYNC_PID" 2>/dev/null
    fi
    
    echo "Cleanup complete. Exiting."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Function to show usage
show_usage() {
    echo "Photo Portfolio Sync"
    echo ""
    echo "Usage:"
    echo "  Double-click this file for one-time sync"
    echo "  Or run from terminal:"
    echo "    $0 sync     - One-time sync"
    echo "    $0 watch    - Continuous sync (watch mode)"
    echo "    $0 setup    - Initial setup"
    echo "    $0 remove <folder> - Remove specific folder"
    echo ""
    echo "Examples:"
    echo "  $0 watch     # Start continuous sync"
    echo "  $0 remove test  # Remove 'test' folder from Pi5"
}

# If no arguments provided (double-clicked), run one-time sync
if [ $# -eq 0 ]; then
    echo "Starting one-time sync..."
    echo "For continuous sync, run: $0 watch"
    echo ""
    echo "Press Ctrl+C to stop at any time"
    echo ""
    
    # Run the sync script and capture its PID
    "$SCRIPT_DIR/sync-to-pi5.sh" sync &
    SYNC_PID=$!
    
    # Wait for the sync script to complete
    wait "$SYNC_PID"
    SYNC_EXIT_CODE=$?
    
    if [ $SYNC_EXIT_CODE -eq 0 ]; then
        echo ""
        echo "Sync completed successfully!"
    else
        echo ""
        echo "Sync completed with errors (exit code: $SYNC_EXIT_CODE)"
    fi
    
    # Keep terminal open if double-clicked
    if [ -t 0 ]; then
        echo ""
        echo "Press Enter to close..."
        read -r
    fi
else
    # Pass all arguments to the sync script
    echo "Running sync with arguments: $*"
    echo "Press Ctrl+C to stop at any time"
    echo ""
    
    # Run the sync script and capture its PID
    "$SCRIPT_DIR/sync-to-pi5.sh" "$@" &
    SYNC_PID=$!
    
    # Wait for the sync script to complete
    wait "$SYNC_PID"
    SYNC_EXIT_CODE=$?
    
    if [ $SYNC_EXIT_CODE -eq 0 ]; then
        echo ""
        echo "Operation completed successfully!"
    else
        echo ""
        echo "Operation completed with errors (exit code: $SYNC_EXIT_CODE)"
    fi
    
    # Keep terminal open if double-clicked
    if [ -t 0 ]; then
        echo ""
        echo "Press Enter to close..."
        read -r
    fi
fi 