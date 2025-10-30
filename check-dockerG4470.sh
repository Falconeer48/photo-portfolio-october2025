#!/bin/zsh
# Quick check to see if the Pi5 printer server is reachable, then re-enable queue

PRINTER="DockerG4470"
PI_IP="192.168.50.243"
LOGFILE="$HOME/printer-check.log"

# wait up to 20s for Pi5 to respond on port 631
for i in {1..20}; do
  nc -z $PI_IP 631 >/dev/null 2>&1 && break
  sleep 1
done

# if reachable, refresh printer queue
if nc -z $PI_IP 631 >/dev/null 2>&1; then
  /usr/sbin/cupsenable $PRINTER
  /usr/sbin/cupsaccept $PRINTER
  echo "$(date): $PRINTER is ready" >> "$LOGFILE"
else
  echo "$(date): $PRINTER not reachable" >> "$LOGFILE"
fi

# keep only the last 50 lines
tail -n 50 "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"