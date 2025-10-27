#!/bin/bash

# Configuration
PI_USER="ian"
PI_HOST="192.168.50.243"
PI_PATH="/mnt/Plex/photo-portfolio/images"
SSH_KEY="~/.ssh/id_ed25519"

echo "🔍 Checking and optimizing images on Pi5..."
echo "📁 Location: $PI_PATH"
echo ""

# Check Farnborough folder specifically
echo "=== Checking Farnborough Folder ==="
if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "
    if [ -d '$PI_PATH/Farnborough' ]; then
        echo '📂 Farnborough folder exists'
        echo '📊 Image count:'
        ls -1 '$PI_PATH/Farnborough/*.jpg' 2>/dev/null | wc -l
        echo '📏 Sample file sizes:'
        ls -lh '$PI_PATH/Farnborough/'*.jpg 2>/dev/null | head -5
        echo ''
        echo '✏️  Image metadata (showing optimization info):'
        ls -1 '$PI_PATH/Farnborough/'*.jpg 2>/dev/null | head -1 | while read img; do
            file \"\$img\"
            jpeginfo -c \"\$img\" 2>/dev/null || echo '⚠️  jpeginfo not available'
        done
    else
        echo '❌ Farnborough folder not found'
    fi
"; then
    echo ""
fi

echo ""
echo "=== Optimizing Images ==="
echo "🔧 Running jpegoptim..."

OPTIMIZE_OUTPUT=$(ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "
    SOURCE_DIR=\"$PI_PATH\"
    
    if [ ! -d \"\$SOURCE_DIR\" ]; then
        echo \"❌ Source directory not found: \$SOURCE_DIR\" >&2
        exit 1
    fi
    
    echo \"📁 Optimizing images in: \$SOURCE_DIR\"
    
    # Count total images
    TOTAL_IMAGES=\$(find \"\$SOURCE_DIR\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' \\) | wc -l)
    echo \"📊 Total images: \$TOTAL_IMAGES\"
    
    # Use jpegoptim to optimize JPEG images
    if command -v jpegoptim >/dev/null 2>&1; then
        echo \"⚙️  Running jpegoptim with --max=85...\"
        find \"\$SOURCE_DIR\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' \\) -print0 | \
        xargs -0 -I {} sh -c 'jpegoptim --max=85 --strip-all --overwrite \"{}\" && echo \"✓ {}\"' 2>/dev/null | \
        head -30
        echo \"✅ Optimization complete\"
        exit 0
    else
        echo \"❌ jpegoptim not found\" >&2
        exit 1
    fi
" 2>&1)

if [ $? -eq 0 ]; then
    echo "$OPTIMIZE_OUTPUT"
    echo ""
    echo "✅ Images optimized successfully!"
else
    echo "$OPTIMIZE_OUTPUT"
    echo ""
    echo "❌ Optimization failed!"
fi

echo ""
echo "=== After Optimization Check ==="
echo "📊 Checking Farnborough folder again..."
if ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "
    if [ -d '$PI_PATH/Farnborough' ]; then
        echo '📏 File sizes after optimization:'
        ls -lh '$PI_PATH/Farnborough/'*.jpg 2>/dev/null | head -5
    fi
"; then
    echo ""
fi

echo ""
echo "🎉 Done!"

