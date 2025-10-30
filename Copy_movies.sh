#!/bin/bash

### CONFIGURATION ###
DRY_RUN=false
SRC_DIR="/Volumes/M2 Drive/M2 Downloads/Movie Transfers"
RSYNC_BIN="/opt/homebrew/bin/rsync"
GIG_URL="smb://admin@192.168.50.183/Gigabyte/Movies"
PLEX_URL="smb://ian:Falcon1959@192.168.50.243/mnt/Plex/Movies"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run    Show what would be transferred without actually transferring"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Log directory: write logs into /Users/ian/Scripts
LOG_DIR="/Users/ian/Scripts"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/movie_transfer_$(date +%Y%m%d_%H%M%S).log"

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

# Space checking function
check_space() {
    local source_path="$1"
    local dest_path1="$2"
    local dest_path2="$3"
    
    log "Checking available space..."
    
    # Calculate source size (with timeout to prevent hanging)
    local source_size
    source_size=$(timeout 30 du -sk "$source_path" 2>/dev/null | cut -f1)
    if [ -z "$source_size" ]; then
        log "WARNING: Could not calculate source size (timeout or error) - proceeding anyway"
        return 0
    fi
    
    local source_size_mb=$((source_size / 1024))
    log "Source size: ${source_size_mb}MB"
    
    # Check available space on both destinations
    local dest1_available
    dest1_available=$(df -k "$dest_path1" 2>/dev/null | tail -1 | awk '{print $4}')
    local dest2_available
    dest2_available=$(df -k "$dest_path2" 2>/dev/null | tail -1 | awk '{print $4}')
    
    if [ -z "$dest1_available" ] || [ -z "$dest2_available" ]; then
        log "WARNING: Could not check available space - proceeding anyway"
        return 0
    fi
    
    local dest1_available_mb=$((dest1_available / 1024))
    local dest2_available_mb=$((dest2_available / 1024))
    
    log "Available space - Gigabyte: ${dest1_available_mb}MB, Plex: ${dest2_available_mb}MB"
    
    # Check if both destinations have enough space
    if [ "$source_size" -gt "$dest1_available" ] || [ "$source_size" -gt "$dest2_available" ]; then
        local error_msg="Insufficient space! Source: ${source_size_mb}MB, Gigabyte: ${dest1_available_mb}MB, Plex: ${dest2_available_mb}MB"
        log "ERROR: $error_msg"
        notify "$error_msg" "Movie Transfer"
        return 1
    fi
    
    log "Space check passed - sufficient space available on both destinations"
    return 0
}

