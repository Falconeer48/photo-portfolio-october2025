#!/bin/bash

# Force Sync Portfolio Images from Mac Mini to Pi5
# This script will overwrite ALL files, including corrupted ones
# Usage: ./force-sync-from-mac-mini.sh [--dry-run]

# Configuration
MOUNTED_VOLUME_PATH="/Volumes/ian/Portfolio Images to Transfer"
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/home/ian/photo-portfolio/public/images/portfolio"

# Parse command line arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🧪 DRY RUN MODE - No actual changes will be made"
fi

echo "🔄 FORCE SYNC: Portfolio Images from Mac Mini to Pi5"
echo "===================================================="
echo "Source: $MOUNTED_VOLUME_PATH"
echo "Target: $PI_USER@$PI_HOST:$PI_PATH"
echo "Mode: $(if [ "$DRY_RUN" = true ]; then echo "DRY RUN (preview only)"; else echo "FORCE OVERWRITE ALL FILES"; fi)"
echo ""

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

# Function to check if mounted volume exists and contains images
check_mounted_volume() {
    print_status $BLUE "🔍 Checking mounted volume..."
    
    if [ ! -d "$MOUNTED_VOLUME_PATH" ]; then
        print_status $RED "❌ Mounted volume not found: $MOUNTED_VOLUME_PATH"
        print_status $YELLOW "💡 Make sure the Mac Mini is mounted at /Volumes/ian"
        return 1
    fi
    
    print_status $GREEN "✅ Mounted volume found: $MOUNTED_VOLUME_PATH"
    
    # Count images
    local image_count=$(find "$MOUNTED_VOLUME_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
    local folder_count=$(find "$MOUNTED_VOLUME_PATH" -type d | wc -l)
    
    print_status $BLUE "📊 Volume contents:"
    echo "   📁 Folders: $folder_count"
    echo "   🖼️  Images: $image_count"
    
    if [ "$image_count" -eq 0 ]; then
        print_status $RED "❌ No images found in mounted volume"
        return 1
    fi
    
    return 0
}

# Function to check Pi5 connectivity
check_pi5_connectivity() {
    print_status $BLUE "🔍 Checking Pi5 connectivity..."
    
    if ping -c 1 -W 5000 "$PI_HOST" >/dev/null 2>&1; then
        print_status $GREEN "✅ Pi5 ($PI_HOST) is reachable"
    else
        print_status $RED "❌ Pi5 ($PI_HOST) is NOT reachable"
        return 1
    fi
    
    # Test SSH connection
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        print_status $GREEN "✅ SSH connection to Pi5 successful"
    else
        print_status $RED "❌ SSH connection to Pi5 failed"
        return 1
    fi
    
    # Check if Pi5 photo portfolio directory exists
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "[ -d '$PI_PATH' ]"; then
        print_status $GREEN "✅ Pi5 photo portfolio directory exists: $PI_PATH"
    else
        print_status $RED "❌ Pi5 photo portfolio directory not found: $PI_PATH"
        return 1
    fi
    
    return 0
}

# Function to calculate total size of images to be synced
calculate_sync_size() {
    local total_size=0
    
    # Calculate size of all image files in the mounted volume
    total_size=$(find "$MOUNTED_VOLUME_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    
    echo "$total_size"
}

# Function to check available space on Pi5
check_pi5_space() {
    local required_bytes="$1"
    local buffer_percent=10
    
    # Get available space on remote filesystem containing PI_PATH (in KB)
    local available_kb
    available_kb=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "df -Pk \"$PI_PATH\" | awk 'NR==2 {print \$4}'") || return 1
    
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
        print_status $RED "❌ Not enough space on Pi5. Available: ${available_mb}MB, Required (with ${buffer_percent}% buffer): ${total_required_mb}MB"
        return 1
    fi
}

# Function to force sync all images (overwrite everything)
force_sync_images() {
    print_status $BLUE "📤 Starting FORCE SYNC (will overwrite all files)..."
    
    # Calculate total size
    print_status $BLUE "📏 Calculating total size..."
    local total_sync_size=$(calculate_sync_size)
    local total_sync_size_mb=$((total_sync_size / 1024 / 1024))
    print_status $BLUE "📊 Total size to sync: ${total_sync_size_mb}MB"
    
    # Check space on Pi5 (only if not dry run and size > 0)
    if [ "$DRY_RUN" = false ] && [ "$total_sync_size" -gt 0 ]; then
        if ! check_pi5_space "$total_sync_size"; then
            print_status $RED "❌ Aborting sync due to insufficient space on Pi5"
            exit 1
        fi
    elif [ "$DRY_RUN" = true ] && [ "$total_sync_size" -gt 0 ]; then
        print_status $YELLOW "🧪 [DRY RUN] Would check Pi5 space (${total_sync_size_mb}MB required)"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status $YELLOW "🧪 [DRY RUN] Would perform force sync..."
        print_status $YELLOW "🧪 [DRY RUN] This would overwrite ALL existing files on Pi5"
        
        # Show what would be synced
        print_status $BLUE "📁 Folders that would be synced:"
        find "$MOUNTED_VOLUME_PATH" -type d | while read -r folder; do
            if find "$folder" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -print -quit | grep -q .; then
                relative_path="${folder#$MOUNTED_VOLUME_PATH/}"
                echo "   📁 $relative_path"
            fi
        done
        
        print_status $YELLOW "🧪 [DRY RUN] To run the actual force sync, execute: $0"
        return 0
    else
        print_status $RED "⚠️  WARNING: This will OVERWRITE ALL existing files on Pi5!"
        print_status $YELLOW "Press Ctrl+C within 10 seconds to cancel..."
        
        # Countdown
        for i in 10 9 8 7 6 5 4 3 2 1; do
            echo -n "$i... "
            sleep 1
        done
        echo ""
        
        print_status $BLUE "🚀 Starting force sync..."
        
        # Use rsync with --delete to completely replace the directory
        if rsync -avz --progress --delete \
            --exclude '._*' \
            --exclude '.DS_Store' \
            --exclude 'Thumbs.db' \
            -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no" \
            "$MOUNTED_VOLUME_PATH/" "$PI_USER@$PI_HOST:$PI_PATH/"; then
            print_status $GREEN "✅ Force sync completed successfully!"
            print_status $GREEN "✅ All files have been overwritten with fresh copies from Mac Mini"
            return 0
        else
            print_status $RED "❌ Force sync failed!"
            return 1
        fi
    fi
}

# Function to optimize images on Pi5
optimize_images() {
    print_status $BLUE "🔧 Optimizing images on Pi5..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status $YELLOW "🧪 [DRY RUN] Would optimize images on Pi5..."
    else
        if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "cd /home/ian/photo-portfolio && ./scripts/optimize-images.sh"; then
            print_status $GREEN "✅ Images optimized successfully!"
        else
            print_status $YELLOW "⚠️  Image optimization had issues, but continuing..."
        fi
    fi
}

# Function to restart photo portfolio service
restart_service() {
    print_status $BLUE "🔄 Restarting photo portfolio service..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status $YELLOW "🧪 [DRY RUN] Would restart photo portfolio service..."
    else
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "sudo systemctl restart photo-portfolio.service && sleep 3"
        print_status $GREEN "✅ Photo portfolio service restarted"
    fi
}

# Function to test website
test_website() {
    print_status $BLUE "🌐 Testing website..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status $YELLOW "🧪 [DRY RUN] Would test website response..."
    else
        local HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://iancook.myddns.me)
        if [ "$HTTP_CODE" -eq 200 ]; then
            print_status $GREEN "✅ Website responding (HTTP 200)"
        else
            print_status $RED "❌ Website not responding (HTTP $HTTP_CODE)"
        fi
    fi
}

# Main execution
main() {
    # Check mounted volume
    if ! check_mounted_volume; then
        exit 1
    fi
    
    echo ""
    
    # Check Pi5 connectivity
    if ! check_pi5_connectivity; then
        exit 1
    fi
    
    echo ""
    
    # Force sync images
    if force_sync_images; then
        echo ""
        
        # Optimize images
        optimize_images
        
        echo ""
        
        # Restart service
        restart_service
        
        echo ""
        
        # Test website
        test_website
        
        echo ""
        
        if [ "$DRY_RUN" = true ]; then
            print_status $YELLOW "🧪 [DRY RUN] Dry run completed - no actual changes made"
            print_status $BLUE "💡 To run the actual force sync, execute: $0"
        else
            print_status $GREEN "🎉 FORCE SYNC completed successfully!"
            print_status $GREEN "✅ All corrupted files have been replaced with fresh copies"
            print_status $BLUE "🌐 View your portfolio at:"
            print_status $BLUE "   Local: http://$PI_HOST:3000"
            print_status $BLUE "   External: https://iancook.myddns.me"
        fi
    else
        print_status $RED "❌ Force sync failed!"
        exit 1
    fi
}

# Run main function
main
