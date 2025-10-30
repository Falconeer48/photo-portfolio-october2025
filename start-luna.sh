#!/bin/bash

IMAC_HOST="Ians-iMac.local"
SSH_USER="iancook"
SCRIPT_PATH="/Users/iancook/Library/Scripts/Launch Luna Secondary on iMac.scpt"
IMAC_MAC="AC:87:A3:03:E4:42"
MAX_PING_WAIT_SECONDS=60
MAX_SSH_RETRIES=5
SSH_RETRY_INTERVAL=2
SKIP_WOL=false

# Handle flag
[[ "$1" == "--no-wol" ]] && SKIP_WOL=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/luna_display.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[`date`] ==== Luna Display Launch Started ===="

# Wake-on-LAN
if [ "$SKIP_WOL" = false ]; then
  echo "[`date`] Sending Wake-on-LAN to $IMAC_MAC"
  wakeonlan "$IMAC_MAC"
else
  echo "[`date`] Wake-on-LAN skipped via --no-wol"
fi

# Wait for ping response
echo "[`date`] Waiting for $IMAC_HOST to respond..."
SECONDS_WAITED=0
while ! ping -c 1 -W 1 "$IMAC_HOST" &>/dev/null; do
  sleep 1
  ((SECONDS_WAITED++))
  if (( SECONDS_WAITED >= MAX_PING_WAIT_SECONDS )); then
    echo "[`date`] ❌ iMac unreachable after $MAX_PING_WAIT_SECONDS seconds"
    osascript -e 'display notification "iMac is offline or unreachable." with title "Luna Launch Failed"'
    exit 1
  fi
done
echo "[`date`] ✅ iMac reachable after $SECONDS_WAITED seconds"

# Launch Luna locally
echo "[`date`] Launching Luna Display locally"
open -a "Luna Display" &

# Refresh SSH key
echo "[`date`] Refreshing SSH known_hosts"
ssh-keygen -R "$IMAC_HOST" >/dev/null 2>&1
ssh-keyscan -H "$IMAC_HOST" >> ~/.ssh/known_hosts 2>/dev/null

# Try SSH and validate Luna is running
RETRY=0
while (( RETRY < MAX_SSH_RETRIES )); do
  if ssh -o ConnectTimeout=10 "$SSH_USER@$IMAC_HOST" '
    osascript "'"$SCRIPT_PATH"'" &&
    sleep 10 &&
    pgrep -x "Luna Display" > /dev/null
  '; then
    echo "[`date`] ✅ Luna Secondary running on iMac"
    osascript -e 'display notification "Luna Display Secondary is live." with title "Luna Launch Success"'
    echo "[`date`] ==== Script Completed ===="
    exit 0
  else
    echo "[`date`] ⚠️ SSH attempt $((RETRY+1)) failed or Luna not running"
    ((RETRY++))
    sleep "$SSH_RETRY_INTERVAL"
  fi
done

# If all fail
echo "[`date`] ❌ All SSH retries failed or Luna not detected"
osascript -e 'display notification "SSH or Luna launch failed." with title "Luna Launch Failed"'
exit 1