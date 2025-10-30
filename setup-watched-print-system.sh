#!/bin/bash

# Complete setup script for watched folder printing system
# This sets up both Mac Mini and iMac components

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

print_status "$BLUE" "🖨️  Setting up Watched Folder Printing System"
echo ""

# Check if we're on Mac Mini or iMac
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" == *"mini"* ]] || [[ "$HOSTNAME" == *"Mini"* ]]; then
    MACHINE_TYPE="Mac Mini"
else
    MACHINE_TYPE="iMac"
fi

print_status "$BLUE" "🖥️  Detected: $MACHINE_TYPE"

if [[ "$MACHINE_TYPE" == "Mac Mini" ]]; then
    print_status "$BLUE" "📋 Setting up Mac Mini components..."
    
    # 1. Check SSH key setup
    print_status "$BLUE" "🔑 Checking SSH key setup..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes iancook@Ians-iMac.local "echo 'SSH test'" >/dev/null 2>&1; then
        print_status "$GREEN" "✅ SSH connection to iMac working"
    else
        print_status "$YELLOW" "⚠️  SSH connection not working. Setting up SSH key..."
        print_status "$YELLOW" "💡 Run these commands:"
        print_status "$YELLOW" "   ssh-keygen -t ed25519 -C 'mini→imac'"
        print_status "$YELLOW" "   ssh-copy-id iancook@Ians-iMac.local"
        print_status "$YELLOW" "   Then run this script again"
        exit 1
    fi
    
    # 2. Create Quick Action
    print_status "$BLUE" "🔧 Creating Quick Action for Finder..."
    ./create-quick-action.sh
    
    # 3. Create a simple test
    print_status "$BLUE" "🧪 Creating test script..."
    cat > test-watched-print.sh << 'EOF'
#!/bin/bash
# Test the watched folder printing system

echo "🧪 Testing watched folder printing system..."

# Create a test PDF
cat > /tmp/test-document.txt << 'TXT'
Test Print Document
==================

This is a test of the watched folder printing system.

Date: $(date)
Time: $(date +%H:%M:%S)
Machine: $(hostname)

If you can see this printed, the system is working correctly!

The watched folder system allows you to:
1. Print from any app by saving as PDF
2. Right-click the PDF in Finder
3. Select "Quick Actions" → "Send to iMac Printer"
4. The file is automatically sent to iMac and printed

This is much more convenient than the previous method!
TXT

# Convert to PDF
textutil -convert pdf /tmp/test-document.txt -output ~/Desktop/test-watched-print.pdf

echo "✅ Test PDF created: ~/Desktop/test-watched-print.pdf"
echo ""
echo "📋 To test the system:"
echo "1. Right-click the PDF in Finder"
echo "2. Select 'Quick Actions' → 'Send to iMac Printer'"
echo "3. Check if it prints on your iMac"
echo ""
echo "Or run: ./send-to-imac-printer.sh ~/Desktop/test-watched-print.pdf"
EOF

    chmod +x test-watched-print.sh
    print_status "$GREEN" "✅ Mac Mini setup completed!"
    
else
    print_status "$BLUE" "📋 Setting up iMac components..."
    
    # Run the iMac setup script
    ./setup-imac-watched-folder.sh
    
    print_status "$GREEN" "✅ iMac setup completed!"
fi

print_status "$BLUE" "📖 Usage Instructions:"
echo ""
print_status "$YELLOW" "From any app (Word, Notes, etc.):"
print_status "$YELLOW" "1. Choose File → Print"
print_status "$YELLOW" "2. Click 'PDF' button (bottom left)"
print_status "$YELLOW" "3. Select 'Save as PDF...'"
print_status "$YELLOW" "4. Save the PDF anywhere"
print_status "$YELLOW" "5. Right-click the PDF in Finder"
print_status "$YELLOW" "6. Select 'Quick Actions' → 'Send to iMac Printer'"
print_status "$YELLOW" "7. The file will be sent to iMac and printed automatically!"
echo ""
print_status "$YELLOW" "Or use the command line:"
print_status "$YELLOW" "  ./send-to-imac-printer.sh document.pdf"
echo ""
print_status "$GREEN" "🎉 Setup completed! The system is ready to use."




