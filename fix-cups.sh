#!/bin/bash
set -euo pipefail

echo "== Stop printing UI helpers =="
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
# Kill Add Printer window and helpers
sudo pkill -f '/System/Library/CoreServices/AddPrinter.app/Contents/MacOS/AddPrinter' || true
sudo pkill -f '[P]rintCenterWidgetExtension.macOS' || true
sudo pkill -f '[P]rinterScannerSettings.appex/Contents/MacOS/PrinterScannerSettings' || true
sudo pkill -f '[P]rintUITool' || true
sudo pkill -f '[p]rinttool' || true

echo "== Check for remote CUPS override =="
if [ -f /etc/cups/client.conf ]; then
  echo "Found /etc/cups/client.conf:"
  cat /etc/cups/client.conf || true
  TS=$(date +%s)
  echo "Disabling client.conf -> /etc/cups/client.conf.disabled.$TS"
  sudo mv /etc/cups/client.conf "/etc/cups/client.conf.disabled.$TS"
else
  echo "No /etc/cups/client.conf present."
fi

echo "== Hard stop and restart CUPS (no kickstart) =="
sudo pkill -9 cupsd 2>/dev/null || true
sudo launchctl bootout system /System/Library/LaunchDaemons/org.cups.cupsd.plist 2>/dev/null || true
sudo launchctl bootstrap system /System/Library/LaunchDaemons/org.cups.cupsd.plist
sudo launchctl enable system/org.cups.cupsd

echo "== Verify CUPS =="
echo "- lpstat -r:"
lpstat -r || true

echo "- Listener on 631:"
sudo lsof -nP -iTCP:631 -sTCP:LISTEN || true

echo "- HTTP check:"
curl -Is http://localhost:631 | head -n1 || true

echo "== Done. If the three checks look good, try 'Printers & Scanners' again, then add the Canon G4470."
