#!/bin/bash

# Deploy Uppy.js Enhanced Photo Upload to Pi5
# This script deploys the enhanced upload functionality to your Pi5

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
UPLOAD_SERVER_PORT=3001
LOG_FILE="$PI5_PROJECT_DIR/uppy-server.log"

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  Deploying Uppy.js Enhanced Upload${NC}"
echo -e "${PURPLE}========================================${NC}"
echo

# Function to check Pi5 connectivity
check_pi5_connection() {
    echo -e "${BLUE}Checking Pi5 connectivity...${NC}"
    if ssh -o ConnectTimeout=10 "$PI5_HOST" "echo 'Pi5 is reachable'" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Pi5 is reachable${NC}"
        return 0
    else
        echo -e "${RED}✗ Cannot connect to Pi5 at $PI5_HOST${NC}"
        return 1
    fi
}

# Function to create upload directories
create_upload_directories() {
    echo -e "${BLUE}Creating upload directories...${NC}"
    
    ssh "$PI5_HOST" "mkdir -p $PI5_PROJECT_DIR/uploads" 2>/dev/null
    ssh "$PI5_HOST" "mkdir -p $PI5_PROJECT_DIR/chunks" 2>/dev/null
    ssh "$PI5_HOST" "mkdir -p $PI5_PROJECT_DIR/uppy" 2>/dev/null
    
    echo -e "${GREEN}✓ Upload directories created${NC}"
}

# Function to copy files to Pi5
copy_files() {
    echo -e "${BLUE}Copying Uppy.js files to Pi5...${NC}"
    
    # Copy the upload handler
    if scp uppy-upload-handler.cjs "$PI5_HOST:$PI5_PROJECT_DIR/"; then
        echo -e "${GREEN}✓ Upload handler copied${NC}"
    else
        echo -e "${RED}✗ Failed to copy upload handler${NC}"
        return 1
    fi
    
    # Copy the HTML interface
    if scp uppy-photo-upload.html "$PI5_HOST:$PI5_PROJECT_DIR/uppy/"; then
        echo -e "${GREEN}✓ HTML interface copied${NC}"
    else
        echo -e "${RED}✗ Failed to copy HTML interface${NC}"
        return 1
    fi
    
    # Copy package.json
    if scp uppy-package.json "$PI5_HOST:$PI5_PROJECT_DIR/package-uppy.json"; then
        echo -e "${GREEN}✓ Package configuration copied${NC}"
    else
        echo -e "${RED}✗ Failed to copy package configuration${NC}"
        return 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${BLUE}Installing Uppy.js dependencies...${NC}"
    
    # Install dependencies for the upload server
    if ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && npm install express multer cors --save"; then
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "${RED}✗ Failed to install dependencies${NC}"
        return 1
    fi
}

# Function to stop existing upload server
stop_upload_server() {
    echo -e "${BLUE}Stopping existing upload server...${NC}"
    
    # Kill any existing upload server processes
    ssh "$PI5_HOST" "sudo pkill -f 'uppy-upload-handler.cjs'" 2>/dev/null
    ssh "$PI5_HOST" "sudo pkill -f 'node.*3001'" 2>/dev/null
    
    # Wait for processes to stop
    sleep 3
    
    # Check if port is free
    if ssh "$PI5_HOST" "sudo lsof -i :$UPLOAD_SERVER_PORT" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Port $UPLOAD_SERVER_PORT is still in use${NC}"
        ssh "$PI5_HOST" "sudo lsof -i :$UPLOAD_SERVER_PORT"
    else
        echo -e "${GREEN}✓ Port $UPLOAD_SERVER_PORT is free${NC}"
    fi
}

# Function to start upload server
start_upload_server() {
    echo -e "${BLUE}Starting Uppy.js upload server...${NC}"
    
    # Start the upload server
    ssh "$PI5_HOST" "cd '$PI5_PROJECT_DIR' && nohup node uppy-upload-handler.cjs > $LOG_FILE 2>&1 &"
    
    # Wait for server to start
    sleep 5
    
    # Check if server is running
    if ssh "$PI5_HOST" "ps aux | grep -v grep | grep 'uppy-upload-handler.cjs'" >/dev/null; then
        echo -e "${GREEN}✓ Upload server is running${NC}"
    else
        echo -e "${RED}✗ Failed to start upload server${NC}"
        echo -e "${BLUE}Checking server logs...${NC}"
        ssh "$PI5_HOST" "tail -20 $LOG_FILE"
        return 1
    fi
    
    # Test server endpoint
    echo -e "${BLUE}Testing upload server...${NC}"
    if ssh "$PI5_HOST" "curl -s http://localhost:$UPLOAD_SERVER_PORT/api/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Upload server is responding${NC}"
    else
        echo -e "${YELLOW}⚠ Upload server may not be fully ready yet${NC}"
    fi
}

