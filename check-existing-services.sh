#!/bin/bash

# Check existing Time Machine services on Raspberry Pi 5
# Run this script on your Pi to see what's already installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Pi 5 Time Machine Services Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script should be run as root (use sudo)${NC}"
   echo -e "${YELLOW}Continuing with limited checks...${NC}"
   echo
fi

# Function to check if package is installed
check_package() {
    local package=$1
    if dpkg -l | grep -q "^ii.*$package "; then
        echo -e "${GREEN}✓${NC} $package is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $package is NOT installed"
        return 1
    fi
}

# Function to check service status
check_service() {
    local service=$1
    if systemctl list-unit-files | grep -q "^$service.service"; then
        local status=$(systemctl is-active $service 2>/dev/null || echo "inactive")
        if [ "$status" = "active" ]; then
            echo -e "${GREEN}✓${NC} $service service is installed and running"
        elif [ "$status" = "inactive" ]; then
            echo -e "${YELLOW}⚠${NC} $service service is installed but not running"
        else
            echo -e "${RED}✗${NC} $service service is installed but has issues (status: $status)"
        fi
    else
        echo -e "${RED}✗${NC} $service service is NOT installed"
    fi
}

# Check required packages
echo -e "${YELLOW}Checking required packages...${NC}"
check_package "samba"
check_package "samba-common-bin"
check_package "avahi-daemon"
check_package "avahi-utils"
check_package "netatalk"
check_package "hfsprogs"
check_package "hfsutils"
check_package "hfsplus"
check_package "ntfs-3g"
check_package "exfat-fuse"
check_package "exfat-utils"
check_package "rsync"
check_package "cron"

echo

# Check services
echo -e "${YELLOW}Checking services...${NC}"
check_service "smbd"
check_service "nmbd"
check_service "avahi-daemon"
check_service "netatalk"

echo

# Check configuration files
echo -e "${YELLOW}Checking configuration files...${NC}"

if [ -f "/etc/samba/smb.conf" ]; then
    echo -e "${GREEN}✓${NC} Samba configuration exists"
    if grep -q "TimeMachine" /etc/samba/smb.conf; then
        echo -e "${GREEN}✓${NC} Time Machine share configured in Samba"
    else
        echo -e "${RED}✗${NC} Time Machine share NOT configured in Samba"
    fi
else
    echo -e "${RED}✗${NC} Samba configuration file missing"
fi

if [ -f "/etc/netatalk/afp.conf" ]; then
    echo -e "${GREEN}✓${NC} Netatalk configuration exists"
    if grep -q "TimeMachine" /etc/netatalk/afp.conf; then
        echo -e "${GREEN}✓${NC} Time Machine share configured in Netatalk"
    else
        echo -e "${RED}✗${NC} Time Machine share NOT configured in Netatalk"
    fi
else
    echo -e "${RED}✗${NC} Netatalk configuration file missing"
fi

if [ -f "/etc/avahi/services/samba.service" ]; then
    echo -e "${GREEN}✓${NC} Avahi Samba service file exists"
else
    echo -e "${RED}✗${NC} Avahi Samba service file missing"
fi

echo

# Check Time Machine directory
echo -e "${YELLOW}Checking Time Machine directory...${NC}"
if [ -d "/mnt/timemachine" ]; then
    echo -e "${GREEN}✓${NC} Time Machine directory exists"
    echo -e "${BLUE}  Path:${NC} /mnt/timemachine"
    echo -e "${BLUE}  Owner:${NC} $(ls -ld /mnt/timemachine | awk '{print $3":"$4}')"
    echo -e "${BLUE}  Permissions:${NC} $(ls -ld /mnt/timemachine | awk '{print $1}')"
    echo -e "${BLUE}  Size:${NC} $(du -sh /mnt/timemachine 2>/dev/null | cut -f1)"
    echo -e "${BLUE}  Contents:${NC}"
    ls -la /mnt/timemachine | head -10 | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} Time Machine directory does not exist"
fi

echo

