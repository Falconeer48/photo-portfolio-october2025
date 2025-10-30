#!/bin/bash

# Ollama Configuration Script
# Prevents multiple models from loading simultaneously by managing keep-alive settings

echo "=== Ollama Configuration ==="
echo ""
echo "This script configures Ollama to prevent multiple models from loading simultaneously."
echo ""

# Options for OLLAMA_KEEP_ALIVE:
# 0     = Unload immediately after use
# 5m    = Keep for 5 minutes (default)
# 30s   = Keep for 30 seconds
# -1    = Keep forever (not recommended for limited RAM)

echo "Choose your preferred setting:"
echo "1) Unload immediately after use (0) - Best for limited RAM"
echo "2) Keep for 30 seconds (30s) - Good balance"
echo "3) Keep for 5 minutes (5m) - Ollama default"
echo "4) Check current setting"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        KEEP_ALIVE="0"
        echo "Setting OLLAMA_KEEP_ALIVE=0 (unload immediately)"
        ;;
    2)
        KEEP_ALIVE="30s"
        echo "Setting OLLAMA_KEEP_ALIVE=30s (keep for 30 seconds)"
        ;;
    3)
        KEEP_ALIVE="5m"
        echo "Setting OLLAMA_KEEP_ALIVE=5m (keep for 5 minutes)"
        ;;
    4)
        echo ""
        echo "Current setting:"
        launchctl getenv OLLAMA_KEEP_ALIVE
        if [ $? -ne 0 ] || [ -z "$(launchctl getenv OLLAMA_KEEP_ALIVE)" ]; then
            echo "OLLAMA_KEEP_ALIVE is not set (using default: 5m)"
        fi
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Setting environment variable for current session..."
export OLLAMA_KEEP_ALIVE=$KEEP_ALIVE

echo "Setting environment variable for Ollama app..."
launchctl setenv OLLAMA_KEEP_ALIVE $KEEP_ALIVE

echo ""
echo "Creating persistent configuration..."

# Create or update ~/.ollama/environment file
mkdir -p ~/.ollama
echo "export OLLAMA_KEEP_ALIVE=$KEEP_ALIVE" > ~/.ollama/environment

# Add to shell profile if not already there
SHELL_PROFILE=""
if [ -f ~/.zshrc ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f ~/.bash_profile ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
elif [ -f ~/.bashrc ]; then
    SHELL_PROFILE="$HOME/.bashrc"
fi

if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q "OLLAMA_KEEP_ALIVE" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# Ollama configuration" >> "$SHELL_PROFILE"
        echo "export OLLAMA_KEEP_ALIVE=$KEEP_ALIVE" >> "$SHELL_PROFILE"
        echo "Added to $SHELL_PROFILE"
    else
        echo "OLLAMA_KEEP_ALIVE already exists in $SHELL_PROFILE"
        echo "You may want to manually update it to: $KEEP_ALIVE"
    fi
fi

echo ""
echo "=== Configuration Complete ==="
echo ""
echo "IMPORTANT: Restart Ollama for changes to take effect:"
echo "  1) Quit Ollama completely (Cmd+Q or: killall ollama)"
echo "  2) Reopen Ollama app"
echo ""
echo "To verify the setting after restart:"
echo "  curl http://localhost:11434/api/ps"
echo ""
echo "Additional tips to avoid multiple models loading:"
echo "  - Close applications using Ollama when not needed"
echo "  - Use 'ollama ps' to see loaded models"
echo "  - Use 'ollama stop <model>' to manually unload a model"
echo ""
