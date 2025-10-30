#!/bin/bash

# Minimal Time Machine Fix for Pi 5 (Samba Only)
# Your Time Machine is mostly working, just needs Bonjour discovery

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Time Machine Quick Fix (Samba Only)${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

echo -e "${GREEN}Great news! Your Time Machine is already mostly configured!${NC}"
echo -e "${YELLOW}Adding Bonjour discovery so your Mac can find it automatically...${NC}"
echo

# Create Avahi service file for Bonjour discovery
echo -e "${YELLOW}Creating Bonjour service file...${NC}"
mkdir -p /etc/avahi/services
cat > /etc/avahi/services/samba.service << EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h Time Machine</name>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
  <service>
    <type>_device-info._tcp</type>
    <port>0</port>
    <txt-record>model=RackMac</txt-record>
  </service>
</service-group>
EOF

# Restart Avahi to pick up the new service
echo -e "${YELLOW}Restarting Avahi service...${NC}"
systemctl restart avahi-daemon

# Configure firewall (if ufw is installed)
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Configuring firewall rules...${NC}"
    ufw allow 445/tcp
    ufw allow 5353/udp
fi

# Test Samba configuration
echo -e "${YELLOW}Testing Samba configuration...${NC}"
if testparm /etc/samba/smb.conf > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Samba configuration is valid"
else
    echo -e "${RED}✗${NC} Samba configuration has issues"
fi

# Display completion message
echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Time Machine Fix Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}Your Time Machine server is now ready!${NC}"
echo
echo -e "${BLUE}On your Mac:${NC}"
echo "1. Open System Preferences > Time Machine"
echo "2. Click 'Select Backup Disk'"
echo "3. Look for 'mypi5 Time Machine' in the list"
echo "4. Select it and enter:"
echo "   - Username: ian"
echo "   - Password: [your Pi password]"
echo
echo -e "${BLUE}Server details:${NC}"
echo "- Server name: mypi5 Time Machine"
echo "- Username: ian"
echo "- Backup location: /mnt/Externaldrive/timemachine"
echo "- Size limit: 1500G"
echo "- Protocol: SMB (port 445)"
echo
echo -e "${YELLOW}Note: It may take 1-2 minutes for your Mac to discover the server.${NC}"
echo -e "${YELLOW}If it doesn't appear, try restarting your Mac's network connection.${NC}"
echo
echo -e "${BLUE}Test commands:${NC}"
echo "- Check services: sudo systemctl status smbd avahi-daemon"
echo "- Test SMB: smbclient -L localhost -U ian"
echo "- Check Bonjour: avahi-browse -t _smb._tcp"
echo "- View Samba logs: sudo tail -f /var/log/samba/log.smbd"

