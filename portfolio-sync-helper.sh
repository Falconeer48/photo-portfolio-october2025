#!/bin/bash

# Manual Portfolio Image Sync Helper
# Helps you locate and sync portfolio images from Mac Main to Pi5

MAC_MAIN_IP="192.168.50.12"
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/home/ian/photo-portfolio/public/images/portfolio"

echo "🖼️  Portfolio Image Sync Helper"
echo "==============================="
echo "Mac Main: $MAC_MAIN_IP"
echo "Pi5: $PI_HOST"
echo ""

# Test connectivity
echo "🔍 Testing connectivity..."
if ping -c 1 -W 5000 "$MAC_MAIN_IP" >/dev/null 2>&1; then
    echo "✅ Mac Main ($MAC_MAIN_IP) is reachable"
else
    echo "❌ Mac Main ($MAC_MAIN_IP) is NOT reachable"
    exit 1
fi

if ping -c 1 -W 5000 "$PI_HOST" >/dev/null 2>&1; then
    echo "✅ Pi5 ($PI_HOST) is reachable"
else
    echo "❌ Pi5 ($PI_HOST) is NOT reachable"
    exit 1
fi

echo ""
echo "📋 Manual Steps to Sync Portfolio Images:"
echo "========================================="
echo ""
echo "1️⃣  Connect to Mac Main:"
echo "   • Open Finder"
echo "   • Press Cmd+K (or Go → Connect to Server)"
echo "   • Enter: smb://$MAC_MAIN_IP"
echo "   • Enter your Mac Main username and password"
echo ""
echo "2️⃣  Find Portfolio Images:"
echo "   • Look for folders containing images in these locations:"
echo "     - Desktop/Portfolio Images"
echo "     - Documents/Portfolio Images"
echo "     - Pictures/Portfolio Images"
echo "     - Portfolio Images to Transfer"
echo "     - Any other folder with your photos"
echo ""
echo "3️⃣  Copy Images to Local Directory:"
echo "   • Create local directory: mkdir -p '/Users/ian/Portfolio Images to Transfer'"
echo "   • Copy the portfolio folders from Mac Main to this local directory"
echo ""
echo "4️⃣  Run the Sync Script:"
echo "   • Test: ./sync-images-to-pi5-fixed.sh --dry-run"
echo "   • Sync: ./sync-images-to-pi5-fixed.sh"
echo ""

# Check if local directory exists
if [ -d "/Users/ian/Portfolio Images to Transfer" ]; then
    echo "✅ Local portfolio directory exists: /Users/ian/Portfolio Images to Transfer"
    
    # Count images
    image_count=$(find "/Users/ian/Portfolio Images to Transfer" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
    folder_count=$(find "/Users/ian/Portfolio Images to Transfer" -type d | wc -l)
    
    echo "   📁 Folders: $folder_count"
    echo "   🖼️  Images: $image_count"
    
    if [ "$image_count" -gt 0 ]; then
        echo ""
        echo "🎉 Ready to sync! Run:"
        echo "   ./sync-images-to-pi5-fixed.sh --dry-run  # Test first"
        echo "   ./sync-images-to-pi5-fixed.sh            # Actual sync"
    else
        echo "   ⚠️  No images found - copy images from Mac Main first"
    fi
else
    echo "❌ Local portfolio directory not found"
    echo "   Create it with: mkdir -p '/Users/ian/Portfolio Images to Transfer'"
fi

echo ""
echo "🌐 Your Photo Portfolio:"
echo "   Local: http://$PI_HOST:3000"
echo "   External: https://iancook.myddns.me"
echo ""
echo "💡 Alternative: Use the Finder connection method above to directly"
echo "   copy images from Mac Main to your local machine, then sync to Pi5."
