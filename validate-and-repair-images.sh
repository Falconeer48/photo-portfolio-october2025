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

# Function to validate a single image file
validate_image() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # Check if file exists and is readable
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "test -r '$file_path'" 2>/dev/null; then
        echo "❌ $filename - File not readable"
        return 1
    fi
    
    # Get file size
    local file_size=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "stat -c%s '$file_path'" 2>/dev/null)
    
    # Check if file is too small (likely corrupted)
    if [ "$file_size" -lt 1000 ]; then
        echo "❌ $filename - File too small ($file_size bytes) - likely corrupted"
        return 1
    fi
    
    # Try to get image dimensions using ImageMagick identify
    local dimensions=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "identify -format '%wx%h' '$file_path' 2>/dev/null")
    
    if [ $? -eq 0 ] && [ -n "$dimensions" ]; then
        echo "✅ $filename - Valid ($dimensions, ${file_size} bytes)"
        return 0
    else
        echo "❌ $filename - Corrupted or invalid format"
        return 1
    fi
}

# Function to repair a corrupted image
repair_image() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    local backup_path="${file_path}.backup"
    
    print_status $YELLOW "🔧 Attempting to repair: $filename"
    
    # Create backup first
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "cp '$file_path' '$backup_path'" 2>/dev/null
    
    # Try to repair using ImageMagick convert
    local repair_result=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "
        convert '$file_path' -auto-orient -strip '$file_path.repaired' 2>&1
        if [ \$? -eq 0 ] && [ -f '$file_path.repaired' ]; then
            mv '$file_path.repaired' '$file_path'
            echo 'SUCCESS'
        else
            echo 'FAILED'
        fi
    " 2>/dev/null)
    
    if [ "$repair_result" = "SUCCESS" ]; then
        print_status $GREEN "✅ Successfully repaired: $filename"
        return 0
    else
        print_status $RED "❌ Failed to repair: $filename"
        # Restore backup
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "mv '$backup_path' '$file_path'" 2>/dev/null
        return 1
    fi
}

# Function to scan and validate all images
scan_images() {
    print_status $BLUE "🔍 Scanning for image files..."
    
    # Get list of all image files
    local image_files=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ian@"$PI5_IP" "
        find '$IMAGE_DIR' -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) 2>/dev/null
    " 2>/dev/null)
    
    if [ -z "$image_files" ]; then
        print_status $RED "❌ No image files found in $IMAGE_DIR"
        return 1
    fi
    
    local total_files=$(echo "$image_files" | wc -l)
    local corrupted_files=()
    local valid_files=0
    
    print_status $BLUE "📊 Found $total_files image files to validate"
    echo ""
    
    # Validate each file
    echo "$image_files" | while IFS= read -r file_path; do
        if [ -n "$file_path" ]; then
            if validate_image "$file_path"; then
                ((valid_files++))
            else
                corrupted_files+=("$file_path")
            fi
        fi
    done
    
    echo ""
    print_status $BLUE "📊 Validation Summary:"
    echo "Total files: $total_files"
    echo "Valid files: $valid_files"
    echo "Corrupted files: ${#corrupted_files[@]}"
    
    if [ ${#corrupted_files[@]} -gt 0 ]; then
        echo ""
        print_status $YELLOW "🔧 Corrupted files found:"
        for file in "${corrupted_files[@]}"; do
            echo "  - $(basename "$file")"
        done
        
        echo ""
        print_status $BLUE "🛠️  Attempting to repair corrupted files..."
        local repaired_count=0
        
        for file in "${corrupted_files[@]}"; do
            if repair_image "$file"; then
                ((repaired_count++))
            fi
        done
        
        echo ""
        print_status $GREEN "✅ Repair Summary:"
        echo "Files repaired: $repaired_count"
        echo "Files still corrupted: $((${#corrupted_files[@]} - repaired_count))"
    else
        print_status $GREEN "✅ All image files are valid!"
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
    scan_images
    
    echo ""
    print_status $BLUE "🎉 Image validation and repair completed!"
    print_status $YELLOW "💡 Tip: Run this script regularly to maintain image integrity"
}

# Run main function
main
