# Pi5 Printer Server Status - Canon G4470

## Current Setup ✅

### Pi5 Status:
- **Printer Name**: `Canon_G4470`
- **Status**: Idle and Enabled
- **CUPS Service**: Active and Running
- **Connection**: Direct USB connection (presumed)

### Mac Mini Scripts (Located in /Volumes/ian/Scripts):

#### 1. **test-print-pi5.sh** - Main Printing Script
- Sends files to Pi5 for printing
- Copies file to Pi5 via SSH/SCP
- Submits print job using CUPS `lp` command
- **Usage**: `./test-print-pi5.sh <file> [copies]`
- **Printer**: Canon_G4470

#### 2. **diagnose-pi5-print.sh** - Diagnostic Tool
- Checks Pi5 connectivity
- Tests printer status
- Verifies CUPS service

#### 3. **setup-print.sh** - Configuration Setup
- Interactive setup for iMac printer
- Creates print-config.sh
- Tests connections

#### 4. **check-pi-printer.sh** - Status Checker
- Quick status check

#### 5. **print-pdf-manual.sh** - Manual PDF Printing
- For printing PDFs manually

## How to Use

### Send a file from Mac Mini to Pi5 for printing:

```bash
cd /Volumes/ian/Scripts
./test-print-pi5.sh /path/to/file.pdf
```

### Check printer status:

```bash
./check-pi-printer.sh
```

### Run diagnostics:

```bash
./diagnose-pi5-print.sh
```

## Network Configuration

- **Pi5**: ian@192.168.50.243
- **SSH Key**: ~/.ssh/id_ed25519
- **CUPS**: Port 631 (default)

## Supported File Types

Based on the scripts:
- PDF
- Images: JPG, PNG, GIF, BMP, TIFF
- Documents: DOC, DOCX, TXT, RTF

## Notes

- The Canon printer driver files are located at `/home/ian/Canon-printer-server/`
- The setup script is compressed and may need extraction
- CUPS web interface is available at http://192.168.50.243:631


