#!/bin/bash

# Photo Portfolio Remote Startup Script (Mac)
# This script remotely starts the photo portfolio server on the Pi5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
PI5_PROJECT_DIR="/media/ian/Externaldrive/Cursor_Projects/photo-portfolio"
SERVER_PORT=3000

echo -e "${BLUE}Starting Photo Portfolio Server on Pi5...${NC}"

# Function to check if server is responding
check_server() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}Checking if server is responding...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if ssh "$PI5_HOST" "curl -s http://localhost:$SERVER_PORT/api/categories >/dev/null 2>&1"; then
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

# Kill any existing Node.js processes on Pi5
echo -e "${BLUE}Stopping any existing Node.js processes on Pi5...${NC}"
ssh "$PI5_HOST" "sudo pkill -f 'node server.js'" 2>/dev/null
sleep 3

# Check if port 3000 is free on Pi5
echo -e "${BLUE}Checking port status on Pi5...${NC}"
if ssh "$PI5_HOST" "sudo lsof -i :$SERVER_PORT >/dev/null 2>&1"; then
    echo -e "${YELLOW}Warning: Port $SERVER_PORT is already in use on Pi5${NC}"
    echo -e "${BLUE}Processes using port $SERVER_PORT on Pi5:${NC}"
    ssh "$PI5_HOST" "sudo lsof -i :$SERVER_PORT"
fi

# Start the server on Pi5
echo -e "${BLUE}Starting Node.js server on Pi5...${NC}"
ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && sudo NODE_ENV=production nohup node server.js > server.log 2>&1 &"

# Wait a moment for the server to start
sleep 5

# Check if the process is running on Pi5
if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'node server.js' >/dev/null"; then
    echo -e "${GREEN}✓ Node.js server process is running on Pi5${NC}"
else
    echo -e "${RED}✗ Failed to start Node.js server on Pi5${NC}"
    echo -e "${BLUE}Checking server logs on Pi5...${NC}"
    ssh "$PI5_HOST" "tail -20 '$PI5_PROJECT_DIR/server.log'"
    exit 1
fi

# Check if server is responding
if check_server; then
    echo -e "${GREEN}✓ Photo Portfolio server is running successfully on Pi5!${NC}"
    echo -e "${BLUE}Server URL: http://192.168.50.243:$SERVER_PORT${NC}"
    echo -e "${BLUE}API endpoint: http://192.168.50.243:$SERVER_PORT/api/categories${NC}"
    
    # Show some basic info
    echo -e "${BLUE}Server information:${NC}"
    echo -e "  Process ID: $(ssh "$PI5_HOST" "ps aux | grep 'node server.js' | grep -v grep | awk '{print \$2}'")"
    echo -e "  Log file: $PI5_PROJECT_DIR/server.log"
    echo -e "  Port: $SERVER_PORT"
    
    # Test API endpoint
    echo -e "${BLUE}Testing API endpoint...${NC}"
    if ssh "$PI5_HOST" "curl -s http://localhost:$SERVER_PORT/api/categories | head -c 100 >/dev/null"; then
        echo -e "${GREEN}✓ API is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠ API test failed${NC}"
    fi
    
else
    echo -e "${RED}✗ Server failed to respond${NC}"
    echo -e "${BLUE}Checking server logs on Pi5...${NC}"
    ssh "$PI5_HOST" "tail -20 '$PI5_PROJECT_DIR/server.log'"
    exit 1
fi

echo -e "${GREEN}Photo Portfolio startup complete!${NC}"
echo -e "${BLUE}To view logs: ssh $PI5_HOST 'tail -f $PI5_PROJECT_DIR/server.log'${NC}"
echo -e "${BLUE}To stop server: ssh $PI5_HOST 'sudo pkill -f \"node server.js\"'${NC}" 