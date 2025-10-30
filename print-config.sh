#!/bin/bash

# Print Configuration File
# Edit these settings to match your setup

# iMac connection settings
export IMAC_USER="iancook"               # Your iMac username
export IMAC_HOST="Ians-iMac.local"       # Your iMac's hostname
export IMAC_SSH_KEY="$HOME/.ssh/id_rsa"      # SSH key for connecting to iMac

# Printer settings
export PRINTER_NAME="Canon_G4070_series" # Name of the printer on iMac
export DEFAULT_COPIES=1                   # Default number of copies

# Print options (optional)
export DEFAULT_OPTIONS=""                 # Default print options (e.g., "media=A4,duplex=long-edge")

# Network settings
export PING_TIMEOUT=5                     # Ping timeout in seconds (increased for hostname resolution)
export SSH_TIMEOUT=10                     # SSH connection timeout in seconds

# File handling
export MAX_FILE_SIZE_MB=100              # Maximum file size to print (MB)
export SUPPORTED_EXTENSIONS="pdf,jpg,jpeg,png,gif,bmp,tiff,doc,docx,txt,rtf"  # Supported file types
