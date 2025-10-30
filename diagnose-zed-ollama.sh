#!/bin/bash

# Zed + Ollama Connection Diagnostic Script
# Diagnoses why Zed might not be connecting to local Ollama models

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}🔍 Zed + Ollama Connection Diagnostics${NC}"
echo "========================================"
echo ""

# 1. Check Ollama Service
echo -e "${BLUE}[1/8] Checking Ollama Service...${NC}"
if pgrep -x "ollama" > /dev/null; then
    echo -e "${GREEN}✅ Ollama process is running${NC}"
    ps aux | grep ollama | grep -v grep | head -3
else
    echo -e "${RED}❌ Ollama process NOT running${NC}"
    echo "Start it with: ollama serve"
fi
echo ""

# 2. Check Ollama API
echo -e "${BLUE}[2/8] Checking Ollama API Endpoint...${NC}"
if curl -s -f "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama API is responding${NC}"
else
    echo -e "${RED}❌ Ollama API is NOT responding${NC}"
    echo "Try: ollama serve"
fi
echo ""

# 3. List Available Models
echo -e "${BLUE}[3/8] Available Ollama Models...${NC}"
ollama list
echo ""

# 4. Test Model Response
echo -e "${BLUE}[4/8] Testing Model Response...${NC}"
echo "Sending test prompt to llama3.2:3b..."
RESPONSE=$(echo "Reply with just: OK" | ollama run llama3.2:3b 2>&1 | head -5)
if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✅ Model responded:${NC}"
    echo "$RESPONSE"
else
    echo -e "${RED}❌ No response from model${NC}"
fi
echo ""

# 5. Check Zed Installation
echo -e "${BLUE}[5/8] Checking Zed Installation...${NC}"
if [ -d "/Applications/Zed.app" ]; then
    echo -e "${GREEN}✅ Zed found at: /Applications/Zed.app${NC}"
    ZED_VERSION=$(/Applications/Zed.app/Contents/MacOS/zed --version 2>/dev/null || echo "Unknown")
    echo "   Version: $ZED_VERSION"
else
    echo -e "${RED}❌ Zed not found in /Applications${NC}"
fi
echo ""

# 6. Check Zed Configuration
echo -e "${BLUE}[6/8] Checking Zed Configuration...${NC}"
ZED_CONFIG="$HOME/Library/Application Support/Zed/settings.json"
if [ -f "$ZED_CONFIG" ]; then
    echo -e "${GREEN}✅ Settings file exists${NC}"
    echo "   Location: $ZED_CONFIG"

    # Check for Ollama configuration
    if grep -q '"ollama"' "$ZED_CONFIG"; then
        echo -e "${GREEN}✅ Ollama provider configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Ollama provider NOT found in settings${NC}"
    fi

    if grep -q '"localhost:11434"' "$ZED_CONFIG"; then
        echo -e "${GREEN}✅ Ollama API URL configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Ollama API URL not found${NC}"
    fi

    # Extract default model
    if grep -q '"default_model"' "$ZED_CONFIG"; then
        DEFAULT_MODEL=$(grep -A2 '"default_model"' "$ZED_CONFIG" | grep '"model"' | cut -d'"' -f4)
        echo -e "${GREEN}✅ Default model: $DEFAULT_MODEL${NC}"
    else
        echo -e "${YELLOW}⚠️  No default model configured${NC}"
    fi
else
    echo -e "${RED}❌ Zed settings file NOT found${NC}"
    echo "   Expected at: $ZED_CONFIG"
fi
echo ""

# 7. Check for API Keys (internet models)
echo -e "${BLUE}[7/8] Checking for Internet-based API Keys...${NC}"
if [ -f "$ZED_CONFIG" ]; then
    if grep -q "anthropic\|openai\|api_key" "$ZED_CONFIG"; then
        echo -e "${YELLOW}⚠️  WARNING: Found API key configuration in settings${NC}"
        echo "   This means Zed MIGHT use internet-based models as fallback"
        echo "   Keys found for:"
        grep -o '"anthropic"\|"openai"\|"api_key"' "$ZED_CONFIG" | sort -u | sed 's/^/     - /'
    else
        echo -e "${GREEN}✅ No internet API keys found${NC}"
        echo "   Zed should only use local models"
    fi
