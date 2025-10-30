#!/bin/zsh
set -euo pipefail

QUEUE="${QUEUE:-DockerG4470}"
FILE="${1:-/Volumes/M2 Drive/M2 Downloads/TestPage.pdf}"
MODE="${2:-color}"   # color | mono

# Validate file
if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE"
  echo "Usage: $0 [PDF_PATH] [color|mono]"
  exit 1
fi

# Map mode to CUPS option
OPT=""
case "$MODE" in
  color|colour) OPT="-o print-color-mode=color" ;;
  mono|gray|grey|bw|blackwhite) OPT="-o print-color-mode=monochrome" ;;
  *) echo "Unknown mode: $MODE (use color or mono)"; exit 1 ;;
esac

echo "Queue: $QUEUE"
echo "File:  $FILE"
echo "Mode:  $MODE"

# Show key options
lpoptions -p "$QUEUE" -l | grep -i Color || true

# Submit job
JOB_OUT=$(lp -d "$QUEUE" $OPT "$FILE" || true)
echo "lp output: $JOB_OUT"

# Show current jobs and watch until this file is no longer listed
echo "Watching queue (Ctrl+C to stop)..."
for i in {1..30}; do
  lpstat -o "$QUEUE" | head -n 5 || true
  sleep 2
done
