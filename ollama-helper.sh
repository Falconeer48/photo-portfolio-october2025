#!/bin/bash

# Ollama Helper Script
# Easy interface for using local Ollama models

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OLLAMA_HOST="http://localhost:11434"
DEFAULT_MODEL="llama3.1:8b"

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

# Check if Ollama is running
check_ollama() {
    if ! pgrep -x "ollama" > /dev/null; then
        warning "Ollama service not running, attempting to start..."
        ollama serve > /dev/null 2>&1 &
        sleep 2
    fi

    if ! curl -s "$OLLAMA_HOST/api/tags" > /dev/null; then
        error "Cannot connect to Ollama at $OLLAMA_HOST"
        echo "Try running: ollama serve"
        exit 1
    fi
}

# List available models
list_models() {
    echo -e "${PURPLE}📋 Available Local Models:${NC}"
    ollama list
}

# Interactive model selection
select_model() {
    echo -e "${CYAN}Select a model:${NC}"
    models=($(ollama list | tail -n +2 | awk '{print $1}'))

    for i in "${!models[@]}"; do
        echo -e "${YELLOW}$((i+1)))${NC} ${models[$i]}"
    done

    read -p "Enter number (or press Enter for default): " choice

    if [[ -z "$choice" ]]; then
        echo "$DEFAULT_MODEL"
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#models[@]}" ]; then
        echo "${models[$((choice-1))]}"
    else
        echo "$DEFAULT_MODEL"
    fi
}

# Code review function
code_review() {
    local file="$1"
    local model="$2"

    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi

    info "Reviewing code in $file with $model..."

    local prompt="Please review this code for potential issues, bugs, security concerns, and improvements:\n\n"
    prompt+="$(cat "$file")"

    echo -e "$prompt" | ollama run "$model"
}

# Explain code function
explain_code() {
    local file="$1"
    local model="$2"

    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi

    info "Explaining code in $file with $model..."

    local prompt="Please explain what this code does in detail:\n\n"
    prompt+="$(cat "$file")"

    echo -e "$prompt" | ollama run "$model"
}

# Generate documentation
generate_docs() {
    local file="$1"
    local model="$2"

    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi

    info "Generating documentation for $file with $model..."

    local prompt="Please generate comprehensive documentation for this code including usage examples:\n\n"
    prompt+="$(cat "$file")"

    echo -e "$prompt" | ollama run "$model"
}

# Debug help function
debug_help() {
    local error_msg="$1"
    local model="$2"

    info "Getting debug help with $model..."

    local prompt="I'm getting this error, please help me understand and fix it:\n\n"
    prompt+="$error_msg"

    echo -e "$prompt" | ollama run "$model"
}

# Interactive chat
interactive_chat() {
    local model="$1"

    info "Starting interactive chat with $model"
    echo -e "${YELLOW}Type 'exit' to quit, 'clear' to clear screen${NC}"
    echo ""

    while true; do
        echo -ne "${GREEN}You: ${NC}"
        read -r input

        case "$input" in
            "exit"|"quit"|"q")
                echo -e "${BLUE}Goodbye!${NC}"
                break
                ;;
            "clear"|"cls")
                clear
                ;;
            "")
                continue
                ;;
            *)
                echo -e "${CYAN}$model:${NC}"
                echo "$input" | ollama run "$model"
                echo ""
                ;;
        esac
    done
}

# Show usage
show_usage() {
    echo -e "${PURPLE}🤖 Ollama Helper - Local AI Assistant${NC}"
    echo "====================================="
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  list                    - List available models"
    echo "  chat [model]           - Interactive chat session"
    echo "  review <file> [model]  - Review code for issues"
    echo "  explain <file> [model] - Explain what code does"
    echo "  docs <file> [model]    - Generate documentation"
    echo "  debug <error> [model]  - Help debug an error"
    echo "  run <model> <prompt>   - Run single prompt"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 list"
    echo "  $0 chat"
    echo "  $0 review script.sh"
    echo "  $0 explain photo-portfolio-test.sh codellama:13b"
    echo "  $0 debug 'npm build failed' llama3.1:8b"
    echo "  $0 run llama3.2:3b 'What is Docker?'"
    echo ""
    echo -e "${YELLOW}Available Models:${NC}"
    ollama list | tail -n +2 | awk '{printf "  • %s (%s)\n", $1, $3}'
}

# Main script logic
main() {
    check_ollama

    case "${1:-help}" in
        "list"|"ls")
            list_models
            ;;
        "chat"|"c")
            model="${2:-$(select_model)}"
            interactive_chat "$model"
            ;;
        "review"|"r")
            if [ -z "$2" ]; then
                error "Please specify a file to review"
                echo "Usage: $0 review <file> [model]"
                exit 1
            fi
            model="${3:-$DEFAULT_MODEL}"
            code_review "$2" "$model"
            ;;
        "explain"|"e")
            if [ -z "$2" ]; then
                error "Please specify a file to explain"
                echo "Usage: $0 explain <file> [model]"
                exit 1
            fi
            model="${3:-$DEFAULT_MODEL}"
            explain_code "$2" "$model"
            ;;
        "docs"|"d")
            if [ -z "$2" ]; then
                error "Please specify a file to document"
                echo "Usage: $0 docs <file> [model]"
                exit 1
            fi
            model="${3:-$DEFAULT_MODEL}"
            generate_docs "$2" "$model"
            ;;
        "debug"|"db")
            if [ -z "$2" ]; then
                error "Please specify an error message"
                echo "Usage: $0 debug '<error_message>' [model]"
                exit 1
            fi
            model="${3:-$DEFAULT_MODEL}"
            debug_help "$2" "$model"
            ;;
        "run")
            if [ -z "$2" ] || [ -z "$3" ]; then
                error "Please specify model and prompt"
                echo "Usage: $0 run <model> '<prompt>'"
                exit 1
            fi
            echo "$3" | ollama run "$2"
            ;;
        "help"|"h"|*)
            show_usage
            ;;
    esac
}

main "$@"
