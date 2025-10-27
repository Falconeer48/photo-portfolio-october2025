#!/bin/bash

# Fixed PDF printer monitor for iMac
# This script properly monitors the IncomingPrints folder and prints PDFs

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

WATCHED_FOLDER="$HOME/IncomingPrints"
PRINTER="Canon_G4070_series"
LOG_FILE="$WATCHED_FOLDER/printer-monitor.log"

# Create the watched folder if it doesn't exist
mkdir -p "$WATCHED_FOLDER"

# Function to print a PDF
print_pdf() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_status $BLUE "📄 Printing: $filename" | tee -a "$LOG_FILE"
    
    if lp -d "$PRINTER" "$file"; then
        print_status $GREEN "✅ Successfully printed: $filename" | tee -a "$LOG_FILE"
        echo "$(date): Printed $filename" >> "$WATCHED_FOLDER/print-log.txt"
        return 0
    else
        print_status $RED "❌ Failed to print: $filename" | tee -a "$LOG_FILE"
        echo "$(date): Failed to print $filename" >> "$WATCHED_FOLDER/print-log.txt"
        return 1
    fi
}

# Function to monitor folder
monitor_folder() {
    print_status $BLUE "👀 Starting PDF monitor for: $WATCHED_FOLDER" | tee -a "$LOG_FILE"
    print_status $BLUE "🖨️  Printer: $PRINTER" | tee -a "$LOG_FILE"
    echo "Monitor started at $(date)" >> "$LOG_FILE"
    
    # Get initial list of PDF files
    previous_files=$(find "$WATCHED_FOLDER" -name "*.pdf" -type f 2>/dev/null | sort)
    
    while true; do
        # Get current list of PDF files
        current_files=$(find "$WATCHED_FOLDER" -name "*.pdf" -type f 2>/dev/null | sort)
        
        # Find new files
        new_files=$(comm -13 <(echo "$previous_files") <(echo "$current_files"))
        
        if [ -n "$new_files" ]; then
            echo "$new_files" | while read -r file; do
                if [ -f "$file" ]; then
                    # Wait a moment to ensure file is fully written
                    sleep 2
                    print_pdf "$file"
                fi
            done
        fi
        
        # Update previous files list
        previous_files="$current_files"
        
        # Wait 3 seconds before checking again
        sleep 3
    done
}

# Check if we should run in background
if [ "$1" = "--background" ]; then
    print_status $YELLOW "🔄 Running in background mode..."
    nohup "$0" > "$LOG_FILE" 2>&1 &
    echo $! > "$WATCHED_FOLDER/printer-monitor.pid"
    print_status $GREEN "✅ Printer monitor started in background (PID: $!)"
    print_status $BLUE "📋 To stop: kill \$(cat $WATCHED_FOLDER/printer-monitor.pid)"
    print_status $BLUE "📋 To view log: tail -f $LOG_FILE"
else
    monitor_folder
fi
