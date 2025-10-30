#!/bin/bash

### CONFIGURATION ###
SRC_DIR="/Volumes/M2 Drive/M2 Downloads/Series Transfers"
RSYNC_BIN="/opt/homebrew/bin/rsync"
GIG_URL="smb://admin@192.168.50.183/Gigabyte"
PLEX_URL="smb://ian:Falcon1959@192.168.50.243/Movies"

# Log directory: write logs into /Users/ian/Scripts
LOG_DIR="/Users/ian/Scripts"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/series_batch_transfer_$(date +%Y%m%d_%H%M%S).log"

# Logging: write timestamped entries to log file and stderr
log() {
    local ts
    ts="[$(date +'%Y-%m-%d %H:%M:%S')]"
    local entry
    entry="$ts $1"
    echo "$entry" | tee -a "$LOG_FILE" >&2
}

# Notification: macOS notification + terminal echo to stderr
notify() {
    /usr/bin/osascript -e "display notification \"$1\" with title \"$2\""
    echo "[NOTICE] $1" >&2
}

# Status dialog: Shows a dialog that stays open until dismissed
show_status() {
    /usr/bin/osascript -e "display dialog \"$1\" with title \"$2\" buttons {\"OK\"} default button \"OK\""
    echo "[STATUS] $1" >&2
}

# Progress notification: Shows progress in terminal and notification
notify_progress() {
    local message="$1"
    local title="$2"
    echo "[PROGRESS] $message" >&2
    /usr/bin/osascript -e "display notification \"$message\" with title \"$title\""
}

# mount_volume <Name> <SMB_URL>
# Handles stale dirs, retries, returns mount path on stdout
mount_volume() {
    local NAME="$1" URL="$2" VOLDIR="/Volumes"
    log "Checking existing mount for $NAME"

    # If already mounted under any NAME* directory, return it
    for mp in "$VOLDIR"/"$NAME"*; do
        if [ -d "$mp" ] && mount | grep -q " on $mp "; then
            log "$NAME already mounted at $mp"
            echo "$mp"
            return 0
        fi
    done
    
    # Special case: check if Movies share is already mounted for Plex
    if [ "$NAME" = "Plex" ] && [ -d "/Volumes/Movies" ] && mount | grep -q " on /Volumes/Movies "; then
        log "Plex Movies share already mounted at /Volumes/Movies"
        echo "/Volumes/Movies"
        return 0
    fi

    # Remove stale base dir if present
    if [ -d "$VOLDIR/$NAME" ] && ! mount | grep -q " on $VOLDIR/$NAME "; then
        log "Removing stale directory $VOLDIR/$NAME"
        rmdir "$VOLDIR/$NAME" 2>/dev/null
    fi

    # Attempt mount up to 3 times (delays 1s,2s,4s)
    local delay=1
    for attempt in {1..3}; do
        log "Mount attempt #$attempt for $NAME"
        osascript -e "mount volume \"$URL\""
        # check mounts
        for mp in "$VOLDIR"/"$NAME"*; do
            if mount | grep -q " on $mp "; then
                log "$NAME mounted at $mp"
                echo "$mp"
                return 0
            fi
        done
        sleep $delay
        delay=$((delay * 2))
    done

    return 1
}

# check_space <source_path> <dest_path1> <dest_path2>
check_space() {
    local source_path="$1"
    local dest_path1="$2"
    local dest_path2="$3"
    
    log "Checking available space..."
    
    # Calculate source size
    local source_size
    source_size=$(du -sk "$source_path" | cut -f1)
    local source_size_mb=$((source_size / 1024))
    log "Source size: ${source_size_mb}MB"
    
    # Check available space on both destinations
    local dest1_available
    dest1_available=$(df -k "$dest_path1" | tail -1 | awk '{print $4}')
    local dest2_available
    dest2_available=$(df -k "$dest_path2" | tail -1 | awk '{print $4}')
    
    local dest1_available_mb=$((dest1_available / 1024))
    local dest2_available_mb=$((dest2_available / 1024))
    
    log "Available space - Gigabyte: ${dest1_available_mb}MB, Plex: ${dest2_available_mb}MB"
    
    # Check if both destinations have enough space
    if [ "$source_size" -gt "$dest1_available" ] || [ "$source_size" -gt "$dest2_available" ]; then
        local error_msg="Insufficient space! Source: ${source_size_mb}MB, Gigabyte: ${dest1_available_mb}MB, Plex: ${dest2_available_mb}MB"
        log "ERROR: $error_msg"
        notify "$error_msg" "Series Batch Transfer"
        return 1
    fi
    
    log "Space check passed - sufficient space available on both destinations"
    return 0
}

