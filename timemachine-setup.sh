#!/bin/bash

# Apple Time Machine Setup for Raspberry Pi 5
# This script configures your Pi as a Time Machine backup destination

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
TIMEMACHINE_USER="timemachine"
TIMEMACHINE_GROUP="timemachine"
TIMEMACHINE_SHARE="/mnt/timemachine"
BACKUP_SIZE="500G"  # Adjust this based on your needs
MAC_USERNAME=""     # Will be prompted
MAC_PASSWORD=""     # Will be prompted

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Apple Time Machine Setup for Pi 5${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Update system packages
echo -e "${YELLOW}Updating system packages...${NC}"
apt update && apt upgrade -y

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt install -y \
    samba \
    samba-common-bin \
    avahi-daemon \
    avahi-utils \
    netatalk \
    hfsprogs \
    hfsutils \
    hfsplus \
    ntfs-3g \
    exfat-fuse \
    exfat-utils \
    rsync \
    cron

# Create Time Machine user and group
echo -e "${YELLOW}Creating Time Machine user and group...${NC}"
if ! getent group $TIMEMACHINE_GROUP > /dev/null 2>&1; then
    groupadd $TIMEMACHINE_GROUP
fi

if ! getent passwd $TIMEMACHINE_USER > /dev/null 2>&1; then
    useradd -r -g $TIMEMACHINE_GROUP -d $TIMEMACHINE_SHARE -s /bin/false $TIMEMACHINE_USER
fi

# Create Time Machine directory
echo -e "${YELLOW}Creating Time Machine directory...${NC}"
mkdir -p $TIMEMACHINE_SHARE
chown $TIMEMACHINE_USER:$TIMEMACHINE_GROUP $TIMEMACHINE_SHARE
chmod 755 $TIMEMACHINE_SHARE

# Prompt for Mac credentials
echo -e "${YELLOW}Enter your Mac's username for Time Machine access:${NC}"
read -p "Mac Username: " MAC_USERNAME
echo -e "${YELLOW}Enter your Mac's password:${NC}"
read -s -p "Mac Password: " MAC_PASSWORD
echo

# Add Mac user to Samba
echo -e "${YELLOW}Adding Mac user to Samba...${NC}"
(echo "$MAC_PASSWORD"; echo "$MAC_PASSWORD") | smbpasswd -a -s $MAC_USERNAME

# Configure Samba
echo -e "${YELLOW}Configuring Samba...${NC}"
cat > /etc/samba/smb.conf << EOF
[global]
   workgroup = WORKGROUP
   server string = Raspberry Pi Time Machine
   security = user
   map to guest = Bad User
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000
   syslog = 0
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes

[TimeMachine]
   comment = Time Machine Backup
   path = $TIMEMACHINE_SHARE
   valid users = $MAC_USERNAME
   list = yes
   read only = no
   writable = yes
   guest ok = no
   browseable = yes
   create mask = 0755
   directory mask = 0755
   vfs objects = catia fruit streams_xattr
   fruit:aapl = yes
   fruit:time machine = yes
   fruit:time machine max size = $BACKUP_SIZE
EOF

# Configure Avahi for Bonjour discovery
echo -e "${YELLOW}Configuring Avahi for Bonjour discovery...${NC}"
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

# Configure Netatalk for AFP support
echo -e "${YELLOW}Configuring Netatalk for AFP support...${NC}"
cat > /etc/netatalk/afp.conf << EOF
[Global]
; Global server settings
log level = default:info
log file = /var/log/netatalk.log
hostname = raspberrypi-timemachine
uam list = uams_guest.so,uams_dhx.so,uams_dhx2.so
zeroconf = yes

[TimeMachine]
path = $TIMEMACHINE_SHARE
time machine = yes
valid users = $MAC_USERNAME
EOF

# Create backup cleanup script
echo -e "${YELLOW}Creating backup cleanup script...${NC}"
cat > /usr/local/bin/timemachine-cleanup.sh << 'EOF'
#!/bin/bash
# Time Machine cleanup script
TIMEMACHINE_SHARE="/mnt/timemachine"
MAX_AGE_DAYS=30

# Remove backups older than MAX_AGE_DAYS
find $TIMEMACHINE_SHARE -name "*.sparsebundle" -type d -mtime +$MAX_AGE_DAYS -exec rm -rf {} \;

# Log cleanup activity
echo "$(date): Time Machine cleanup completed" >> /var/log/timemachine-cleanup.log
EOF

chmod +x /usr/local/bin/timemachine-cleanup.sh

# Add cleanup to crontab (run weekly)
echo -e "${YELLOW}Setting up automatic cleanup...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/timemachine-cleanup.sh") | crontab -

# Enable and start services
echo -e "${YELLOW}Enabling and starting services...${NC}"
systemctl enable smbd
systemctl enable nmbd
systemctl enable avahi-daemon
systemctl enable netatalk

systemctl restart smbd
systemctl restart nmbd
systemctl restart avahi-daemon
systemctl restart netatalk

# Create firewall rules (if ufw is installed)
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Configuring firewall rules...${NC}"
    ufw allow 445/tcp
    ufw allow 548/tcp
    ufw allow 5353/udp
fi

# Display completion message
echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Time Machine Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. On your Mac, open System Preferences > Time Machine"
echo "2. Click 'Select Backup Disk'"
echo "3. Look for 'raspberrypi-timemachine' or 'Time Machine' in the list"
echo "4. Select it and enter your Mac credentials when prompted"
echo
echo -e "${BLUE}Configuration details:${NC}"
echo "- Time Machine share: $TIMEMACHINE_SHARE"
echo "- Mac username: $MAC_USERNAME"
echo "- Backup size limit: $BACKUP_SIZE"
echo "- Services enabled: Samba, Avahi, Netatalk"
echo
echo -e "${BLUE}Useful commands:${NC}"
echo "- Check Samba status: systemctl status smbd"
echo "- Check Avahi status: systemctl status avahi-daemon"
echo "- Check Netatalk status: systemctl status netatalk"
echo "- View Samba logs: tail -f /var/log/samba/log.smbd"
echo "- View Netatalk logs: tail -f /var/log/netatalk.log"
echo
echo -e "${YELLOW}Note: It may take a few minutes for your Mac to discover the Time Machine server.${NC}"
echo -e "${YELLOW}If it doesn't appear, try restarting your Mac's network connection.${NC}"

