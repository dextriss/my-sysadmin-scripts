# my-sysadmin-scripts

Сервис мониторинга системных метрик с HTTP-интерфейсом, reverse proxy на Nginx, HTTPS и автостартом через systemd.

## Что делает скрипт

Скрипт `script.sh` собирает метрики ресурсов системы и сохраняет их в файл `monitor.log`.

- Каждые N секунд (по умолчанию 5) снимает:
  - `free -h` — использование оперативной памяти.
  - `df -h` — свободное место на дисках.
  - `uptime` — время работы системы, количество пользователей и среднюю нагрузку.
- Добавляет временную метку перед каждым блоком данных.
- Поддерживает аргумент командной строки: `./script.sh <интервал_сек>`.

## Архитектура стенда

- **Контейнер**: образ `my-script`, внутри которого крутится `script.sh`. Контейнер слушает порт 8080 и отдаёт `monitor.log` по HTTP.
- **Nginx**: reverse proxy, принимает запросы на портах 80/443 и проксирует их на 8080 внутри контейнера.
- **HTTPS**: самоподписанный сертификат (openssl) для демонстрации терминации SSL на Nginx.
- **Автостарт**: systemd-юнит `my-app.service` управляет контейнером через `docker start`. Контейнер создаётся один раз (`docker create`) и далее не пересоздаётся.

## Как развернуть

1. Собери Docker-образ:

       docker build -t my-script .

2. Создай контейнер (один раз, дальше он управляется systemd):

       docker create --name my-app -p 8080:8080 -v /var/log:/var/log:ro my-script

3. Сгенерируй самоподписанный SSL-сертификат для Nginx:

       mkdir -p /etc/nginx/ssl
       openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
         -keyout /etc/nginx/ssl/selfsigned.key \
         -out /etc/nginx/ssl/selfsigned.crt \
         -subj "/CN=localhost"

4. Скопируй конфиг Nginx и активируй сайт:

       cp nginx-my-app.conf /etc/nginx/sites-available/my-app
       ln -s /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/my-app

5. Проверь конфиг и перезагрузи Nginx:

       nginx -t && systemctl reload nginx

6. Настрой и запусти сервис через systemd:

       systemctl daemon-reload
       systemctl enable my-app
       systemctl start my-app

## Важные нюансы

- **Ошибка `Conflict` при создании контейнера** — ожидаемое поведение: контейнер создаётся один раз, дальше им управляет systemd.
- **Ошибка Nginx `unknown directive "nginx"`** — возникала из-за попадания команды терминала в конфиг-файл. Исправлена удалением лишней строки.
- **Проверка через curl** — из-за самоподписанного сертификата нужен флаг `-k`. Ошибка `curl: (23)` — клиентская, на работу сервиса не влияет.

## Пример вывода метрик

Данные доступны по адресу: `https://45.149.113.154/monitor.log`

    --- 2026-10-13 21:43:22 ---
    # free -h
                   total        used        free      shared  buff/cache   available
    Mem:           1.9Gi       248Mi       289Mi       4.0Mi       1.4Gi       1.5Gi
    Swap:             0B          0B          0B
    # df -h
    Filesystem      Size  Used Avail Use% Mounted on
    overlay          19G  3.3G   16G  18% /
    tmpfs            64M     0   64M   0% /dev
    shm              64M     0   64M   0% /dev/shm
    /dev/sda1        19G  3.3G   16G  18% /var/log
    tmpfs           984M     0  984M   0% /proc/acpi
    tmpfs           984M     0  984M   0% /proc/scsi
    tmpfs           984M     0  984M   0% /sys/firmware
    # uptime

## Статус сервиса

Проверить работу можно командами:

    systemctl status my-app --no-pager
    docker ps --filter name=my-app
    curl -k https://127.0.0.1/monitor.log | head -n 15
