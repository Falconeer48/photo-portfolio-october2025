#!/bin/bash

# Configuration
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/mnt/Plex/photo-portfolio/images"
SSH_KEY="~/.ssh/id_ed25519"
LOCAL_PATH="/Users/ian/Portfolio Images to Transfer"

# Parse command line arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🧪 DRY RUN MODE - No actual changes will be made"
fi

echo "🔄 Syncing images from 'Portfolio Images to Transfer' to Pi5 (with nested folder support)..."

# Check if local portfolio directory exists
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Portfolio transfer directory not found: $LOCAL_PATH"
    echo "Please ensure you have images in the 'Portfolio Images to Transfer' folder"
    exit 1
fi

# No folder mapping needed - use folder names as-is

# Function to check available space on Pi5
check_pi5_space() {
    local required_bytes="$1"
    local buffer_percent=10
    # Get available space on remote filesystem containing PI_PATH (in KB)
    local available_kb
    available_kb=$(ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "df -Pk \"$PI_PATH\" | awk 'NR==2 {print \$4}'") || return 1
    # Convert to bytes
    local available_bytes=$((available_kb * 1024))
    # Add buffer to required
    local buffer_bytes=$((required_bytes * buffer_percent / 100))
    local total_required_bytes=$((required_bytes + buffer_bytes))
    # Compare
    if (( available_bytes >= total_required_bytes )); then
        return 0
    else
        local available_mb=$((available_bytes / 1024 / 1024))
        local total_required_mb=$((total_required_bytes / 1024 / 1024))
        echo "❌ Not enough space on Pi5. Available: ${available_mb}MB, Required (with ${buffer_percent}% buffer): ${total_required_mb}MB"
        return 1
    fi
}

