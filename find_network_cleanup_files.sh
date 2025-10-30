#!/bin/bash

echo "🔍 Searching for network cleanup files..."

# List of filenames to find
FILES=(
  "disable_unused_networks.sh"
  "notify_network_cleanup.sh"
  "disable_unused_networks.conf"
  "com.local.disable-unused-networks.plist"
  "com.local.notify-network-cleanup.plist"
)

# List of common base directories to search
BASE_DIRS=(
  "/usr/local/sbin"
  "/usr/local/bin"
  "/Library/Scripts"
  "/Library/LaunchDaemons"
  "/etc/newsyslog.d"
  "/Users/Shared/Library/LaunchAgents"
  "$HOME/Library/LaunchAgents"
  "$HOME"
)

for FILE in "${FILES[@]}"; do
  echo ""
  echo "🔎 Looking for: $FILE"
  FOUND=false
  for DIR in "${BASE_DIRS[@]}"; do
    FULL_PATH="$DIR/$FILE"
    if [ -e "$FULL_PATH" ]; then
      echo "✅ Found: $FULL_PATH"
      FOUND=true
    fi
  done
  if [ "$FOUND" = false ]; then
    echo "❌ Not found in known locations"
  fi
done

echo ""
echo "✅ Done scanning."