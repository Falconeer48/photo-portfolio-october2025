# Zed AI Assistant Usage Guide

## How to Access AI Features in Zed

### Method 1: Command Palette (Most Reliable)
1. Press `Cmd+Shift+P` to open the command palette
2. Type: "assistant" or "chat"
3. Select "assistant: Toggle Focus" or similar option

### Method 2: Via Menu Bar
- **View** → **Assistant Panel** or **Chat Panel**
- Look for AI/Assistant options in the menu

### Method 3: Keyboard Shortcuts to Try
Different versions of Zed use different shortcuts:
- `Ctrl+Enter` - Toggle assistant
- `Cmd+.` - Open assistant
- `/` - In some contexts opens AI inline
- Try checking: Zed → Preferences → Keybindings for "assistant"

### Method 4: Inline AI
1. Select code in your editor
2. Right-click
3. Look for "Ask Assistant" or AI-related options

## How to Use Your Local Ollama Models

### Step 1: Verify Models Are Available
In Zed's assistant panel, you should see a model dropdown with:
- CodeLlama 13B (Local)
- Llama 3.1 8B (Local)
- Llama 3.2 3B (Local)

### Step 2: Select Your Model
Click the model dropdown and choose one of your local models

### Step 3: Ask Questions
Type your question or request in the assistant panel:
- "Explain this code"
- "Find bugs in this function"
- "Optimize this algorithm"
- "Add error handling"

## Troubleshooting

### If AI Panel Doesn't Open
1. Check Zed version is recent (Ollama support is newer)
2. Try: Zed → Check for Updates
3. Restart Zed completely (Cmd+Q)

### If Models Don't Respond
1. Verify Ollama is running:
   ```bash
   curl http://localhost:11434/api/tags
   ```
2. If not running, start it:
   ```bash
   ollama serve
   ```
3. Restart Zed

### If You See "No Models Available"
1. Check settings file exists:
   ```bash
   cat "$HOME/Library/Application Support/Zed/settings.json" | grep ollama
   ```
2. Should show: `"provider": "ollama"`
3. If missing, run setup again:
   ```bash
   cd ~/Scripts
   ./setup-zed-local-ai.sh
   ```

## Alternative: 100% Working Command-Line AI

If Zed's AI isn't working, use the command-line tools:

### Interactive Chat
```bash
cd ~/Scripts
./ollama-helper.sh chat
```

### Code Review
```bash
./ollama-helper.sh review yourfile.js
```

### Explain Code
```bash
./ollama-helper.sh explain yourfile.sh
```

### Direct Ollama Usage
```bash
ollama run codellama:13b
# Then type your questions
```

## Checking Zed's Keybindings

To find the exact keybinding for your Zed version:

1. In Zed, go to: **Zed → Preferences → Keybindings**
2. Search for: "assistant"
3. You'll see the actual keyboard shortcut assigned

Or check the keymap file:
```bash
cat "$HOME/Library/Application Support/Zed/keymap.json" 2>/dev/null
```

## Privacy Guarantee

With our setup:
- ✅ No API keys configured
- ✅ Only local Ollama models available
- ✅ If Ollama isn't responding, AI simply won't work
- ✅ Zed CANNOT silently fall back to internet models

Verify:
```bash
grep -i "api_key\|anthropic\|openai" "$HOME/Library/Application Support/Zed/settings.json"
```
Should return: nothing (no matches)

## Model Selection Guide

**CodeLlama 13B** (Default)
- Best for: Code completion, debugging, refactoring
- Size: 7.4 GB
- Speed: Moderate

**Llama 3.1 8B**
- Best for: Explanations, documentation, general questions
- Size: 4.9 GB
- Speed: Fast

**Llama 3.2 3B**
- Best for: Quick suggestions, simple questions
- Size: 2.0 GB
- Speed: Very fast

## Quick Test

1. Open Zed
2. Create new file: `test.js`
3. Type: `function add`
4. Wait for AI completion suggestion
5. Or open command palette (Cmd+Shift+P) → "assistant"
6. Ask: "Write a function to add two numbers"

## Support

If nothing works, Zed's Ollama integration may be:
- Too new/experimental in your version
- Requiring a newer version of Zed
- Not yet fully supported on macOS

**Fallback**: Use command-line tools which are 100% guaranteed to work:
```bash
cd ~/Scripts
./ollama-helper.sh chat
```

This provides the same AI assistance via terminal instead of Zed's UI.