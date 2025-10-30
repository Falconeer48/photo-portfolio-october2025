#!/bin/bash

### CONFIGURATION ###
TARGET_DIR="$1"
DRY_RUN="${2:-false}"

# Patterns to remove from filenames
PATTERNS=(
    "BRrip 1080p (LiLTVision) (LiLTV)"
    "BRrip 1080p (LiLTVision)"
    "BRrip 1080p (LiLTV)"
    "BRrip 1080p"
    "BRrip"
    "1080p (LiLTVision) (LiLTV)"
    "1080p (LiLTVision)"
    "1080p (LiLTV)"
    "1080p"
    "(LiLTVision) (LiLTV)"
    "(LiLTVision)"
    "(LiLTV)"
    "Extended cut"
    "EXTENDED"
    "Extended Cut"
    "EXTENDED CUT"
)

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Clean filename function
clean_filename() {
    local filename="$1"
    local original="$filename"
    
    # Remove .mp4 extension temporarily
    local name_without_ext="${filename%.mp4}"
    local extension=".mp4"
    
    # Remove each pattern
    for pattern in "${PATTERNS[@]}"; do
        # Escape special characters for sed
        local escaped_pattern=$(echo "$pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')
        name_without_ext=$(echo "$name_without_ext" | sed "s/$escaped_pattern//g")
    done
    
    # Clean up multiple spaces and trim
    name_without_ext=$(echo "$name_without_ext" | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')
    
    # Remove leftover parentheses and their contents
    name_without_ext=$(echo "$name_without_ext" | sed 's/ *(.*)//g')
    
    # Clean up dashes and spaces around them
    name_without_ext=$(echo "$name_without_ext" | sed 's/ *- */-/g')  # Convert " - " to "-"
    name_without_ext=$(echo "$name_without_ext" | sed 's/ *- *$//')    # Remove trailing dashes
    name_without_ext=$(echo "$name_without_ext" | sed 's/^- *//')      # Remove leading dashes
    name_without_ext=$(echo "$name_without_ext" | sed 's/  */ /g')     # Clean up multiple spaces again
    
    # Remove spaces before .mp4 extension
    name_without_ext=$(echo "$name_without_ext" | sed 's/ *$//')
    
    # Reconstruct filename
    local cleaned="${name_without_ext}${extension}"
    
    echo "$cleaned"
}

# Main function
process_files() {
    local dir="$1"
    local dry_run="$2"
    
    if [ ! -d "$dir" ]; then
        log "ERROR: Directory '$dir' does not exist"
        exit 1
    fi
    
    log "Processing directory: $dir"
    log "Dry run mode: $dry_run"
    log "Patterns to remove:"
    for pattern in "${PATTERNS[@]}"; do
        log "  - '$pattern'"
    done
    log ""
    
    local count=0
    local renamed_count=0
    
    # Process all .mp4 files
    find "$dir" -name "*.mp4" -type f | while read -r file; do
        local basename=$(basename "$file")
        local dirname=$(dirname "$file")
        local cleaned=$(clean_filename "$basename")
        
        count=$((count + 1))
        
        if [ "$basename" != "$cleaned" ]; then
            local old_path="$file"
            local new_path="$dirname/$cleaned"
            
            log "File $count:"
            log "  Original: $basename"
            log "  Cleaned:  $cleaned"
            
            if [ "$dry_run" = "true" ]; then
                log "  [DRY RUN] Would rename: $old_path -> $new_path"
            else
                if mv "$old_path" "$new_path" 2>/dev/null; then
                    log "  [RENAMED] $old_path -> $new_path"
                    renamed_count=$((renamed_count + 1))
                else
                    log "  [ERROR] Failed to rename: $old_path"
                fi
            fi
            log ""
        else
            log "File $count: $basename (no changes needed)"
        fi
    done
    
    if [ "$dry_run" = "true" ]; then
        log "DRY RUN COMPLETE: Would rename $renamed_count files"
    else
        log "RENAME COMPLETE: Renamed $renamed_count files"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 <directory> [dry-run]"
    echo ""
    echo "Arguments:"
    echo "  directory  - Directory containing .mp4 files to rename"
    echo "  dry-run    - Optional: 'true' for dry run, 'false' for actual rename (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/movies                    # Rename files in directory"
    echo "  $0 /path/to/movies true               # Dry run (show what would be renamed)"
    echo "  $0 \"/Volumes/M2 Drive/Movies\"        # Rename files with spaces in path"
    echo ""
    echo "Patterns that will be removed:"
    for pattern in "${PATTERNS[@]}"; do
        echo "  - '$pattern'"
    done
    echo "  - Spaces before .mp4 extension"
}

# Main execution
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Process files
process_files "$TARGET_DIR" "$DRY_RUN"
