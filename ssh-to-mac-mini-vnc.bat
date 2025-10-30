@echo off
REM SSH to Mac Mini and Run VNC Commands
REM This batch file helps you SSH from Windows 11 to Mac Mini and run VNC scripts

echo ==========================================
echo SSH to Mac Mini VNC Setup
echo ==========================================
echo.

REM Configuration - Update these with your Mac Mini details
set MAC_MINI_HOST=192.168.50.XXX
set MAC_MINI_USER=your_username
set PI5_HOST=192.168.50.243

echo Before running this script, please update:
echo 1. MAC_MINI_HOST with your Mac Mini IP address
echo 2. MAC_MINI_USER with your Mac Mini username
echo.
echo Current settings:
echo Mac Mini Host: %MAC_MINI_HOST%
echo Mac Mini User: %MAC_MINI_USER%
echo Pi5 Host: %PI5_HOST%
echo.

pause

echo ==========================================
echo Step 1: Testing SSH Connection to Mac Mini
echo ==========================================
echo.

ssh -o ConnectTimeout=10 %MAC_MINI_USER%@%MAC_MINI_HOST% "echo SSH connection successful"

if %errorlevel% neq 0 (
    echo ERROR: SSH connection to Mac Mini failed
    echo Please check:
    echo - Mac Mini IP address
    echo - Username
    echo - SSH is enabled on Mac Mini
    echo - SSH key authentication
    pause
    exit /b 1
)

echo.
echo SUCCESS: SSH connection to Mac Mini successful
echo.

echo ==========================================
echo Step 2: Copying VNC Scripts to Mac Mini
echo ==========================================
echo.

echo Copying VNC scripts to Mac Mini...
scp fix-mac-mini-vnc.sh %MAC_MINI_USER%@%MAC_MINI_HOST%:~/
scp connect-vnc-pi5-mac-mini.sh %MAC_MINI_USER%@%MAC_MINI_HOST%:~/

echo.
echo SUCCESS: VNC scripts copied to Mac Mini
echo.

echo ==========================================
echo Step 3: Running VNC Setup on Mac Mini
echo ==========================================
echo.

echo Running VNC setup on Mac Mini...
ssh %MAC_MINI_USER%@%MAC_MINI_HOST% "chmod +x fix-mac-mini-vnc.sh connect-vnc-pi5-mac-mini.sh && ./fix-mac-mini-vnc.sh"

echo.
echo SUCCESS: VNC setup completed on Mac Mini
echo.

echo ==========================================
echo Step 4: Ready to Connect to Pi5
echo ==========================================
echo.

echo VNC setup completed! You can now connect to Pi5 from Mac Mini.
echo.
echo Quick commands:
echo.
echo 1. SSH to Mac Mini:
echo    ssh %MAC_MINI_USER%@%MAC_MINI_HOST%
echo.
echo 2. Run VNC connection script:
echo    ./connect-vnc-pi5-mac-mini.sh
echo.
echo 3. Or direct VNC command:
echo    vncviewer -FullScreen=0 -Scaling=FitToWindow %PI5_HOST%:5900
echo.
echo 4. One-liner from Windows 11:
echo    ssh %MAC_MINI_USER%@%MAC_MINI_HOST% "vncviewer -FullScreen=0 -Scaling=FitToWindow %PI5_HOST%:5900"
echo.

pause

