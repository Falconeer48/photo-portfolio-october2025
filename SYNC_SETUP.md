# Photo Portfolio Sync System

This system automatically syncs images from your Mac Mini to the Pi5 photo portfolio server, including support for folder deletions.

## Quick Start

### 1. Initial Setup
```bash
# Run the setup command to create the sync folder structure
./scripts/sync-to-pi5.sh setup
```

This will:
- Create `/Users/ian/Portfolio Images to Transfer` folder on your Mac Mini
- Mirror the current Pi5 folder structure locally
- Set up the sync environment

### 2. Manual Sync
```bash
# Sync all folders once (includes deletion detection)
./scripts/sync-to-pi5.sh sync
```

### 3. Automatic Sync (Recommended)
```bash
# Watch for changes and sync automatically
./scripts/sync-to-pi5.sh watch
```

## How It Works

### Folder Structure
```
/Users/ian/Portfolio Images to Transfer/
├── flora/
├── landscapes/
├── wildlife/
├── holidays/
├── doors_and_windows/
├── urban_landscapes/
└── safaris/
```

### Usage Workflow

1. **Add new images**: Place images in the appropriate folder under `/Users/ian/Portfolio Images to Transfer/`
2. **Remove folders**: Delete folders from the Mac Mini to remove them from Pi5
3. **Automatic sync**: The watch mode will detect changes and transfer files to Pi5
4. **Cache refresh**: The Pi5 server automatically refreshes its image cache
5. **Web app update**: New images appear in the web interface immediately

### File Transfer Details

- **Transfer method**: rsync over SSH
- **Excluded files**: .DS_Store, Thumbs.db, .tmp files
- **Progress tracking**: Shows transfer progress for each folder
- **Logging**: All sync activities are logged to `/Users/ian/photo-portfolio/sync.log`
- **Deletion support**: Automatically removes folders from Pi5 when deleted locally

## Commands

### Setup
```bash
./scripts/sync-to-pi5.sh setup
```
Creates the initial folder structure and sync environment.

### One-time Sync
```bash
./scripts/sync-to-pi5.sh sync
```
Syncs all folders once and removes any locally deleted folders from Pi5.

### Watch Mode
```bash
./scripts/sync-to-pi5.sh watch
```
Continuously monitors for changes and syncs automatically.

### Remove Specific Folder
```bash
./scripts/sync-to-pi5.sh remove <folder_name>
```
Manually removes a specific folder from Pi5 (e.g., `./scripts/sync-to-pi5.sh remove test`).

### Using the Launcher
Double-click `scripts/start-sync.command` to open Terminal and run the sync script.

## Folder Deletion

### Automatic Deletion
When you delete a folder from `/Users/ian/Portfolio Images to Transfer/`, the next sync operation will:
1. Detect that the folder no longer exists locally
2. Remove the corresponding folder from Pi5
3. Trigger a cache refresh on the web interface

### Manual Deletion
You can also manually remove folders from Pi5:
```bash
# Remove a specific folder
./scripts/sync-to-pi5.sh remove test

# Remove multiple folders
./scripts/sync-to-pi5.sh remove test
./scripts/sync-to-pi5.sh remove old_folder
```

### Safety Features
- Deletion only affects folders that exist on Pi5 but not locally
- System folders and the main portfolio folder are protected
- All deletion operations are logged
- Cache is automatically refreshed after deletions

## Requirements

### Mac Mini
- SSH access to Pi5 (SSH key authentication recommended)
- rsync (usually pre-installed)
- fswatch (for automatic watching - install with `brew install fswatch`)

### Pi5
- SSH server running
- Proper permissions for the photo portfolio directory

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connection
ssh ian@192.168.50.243 "echo 'Connection successful'"
```

### Permission Issues
```bash
# Check Pi5 directory permissions
ssh ian@192.168.50.243 "ls -la /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/public/images/portfolio"
```

### Manual Cache Refresh
If images don't appear on the web interface:
```bash
ssh ian@192.168.50.243 "touch /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/public/images/portfolio/metadata.json"
```

### View Sync Logs
```bash
tail -f /Users/ian/photo-portfolio/sync.log
```

### Check Deletion Status
```bash
# See what folders exist on Pi5
ssh ian@192.168.50.243 "ls -la /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/public/images/portfolio"

# Compare with local folders
ls -la "/Users/ian/Portfolio Images to Transfer"
```

## Advanced Configuration

### Custom Source Directory
Edit `scripts/sync-to-pi5.sh` and change the `SOURCE_DIR` variable:
```bash
SOURCE_DIR="/path/to/your/custom/folder"
```

### Custom Pi5 Settings
Edit the configuration variables in `scripts/sync-to-pi5.sh`:
```bash
PI5_HOST="your-pi5-ip"
PI5_PORT="22"
PI5_DEST_DIR="/path/to/pi5/portfolio"
```

## Security Notes

- Uses SSH for secure file transfer
- Excludes system files (.DS_Store, Thumbs.db)
- Logs all transfer and deletion activities
- Requires SSH key authentication for automated operation
- Deletion operations are logged for audit purposes

## Performance Tips

- Use watch mode for frequent updates
- Large files may take time to transfer
- Consider image optimization before transfer
- Monitor disk space on both systems
- Deletion operations are fast and efficient

## Examples

### Complete Workflow Example
```bash
# 1. Add new images to a folder
cp ~/Pictures/new_photos/* "/Users/ian/Portfolio Images to Transfer/flora/"

# 2. Sync to Pi5
./scripts/sync-to-pi5.sh sync

# 3. Later, remove a folder you don't want
rm -rf "/Users/ian/Portfolio Images to Transfer/test"

# 4. Sync again (will remove test folder from Pi5)
./scripts/sync-to-pi5.sh sync
```

### Watch Mode Example
```bash
# Start watching for changes (will handle both additions and deletions)
./scripts/sync-to-pi5.sh watch

# In another terminal, add or remove folders
# The watch mode will automatically sync changes
``` 