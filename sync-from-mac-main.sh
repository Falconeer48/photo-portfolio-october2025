#!/bin/bash

# Sync Portfolio Images from Mac Main to Pi5
# Handles different connection methods and finds portfolio images

# Configuration
MAC_MAIN_IP="192.168.50.12"
MAC_MAIN_USER="ian"
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/home/ian/photo-portfolio/public/images/portfolio"

# Parse command line arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🧪 DRY RUN MODE - No actual changes will be made"
fi

echo "🔄 Syncing Portfolio Images from Mac Main ($MAC_MAIN_IP) to Pi5..."
echo "=============================================================="

# Function to test connectivity
test_connectivity() {
    echo "🔍 Testing connectivity..."
    
    # Test Mac Main connectivity
    if ping -c 1 -W 5000 "$MAC_MAIN_IP" >/dev/null 2>&1; then
        echo "✅ Mac Main ($MAC_MAIN_IP) is reachable"
    else
        echo "❌ Mac Main ($MAC_MAIN_IP) is NOT reachable"
        return 1
    fi
    
    # Test Pi5 connectivity
    if ping -c 1 -W 5000 "$PI_HOST" >/dev/null 2>&1; then
        echo "✅ Pi5 ($PI_HOST) is reachable"
    else
        echo "❌ Pi5 ($PI_HOST) is NOT reachable"
        return 1
    fi
    
    return 0
}

