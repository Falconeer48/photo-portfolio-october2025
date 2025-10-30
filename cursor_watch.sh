#!/bin/sh
while true; do
  if dig +short api.cursor.sh | grep -qE '^[0-9]'; then
    echo "$(date): api.cursor.sh is back online!"
    exit 0
  else
    echo "$(date): still no DNS record..."
  fi
  sleep 60
done
