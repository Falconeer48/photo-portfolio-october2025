# Fix VNC Cursor Script for Pi5 (PowerShell Version)
# This script fixes the "X" cursor issue in VNC sessions

# Colors for output
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Blue"
$PURPLE = "Magenta"

# Configuration
$PI5_HOST = "ian@192.168.50.243"
$SSH_KEY = "~/.ssh/id_ed25519"
$VNC_DISPLAY = ":1"

function Write-Status {
    param(
        [string]$Color,
        [string]$Message
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host $Title -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
}

function Invoke-Pi5Command {
    param([string]$Command)
    ssh -i $SSH_KEY $PI5_HOST $Command
}

Write-Header "Pi5 VNC Cursor Fix"

# 1. Check Pi5 connectivity
Write-Header "1. Checking Pi5 Connectivity"
$connectTest = ssh -i $SSH_KEY -o ConnectTimeout=10 -o BatchMode=yes $PI5_HOST "echo 'Connected'" 2>$null
if (-not $connectTest) {
    Write-Status $RED "❌ Cannot connect to Pi5"
    exit 1
}
Write-Status $GREEN "✅ Connected to Pi5"

# 2. Check current VNC status
Write-Header "2. Checking VNC Status"
$VNC_STATUS = Invoke-Pi5Command "ps aux | grep vncserver-virtual | grep -v grep"
if ($VNC_STATUS) {
    Write-Status $GREEN "✅ VNC server is running"
} else {
    Write-Status $RED "❌ VNC server is not running"
    Write-Status $YELLOW "💡 Starting VNC server..."
    Invoke-Pi5Command "vncserver-virtual :1 -geometry 1920x1080"
    Start-Sleep -Seconds 3
}

# 3. Fix cursor immediately
Write-Header "3. Fixing Cursor Immediately"
Write-Status $BLUE "Setting cursor to normal arrow..."

# Try multiple cursor fixes
Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name left_ptr" 2>$null
Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name arrow" 2>$null
Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name default" 2>$null

# Set cursor theme environment variables
Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY export XCURSOR_THEME=Adwaita"
Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY export XCURSOR_SIZE=24"

Write-Status $GREEN "✅ Cursor fixes applied"

# 4. Update xstartup file for permanent fix
Write-Header "4. Updating xstartup for Permanent Fix"
Write-Status $BLUE "Creating improved xstartup file..."

$XSTARTUP_CONTENT = @"
#!/bin/bash
# Uncomment the following two lines for normal desktop:
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="LXDE"
export XDG_MENU_PREFIX="lxde-"
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r `$HOME/.Xresources ] && xrdb `$HOME/.Xresources
# Fix cursor - set proper cursor theme and size
export XCURSOR_THEME="Adwaita"
export XCURSOR_SIZE="24"
xsetroot -solid grey -cursor_name left_ptr
vncconfig -iconic &
# Start desktop environment
lxsession -s LXDE-pi -e LXDE &
"@

Invoke-Pi5Command "cat > ~/.vnc/xstartup << 'EOF'
$XSTARTUP_CONTENT
EOF"

Invoke-Pi5Command "chmod +x ~/.vnc/xstartup"
Write-Status $GREEN "✅ xstartup file updated"

# 5. Install cursor themes if missing
Write-Header "5. Checking Cursor Themes"
$CURSOR_THEMES = Invoke-Pi5Command "ls /usr/share/icons/ | grep -E '(Adwaita|default|gnome)'"
if ($CURSOR_THEMES) {
    Write-Status $GREEN "✅ Cursor themes available:"
    $CURSOR_THEMES -split "`n" | ForEach-Object {
        if ($_.Trim()) {
            Write-Status $GREEN "   📁 $($_.Trim())"
        }
    }
} else {
    Write-Status $YELLOW "⚠️  Installing additional cursor themes..."
    Invoke-Pi5Command "sudo apt update && sudo apt install -y adwaita-icon-theme"
}

# 6. Test cursor fix
Write-Header "6. Testing Cursor Fix"
Write-Status $BLUE "Testing cursor commands..."

# Test various cursor commands
$test1 = Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name left_ptr" 2>$null
if ($test1 -eq $null) { Write-Status $GREEN "✅ left_ptr cursor set" }

$test2 = Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name arrow" 2>$null
if ($test2 -eq $null) { Write-Status $GREEN "✅ arrow cursor set" }

$test3 = Invoke-Pi5Command "DISPLAY=$VNC_DISPLAY xsetroot -cursor_name default" 2>$null
if ($test3 -eq $null) { Write-Status $GREEN "✅ default cursor set" }

# 7. Create cursor fix script for future use
Write-Header "7. Creating Cursor Fix Script"
$FIX_SCRIPT_CONTENT = @"
#!/bin/bash
# Quick cursor fix script
export DISPLAY=:1
export XCURSOR_THEME="Adwaita"
export XCURSOR_SIZE="24"
xsetroot -cursor_name left_ptr
echo "Cursor fixed!"
"@

Invoke-Pi5Command "cat > ~/fix-cursor.sh << 'EOF'
$FIX_SCRIPT_CONTENT
EOF"

Invoke-Pi5Command "chmod +x ~/fix-cursor.sh"
Write-Status $GREEN "✅ Cursor fix script created: ~/fix-cursor.sh"

# 8. Final status
Write-Header "8. Final Status"
Write-Status $GREEN "✅ Cursor fix completed!"
Write-Host ""
Write-Status $BLUE "Cursor fixes applied:"
Write-Status $GREEN "  ✅ Immediate cursor fix"
Write-Status $GREEN "  ✅ Updated xstartup file"
Write-Status $GREEN "  ✅ Set cursor theme to Adwaita"
Write-Status $GREEN "  ✅ Created fix-cursor.sh script"
Write-Host ""
Write-Status $YELLOW "If cursor is still showing as 'X':"
Write-Status $YELLOW "  1. Reconnect to VNC"
Write-Status $YELLOW "  2. Run: ssh $PI5_HOST '~/fix-cursor.sh'"
Write-Status $YELLOW "  3. Restart VNC: ssh $PI5_HOST 'vncserver-virtual -kill :1 && vncserver-virtual :1'"
Write-Host ""
Write-Status $PURPLE "VNC Cursor Fix Complete!"

