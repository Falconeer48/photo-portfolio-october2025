#!/bin/bash

# Zed Local AI Setup Script
# Configures Zed to use local Ollama models for free AI assistance

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

echo -e "${PURPLE}🚀 Zed Local AI Setup${NC}"
echo "===================="
echo ""

# Check if Zed is installed
log "Checking Zed installation..."
if ! command -v zed >/dev/null 2>&1; then
    warning "Zed not found in PATH. Checking /Applications..."
    if [ ! -d "/Applications/Zed.app" ]; then
        error "Zed not installed. Please install Zed first:"
        echo "  Download from: https://zed.dev"
        echo "  Or install via Homebrew: brew install --cask zed"
        exit 1
    else
        success "Found Zed in /Applications"
        # Add zed command if not in PATH
        if [ ! -L "/usr/local/bin/zed" ]; then
            info "Creating zed command link..."
            sudo ln -sf "/Applications/Zed.app/Contents/MacOS/cli" "/usr/local/bin/zed" 2>/dev/null || true
        fi
    fi
else
    success "Zed found in PATH"
fi

# Check Ollama installation
log "Checking Ollama installation..."
if ! command -v ollama >/dev/null 2>&1; then
    error "Ollama not found. Please install Ollama first:"
    echo "  Download from: https://ollama.ai"
    echo "  Or install via Homebrew: brew install ollama"
    exit 1
fi
success "Ollama found"

# Check if Ollama is running
log "Checking Ollama service..."
if ! pgrep -x "ollama" > /dev/null; then
    warning "Ollama service not running, starting it..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Test Ollama connection
if curl -s "http://localhost:11434/api/tags" > /dev/null; then
    success "Ollama service is running"
else
    error "Cannot connect to Ollama service"
    echo "Try running: ollama serve"
    exit 1
fi

# Get available models
log "Checking available models..."
AVAILABLE_MODELS=$(ollama list | tail -n +2 | awk '{print $1}')
if [ -z "$AVAILABLE_MODELS" ]; then
    error "No Ollama models found. Please install at least one model:"
    echo "  For coding: ollama pull codellama:13b"
    echo "  General: ollama pull llama3.1:8b"
    echo "  Lightweight: ollama pull llama3.2:3b"
    exit 1
fi

echo -e "${GREEN}Available models:${NC}"
echo "$AVAILABLE_MODELS" | sed 's/^/  • /'

# Determine Zed config directory
ZED_CONFIG_DIR="$HOME/.config/zed"
if [[ "$OSTYPE" == "darwin"* ]]; then
    ZED_CONFIG_DIR="$HOME/Library/Application Support/Zed"
fi

# Create config directory if it doesn't exist
log "Setting up Zed configuration directory..."
mkdir -p "$ZED_CONFIG_DIR"
success "Config directory ready: $ZED_CONFIG_DIR"

# Backup existing settings if they exist
if [ -f "$ZED_CONFIG_DIR/settings.json" ]; then
    log "Backing up existing settings..."
    cp "$ZED_CONFIG_DIR/settings.json" "$ZED_CONFIG_DIR/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    success "Existing settings backed up"
fi

# Select default model
DEFAULT_MODEL=""
if echo "$AVAILABLE_MODELS" | grep -q "codellama:13b"; then
    DEFAULT_MODEL="codellama:13b"
elif echo "$AVAILABLE_MODELS" | grep -q "llama3.1:8b"; then
    DEFAULT_MODEL="llama3.1:8b"
else
    DEFAULT_MODEL=$(echo "$AVAILABLE_MODELS" | head -n1)
fi

info "Using $DEFAULT_MODEL as default model"

# Create Zed settings file
log "Creating Zed settings configuration..."
cat > "$ZED_CONFIG_DIR/settings.json" << EOF
{
  "assistant": {
    "default_model": {
      "provider": "ollama",
      "model": "$DEFAULT_MODEL"
    },
    "provider": {
      "ollama": {
        "api_url": "http://localhost:11434"
      }
    }
  },
  "language_models": {
    "ollama": {
      "api_url": "http://localhost:11434",
      "models": {
EOF

# Add available models to config
while IFS= read -r model; do
    if [ -n "$model" ]; then
        # Determine display name and context window based on model
        case "$model" in
            *"codellama"*)
                DISPLAY_NAME="CodeLlama (Local)"
                CONTEXT_WINDOW=16384
                MAX_TOKENS=4096
                ;;
            *"llama3.1"*)
                DISPLAY_NAME="Llama 3.1 (Local)"
                CONTEXT_WINDOW=32768
                MAX_TOKENS=4096
                ;;
            *"llama3.2"*)
                DISPLAY_NAME="Llama 3.2 (Local)"
                CONTEXT_WINDOW=8192
                MAX_TOKENS=2048
                ;;
            *)
                DISPLAY_NAME="${model} (Local)"
                CONTEXT_WINDOW=8192
                MAX_TOKENS=2048
                ;;
        esac

        cat >> "$ZED_CONFIG_DIR/settings.json" << EOF
        "$model": {
          "display_name": "$DISPLAY_NAME",
          "max_tokens": $MAX_TOKENS,
          "context_window": $CONTEXT_WINDOW
        },
EOF
    fi
done <<< "$AVAILABLE_MODELS"

