#!/bin/bash

# Smart Image Optimization Script for Photo Portfolio
# Only optimizes new or changed images

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_DIR="/mnt/Plex/photo-portfolio/images"
OPTIMIZED_DIR="/mnt/Plex/photo-portfolio/images/optimized"
THUMBNAIL_SIZE="300x300"
PREVIEW_SIZE="800x800"
LARGE_SIZE="1200x1200"
QUALITY="85"

# Allow specific folders to be optimized (passed as arguments)
FOLDERS_TO_OPTIMIZE=()
if [ $# -gt 0 ]; then
    # If folders are specified, only optimize those
    while [ $# -gt 0 ]; do
        FOLDERS_TO_OPTIMIZE+=("$1")
        shift
    done
    echo -e "${BLUE}Optimizing only specified folders: ${FOLDERS_TO_OPTIMIZE[*]}${NC}"
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}ImageMagick is not installed. Installing...${NC}"
    sudo apt update && sudo apt install -y imagemagick
fi

# Create optimized directories
create_directories() {
  echo -e "${BLUE}Creating optimized image directories...${NC}"
  mkdir -p "$OPTIMIZED_DIR"
  mkdir -p "$OPTIMIZED_DIR/thumbnails"
  mkdir -p "$OPTIMIZED_DIR/previews"
  mkdir -p "$OPTIMIZED_DIR/large"
  mkdir -p "$OPTIMIZED_DIR/full"
}

# Check if image needs optimization
needs_optimization() {
    local input_file="$1"
    local relative_path="${input_file#$SOURCE_DIR/}"
    local thumbnail_file="$OPTIMIZED_DIR/thumbnails/$relative_path"
    local preview_file="$OPTIMIZED_DIR/previews/$relative_path"
    local large_file="$OPTIMIZED_DIR/large/$relative_path"
    local full_file="$OPTIMIZED_DIR/full/$relative_path"
    
    # If any optimized file doesn't exist, needs optimization
    if [ ! -f "$thumbnail_file" ] || [ ! -f "$preview_file" ] || [ ! -f "$large_file" ] || [ ! -f "$full_file" ]; then
        return 0  # Needs optimization
    fi
    
    # If source file is newer than any optimized file, needs optimization
    local source_time=$(stat -c %Y "$input_file")
    local thumbnail_time=$(stat -c %Y "$thumbnail_file")
    local preview_time=$(stat -c %Y "$preview_file")
    local large_time=$(stat -c %Y "$large_file")
    local full_time=$(stat -c %Y "$full_file")
    
    if [ "$source_time" -gt "$thumbnail_time" ] || [ "$source_time" -gt "$preview_time" ] || [ "$source_time" -gt "$large_time" ] || [ "$source_time" -gt "$full_time" ]; then
        return 0  # Needs optimization
    fi
    
    return 1  # Doesn't need optimization
}

# Optimize a single image
optimize_image() {
    local input_file="$1"
    local relative_path="${input_file#$SOURCE_DIR/}"
    local dirname=$(dirname "$relative_path")
    
    echo -e "${YELLOW}Processing: $relative_path${NC}"
    
    # Create directories
    mkdir -p "$OPTIMIZED_DIR/thumbnails/$dirname"
    mkdir -p "$OPTIMIZED_DIR/previews/$dirname"
    mkdir -p "$OPTIMIZED_DIR/large/$dirname"
    mkdir -p "$OPTIMIZED_DIR/full/$dirname"
    
    # Generate thumbnail (JPEG) - resize to fit, maintain aspect ratio (no cropping)
    convert "$input_file" -resize "${THUMBNAIL_SIZE}>" \
        -quality "$QUALITY" "$OPTIMIZED_DIR/thumbnails/$relative_path"
    
    # Generate preview (JPEG) - resize to fit, maintain aspect ratio (no cropping)
    convert "$input_file" -resize "${PREVIEW_SIZE}>" \
        -quality "$QUALITY" "$OPTIMIZED_DIR/previews/$relative_path"
    
    # Generate large (JPEG) for desktop - resize to fit, maintain aspect ratio (no cropping)
    convert "$input_file" -resize "${LARGE_SIZE}>" \
        -quality "$QUALITY" "$OPTIMIZED_DIR/large/$relative_path"
    
    # Copy full-size image for fullscreen viewing (original quality)
    # Convert to JPEG if it's not already, to ensure consistency
    local file_ext="${input_file##*.}"
    local full_path="$OPTIMIZED_DIR/full/$relative_path"
    
    if [[ "${file_ext,,}" == "jpg" ]] || [[ "${file_ext,,}" == "jpeg" ]]; then
        # For JPEG files, copy as-is to preserve quality
        cp "$input_file" "$full_path"
    else
        # For PNG and other formats, convert to JPEG with high quality
        convert "$input_file" -quality 95 "$full_path"
    fi
    
    echo -e "${GREEN}✓ Optimized: $relative_path${NC}"
}

# Process all images - SMART VERSION with optional folder filtering
process_all_images() {
    echo -e "${BLUE}Starting smart image optimization...${NC}"
    
    # Create array of all images
    local images=()
    
    # If specific folders are provided, only process those
    if [ ${#FOLDERS_TO_OPTIMIZE[@]} -gt 0 ]; then
        echo -e "${YELLOW}Optimizing only recently synced folders...${NC}"
        for folder in "${FOLDERS_TO_OPTIMIZE[@]}"; do
            # Build full path to folder
            local folder_path="$SOURCE_DIR/$folder"
            
            # Check if folder exists
            if [ ! -d "$folder_path" ]; then
                echo -e "${YELLOW}⚠️  Folder not found, skipping: $folder${NC}"
                continue
            fi
            
            echo -e "${BLUE}📁 Processing folder: $folder${NC}"
            
            # Find all images in this folder and subfolders
            while IFS= read -r -d '' image; do
                images+=("$image")
            done < <(find -L "$folder_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0)
        done
    else
        # Process all images if no specific folders provided
        echo -e "${BLUE}Processing all images in portfolio...${NC}"
        while IFS= read -r -d '' image; do
            images+=("$image")
        done < <(find -L "$SOURCE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0)
    fi
    
    local total_images=${#images[@]}
    local processed=0
    local skipped=0
    local optimized=0
    
    if [ "$total_images" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No images found to optimize${NC}"
        return
    fi
    
    echo -e "${BLUE}Found $total_images images to check${NC}"
    
    for image in "${images[@]}"; do
        if needs_optimization "$image"; then
            optimize_image "$image"
            ((optimized++))
        else
            echo -e "${BLUE}⏭️  Skipping: ${image#$SOURCE_DIR/} (already optimized)${NC}"
            ((skipped++))
        fi
        ((processed++))
        
        # Only show progress every 10 images to reduce output noise
        if [ $((processed % 10)) -eq 0 ] || [ $processed -eq $total_images ]; then
            echo -e "${BLUE}Progress: $processed/$total_images (Optimized: $optimized, Skipped: $skipped)${NC}"
        fi
    done
    
    echo -e "${GREEN}=== Optimization Summary ===${NC}"
    echo -e "${GREEN}Total images checked: $total_images${NC}"
    echo -e "${GREEN}Images optimized: $optimized${NC}"
    echo -e "${BLUE}Images skipped: $skipped${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}=== Smart Image Optimization Script ===${NC}"
    echo -e "${BLUE}Source: $SOURCE_DIR${NC}"
    echo -e "${BLUE}Output: $OPTIMIZED_DIR${NC}"
    echo
    
    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}Error: Source directory not found: $SOURCE_DIR${NC}"
        exit 1
    fi
    
    create_directories
    process_all_images
    
    echo -e "${GREEN}=== Smart Optimization Complete! ===${NC}"
    echo -e "${GREEN}Optimized images saved to: $OPTIMIZED_DIR${NC}"
}

# Run main function
main "$@"
