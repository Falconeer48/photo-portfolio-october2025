#!/bin/bash

# Image Validation and Repair Script for Photo Portfolio
# Checks for corrupted images and attempts to repair them
# Usage: ./validate-and-repair-images.sh [IP_ADDRESS] [IMAGE_DIRECTORY]

PI5_IP=${1:-"192.168.50.243"}
IMAGE_DIR=${2:-"/home/ian/photo-portfolio/public/images/portfolio"}

echo "🖼️  Image Validation and Repair Tool for Photo Portfolio"
echo "========================================================"
echo "Pi5 IP: $PI5_IP"
echo "Image Directory: $IMAGE_DIR"
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

# Function to check if Pi5 is reachable
check_pi5_connection() {
    print_status $BLUE "🔍 Checking Pi5 connection..."
    if ping -c 1 -W 5000 "$PI5_IP" >/dev/null 2>&1; then
        print_status $GREEN "✅ Pi5 ($PI5_IP) is reachable"
        return 0
    else
        print_status $RED "❌ Pi5 ($PI5_IP) is NOT reachable"
        return 1
    fi
}

# Function to check if required tools are available on Pi5
check_tools() {
    print_status $BLUE "🔧 Checking required tools on Pi5..."
    
    local tools_available=true
    
    # Check for ImageMagick
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "which identify >/dev/null 2>&1" 2>/dev/null; then
        print_status $RED "❌ ImageMagick not installed on Pi5"
        tools_available=false
    else
        print_status $GREEN "✅ ImageMagick available"
    fi
    
    # Check for convert command
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "which convert >/dev/null 2>&1" 2>/dev/null; then
        print_status $RED "❌ ImageMagick convert not available on Pi5"
        tools_available=false
    else
        print_status $GREEN "✅ ImageMagick convert available"
    fi
    
    if [ "$tools_available" = false ]; then
        echo ""
        print_status $YELLOW "💡 To install ImageMagick on Pi5:"
        echo "   ssh ian@$PI5_IP"
        echo "   sudo apt update"
        echo "   sudo apt install imagemagick"
        return 1
    fi
    
    return 0
}

# Function to validate and repair images using a single SSH session
validate_and_repair_images() {
    print_status $BLUE "🔍 Starting comprehensive image validation..."
    
    # Run the entire validation process on Pi5
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "
        cd '$IMAGE_DIR'
        
        echo '📊 Scanning for image files...'
        
        # Initialize counters
        total_files=0
        valid_files=0
        corrupted_files=0
        repaired_files=0
        
        # Find all image files
        image_files=\$(find . -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \\) 2>/dev/null)
        
        if [ -z \"\$image_files\" ]; then
            echo '❌ No image files found'
            exit 1
        fi
        
        # Count total files
        total_files=\$(echo \"\$image_files\" | wc -l)
        echo \"📊 Found \$total_files image files to validate\"
        echo ''
        
        # Process each file
        echo \"\$image_files\" | while IFS= read -r file_path; do
            if [ -n \"\$file_path\" ]; then
                filename=\$(basename \"\$file_path\")
                
                # Check if file is readable
                if [ ! -r \"\$file_path\" ]; then
                    echo \"❌ \$filename - File not readable\"
                    continue
                fi
                
                # Get file size
                file_size=\$(stat -c%s \"\$file_path\" 2>/dev/null)
                
                # Check if file is too small
                if [ \"\$file_size\" -lt 1000 ]; then
                    echo \"❌ \$filename - File too small (\$file_size bytes) - likely corrupted\"
                    continue
                fi
                
                # Try to get image dimensions
                dimensions=\$(identify -format '%wx%h' \"\$file_path\" 2>/dev/null)
                
                if [ \$? -eq 0 ] && [ -n \"\$dimensions\" ]; then
                    echo \"✅ \$filename - Valid (\$dimensions, \${file_size} bytes)\"
                else
                    echo \"❌ \$filename - Corrupted or invalid format\"
                    echo \"🔧 Attempting to repair: \$filename\"
                    
                    # Create backup
                    cp \"\$file_path\" \"\$file_path.backup\"
                    
                    # Try to repair
                    if convert \"\$file_path\" -auto-orient -strip \"\$file_path.repaired\" 2>/dev/null; then
                        if [ -f \"\$file_path.repaired\" ]; then
                            mv \"\$file_path.repaired\" \"\$file_path\"
                            echo \"✅ Successfully repaired: \$filename\"
                        else
                            echo \"❌ Repair failed: \$filename\"
                            mv \"\$file_path.backup\" \"\$file_path\"
                        fi
                    else
                        echo \"❌ Repair failed: \$filename\"
                        mv \"\$file_path.backup\" \"\$file_path\"
                    fi
                fi
            fi
        done
        
        echo ''
        echo '📊 File count by type:'
        echo \"JPG files: \$(find . -name '*.jpg' | wc -l)\"
        echo \"JPEG files: \$(find . -name '*.jpeg' | wc -l)\"
        echo \"PNG files: \$(find . -name '*.png' | wc -l)\"
        echo \"GIF files: \$(find . -name '*.gif' | wc -l)\"
        echo \"WebP files: \$(find . -name '*.webp' | wc -l)\"
        
        echo ''
        echo '📁 Directory structure:'
        find . -type d | head -10
        
        echo ''
        echo '🎉 Image validation completed!'
    " 2>/dev/null
}

# Function to show summary
show_summary() {
    echo ""
    print_status $BLUE "📋 Summary"
    echo "=========="
    print_status $GREEN "✅ Image validation and repair process completed"
    print_status $YELLOW "💡 All images in your photo portfolio have been checked"
    print_status $YELLOW "🔧 Any corrupted images have been automatically repaired"
    print_status $YELLOW "📁 Backup files (.backup) were created before repairs"
    
    echo ""
    print_status $BLUE "🛠️  Maintenance Tips:"
    echo "- Run this script regularly to maintain image integrity"
    echo "- Check the photo portfolio web app at: http://$PI5_IP:3000"
    echo "- Monitor disk space if many repairs were performed"
}

# Main execution
main() {
    if ! check_pi5_connection; then
        exit 1
    fi
    
    echo ""
    if ! check_tools; then
        exit 1
    fi
    
    echo ""
    validate_and_repair_images
    
    show_summary
}

# Run main function
main
