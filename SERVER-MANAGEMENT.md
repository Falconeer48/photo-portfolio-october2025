# Photo Portfolio Server Management

This document provides instructions for managing your photo portfolio server without needing AI assistance.

## Quick Start Commands

### Start the Server
```bash
./start-photo-portfolio.sh
```
This script will:
- Stop any existing Node.js processes
- Check if port 3000 is available
- Start the server with proper logging
- Verify the server is responding
- Test the API endpoint

### Stop the Server
```bash
./stop-photo-portfolio.sh
```
This script will:
- Find and stop the Node.js server process
- Verify the process is stopped
- Check if port 3000 is free

### Check Server Status
```bash
./status-photo-portfolio.sh
```
This script will show:
- Whether the server process is running
- Port usage status
- API response status
- Log file information
- Project directory status

### Restart the Server
```bash
./restart-photo-portfolio.sh
```
This script will stop and then start the server.

## Manual Server Management

If the scripts don't work, here are the manual commands:

### Start Server Manually
```bash
cd /media/ian/Externaldrive/Cursor_Projects/photo-portfolio
sudo NODE_ENV=production nohup node server.js > server.log 2>&1 &
```

### Stop Server Manually
```bash
sudo pkill -f "node server.js"
```

### Check if Server is Running
```bash
ps aux | grep "node server.js" | grep -v grep
```

### Check Port Usage
```bash
sudo lsof -i :3000
```

### View Server Logs
```bash
tail -f /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/server.log
```

## Troubleshooting

### Server Won't Start
1. Check if port 3000 is in use:
   ```bash
   sudo lsof -i :3000
   ```
2. Kill any processes using port 3000:
   ```bash
   sudo pkill -f "process_name"
   ```
3. Check the log file for errors:
   ```bash
   tail -20 /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/server.log
   ```

### Server Not Responding
1. Check if the process is running:
   ```bash
   ps aux | grep "node server.js" | grep -v grep
   ```
2. Test the API endpoint:
   ```bash
   curl http://localhost:3000/api/categories
   ```
3. Check if the dist directory exists:
   ```bash
   ls -la /media/ian/Externaldrive/Cursor_Projects/photo-portfolio/dist/
   ```

### Permission Issues
If you get permission errors:
```bash
sudo chown -R $USER:$USER /media/ian/Externaldrive/Cursor_Projects/photo-portfolio
chmod +x *.sh
```

### Missing Dependencies
If Node.js modules are missing:
```bash
cd /media/ian/Externaldrive/Cursor_Projects/photo-portfolio
npm install
```

## Configuration

The server runs on port 3000 by default. The main configuration files are:
- `server.js` - Main server file
- `src/config/portfolio.config.js` - Portfolio configuration
- `src/config/auth.config.js` - Authentication configuration

## File Locations

- **Project Directory**: `/media/ian/Externaldrive/Cursor_Projects/photo-portfolio`
- **Server Log**: `/media/ian/Externaldrive/Cursor_Projects/photo-portfolio/server.log`
- **Built Files**: `/media/ian/Externaldrive/Cursor_Projects/photo-portfolio/dist/`

## API Endpoints

- **Categories**: `http://localhost:3000/api/categories`
- **Images**: `http://localhost:3000/api/images/{category}`
- **Refresh Config**: `http://localhost:3000/api/refresh-config`

## Nginx Configuration

The server runs on HTTP port 3000, with nginx handling HTTPS and proxying requests. The nginx configuration should proxy requests from port 80/443 to port 3000.

## Backup and Recovery

### Backup Configuration
```bash
cp src/config/portfolio.config.js src/config/portfolio.config.js.backup
cp src/config/auth.config.js src/config/auth.config.js.backup
```

### Restore Configuration
```bash
cp src/config/portfolio.config.js.backup src/config/portfolio.config.js
cp src/config/auth.config.js.backup src/config/auth.config.js
```

## Monitoring

To monitor the server continuously:
```bash
watch -n 5 ./status-photo-portfolio.sh
```

This will check the server status every 5 seconds.

## Emergency Stop

If the server becomes unresponsive:
```bash
sudo pkill -9 -f "node server.js"
sudo lsof -i :3000 | awk 'NR>1 {print $2}' | xargs sudo kill -9
```

## Log Rotation

To prevent log files from growing too large:
```bash
# Add to crontab (crontab -e)
0 2 * * * /usr/bin/find /media/ian/Externaldrive/Cursor_Projects/photo-portfolio -name "*.log" -size +100M -exec truncate -s 0 {} \;
```

This will truncate log files larger than 100MB at 2 AM daily. 