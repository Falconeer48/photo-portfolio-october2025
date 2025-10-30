#!/bin/bash

# Quick Deploy Script for Photo Portfolio
# Runs essential checks and deploys quickly

set -e

# Configuration
PI5_HOST="192.168.50.243"
PI5_USER="ian"
PI5_APP_DIR="/media/ian/Externaldrive/Cursor_Projects/photo-portfolio"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

echo "🚀 Quick Deploy - Photo Portfolio"

# Quick syntax check
log "Checking syntax..."
if ! node -c server.js 2>/dev/null; then
    error "Syntax error in server.js"
fi

# Build
log "Building application..."
npm run build

# Check build
if [ ! -f "dist/index.html" ]; then
    error "Build failed"
fi

# Deploy
log "Deploying to Pi5..."
rsync -avz --delete dist/ "$PI5_USER@$PI5_HOST:$PI5_APP_DIR/dist/"
rsync -avz server.js "$PI5_USER@$PI5_HOST:$PI5_APP_DIR/"

# Restart server
log "Restarting server..."
ssh "$PI5_USER@$PI5_HOST" "sudo systemctl restart photo-portfolio"
sleep 3

# Quick test
log "Testing deployment..."
if curl -s -f "http://$PI5_HOST:3000/" >/dev/null; then
    success "Deployment successful!"
    echo "🌐 Your portfolio is live at: http://$PI5_HOST:3000"
else
    error "Server not responding after deployment"
fi 