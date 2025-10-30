#!/bin/bash

# Pi5 Photo Portfolio Complete Restart Script
# This script performs a complete restart of the photo portfolio web app on Pi5
# It stops all processes, cleans up, and starts fresh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PI5_HOST="ian@192.168.50.243"
PI5_PROJECT_DIR="/home/ian/photo-portfolio"
SERVER_PORT=3000
LOG_FILE="$PI5_PROJECT_DIR/server.log"

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  Pi5 Photo Portfolio Complete Restart${NC}"
echo -e "${PURPLE}========================================${NC}"
echo

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

# Function to check Pi5 connectivity
check_pi5_connection() {
    echo -e "${BLUE}Checking Pi5 connectivity...${NC}"
    if ssh -o ConnectTimeout=10 "$PI5_HOST" "echo 'Pi5 is reachable'" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Pi5 is reachable${NC}"
        return 0
    else
        echo -e "${RED}✗ Cannot connect to Pi5 at $PI5_HOST${NC}"
        echo -e "${YELLOW}Please check:${NC}"
        echo -e "${YELLOW}  - Pi5 is powered on${NC}"
        echo -e "${YELLOW}  - Network connection${NC}"
        echo -e "${YELLOW}  - SSH key authentication${NC}"
        return 1
    fi
}

# Function to check project directory
check_project_directory() {
    echo -e "${BLUE}Checking project directory on Pi5...${NC}"
    if ssh "$PI5_HOST" "[ -d '$PI5_PROJECT_DIR' ]"; then
        echo -e "${GREEN}✓ Project directory exists: $PI5_PROJECT_DIR${NC}"
        return 0
    else
        echo -e "${RED}✗ Project directory not found: $PI5_PROJECT_DIR${NC}"
        return 1
    fi
}

# Function to check Node.js installation
check_nodejs() {
    echo -e "${BLUE}Checking Node.js installation on Pi5...${NC}"
    if ssh "$PI5_HOST" "node --version" >/dev/null 2>&1; then
        local node_version=$(ssh "$PI5_HOST" "node --version")
        echo -e "${GREEN}✓ Node.js is installed: $node_version${NC}"
        return 0
    else
        echo -e "${RED}✗ Node.js is not installed on Pi5${NC}"
        return 1
    fi
}

# Function to check npm dependencies
check_dependencies() {
    echo -e "${BLUE}Checking npm dependencies on Pi5...${NC}"
    if ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && [ -d 'node_modules' ]"; then
        echo -e "${GREEN}✓ node_modules directory exists${NC}"
        
        # Check if package.json exists
        if ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && [ -f 'package.json' ]"; then
            echo -e "${GREEN}✓ package.json exists${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ package.json not found${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ node_modules directory not found${NC}"
        return 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${BLUE}Installing npm dependencies on Pi5...${NC}"
    if ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && npm install"; then
        echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to install dependencies${NC}"
        return 1
    fi
}

# Function to stop all processes
stop_processes() {
    echo -e "${BLUE}Step 1: Stopping all photo portfolio processes...${NC}"
    
    # Kill Node.js processes
    echo -e "${BLUE}Stopping Node.js processes...${NC}"
    ssh "$PI5_HOST" "sudo pkill -f 'node server.js'" 2>/dev/null
    ssh "$PI5_HOST" "sudo pkill -f 'node.*photo-portfolio'" 2>/dev/null
    
    # Wait for processes to stop
    sleep 3
    
    # Force kill if still running
    if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'node server.js'" >/dev/null 2>&1; then
        echo -e "${YELLOW}Force killing remaining processes...${NC}"
        ssh "$PI5_HOST" "sudo pkill -9 -f 'node server.js'"
        sleep 2
    fi
    
    # Check if port is free
    if ssh "$PI5_HOST" "sudo lsof -i :$SERVER_PORT" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Port $SERVER_PORT is still in use${NC}"
        echo -e "${BLUE}Processes using port $SERVER_PORT:${NC}"
        ssh "$PI5_HOST" "sudo lsof -i :$SERVER_PORT"
    else
        echo -e "${GREEN}✓ Port $SERVER_PORT is now free${NC}"
    fi
}

