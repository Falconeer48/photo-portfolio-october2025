#!/bin/bash

# Quick Image Corruption Checker
# Fast check for obviously corrupted images

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
CORRUPTED=0
CHECKED=0

echo "🚀 Quick Image Corruption Check"
echo "==============================="

# Directory to check
DIR="/Users/ian/Portfolio Images to Transfer"

if [ ! -d "$DIR" ]; then
    echo -e "${RED}Directory not found: $DIR${NC}"
    exit 1
fi

echo "Checking: $DIR"
echo ""

# Find and check images
while IFS= read -r -d '' file; do
    ((CHECKED++))
    filename=$(basename "$file")
    corrupted=false

    # Quick checks
    if [ ! -s "$file" ]; then
        echo -e "${RED}CORRUPTED: $filename (0 bytes)${NC}"
        ((CORRUPTED++))
        continue
    fi

    # Check file type
    if ! file "$file" | grep -qE "(JPEG|PNG|GIF|TIFF|BMP)"; then
        echo -e "${RED}CORRUPTED: $filename (invalid format)${NC}"
        ((CORRUPTED++))
        continue
    fi

    # Quick sips check (macOS)
    if ! sips -g pixelWidth "$file" >/dev/null 2>&1; then
        echo -e "${RED}CORRUPTED: $filename (sips failed)${NC}"
        ((CORRUPTED++))
        continue
    fi

    # Show progress every 50 files
    if [ $((CHECKED % 50)) -eq 0 ]; then
        echo -e "${BLUE}Checked: $CHECKED files...${NC}"
    fi

done < <(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.bmp" \) -print0)

echo ""
echo "📊 Results:"
echo "==========="
echo -e "Total checked: ${BLUE}$CHECKED${NC}"
echo -e "Corrupted: ${RED}$CORRUPTED${NC}"
echo -e "Valid: ${GREEN}$((CHECKED - CORRUPTED))${NC}"

if [ $CORRUPTED -eq 0 ]; then
    echo -e "${GREEN}🎉 No corrupted images found!${NC}"
else
    echo -e "${YELLOW}⚠️  Found $CORRUPTED corrupted images${NC}"
fi
