# Cursor Health Monitoring Scripts

## Summary of the Issue

Your Cursor AI was running slowly because:

1. **DNS Issue (FIXED)**: A hosts file entry was redirecting `api.cursor.sh` to `api.cursor.com`, causing SSL certificate mismatches
2. **Resource Bloat (FIXED)**: The extension-host process had been running for **9+ days** (218 hours), consuming:
   - 35.9% CPU
   - 17.7% memory (3GB)
   
This is why responses were slow compared to ChatGPT.

## Scripts Available

### 1. `check_cursor_health.sh` - Manual Health Check

**Purpose**: Check Cursor's resource usage and identify issues

**Usage**:
```bash
./check_cursor_health.sh
```

**What it checks**:
- CPU usage per process (alerts if > 50%)
- Memory usage per process (alerts if > 15%)
- Runtime (alerts if > 48 hours)
- Shows total resource summary
- Shows longest running process

**⚠️ IMPORTANT**: High CPU (100%) is **NORMAL** when actively using Cursor AI!
- The AI uses CPU to process your requests
- Only a problem if high CPU persists when idle

**Example output**:
```
✓ All Cursor processes are healthy
Total Cursor processes: 14
Total CPU usage: 28.2%
Total Memory usage: 6.1%
```

### 2. `check_cursor_idle.sh` - Idle Resource Check (NEW!)

**Purpose**: Check if Cursor is using excessive resources when it SHOULD be idle

**Usage**:
```bash
./check_cursor_idle.sh
```

**When to use**: 
- Run this when you're **NOT** actively using Cursor AI
- Wait 30+ seconds after your last AI request
- Checks for true resource problems vs. normal AI processing

**What it checks**:
- CPU > 20% while idle (problem)
- Memory > 10% (problem)
- Runtime > 72 hours (problem)

**This is the better script for detecting real issues!**

### 3. `auto_restart_cursor.sh` - Automatic Restart

**Purpose**: Automatically restart Cursor if it's consuming too many resources

**Usage**:
```bash
./auto_restart_cursor.sh
```

**Thresholds**:
- Restarts if memory > 15%
- Restarts if runtime > 72 hours (3 days)

**Use with cron** (optional - runs daily at 2am):
```bash
# Edit crontab
crontab -e

# Add this line:
0 2 * * * /Users/ian/Scripts/auto_restart_cursor.sh >> /Users/ian/Scripts/cursor_health.log 2>&1
```

## Recommended Practices

1. **Restart Cursor regularly** - At least once every few days to prevent resource buildup
2. **Run health check weekly** - Use `check_cursor_health.sh` to monitor
3. **Watch for warning signs**:
   - Slow AI responses
   - High fan noise (indicates high CPU)
   - UI lag or freezing

## Adjusting Thresholds

You can edit the scripts to change thresholds:

In `check_cursor_health.sh`:
```bash
MAX_CPU_PERCENT=50        # Alert if CPU > 50%
MAX_MEMORY_PERCENT=15     # Alert if memory > 15%
MAX_RUNTIME_HOURS=48      # Alert if running > 48 hours
```

In `auto_restart_cursor.sh`:
```bash
MAX_MEMORY_PERCENT=15     # Auto-restart if memory > 15%
MAX_RUNTIME_HOURS=72      # Auto-restart if running > 72 hours
```

## What We Fixed Today

1. ✅ Removed incorrect hosts file entry (`api.cursor.sh`)
2. ✅ Flushed DNS cache
3. ✅ Restarted Cursor to clear bloated processes
4. ✅ Created monitoring scripts for future prevention

## Quick Commands

```bash
# Check Cursor health
./check_cursor_health.sh

# Auto-restart if needed
./auto_restart_cursor.sh

# Manually restart Cursor
killall Cursor

# View current Cursor processes
ps aux | grep -i cursor | grep -v grep

# Check total resource usage
ps aux | grep -i cursor | awk '{cpu+=$3; mem+=$4} END {print "CPU: "cpu"% Memory: "mem"%"}'
```

## Expected Performance

After the fixes:
- AI responses should be similar in speed to ChatGPT
- No more "not replying at all" issues
- Cursor should feel responsive and snappy

If you still experience slowness, run the health check script to see what's consuming resources.

