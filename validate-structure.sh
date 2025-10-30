#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help/usage
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Photo Portfolio Structure Validation"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --auto-setup                Create missing folders automatically"
    echo "  --sync-structure-from-pi5   Sync folder structure from Pi5 to Mac (no images)"
    echo "  --help, -h                  Show this help message"
    echo
    exit 0
fi

# Function to get folder names from the Pi5 dynamically
get_pi5_folders() {
    ssh -p 22 ian@192.168.50.243 "find /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/public/images/portfolio/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n'" 2>/dev/null
}

# Function to get expected folders dynamically (tries Pi5 first, then sync script, then fallback)
get_expected_folders() {
    local pi5_folders
    pi5_folders=$(get_pi5_folders)
    if [ -n "$pi5_folders" ]; then
        echo "$pi5_folders"
        return
    fi
    if [ -f "$SYNC_SCRIPT" ]; then
        grep -A 20 "map_folder_name()" "$SYNC_SCRIPT" | grep "echo.*\".*\"" | sed 's/.*echo "\([^"]*\)".*/\1/' | grep -v "as-is"
        return
    fi
    echo "ERROR: Could not fetch folder names from Pi5 or sync script." >&2
    exit 1
}

# Use a POSIX-compatible loop to populate expected_folders
expected_folders=()
while IFS= read -r line; do
  expected_folders+=("$line")
done < <(get_expected_folders)

# Use the map_folder_name function from sync script if available, otherwise use fallback
if [ -f "$SYNC_SCRIPT" ]; then
    source "$SYNC_SCRIPT"
fi
if ! command -v map_folder_name >/dev/null 2>&1; then
    map_folder_name() {
        local source_name="$1"
        case "$source_name" in
            "doors_and_windows") echo "Doors and Windows" ;;
            "urban_landscapes") echo "Urban Landscapes" ;;
            "flora") echo "Flora" ;;
            "holidays") echo "Holidays" ;;
            "landscapes") echo "Landscapes" ;;
            "psc_course") echo "PSC Course" ;;
            "safaris") echo "Safaris" ;;
            "wildlife") echo "Wildlife" ;;
            "family_and_friends") echo "Family and Friends" ;;
            "south_africa") echo "South Africa" ;;
            "australia") echo "Australia" ;;
            "hms_victory") echo "HMS_Victory" ;;
            *) echo "$source_name" ;;
        esac
    }
fi

# Function to sync just the folder structure from Pi5 to Mac
sync_structure_from_pi5() {
    echo -e "${BLUE}Syncing folder structure from Pi5 to Mac...${NC}"
    echo "Running as: $(whoami)"
    echo "Current directory: $(pwd)"
    echo "PATH: $PATH"
    # Only copy directory structure, not files
    rsync -av --protect-args -f "+ */" -f "- *" \
        -e "ssh -p 22" \
        ian@192.168.50.243:/media/ian/Externaldrive/Cursor_Projects/photo-portfolio/public/images/portfolio/ \
        "/Users/ian/Portfolio Images to Transfer/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Folder structure synced from Pi5 to Mac successfully!${NC}"
    else
        echo -e "${RED}Failed to sync folder structure from Pi5 to Mac.${NC}"
    fi
}

# Option to call the sync_structure_from_pi5 function
if [[ "$1" == "--sync-structure-from-pi5" ]]; then
    sync_structure_from_pi5
    exit $?
fi

# Parse command line arguments
AUTO_SETUP=false
if [ "$1" = "--auto-setup" ] || [ "$1" = "-a" ]; then
    AUTO_SETUP=true
fi

# Check if source directory exists
SOURCE_DIR="/Users/ian/Portfolio Images to Transfer"
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ Source directory '$SOURCE_DIR' does not exist${NC}"
    echo -e "${YELLOW}💡 Creating directory structure automatically...${NC}"
    mkdir -p "$SOURCE_DIR"
fi