# mount_volume <Name> <SMB_URL>
# Handles stale dirs, retries, returns mount path on stdout
mount_volume() {
    local NAME="$1" URL="$2" VOLDIR="/Volumes"
    log "Checking existing mount for $NAME"

    # Return any already-mounted path
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

    # Remove stale dir if exists but not a mount
    if [ -d "$VOLDIR/$NAME" ] && ! mount | grep -q " on $VOLDIR/$NAME "; then
        log "Removing stale directory $VOLDIR/$NAME"
        rmdir "$VOLDIR/$NAME" 2>/dev/null
    fi

    # Try mounting up to 3 times (delays 1s,2s,4s)
    local delay=1
    for attempt in {1..3}; do
        log "Mount attempt #$attempt for $NAME"
        osascript -e "mount volume \"$URL\""
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

### MAIN ###
log "===== Movie Transfer started ====="

# 1) Mount Gigabyte and Plex
GIG_MOUNT=$(mount_volume "Gigabyte" "$GIG_URL") || {
    log "ERROR: Could not mount Gigabyte"
        notify "Could not mount Gigabyte" "Movie Transfer"
    exit 1
}
PLEX_MOUNT=$(mount_volume "Plex" "$PLEX_URL") || {
    log "ERROR: Could not mount Plex"
    notify "Could not mount Plex" "Movie Transfer"
    exit 1
}

# 2) Verify source directory exists
log "Verifying source directory: $SRC_DIR"
if [ ! -d "$SRC_DIR" ]; then
    log "ERROR: Source directory not found"
    notify "Source folder not found: $SRC_DIR" "Movie Transfer"
    exit 1
fi

# 3) Create destination directories
DEST_PATH1="$GIG_MOUNT"
DEST_PATH2="$PLEX_MOUNT"
log "Creating destination directories: $DEST_PATH1 and $DEST_PATH2"
mkdir -p "$DEST_PATH1" "$DEST_PATH2"

# 4) Check for existing movies and duplicates (quick check)
log "Checking for existing movies on both destinations"
if [ -d "$DEST_PATH1" ] && [ -d "$DEST_PATH2" ]; then
    # Quick check - just see if directories have any files (don't count all)
    gig_has_files=$(find "$DEST_PATH1" -maxdepth 1 -type f | head -1 | wc -l)
    plex_has_files=$(find "$DEST_PATH2" -maxdepth 1 -type f | head -1 | wc -l)
    
    if [ "$gig_has_files" -gt 0 ] && [ "$plex_has_files" -gt 0 ]; then
        log "INFO: Movies already exist on both destinations"
        log "Will add new files to existing movies (rsync will handle duplicates efficiently)"
        
        if [ "$DRY_RUN" = true ]; then
            log "[TEST MODE] Would add new files to existing movies"
        else
            # Automatically proceed to add new files
            log "Adding new files to existing movies"
        fi
    else
        log "INFO: No existing movies found - will perform full transfer"
    fi
else
    log "INFO: Destination directories don't exist - will perform full transfer"
fi

# 5) Remove AppleDouble files
log "Deleting AppleDouble files in target Movies directories"
find "$DEST_PATH1" -maxdepth 1 -name '._*' -delete 2>/dev/null
find "$DEST_PATH2" -maxdepth 1 -name '._*' -delete 2>/dev/null

# 6) Check available space before transfer
if [ "$DRY_RUN" = false ]; then
    check_space "$SRC_DIR" "$DEST_PATH1" "$DEST_PATH2" || {
        log "ERROR: Space check failed"
        notify "Space check failed - transfer aborted" "Movie Transfer"
        exit 1
    }
fi

        # 7) Run rsync transfers
        if [ "$DRY_RUN" = true ]; then
            notify "Starting movie transfer (DRY RUN)" "Movie Transfer"
            log "[DRY RUN] Would transfer to $DEST_PATH1"
            echo "=== DRY RUN - Gigabyte NAS (Movies) ==="
            echo "Note: rsync will skip identical files and only transfer new/changed movies"
            "$RSYNC_BIN" -a --dry-run --info=progress2 --itemize-changes --no-xattrs --exclude='.DS_Store' "${SRC_DIR}/" "$DEST_PATH1"
            R1=$?
            log "Dry run to Gigabyte Movies exit code: $R1"

            log "[DRY RUN] Would transfer to $DEST_PATH2"
            echo "=== DRY RUN - Pi5 (Plex Movies) ==="
            echo "Note: rsync will skip identical files and only transfer new/changed movies"
            "$RSYNC_BIN" -a --dry-run --info=progress2 --itemize-changes --no-xattrs --exclude='.DS_Store' "${SRC_DIR}/" "$DEST_PATH2"
            R2=$?
            log "Dry run to Plex exit code: $R2"
        else
            notify "Starting movie transfer" "Movie Transfer"
            log "[RSYNC] Transferring to Gigabyte NAS ($DEST_PATH1)"
            echo "=== TRANSFERRING TO GIGABYTE NAS (MOVIES) ==="
            echo "Note: rsync will skip identical files and only transfer new/changed movies"
            "$RSYNC_BIN" -a --info=progress2 --itemize-changes --no-xattrs --exclude='.DS_Store' "${SRC_DIR}/" "$DEST_PATH1"
            R1=$?
            log "Rsync to Gigabyte Movies exit code: $R1"

            log "[RSYNC] Transferring to Pi5 ($DEST_PATH2)"
            echo "=== TRANSFERRING TO PI5 (PLEX MOVIES) ==="
            echo "Note: rsync will skip identical files and only transfer new/changed movies"
            "$RSYNC_BIN" -a --info=progress2 --itemize-changes --no-xattrs --exclude='.DS_Store' "${SRC_DIR}/" "$DEST_PATH2"
            R2=$?
            log "Rsync to Pi5 exit code: $R2"
        fi

# 8) Report completion status
if [ $R1 -eq 0 ] && [ $R2 -eq 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        log "Dry run completed successfully"
        notify "Dry run completed successfully" "Movie Transfer"
    else
        log "Movie transfer successful; source files preserved"
        # Show final file counts (quick check)
        final_gig_files=$(find "$DEST_PATH1" -maxdepth 1 -type f | wc -l)
        final_plex_files=$(find "$DEST_PATH2" -maxdepth 1 -type f | wc -l)
        log "Final file counts (top level) - Gigabyte: $final_gig_files, Pi5: $final_plex_files"
        notify "Movie transfer complete—source files preserved." "Movie Transfer"
    fi
else
    log "ERROR: Transfer failed"
    if [ "$DRY_RUN" = true ]; then
        notify "Dry run failed" "Movie Transfer"
    else
        notify "Movie transfer failed" "Movie Transfer"
    fi
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    log "===== Dry Run completed ====="
    echo "Dry run complete. Log file: $LOG_FILE"
else
    log "===== Movie Transfer completed ====="
    echo "Transfer complete. Log file: $LOG_FILE"
fi