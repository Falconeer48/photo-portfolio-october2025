#!/bin/bash

# Configuration
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/home/ian/photo-portfolio/public/images/portfolio"
SSH_KEY="~/.ssh/id_ed25519"
LOCAL_PATH="/Users/ian/Portfolio Images to Transfer"

echo "🔄 Syncing images from 'Portfolio Images to Transfer' to Pi5..."

# Check if local portfolio directory exists
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Portfolio transfer directory not found: $LOCAL_PATH"
    echo "Please ensure you have images in the 'Portfolio Images to Transfer' folder"
    exit 1
fi

# Show what folders exist locally
echo "📁 Local folders found:"
find "$LOCAL_PATH" -maxdepth 1 -type d -not -path "$LOCAL_PATH" -exec basename {} \; | sort

# Show what folders exist on Pi5
echo "📁 Pi5 folders found:"
ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "find $PI_PATH -type d -mindepth 1 | sed 's|.*/||' | sort"

# Function to map Mac folder names to Pi5 folder names
map_folder_name() {
    local mac_folder="$1"
    case "$mac_folder" in
        "Doors and Windows")
            echo "Doors and Windows"
            ;;
        "Urban Landscapes")
            echo "Urban Landscapes"
            ;;
        "Family and Friends")
            echo "Family and Friends"
            ;;
        "South Africa")
            echo "South Africa"
            ;;
        *)
            echo "$mac_folder"
            ;;
    esac
}

echo "📤 Syncing images to Pi5..."
echo "🔄 Checking for missing folders and creating them..."

# Process each folder using process substitution to handle spaces
sync_success=true
while IFS= read -r -d '' folder_path; do
    mac_folder=$(basename "$folder_path")
    pi5_folder=$(map_folder_name "$mac_folder")
    echo "📁 Processing: '$mac_folder' → '$pi5_folder'"
    
    # Check if folder exists on Pi5, create if it doesn't
    if ! ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "[ -d '$PI_PATH/$pi5_folder' ]"; then
        echo "   ➕ Creating missing folder: $pi5_folder"
        ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "mkdir -p '$PI_PATH/$pi5_folder'"
    else
        echo "   ✅ Folder exists: $pi5_folder"
    fi
    
    # Sync this specific folder (including subfolders)
    echo "   📤 Syncing folder: $mac_folder"
    if rsync -avz --progress \
        --exclude '._*' \
        --exclude '.DS_Store' \
        -e "ssh -i $SSH_KEY" \
        "$LOCAL_PATH/$mac_folder/" "$PI_USER@$PI_HOST:$PI_PATH/$pi5_folder/"; then
        echo "   ✅ Successfully synced: $mac_folder"
        
        # Ensure Cover.jpg exists in the folder
        echo "   🖼️  Ensuring Cover.jpg exists..."
        
        # Check if Cover.jpg already exists on Pi5
        if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "[ -f '$PI_PATH/$pi5_folder/Cover.jpg' ]"; then
            echo "   ✅ Cover.jpg already exists"
        else
            # Find the first image file in the folder
            first_image=$(ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "find '$PI_PATH/$pi5_folder' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | head -1")
            
            if [ -n "$first_image" ]; then
                # Rename the first image to Cover.jpg
                echo "   📝 Renaming first image to Cover.jpg"
                ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "mv '$first_image' '$PI_PATH/$pi5_folder/Cover.jpg'"
            else
                # Create a generic cover image if no images exist
                echo "   🎨 Creating generic cover image"
                # Try ImageMagick first, fallback to copying a placeholder
                ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "
                    if command -v convert >/dev/null 2>&1; then
                        convert -size 800x600 xc:lightgray -pointsize 48 -fill black -gravity center -annotate +0+0 '$pi5_folder' '$PI_PATH/$pi5_folder/Cover.jpg'
                        echo '   ✅ Created cover with ImageMagick'
                    else
                        # Create a simple placeholder file
                        echo 'Generic Cover Image for $pi5_folder' > '$PI_PATH/$pi5_folder/Cover.jpg'
                        echo '   ⚠️  Created text placeholder (ImageMagick not available)'
                    fi
                "
            fi
        fi
    else
        echo "   ❌ Failed to sync: $mac_folder"
        sync_success=false
    fi
done < <(find "$LOCAL_PATH" -maxdepth 1 -type d -not -path "$LOCAL_PATH" -print0)

if [ "$sync_success" = true ]; then
    echo "✅ Images synced successfully!"
    
    # Optimize images on Pi5
    echo "🔧 Optimizing images on Pi5..."
    if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "cd /home/ian/photo-portfolio && ./scripts/optimize-images.sh"; then
        echo "✅ Images optimized successfully!"
    else
        echo "⚠️  Image optimization had issues, but continuing..."
    fi
    
    # Restart the photo portfolio service to refresh the cache
    echo "🔄 Restarting photo portfolio service..."
    ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "sudo systemctl restart photo-portfolio.service && sleep 3"
    
    # Verify the website is responding
    echo "🌐 Testing website..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://iancook.myddns.me)
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "✅ Website responding (HTTP 200)"
    else
        echo "❌ Website not responding (HTTP $HTTP_CODE)"
    fi
    
    echo "🎉 Image sync and optimization completed!"
    echo "📱 Test on your iPhone: https://iancook.myddns.me"
else
    echo "❌ Image sync failed!"
    exit 1
fi

