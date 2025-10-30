#!/bin/bash

# Photo Portfolio Stop Script
# This script stops the photo portfolio server and verifies it's stopped

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_PORT=3000

echo -e "${BLUE}Stopping Photo Portfolio Server...${NC}"

# Check if server is running
if ps aux | grep -v grep | grep "node server.js" >/dev/null; then
    echo -e "${BLUE}Found running Node.js server process${NC}"
    
    # Get process ID
    PID=$(ps aux | grep 'node server.js' | grep -v grep | awk '{print $2}')
    echo -e "${BLUE}Stopping process ID: $PID${NC}"
    
    # Kill the process
    sudo pkill -f "node server.js"
    sleep 3
    
    # Check if process is still running
    if ps aux | grep -v grep | grep "node server.js" >/dev/null; then
        echo -e "${YELLOW}Process still running, forcing kill...${NC}"
        sudo pkill -9 -f "node server.js"
        sleep 2
    fi
    
    # Final check
    if ps aux | grep -v grep | grep "node server.js" >/dev/null; then
        echo -e "${RED}✗ Failed to stop server${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Server stopped successfully${NC}"
    fi
else
    echo -e "${YELLOW}No Node.js server process found${NC}"
fi

# Check if port is free
if sudo lsof -i :$SERVER_PORT >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Port $SERVER_PORT is still in use${NC}"
    echo -e "${BLUE}Processes using port $SERVER_PORT:${NC}"
    sudo lsof -i :$SERVER_PORT
else
    echo -e "${GREEN}✓ Port $SERVER_PORT is now free${NC}"
fi

echo -e "${GREEN}Photo Portfolio stop complete!${NC}" 