# transfer_series <series_name> <gig_mount> <plex_mount> [test_mode]
transfer_series() {
    local series_name="$1"
    local gig_mount="$2"
    local plex_mount="$3"
    local test_mode="${4:-false}"
    local series_src="$SRC_DIR/$series_name"
    
    log "Processing series: $series_name"
    
    # Check if series directory exists
    if [ ! -d "$series_src" ]; then
        log "WARNING: Series directory not found: $series_src"
        return 1
    fi
    
    # Create destination directories
    local dest_gig="$gig_mount/Series/$series_name"
    local dest_plex="$plex_mount/Series/$series_name"
    
    log "Creating destination directories: $dest_gig and $dest_plex"
    mkdir -p "$dest_gig" "$dest_plex"
    
    # Check if series already exists on both destinations
    if [ -d "$dest_gig" ] && [ -d "$dest_plex" ]; then
        local gig_files
        gig_files=$(find "$dest_gig" -type f | wc -l)
        local plex_files
        plex_files=$(find "$dest_plex" -type f | wc -l)
        local src_files
        src_files=$(find "$series_src" -type f | wc -l)
        
        if [ "$gig_files" -gt 0 ] && [ "$plex_files" -gt 0 ]; then
            log "INFO: $series_name already exists on both destinations"
            log "Gigabyte: $gig_files files, Pi5: $plex_files files, Source: $src_files files"
            log "Will add new files to existing series (rsync will handle duplicates)"
            
            if [ "$test_mode" = "true" ]; then
                log "[TEST MODE] Would add new files to existing $series_name"
                return 0
            else
                # Automatically proceed to add new files
                log "Adding new files to existing $series_name"
            fi
        fi
    fi
    
    # Check available space before transfer
    if ! check_space "$series_src" "$dest_gig" "$dest_plex"; then
        log "ERROR: Insufficient space for $series_name"
        return 1
    fi
    
    # Clean AppleDouble files
    log "Deleting AppleDouble files in targets for $series_name"
    find "$dest_gig" -name '._*' -delete 2>/dev/null
    find "$dest_plex" -name '._*' -delete 2>/dev/null
    
    # Transfer to Gigabyte
    if [ "$test_mode" = "true" ]; then
        log "[TEST MODE] Would transfer $series_name to $dest_gig"
        local r1=0
    else
        show_status "Starting transfer: $series_name → Gigabyte NAS" "Series Transfer Progress"
        log "[RSYNC] $series_name to $dest_gig"
        "$RSYNC_BIN" -a --info=progress2 --no-xattrs "${series_src}/" "$dest_gig"
        local r1
        r1=$?
        log "Rsync to Gigabyte for $series_name exit code: $r1"
        if [ $r1 -eq 0 ]; then
            show_status "✓ Completed: $series_name → Gigabyte NAS" "Series Transfer Progress"
        else
            show_status "✗ Failed: $series_name → Gigabyte NAS" "Series Transfer Progress"
        fi
    fi
    
    # Transfer to Plex
    if [ "$test_mode" = "true" ]; then
        log "[TEST MODE] Would transfer $series_name to $dest_plex"
        local r2=0
    else
        show_status "Starting transfer: $series_name → Plex Server" "Series Transfer Progress"
        log "[RSYNC] $series_name to $dest_plex"
        "$RSYNC_BIN" -a --info=progress2 --no-xattrs "${series_src}/" "$dest_plex"
        local r2
        r2=$?
        log "Rsync to Plex for $series_name exit code: $r2"
        if [ $r2 -eq 0 ]; then
            show_status "✓ Completed: $series_name → Plex Server" "Series Transfer Progress"
        else
            show_status "✗ Failed: $series_name → Plex Server" "Series Transfer Progress"
        fi
    fi
    
    # Check if both transfers succeeded
    if [ $r1 -eq 0 ] && [ $r2 -eq 0 ]; then
        log "SUCCESS: $series_name transferred to both destinations"
        notify "✓ $series_name transferred successfully" "Series Batch Transfer"
        return 0
    else
        log "ERROR: $series_name transfer failed (Gigabyte: $r1, Plex: $r2)"
        notify "✗ $series_name transfer failed" "Series Batch Transfer"
        return 1
    fi
}

