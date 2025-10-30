#!/bin/bash
# Control script for Xiaomi BLE to MQTT Bridge
# Quick commands to manage the service on your Raspberry Pi

PI_HOST="pi@192.168.1.XXX"  # Update with your Bridge Pi's IP
SERVICE_NAME="xiaomi-ble-bridge.service"

case "$1" in
    start)
        echo "Starting Xiaomi BLE Bridge..."
        ssh $PI_HOST "sudo systemctl start $SERVICE_NAME"
        ;;
    stop)
        echo "Stopping Xiaomi BLE Bridge..."
        ssh $PI_HOST "sudo systemctl stop $SERVICE_NAME"
        ;;
    restart)
        echo "Restarting Xiaomi BLE Bridge..."
        ssh $PI_HOST "sudo systemctl restart $SERVICE_NAME"
        ;;
    status)
        echo "Checking Xiaomi BLE Bridge status..."
        ssh $PI_HOST "sudo systemctl status $SERVICE_NAME"
        ;;
    logs)
        echo "Showing Xiaomi BLE Bridge logs (Ctrl+C to exit)..."
        ssh $PI_HOST "sudo journalctl -u $SERVICE_NAME -f"
        ;;
    logs-recent)
        echo "Showing recent Xiaomi BLE Bridge logs..."
        ssh $PI_HOST "sudo journalctl -u $SERVICE_NAME -n 50"
        ;;
    enable)
        echo "Enabling Xiaomi BLE Bridge to start on boot..."
        ssh $PI_HOST "sudo systemctl enable $SERVICE_NAME"
        ;;
    disable)
        echo "Disabling Xiaomi BLE Bridge auto-start..."
        ssh $PI_HOST "sudo systemctl disable $SERVICE_NAME"
        ;;
    edit)
        echo "Editing configuration..."
        ssh $PI_HOST "sudo nano /opt/xiaomi-ble-bridge/xiaomi_ble_mqtt_bridge.py"
        ;;
    scan)
        echo "Scanning for Bluetooth devices..."
        echo "Press Ctrl+C when you see your device"
        ssh $PI_HOST "sudo timeout 20 hcitool lescan"
        ;;
    *)
        echo "Xiaomi BLE to MQTT Bridge Control"
        echo "=================================="
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs|logs-recent|enable|disable|edit|scan}"
        echo ""
        echo "Commands:"
        echo "  start        - Start the bridge service"
        echo "  stop         - Stop the bridge service"
        echo "  restart      - Restart the bridge service"
        echo "  status       - Show service status"
        echo "  logs         - Show live logs (Ctrl+C to exit)"
        echo "  logs-recent  - Show last 50 log lines"
        echo "  enable       - Enable auto-start on boot"
        echo "  disable      - Disable auto-start"
        echo "  edit         - Edit configuration file"
        echo "  scan         - Scan for BLE devices to find MAC address"
        echo ""
        echo "Note: Update PI_HOST in this script with your Raspberry Pi's IP"
        exit 1
        ;;
esac


