# Connect to Pi5 VNC via Mac Mini (PowerShell Version)
# This script helps you SSH from Windows 11 to Mac Mini and connect to Pi5 VNC

# Colors for output
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Blue"
$PURPLE = "Magenta"

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

Write-Header "Connect to Pi5 VNC via Mac Mini"
Write-Host ""

# Configuration - Update these with your Mac Mini details
$MAC_MINI_HOST = "192.168.50.XXX"  # Replace with your Mac Mini IP
$MAC_MINI_USER = "your_username"   # Replace with your Mac Mini username
$PI5_HOST = "192.168.50.243"
$PI5_VNC_PORT = "5901"  # Updated to use display :1

Write-Status $YELLOW "Before running this script, please update:"
Write-Status $YELLOW "1. MAC_MINI_HOST with your Mac Mini IP address"
Write-Status $YELLOW "2. MAC_MINI_USER with your Mac Mini username"
Write-Host ""

$response = Read-Host "Have you updated the configuration? (y/n)"
if ($response -notmatch "^[Yy]$") {
    Write-Status $RED "Please update the configuration first"
    Write-Status $BLUE "Edit this script and update:"
    Write-Status $BLUE "  `$MAC_MINI_HOST = `"192.168.50.XXX`""
    Write-Status $BLUE "  `$MAC_MINI_USER = `"your_username`""
    exit 1
}

Write-Header "Step 1: Test SSH Connection to Mac Mini"
Write-Status $BLUE "Testing SSH connection to Mac Mini..."

$sshTest = ssh -o ConnectTimeout=10 "$MAC_MINI_USER@$MAC_MINI_HOST" "echo 'SSH connection successful'" 2>$null
if ($sshTest) {
    Write-Status $GREEN "✅ SSH connection to Mac Mini successful"
} else {
    Write-Status $RED "❌ SSH connection to Mac Mini failed"
    Write-Status $YELLOW "Please check:"
    Write-Status $YELLOW "• Mac Mini IP address: $MAC_MINI_HOST"
    Write-Status $YELLOW "• Username: $MAC_MINI_USER"
    Write-Status $YELLOW "• SSH is enabled on Mac Mini (System Preferences > Sharing > Remote Login)"
    Write-Status $YELLOW "• SSH key authentication or password"
    exit 1
}

Write-Header "Step 2: Check VNC Client on Mac Mini"
Write-Status $BLUE "Checking available VNC clients on Mac Mini..."

$VNC_CLIENTS = ssh "$MAC_MINI_USER@$MAC_MINI_HOST" @"
if command -v vncviewer >/dev/null 2>&1; then
    echo 'TigerVNC: Available'
fi
if [ -d '/Applications/VNC Viewer.app' ]; then
    echo 'RealVNC: Available'
fi
if [ -d '/System/Library/CoreServices/Screen Sharing.app' ]; then
    echo 'Screen Sharing: Available'
fi
"@

if ($VNC_CLIENTS) {
    Write-Status $GREEN "✅ Available VNC clients on Mac Mini:"
    $VNC_CLIENTS -split "`n" | ForEach-Object {
        if ($_.Trim()) {
            Write-Status $GREEN "   📱 $($_.Trim())"
        }
    }
} else {
    Write-Status $YELLOW "⚠️  No VNC clients found on Mac Mini"
    Write-Status $YELLOW "Installing TigerVNC..."
    ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "brew install tigervnc"
}

Write-Header "Step 3: Connect to Pi5 VNC"
Write-Status $BLUE "Connecting to Pi5 VNC from Mac Mini..."
Write-Status $BLUE "Pi5 VNC: $PI5_HOST`:$PI5_VNC_PORT"
Write-Host ""

Write-Status $GREEN "Choose connection method:"
Write-Status $GREEN "1. TigerVNC (recommended)"
Write-Status $GREEN "2. Screen Sharing (built-in)"
Write-Status $GREEN "3. RealVNC Viewer"
Write-Host ""

$choice = Read-Host "Choose method (1-3)"

switch ($choice) {
    "1" {
        Write-Status $BLUE "Using TigerVNC..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" @"
            vncviewer \
                -FullScreen=0 \
                -Scaling=FitToWindow \
                -PreferredEncoding=Tight \
                -CompressLevel=6 \
                -QualityLevel=6 \
                $PI5_HOST`:$PI5_VNC_PORT
"@
    }
    "2" {
        Write-Status $BLUE "Using Screen Sharing..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "open `"vnc://$PI5_HOST`:$PI5_VNC_PORT`""
    }
    "3" {
        Write-Status $BLUE "Using RealVNC Viewer..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "open -a `"VNC Viewer`" `"vnc://$PI5_HOST`:$PI5_VNC_PORT`""
    }
    default {
        Write-Status $RED "Invalid choice. Using TigerVNC as default..."
        ssh "$MAC_MINI_USER@$MAC_MINI_HOST" @"
            vncviewer \
                -FullScreen=0 \
                -Scaling=FitToWindow \
                $PI5_HOST`:$PI5_VNC_PORT
"@
    }
}

Write-Header "Step 4: Quick Commands for Future Use"
Write-Status $GREEN "✅ Connection completed!"
Write-Host ""

Write-Status $BLUE "Quick commands for future connections:"
Write-Host ""

Write-Status $GREEN "1. SSH to Mac Mini:"
Write-Status $BLUE "ssh $MAC_MINI_USER@$MAC_MINI_HOST"
Write-Host ""

Write-Status $GREEN "2. Connect to Pi5 VNC (TigerVNC):"
Write-Status $BLUE "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST`:$PI5_VNC_PORT'"
Write-Host ""

Write-Status $GREEN "3. Connect to Pi5 VNC (Screen Sharing):"
Write-Status $BLUE "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'open `"vnc://$PI5_HOST`:$PI5_VNC_PORT`"'"
Write-Host ""

Write-Status $GREEN "4. One-liner from Windows 11:"
Write-Status $BLUE "ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST`:$PI5_VNC_PORT'"
Write-Host ""

Write-Status $YELLOW "Key parameters that fix Mac Mini VNC issues:"
Write-Status $YELLOW "• -FullScreen=0 (prevents fullscreen)"
Write-Status $YELLOW "• -Scaling=FitToWindow (fixes large text)"
Write-Status $YELLOW "• -PreferredEncoding=Tight (better performance)"
Write-Host ""

Write-Header "Setup Complete"
Write-Status $GREEN "✅ You can now connect to Pi5 VNC from Mac Mini!"
Write-Status $GREEN "✅ The cursor fix and resolution settings will be preserved"
Write-Status $GREEN "✅ Use the quick commands above for future connections"
Write-Host ""

