#!/bin/bash

# Time Machine Status Checker for Raspberry Pi 5
# This script checks the status of all Time Machine related services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Time Machine Status Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Function to check service status
check_service() {
    local service=$1
    local status=$(systemctl is-active $service)
    
    if [ "$status" = "active" ]; then
        echo -e "${GREEN}✓${NC} $service is running"
    else
        echo -e "${RED}✗${NC} $service is not running (status: $status)"
    fi
}

# Function to check port
check_port() {
    local port=$1
    local protocol=$2
    local service_name=$3
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓${NC} $service_name port $port/$protocol is listening"
    else
        echo -e "${RED}✗${NC} $service_name port $port/$protocol is not listening"
    fi
}

# Check services
echo -e "${YELLOW}Checking services...${NC}"
check_service "smbd"
check_service "nmbd"
check_service "avahi-daemon"
check_service "netatalk"

echo

# Check ports
echo -e "${YELLOW}Checking ports...${NC}"
check_port "445" "tcp" "Samba"
check_port "548" "tcp" "AFP"
check_port "5353" "udp" "Bonjour/mDNS"

echo

# Check Time Machine directory
echo -e "${YELLOW}Checking Time Machine directory...${NC}"
if [ -d "/mnt/timemachine" ]; then
    echo -e "${GREEN}✓${NC} Time Machine directory exists"
    echo -e "${BLUE}  Path:${NC} /mnt/timemachine"
    echo -e "${BLUE}  Owner:${NC} $(ls -ld /mnt/timemachine | awk '{print $3":"$4}')"
    echo -e "${BLUE}  Permissions:${NC} $(ls -ld /mnt/timemachine | awk '{print $1}')"
    echo -e "${BLUE}  Size:${NC} $(du -sh /mnt/timemachine 2>/dev/null | cut -f1)"
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
    echo -e "${YELLOW}?${NC} pdbedit not available, cannot check Samba users"
fi

echo

# Check Bonjour services
echo -e "${YELLOW}Checking Bonjour services...${NC}"
if command -v avahi-browse &> /dev/null; then
    services=$(avahi-browse -t _smb._tcp 2>/dev/null | grep -c "raspberrypi\|timemachine" || echo "0")
    if [ $services -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Time Machine service advertised via Bonjour"
    else
        echo -e "${RED}✗${NC} Time Machine service not found in Bonjour"
    fi
else
    echo -e "${YELLOW}?${NC} avahi-browse not available, cannot check Bonjour services"
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

# Network connectivity test
echo -e "${YELLOW}Testing network connectivity...${NC}"
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Internet connectivity OK"
else
    echo -e "${RED}✗${NC} No internet connectivity"
fi

# Check local network
local_ip=$(hostname -I | awk '{print $1}')
if [ ! -z "$local_ip" ]; then
    echo -e "${GREEN}✓${NC} Local IP address: $local_ip"
else
    echo -e "${RED}✗${NC} No local IP address found"
fi

echo

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"

# Count issues
issues=0

# Check for critical issues
if ! systemctl is-active smbd &> /dev/null; then
    echo -e "${RED}Critical: Samba service is not running${NC}"
    ((issues++))
fi

if ! systemctl is-active avahi-daemon &> /dev/null; then
    echo -e "${RED}Critical: Avahi service is not running${NC}"
    ((issues++))
fi

if ! netstat -tlnp 2>/dev/null | grep -q ":445 "; then
    echo -e "${RED}Critical: Samba port 445 is not listening${NC}"
    ((issues++))
fi

if [ ! -d "/mnt/timemachine" ]; then
    echo -e "${RED}Critical: Time Machine directory does not exist${NC}"
    ((issues++))
fi

if [ $issues -eq 0 ]; then
    echo -e "${GREEN}All critical components are working correctly!${NC}"
    echo -e "${GREEN}Your Time Machine server should be discoverable by Macs on the network.${NC}"
else
    echo -e "${RED}$issues critical issue(s) found.${NC}"
    echo -e "${YELLOW}Please run the setup script or check the troubleshooting guide.${NC}"
fi

echo
echo -e "${BLUE}For troubleshooting, see: timemachine-troubleshooting.md${NC}"
