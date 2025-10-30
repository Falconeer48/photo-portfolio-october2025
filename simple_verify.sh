#!/bin/bash
echo "=== Speedtest Crontab Verification ==="
echo "1. Cron service: $(systemctl is-active cron)"
echo "2. Crontab entries:"
crontab -l | grep speedtest
echo "3. Script exists: $([ -f /home/ian/speedtest/robust_speedtest.py ] && echo 'YES' || echo 'NO')"
echo "4. Script executable: $([ -x /home/ian/speedtest/robust_speedtest.py ] && echo 'YES' || echo 'NO')"
echo "5. Log directory: $([ -d /home/ian/speedtest ] && echo 'EXISTS' || echo 'MISSING')"
echo "6. Network test: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
echo "=== End Verification ==="