# Function to clean up logs and temp files
cleanup() {
    echo -e "${BLUE}Step 2: Cleaning up logs and temp files...${NC}"
    
    # Clear old logs (keep last 100 lines)
    ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && tail -100 server.log > server.log.tmp && mv server.log.tmp server.log" 2>/dev/null
    
    # Clear npm cache
    ssh "$PI5_HOST" "npm cache clean --force" 2>/dev/null
    
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Function to start the server
start_server() {
    echo -e "${BLUE}Step 3: Starting photo portfolio server...${NC}"
    
    # Start the server
    ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && sudo NODE_ENV=production nohup node server.js > server.log 2>&1 &"
    
    # Wait for server to start
    sleep 5
    
    # Check if process is running
    if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'node server.js'" >/dev/null; then
        echo -e "${GREEN}✓ Node.js server process is running${NC}"
    else
        echo -e "${RED}✗ Failed to start Node.js server${NC}"
        echo -e "${BLUE}Checking server logs...${NC}"
        ssh "$PI5_HOST" "tail -20 '$PI5_PROJECT_DIR/server.log'"
        return 1
    fi
    
    # Check if server is responding
    if check_server; then
        echo -e "${GREEN}✓ Photo Portfolio server is running successfully!${NC}"
        return 0
    else
        echo -e "${RED}✗ Server failed to respond${NC}"
        echo -e "${BLUE}Checking server logs...${NC}"
        ssh "$PI5_HOST" "tail -20 '$PI5_PROJECT_DIR/server.log'"
        return 1
    fi
}

# Function to show server status
show_status() {
    echo -e "${BLUE}Step 4: Server Status${NC}"
    echo -e "${BLUE}===================${NC}"
    
    # Get process info
    local pid=$(ssh "$PI5_HOST" "ps aux | grep 'node server.js' | grep -v grep | awk '{print \$2}'" 2>/dev/null)
    if [ -n "$pid" ]; then
        echo -e "${GREEN}✓ Process ID: $pid${NC}"
    else
        echo -e "${RED}✗ No process found${NC}"
    fi
    
    # Show server URL
    echo -e "${BLUE}Server URL: http://192.168.50.243:$SERVER_PORT${NC}"
    echo -e "${BLUE}API endpoint: http://192.168.50.243:$SERVER_PORT/api/categories${NC}"
    
    # Test API endpoint
    echo -e "${BLUE}Testing API endpoint...${NC}"
    if ssh "$PI5_HOST" "curl -s http://localhost:$SERVER_PORT/api/categories | head -c 100" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ API is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠ API test failed${NC}"
    fi
    
    # Show log file location
    echo -e "${BLUE}Log file: $LOG_FILE${NC}"
    echo -e "${BLUE}To view logs: ssh $PI5_HOST 'tail -f $LOG_FILE'${NC}"
}

# Main execution
main() {
    # Pre-flight checks
    if ! check_pi5_connection; then
        exit 1
    fi
    
    if ! check_project_directory; then
        exit 1
    fi
    
    if ! check_nodejs; then
        exit 1
    fi
    
    # Check dependencies and install if needed
    if ! check_dependencies; then
        echo -e "${YELLOW}Dependencies missing, installing...${NC}"
        if ! install_dependencies; then
            echo -e "${RED}Failed to install dependencies. Exiting.${NC}"
            exit 1
        fi
    fi
    
    # Perform restart
    stop_processes
    cleanup
    start_server
    
    if [ $? -eq 0 ]; then
        show_status
        echo
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Photo Portfolio Restart Complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  Photo Portfolio Restart Failed!${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
