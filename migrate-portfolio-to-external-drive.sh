#!/bin/bash

# Complete Photo Portfolio Migration Script
# 1. Moves images from SSD to external drive
# 2. Updates configuration to use external drive
# 3. Syncs ALL files from Mac Mini to replace corrupted ones

# Configuration
MOUNTED_VOLUME_PATH="/Volumes/ian/Portfolio Images to Transfer"
PI_USER="ian"
PI_HOST="192.168.50.243"
OLD_PORTFOLIO_PATH="/home/ian/photo-portfolio/public/images/portfolio"
NEW_PORTFOLIO_PATH="/mnt/Plex/photo-portfolio/images"
SERVICE_NAME="photo-portfolio.service"

echo "🔄 Complete Photo Portfolio Migration Script"
echo "============================================"
echo "Step 1: Move images from SSD to external drive"
echo "Step 2: Update configuration to use external drive"
echo "Step 3: Sync ALL files from Mac Mini (including corrupted ones)"
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

# Function to check prerequisites
check_prerequisites() {
    print_status $BLUE "🔍 Checking prerequisites..."
    
    # Check Mac Mini mounted volume
    if [ ! -d "$MOUNTED_VOLUME_PATH" ]; then
        print_status $RED "❌ Mac Mini volume not found: $MOUNTED_VOLUME_PATH"
        return 1
    fi
    print_status $GREEN "✅ Mac Mini volume found"
    
    # Check Pi5 connectivity
    if ! ping -c 1 -W 5000 "$PI_HOST" >/dev/null 2>&1; then
        print_status $RED "❌ Pi5 not reachable"
        return 1
    fi
    print_status $GREEN "✅ Pi5 reachable"
    
    # Check external drive is mounted
    if ! ssh "$PI_USER@$PI_HOST" "[ -d '/mnt/Plex' ]"; then
        print_status $RED "❌ External drive not mounted at /mnt/Plex"
        return 1
    fi
    print_status $GREEN "✅ External drive mounted"
    
    # Check current portfolio exists
    if ! ssh "$PI_USER@$PI_HOST" "[ -d '$OLD_PORTFOLIO_PATH' ]"; then
        print_status $RED "❌ Current portfolio directory not found"
        return 1
    fi
    print_status $GREEN "✅ Current portfolio directory found"
    
    return 0
}

# Function to stop the photo portfolio service
stop_service() {
    print_status $BLUE "🛑 Stopping photo portfolio service..."
    ssh "$PI_USER@$PI_HOST" "sudo systemctl stop $SERVICE_NAME"
    print_status $GREEN "✅ Service stopped"
}

# Function to create new directory structure on external drive
create_external_structure() {
    print_status $BLUE "📁 Creating directory structure on external drive..."
    ssh "$PI_USER@$PI_HOST" "
        sudo mkdir -p '$NEW_PORTFOLIO_PATH'
        sudo chown -R $PI_USER:$PI_USER /mnt/Plex/photo-portfolio
    "
    print_status $GREEN "✅ Directory structure created"
}

# Function to move images from SSD to external drive
move_images_to_external() {
    print_status $BLUE "📦 Moving images from SSD to external drive..."
    
    # Get current size
    local current_size=$(ssh "$PI_USER@$PI_HOST" "du -sh '$OLD_PORTFOLIO_PATH' | cut -f1")
    print_status $BLUE "📊 Current portfolio size: $current_size"
    
    # Move the directory
    ssh "$PI_USER@$PI_HOST" "mv '$OLD_PORTFOLIO_PATH' '$NEW_PORTFOLIO_PATH'"
    
    # Verify move
    if ssh "$PI_USER@$PI_HOST" "[ -d '$NEW_PORTFOLIO_PATH' ]"; then
        print_status $GREEN "✅ Images moved to external drive"
    else
        print_status $RED "❌ Failed to move images"
        return 1
    fi
    
    return 0
}

# Function to update environment configuration
update_environment() {
    print_status $BLUE "⚙️  Updating environment configuration..."
    
    # Create .env file with new path
    ssh "$PI_USER@$PI_HOST" "
        echo 'PORTFOLIO_PATH=$NEW_PORTFOLIO_PATH' > /home/ian/photo-portfolio/.env
        echo 'NODE_ENV=production' >> /home/ian/photo-portfolio/.env
    "
    
    print_status $GREEN "✅ Environment configuration updated"
}

# Function to update systemd service
update_systemd_service() {
    print_status $BLUE "🔧 Updating systemd service configuration..."
    
    # Create systemd override directory
    ssh "$PI_USER@$PI_HOST" "sudo mkdir -p /etc/systemd/system/$SERVICE_NAME.d"
    
    # Create override file
    ssh "$PI_USER@$PI_HOST" "
        sudo tee /etc/systemd/system/$SERVICE_NAME.d/override.conf > /dev/null << 'EOF'
[Service]
Environment=PORTFOLIO_PATH=$NEW_PORTFOLIO_PATH
WorkingDirectory=/home/ian/photo-portfolio
User=ian
Group=ian
EOF
    "
    
    # Reload systemd
    ssh "$PI_USER@$PI_HOST" "sudo systemctl daemon-reload"
    
    print_status $GREEN "✅ Systemd service updated"
}

