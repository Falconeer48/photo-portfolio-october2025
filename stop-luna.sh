#!/bin/bash
# Quit Luna Display locally:
osascript -e 'tell application "Luna Display" to quit'

# Quit Luna Secondary on the iMac:
ssh iancook@Ians-iMac.local \
  'osascript -e "tell application \"Luna Secondary\" to quit"'