else
    echo -e "${YELLOW}⚠️  Cannot check - settings file not found${NC}"
fi
echo ""

# 8. Test Ollama API Directly
echo -e "${BLUE}[8/8] Testing Ollama API Format...${NC}"
echo "Testing API with JSON request..."
TEST_RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "prompt": "Say test", "stream": false}' \
  2>&1 | head -20)

if echo "$TEST_RESPONSE" | grep -q "response"; then
    echo -e "${GREEN}✅ Ollama API responding correctly to JSON requests${NC}"
else
    echo -e "${YELLOW}⚠️  API response format unexpected${NC}"
    echo "Response preview:"
    echo "$TEST_RESPONSE" | head -5
fi
echo ""

# Summary and Recommendations
echo -e "${PURPLE}📋 Summary & Recommendations${NC}"
echo "================================"
echo ""

OLLAMA_RUNNING=$(pgrep -x "ollama" > /dev/null && echo "yes" || echo "no")
API_WORKING=$(curl -s -f "http://localhost:11434/api/tags" > /dev/null 2>&1 && echo "yes" || echo "no")
ZED_INSTALLED=$([ -d "/Applications/Zed.app" ] && echo "yes" || echo "no")
CONFIG_EXISTS=$([ -f "$ZED_CONFIG" ] && echo "yes" || echo "no")

if [ "$OLLAMA_RUNNING" = "yes" ] && [ "$API_WORKING" = "yes" ] && [ "$ZED_INSTALLED" = "yes" ] && [ "$CONFIG_EXISTS" = "yes" ]; then
    echo -e "${GREEN}✅ All basic components are working${NC}"
    echo ""
    echo -e "${YELLOW}If Zed still doesn't respond with local models:${NC}"
    echo ""
    echo "1. Zed's Ollama integration may be experimental/incomplete"
    echo "2. Try restarting Zed completely (Cmd+Q, then reopen)"
    echo "3. Check Zed's console for errors:"
    echo "   - In Zed: Help → Toggle Developer Tools → Console"
    echo "4. Verify in Zed's Assistant panel that Ollama models appear"
    echo "5. Try selecting a different model from the dropdown"
    echo ""
    echo -e "${CYAN}Alternative: Use Command-Line AI (100% guaranteed local):${NC}"
    echo "   ./ollama-helper.sh chat"
    echo "   ./ollama-helper.sh review yourfile.js"
    echo "   ollama run codellama:13b"
else
    echo -e "${RED}⚠️  Some components are not working properly:${NC}"
    echo ""
    [ "$OLLAMA_RUNNING" = "no" ] && echo "❌ Ollama not running - Run: ollama serve"
    [ "$API_WORKING" = "no" ] && echo "❌ Ollama API not responding - Restart Ollama"
    [ "$ZED_INSTALLED" = "no" ] && echo "❌ Zed not installed - Install from: https://zed.dev"
    [ "$CONFIG_EXISTS" = "no" ] && echo "❌ Zed config missing - Run: ./setup-zed-local-ai.sh"
fi

echo ""
echo -e "${CYAN}💡 Key Point About Privacy:${NC}"
echo "If local models aren't responding in Zed and you haven't configured"
echo "any API keys, Zed will simply show an error - it WON'T silently use"
echo "internet models. Check the settings file to be sure:"
echo ""
echo "   cat \"$ZED_CONFIG\" | grep -i \"api_key\|anthropic\|openai\""
echo ""
echo "If that returns nothing, you're safe - no internet models configured."
echo ""

# Generate report file
REPORT_FILE="zed_ollama_diagnostic_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Zed + Ollama Diagnostic Report"
    echo "Generated: $(date)"
    echo "=============================="
    echo ""
    echo "Ollama Running: $OLLAMA_RUNNING"
    echo "API Working: $API_WORKING"
    echo "Zed Installed: $ZED_INSTALLED"
    echo "Config Exists: $CONFIG_EXISTS"
    echo ""
    echo "Available Models:"
    ollama list
    echo ""
    echo "Zed Config Path: $ZED_CONFIG"
} > "$REPORT_FILE"

echo -e "${BLUE}📄 Full report saved to: $REPORT_FILE${NC}"
