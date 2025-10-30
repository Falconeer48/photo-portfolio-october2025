#!/bin/bash

# Main Photo Portfolio Deployment Script
# Runs tests first, then deploys if everything passes

set -e

echo "🚀 Photo Portfolio Deployment Pipeline"
echo "======================================"

# Run system integrity test first
echo ""
echo "🔍 Running system integrity tests..."
if ./scripts/test-system.sh; then
    echo ""
    echo "✅ All tests passed! Proceeding with deployment..."
    echo ""
    
    # Ask user which deployment method to use
    echo "Choose deployment method:"
    echo "1) Quick deploy (fast, essential checks only)"
    echo "2) Full deploy (comprehensive checks and backup)"
    echo "3) Skip deployment (tests only)"
    echo ""
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            echo ""
            echo "🚀 Running quick deploy..."
            ./scripts/quick-deploy.sh
            ;;
        2)
            echo ""
            echo "🔍 Running full deployment with checks..."
            ./scripts/deploy-with-checks.sh
            ;;
        3)
            echo ""
            echo "✅ Tests completed successfully. No deployment performed."
            ;;
        *)
            echo ""
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    echo ""
    echo "❌ System integrity tests failed. Please fix issues before deploying."
    echo ""
    echo "Common fixes:"
    echo "- Run 'npm install' to install dependencies"
    echo "- Check for syntax errors in your code"
    echo "- Ensure Pi5 is running and accessible"
    echo "- Verify the photo-portfolio service is running on Pi5"
    exit 1
fi 