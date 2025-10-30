#!/bin/bash
cd "/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio"
/Users/ian/Scripts/validate-structure.sh --auto-setup
sleep 2
osascript -e 'tell application "Terminal" to quit' &
exit 0 