ian@Ians Mac Mini Scripts % cat fix_cursor_dns.sh
#!/bin/bash

# Fix Cursor DNS Resolution Issue
# This script adds a hosts file entry to redirect api.cursor.sh to api.cursor.com

echo "=========================================="
echo "Cursor DNS Fix Script"
echo "=========================================="
echo ""

# Check if api.cursor.sh is already in hosts file
if grep -q "api.cursor.sh" /etc/hosts; then
    echo "✓ api.cursor.sh entry already exists in hosts file"
    echo "Current entry:"
    grep "api.cursor.sh" /etc/hosts
else
    echo "Adding api.cursor.sh -> api.cursor.com mapping to hosts file..."
    
    # Get the IP address of api.cursor.com
    CURSOR_IP=$(nslookup api.cursor.com | grep "Address:" | tail -1 | awk '{print $2}')
    
    if [ -n "$CURSOR_IP" ]; then
        echo "Found api.cursor.com IP: $CURSOR_IP"
        
        # Add the entry to hosts file
        echo "$CURSOR_IP api.cursor.sh" | sudo tee -a /etc/hosts
        
        echo "✓ Added hosts file entry: $CURSOR_IP api.cursor.sh"
    else
        echo "✗ Could not resolve api.cursor.com IP address"
        echo "Adding fallback entry..."
        echo "104.21.0.0 api.cursor.sh" | sudo tee -a /etc/hosts
        echo "✓ Added fallback hosts file entry"
    fi
fi

echo ""
echo "Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

echo ""
echo "Testing DNS resolution..."
if nslookup api.cursor.sh > /dev/null 2>&1; then
    echo "✓ api.cursor.sh now resolves successfully!"
else
    echo "✗ DNS resolution still failing"
fi

echo ""
echo "Testing connectivity..."
if curl -s --connect-timeout 5 https://api.cursor.sh > /dev/null 2>&1; then
    echo "✓ Successfully connected to api.cursor.sh!"
else
    echo "✗ Connection to api.cursor.sh still failing"
fi

echo ""
echo "=========================================="
echo "DNS Fix Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart Cursor completely (quit and reopen)"
echo "2. Test AI responses in Cursor"
echo "3. If issues persist, check Cursor settings for API endpoint"
echo ""
echo "To verify the fix worked:"
echo "nslookup api.cursor.sh"
echo "curl -I https://api.cursor.sh"#!/bin/bash

# Fix Cursor DNS Resolution Issue
# This script adds a hosts file entry to redirect api.cursor.sh to api.cursor.com

echo "=========================================="
echo "Cursor DNS Fix Script"
echo "=========================================="
echo ""

# Check if api.cursor.sh is already in hosts file
if grep -q "api.cursor.sh" /etc/hosts; then
    echo "✓ api.cursor.sh entry already exists in hosts file"
    echo "Current entry:"
    grep "api.cursor.sh" /etc/hosts
else
    echo "Adding api.cursor.sh -> api.cursor.com mapping to hosts file..."
    
    # Get the IP address of api.cursor.com
    CURSOR_IP=$(nslookup api.cursor.com | grep "Address:" | tail -1 | awk '{print $2}')
    
    if [ -n "$CURSOR_IP" ]; then
        echo "Found api.cursor.com IP: $CURSOR_IP"
        
        # Add the entry to hosts file
        echo "$CURSOR_IP api.cursor.sh" | sudo tee -a /etc/hosts
        
        echo "✓ Added hosts file entry: $CURSOR_IP api.cursor.sh"
    else
        echo "✗ Could not resolve api.cursor.com IP address"
        echo "Adding fallback entry..."
        echo "104.21.0.0 api.cursor.sh" | sudo tee -a /etc/hosts
        echo "✓ Added fallback hosts file entry"
    fi
fi

echo ""
echo "Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

echo ""
echo "Testing DNS resolution..."
if nslookup api.cursor.sh > /dev/null 2>&1; then
    echo "✓ api.cursor.sh now resolves successfully!"
else
    echo "✗ DNS resolution still failing"
fi

echo ""
echo "Testing connectivity..."
if curl -s --connect-timeout 5 https://api.cursor.sh > /dev/null 2>&1; then
    echo "✓ Successfully connected to api.cursor.sh!"
else
    echo "✗ Connection to api.cursor.sh still failing"
fi

echo ""
echo "=========================================="
echo "DNS Fix Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart Cursor completely (quit and reopen)"
echo "2. Test AI responses in Cursor"
echo "3. If issues persist, check Cursor settings for API endpoint"
echo ""
echo "To verify the fix worked:"
echo "nslookup api.cursor.sh"
echo "curl -I https://api.cursor.sh"

