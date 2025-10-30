#!/bin/bash
# Helper script to copy sync-images-to-pi5-nested.sh to Mac Mini
# Run this from the Mac Mini or manually copy the file

echo "To copy sync-images-to-pi5-nested.sh to Mac Mini:"
echo ""
echo "Option 1: From Mac Mini, copy from network share:"
echo "  cp /Volumes/ian/Scripts/sync-images-to-pi5-nested.sh ~/"
echo "  chmod +x ~/sync-images-to-pi5-nested.sh"
echo ""
echo "Option 2: Manual copy via USB/external drive"
echo ""
echo "Option 3: From Mac Mini, pull directly:"
echo "  curl -o ~/sync-images-to-pi5-nested.sh https://[your-git-repo]/sync-images-to-pi5-nested.sh"
echo "  chmod +x ~/sync-images-to-pi5-nested.sh"