# Function to calculate total size of images to be synced
calculate_sync_size() {
    local total_size=0
    
    for folder_path in "${portfolio_folders[@]}"; do
        # Calculate size of image files in this folder
        local folder_size=$(find "$folder_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
        total_size=$((total_size + folder_size))
    done
    
    echo "$total_size"
}

# Function to find all portfolio folders (including nested ones)
find_portfolio_folders() {
    local base_path="$1"
    local folders=()
    
    # Find all directories that contain image files
    while IFS= read -r -d '' folder_path; do
        # Check if this folder contains any image files
        if find "$folder_path" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -print -quit | grep -q .; then
            folders+=("$folder_path")
        fi
    done < <(find "$base_path" -type d -print0)
    
    # Return the array by printing each element on a new line
    for folder in "${folders[@]}"; do
        echo "$folder"
    done
}

# Show what folders exist locally (including nested ones)
echo "📁 Local portfolio folders found:"
# Use a temporary array to store results
portfolio_folders=()
while IFS= read -r folder; do
    portfolio_folders+=("$folder")
done < <(find_portfolio_folders "$LOCAL_PATH")

for folder in "${portfolio_folders[@]}"; do
    relative_path="${folder#$LOCAL_PATH/}"
    echo "   📂 $relative_path"
done

# Show what folders exist on Pi5
echo "📁 Pi5 folders found:"
ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "find $PI_PATH -type d -mindepth 1 | sed \"s|$PI_PATH/||\" | sort"

# Calculate total size of images to be synced
echo "📏 Calculating total size of images to sync..."
total_sync_size=$(calculate_sync_size)
total_sync_size_mb=$((total_sync_size / 1024 / 1024))
echo "   📊 Total size to sync: ${total_sync_size_mb}MB"

# Check if there's enough space on Pi5 (only if not dry run and size > 0)
if [ "$DRY_RUN" = false ] && [ "$total_sync_size" -gt 0 ]; then
    if ! check_pi5_space "$total_sync_size"; then
        echo "❌ Aborting sync due to insufficient space on Pi5"
        exit 1
    fi
elif [ "$DRY_RUN" = true ] && [ "$total_sync_size" -gt 0 ]; then
    echo "🧪 [DRY RUN] Would check Pi5 space (${total_sync_size_mb}MB required)"
fi

echo "📤 Syncing images to Pi5..."
echo "🔄 Checking for missing folders and creating them..."

# Process each portfolio folder
sync_success=true
synced_folders=()  # Track which folders were actually synced
for folder_path in "${portfolio_folders[@]}"; do
    # Get the relative path from the base directory
    relative_path="${folder_path#$LOCAL_PATH/}"
    
    # Use the relative path as the Pi5 folder name (works for both top-level and nested)
    pi5_folder="$relative_path"
    
    echo "📁 Processing: '$relative_path' → '$pi5_folder'"
    
    # Check if folder exists on Pi5, create if it doesn't
    if ! ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "[ -d '$PI_PATH/$pi5_folder' ]"; then
        if [ "$DRY_RUN" = true ]; then
            echo "   🧪 [DRY RUN] Would create missing folder: $pi5_folder"
        else
            echo "   ➕ Creating missing folder: $pi5_folder"
            ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "mkdir -p '$PI_PATH/$pi5_folder'"
        fi
    else
        echo "   ✅ Folder exists: $pi5_folder"
    fi
    
    # Sync this specific folder (including subfolders)
    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY RUN] Would sync folder: $relative_path"
        
        # Count total files locally
        local_file_count=$(find "$folder_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
        
        # Check what files would actually be synced (new or different files)
        echo "   🧪 [DRY RUN] Checking what files need syncing..."
        
        # Use rsync --dry-run to see what would actually be transferred
        # Only sync files that are newer on Mac or don't exist on Pi5
        rsync_output=$(rsync -avz --dry-run --update \
            --exclude '._*' \
            --exclude '.DS_Store' \
            --exclude 'Thumbs.db' \
            -e "ssh -i $SSH_KEY" \
            "$folder_path/" "$PI_USER@$PI_HOST:$PI_PATH/$pi5_folder/" 2>/dev/null)
        
        # Extract files that would actually be transferred (look for file names, not summary lines)
        files_to_sync=$(echo "$rsync_output" | grep -E "^\S+.*\.(jpg|jpeg|png|gif|bmp|tiff)$")
        actual_sync_count=$(echo "$files_to_sync" | wc -l)
        
        if [ "$actual_sync_count" -gt 0 ]; then
            echo "   🧪 [DRY RUN] Would sync $actual_sync_count files (out of $local_file_count total local files)"
            echo "   💡 Note: Files may need syncing due to size, timestamp, or permission differences"
            # Show each file that would be synced (limit to first 10 to avoid clutter)
            echo "$files_to_sync" | head -10 | while read -r file; do
                # Extract just the filename from the full path
                filename=$(basename "$file")
                echo "      📄 $filename"
            done
            if [ "$actual_sync_count" -gt 10 ]; then
                remaining=$((actual_sync_count - 10))
                echo "      ... and $remaining more files"
            fi
        else
            echo "   🧪 [DRY RUN] No files need syncing (all $local_file_count local files already exist on Pi5)"
        fi
        
        sync_success=true
    else
        echo "   📤 Syncing folder: $relative_path"
        if rsync -avz --progress --update \
            --exclude '._*' \
            --exclude '.DS_Store' \
            --exclude 'Thumbs.db' \
            -e "ssh -i $SSH_KEY" \
            "$folder_path/" "$PI_USER@$PI_HOST:$PI_PATH/$pi5_folder/"; then
            echo "   ✅ Successfully synced: $relative_path"
            # Track this folder for optimization
            synced_folders+=("$pi5_folder")
            
            # Ensure Cover.jpg exists in the folder
            echo "   🖼️  Ensuring Cover.jpg exists..."
            
            # Check if Cover.jpg already exists on Pi5
            if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "[ -f '$PI_PATH/$pi5_folder/Cover.jpg' ]"; then
                echo "   ✅ Cover.jpg already exists"
            else
                # Find the first image file in the folder
                first_image=$(ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "find '$PI_PATH/$pi5_folder' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | head -1")
                
                if [ -n "$first_image" ]; then
                    # Rename the first image to Cover.jpg
                    echo "   📝 Renaming first image to Cover.jpg"
                    ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "mv '$first_image' '$PI_PATH/$pi5_folder/Cover.jpg'"
                else
                    # Create a generic cover image if no images exist
                    echo "   🎨 Creating generic cover image"
                    # Try ImageMagick first, fallback to copying a placeholder
                    ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "
                        if command -v convert >/dev/null 2>&1; then
                            convert -size 800x600 xc:lightgray -pointsize 48 -fill black -gravity center -annotate +0+0 '$pi5_folder' '$PI_PATH/$pi5_folder/Cover.jpg'
                            echo '   ✅ Created cover with ImageMagick'
                        else
                            # Create a simple placeholder file
                            echo 'Generic Cover Image for $pi5_folder' > '$PI_PATH/$pi5_folder/Cover.jpg'
                            echo '   ⚠️  Created text placeholder (ImageMagick not available)'
                        fi
                    "
                fi
            fi
        else
            echo "   ❌ Failed to sync: $relative_path"
            sync_success=false
        fi
    fi
done

if [ "$sync_success" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "🧪 [DRY RUN] Would sync images successfully!"
        echo "🧪 [DRY RUN] Would optimize images on Pi5..."
        echo "🧪 [DRY RUN] Would restart photo portfolio service..."
        echo "🧪 [DRY RUN] Would test website response..."
        echo "🧪 [DRY RUN] Dry run completed - no actual changes made"
        echo "💡 To run for real, execute: $0"
    else
        echo "✅ Images synced successfully!"
        
        # Optimize images on Pi5 - only recently synced folders
        echo "🔧 Optimizing images on Pi5..."
        
        if [ ${#synced_folders[@]} -gt 0 ]; then
            echo "📊 Creating web-optimized versions for recently synced folders only..."
            echo "📁 Folders to optimize: ${synced_folders[*]}"
            
            # Build SSH command with folder parameters
            # Escape folder names properly for SSH
optimize_folders_args=""
            for folder in "${synced_folders[@]}"; do
                # Escape single quotes in folder names and wrap in quotes
                escaped_folder=$(echo "$folder" | sed "s/'/'\\\\''/g")
                optimize_folders_args="$optimize_folders_args '$escaped_folder'"
            done
            
            # Run optimization for only the synced folders
            ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "cd /home/ian/photo-portfolio && bash scripts/optimize-images.sh$optimize_folders_args" 2>&1 | \
            grep -E "(Optimizing only|Processing folder|Found|Images optimized|Images skipped|Optimization Summary|Optimization Complete)" || true
        else
            echo "⚠️  No folders were synced, skipping optimization"
        fi
        
        # ALWAYS perform a full restart to ensure new folders/images are detected
        echo "🔄 Performing FULL photo portfolio server restart..."
        echo "   (This ensures all new folders and images are properly loaded and visible)"
        
        # Comprehensive restart: kill all related processes
        echo "   📴 Stopping server completely..."
        ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "sudo pkill -f 'node server.js'" 2>/dev/null || true
        ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "sudo pkill -f 'node.*photo-portfolio'" 2>/dev/null || true
        sleep 4
        
        # Force kill if still running
        ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "pgrep -f 'node server.js' > /dev/null && sudo pkill -9 -f 'node server.js'" 2>/dev/null || true
        sleep 2
        
        # Verify it's fully stopped
        if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "pgrep -f 'node server.js' > /dev/null 2>&1"; then
            echo "   ⚠️  Warning: Server process still running, forcing kill..."
            ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "sudo pkill -9 -f 'node server.js'"
            sleep 2
        else
            echo "   ✅ Server fully stopped"
        fi
        
        # Start the server completely fresh
        echo "   🚀 Starting server fresh with all new configurations..."
        ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "cd /home/ian/photo-portfolio && sudo NODE_ENV=production nohup node server.js > server.log 2>&1 &"
        
        # Wait for server to fully start
        echo "   ⏳ Waiting for server to start and initialize..."
        sleep 6
        
        # Verify server is running and responding
        MAX_ATTEMPTS=15
        ATTEMPT=1
        SERVER_RUNNING=false
        
        while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
            if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "pgrep -f 'node server.js' > /dev/null"; then
                # Check if server is responding
                if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "curl -s http://localhost:3000/api/categories > /dev/null 2>&1"; then
                    SERVER_RUNNING=true
                    echo "   ✅ Server is running and responding (attempt $ATTEMPT/$MAX_ATTEMPTS)"
                    break
                else
                    echo "   ⏳ Server process running but not responding yet (attempt $ATTEMPT/$MAX_ATTEMPTS)..."
                fi
            else
                echo "   ⏳ Waiting for server process to start (attempt $ATTEMPT/$MAX_ATTEMPTS)..."
            fi
            sleep 2
            ((ATTEMPT++))
        done
        
        if [ "$SERVER_RUNNING" = false ]; then
            echo "   ❌ Server failed to start or respond - check logs:"
            echo "   ssh $PI_USER@$PI_HOST 'tail -30 /home/ian/photo-portfolio/server.log'"
        fi
        
        # Verify the website is responding
        echo "🌐 Testing website..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://iancook.myddns.me)
        if [ "$HTTP_CODE" -eq 200 ]; then
            echo "✅ Website responding (HTTP 200)"
        else
            echo "❌ Website not responding (HTTP $HTTP_CODE)"
        fi
        
        echo "🎉 Image sync and optimization completed!"
        echo "📱 Test on your iPhone: https://iancook.myddns.me"
    fi
else
    echo "❌ Image sync failed!"
    exit 1
fi