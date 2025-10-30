# SSH to Mac Mini and Run VNC Commands
# PowerShell script to SSH from Windows 11 to Mac Mini and run VNC scripts

Write-Host "==========================================" -ForegroundColor Blue
Write-Host "SSH to Mac Mini VNC Setup" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

# Configuration - Update these with your Mac Mini details
$MAC_MINI_HOST = "192.168.50.XXX"  # Replace with your Mac Mini IP
$MAC_MINI_USER = "your_username"   # Replace with your Mac Mini username
$PI5_HOST = "192.168.50.243"

Write-Host "Before running this script, please update:" -ForegroundColor Yellow
Write-Host "1. MAC_MINI_HOST with your Mac Mini IP address" -ForegroundColor Yellow
Write-Host "2. MAC_MINI_USER with your Mac Mini username" -ForegroundColor Yellow
Write-Host ""
Write-Host "Current settings:" -ForegroundColor Cyan
Write-Host "Mac Mini Host: $MAC_MINI_HOST" -ForegroundColor Cyan
Write-Host "Mac Mini User: $MAC_MINI_USER" -ForegroundColor Cyan
Write-Host "Pi5 Host: $PI5_HOST" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Have you updated the configuration? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Please update the configuration first" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Step 1: Testing SSH Connection to Mac Mini" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Testing SSH connection to Mac Mini..." -ForegroundColor Blue

try {
    $result = ssh -o ConnectTimeout=10 "$MAC_MINI_USER@$MAC_MINI_HOST" "echo 'SSH connection successful'"
    Write-Host "SUCCESS: SSH connection to Mac Mini successful" -ForegroundColor Green
} catch {
    Write-Host "ERROR: SSH connection to Mac Mini failed" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "- Mac Mini IP address" -ForegroundColor Yellow
    Write-Host "- Username" -ForegroundColor Yellow
    Write-Host "- SSH is enabled on Mac Mini" -ForegroundColor Yellow
    Write-Host "- SSH key authentication" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Step 2: Copying VNC Scripts to Mac Mini" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Copying VNC scripts to Mac Mini..." -ForegroundColor Blue

try {
    scp fix-mac-mini-vnc.sh "$MAC_MINI_USER@$MAC_MINI_HOST`:~/"
    scp connect-vnc-pi5-mac-mini.sh "$MAC_MINI_USER@$MAC_MINI_HOST`:~/"
    Write-Host "SUCCESS: VNC scripts copied to Mac Mini" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to copy VNC scripts" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Step 3: Running VNC Setup on Mac Mini" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Running VNC setup on Mac Mini..." -ForegroundColor Blue

try {
    ssh "$MAC_MINI_USER@$MAC_MINI_HOST" "chmod +x fix-mac-mini-vnc.sh connect-vnc-pi5-mac-mini.sh && ./fix-mac-mini-vnc.sh"
    Write-Host "SUCCESS: VNC setup completed on Mac Mini" -ForegroundColor Green
} catch {
    Write-Host "ERROR: VNC setup failed on Mac Mini" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Step 4: Ready to Connect to Pi5" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "VNC setup completed! You can now connect to Pi5 from Mac Mini." -ForegroundColor Green
Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. SSH to Mac Mini:" -ForegroundColor Green
Write-Host "   ssh $MAC_MINI_USER@$MAC_MINI_HOST" -ForegroundColor Blue
Write-Host ""
Write-Host "2. Run VNC connection script:" -ForegroundColor Green
Write-Host "   ./connect-vnc-pi5-mac-mini.sh" -ForegroundColor Blue
Write-Host ""
Write-Host "3. Or direct VNC command:" -ForegroundColor Green
Write-Host "   vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST`:5900" -ForegroundColor Blue
Write-Host ""
Write-Host "4. One-liner from Windows 11:" -ForegroundColor Green
Write-Host "   ssh $MAC_MINI_USER@$MAC_MINI_HOST 'vncviewer -FullScreen=0 -Scaling=FitToWindow $PI5_HOST`:5900'" -ForegroundColor Blue
Write-Host ""

Write-Host "Key parameters that fix the Mac Mini VNC issues:" -ForegroundColor Yellow
Write-Host "- -FullScreen=0 (prevents fullscreen)" -ForegroundColor Yellow
Write-Host "- -Scaling=FitToWindow (fixes large text)" -ForegroundColor Yellow
Write-Host "- -Geometry=1024x768 (sets window size)" -ForegroundColor Yellow
Write-Host ""

Write-Host "==========================================" -ForegroundColor Purple
Write-Host "Setup Complete" -ForegroundColor Purple
Write-Host "==========================================" -ForegroundColor Purple
Write-Host "SUCCESS: Mac Mini VNC setup completed!" -ForegroundColor Green
Write-Host "SUCCESS: You can now SSH from Windows 11 to Mac Mini" -ForegroundColor Green
Write-Host "SUCCESS: VNC scripts are ready to use" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to continue"

