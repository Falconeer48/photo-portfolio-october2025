#!/bin/bash

# Check for Corrupted Images Script
# Identifies corrupted or damaged image files using multiple validation methods

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Counters
TOTAL_IMAGES=0
CORRUPTED_IMAGES=0
SUSPICIOUS_IMAGES=0

# Arrays to store results
CORRUPTED_FILES=()
SUSPICIOUS_FILES=()
VALID_FILES=()

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

info() {
    echo -e "${PURPLE}ℹ️${NC} $1"
}

# Function to check if file is corrupted using multiple methods
check_image_integrity() {
    local file="$1"
    local filename=$(basename "$file")
    local corruption_detected=false
    local suspicious_detected=false
    local issues=()

    # Method 1: Check file size (0 bytes = definitely corrupted)
    if [ ! -s "$file" ]; then
        issues+=("zero-byte file")
        corruption_detected=true
    fi

    # Method 2: Use 'file' command to check magic bytes
    local file_type=$(file -b "$file" 2>/dev/null)
    if [[ ! "$file_type" =~ ^(JPEG|PNG|GIF|TIFF|BMP) ]]; then
        if [[ "$file_type" == "data" ]] || [[ "$file_type" == *"cannot"* ]] || [[ "$file_type" == *"empty"* ]]; then
            issues+=("invalid file format")
            corruption_detected=true
        fi
    fi

    # Method 3: Try to identify with sips (macOS built-in)
    if command -v sips >/dev/null 2>&1; then
        if ! sips -g pixelWidth "$file" >/dev/null 2>&1; then
            issues+=("sips validation failed")
            corruption_detected=true
        fi
    fi

    # Method 4: Try to get metadata with mdls (macOS)
    if command -v mdls >/dev/null 2>&1; then
        local pixel_width=$(mdls -name kMDItemPixelWidth "$file" 2>/dev/null | grep -o '[0-9]*')
        if [ -z "$pixel_width" ] || [ "$pixel_width" = "0" ]; then
            issues+=("no valid metadata")
            suspicious_detected=true
        fi
    fi

    # Method 5: Check file extension vs actual format
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    case "$extension" in
        jpg|jpeg)
            if [[ ! "$file_type" =~ JPEG ]]; then
                issues+=("extension mismatch")
                suspicious_detected=true
            fi
            ;;
        png)
            if [[ ! "$file_type" =~ PNG ]]; then
                issues+=("extension mismatch")
                suspicious_detected=true
            fi
            ;;
        gif)
            if [[ ! "$file_type" =~ GIF ]]; then
                issues+=("extension mismatch")
                suspicious_detected=true
            fi
            ;;
        tiff|tif)
            if [[ ! "$file_type" =~ TIFF ]]; then
                issues+=("extension mismatch")
                suspicious_detected=true
            fi
            ;;
        bmp)
            if [[ ! "$file_type" =~ BMP ]]; then
                issues+=("extension mismatch")
                suspicious_detected=true
            fi
            ;;
    esac

    # Method 6: Check for unusual file sizes (suspiciously small)
    local size=$(stat -f%z "$file" 2>/dev/null || echo "0")
    if [ "$size" -lt 100 ]; then
        issues+=("suspiciously small ($size bytes)")
        suspicious_detected=true
    fi

    # Report results
    if [ "$corruption_detected" = true ]; then
        error "CORRUPTED: $filename"
        for issue in "${issues[@]}"; do
            echo -e "    ${RED}•${NC} $issue"
        done
        CORRUPTED_FILES+=("$file")
        ((CORRUPTED_IMAGES++))
    elif [ "$suspicious_detected" = true ]; then
        warning "SUSPICIOUS: $filename"
        for issue in "${issues[@]}"; do
            echo -e "    ${YELLOW}•${NC} $issue"
        done
        SUSPICIOUS_FILES+=("$file")
        ((SUSPICIOUS_IMAGES++))
    else
        VALID_FILES+=("$file")
    fi

    ((TOTAL_IMAGES++))
}

