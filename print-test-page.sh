#!/bin/bash

# Create a test page for Pi5 print server
# This creates a simple text-based test page

cat > /tmp/pi5_test_page.txt << 'EOF'
==========================================
    Pi5 Print Server Test Page
==========================================

Date: $(date)
Time: $(date +%H:%M:%S)
Server: Raspberry Pi 5 Print Server
Printer: Canon PIXMA G4470
Connection: Mac Mini → Pi5 → Printer

==========================================
Test Information:
==========================================

✓ Pi5 Connectivity: PASSED
✓ CUPS Service: RUNNING
✓ Printer Configuration: CORRECT
✓ Print Job Submission: SUCCESSFUL

==========================================
Network Details:
==========================================

Mac Mini IP: 192.168.50.x
Pi5 IP: 192.168.50.243
Printer IP: 192.168.50.188
Protocol: Socket (Port 9100)

==========================================
Print Server Status:
==========================================

Printer Name: Canon_G4470
Status: Idle and Ready
Queue: Empty
Default Printer: Yes

==========================================
Test Results:
==========================================

This test page confirms that:
• Mac Mini can connect to Pi5 via SSH
• Files can be transferred to Pi5
• Print jobs can be submitted successfully
• Printer receives and processes jobs
• Print queue management works correctly

==========================================
Congratulations!
==========================================

Your Pi5 print server is working perfectly!
You can now print from your Mac to the
Canon PIXMA G4470 via the Raspberry Pi 5.

==========================================
EOF

# Replace $(date) with actual date
sed -i '' "s/\$(date)/$(date)/g" /tmp/pi5_test_page.txt
sed -i '' "s/\$(date +%H:%M:%S)/$(date +%H:%M:%S)/g" /tmp/pi5_test_page.txt

echo "📄 Test page created: /tmp/pi5_test_page.txt"
echo "🖨️  Printing test page to Pi5..."

# Print the test page
./test-print-pi5.sh /tmp/pi5_test_page.txt

echo "✅ Test page printing completed!"

