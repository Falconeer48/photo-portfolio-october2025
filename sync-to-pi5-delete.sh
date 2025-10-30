#!/bin/bash

# Photo Portfolio Sync Script with Delete After Sync
# Syncs images from Mac Mini to Pi5 and deletes from Mac after successful sync

# Configuration
SOURCE_DIR="/Users/ian/Portfolio Images to Transfer"
PI5_HOST="ian@192.168.50.243"
PI5_PORT="22"
PI5_DEST_DIR="/media/ian/Externaldrive/Cursor_Projects/photo-portfolio/public/images/portfolio"
LOG_FILE="/Users/ian/photo-portfolio/sync.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables for cleanup
FSWATCH_PID=""
SSH_PIDS=()

# Signal handler for clean exit
cleanup() {
    log "${YELLOW}Received interrupt signal, cleaning up...${NC}"
    
    # Kill fswatch if running
    if [ -n "$FSWATCH_PID" ] && kill -0 "$FSWATCH_PID" 2>/dev/null; then
        log "${BLUE}Stopping file watcher...${NC}"
        kill "$FSWATCH_PID" 2>/dev/null
        wait "$FSWATCH_PID" 2>/dev/null
    fi
    
    # Kill any background SSH processes
    for pid in "${SSH_PIDS[@]}"; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        fi
    done
    
    log "${GREEN}Cleanup complete. Exiting.${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log "${RED}ERROR: Source directory '$SOURCE_DIR' does not exist${NC}"
    log "${YELLOW}Creating source directory...${NC}"
    mkdir -p "$SOURCE_DIR"
    log "${GREEN}Created source directory: $SOURCE_DIR${NC}"
fi

# Function to get folder names from the Pi5 dynamically
get_pi5_folders() {
    ssh -p "$PI5_PORT" "$PI5_HOST" "find '$PI5_DEST_DIR' -mindepth 1 -maxdepth 1 -type d -printf '%f\n'" 2>/dev/null
}

# Updated map_folder_name: convert underscores to spaces and capitalize words
map_folder_name() {
    local source_name="$1"
    # Replace underscores with spaces and capitalize each word
    local spaced_name="${source_name//_/ }"
    # Capitalize each word
    echo "$spaced_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1'
}

# Function to sync a single folder and delete from Mac after successful sync
sync_folder_and_delete() {
    local source_folder_name="$1"
    local dest_folder_name=$(map_folder_name "$source_folder_name")
    local source_folder="$SOURCE_DIR/$source_folder_name"
    local dest_folder="$PI5_DEST_DIR/$dest_folder_name"
    
    if [ ! -d "$source_folder" ]; then
        log "${YELLOW}Source folder '$source_folder_name' doesn't exist, skipping${NC}"
        return
    fi
    
    log "${BLUE}Syncing folder: $source_folder_name -> $dest_folder_name${NC}"

    # Ensure Cover.jpg exists in the source folder before syncing
    cover_path="$source_folder/Cover.jpg"
    if [ ! -f "$cover_path" ]; then
        first_image=$(find "$source_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | sort | head -n 1)
        if [ -n "$first_image" ]; then
            mv "$first_image" "$cover_path"
            log "${GREEN}Renamed $(basename "$first_image") to Cover.jpg in $source_folder_name${NC}"
        else
            log "${YELLOW}No image found to set as Cover.jpg in $source_folder_name${NC}"
        fi
    fi

    # Create destination folder on Pi5 if it doesn't exist
    ssh -p "$PI5_PORT" "$PI5_HOST" "mkdir -p '$dest_folder'" &
    SSH_PIDS+=($!)
    wait $!
    
    # Sync files using rsync
    rsync -avz --progress \
        --exclude='*.DS_Store' \
        --exclude='Thumbs.db' \
        --exclude='*.tmp' \
        "$source_folder/" \
        "$PI5_HOST:$dest_folder/"
    
    if [ $? -eq 0 ]; then
        log "${GREEN}Successfully synced folder: $source_folder_name -> $dest_folder_name${NC}"
        
        # Refresh portfolio configuration on Pi5
        log "${BLUE}Refreshing portfolio configuration on Pi5...${NC}"
        ssh -p "$PI5_PORT" "$PI5_HOST" "curl -s -X POST https://localhost/api/refresh-config -k" &
        SSH_PIDS+=($!)
        wait $!
        
        if [ $? -eq 0 ]; then
            log "${GREEN}Portfolio configuration refreshed successfully${NC}"
            
            # DELETE IMAGES FROM MAC AFTER SUCCESSFUL SYNC
            log "${YELLOW}Deleting images from Mac after successful sync...${NC}"
            
            # Count files before deletion
            file_count=$(find "$source_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
            
            # Delete all image files from Mac (but keep the folder structure)
            find "$source_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -delete
            
            log "${GREEN}Successfully deleted $file_count images from Mac folder: $source_folder_name${NC}"
            log "${BLUE}Folder structure preserved on Mac for future use${NC}"
            
        else
            log "${YELLOW}Warning: Failed to refresh portfolio configuration${NC}"
        fi
    else
        log "${RED}Failed to sync folder: $source_folder_name -> $dest_folder_name${NC}"
        log "${RED}Images NOT deleted from Mac due to sync failure${NC}"
    fi
}

# Function to handle folder deletions
handle_deletions() {
    log "${BLUE}Checking for deleted folders...${NC}"
    
    # Get list of folders on Pi5
    local pi5_folders=$(ssh -p "$PI5_PORT" "$PI5_HOST" "find '$PI5_DEST_DIR' -maxdepth 1 -type d -printf '%f\n'" | grep -v "^portfolio$" | grep -v "^\.$")
    
    # Check each Pi5 folder against local folders
    while IFS= read -r pi5_folder_name; do
        if [ -n "$pi5_folder_name" ]; then
            # Check if any local folder maps to this Pi5 folder
            local folder_found=false
            for local_folder in "$SOURCE_DIR"/*/; do
                if [ -d "$local_folder" ]; then
                    local local_folder_name=$(basename "$local_folder")
                    local mapped_name=$(map_folder_name "$local_folder_name")
                    if [ "$mapped_name" = "$pi5_folder_name" ]; then
                        folder_found=true
                        break
                    fi
                fi
            done
            
            if [ "$folder_found" = false ]; then
                log "${YELLOW}Local folder mapping to '$pi5_folder_name' not found, removing from Pi5...${NC}"
                
                # Remove folder from Pi5
                ssh -p "$PI5_PORT" "$PI5_HOST" "rm -rf '$PI5_DEST_DIR/$pi5_folder_name'" &
                SSH_PIDS+=($!)
                wait $!
                
                if [ $? -eq 0 ]; then
                    log "${GREEN}Successfully removed folder from Pi5: $pi5_folder_name${NC}"
                    
                    # Refresh portfolio configuration on Pi5
                    log "${BLUE}Refreshing portfolio configuration on Pi5...${NC}"
                    ssh -p "$PI5_PORT" "$PI5_HOST" "curl -s -X POST https://localhost/api/refresh-config -k" &
                    SSH_PIDS+=($!)
                    wait $!
                    
                    if [ $? -eq 0 ]; then
                        log "${GREEN}Portfolio configuration refreshed successfully${NC}"
                    else
                        log "${YELLOW}Warning: Failed to refresh portfolio configuration${NC}"
                    fi
                else
                    log "${RED}Failed to remove folder from Pi5: $pi5_folder_name${NC}"
                fi
            fi
        fi
    done <<< "$pi5_folders"
}

# Function to cleanup duplicate folders on Pi5
cleanup_duplicates() {
    log "${BLUE}Cleaning up duplicate folders on Pi5...${NC}"
    
    # Function to map folder names (same as sync script)
    map_folder_name() {
        local source_name="$1"
        # Replace underscores with spaces and capitalize each word
        local spaced_name="${source_name//_/ }"
        # Capitalize each word
        echo "$spaced_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1'
    }
    
    # Get all folders on Pi5
    folders=$(ssh -p "$PI5_PORT" "$PI5_HOST" "ls -1 '$PI5_DEST_DIR' | grep -E '^[A-Za-z_]+$'")
    
    # Check for duplicates
    duplicates_found=false
    
    while IFS= read -r folder; do
        if [ -n "$folder" ]; then
            # Check if this folder has an underscore version
            underscore_version="${folder// /_}"
            if [ "$folder" != "$underscore_version" ] && ssh -p "$PI5_PORT" "$PI5_HOST" "[ -d '$PI5_DEST_DIR/$underscore_version' ]"; then
                log "${YELLOW}Found duplicate: '$folder' and '$underscore_version'${NC}"
                log "${BLUE}Removing underscore version: '$underscore_version'${NC}"
                
                ssh -p "$PI5_PORT" "$PI5_HOST" "rm -rf '$PI5_DEST_DIR/$underscore_version'" &
                SSH_PIDS+=($!)
                wait $!
                
                if [ $? -eq 0 ]; then
                    log "${GREEN}Successfully removed duplicate folder: $underscore_version${NC}"
                    duplicates_found=true
                else
                    log "${RED}Failed to remove duplicate folder: $underscore_version${NC}"
                fi
            fi
        fi
    done <<< "$folders"
    
    if [ "$duplicates_found" = false ]; then
        log "${GREEN}No duplicate folders found!${NC}"
    fi
}

# Function to sync all folders
sync_all_folders() {
    log "${BLUE}Starting sync of all folders...${NC}"
    
    # Get list of folders in source directory
    for folder in "$SOURCE_DIR"/*/; do
        if [ -d "$folder" ]; then
            folder_name=$(basename "$folder")
            sync_folder_and_delete "$folder_name"
        fi
    done
    
    # Clean up duplicates after sync
    cleanup_duplicates
    
    log "${GREEN}Sync completed!${NC}"
}

# Function to watch for changes and sync automatically
watch_and_sync() {
    log "${BLUE}Starting file watcher...${NC}"
    log "${YELLOW}Watching for changes in: $SOURCE_DIR${NC}"
    log "${YELLOW}Press Ctrl+C to stop watching${NC}"
    
    # Check if fswatch is installed
    if ! command -v fswatch &> /dev/null; then
        log "${RED}ERROR: fswatch is not installed${NC}"
        log "${YELLOW}Please install fswatch: brew install fswatch${NC}"
        exit 1
    fi
    
    # Start fswatch in background
    fswatch -o "$SOURCE_DIR" | while read f; do
        log "${BLUE}Change detected, starting sync...${NC}"
        sync_all_folders
        log "${BLUE}Watching for more changes...${NC}"
    done &
    
    FSWATCH_PID=$!
    log "${GREEN}File watcher started with PID: $FSWATCH_PID${NC}"
    
    # Wait for fswatch to exit
    wait $FSWATCH_PID
}

# Main script logic
case "${1:-}" in
    "sync")
        sync_all_folders
        ;;
    "watch")
        watch_and_sync
        ;;
    "cleanup")
        cleanup_duplicates
        ;;
    "delete")
        handle_deletions
        ;;
    *)
        echo "Usage: $0 {sync|watch|cleanup|delete}"
        echo ""
        echo "Commands:"
        echo "  sync     - Sync all folders once"
        echo "  watch    - Watch for changes and sync automatically"
        echo "  cleanup  - Clean up duplicate folders on Pi5"
        echo "  delete   - Handle folder deletions"
        echo ""
        echo "This version DELETES images from Mac after successful sync to Pi5!"
        echo "Use with caution - images will be permanently removed from Mac."
        exit 1
        ;;
esac 