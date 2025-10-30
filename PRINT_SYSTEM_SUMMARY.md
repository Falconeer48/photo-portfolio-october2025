# Pi5 Print Server Scripts Summary

## Overview
The Mac Mini uses the Pi5 as a print server for the Canon G4470 printer.

## Key Scripts

### test-print-pi5.sh
- Main printing script
- Uploads files to Pi5 and sends to printer via CUPS
- Usage: `./test-print-pi5.sh <file> [copies]`

### diagnose-pi5-print.sh  
- Diagnostic tool for printer connectivity
- Checks Pi5 and CUPS status

### print-pdf-manual.sh
- Manual PDF printing utility

## System Configuration
- **Pi5**: ian@192.168.50.243
- **Printer**: Canon_G4470  
- **CUPS**: Active on Pi5
- **Network**: 192.168.50.243

## Files Location
All scripts are in `/Volumes/ian/Scripts/`