# Check for expected folders (Mac → Pi5 mapping)
echo -e "${BLUE}📁 Checking for expected folders (Mac → Pi5 mapping)...${NC}"
missing_folders=()
for folder in "${expected_folders[@]}"; do
    if [ -d "$SOURCE_DIR/$folder" ]; then
        pi5_name=$(map_folder_name "$folder")
        echo -e "${GREEN}  ✅ $folder → $pi5_name${NC}"
    else
        pi5_name=$(map_folder_name "$folder")
        echo -e "${YELLOW}  ⚠️  $folder → $pi5_name (missing)${NC}"
        missing_folders+=("$folder")
    fi
done

# Auto-create missing folders if requested
if [ "$AUTO_SETUP" = true ] && [ ${#missing_folders[@]} -gt 0 ]; then
    echo
    echo -e "${BLUE}🔧 Auto-creating missing folders...${NC}"
    for folder in "${missing_folders[@]}"; do
        mkdir -p "$SOURCE_DIR/$folder"
        if [ $? -eq 0 ]; then
            pi5_name=$(map_folder_name "$folder")
            echo -e "${GREEN}  ✅ Created: $folder → $pi5_name${NC}"
            # If the folder contains images and no Cover.jpg, rename the first image to Cover.jpg
            if [ -d "$SOURCE_DIR/$folder" ]; then
              cover_path="$SOURCE_DIR/$folder/Cover.jpg"
              if [ ! -f "$cover_path" ]; then
                first_image=$(find "$SOURCE_DIR/$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | sort | head -n 1)
                if [ -n "$first_image" ]; then
                  mv "$first_image" "$cover_path"
                  echo -e "${GREEN}    Renamed $(basename "$first_image") to Cover.jpg in $folder${NC}"
                fi
              fi
            fi
        else
            echo -e "${RED}  ❌ Failed to create: $folder${NC}"
        fi
    done
    # Re-check missing folders after creation
    missing_folders=()
    for folder in "${expected_folders[@]}"; do
        if [ ! -d "$SOURCE_DIR/$folder" ]; then
            missing_folders+=("$folder")
        fi
    done
fi

# Check for unexpected folders (ignore folders with underscores)
echo -e "${BLUE}🔍 Checking for unexpected folders...${NC}"
unexpected_folders=()
for folder in "$SOURCE_DIR"/*/; do
    if [ -d "$folder" ]; then
        folder_name="$(basename "$folder")"
        # Ignore folders with underscores
        if [[ "$folder_name" == *"_"* ]]; then
            continue
        fi
        found=false
        for expected in "${expected_folders[@]}"; do
            if [ "$folder_name" = "$expected" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            pi5_name=$(map_folder_name "$folder_name")
            echo -e "${YELLOW}  ⚠️  $folder_name → $pi5_name (unexpected)${NC}"
            echo -e "${BLUE}      This will be synced as-is to Pi5${NC}"
            unexpected_folders+=("$folder_name")
        fi
    fi
done
if [ ${#unexpected_folders[@]} -eq 0 ]; then
    echo -e "${GREEN}  ✅ No unexpected folders found${NC}"
fi

# Check folder contents (ignore folders with underscores)
echo -e "${BLUE}📸 Checking folder contents...${NC}"
empty_folders=()
no_cover_folders=()
total_images=0
for folder in "$SOURCE_DIR"/*/; do
    if [ -d "$folder" ]; then
        folder_name="$(basename "$folder")"
        # Ignore folders with underscores
        if [[ "$folder_name" == *"_"* ]]; then
            continue
        fi
        if [ -z "$(ls -A "$folder")" ]; then
            echo -e "${YELLOW}  ⚠️  $folder_name (empty)${NC}"
            empty_folders+=("$folder_name")
        else
            # Count image files
            image_count=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
            total_images=$((total_images + image_count))
            if [ "$image_count" -eq 0 ]; then
                echo -e "${YELLOW}  ⚠️  $folder_name (no images)${NC}"
            else
                echo -e "${GREEN}  ✅ $folder_name ($image_count images)${NC}"
            fi
            # Check for cover image
            if [ -f "$folder/Cover.jpg" ] || [ -f "$folder/cover.jpg" ]; then
                echo -e "${GREEN}    ✅ Has cover image${NC}"
            else
                echo -e "${YELLOW}    ⚠️  No cover image${NC}"
                no_cover_folders+=("$folder_name")
            fi
        fi
    fi
done

# Summary
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "  📁 Total folders found: $(find "$SOURCE_DIR" -maxdepth 1 -type d | wc -l)"
echo -e "  📸 Total images: $total_images"
echo -e "  ✅ Expected folders: $((${#expected_folders[@]} - ${#missing_folders[@]}))/${#expected_folders[@]}"
if [ ${#missing_folders[@]} -gt 0 ]; then
    echo -e "  ⚠️  Missing folders: ${#missing_folders[@]}"
fi
if [ ${#unexpected_folders[@]} -gt 0 ]; then
    echo -e "  ⚠️  Unexpected folders: ${#unexpected_folders[@]}"
fi
if [ ${#empty_folders[@]} -gt 0 ]; then
    echo -e "  ⚠️  Empty folders: ${#empty_folders[@]}"
fi
if [ ${#no_cover_folders[@]} -gt 0 ]; then
    echo -e "  ⚠️  Folders without cover images: ${#no_cover_folders[@]}"
fi

echo
# Show Pi5 folder structure
echo -e "${BLUE}🖥️  Pi5 Folder Structure (after sync):${NC}"
for folder in "${expected_folders[@]}"; do
    if [ -d "$SOURCE_DIR/$folder" ]; then
        pi5_name=$(map_folder_name "$folder")
        image_count=$(find "$SOURCE_DIR/$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
        if [ "$image_count" -gt 0 ]; then
            echo -e "${GREEN}  📸 $pi5_name ($image_count images)${NC}"
        else
            echo -e "${YELLOW}  📁 $pi5_name (empty)${NC}"
        fi
    fi
done
for folder in "${unexpected_folders[@]}"; do
    pi5_name=$(map_folder_name "$folder")
    image_count=$(find "$SOURCE_DIR/$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) | wc -l)
    if [ "$image_count" -gt 0 ]; then
        echo -e "${YELLOW}  📸 $pi5_name ($image_count images) - unexpected${NC}"
    else
        echo -e "${YELLOW}  📁 $pi5_name (empty) - unexpected${NC}"
    fi
done

echo
if [ ${#missing_folders[@]} -gt 0 ] || [ ${#empty_folders[@]} -gt 0 ]; then
    echo -e "${YELLOW}💡 Recommendations:${NC}"
    if [ ${#missing_folders[@]} -gt 0 ]; then
        echo -e "  • Run './scripts/validate-structure.sh --auto-setup' to create missing folders automatically"
        echo -e "  • Or run './sync-to-pi5.sh setup' to create missing folders"
    fi
    if [ ${#empty_folders[@]} -gt 0 ]; then
        echo -e "  • Add images to empty folders before syncing"
    fi
    if [ ${#no_cover_folders[@]} -gt 0 ]; then
        echo -e "  • Add Cover.jpg files to folders for better display"
    fi
    echo
fi
if [ ${#missing_folders[@]} -eq 0 ] && [ ${#empty_folders[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 Structure validation passed! Ready for syncing.${NC}"
    echo -e "${BLUE}💡 Run './sync-to-pi5.sh sync' to sync to Pi5${NC}"
    echo
    echo -e "${BLUE}Press any key to exit...${NC}"
    read -n 1 -s
    exit 0
else
    echo -e "${YELLOW}⚠️  Structure validation completed with warnings${NC}"
    echo -e "${BLUE}💡 Review recommendations above before syncing${NC}"
    echo
    echo -e "${BLUE}Press any key to exit...${NC}"
    read -n 1 -s
    exit 1
fi 