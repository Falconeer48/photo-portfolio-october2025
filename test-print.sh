#!/bin/bash

# Test script for print functionality
# This creates a test document and attempts to print it

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="$SCRIPT_DIR/test-print.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status "$BLUE" "🧪 Testing print functionality..."

# Create a test file
print_status "$BLUE" "📝 Creating test document..."
cat > "$TEST_FILE" << EOF
Test Print Document
==================

This is a test document created by the print test script.

Date: $(date)
Time: $(date +%H:%M:%S)
User: $(whoami)
Host: $(hostname)

If you can see this printed, the print-to-imac functionality is working correctly!

EOF

print_status "$GREEN" "✅ Test document created: $TEST_FILE"

# Test connection
print_status "$BLUE" "🔍 Testing connection..."
if "$SCRIPT_DIR/print-to-imac.sh" --check-connection; then
    print_status "$GREEN" "✅ Connection test passed"
else
    print_status "$RED" "❌ Connection test failed"
    exit 1
fi

# Test dry run
print_status "$BLUE" "🧪 Testing dry run..."
if "$SCRIPT_DIR/print-to-imac.sh" --dry-run "$TEST_FILE"; then
    print_status "$GREEN" "✅ Dry run test passed"
else
    print_status "$RED" "❌ Dry run test failed"
    exit 1
fi

# Ask if user wants to actually print
print_status "$YELLOW" "🤔 Do you want to actually print the test document?"
read -p "Print test document? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "$BLUE" "🖨️  Printing test document..."
    if "$SCRIPT_DIR/print.sh" "$TEST_FILE"; then
        print_status "$GREEN" "✅ Print test completed successfully!"
    else
        print_status "$RED" "❌ Print test failed"
        exit 1
    fi
else
    print_status "$YELLOW" "⏭️  Skipping actual print test"
fi

# Clean up
print_status "$BLUE" "🧹 Cleaning up test file..."
rm -f "$TEST_FILE"
print_status "$GREEN" "✅ Test completed!"

print_status "$BLUE" "📖 You can now use:"
print_status "$BLUE" "  ./print.sh <file>     - Print any file"
print_status "$BLUE" "  ./print.sh --help     - Show help"
print_status "$BLUE" "  ./print.sh --list-printers - List available printers"




