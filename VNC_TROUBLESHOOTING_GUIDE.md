# VNC Troubleshooting Guide: Mac Mini vs Other Devices

## Problem Description

You're experiencing different VNC behavior between devices:
- **Windows 11 PC**: VNC works fine with proper windowing
- **iMac**: VNC works fine with proper windowing  
- **Mac Mini**: VNC goes to fullscreen with very large text and UI elements

## Root Cause

This is a common issue with VNC clients on macOS, particularly on Mac Mini devices. The problem occurs because:

1. **Different VNC clients**: Mac Mini might be using a different VNC client or version
2. **Display scaling**: Mac Mini's display scaling settings affect VNC behavior
3. **Client preferences**: VNC client preferences are set differently
4. **Fullscreen mode**: VNC client defaults to fullscreen mode on Mac Mini

## Solutions

### Solution 1: Use TigerVNC with Proper Parameters

```bash
# Install TigerVNC (if not already installed)
brew install tigervnc

# Connect with windowed mode and proper scaling
vncviewer -FullScreen=0 -Scaling=FitToWindow -Geometry=1024x768 192.168.50.243:5900
```

### Solution 2: Use Built-in Screen Sharing with Preferences

1. Open **System Preferences** → **Sharing** → **Screen Sharing**
2. Click **Computer Settings**
3. Uncheck **"VNC viewers may control screen with password"**
4. Connect using: `open "vnc://192.168.50.243:5900"`

### Solution 3: RealVNC Viewer Configuration

If using RealVNC Viewer:
1. Open VNC Viewer
2. Go to **File** → **Options**
3. Set **Scaling** to **"Fit to window"**
4. Uncheck **"Full screen"**
5. Set **Quality** to **"Balanced"**

### Solution 4: Create Custom Connection Scripts

Use the provided scripts:
- `connect-vnc-pi5-mac-mini.sh` - Main connection script
- `fix-mac-mini-vnc.sh` - Configuration setup script

## Quick Fixes

### Immediate Fix (Command Line)

```bash
# Connect in windowed mode
vncviewer -FullScreen=0 -Scaling=FitToWindow 192.168.50.243:5900

# Connect with specific window size
vncviewer -FullScreen=0 -Geometry=1280x720 192.168.50.243:5900

# Connect with custom scaling
vncviewer -FullScreen=0 -Scaling=FitToWindow -PreferredEncoding=Tight 192.168.50.243:5900
```

### Immediate Fix (Screen Sharing)

```bash
# Open Screen Sharing
open "vnc://192.168.50.243:5900"

# Then in Screen Sharing app:
# 1. Go to View → Scaling → Fit to Window
# 2. Go to View → Full Screen (uncheck)
```

## Advanced Configuration

### TigerVNC Configuration File

Create `~/.vnc/vncviewerrc`:
```
FullScreen=0
Scaling=FitToWindow
PreferredEncoding=Tight
CompressLevel=6
QualityLevel=6
Geometry=1024x768
```

### RealVNC Configuration

In VNC Viewer preferences:
- **Display**: Fit to window
- **Full screen**: Off
- **Quality**: Balanced
- **Compression**: Tight

## Troubleshooting Steps

### Step 1: Check VNC Client
```bash
# Check which VNC client is installed
which vncviewer
ls -la /Applications/ | grep -i vnc
```

### Step 2: Test Different Parameters
```bash
# Test 1: Basic windowed connection
vncviewer -FullScreen=0 192.168.50.243:5900

# Test 2: With scaling
vncviewer -FullScreen=0 -Scaling=FitToWindow 192.168.50.243:5900

# Test 3: With specific geometry
vncviewer -FullScreen=0 -Geometry=1024x768 192.168.50.243:5900
```

### Step 3: Check Display Settings
```bash
# Check Mac Mini display settings
system_profiler SPDisplaysDataType
```

## Prevention

### Create Desktop Shortcut

Create `~/Desktop/Connect-to-Pi5.command`:
```bash
#!/bin/bash
cd ~
vncviewer -FullScreen=0 -Scaling=FitToWindow 192.168.50.243:5900
```

Make it executable:
```bash
chmod +x ~/Desktop/Connect-to-Pi5.command
```

### Set Default VNC Parameters

Add to your shell profile (`~/.zshrc` or `~/.bash_profile`):
```bash
alias vnc-pi5='vncviewer -FullScreen=0 -Scaling=FitToWindow 192.168.50.243:5900'
```

## Common Issues and Solutions

### Issue: Still going fullscreen
**Solution**: Use `-FullScreen=0` parameter explicitly

### Issue: Text too large
**Solution**: Use `-Scaling=FitToWindow` parameter

### Issue: Poor performance
**Solution**: Use `-PreferredEncoding=Tight -CompressLevel=6`

### Issue: Wrong window size
**Solution**: Use `-Geometry=1024x768` parameter

## Testing

Test each solution:
1. Run the connection command
2. Check if it opens in windowed mode
3. Verify text size is normal
4. Test window resizing

## Summary

The Mac Mini VNC issue is caused by default client settings that force fullscreen mode and improper scaling. The solution is to use explicit parameters that force windowed mode and proper scaling:

```bash
vncviewer -FullScreen=0 -Scaling=FitToWindow -Geometry=1024x768 192.168.50.243:5900
```

This command ensures:
- ✅ Windowed mode (not fullscreen)
- ✅ Proper text scaling
- ✅ Resizable window
- ✅ Normal UI element sizes

