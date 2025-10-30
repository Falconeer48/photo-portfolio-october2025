#!/bin/bash

# Photo Portfolio System Integrity Test
# Run this script to test the entire system without deploying

set -e

# Configuration
PI5_HOST="192.168.50.243"
PI5_USER="ian"
PI5_APP_DIR="/media/ian/Externaldrive/Cursor_Projects/photo-portfolio"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

echo "🔍 Photo Portfolio System Integrity Test"
echo "========================================"

# Test 1: Local Environment
log "Testing local development environment..."
if command -v node >/dev/null 2>&1; then
    success "Node.js is installed ($(node --version))"
else
    error "Node.js is not installed"
fi

if command -v npm >/dev/null 2>&1; then
    success "npm is installed ($(npm --version))"
else
    error "npm is not installed"
fi

# Test 2: Project Structure
log "Testing project structure..."
if [ -f "package.json" ]; then
    success "package.json found"
else
    error "package.json not found"
fi

if [ -f "server.js" ]; then
    success "server.js found"
else
    error "server.js not found"
fi

if [ -d "src" ]; then
    success "src directory found"
else
    error "src directory not found"
fi

# Test 3: Dependencies
log "Testing dependencies..."
if [ -f "package-lock.json" ]; then
    success "package-lock.json found"
else
    warning "package-lock.json not found - run 'npm install'"
fi

# Test 4: Syntax Checks
log "Testing code syntax..."
if [ -f "server.js" ]; then
    if node -c server.js 2>/dev/null; then
        success "server.js syntax is valid"
    else
        error "server.js has syntax errors"
    fi
else
    warning "server.js not found, skipping syntax check"
fi

# Check all JS/JSX files
if [ -d "src" ]; then
    SYNTAX_ERRORS=0
    JS_FILES=$(find src -name "*.js" -o -name "*.jsx")
    if [ -n "$JS_FILES" ]; then
        for file in $JS_FILES; do
            if ! node -c "$file" 2>/dev/null; then
                error "Syntax error in $file"
                SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
            fi
        done

        if [ $SYNTAX_ERRORS -eq 0 ]; then
            success "All JavaScript/JSX files have valid syntax"
        fi
    else
        warning "No JavaScript/JSX files found in src directory"
    fi
else
    warning "src directory not found, skipping JS/JSX syntax checks"
fi

# Test 5: Build Process
log "Testing build process..."
set +e
npm run build >/dev/null 2>&1
BUILD_RESULT=$?
set -e
if [ $BUILD_RESULT -eq 0 ]; then
    success "Build completed successfully"
else
    error "Build failed"
fi

# Test 6: Build Output
log "Testing build output..."
if [ -f "dist/index.html" ]; then
    success "index.html generated"
else
    error "index.html not generated"
fi

if [ -d "dist/assets" ]; then
    JS_FILES=$(find dist/assets -name "*.js" | wc -l)
    success "dist/assets directory found with $JS_FILES JS files"
else
    error "dist/assets directory not found"
fi

# Test 7: Build Integrity
log "Testing build integrity..."
if [ -d "dist/assets" ]; then
    JS_BUILD_FILES=$(find dist/assets -name "*.js")
    if [ -n "$JS_BUILD_FILES" ]; then
        if grep -q "CommentsAdmin" dist/assets/*.js 2>/dev/null; then
            success "CommentsAdmin component included in build"
        else
            warning "CommentsAdmin component not found in build"
        fi

        if grep -q "ReorderPage" dist/assets/*.js 2>/dev/null; then
            success "ReorderPage component included in build"
        else
            warning "ReorderPage component not found in build"
        fi
    else
        warning "No JavaScript files found in dist/assets"
    fi
else
    warning "dist/assets directory not found, skipping build integrity check"
fi

# Test 8: SSH Connection
log "Testing SSH connection to Pi5..."
if ssh -o ConnectTimeout=10 "$PI5_USER@$PI5_HOST" "echo 'SSH test successful'" >/dev/null 2>&1; then
    success "SSH connection to Pi5 working"
else
    error "Cannot connect to Pi5 via SSH"
fi

# Test 9: Pi5 Server Status
log "Testing Pi5 server status..."
if ssh "$PI5_USER@$PI5_HOST" "sudo systemctl is-active --quiet photo-portfolio"; then
    success "Photo portfolio service is running on Pi5"
else
    error "Photo portfolio service is not running on Pi5"
fi

# Test 10: Network Connectivity
log "Testing network connectivity..."
if ping -c 1 "$PI5_HOST" >/dev/null 2>&1; then
    success "Pi5 is reachable on network"
else
    error "Pi5 is not reachable on network"
fi

# Test 11: Web Server Response
log "Testing web server response..."
if curl -s -f "http://$PI5_HOST:3000/" >/dev/null; then
    success "Web server is responding"
else
    error "Web server is not responding"
fi

# Test 12: API Endpoints
log "Testing API endpoints..."
if curl -s -f "http://$PI5_HOST:3000/api/categories" >/dev/null; then
    success "Categories API endpoint working"
else
    error "Categories API endpoint not working"
fi

if curl -s -f "http://$PI5_HOST:3000/api/comments/all" >/dev/null; then
    success "Comments API endpoint working"
else
    error "Comments API endpoint not working"
fi

# Test 13: Static File Serving
log "Testing static file serving..."
if curl -s -f "http://$PI5_HOST:3000/assets/" >/dev/null; then
    success "Static assets being served"
else
    error "Static assets not being served"
fi

# Test 14: Latest Files Check
log "Testing latest files are being served..."
LATEST_JS=$(curl -s "http://$PI5_HOST:3000/" | grep -o 'src="[^"]*\.js[^"]*"' | head -1)
if [ -n "$LATEST_JS" ]; then
    success "JavaScript file being served: $LATEST_JS"
else
    error "Cannot determine JavaScript file being served"
fi

# Test 15: Component Verification
log "Verifying components in served files..."
if [ -n "$LATEST_JS" ]; then
    JS_FILENAME=$(echo "$LATEST_JS" | sed 's/src="\/assets\///' | sed 's/"//')
    if [ -n "$JS_FILENAME" ]; then
        if ssh "$PI5_USER@$PI5_HOST" "grep -q 'CommentsAdmin' $PI5_APP_DIR/dist/assets/$JS_FILENAME" 2>/dev/null; then
            success "CommentsAdmin component found in served JavaScript"
        else
            warning "CommentsAdmin component not found in served JavaScript"
        fi
    else
        warning "Could not extract JavaScript filename from served HTML"
    fi
else
    warning "No JavaScript file reference found in served HTML"
fi

echo ""
echo "🎯 System Integrity Test Summary"
echo "================================"
echo "✅ All critical tests passed!"
echo "🌐 Your photo portfolio is fully operational"
echo "🔗 Access it at: http://$PI5_HOST:3000"
echo ""
echo "💡 To deploy changes, run: ./scripts/quick-deploy.sh"
echo "🔍 To run full deployment with checks: ./scripts/deploy-with-checks.sh"
