#!/bin/bash

echo "🔧 Uninstalling Network Cleanup components..."

# Stop and remove LaunchDaemon
if launchctl list | grep -q com.local.disable-unused-networks; then
  echo "Unloading LaunchDaemon..."
  sudo launchctl bootout system /Library/LaunchDaemons/com.local.disable-unused-networks.plist 2>/dev/null
fi
sudo rm -f /Library/LaunchDaemons/com.local.disable-unused-networks.plist

# Remove main script
sudo rm -f /usr/local/sbin/disable_unused_networks.sh

# Remove notification script
sudo rm -f /Library/Scripts/notify_network_cleanup.sh

# Remove newsyslog config
sudo rm -f /etc/newsyslog.d/disable_unused_networks.conf

# Remove logs
sudo rm -f /var/log/disable_unused_networks.log
sudo rm -f /var/log/disable_unused_networks_install.log

# Remove shared LaunchAgent (source file)
sudo rm -f /Users/Shared/Library/LaunchAgents/com.local.notify-network-cleanup.plist

# Remove LaunchAgent from each user
for USER_HOME in /Users/*; do
  USER_NAME=$(basename "$USER_HOME")
  if [[ "$USER_NAME" == "Shared" ]]; then continue; fi
  AGENT="$USER_HOME/Library/LaunchAgents/com.local.notify-network-cleanup.plist"
  if [ -f "$AGENT" ]; then
    echo "Removing LaunchAgent for $USER_NAME"
    sudo rm -f "$AGENT"
  fi
done

echo "✅ Uninstall complete."