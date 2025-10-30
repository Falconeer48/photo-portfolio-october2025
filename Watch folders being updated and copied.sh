#!/bin/bash

# Wrapper to launch the Python watcher script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/watch-folders.py" "$@"




