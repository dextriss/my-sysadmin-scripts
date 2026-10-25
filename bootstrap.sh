#!/bin/bash
# monitor.sh — мониторинг ресурсов
# Использование: ./script.sh [интервал_в_секундах]
# По умолчанию интервал 5 секунд.

INTERVAL="${1:-5}"
LOGFILE="monitor.log"

# Проверка: интервал должен быть положительным целым числом
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -eq 0 ]]; then
    echo "Ошибка: интервал должен быть положительным целым числом (например, 5)" >&2
    exit 1
fi

# Проверка прав на запись в лог-файл
if ! touch "$LOGFILE" 2>/dev/null; then
    echo "Ошибка: не удалось создать или записать в файл $LOGFILE. Проверьте права доступа." >&2
    exit 1
fi

echo "Мониторинг запущен. Интервал: ${INTERVAL}с. Лог: $LOGFILE"
echo "Для остановки нажмите Ctrl+C"

trap 'echo; echo "Мониторинг остановлен."; exit 0' INT

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "--- $timestamp ---" >> "$LOGFILE"
    
    echo "# free -h" >> "$LOGFILE"
    free -h >> "$LOGFILE"
    
    echo "# df -h" >> "$LOGFILE"
    df -h >> "$LOGFILE"
    
    echo "# uptime" >> "$LOGFILE"
    uptime >> "$LOGFILE"
    
    echo "" >> "$LOGFILE"
    sleep "$INTERVAL"
done