# Function to sync ALL files from Mac Mini
sync_from_mac_mini() {
    print_status $BLUE "📤 Syncing ALL files from Mac Mini to external drive..."
    
    # Calculate total size
    local total_size=$(find "$MOUNTED_VOLUME_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    local total_size_mb=$((total_size / 1024 / 1024))
    
    print_status $BLUE "📊 Total size to sync: ${total_size_mb}MB"
    print_status $YELLOW "⚠️  This will overwrite ALL existing files with fresh copies from Mac Mini"
    
    # Use rsync with --delete to completely replace the directory
    if rsync -avz --progress --delete \
        --exclude '._*' \
        --exclude '.DS_Store' \
        --exclude 'Thumbs.db' \
        -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no" \
        "$MOUNTED_VOLUME_PATH/" "$PI_USER@$PI_HOST:$NEW_PORTFOLIO_PATH/"; then
        print_status $GREEN "✅ All files synced from Mac Mini successfully!"
        print_status $GREEN "✅ Corrupted files replaced with fresh copies"
    else
        print_status $RED "❌ Failed to sync files from Mac Mini"
        return 1
    fi
    
    return 0
}

# Function to optimize images
optimize_images() {
    print_status $BLUE "🔧 Optimizing images on external drive..."
    
    if ssh "$PI_USER@$PI_HOST" "cd /home/ian/photo-portfolio && PORTFOLIO_PATH='$NEW_PORTFOLIO_PATH' ./scripts/optimize-images.sh"; then
        print_status $GREEN "✅ Images optimized successfully!"
    else
        print_status $YELLOW "⚠️  Image optimization had issues, but continuing..."
    fi
}

# Function to start the service
start_service() {
    print_status $BLUE "🚀 Starting photo portfolio service..."
    ssh "$PI_USER@$PI_HOST" "sudo systemctl start $SERVICE_NAME && sleep 3"
    
    # Check if service is running
    if ssh "$PI_USER@$PI_HOST" "systemctl is-active $SERVICE_NAME" | grep -q "active"; then
        print_status $GREEN "✅ Service started successfully"
    else
        print_status $RED "❌ Service failed to start"
        return 1
    fi
    
    return 0
}

# Function to test the website
test_website() {
    print_status $BLUE "🌐 Testing website..."
    
    # Wait a moment for service to fully start
    sleep 5
    
    local HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$PI_HOST:3000)
    if [ "$HTTP_CODE" -eq 200 ]; then
        print_status $GREEN "✅ Website responding (HTTP 200)"
    else
        print_status $RED "❌ Website not responding (HTTP $HTTP_CODE)"
        return 1
    fi
    
    return 0
}

# Function to show final status
show_final_status() {
    print_status $BLUE "📊 Final Status Report"
    echo "====================="
    
    # Show disk usage
    print_status $BLUE "💾 Disk Usage:"
    ssh "$PI_USER@$PI_HOST" "df -h | grep -E '(sdb2|Plex)'"
    
    # Show portfolio size
    local portfolio_size=$(ssh "$PI_USER@$PI_HOST" "du -sh '$NEW_PORTFOLIO_PATH' | cut -f1")
    print_status $BLUE "📁 Portfolio size on external drive: $portfolio_size"
    
    # Show image count
    local image_count=$(ssh "$PI_USER@$PI_HOST" "find '$NEW_PORTFOLIO_PATH' -name '*.jpg' | wc -l")
    print_status $BLUE "🖼️  Total images: $image_count"
    
    print_status $GREEN "🎉 Migration completed successfully!"
    print_status $BLUE "🌐 Your portfolio is now running from external drive:"
    print_status $BLUE "   Local: http://$PI_HOST:3000"
    print_status $BLUE "   External: https://iancook.myddns.me"
}

# Main execution
main() {
    print_status $YELLOW "⚠️  This script will:"
    print_status $YELLOW "   1. Move all images from SSD to external drive"
    print_status $YELLOW "   2. Update configuration to use external drive"
    print_status $YELLOW "   3. Replace ALL files with fresh copies from Mac Mini"
    print_status $YELLOW "   4. Optimize images and restart service"
    echo ""
    print_status $YELLOW "Press Ctrl+C within 10 seconds to cancel..."
    
    # Countdown
    for i in 10 9 8 7 6 5 4 3 2 1; do
        echo -n "$i... "
        sleep 1
    done
    echo ""
    
    # Check prerequisites
    if ! check_prerequisites; then
        print_status $RED "❌ Prerequisites check failed"
        exit 1
    fi
    
    echo ""
    
    # Step 1: Stop service
    stop_service
    
    # Step 2: Create external structure
    create_external_structure
    
    # Step 3: Move images to external drive
    if ! move_images_to_external; then
        print_status $RED "❌ Failed to move images"
        exit 1
    fi
    
    # Step 4: Update environment
    update_environment
    
    # Step 5: Update systemd service
    update_systemd_service
    
    # Step 6: Sync ALL files from Mac Mini
    if ! sync_from_mac_mini; then
        print_status $RED "❌ Failed to sync from Mac Mini"
        exit 1
    fi
    
    # Step 7: Optimize images
    optimize_images
    
    # Step 8: Start service
    if ! start_service; then
        print_status $RED "❌ Failed to start service"
        exit 1
    fi
    
    # Step 9: Test website
    if ! test_website; then
        print_status $RED "❌ Website test failed"
        exit 1
    fi
    
    # Step 10: Show final status
    echo ""
    show_final_status
}

# Run main function
main
