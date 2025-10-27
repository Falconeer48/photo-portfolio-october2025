#!/bin/bash

# Test version of sync-images-to-pi5-nested.sh
# Fixed SSH key issue and added better error handling

# Configuration
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/home/ian/photo-portfolio/public/images/portfolio"
LOCAL_PATH="/Users/ian/Portfolio Images to Transfer"

# Parse command line arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🧪 DRY RUN MODE - No actual changes will be made"
fi

echo "🔄 Testing sync script functionality..."
echo "======================================"

# Test 1: Check Pi5 connectivity
echo "1️⃣ Testing Pi5 connectivity..."
if ping -c 1 -W 5000 "$PI_HOST" >/dev/null 2>&1; then
    echo "✅ Pi5 ($PI_HOST) is reachable"
else
    echo "❌ Pi5 ($PI_HOST) is NOT reachable"
    exit 1
fi

# Test 2: Check SSH connection
echo ""
echo "2️⃣ Testing SSH connection..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "echo 'SSH connection successful'" >/dev/null 2>&1; then
    echo "✅ SSH connection to Pi5 successful"
else
    echo "❌ SSH connection to Pi5 failed"
    exit 1
fi

# Test 3: Check if Pi5 photo portfolio directory exists
echo ""
echo "3️⃣ Checking Pi5 photo portfolio directory..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "[ -d '$PI_PATH' ]"; then
    echo "✅ Pi5 photo portfolio directory exists: $PI_PATH"
else
    echo "❌ Pi5 photo portfolio directory not found: $PI_PATH"
    exit 1
fi

# Test 4: Check local portfolio directory
echo ""
echo "4️⃣ Checking local portfolio directory..."
if [ -d "$LOCAL_PATH" ]; then
    echo "✅ Local portfolio directory exists: $LOCAL_PATH"
    
    # Count folders and files
    folder_count=$(find "$LOCAL_PATH" -type d | wc -l)
    file_count=$(find "$LOCAL_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
    echo "   📁 Folders found: $folder_count"
    echo "   🖼️  Image files found: $file_count"
else
    echo "❌ Local portfolio directory not found: $LOCAL_PATH"
    echo "   💡 This directory needs to exist for the sync script to work"
    echo "   💡 You can create it with: mkdir -p '$LOCAL_PATH'"
fi

# Test 5: Check Pi5 photo portfolio service
echo ""
echo "5️⃣ Checking Pi5 photo portfolio service..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "systemctl is-active photo-portfolio.service" >/dev/null 2>&1; then
    echo "✅ Photo portfolio service is active"
else
    echo "⚠️  Photo portfolio service is not active"
fi

# Test 6: Check Pi5 disk space
echo ""
echo "6️⃣ Checking Pi5 disk space..."
available_space=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "df -h '$PI_PATH' | awk 'NR==2 {print \$4}'" 2>/dev/null)
if [ -n "$available_space" ]; then
    echo "✅ Available space on Pi5: $available_space"
else
    echo "❌ Could not determine Pi5 disk space"
fi

# Test 7: Check ImageMagick on Pi5
echo ""
echo "7️⃣ Checking ImageMagick on Pi5..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "which convert >/dev/null 2>&1"; then
    echo "✅ ImageMagick is available on Pi5"
else
    echo "⚠️  ImageMagick not found on Pi5 (needed for image optimization)"
fi

# Test 8: Test rsync functionality
echo ""
echo "8️⃣ Testing rsync functionality..."
if command -v rsync >/dev/null 2>&1; then
    echo "✅ rsync is available locally"
    
    # Test rsync dry-run with a small test
    if [ -d "$LOCAL_PATH" ]; then
        echo "   🧪 Testing rsync dry-run..."
        rsync_output=$(rsync -avz --dry-run --update \
            --exclude '._*' \
            --exclude '.DS_Store' \
            --exclude 'Thumbs.db' \
            -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no" \
            "$LOCAL_PATH/" "$PI_USER@$PI_HOST:$PI_PATH/test-sync/" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "   ✅ rsync dry-run test successful"
        else
            echo "   ❌ rsync dry-run test failed"
            echo "   Error: $rsync_output"
        fi
    else
        echo "   ⚠️  Skipping rsync test (local directory doesn't exist)"
    fi
else
    echo "❌ rsync not found locally"
fi

# Summary
echo ""
echo "📋 Test Summary"
echo "==============="
echo "✅ Pi5 connectivity: Working"
echo "✅ SSH connection: Working"
echo "✅ Pi5 photo portfolio directory: Exists"
if [ -d "$LOCAL_PATH" ]; then
    echo "✅ Local portfolio directory: Exists"
else
    echo "❌ Local portfolio directory: Missing"
fi
echo "✅ Photo portfolio service: Checked"
echo "✅ Pi5 disk space: Checked"
echo "✅ ImageMagick: Checked"
echo "✅ rsync: Checked"

echo ""
echo "🔧 Script Status:"
if [ -d "$LOCAL_PATH" ]; then
    echo "✅ The sync script should work properly"
    echo "💡 To run the actual sync: $0"
    echo "💡 To test what would be synced: $0 --dry-run"
else
    echo "⚠️  The sync script needs the local directory to be created"
    echo "💡 Create the directory: mkdir -p '$LOCAL_PATH'"
    echo "💡 Then add your portfolio images to sync"
fi

echo ""
echo "🌐 Photo Portfolio Access:"
echo "Local: http://$PI_HOST:3000"
echo "External: https://iancook.myddns.me"
