#!/bin/bash

# Photo Portfolio Remote Stop Script (Mac)
# This script remotely stops the photo portfolio server on the Pi5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
SERVER_PORT=3000

echo -e "${BLUE}Stopping Photo Portfolio Server on Pi5...${NC}"

# Check if server is running on Pi5
if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'node server.js' >/dev/null"; then
    echo -e "${BLUE}Found running Node.js server process on Pi5${NC}"
    
    # Get process ID
    PID=$(ssh "$PI5_HOST" "ps aux | grep 'node server.js' | grep -v grep | awk '{print \$2}'")
    echo -e "${BLUE}Stopping process ID: $PID${NC}"
    
    # Kill the process
    ssh "$PI5_HOST" "sudo pkill -f 'node server.js'"
    sleep 3
    
    # Check if process is still running
    if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'node server.js' >/dev/null"; then
        echo -e "${YELLOW}Process still running, forcing kill...${NC}"
        ssh "$PI5_HOST" "sudo pkill -9 -f 'node server.js'"
        sleep 2
    fi
    
    # Final check
    if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'node server.js' >/dev/null"; then
        echo -e "${RED}✗ Failed to stop server on Pi5${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Server stopped successfully on Pi5${NC}"
    fi
else
    echo -e "${YELLOW}No Node.js server process found on Pi5${NC}"
fi

# Check if port is free on Pi5
if ssh "$PI5_HOST" "sudo lsof -i :$SERVER_PORT >/dev/null 2>&1"; then
    echo -e "${YELLOW}Warning: Port $SERVER_PORT is still in use on Pi5${NC}"
    echo -e "${BLUE}Processes using port $SERVER_PORT on Pi5:${NC}"
    ssh "$PI5_HOST" "sudo lsof -i :$SERVER_PORT"
else
    echo -e "${GREEN}✓ Port $SERVER_PORT is now free on Pi5${NC}"
fi

echo -e "${GREEN}Photo Portfolio stop complete!${NC}" 