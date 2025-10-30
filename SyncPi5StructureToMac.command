#!/bin/bash
set -x
echo "Bash version: $(bash --version | head -n 1)"
echo "Current directory: $(pwd)"
echo "PATH: $PATH"
whoami
cd "/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio"
/Users/ian/Scripts/validate-structure.sh --sync-structure-from-pi5
read -p "Press Enter to close Terminal..."
osascript -e 'tell application "Terminal" to quit' &
exit 0 