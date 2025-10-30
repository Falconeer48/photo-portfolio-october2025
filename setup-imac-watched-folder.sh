#!/bin/bash

# Setup script for iMac watched folder printing
# Run this on your iMac to set up the auto-print system

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status "$BLUE" "🖨️  Setting up watched folder auto-print system on iMac..."
echo ""

# Create the watched folder
WATCHED_FOLDER="$HOME/IncomingPrints"
print_status "$BLUE" "📁 Creating watched folder: $WATCHED_FOLDER"
mkdir -p "$WATCHED_FOLDER"
print_status "$GREEN" "✅ Folder created"

# Create the AppleScript for folder actions
SCRIPT_PATH="$HOME/Library/Scripts/Folder Action Scripts/Auto Print.scpt"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

print_status "$BLUE" "📝 Creating AppleScript folder action..."
mkdir -p "$SCRIPT_DIR"

# Create the AppleScript
cat > "/tmp/Auto Print.applescript" << 'EOF'
on adding folder items to this_folder after receiving these_items
    repeat with f in these_items
        try
            set p to POSIX path of f
            -- wait briefly so copying finishes
            delay 1
            -- only print common formats; extend as you wish
            set ext to do shell script "/usr/bin/python3 - <<'PY'
import os,sys
p=sys.argv[1]
print(os.path.splitext(p)[1].lower())
PY " & quoted form of p
            if ext is in {".pdf",".png",".jpg",".jpeg",".tiff",".bmp"} then
                -- send to your Canon queue on the iMac; adjust the printer name if needed
                do shell script "/usr/bin/lp -d Canon_G4070_series -o media=A4 -o sides=two-sided-long-edge " & quoted form of p
                -- log the print job
                do shell script "echo \"$(date): Printed $(basename " & quoted form of p & ")\" >> ~/IncomingPrints/print-log.txt"
            else
                -- log unsupported files
                do shell script "echo \"$(date): Skipped unsupported file $(basename " & quoted form of p & ") - extension: " & ext & "\" >> ~/IncomingPrints/print-log.txt"
            end if
        end try
    end repeat
end adding folder items to
EOF

# Compile the AppleScript
osacompile -o "$SCRIPT_PATH" "/tmp/Auto Print.applescript"
rm "/tmp/Auto Print.applescript"

print_status "$GREEN" "✅ AppleScript created and compiled"

# Create a simple test script
cat > "$WATCHED_FOLDER/test-print.sh" << 'EOF'
#!/bin/bash
# Test script for the watched folder
echo "Testing watched folder auto-print..."

# Create a test PDF
cat > /tmp/test-print.txt << 'TXT'
Test Print Document
==================

This is a test document for the watched folder auto-print system.

Date: $(date)
Time: $(date +%H:%M:%S)

If you can see this printed, the watched folder system is working correctly!
TXT

# Convert to PDF
textutil -convert pdf /tmp/test-print.txt -output "$HOME/IncomingPrints/test-print.pdf"

echo "Test PDF created. Check if it prints automatically!"
echo "If it doesn't print, check the print-log.txt file for errors."
EOF

chmod +x "$WATCHED_FOLDER/test-print.sh"

print_status "$GREEN" "✅ Test script created"

# Instructions for setting up Folder Actions
print_status "$BLUE" "📋 Next steps to complete setup:"
echo ""
print_status "$YELLOW" "1. Open Folder Actions Setup:"
print_status "$YELLOW" "   - Press Cmd+Space, type 'Folder Actions Setup', press Enter"
print_status "$YELLOW" "   - Or: System Preferences → Shortcuts → Services → Folder Actions"
echo ""
print_status "$YELLOW" "2. Attach the script to the folder:"
print_status "$YELLOW" "   - Click the '+' button"
print_status "$YELLOW" "   - Navigate to: $WATCHED_FOLDER"
print_status "$YELLOW" "   - Select the folder and click 'Attach'"
print_status "$YELLOW" "   - Choose: 'Auto Print.scpt' from the list"
echo ""
print_status "$YELLOW" "3. Test the setup:"
print_status "$YELLOW" "   - Run: $WATCHED_FOLDER/test-print.sh"
print_status "$YELLOW" "   - Or manually drop a PDF into $WATCHED_FOLDER"
echo ""
print_status "$YELLOW" "4. Optional - Prevent iMac from sleeping:"
print_status "$YELLOW" "   - System Settings → Displays & Energy → Prevent automatic sleeping on power adapter"

print_status "$GREEN" "✅ iMac setup script completed!"
print_status "$BLUE" "📁 Watched folder: $WATCHED_FOLDER"
print_status "$BLUE" "📝 AppleScript: $SCRIPT_PATH"




