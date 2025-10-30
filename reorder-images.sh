#!/bin/bash

# Image Reordering Script
# Helps you reorder images in folders by renaming them with numbers

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Image Reordering Script"
    echo ""
    echo "Usage:"
    echo "  $0 <folder_path> [start_number]"
    echo ""
    echo "Examples:"
    echo "  $0 '/Users/ian/Portfolio Images to Transfer/Australia/Tasmania'"
    echo "  $0 '/Users/ian/Portfolio Images to Transfer/flora' 1"
    echo "  $0 '/Users/ian/Portfolio Images to Transfer/landscapes' 10"
    echo ""
    echo "This will:"
    echo "  1. Show current image order"
    echo "  2. Let you reorder by renaming with numbers"
    echo "  3. Optionally sync to Pi5"
}

# Check if folder path is provided
if [ -z "$1" ]; then
    show_usage
    exit 1
fi

FOLDER_PATH="$1"
START_NUMBER="${2:-1}"

# Check if folder exists
if [ ! -d "$FOLDER_PATH" ]; then
    echo "${RED}Error: Folder '$FOLDER_PATH' does not exist${NC}"
    exit 1
fi

echo "${BLUE}Image Reordering Tool${NC}"
echo "Folder: $FOLDER_PATH"
echo ""

# Get list of image files (excluding Cover.jpg) - only files in the current directory
cd "$FOLDER_PATH" || { echo "${RED}Error: Failed to cd to '$FOLDER_PATH'${NC}"; exit 1; }
IMAGES=($(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -not -name "Cover.jpg" -print0 | xargs -0 -I{} basename "{}" | sort))

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "${YELLOW}No images found in folder${NC}"
    exit 0
fi

echo "${GREEN}Current image order:${NC}"
for i in "${!IMAGES[@]}"; do
    echo "  $((i+1)). ${IMAGES[$i]}"
done

echo ""
echo "${YELLOW}To reorder images:${NC}"
echo "1. Rename files with numbers (e.g., '01_Image.jpg', '02_Image.jpg')"
echo "2. The website will display them in numerical/alphabetical order"
echo "3. Run sync to update the website"
echo ""

# Show example rename commands
echo "${BLUE}Example rename commands:${NC}"
for i in "${!IMAGES[@]}"; do
    new_number=$((START_NUMBER + i))
    printf "  %02d_%s\n" $new_number "${IMAGES[$i]}"
done

echo ""
echo "${GREEN}Quick reorder options:${NC}"
echo "1. ${BLUE}Auto-number all images${NC}:"
echo "2. ${BLUE}Manual reorder${NC}: Use Finder or rename files manually"
echo "3. ${BLUE}Sync after reordering${NC}: cd /Users/ian/Scripts && ./sync-to-pi5.sh sync"
echo ""

# Ask if user wants to auto-number
read -p "Do you want to auto-number all images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "${BLUE}Auto-numbering images...${NC}"
    
    # Create backup
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp *.jpg "$BACKUP_DIR/" 2>/dev/null || true
    cp *.jpeg "$BACKUP_DIR/" 2>/dev/null || true
    cp *.png "$BACKUP_DIR/" 2>/dev/null || true
    cp *.gif "$BACKUP_DIR/" 2>/dev/null || true
    cp *.webp "$BACKUP_DIR/" 2>/dev/null || true
    echo "${GREEN}Backup created: $FOLDER_PATH/$BACKUP_DIR${NC}"
    
    # Rename files
    for i in "${!IMAGES[@]}"; do
        filename="${IMAGES[$i]}"
        new_number=$((START_NUMBER + i))
        new_name=$(printf "%02d_%s" $new_number "$filename")
        
        if [ "$filename" != "$new_name" ]; then
            mv "$filename" "$new_name"
            echo "${GREEN}Renamed: $filename → $new_name${NC}"
        fi
    done
    
    echo ""
    echo "${GREEN}Auto-numbering complete!${NC}"
    echo "${YELLOW}Run sync to update website: cd /Users/ian/Scripts && ./sync-to-pi5.sh sync${NC}"
else
    echo "${YELLOW}Manual reordering mode. Rename files as needed, then run sync.${NC}"
fi 