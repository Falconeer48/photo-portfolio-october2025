#!/bin/bash

### CONFIGURATION ###
SRC_DIR="/Volumes/M2 Drive/M2 Downloads/Movie Transfers"
RSYNC_BIN="/opt/homebrew/bin/rsync"
GIG_URL="smb://admin@192.168.50.183/Gigabyte"
PLEX_URL="smb://ian:Falcon1959@192.168.50.243/Movies"

# Log directory
LOG_DIR="/Users/ian/Scripts"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/movie_transfer_$(date +%Y%m%d_%H%M%S).log"

# Logging function
log() {
    local ts="[$(date +'%Y-%m-%d %H:%M:%S')]"
    local entry="$ts $1"
    echo "$entry" | tee -a "$LOG_FILE"
}

# Notification function
notify() {
    /usr/bin/osascript -e "display notification \"$1\" with title \"$2\""
    echo "[NOTICE] $1"
}

# mount_volume function
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
log "Checking existing mount for Gigabyte"
GIG_MOUNT=$(mount_volume "Gigabyte" "$GIG_URL") || {
    log "ERROR: Could not mount Gigabyte"
    notify "Could not mount Gigabyte" "Movie Transfer"
    osascript -e 'display dialog "❌ Error: Could not mount Gigabyte NAS. Please check connection and try again." buttons {"OK"}'
    exit 1
}

log "Checking existing mount for Plex"
PLEX_MOUNT=$(mount_volume "Plex" "$PLEX_URL") || {
    log "ERROR: Could not mount Plex"
    notify "Could not mount Plex" "Movie Transfer"
    osascript -e 'display dialog "❌ Error: Could not mount Pi5. Please check connection and try again." buttons {"OK"}'
    exit 1
}

# 2) Verify source directory exists
log "Verifying source directory: $SRC_DIR"
if [ ! -d "$SRC_DIR" ]; then
    log "ERROR: Source directory not found"
    notify "Source folder not found: $SRC_DIR" "Movie Transfer"
    osascript -e "display dialog \"❌ Error: Source folder '$SRC_DIR' does not exist.\" buttons {\"OK\"}"
    exit 1
fi

# 3) Create destination directories under 'Movies'
DEST_PATH1="$GIG_MOUNT/Movies"
DEST_PATH2="$PLEX_MOUNT/Movies"
log "Creating destination directories: $DEST_PATH1 and $DEST_PATH2"
mkdir -p "$DEST_PATH1" "$DEST_PATH2"

# Check available space
SOURCE_SIZE=$(du -sk "$SRC_DIR" | cut -f1)
log "Source directory size: ${SOURCE_SIZE}KB"
AVAIL_SPACE1=$(df -k "$DEST_PATH1" | tail -1 | awk '{print $4}')
AVAIL_SPACE2=$(df -k "$DEST_PATH2" | tail -1 | awk '{print $4}')
log "Available space - Gigabyte: ${AVAIL_SPACE1}KB, Pi5: ${AVAIL_SPACE2}KB"

if [ "$AVAIL_SPACE1" -lt "$SOURCE_SIZE" ]; then
    log "ERROR: Not enough space on Gigabyte NAS"
    osascript -e 'display dialog "❌ Error: Not enough space on Gigabyte NAS for transfer." buttons {"OK"}'
    exit 1
fi

if [ "$AVAIL_SPACE2" -lt "$SOURCE_SIZE" ]; then
    log "ERROR: Not enough space on Pi5"
    osascript -e 'display dialog "❌ Error: Not enough space on Pi5 for transfer." buttons {"OK"}'
    exit 1
fi

# 4) Remove AppleDouble files
log "Deleting AppleDouble files in target Movies directories"
find "$DEST_PATH1" -name '._*' -delete 2>/dev/null
find "$DEST_PATH2" -name '._*' -delete 2>/dev/null

# 5) Run rsync transfers
notify "Starting movie transfer" "Movie Transfer"
log "[RSYNC] Transferring to Gigabyte NAS ($DEST_PATH1)"
"$RSYNC_BIN" -a --info=progress2 --itemize-changes --no-xattrs --exclude='.DS_Store' "${SRC_DIR}/" "$DEST_PATH1"
R1=$?
log "Rsync to Gigabyte exit code: $R1"

log "[RSYNC] Transferring to Pi5 ($DEST_PATH2)"
"$RSYNC_BIN" -a --info=progress2 --itemize-changes --no-xattrs --exclude='.DS_Store' "${SRC_DIR}/" "$DEST_PATH2"
R2=$?
log "Rsync to Pi5 exit code: $R2"

# 6) Report completion status
if [ $R1 -eq 0 ] && [ $R2 -eq 0 ]; then
    log "Movie transfer successful; source files preserved"
    notify "Movie transfer complete—source files preserved." "Movie Transfer"
    osascript -e 'display dialog "✅ Movie transfer completed successfully to both destinations. Source files have been preserved on your Mac mini." buttons {"OK"}'
else
    log "ERROR: Transfer failed"
    notify "Movie transfer failed" "Movie Transfer"
    osascript -e 'display dialog "⚠️ Transfer failed for one or both destinations. Please check the log file for details." buttons {"OK"}'
    exit 1
fi

log "===== Movie Transfer completed ====="
echo "Transfer complete. Log file: $LOG_FILE"
