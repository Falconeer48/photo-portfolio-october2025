# Photo Portfolio Scripts

This directory contains scripts for managing your photo portfolio sync process.

## Quick Start

### 1. Validate Your Structure (Recommended First Step)
Before adding any files, run the validation script to ensure your folder structure is correct:

```bash
# Basic validation
./scripts/validate-structure.sh

# Auto-create missing folders
./scripts/validate-structure.sh --auto-setup
```

This will:
- ✅ Check if all expected folders exist
- ✅ Count images in each folder
- ✅ Verify cover images are present
- ✅ Identify any issues before syncing
- ✅ **Auto-create missing folders** (with `--auto-setup` flag)

### 2. Setup (If Needed)
If you need to create the folder structure:

```bash
./scripts/sync-to-pi5.sh setup
```

This creates all the expected folders with the correct Mac naming convention.

### 3. Sync to Pi5
Once your structure is validated, sync to your Pi5:

```bash
./scripts/sync-to-pi5.sh sync
```

## Available Commands

### Validation Script
- `./scripts/validate-structure.sh` - Comprehensive structure validation
- `./scripts/validate-structure.sh --auto-setup` - Validate and auto-create missing folders
- `./scripts/validate-structure.sh --help` - Show usage information

### Sync Script
- `./scripts/sync-to-pi5.sh validate` - Validate structure (same as above)
- `./scripts/sync-to-pi5.sh setup` - Create folder structure
- `./scripts/sync-to-pi5.sh sync` - Sync once to Pi5
- `./scripts/sync-to-pi5.sh watch` - Watch for changes and auto-sync
- `./scripts/sync-to-pi5.sh remove <folder>` - Remove folder from Pi5

## Expected Folder Structure

Your Mac should have these folders (with underscores):
```
/Users/ian/Portfolio Images to Transfer/
├── doors_and_windows/
├── urban_landscapes/
├── flora/
├── holidays/
├── landscapes/
├── psc_course/
├── safaris/
├── wildlife/
├── family_and_friends/
├── south_africa/
├── australia/
└── hms_victory/
```

These will be automatically mapped to Pi5 with proper spacing:
- `doors_and_windows` → `Doors and Windows`
- `urban_landscapes` → `Urban Landscapes`
- etc.

## Best Practices

1. **Always validate first**: Run `./scripts/validate-structure.sh` before adding files
2. **Use Cover.jpg**: Add a cover image to each folder for better display
3. **Check before syncing**: The validation script will warn you about any issues
4. **Monitor the log**: Check `/Users/ian/photo-portfolio/sync.log` for sync history

## Troubleshooting

### Common Issues:
- **Missing folders**: Run `./scripts/sync-to-pi5.sh setup`
- **Empty folders**: Add images before syncing
- **No cover images**: Add `Cover.jpg` to folders for better display
- **Connection issues**: Check Pi5 IP address in the script configuration

### Log File:
Check `/Users/ian/photo-portfolio/sync.log` for detailed sync information. 