# Function to scan directory for images
scan_directory() {
    local dir="$1"
    local search_pattern="$2"

    log "Scanning directory: $dir"

    if [ ! -d "$dir" ]; then
        error "Directory does not exist: $dir"
        return 1
    fi

    # Find all image files
    local image_files
    if [ -n "$search_pattern" ]; then
        image_files=$(find "$dir" -type f -iname "$search_pattern" 2>/dev/null)
    else
        image_files=$(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.bmp" \) 2>/dev/null)
    fi

    if [ -z "$image_files" ]; then
        warning "No image files found in $dir"
        return 0
    fi

    local file_count=$(echo "$image_files" | wc -l | tr -d ' ')
    info "Found $file_count image files to check"

    # Check each image file
    local counter=0
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            ((counter++))
            echo -ne "\rProgress: $counter/$file_count "
            check_image_integrity "$file"
        fi
    done <<< "$image_files"

    echo "" # New line after progress
}

# Function to display summary
display_summary() {
    echo ""
    echo "🔍 Image Corruption Check Summary"
    echo "================================="
    echo -e "${BLUE}Total Images Checked:${NC} $TOTAL_IMAGES"
    echo -e "${GREEN}Valid Images:${NC} $((TOTAL_IMAGES - CORRUPTED_IMAGES - SUSPICIOUS_IMAGES))"
    echo -e "${YELLOW}Suspicious Images:${NC} $SUSPICIOUS_IMAGES"
    echo -e "${RED}Corrupted Images:${NC} $CORRUPTED_IMAGES"

    if [ $CORRUPTED_IMAGES -gt 0 ]; then
        echo ""
        echo -e "${RED}📋 CORRUPTED FILES:${NC}"
        for file in "${CORRUPTED_FILES[@]}"; do
            echo -e "  ${RED}•${NC} $file"
        done
    fi

    if [ $SUSPICIOUS_IMAGES -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}📋 SUSPICIOUS FILES:${NC}"
        for file in "${SUSPICIOUS_FILES[@]}"; do
            echo -e "  ${YELLOW}•${NC} $file"
        done
    fi

    echo ""
    if [ $CORRUPTED_IMAGES -eq 0 ] && [ $SUSPICIOUS_IMAGES -eq 0 ]; then
        success "All images appear to be valid! 🎉"
    else
        echo -e "${BLUE}💡 Recommendations:${NC}"
        echo "• Backup corrupted files before attempting repair"
        echo "• Try opening suspicious files to verify they display correctly"
        echo "• Consider re-downloading or re-exporting damaged images"
        echo "• Use professional image repair tools for valuable corrupted files"
    fi
}

# Main script
echo "🔍 Image Corruption Checker"
echo "==========================="

# Check if arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory> [pattern]"
    echo ""
    echo "Examples:"
    echo "  $0 /Users/ian/Pictures"
    echo "  $0 /Users/ian/Portfolio '*.jpg'"
    echo "  $0 . '*.png'"
    echo ""
    echo "Scanning default portfolio directory..."
    DEFAULT_DIR="/Users/ian/Portfolio Images to Transfer"
    if [ -d "$DEFAULT_DIR" ]; then
        scan_directory "$DEFAULT_DIR"
    else
        error "Default directory not found. Please specify a directory to scan."
        exit 1
    fi
else
    scan_directory "$1" "$2"
fi

display_summary

# Create log file with results
LOG_FILE="corrupted_images_$(date +%Y%m%d_%H%M%S).log"
{
    echo "Image Corruption Check Results - $(date)"
    echo "========================================"
    echo "Total Images: $TOTAL_IMAGES"
    echo "Corrupted: $CORRUPTED_IMAGES"
    echo "Suspicious: $SUSPICIOUS_IMAGES"
    echo ""
    if [ $CORRUPTED_IMAGES -gt 0 ]; then
        echo "CORRUPTED FILES:"
        for file in "${CORRUPTED_FILES[@]}"; do
            echo "  $file"
        done
        echo ""
    fi
    if [ $SUSPICIOUS_IMAGES -gt 0 ]; then
        echo "SUSPICIOUS FILES:"
        for file in "${SUSPICIOUS_FILES[@]}"; do
            echo "  $file"
        done
    fi
} > "$LOG_FILE"

info "Results saved to: $LOG_FILE"
