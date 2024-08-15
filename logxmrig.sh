#!/bin/bash

# Цветовые переменные для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Переменные
XMRIG_PATH="/opt/xmrig"
LOG_FILE="/dev/shm/xmrig.log"
ERROR_LOG_DIR="$XMRIG_PATH/error_logs"
ERROR_LOG_FILE="$ERROR_LOG_DIR/error.log"
MONITOR_SCRIPT="/usr/local/bin/monitor_xmrig.sh"
WALLET="4A9SeKhwWx8DtAboVp1e1LdbgrRJxvjEFNh4VNw1NDng6ELLeKJPVrPQ9n9eNc4iLVC4BKeR4egnUL68D1qUmdJ7N3TaB5w"
PROXY="socks5://username:password@proxy-server:1080"  # Замените на данные вашего прокси

# Логирование
exec > >(tee -a "$LOG_FILE") 2>&1

# Функция для обработки ошибок
handle_error() {
    echo -e "${RED}Произошла ошибка: $1${NC}"
    mkdir -p "$ERROR_LOG_DIR"  # Убедимся, что директория для логов ошибок существует
    echo "$(date) - $1" >> "$ERROR_LOG_FILE"
    exit 1
}

# Проверка и установка необходимых команд
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        handle_error "$1 не установлен. Установите его и повторите попытку."
    fi
}

# Проверка и установка зависимостей
echo -e "${YELLOW}Проверка и установка необходимых команд...${NC}"
check_command git
check_command cmake
check_command make
check_command screen
check_command cpulimit
check_command crontab

echo -e "${BLUE}Определение пакетного менеджера...${NC}"

if command -v apt >/dev/null 2>&1; then
    echo -e "${YELLOW}Обнаружен пакетный менеджер: apt${NC}"
    echo -e "${BLUE}Обновление системы и установка зависимостей...${NC}"
    apt update && apt upgrade -y || handle_error "Не удалось обновить систему"
    apt install -y build-essential cmake libuv1-dev libssl-dev libhwloc-dev git screen cpulimit libmicrohttpd-dev || handle_error "Не удалось установить зависимости"
elif command -v yum >/dev/null 2>&1; then
    echo -e "${YELLOW}Обнаружен пакетный менеджер: yum${NC}"
    echo -e "${BLUE}Обновление системы и установка зависимостей...${NC}"
    yum update -y || handle_error "Не удалось обновить систему"
    yum install -y epel-release || handle_error "Не удалось установить epel-release"
    yum install -y cmake3 libuv-devel openssl-devel hwloc-devel git screen cpulimit libmicrohttpd-devel || handle_error "Не удалось установить зависимости"
elif command -v dnf >/dev/null 2>&1; then
    echo -e "${YELLOW}Обнаружен пакетный менеджер: dnf${NC}"
    echo -e "${BLUE}Обновление системы и установка зависимостей...${NC}"
    dnf update -y || handle_error "Не удалось обновить систему"
    dnf install -y cmake libuv-devel openssl-devel hwloc-devel git screen cpulimit libmicrohttpd-devel || handle_error "Не удалось установить зависимости"
elif command -v apk >/dev/null 2>&1; then
    echo -e "${YELLOW}Обнаружен пакетный менеджер: apk${NC}"
    echo -e "${BLUE}Обновление системы и установка зависимостей...${NC}"
    apk update || handle_error "Не удалось обновить систему"
    apk add build-base cmake libuv-dev openssl-dev hwloc-dev git screen cpulimit libmicrohttpd-dev || handle_error "Не удалось установить зависимости"
elif command -v zypper >/dev/null 2>&1; then
    echo -e "${YELLOW}Обнаружен пакетный менеджер: zypper${NC}"
    echo -e "${BLUE}Обновление системы и установка зависимостей...${NC}"
    zypper refresh || handle_error "Не удалось обновить систему"
    zypper install -y gcc gcc-c++ cmake libuv-devel libopenssl-devel hwloc-devel git screen cpulimit libmicrohttpd-devel || handle_error "Не удалось установить зависимости"
else
    handle_error "Пакетный менеджер не найден. Установка зависимостей невозможна."
fi

# Скачивание и сборка XMRig
if [ -d "$XMRIG_PATH" ]; then
    echo -e "${YELLOW}Папка $XMRIG_PATH уже существует. Удаление старой версии...${NC}"
    rm -rf "$XMRIG_PATH" || handle_error "Не удалось удалить старую версию $XMRIG_PATH"
