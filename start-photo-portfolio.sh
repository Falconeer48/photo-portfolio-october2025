#!/bin/bash

# Photo Portfolio Startup Script
# This script starts the photo portfolio server and verifies it's working

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/media/ian/Externaldrive/Cursor_Projects/photo-portfolio"
SERVER_PORT=3000
LOG_FILE="$PROJECT_DIR/server.log"

echo -e "${BLUE}Starting Photo Portfolio Server...${NC}"

# Function to check if a port is in use
check_port() {
    local port=$1
    if sudo lsof -i :$port >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to check if server is responding
check_server() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}Checking if server is responding...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:${SERVER_PORT}/api/categories" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Server is responding on port $SERVER_PORT${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}Attempt $attempt/$max_attempts: Server not ready yet...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}✗ Server failed to start after $max_attempts attempts${NC}"
    return 1
}

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR" || { echo -e "${RED}Error: Failed to cd to ${PROJECT_DIR}${NC}"; exit 1; }

# Kill any existing Node.js processes
echo -e "${BLUE}Stopping any existing Node.js processes...${NC}"
sudo pkill -f "node server.js" 2>/dev/null
sleep 3

# Check if port 3000 is free
if check_port $SERVER_PORT; then
    echo -e "${YELLOW}Warning: Port $SERVER_PORT is already in use${NC}"
    echo -e "${BLUE}Checking what's using the port...${NC}"
    sudo lsof -i :$SERVER_PORT
    echo -e "${YELLOW}If this is not our server, please stop the process using port $SERVER_PORT${NC}"
fi

# Start the server
echo -e "${BLUE}Starting Node.js server...${NC}"
sudo NODE_ENV=production nohup node server.js 2>&1 | tee -a "$LOG_FILE" >/dev/null &

# Wait a moment for the server to start
sleep 5

# Check if the process is running
if pgrep -f "node server.js" >/dev/null; then
    echo -e "${GREEN}✓ Node.js server process is running${NC}"
else
    echo -e "${RED}✗ Failed to start Node.js server${NC}"
    echo -e "${BLUE}Checking server logs...${NC}"
    tail -20 "$LOG_FILE"
    exit 1
fi

# Check if server is responding
if check_server; then
    echo -e "${GREEN}✓ Photo Portfolio server is running successfully!${NC}"
    echo -e "${BLUE}Server URL: http://localhost:$SERVER_PORT${NC}"
    echo -e "${BLUE}API endpoint: http://localhost:$SERVER_PORT/api/categories${NC}"
    
    # Show some basic info
    echo -e "${BLUE}Server information:${NC}"
    echo -e "  Process ID: $(pgrep -f 'node server.js' | head -n 1)"
    echo -e "  Log file: $LOG_FILE"
    echo -e "  Port: $SERVER_PORT"
    
    # Test API endpoint
    echo -e "${BLUE}Testing API endpoint...${NC}"
    if curl -s http://localhost:$SERVER_PORT/api/categories | head -c 100 >/dev/null; then
        echo -e "${GREEN}✓ API is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠ API test failed${NC}"
    fi
    
else
    echo -e "${RED}✗ Server failed to respond${NC}"
    echo -e "${BLUE}Checking server logs...${NC}"
    tail -20 "$LOG_FILE"
    exit 1
fi

echo -e "${GREEN}Photo Portfolio startup complete!${NC}"
echo -e "${BLUE}To view logs: tail -f $LOG_FILE${NC}"
echo -e "${BLUE}To stop server: sudo pkill -f 'node server.js'${NC}" 