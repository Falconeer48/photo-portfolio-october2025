#!/bin/bash

# Photo Portfolio Deployment Script - Run from anywhere
# This script automatically navigates to the project directory and runs deployment

set -e

# Project directory
PROJECT_DIR="/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
    exit 1
}

echo "🚀 Photo Portfolio Deployment"
echo "============================="

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    error "Project directory not found: $PROJECT_DIR"
fi

# Navigate to project directory
log "Navigating to project directory..."
cd "$PROJECT_DIR"

# Check if we're in the right place
if [ ! -f "package.json" ] || [ ! -f "deploy.sh" ]; then
    error "Not in photo portfolio project directory"
fi

success "Found photo portfolio project"

# Run the deployment
log "Starting deployment..."
./deploy.sh 