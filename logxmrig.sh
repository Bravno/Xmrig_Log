#!/bin/bash

# Переменные
XMRIG_VERSION="6.20.0"
XMRIG_DIR="/opt/xmrig"
LOG_DIR="/var/log/xmrig"
CONFIG_FILE="$XMRIG_DIR/config.json"
LOG_FILE="$LOG_DIR/xmrig.log"
WALLET="4A9SeKhwWx8DtAboVp1e1LdbgrRJxvjEFNh4VNw1NDng6ELLeKJPVrPQ9n9eNc4iLVC4BKeR4egnUL68D1qUmdJ7N3TaB5w"

# Установка зависимостей
apt-get update
apt-get install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# Клонирование репозитория XMRig
git clone https://github.com/xmrig/xmrig.git $XMRIG_DIR
cd $XMRIG_DIR

# Сборка XMRig
mkdir build
cd build
cmake ..
make -j$(nproc)

# Создание директории для логов
mkdir -p $LOG_DIR

# Создание конфигурационного файла
cat << EOF > $CONFIG_FILE
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "priority": 5
    },
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "url": "pool.supportxmr.com:3333",
            "user": "$WALLET",
            "pass": "x",
            "keepalive": true,
            "nicehash": false,
            "variant": -1
        }
    ]
}
EOF

# Запуск XMRig с логированием
$XMRIG_DIR/build/xmrig -c $CONFIG_FILE | tee -a $LOG_FILE
