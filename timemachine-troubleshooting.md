# Apple Time Machine Setup for Raspberry Pi 5 - Troubleshooting Guide

## Quick Setup Instructions

1. **Run the setup script:**
   ```bash
   chmod +x timemachine-setup.sh
   sudo ./timemachine-setup.sh
   ```

2. **On your Mac:**
   - Open System Preferences > Time Machine
   - Click "Select Backup Disk"
   - Look for "raspberrypi-timemachine" or "Time Machine"
   - Select it and enter your Mac credentials

## Troubleshooting Common Issues

### Time Machine Server Not Appearing on Mac

**Problem:** The Time Machine server doesn't show up in the backup disk selection.

**Solutions:**
1. **Check Bonjour/mDNS:**
   ```bash
   sudo systemctl status avahi-daemon
   sudo avahi-browse -t _smb._tcp
   ```

2. **Restart services:**
   ```bash
   sudo systemctl restart avahi-daemon
   sudo systemctl restart smbd
   sudo systemctl restart netatalk
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 445/tcp
   sudo ufw allow 548/tcp
   sudo ufw allow 5353/udp
   ```

4. **On Mac:** Try restarting your network connection or restarting your Mac.

### Permission Denied Errors

**Problem:** Mac can't access the Time Machine share due to permission issues.

**Solutions:**
1. **Check Samba user:**
   ```bash
   sudo smbpasswd -e your_mac_username
   ```

2. **Reset permissions:**
   ```bash
   sudo chown -R timemachine:timemachine /mnt/timemachine
   sudo chmod -R 755 /mnt/timemachine
   ```

3. **Verify Samba configuration:**
   ```bash
   sudo testparm /etc/samba/smb.conf
   ```

### Backup Fails or Stops

**Problem:** Time Machine backup starts but fails or stops unexpectedly.

**Solutions:**
1. **Check disk space:**
   ```bash
   df -h /mnt/timemachine
   ```

2. **Check logs:**
   ```bash
   sudo tail -f /var/log/samba/log.smbd
   sudo tail -f /var/log/netatalk.log
   ```

3. **Increase backup size limit in smb.conf:**
   ```bash
   sudo nano /etc/samba/smb.conf
   # Change: fruit:time machine max size = 1T
   sudo systemctl restart smbd
   ```

### Slow Backup Performance

**Problem:** Time Machine backups are very slow.

**Solutions:**
1. **Use wired Ethernet connection** instead of Wi-Fi
2. **Check network speed:**
   ```bash
   iperf3 -s  # On Pi
   iperf3 -c pi_ip_address  # On Mac
   ```
3. **Optimize Samba settings** (add to [global] section in smb.conf):
   ```
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
   read raw = yes
   write raw = yes
   max xmit = 65536
   dead time = 15
   ```

## Advanced Configuration

### Custom Backup Size Limits

Edit `/etc/samba/smb.conf` and modify:
```
fruit:time machine max size = 1T  # Change to desired size
```

### Multiple Mac Support

Add additional users:
```bash
sudo smbpasswd -a another_mac_username
```

Then add them to the TimeMachine share in smb.conf:
```
valid users = username1,username2,username3
```

### External Drive Setup

If using an external drive:

1. **Mount external drive:**
   ```bash
   sudo mkdir /mnt/external
   sudo mount /dev/sda1 /mnt/external  # Adjust device as needed
   ```

2. **Update fstab for automatic mounting:**
   ```bash
   echo "/dev/sda1 /mnt/external ext4 defaults 0 2" | sudo tee -a /etc/fstab
   ```

3. **Update Time Machine path in configurations:**
   - Change `TIMEMACHINE_SHARE` in the setup script
   - Update paths in `/etc/samba/smb.conf` and `/etc/netatalk/afp.conf`

### Security Enhancements

1. **Enable SMB signing:**
   Add to `[global]` section in smb.conf:
   ```
   server signing = mandatory
   ```

2. **Restrict access by IP:**
   Add to `[TimeMachine]` section:
   ```
   hosts allow = 192.168.1.0/24  # Adjust subnet as needed
   ```

## Monitoring and Maintenance

### Check Service Status
```bash
sudo systemctl status smbd nmbd avahi-daemon netatalk
```

### View Logs
```bash
# Samba logs
sudo tail -f /var/log/samba/log.smbd

# Netatalk logs
sudo tail -f /var/log/netatalk.log

# Avahi logs
sudo journalctl -u avahi-daemon -f
```

### Backup Cleanup
The setup script includes automatic cleanup, but you can run manually:
```bash
sudo /usr/local/bin/timemachine-cleanup.sh
```

### Performance Monitoring
```bash
# Check network usage
sudo iftop

# Check disk I/O
sudo iotop

# Check memory usage
free -h
```

## Useful Commands Reference

```bash
# Restart all Time Machine services
sudo systemctl restart smbd nmbd avahi-daemon netatalk

# Check if ports are listening
sudo netstat -tlnp | grep -E ':(445|548|5353)'

# Test Samba connection
smbclient -L localhost -U your_mac_username

# Browse available services
avahi-browse -t _smb._tcp

# Check mounted filesystems
mount | grep timemachine

# View active connections
sudo ss -tuln | grep -E ':(445|548|5353)'
```

## Recovery Procedures

### Reset Time Machine User Password
```bash
sudo smbpasswd -a your_mac_username
```

### Recreate Time Machine Share
```bash
sudo rm -rf /mnt/timemachine/*
sudo chown timemachine:timemachine /mnt/timemachine
sudo chmod 755 /mnt/timemachine
```

### Complete Service Reset
```bash
sudo systemctl stop smbd nmbd avahi-daemon netatalk
sudo systemctl start avahi-daemon
sudo systemctl start smbd nmbd
sudo systemctl start netatalk
```