# Remove trailing comma and close the models section
sed -i '' '$ s/,$//' "$ZED_CONFIG_DIR/settings.json" 2>/dev/null || sed -i '$ s/,$//' "$ZED_CONFIG_DIR/settings.json"

# Complete the settings file
cat >> "$ZED_CONFIG_DIR/settings.json" << 'EOF'
      }
    }
  },
  "features": {
    "inline_completion_provider": "ollama",
    "copilot": false
  },
  "vim_mode": false,
  "ui_font_size": 16,
  "buffer_font_size": 14,
  "theme": {
    "mode": "system",
    "light": "One Light",
    "dark": "One Dark"
  },
  "show_whitespaces": "selection",
  "tab_size": 2,
  "hard_tabs": false,
  "soft_wrap": "editor_width",
  "preferred_line_length": 100,
  "format_on_save": "on",
  "remove_trailing_whitespace_on_save": true,
  "ensure_final_newline_on_save": true,
  "show_inline_completions": true,
  "auto_update": true,
  "terminal": {
    "shell": {
      "program": "/bin/zsh"
    },
    "font_size": 14,
    "working_directory": "current_project_directory"
  },
  "project_panel": {
    "dock": "left",
    "default_width": 240
  },
  "chat_panel": {
    "dock": "right",
    "default_width": 400
  },
  "lsp": {
    "typescript-language-server": {
      "initialization_options": {
        "preferences": {
          "includeInlayParameterNameHints": "all",
          "includeInlayParameterNameHintsWhenArgumentMatchesName": true,
          "includeInlayFunctionParameterTypeHints": true,
          "includeInlayVariableTypeHints": true,
          "includeInlayPropertyDeclarationTypeHints": true,
          "includeInlayFunctionLikeReturnTypeHints": true
        }
      }
    }
  },
  "languages": {
    "JavaScript": {
      "tab_size": 2,
      "format_on_save": "on"
    },
    "TypeScript": {
      "tab_size": 2,
      "format_on_save": "on"
    },
    "JSON": {
      "tab_size": 2,
      "format_on_save": "on"
    },
    "Python": {
      "tab_size": 4,
      "format_on_save": "on"
    },
    "Rust": {
      "tab_size": 4,
      "format_on_save": "on"
    },
    "Go": {
      "tab_size": 4,
      "format_on_save": "on"
    },
    "Shell Script": {
      "tab_size": 2,
      "format_on_save": "on"
    }
  },
  "file_types": {
    "Dockerfile": ["Dockerfile", "*.dockerfile"],
    "JSON": ["*.json", "*.jsonc"],
    "Shell Script": ["*.sh", "*.bash", "*.zsh"]
  },
  "git": {
    "inline_blame": {
      "enabled": true
    }
  },
  "scrollbar": {
    "show": "auto",
    "git_diff": true,
    "search_results": true,
    "selected_symbol": true,
    "diagnostics": true
  },
  "inlay_hints": {
    "enabled": true,
    "show_type_hints": true,
    "show_parameter_hints": true,
    "show_other_hints": true
  }
}
EOF

success "Zed settings configuration created"

# Create a test script
log "Creating test script..."
cat > "$HOME/zed_ai_test.js" << 'EOF'
// Test file for Zed AI integration
// Try asking the AI to complete or explain this code

function fibonacci(n) {
    // Ask AI to complete this function
}

const users = [
    { name: "Alice", age: 30 },
    { name: "Bob", age: 25 },
    { name: "Charlie", age: 35 }
];

// Ask AI to help filter users over 30
EOF

success "Test file created: $HOME/zed_ai_test.js"

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=================="
echo ""
echo -e "${BLUE}What's configured:${NC}"
echo "• Zed settings: $ZED_CONFIG_DIR/settings.json"
echo "• Default model: $DEFAULT_MODEL"
echo "• Ollama API: http://localhost:11434"
echo "• Available models: $(echo "$AVAILABLE_MODELS" | wc -l | tr -d ' ') models"
echo ""
echo -e "${YELLOW}How to use:${NC}"
echo "1. Open Zed: zed"
echo "2. Open test file: zed $HOME/zed_ai_test.js"
echo "3. Use Ctrl+Shift+A (or Cmd+Shift+A) to open AI chat"
echo "4. Try typing code and let AI complete it"
echo "5. Select code and ask AI to explain or refactor it"
echo ""
echo -e "${PURPLE}Available AI features:${NC}"
echo "• Code completion (inline suggestions)"
echo "• Chat with AI about code"
echo "• Code explanation and refactoring"
echo "• Debugging assistance"
echo "• Documentation generation"
echo ""
echo -e "${CYAN}💡 Tips:${NC}"
echo "• Switch models in Zed settings if needed"
echo "• Use the chat panel for complex questions"
echo "• All processing happens locally - completely private!"
echo "• No API costs - just electricity!"
echo ""
echo -e "${GREEN}Ready to code with free local AI! 🚀${NC}"

# Optional: Open Zed with test file
read -p "Open Zed with test file now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v zed >/dev/null 2>&1; then
        zed "$HOME/zed_ai_test.js" &
    else
        open -a Zed "$HOME/zed_ai_test.js" &
    fi
    success "Zed opened with test file"
fi
