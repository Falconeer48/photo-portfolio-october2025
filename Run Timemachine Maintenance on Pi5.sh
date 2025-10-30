#!/bin/bash

# CONFIGURATION
LOG_DIR="$HOME/Library/Logs/tm_maintenance"
TIMESTAMP=$(date +%Y%m%d_%H%M)
SUMMARY_LOG="$LOG_DIR/summary_wrapper_${TIMESTAMP}.log"
SCRIPT_PATH="/Users/ian/Scripts/multi_tm_maintain_report.sh"
MOUNT_POINT="/Volumes/Timemachine"
SMB_TARGET="smb://mypi5.local/Timemachine"

# SETUP
mkdir -p "$LOG_DIR"
echo "========== Time Machine Wrapper Script – $(date) ==========" > "$SUMMARY_LOG"

# STEP 0: Abort if backup is in progress
echo "[CHECK] Checking if Time Machine is running..." | tee -a "$SUMMARY_LOG"
if tmutil status | grep -q "Running = 1"; then
  echo "[ABORT] Time Machine backup is active. Exiting." | tee -a "$SUMMARY_LOG"
  osascript -e "display notification \"Backup in progress. Maintenance postponed.\" with title \"TM Maintenance\" sound name \"Basso\""
  exit 1
fi

# STEP 1: Stop and clean up previous mounts
echo "[STEP 1] Disabling Time Machine and unmounting residual volumes..." | tee -a "$SUMMARY_LOG"
sudo tmutil stopbackup >> "$SUMMARY_LOG" 2>&1
sudo tmutil disable >> "$SUMMARY_LOG" 2>&1

# Attempt unmount of any lingering .timemachine volumes
for VOL in /Volumes/.timemachine* "$MOUNT_POINT"; do
  if mount | grep -q "$VOL"; then
    echo "[CLEANUP] Attempting to unmount $VOL..." | tee -a "$SUMMARY_LOG"
    diskutil unmount force "$VOL" >> "$SUMMARY_LOG" 2>&1
  fi
done

sleep 5

# STEP 2: Mount the SMB share if not mounted
echo "[STEP 2] Verifying Time Machine share mount..." | tee -a "$SUMMARY_LOG"
if ! mount | grep -q "$MOUNT_POINT"; then
  echo "[MOUNT] Attempting to mount $SMB_TARGET..." | tee -a "$SUMMARY_LOG"
  open "$SMB_TARGET"
  sleep 10
  if ! mount | grep -q "$MOUNT_POINT"; then
    echo "[ERROR] Failed to mount $SMB_TARGET." | tee -a "$SUMMARY_LOG"
    osascript -e "display notification \"Mount failed: Timemachine share unavailable.\" with title \"TM Maintenance\" sound name \"Basso\""
    sudo tmutil enable >> "$SUMMARY_LOG" 2>&1
    exit 1
  else
    echo "[SUCCESS] Time Machine share mounted successfully." | tee -a "$SUMMARY_LOG"
  fi
else
  echo "[INFO] Time Machine share already mounted at $MOUNT_POINT." | tee -a "$SUMMARY_LOG"
fi

# STEP 3: Execute the maintenance script
echo "[STEP 3] Executing maintenance script..." | tee -a "$SUMMARY_LOG"
if [ -x "$SCRIPT_PATH" ]; then
  "$SCRIPT_PATH" >> "$SUMMARY_LOG" 2>&1
  MAINTENANCE_STATUS=$?
  echo "[INFO] Maintenance script exited with status $MAINTENANCE_STATUS" | tee -a "$SUMMARY_LOG"
else
  echo "[ERROR] Maintenance script not found or not executable: $SCRIPT_PATH" | tee -a "$SUMMARY_LOG"
  osascript -e "display notification \"Maintenance script not found or not executable.\" with title \"TM Maintenance\" sound name \"Basso\""
  sudo tmutil enable >> "$SUMMARY_LOG" 2>&1
  exit 1
fi

# STEP 4: Re-enable Time Machine
echo "[STEP 4] Re-enabling Time Machine..." | tee -a "$SUMMARY_LOG"
sudo tmutil enable >> "$SUMMARY_LOG" 2>&1

# STEP 5: Notify user
if [ "$MAINTENANCE_STATUS" -eq 0 ]; then
  osascript -e "display notification \"Time Machine maintenance completed successfully.\" with title \"TM Maintenance\" sound name \"Ping\""
  echo "[DONE] Script completed successfully." | tee -a "$SUMMARY_LOG"
else
  osascript -e "display notification \"Maintenance completed with errors.\" with title \"TM Maintenance Warning\" sound name \"Basso\""
  echo "[DONE] Script completed with errors. See log for details." | tee -a "$SUMMARY_LOG"
fi