# Function to find portfolio images on Mac Main via SSH
find_portfolio_images_ssh() {
    echo "🔍 Searching for portfolio images on Mac Main via SSH..."
    
    # Try to find common portfolio directories
    local search_paths=(
        "/Users/ian/Portfolio Images to Transfer"
        "/Users/ian/Desktop/Portfolio Images"
        "/Users/ian/Documents/Portfolio Images"
        "/Users/ian/Pictures/Portfolio Images"
        "/Users/ian/Pictures"
        "/Users/ian/Desktop"
        "/Users/ian/Documents"
    )
    
    for search_path in "${search_paths[@]}"; do
        echo "   🔍 Checking: $search_path"
        
        # Check if directory exists and contains images
        local result=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$MAC_MAIN_USER@$MAC_MAIN_IP" "
            if [ -d '$search_path' ]; then
                image_count=\$(find '$search_path' -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tiff' \\) | wc -l)
                if [ \$image_count -gt 0 ]; then
                    echo 'FOUND:\$image_count'
                else
                    echo 'EMPTY'
                fi
            else
                echo 'NOT_FOUND'
            fi
        " 2>/dev/null)
        
        if [[ "$result" == FOUND:* ]]; then
            local count="${result#FOUND:}"
            echo "   ✅ Found $count images in: $search_path"
            echo "$search_path" > /tmp/portfolio_path.txt
            return 0
        elif [[ "$result" == "EMPTY" ]]; then
            echo "   ⚠️  Directory exists but no images found"
        else
            echo "   ❌ Directory not found"
        fi
    done
    
    echo "❌ No portfolio images found on Mac Main"
    return 1
}

# Function to find portfolio images via SMB mount
find_portfolio_images_smb() {
    echo "🔍 Attempting to find portfolio images via SMB..."
    
    # Try to mount the Mac Main
    local mount_point="/tmp/mac_main_mount"
    mkdir -p "$mount_point"
    
    # Try different SMB connection methods
    local smb_paths=(
        "//$MAC_MAIN_USER@$MAC_MAIN_IP/$MAC_MAIN_USER"
        "//$MAC_MAIN_USER@$MAC_MAIN_IP/ian"
        "//$MAC_MAIN_USER@$MAC_MAIN_IP/Public"
    )
    
    for smb_path in "${smb_paths[@]}"; do
        echo "   🔍 Trying SMB path: $smb_path"
        
        if mount_smbfs "$smb_path" "$mount_point" 2>/dev/null; then
            echo "   ✅ Successfully mounted Mac Main"
            
            # Look for portfolio images
            local search_paths=(
                "$mount_point/Portfolio Images to Transfer"
                "$mount_point/Desktop/Portfolio Images"
                "$mount_point/Documents/Portfolio Images"
                "$mount_point/Pictures/Portfolio Images"
                "$mount_point/Pictures"
                "$mount_point/Desktop"
                "$mount_point/Documents"
            )
            
            for search_path in "${search_paths[@]}"; do
                if [ -d "$search_path" ]; then
                    local image_count=$(find "$search_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
                    if [ "$image_count" -gt 0 ]; then
                        echo "   ✅ Found $image_count images in: $search_path"
                        echo "$search_path" > /tmp/portfolio_path.txt
                        umount "$mount_point" 2>/dev/null
                        return 0
                    fi
                fi
            done
            
            umount "$mount_point" 2>/dev/null
        fi
    done
    
    echo "❌ Could not access portfolio images via SMB"
    return 1
}

# Function to sync images from Mac Main to Pi5
sync_images_to_pi5() {
    local source_path="$1"
    local method="$2"
    
    echo "📤 Syncing images from Mac Main to Pi5..."
    echo "   Source: $source_path"
    echo "   Method: $method"
    
    if [ "$method" = "ssh" ]; then
        # Sync via SSH
        echo "   🔄 Using SSH method..."
        
        if [ "$DRY_RUN" = true ]; then
            echo "   🧪 [DRY RUN] Would sync via SSH..."
            ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$MAC_MAIN_USER@$MAC_MAIN_IP" "
                find '$source_path' -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tiff' \\) | head -10
            " 2>/dev/null | while read -r file; do
                echo "      📄 $(basename "$file")"
            done
        else
            # Create a temporary sync script on Mac Main
            ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$MAC_MAIN_USER@$MAC_MAIN_IP" "
                # Find all portfolio folders
                find '$source_path' -type d | while read -r folder; do
                    if find \"\$folder\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tiff' \\) -print -quit | grep -q .; then
                        relative_path=\${folder#$source_path/}
                        echo \"Processing folder: \$relative_path\"
                        
                        # Create folder on Pi5 if it doesn't exist
                        ssh $PI_USER@$PI_HOST \"mkdir -p '$PI_PATH/\$relative_path'\"
                        
                        # Sync images to Pi5
                        rsync -avz --progress --update \\
                            --exclude '._*' \\
                            --exclude '.DS_Store' \\
                            --exclude 'Thumbs.db' \\
                            \"\$folder/\" $PI_USER@$PI_HOST:$PI_PATH/\$relative_path/
                    fi
                done
            " 2>/dev/null
        fi
        
    elif [ "$method" = "smb" ]; then
        # Sync via SMB mount
        echo "   🔄 Using SMB mount method..."
        
        local mount_point="/tmp/mac_main_mount"
        mkdir -p "$mount_point"
        
        # Mount the Mac Main
        if mount_smbfs "//$MAC_MAIN_USER@$MAC_MAIN_IP/$MAC_MAIN_USER" "$mount_point" 2>/dev/null; then
            echo "   ✅ Successfully mounted Mac Main"
            
            if [ "$DRY_RUN" = true ]; then
                echo "   🧪 [DRY RUN] Would sync from mounted volume..."
                find "$source_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | head -10 | while read -r file; do
                    echo "      📄 $(basename "$file")"
                done
            else
                # Find all portfolio folders and sync them
                find "$source_path" -type d | while read -r folder; do
                    if find "$folder" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -print -quit | grep -q .; then
                        relative_path="${folder#$source_path/}"
                        echo "   📁 Processing folder: $relative_path"
                        
                        # Create folder on Pi5 if it doesn't exist
                        ssh "$PI_USER@$PI_HOST" "mkdir -p '$PI_PATH/$relative_path'"
                        
                        # Sync images to Pi5
                        rsync -avz --progress --update \
                            --exclude '._*' \
                            --exclude '.DS_Store' \
                            --exclude 'Thumbs.db' \
                            "$folder/" "$PI_USER@$PI_HOST:$PI_PATH/$relative_path/"
                    fi
                done
            fi
            
            umount "$mount_point" 2>/dev/null
        else
            echo "   ❌ Failed to mount Mac Main"
            return 1
        fi
    fi
    
    return 0
}

# Main execution
main() {
    # Test connectivity
    if ! test_connectivity; then
        exit 1
    fi
    
    echo ""
    
    # Try to find portfolio images
    local portfolio_path=""
    local sync_method=""
    
    # Try SSH first
    if find_portfolio_images_ssh; then
        portfolio_path=$(cat /tmp/portfolio_path.txt)
        sync_method="ssh"
        echo "✅ Found portfolio images via SSH: $portfolio_path"
    elif find_portfolio_images_smb; then
        portfolio_path=$(cat /tmp/portfolio_path.txt)
        sync_method="smb"
        echo "✅ Found portfolio images via SMB: $portfolio_path"
    else
        echo "❌ Could not find portfolio images on Mac Main"
        echo ""
        echo "💡 Manual steps to find portfolio images:"
        echo "1. Open Finder"
        echo "2. Go to: Go → Connect to Server"
        echo "3. Enter: smb://$MAC_MAIN_IP"
        echo "4. Look for portfolio images in common locations:"
        echo "   - Desktop/Portfolio Images"
        echo "   - Documents/Portfolio Images"
        echo "   - Pictures/Portfolio Images"
        echo "   - Portfolio Images to Transfer"
        exit 1
    fi
    
    echo ""
    
    # Sync images to Pi5
    if sync_images_to_pi5 "$portfolio_path" "$sync_method"; then
        echo ""
        echo "✅ Portfolio images synced successfully!"
        echo "🌐 View your portfolio at: http://$PI_HOST:3000"
    else
        echo "❌ Failed to sync portfolio images"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/portfolio_path.txt
    umount /tmp/mac_main_mount 2>/dev/null
}

# Run main function
main
