#!/bin/bash

# Photo Portfolio Restart Script
# This script stops and then starts the photo portfolio server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Photo Portfolio Restart ===${NC}"
echo

# Stop the server
echo -e "${BLUE}Step 1: Stopping server...${NC}"
if [ -f "./stop-photo-portfolio.sh" ]; then
    ./stop-photo-portfolio.sh
else
    echo -e "${RED}Error: stop-photo-portfolio.sh not found${NC}"
    exit 1
fi

echo

# Wait a moment
echo -e "${BLUE}Waiting 3 seconds...${NC}"
sleep 3

# Start the server
echo -e "${BLUE}Step 2: Starting server...${NC}"
if [ -f "./start-photo-portfolio.sh" ]; then
    ./start-photo-portfolio.sh
else
    echo -e "${RED}Error: start-photo-portfolio.sh not found${NC}"
    exit 1
fi

echo
echo -e "${GREEN}=== Restart Complete ===${NC}" 