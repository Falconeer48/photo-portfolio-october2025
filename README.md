# Apple Time Machine Setup for Raspberry Pi 5

This repository contains scripts and documentation to set up your Raspberry Pi 5 as an Apple Time Machine backup server.

## Quick Start

1. **Clone or download the scripts to your Pi 5**
2. **Run the setup script:**
   ```bash
   chmod +x timemachine-setup.sh
   sudo ./timemachine-setup.sh
   ```
3. **On your Mac:** Open System Preferences > Time Machine and select the Pi as your backup disk

## What's Included

- `timemachine-setup.sh` - Complete automated setup script
- `timemachine-status.sh` - Status checker and diagnostics
- `timemachine-troubleshooting.md` - Comprehensive troubleshooting guide

## Features

- ✅ **Samba (SMB/CIFS)** - Primary file sharing protocol
- ✅ **Netatalk (AFP)** - Apple Filing Protocol support
- ✅ **Avahi (Bonjour/mDNS)** - Automatic service discovery
- ✅ **Automatic cleanup** - Removes old backups to save space
- ✅ **Firewall configuration** - Opens necessary ports
- ✅ **User management** - Secure access control
- ✅ **Logging** - Comprehensive logging for troubleshooting

## Requirements

- Raspberry Pi 5 running Raspberry Pi OS
- External storage (recommended) or sufficient SD card space
- Mac computer for backup
- Both devices on the same network

## Storage Recommendations

- **Minimum:** 2x the size of your Mac's storage
- **Recommended:** 3-4x the size of your Mac's storage
- **External drive:** Use USB 3.0+ external drive for better performance

## Network Requirements

- Both Pi and Mac must be on the same local network
- Ports 445 (SMB), 548 (AFP), and 5353 (Bonjour) must be accessible
- Wired Ethernet recommended for best performance

## Security Notes

- The setup creates a dedicated user account for Time Machine
- Samba passwords are required for access
- Consider restricting access by IP range for additional security

## Troubleshooting

If you encounter issues:

1. **Run the status checker:**
   ```bash
   sudo ./timemachine-status.sh
   ```

2. **Check the troubleshooting guide:** `timemachine-troubleshooting.md`

3. **Common solutions:**
   - Restart services: `sudo systemctl restart smbd nmbd avahi-daemon netatalk`
   - Check firewall: `sudo ufw status`
   - Verify network connectivity between Pi and Mac

## Performance Tips

- Use wired Ethernet instead of Wi-Fi
- Use external USB 3.0+ drive instead of SD card
- Ensure adequate power supply for Pi 5
- Consider using SSD for better performance

## Maintenance

The setup includes automatic cleanup of old backups. You can also:

- Monitor disk usage: `df -h /mnt/timemachine`
- Check service status: `sudo systemctl status smbd avahi-daemon netatalk`
- View logs: `sudo tail -f /var/log/samba/log.smbd`

## Support

For issues not covered in the troubleshooting guide:

1. Check the logs for error messages
2. Verify network connectivity
3. Ensure all services are running
4. Check firewall and port accessibility

## License

This project is provided as-is for educational and personal use.