# Function to show deployment status
show_status() {
    echo -e "${BLUE}Deployment Status${NC}"
    echo -e "${BLUE}================${NC}"
    
    # Get process info
    local pid=$(ssh "$PI5_HOST" "ps aux | grep 'uppy-upload-handler.cjs' | grep -v grep | awk '{print \$2}'" 2>/dev/null)
    if [ -n "$pid" ]; then
        echo -e "${GREEN}✓ Upload Server PID: $pid${NC}"
    else
        echo -e "${RED}✗ Upload server not running${NC}"
    fi
    
    # Show URLs
    echo -e "${BLUE}Upload Interface: http://192.168.50.243:$UPLOAD_SERVER_PORT/uppy/uppy-photo-upload.html${NC}"
    echo -e "${BLUE}Upload API: http://192.168.50.243:$UPLOAD_SERVER_PORT/api/upload${NC}"
    echo -e "${BLUE}Health Check: http://192.168.50.243:$UPLOAD_SERVER_PORT/api/health${NC}"
    
    # Show log file location
    echo -e "${BLUE}Log file: $LOG_FILE${NC}"
    echo -e "${BLUE}To view logs: ssh $PI5_HOST 'tail -f $LOG_FILE'${NC}"
}

# Function to create systemd service (optional)
create_systemd_service() {
    echo -e "${BLUE}Creating systemd service for auto-start...${NC}"
    
    cat > /tmp/uppy-upload.service << EOF
[Unit]
Description=Uppy.js Upload Server
After=network.target

[Service]
Type=simple
User=ian
WorkingDirectory=$PI5_PROJECT_DIR
ExecStart=/usr/bin/node uppy-upload-handler.cjs
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    # Copy service file to Pi5
    scp /tmp/uppy-upload.service "$PI5_HOST:/tmp/"
    
    # Install service
    ssh "$PI5_HOST" "sudo mv /tmp/uppy-upload.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable uppy-upload.service"
    
    echo -e "${GREEN}✓ Systemd service created and enabled${NC}"
    echo -e "${BLUE}To start: sudo systemctl start uppy-upload${NC}"
    echo -e "${BLUE}To stop: sudo systemctl stop uppy-upload${NC}"
    
    # Clean up
    rm /tmp/uppy-upload.service
}

# Main execution
main() {
    # Pre-flight checks
    if ! check_pi5_connection; then
        exit 1
    fi
    
    # Create directories
    create_upload_directories
    
    # Copy files
    if ! copy_files; then
        echo -e "${RED}Failed to copy files. Exiting.${NC}"
        exit 1
    fi
    
    # Install dependencies
    if ! install_dependencies; then
        echo -e "${RED}Failed to install dependencies. Exiting.${NC}"
        exit 1
    fi
    
    # Stop existing server
    stop_upload_server
    
    # Start new server
    if ! start_upload_server; then
        echo -e "${RED}Failed to start upload server. Exiting.${NC}"
        exit 1
    fi
    
    # Show status
    show_status
    
    # Ask about systemd service
    echo
    echo -e "${YELLOW}Would you like to create a systemd service for auto-start? (y/n)${NC}"
    read -p "Enter choice: " choice
    
    if [[ $choice =~ ^[Yy]$ ]]; then
        create_systemd_service
    fi
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Uppy.js Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "${BLUE}1. Open: http://192.168.50.243:$UPLOAD_SERVER_PORT/uppy/uppy-photo-upload.html${NC}"
    echo -e "${BLUE}2. Test uploading photos with multi-connection support${NC}"
    echo -e "${BLUE}3. Monitor logs: ssh $PI5_HOST 'tail -f $LOG_FILE'${NC}"
}

# Run main function
main "$@"