### MAIN ###
# Parse command line arguments
TEST_MODE=false
if [ "$1" = "--test" ] || [ "$1" = "-t" ]; then
    TEST_MODE=true
    log "===== Series Batch Transfer started in TEST MODE ====="
else
    log "===== Series Batch Transfer started ====="
fi

# 1) Mount Gigabyte and Plex
GIG_MOUNT=$(mount_volume "Gigabyte" "$GIG_URL") || {
    log "ERROR: Could not mount Gigabyte"
    notify "Could not mount Gigabyte" "Series Batch Transfer"
    exit 1
}
PLEX_MOUNT=$(mount_volume "Plex" "$PLEX_URL") || {
    log "ERROR: Could not mount Plex"
    notify "Could not mount Plex" "Series Batch Transfer"
    exit 1
}

# 2) Verify source directory
log "Verifying source directory: $SRC_DIR"
if [ ! -d "$SRC_DIR" ]; then
    log "ERROR: Source directory not found"
    notify "Source folder not found: $SRC_DIR" "Series Batch Transfer"
    exit 1
fi

# 3) Find all series directories
log "Scanning for series directories in $SRC_DIR"
series_dirs=()
while IFS= read -r -d '' dir; do
    if [ -d "$dir" ]; then
        series_name=$(basename "$dir")
        series_dirs+=("$series_name")
        log "Found series: $series_name"
    fi
done < <(find "$SRC_DIR" -maxdepth 1 -type d -not -path "$SRC_DIR" -print0)

# 4) Check if any series found
if [ ${#series_dirs[@]} -eq 0 ]; then
    log "ERROR: No series directories found in $SRC_DIR"
    notify "No series folders found in source directory" "Series Batch Transfer"
    exit 1
fi

log "Found ${#series_dirs[@]} series to transfer: ${series_dirs[*]}"

# 5) Ask for confirmation
series_list=$(printf '%s\n' "${series_dirs[@]}")
if [ "$TEST_MODE" = "true" ]; then
    confirm_msg="[TEST MODE] Found the following series to analyze:\n\n$series_list\n\nThis will check space requirements and show what would be transferred.\nDo you want to proceed with the test?"
    button_text="Test All"
else
    confirm_msg="Found the following series to transfer:\n\n$series_list\n\nDo you want to proceed with the batch transfer?"
    button_text="Transfer All"
fi
osascript -e "display dialog \"$confirm_msg\" buttons {\"Cancel\", \"$button_text\"} default button \"$button_text\""

if [ $? -ne 0 ]; then
    log "User cancelled batch transfer"
    notify "Batch transfer cancelled" "Series Batch Transfer"
    exit 0
fi

# 6) Transfer each series
successful=0
failed=0

for series in "${series_dirs[@]}"; do
    if transfer_series "$series" "$GIG_MOUNT" "$PLEX_MOUNT" "$TEST_MODE"; then
        ((successful++))
    else
        ((failed++))
    fi
done

# 7) Summary
log "===== Transfer Summary ====="
log "Successful transfers: $successful"
log "Failed transfers: $failed"
log "Total series processed: ${#series_dirs[@]}"

if [ "$TEST_MODE" = "true" ]; then
    if [ $failed -eq 0 ]; then
        notify "Test completed successfully! All series have sufficient space ($successful series)" "Series Batch Transfer"
        log "===== Test completed successfully ====="
    else
        notify "Test completed with $failed failures ($successful successful, $failed failed)" "Series Batch Transfer"
        log "===== Test completed with some failures ====="
    fi
    echo "Test complete. Log file: $LOG_FILE"
    echo "No files were transferred in test mode."
else
    if [ $failed -eq 0 ]; then
        notify "All series transferred successfully! $successful series" "Series Batch Transfer"
        log "===== All transfers completed successfully ====="
    else
        notify "Transfer completed with $failed failures - $successful successful, $failed failed" "Series Batch Transfer"
        log "===== Transfer completed with some failures ====="
    fi
    echo "Done. Log file: $LOG_FILE"
    echo "Source files have been preserved in: $SRC_DIR"
fi
