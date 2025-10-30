#!/bin/bash

# Photo Portfolio Status Script
# This script checks the status of the photo portfolio server

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

echo -e "${BLUE}=== Photo Portfolio Server Status ===${NC}"
echo

# Check if process is running
echo -e "${BLUE}Process Status:${NC}"
if ps aux | grep -v grep | grep "node server.js" >/dev/null; then
    PID=$(ps aux | grep 'node server.js' | grep -v grep | awk '{print $2}')
    USER=$(ps aux | grep 'node server.js' | grep -v grep | awk '{print $1}')
    CPU=$(ps aux | grep 'node server.js' | grep -v grep | awk '{print $3}')
    MEM=$(ps aux | grep 'node server.js' | grep -v grep | awk '{print $4}')
    echo -e "${GREEN}✓ Server is running${NC}"
    echo -e "  Process ID: $PID"
    echo -e "  User: $USER"
    echo -e "  CPU: ${CPU}%"
    echo -e "  Memory: ${MEM}%"
else
    echo -e "${RED}✗ Server is not running${NC}"
fi

echo

# Check port status
echo -e "${BLUE}Port Status:${NC}"
if sudo lsof -i :$SERVER_PORT >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Port $SERVER_PORT is in use${NC}"
    echo -e "${BLUE}Processes using port $SERVER_PORT:${NC}"
    sudo lsof -i :$SERVER_PORT
else
    echo -e "${YELLOW}⚠ Port $SERVER_PORT is not in use${NC}"
fi

echo

# Check if server is responding
echo -e "${BLUE}Server Response:${NC}"
if curl -s http://localhost:$SERVER_PORT/api/categories >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is responding to API requests${NC}"
    
    # Test API endpoint and show some data
    echo -e "${BLUE}API Test:${NC}"
    CATEGORIES_COUNT=$(curl -s http://localhost:$SERVER_PORT/api/categories | grep -o '"id"' | wc -l)
    echo -e "  Categories found: $CATEGORIES_COUNT"
    
    # Show a sample of categories
    echo -e "${BLUE}Sample categories:${NC}"
    curl -s http://localhost:$SERVER_PORT/api/categories | grep -o '"title":"[^"]*"' | head -5 | sed 's/"title":"/  - /' | sed 's/"$//'
    
else
    echo -e "${RED}✗ Server is not responding to API requests${NC}"
fi

echo

# Check log file
echo -e "${BLUE}Log File Status:${NC}"
if [ -f "$LOG_FILE" ]; then
    echo -e "${GREEN}✓ Log file exists: $LOG_FILE${NC}"
    LOG_SIZE=$(ls -lh "$LOG_FILE" | awk '{print $5}')
    echo -e "  Size: $LOG_SIZE"
    
    # Show last few log entries
    echo -e "${BLUE}Recent log entries:${NC}"
    tail -5 "$LOG_FILE" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠ Log file not found: $LOG_FILE${NC}"
fi

echo

# Check project directory
echo -e "${BLUE}Project Directory:${NC}"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}✓ Project directory exists: $PROJECT_DIR${NC}"
    
    # Check key files
    if [ -f "$PROJECT_DIR/server.js" ]; then
        echo -e "  ✓ server.js exists"
    else
        echo -e "  ✗ server.js missing"
    fi
    
    if [ -d "$PROJECT_DIR/dist" ]; then
        echo -e "  ✓ dist directory exists"
        DIST_FILES=$(ls "$PROJECT_DIR/dist/assets/" 2>/dev/null | wc -l)
        echo -e "  Assets files: $DIST_FILES"
    else
        echo -e "  ✗ dist directory missing"
    fi
    
else
    echo -e "${RED}✗ Project directory not found: $PROJECT_DIR${NC}"
fi

echo

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
if ps aux | grep -v grep | grep "node server.js" >/dev/null && curl -s http://localhost:$SERVER_PORT/api/categories >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Photo Portfolio server is running and healthy${NC}"
    echo -e "${BLUE}Access your portfolio at your usual URL${NC}"
else
    echo -e "${RED}✗ Photo Portfolio server needs attention${NC}"
    echo -e "${BLUE}Run ./start-photo-portfolio.sh to start the server${NC}"
fi

echo
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  Start server: ./start-photo-portfolio.sh"
echo -e "  Stop server:  ./stop-photo-portfolio.sh"
echo -e "  View logs:    tail -f $LOG_FILE" 