fi

echo -e "${BLUE}Клонирование репозитория XMRig...${NC}"
git clone https://github.com/xmrig/xmrig.git "$XMRIG_PATH" || handle_error "Не удалось клонировать репозиторий XMRig"

echo -e "${BLUE}Переход в директорию $XMRIG_PATH...${NC}"
cd "$XMRIG_PATH" || handle_error "Не удалось перейти в директорию $XMRIG_PATH"

echo -e "${BLUE}Создание директории сборки...${NC}"
mkdir build || handle_error "Не удалось создать директорию build"
cd build || handle_error "Не удалось перейти в директорию build"

echo -e "${BLUE}Запуск CMake...${NC}"
cmake .. || handle_error "Не удалось выполнить cmake"

echo -e "${BLUE}Запуск сборки...${NC}"
make || handle_error "Не удалось выполнить make"

# Создание файла конфигурации
echo -e "${BLUE}Создание файла конфигурации...${NC}"
mkdir -p "$XMRIG_PATH/logs" || handle_error "Не удалось создать директорию логов"
cat << EOF > "$XMRIG_PATH/build/config.json"
{
    "algo": "rx/0",
    "url": "pool.supportxmr.com:3333",
    "user": "$WALLET",
    "pass": "x",
    "rig-id": "мой_сервер",
    "threads": 1,
    "cpu-priority": 1,
    "donate-level": 0,
    "log-file": "$LOG_FILE",
    "log-level": 0,
    "proxy": "$PROXY"
}
EOF

# Создание службы systemd для XMRig
echo -e "${BLUE}Создание службы systemd для XMRig...${NC}"
cat << EOF > /etc/systemd/system/xmrig.service
[Unit]
Description=XMRig CPU Miner Service
After=network.target

[Service]
ExecStart=/usr/bin/screen -dmS xmrig bash -c "cpulimit -l 50 -- '$XMRIG_PATH/build/xmrig' --config '$XMRIG_PATH/build/config.json'"
WorkingDirectory=$XMRIG_PATH/build/
Restart=always
Nice=10
CPUQuota=50%
IOWeight=5
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Создание скрипта мониторинга
echo -e "${BLUE}Создание скрипта мониторинга...${NC}"
cat << EOF > "$MONITOR_SCRIPT"
#!/bin/bash

if [ ! -f "/etc/systemd/system/xmrig.service" ] || [ ! -f "$XMRIG_PATH/build/xmrig" ]; then
    echo -e "${RED}XMRig удалён, восстанавливаем...${NC}"
    bash $0
fi
EOF
chmod +x "$MONITOR_SCRIPT" || handle_error "Не удалось сделать скрипт мониторинга исполняемым"

# Добавление скрипта мониторинга в cron
echo -e "${BLUE}Добавление скрипта мониторинга в cron...${NC}"
(crontab -l 2>/dev/null; echo "* * * * * $MONITOR_SCRIPT") | crontab - || handle_error "Не удалось добавить задачу мониторинга в cron"

# Включение и запуск службы
echo -e "${BLUE}Включение и запуск службы XMRig...${NC}"
if systemctl list-unit-files | grep -q xmrig.service; then
    systemctl daemon-reload || handle_error "Не удалось перезагрузить демоны systemd"
    systemctl enable xmrig.service || handle_error "Не удалось включить службу XMRig"
    systemctl start xmrig.service || handle_error "Не удалось запустить службу XMRig"
else
    handle_error "Служба XMRig не была создана. Проверьте конфигурацию."
fi

# Вывод логов на экран после запуска
echo -e "${BLUE}Вывод логов XMRig в реальном времени...${NC}"
tail -f $LOG_FILE

# Завершение установки
echo -e "${GREEN}Установка завершена! XMRig работает в фоновом режиме.${NC}"
echo -e "${GREEN}Для проверки статуса используйте: sudo systemctl status xmrig.service${NC}"

# Запуск XMRig вручную с выводом ошибок
run_xmrig_with_errors() {
    echo -e "${BLUE}Запуск XMRig вручную с выводом ошибок...${NC}"
    $XMRIG_PATH/build/xmrig --config $XMRIG_PATH/build/config.json 2>&1 | tee -a $LOG_FILE
}

run_xmrig_with_errors
