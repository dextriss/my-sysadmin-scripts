#!/bin/bash
# monitor.sh — мониторинг ресурсов: free, df, uptime → monitor.log

INTERVAL=5
LOGFILE="monitor.log"

while true; do
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOGFILE"
    free -h >> "$LOGFILE"
    df -h >> "$LOGFILE"
    uptime >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    sleep "$INTERVAL"
done