# Check Samba users
echo -e "${YELLOW}Checking Samba users...${NC}"
if command -v pdbedit &> /dev/null; then
    users=$(pdbedit -L 2>/dev/null | wc -l)
    if [ $users -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Samba users configured ($users users)"
        echo -e "${BLUE}  Users:${NC}"
        pdbedit -L 2>/dev/null | sed 's/^/    /'
    else
        echo -e "${RED}✗${NC} No Samba users configured"
    fi
else
    echo -e "${RED}✗${NC} pdbedit command not available"
fi

echo

# Check ports
echo -e "${YELLOW}Checking listening ports...${NC}"
if netstat -tlnp 2>/dev/null | grep -q ":445 "; then
    echo -e "${GREEN}✓${NC} Port 445 (SMB) is listening"
else
    echo -e "${RED}✗${NC} Port 445 (SMB) is not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":548 "; then
    echo -e "${GREEN}✓${NC} Port 548 (AFP) is listening"
else
    echo -e "${RED}✗${NC} Port 548 (AFP) is not listening"
fi

if netstat -ulnp 2>/dev/null | grep -q ":5353 "; then
    echo -e "${GREEN}✓${NC} Port 5353 (Bonjour) is listening"
else
    echo -e "${RED}✗${NC} Port 5353 (Bonjour) is not listening"
fi

echo

# Check firewall
echo -e "${YELLOW}Checking firewall status...${NC}"
if command -v ufw &> /dev/null; then
    ufw_status=$(ufw status 2>/dev/null | head -1)
    echo -e "${BLUE}  UFW Status:${NC} $ufw_status"
    if ufw status | grep -q "445/tcp"; then
        echo -e "${GREEN}✓${NC} Port 445 is allowed in firewall"
    else
        echo -e "${RED}✗${NC} Port 445 is not allowed in firewall"
    fi
    if ufw status | grep -q "548/tcp"; then
        echo -e "${GREEN}✓${NC} Port 548 is allowed in firewall"
    else
        echo -e "${RED}✗${NC} Port 548 is not allowed in firewall"
    fi
else
    echo -e "${YELLOW}?${NC} UFW not installed or not available"
fi

echo

# Check recent logs for errors
echo -e "${YELLOW}Checking recent log entries...${NC}"

# Check Samba logs
if [ -f "/var/log/samba/log.smbd" ]; then
    recent_errors=$(tail -20 /var/log/samba/log.smbd | grep -i error | wc -l)
    if [ $recent_errors -gt 0 ]; then
        echo -e "${RED}✗${NC} Recent Samba errors found ($recent_errors)"
        echo -e "${BLUE}  Recent errors:${NC}"
        tail -20 /var/log/samba/log.smbd | grep -i error | tail -3 | sed 's/^/    /'
    else
        echo -e "${GREEN}✓${NC} No recent Samba errors"
    fi
else
    echo -e "${YELLOW}?${NC} Samba log file not found"
fi

# Check Netatalk logs
if [ -f "/var/log/netatalk.log" ]; then
    recent_errors=$(tail -20 /var/log/netatalk.log | grep -i error | wc -l)
    if [ $recent_errors -gt 0 ]; then
        echo -e "${RED}✗${NC} Recent Netatalk errors found ($recent_errors)"
        echo -e "${BLUE}  Recent errors:${NC}"
        tail -20 /var/log/netatalk.log | grep -i error | tail -3 | sed 's/^/    /'
    else
        echo -e "${GREEN}✓${NC} No recent Netatalk errors"
    fi
else
    echo -e "${YELLOW}?${NC} Netatalk log file not found"
fi

echo

# Check system info
echo -e "${YELLOW}System Information...${NC}"
echo -e "${BLUE}  Hostname:${NC} $(hostname)"
echo -e "${BLUE}  IP Address:${NC} $(hostname -I | awk '{print $1}')"
echo -e "${BLUE}  OS:${NC} $(lsb_release -d | cut -f2)"
echo -e "${BLUE}  Kernel:${NC} $(uname -r)"
echo -e "${BLUE}  Uptime:${NC} $(uptime -p)"

echo

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"

# Count installed packages
installed_packages=0
total_packages=12

for package in samba samba-common-bin avahi-daemon avahi-utils netatalk hfsprogs hfsutils hfsplus ntfs-3g exfat-fuse exfat-utils rsync cron; do
    if dpkg -l | grep -q "^ii.*$package "; then
        ((installed_packages++))
    fi
done

echo -e "${BLUE}Packages installed:${NC} $installed_packages/$total_packages"

# Check if Time Machine is fully configured
if [ -d "/mnt/timemachine" ] && [ -f "/etc/samba/smb.conf" ] && grep -q "TimeMachine" /etc/samba/smb.conf; then
    echo -e "${GREEN}Time Machine appears to be configured!${NC}"
    
    # Check if services are running
    running_services=0
    for service in smbd avahi-daemon; do
        if systemctl is-active $service &> /dev/null; then
            ((running_services++))
        fi
    done
    
    if [ $running_services -eq 2 ]; then
        echo -e "${GREEN}All critical services are running!${NC}"
        echo -e "${GREEN}Your Time Machine server should be working.${NC}"
    else
        echo -e "${YELLOW}Some services may need to be started.${NC}"
        echo -e "${YELLOW}Try: sudo systemctl restart smbd nmbd avahi-daemon netatalk${NC}"
    fi
else
    echo -e "${RED}Time Machine is not fully configured.${NC}"
    echo -e "${YELLOW}Run the setup script to complete the configuration.${NC}"
fi

echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. If services are not running: sudo systemctl restart smbd nmbd avahi-daemon netatalk"
echo "2. If configuration is missing: Run the timemachine-setup.sh script"
echo "3. Check your Mac's Time Machine preferences to see if the server appears"
echo "4. For troubleshooting, see: timemachine-troubleshooting.md"
