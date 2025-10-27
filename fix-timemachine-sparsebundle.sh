#!/bin/bash

# Fix Time Machine sparsebundle UUID issue
# This script fixes the missing UUID in the sparsebundle Info.plist

set -e

TIMEMACHINE_VOLUME="/Volumes/TimeMachine"
SPARSEBUNDLE_NAME="Ian's iMac.sparsebundle"
SPARSEBUNDLE_PATH="$TIMEMACHINE_VOLUME/$SPARSEBUNDLE_NAME"

echo "=== Time Machine Sparsebundle Fix ==="
echo "Checking sparsebundle: $SPARSEBUNDLE_PATH"

# Check if sparsebundle exists
if [ ! -d "$SPARSEBUNDLE_PATH" ]; then
    echo "Error: Sparsebundle not found at $SPARSEBUNDLE_PATH"
    exit 1
fi

# Check if Info.plist exists
INFO_PLIST="$SPARSEBUNDLE_PATH/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
    echo "Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi

echo "Found sparsebundle and Info.plist"

# Backup the original Info.plist
echo "Creating backup of Info.plist..."
cp "$INFO_PLIST" "$INFO_PLIST.backup.$(date +%Y%m%d_%H%M%S)"

# Generate a new UUID
NEW_UUID=$(uuidgen)
echo "Generated new UUID: $NEW_UUID"

# Create a temporary plist with the UUID added
TEMP_PLIST="/tmp/Info.plist.temp"

# Extract the existing content and add UUID
cat > "$TEMP_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>band-size</key>
	<integer>8388608</integer>
	<key>bundle-backingstore-version</key>
	<integer>1</integer>
	<key>diskimage-bundle-type</key>
	<string>com.apple.diskimage.sparsebundle</string>
	<key>size</key>
	<integer>59132231680</integer>
	<key>uuid</key>
	<string>$NEW_UUID</string>
</dict>
</plist>
EOF

# Replace the original Info.plist
echo "Updating Info.plist with new UUID..."
cp "$TEMP_PLIST" "$INFO_PLIST"

# Clean up
rm -f "$TEMP_PLIST"

echo "✅ Successfully updated Info.plist with UUID: $NEW_UUID"
echo "Backup created at: $INFO_PLIST.backup.$(date +%Y%m%d_%H%M%S)"

echo ""
echo "Next steps:"
echo "1. Try running Time Machine backup again"
echo "2. If issues persist, try Solution 2 (recreate sparsebundle)"
echo "3. Check Time Machine logs: log stream --predicate 'subsystem == \"com.apple.TimeMachine\"'"
